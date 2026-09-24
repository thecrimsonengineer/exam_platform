import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final issues = <String>[];
  const manifestPath =
      'content/micro_learning/human_review/ml9e_human_review_manifest_v1.json';
  final manifest = await _readObject(manifestPath);
  if (exitCode != 0) return;

  if (manifest['status'] != 'completed' ||
      manifest['humanReviewComplete'] != true ||
      manifest['candidateFactCount'] != 120 ||
      manifest['batchCount'] != 12) {
    issues.add('ML9E_POST_MANIFEST: completed human-review manifest required.');
  }

  final seen = <String>{};
  var validatedFacts = 0;
  var publishedFacts = 0;
  var startupEligibleFacts = 0;
  var rightsPass = 0;
  var curriculumPass = 0;
  var pedagogyPass = 0;
  var accessibilityPass = 0;
  var generalCurriculumExempt = 0;

  for (var batch = 1; batch <= 12; batch++) {
    final id = batch.toString().padLeft(2, '0');
    final packet = await _readObject(
      'content/micro_learning/human_review/ml9e_batch_${id}_human_review.json',
    );
    final evidence = await _readObject(
      'content/micro_learning/evidence/ml9c_batch_${id}_gate_evidence.json',
    );
    if (exitCode != 0) return;

    if (packet['reviewStatus'] != 'completed' ||
        packet['humanReviewComplete'] != true) {
      issues.add('ML9E_POST_PACKET: batch $id is not completed.');
    }

    final reviews = (packet['facts'] as List)
        .whereType<Map>()
        .map(Map<String, dynamic>.from)
        .toList(growable: false);
    final evidenceFacts = (evidence['facts'] as List)
        .whereType<Map>()
        .map(Map<String, dynamic>.from)
        .toList(growable: false);
    final evidenceById = <String, Map<String, dynamic>>{
      for (final entry in evidenceFacts)
        entry['microFactId'] as String: entry,
    };

    if (reviews.length != 10 || evidenceFacts.length != 10) {
      issues.add('ML9E_POST_BATCH_SIZE: batch $id must contain 10 records.');
      continue;
    }

    for (final review in reviews) {
      final factId = review['microFactId'] as String;
      if (!seen.add(factId)) {
        issues.add('ML9E_POST_DUPLICATE_FACT: $factId.');
        continue;
      }
      if (review['overallDecision'] != 'accept') {
        issues.add('ML9E_POST_DECISION: $factId is not accepted.');
      }

      final fact = await _readObject(review['candidatePath'] as String);
      if (exitCode != 0) return;
      if (fact['microFactId'] != factId || fact['contentVersion'] != 1) {
        issues.add('ML9E_POST_FACT_BINDING: $factId.');
      }

      if (fact['status'] == 'validated') {
        validatedFacts++;
      } else if (fact['status'] == 'published') {
        publishedFacts++;
      } else {
        issues.add('ML9E_POST_FACT_STATUS: $factId must be validated.');
      }

      final runtime = Map<String, dynamic>.from(fact['runtime'] as Map);
      if (runtime['startupEligible'] == true) {
        startupEligibleFacts++;
        issues.add('ML9E_POST_STARTUP: $factId became startup eligible.');
      }

      final factReview = Map<String, dynamic>.from(fact['review'] as Map);
      for (final field in const [
        'technicalStatus',
        'sourceStatus',
        'pedagogyStatus',
        'copyrightStatus',
        'uiStatus',
        'humanTechnicalStatus',
      ]) {
        if (factReview[field] != 'pass') {
          issues.add('ML9E_POST_FACT_REVIEW: $factId $field is not pass.');
        }
      }
      if (!_date(factReview['reviewedAt']) ||
          !_date(factReview['nextReviewDueAt'])) {
        issues.add('ML9E_POST_FACT_DATES: $factId.');
      }

      final ev = evidenceById[factId];
      if (ev == null) {
        issues.add('ML9E_POST_EVIDENCE_MISSING: $factId.');
        continue;
      }

      final rights =
          Map<String, dynamic>.from(ev['rightsEvidence'] as Map);
      final rightsReview =
          Map<String, dynamic>.from(rights['review'] as Map);
      if (rightsReview['status'] == 'pass' &&
          rightsReview['humanReviewed'] == true &&
          _date(rightsReview['reviewedAt']) &&
          _date(rightsReview['nextReviewDueAt'])) {
        rightsPass++;
      } else {
        issues.add('ML9E_POST_RIGHTS: $factId.');
      }

      final curriculum = Map<String, dynamic>.from(fact['curriculum'] as Map);
      if (curriculum['scope'] == 'mapped') {
        final mappingRaw = ev['curriculumEvidence'];
        if (mappingRaw is! Map) {
          issues.add('ML9E_POST_MAPPING_MISSING: $factId.');
        } else {
          final mapping = Map<String, dynamic>.from(mappingRaw);
          final mappingReview =
              Map<String, dynamic>.from(mapping['review'] as Map);
          if (mappingReview['status'] == 'pass' &&
              mappingReview['humanReviewed'] == true &&
              mappingReview['conceptAlignmentConfirmed'] == true &&
              _date(mappingReview['reviewedAt']) &&
              _date(mappingReview['nextReviewDueAt'])) {
            curriculumPass++;
          } else {
            issues.add('ML9E_POST_MAPPING: $factId.');
          }
        }
      } else {
        generalCurriculumExempt++;
        if (ev['curriculumEvidence'] != null) {
          issues.add('ML9E_POST_GENERAL_MAPPING: $factId.');
        }
      }

      final pedagogy =
          Map<String, dynamic>.from(ev['pedagogyEvidence'] as Map);
      final pedagogyReview =
          Map<String, dynamic>.from(pedagogy['pedagogyReview'] as Map);
      final accessibilityReview =
          Map<String, dynamic>.from(pedagogy['accessibilityReview'] as Map);

      if (pedagogyReview['status'] == 'pass' &&
          pedagogyReview['humanReviewed'] == true &&
          pedagogyReview['singleConceptConfirmed'] == true &&
          pedagogyReview['standaloneMeaningConfirmed'] == true &&
          pedagogyReview['cognitiveLoadAcceptable'] == true &&
          pedagogyReview['jargonLoadAcceptable'] == true &&
          pedagogyReview['shortVariantMeaningPreserved'] == true &&
          pedagogyReview['precisionPreserved'] == true &&
          pedagogyReview['assessmentLeakageReviewed'] == true &&
          _date(pedagogyReview['reviewedAt']) &&
          _date(pedagogyReview['nextReviewDueAt'])) {
        pedagogyPass++;
      } else {
        issues.add('ML9E_POST_PEDAGOGY: $factId.');
      }

      if (accessibilityReview['status'] == 'pass' &&
          accessibilityReview['humanReviewed'] == true &&
          accessibilityReview['screenReaderStandaloneConfirmed'] == true &&
          accessibilityReview['visualIndependenceConfirmed'] == true &&
          accessibilityReview['reducedMotionEquivalentConfirmed'] == true &&
          accessibilityReview['plainLanguageAccessibleConfirmed'] == true &&
          accessibilityReview['noForcedInteractionConfirmed'] == true &&
          _date(accessibilityReview['reviewedAt']) &&
          _date(accessibilityReview['nextReviewDueAt'])) {
        accessibilityPass++;
      } else {
        issues.add('ML9E_POST_ACCESSIBILITY: $factId.');
      }
    }
  }

  if (seen.length != 120 ||
      validatedFacts != 120 ||
      publishedFacts != 0 ||
      startupEligibleFacts != 0 ||
      rightsPass != 120 ||
      curriculumPass != 114 ||
      generalCurriculumExempt != 6 ||
      pedagogyPass != 120 ||
      accessibilityPass != 120) {
    issues.add(
      'ML9E_POST_COUNTS: expected facts=120 validated=120 published=0 '
      'startup=0 rights=120 curriculum=114 general=6 pedagogy=120 '
      'accessibility=120; got facts=${seen.length} validated=$validatedFacts '
      'published=$publishedFacts startup=$startupEligibleFacts '
      'rights=$rightsPass curriculum=$curriculumPass '
      'general=$generalCurriculumExempt pedagogy=$pedagogyPass '
      'accessibility=$accessibilityPass.',
    );
  }

  if (issues.isNotEmpty) {
    stderr.writeln(
      'ML-9E POST-APPLICATION INVALID with ${issues.length} issue(s):',
    );
    for (final issue in issues) {
      stderr.writeln(' - $issue');
    }
    exitCode = 1;
    return;
  }

  stdout.writeln('ML-9E POST-APPLICATION VALID');
  stdout.writeln('Validated facts: 120');
  stdout.writeln('Published facts: 0');
  stdout.writeln('Startup-eligible facts: 0');
  stdout.writeln('Rights human-pass evidence: 120');
  stdout.writeln('Curriculum human-pass evidence: 114');
  stdout.writeln('General curriculum exemptions: 6');
  stdout.writeln('Pedagogy human-pass evidence: 120');
  stdout.writeln('Accessibility human-pass evidence: 120');
}

bool _date(dynamic value) =>
    value is String && RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value);

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
