import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  final apply = args.contains('--apply');

  final validation = await Process.run(
    Platform.resolvedExecutable,
    const [
      'run',
      'tool/validate_ml9e_human_review.dart',
      '--require-complete',
    ],
    runInShell: true,
  );

  stdout.write(validation.stdout);
  stderr.write(validation.stderr);
  if (validation.exitCode != 0) {
    stderr.writeln(
      'ML-9E application blocked: complete human review validation did not pass.',
    );
    exitCode = validation.exitCode;
    return;
  }

  final updates = <String, Map<String, dynamic>>{};

  for (var batch = 1; batch <= 12; batch++) {
    final id = batch.toString().padLeft(2, '0');
    final packetPath =
        'content/micro_learning/human_review/ml9e_batch_${id}_human_review.json';
    final evidencePath =
        'content/micro_learning/evidence/ml9c_batch_${id}_gate_evidence.json';

    final packet = await _readObject(packetPath);
    final evidence = await _readObject(evidencePath);
    if (exitCode != 0) return;

    final reviewFacts = (packet['facts'] as List)
        .whereType<Map>()
        .map(Map<String, dynamic>.from)
        .toList(growable: false);
    final evidenceFacts = (evidence['facts'] as List)
        .whereType<Map>()
        .map(Map<String, dynamic>.from)
        .toList(growable: false);

    final evidenceIndex = <String, Map<String, dynamic>>{
      for (final entry in evidenceFacts)
        entry['microFactId'] as String: entry,
    };

    for (final reviewFact in reviewFacts) {
      final factId = reviewFact['microFactId'] as String;
      final candidatePath = reviewFact['candidatePath'] as String;
      final fact = await _readObject(candidatePath);
      if (exitCode != 0) return;

      final channels = Map<String, dynamic>.from(reviewFact['channels'] as Map);
      final technical =
          Map<String, dynamic>.from(channels['technical'] as Map);
      final source = Map<String, dynamic>.from(channels['source'] as Map);
      final rights = Map<String, dynamic>.from(channels['rights'] as Map);
      final curriculum =
          Map<String, dynamic>.from(channels['curriculum'] as Map);
      final pedagogy =
          Map<String, dynamic>.from(channels['pedagogy'] as Map);
      final accessibility =
          Map<String, dynamic>.from(channels['accessibility'] as Map);
      final ui = Map<String, dynamic>.from(channels['ui'] as Map);

      final reviewDates = <DateTime>[];
      final dueDates = <DateTime>[];
      for (final channel in [
        technical,
        source,
        rights,
        if (curriculum['status'] != 'not_applicable') curriculum,
        pedagogy,
        accessibility,
        ui,
      ]) {
        reviewDates.add(DateTime.parse(channel['reviewedAt'] as String));
        dueDates.add(DateTime.parse(channel['nextReviewDueAt'] as String));
      }
      reviewDates.sort();
      dueDates.sort();
      final finalReviewedAt = _date(reviewDates.last);
      final finalDueAt = _date(dueDates.first);

      fact['status'] = 'validated';
      final factReview = Map<String, dynamic>.from(fact['review'] as Map);
      factReview
        ..['technicalStatus'] = 'pass'
        ..['sourceStatus'] = 'pass'
        ..['pedagogyStatus'] = 'pass'
        ..['copyrightStatus'] = 'pass'
        ..['uiStatus'] = 'pass'
        ..['humanTechnicalStatus'] = 'pass'
        ..['reviewedAt'] = finalReviewedAt
        ..['nextReviewDueAt'] = finalDueAt;
      fact['review'] = factReview;

      final runtime = Map<String, dynamic>.from(fact['runtime'] as Map);
      runtime['startupEligible'] = false;
      fact['runtime'] = runtime;
      updates[candidatePath] = fact;

      final ev = evidenceIndex[factId];
      if (ev == null) {
        stderr.writeln('Missing ML-9C evidence for $factId.');
        exitCode = 2;
        return;
      }

      final rightsEvidence =
          Map<String, dynamic>.from(ev['rightsEvidence'] as Map);
      final rightsReview =
          Map<String, dynamic>.from(rightsEvidence['review'] as Map);
      rightsReview
        ..['status'] = 'pass'
        ..['reviewerRole'] = rights['reviewerRole']
        ..['humanReviewed'] = true
        ..['reviewedAt'] = rights['reviewedAt']
        ..['nextReviewDueAt'] = rights['nextReviewDueAt'];
      rightsEvidence['review'] = rightsReview;
      ev['rightsEvidence'] = rightsEvidence;

      if (ev['curriculumEvidence'] != null) {
        final curriculumEvidence =
            Map<String, dynamic>.from(ev['curriculumEvidence'] as Map);
        final mappingReview =
            Map<String, dynamic>.from(curriculumEvidence['review'] as Map);
        mappingReview
          ..['status'] = 'pass'
          ..['reviewerRole'] = curriculum['reviewerRole']
          ..['humanReviewed'] = true
          ..['conceptAlignmentConfirmed'] = true
          ..['placementRationale'] = curriculum['rationale']
          ..['reviewedAt'] = curriculum['reviewedAt']
          ..['nextReviewDueAt'] = curriculum['nextReviewDueAt'];
        curriculumEvidence['review'] = mappingReview;
        ev['curriculumEvidence'] = curriculumEvidence;
      }

      final pedagogyEvidence =
          Map<String, dynamic>.from(ev['pedagogyEvidence'] as Map);
      final pedagogyReview =
          Map<String, dynamic>.from(pedagogyEvidence['pedagogyReview'] as Map);
      final pedagogyChecks =
          (pedagogy['confirmedChecks'] as List).whereType<String>().toSet();
      pedagogyReview
        ..['status'] = 'pass'
        ..['reviewerRole'] = pedagogy['reviewerRole']
        ..['humanReviewed'] = true
        ..['singleConceptConfirmed'] =
            pedagogyChecks.contains('single_concept_confirmed')
        ..['standaloneMeaningConfirmed'] =
            pedagogyChecks.contains('standalone_meaning_confirmed')
        ..['cognitiveLoadAcceptable'] =
            pedagogyChecks.contains('cognitive_load_acceptable')
        ..['jargonLoadAcceptable'] =
            pedagogyChecks.contains('jargon_load_acceptable')
        ..['shortVariantMeaningPreserved'] =
            pedagogyChecks.contains('short_variant_meaning_preserved')
        ..['precisionPreserved'] =
            pedagogyChecks.contains('precision_preserved')
        ..['assessmentLeakageReviewed'] =
            pedagogyChecks.contains('assessment_leakage_reviewed')
        ..['reviewedAt'] = pedagogy['reviewedAt']
        ..['nextReviewDueAt'] = pedagogy['nextReviewDueAt'];
      pedagogyEvidence['pedagogyReview'] = pedagogyReview;

      final accessibilityReview = Map<String, dynamic>.from(
        pedagogyEvidence['accessibilityReview'] as Map,
      );
      final accessibilityChecks = (accessibility['confirmedChecks'] as List)
          .whereType<String>()
          .toSet();
      accessibilityReview
        ..['status'] = 'pass'
        ..['reviewerRole'] = accessibility['reviewerRole']
        ..['humanReviewed'] = true
        ..['screenReaderStandaloneConfirmed'] =
            accessibilityChecks.contains('screen_reader_standalone_confirmed')
        ..['visualIndependenceConfirmed'] =
            accessibilityChecks.contains('visual_independence_confirmed')
        ..['reducedMotionEquivalentConfirmed'] =
            accessibilityChecks.contains('reduced_motion_equivalent_confirmed')
        ..['plainLanguageAccessibleConfirmed'] =
            accessibilityChecks.contains('plain_language_accessible_confirmed')
        ..['noForcedInteractionConfirmed'] =
            accessibilityChecks.contains('no_forced_interaction_confirmed')
        ..['reviewedAt'] = accessibility['reviewedAt']
        ..['nextReviewDueAt'] = accessibility['nextReviewDueAt'];
      pedagogyEvidence['accessibilityReview'] = accessibilityReview;
      ev['pedagogyEvidence'] = pedagogyEvidence;
    }

    evidence['facts'] = evidenceFacts;
    updates[evidencePath] = evidence;
  }

  if (!apply) {
    stdout.writeln(
      'ML-9E human review is eligible for mechanical application.',
    );
    stdout.writeln(
      'Dry run only. Re-run with --apply to write validated review state.',
    );
    stdout.writeln('Files that would be updated: ${updates.length}');
    return;
  }

  for (final entry in updates.entries) {
    final file = File(entry.key);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(entry.value) + '\n',
    );
  }

  stdout.writeln('ML-9E human review application complete.');
  stdout.writeln('Updated files: ${updates.length}');
  stdout.writeln('Facts promoted to validated: 120');
  stdout.writeln('Facts published: 0');
  stdout.writeln('Facts startup eligible: 0');
}

Future<Map<String, dynamic>> _readObject(String path) async {
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('ML-9E required file not found: $path');
    exitCode = 2;
    return <String, dynamic>{};
  }
  try {
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is Map<String, dynamic>) return decoded;
  } on FormatException catch (error) {
    stderr.writeln('Invalid JSON in $path: ${error.message}');
    exitCode = 2;
    return <String, dynamic>{};
  }
  stderr.writeln('JSON root must be an object: $path');
  exitCode = 2;
  return <String, dynamic>{};
}

String _date(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';
