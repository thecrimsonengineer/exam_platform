import 'dart:convert';
import 'dart:io';

const _sourceCorpusRef = 'phase-ml9d-whole-corpus-ml8-closed';
const _sourceCorpusSha = 'f4d7e8bde1e5584f27fdce98741b7ab7db0ab23b';
const _maxReviewAgeDays = 365;

const _rolesByChannel = <String, Set<String>>{
  'technical': {
    'subject_matter_reviewer',
    'technical_reviewer',
    'content_governance_reviewer',
  },
  'source': {
    'content_governance_reviewer',
    'technical_reviewer',
    'subject_matter_reviewer',
  },
  'rights': {
    'copyright_reviewer',
    'content_governance_reviewer',
    'legal_or_rights_reviewer',
  },
  'curriculum': {
    'curriculum_reviewer',
    'content_governance_reviewer',
    'subject_matter_reviewer',
  },
  'pedagogy': {
    'pedagogy_reviewer',
    'content_governance_reviewer',
    'subject_matter_reviewer',
  },
  'accessibility': {
    'accessibility_reviewer',
    'content_governance_reviewer',
  },
  'ui': {
    'content_governance_reviewer',
    'accessibility_reviewer',
  },
};

Future<void> main(List<String> args) async {
  final requireComplete = args.contains('--require-complete');
  const manifestPath =
      'content/micro_learning/human_review/ml9e_human_review_manifest_v1.json';
  final manifest = await _readObject(manifestPath);
  if (exitCode != 0) return;

  final issues = <String>[];
  final warnings = <String>[];

  _expect(manifest['schemaVersion'], 1, issues, 'manifest.schemaVersion');
  _expect(manifest['phase'], 'ML-9E', issues, 'manifest.phase');
  _expect(manifest['sourceCorpusRef'], _sourceCorpusRef, issues,
      'manifest.sourceCorpusRef');
  _expect(manifest['sourceCorpusSha'], _sourceCorpusSha, issues,
      'manifest.sourceCorpusSha');
  _expect(manifest['candidateFactCount'], 120, issues,
      'manifest.candidateFactCount');
  _expect(manifest['batchCount'], 12, issues, 'manifest.batchCount');

  final batches = manifest['batches'];
  if (batches is! List || batches.length != 12) {
    issues.add('ML9E_MANIFEST_BATCH_COUNT: expected exactly 12 batches.');
    _fail(issues);
    return;
  }

  final seenFacts = <String>{};
  var acceptedFacts = 0;
  var revisedFacts = 0;
  var rejectedFacts = 0;
  var pendingFacts = 0;
  var completedBatches = 0;
  var signedChannelReviews = 0;
  var pendingChannelReviews = 0;
  var notApplicableChannelReviews = 0;

  for (var index = 0; index < batches.length; index++) {
    final rawBatch = batches[index];
    if (rawBatch is! Map) {
      issues.add('ML9E_BATCH_ENTRY: manifest batch $index is not an object.');
      continue;
    }
    final batch = Map<String, dynamic>.from(rawBatch);
    final expectedId = 'ml9_batch_${(index + 1).toString().padLeft(2, '0')}';
    _expect(batch['batchId'], expectedId, issues, 'manifest.batches[$index]');
    final packetPath = batch['packetPath'];
    if (packetPath is! String || packetPath.isEmpty) {
      issues.add('ML9E_PACKET_PATH: $expectedId has no packetPath.');
      continue;
    }

    final packet = await _readObject(packetPath);
    if (packet.isEmpty && exitCode != 0) return;
    _expect(packet['schemaVersion'], 1, issues, '$packetPath.schemaVersion');
    _expect(packet['phase'], 'ML-9E', issues, '$packetPath.phase');
    _expect(packet['batchId'], expectedId, issues, '$packetPath.batchId');
    _expect(packet['sourceCorpusRef'], _sourceCorpusRef, issues,
        '$packetPath.sourceCorpusRef');
    _expect(packet['sourceCorpusSha'], _sourceCorpusSha, issues,
        '$packetPath.sourceCorpusSha');

    final facts = packet['facts'];
    if (facts is! List || facts.length != 10) {
      issues.add('ML9E_PACKET_FACT_COUNT: $packetPath must contain 10 facts.');
      continue;
    }

    var packetAccepted = 0;
    for (var factIndex = 0; factIndex < facts.length; factIndex++) {
      final rawFact = facts[factIndex];
      if (rawFact is! Map) {
        issues.add(
          'ML9E_FACT_OBJECT: $packetPath fact $factIndex is not an object.',
        );
        continue;
      }
      final review = Map<String, dynamic>.from(rawFact);
      final factId = review['microFactId'];
      if (factId is! String || !seenFacts.add(factId)) {
        issues.add('ML9E_FACT_ID: invalid or duplicate fact ID $factId.');
        continue;
      }
      _expect(review['contentVersion'], 1, issues, '$factId.contentVersion');

      final candidatePath = review['candidatePath'];
      final evidenceBundlePath = review['evidenceBundlePath'];
      if (candidatePath is! String || candidatePath.isEmpty) {
        issues.add('ML9E_CANDIDATE_PATH: $factId.');
        continue;
      }
      if (evidenceBundlePath is! String || evidenceBundlePath.isEmpty) {
        issues.add('ML9E_EVIDENCE_PATH: $factId.');
        continue;
      }

      final fact = await _readObject(candidatePath);
      if (fact.isEmpty && exitCode != 0) return;
      if (fact['microFactId'] != factId ||
          fact['contentVersion'] != review['contentVersion']) {
        issues.add('ML9E_FACT_BINDING: $factId candidate binding mismatch.');
      }
      if (fact['status'] != 'review') {
        issues.add('ML9E_FACT_STATUS: $factId must remain review-state.');
      }
      final runtime = fact['runtime'];
      if (runtime is! Map || runtime['startupEligible'] != false) {
        issues.add(
          'ML9E_STARTUP_BOUNDARY: $factId must remain startup-ineligible.',
        );
      }

      final provenance = Map<String, dynamic>.from(fact['provenance'] as Map);
      _expect(
        review['sourceUrl'],
        provenance['officialUrl'],
        issues,
        '$factId.sourceUrl',
      );
      _expect(
        review['sourceLocator'],
        provenance['sourceLocator'],
        issues,
        '$factId.sourceLocator',
      );

      final evidenceBundle = await _readObject(evidenceBundlePath);
      if (evidenceBundle.isEmpty && exitCode != 0) return;
      final evidenceFacts = evidenceBundle['facts'];
      final matchingEvidence = evidenceFacts is List
          ? evidenceFacts
              .whereType<Map>()
              .map(Map<String, dynamic>.from)
              .where((entry) => entry['microFactId'] == factId)
              .toList(growable: false)
          : const <Map<String, dynamic>>[];
      if (matchingEvidence.length != 1) {
        issues.add(
          'ML9E_EVIDENCE_BINDING: $factId must have exactly one ML-9C evidence record.',
        );
      }

      final curriculum = Map<String, dynamic>.from(fact['curriculum'] as Map);
      final channelsRaw = review['channels'];
      if (channelsRaw is! Map) {
        issues.add('ML9E_CHANNELS: $factId channels missing.');
        continue;
      }
      final channels = Map<String, dynamic>.from(channelsRaw);
      const requiredChannelNames = {
        'technical',
        'source',
        'rights',
        'curriculum',
        'pedagogy',
        'accessibility',
        'ui',
      };
      if (channels.keys.toSet().difference(requiredChannelNames).isNotEmpty ||
          requiredChannelNames.difference(channels.keys.toSet()).isNotEmpty) {
        issues.add('ML9E_CHANNEL_SET: $factId channel set drifted.');
        continue;
      }

      var allApplicablePass = true;
      var anyFail = false;
      for (final channelName in requiredChannelNames) {
        final channelRaw = channels[channelName];
        if (channelRaw is! Map) {
          issues.add('ML9E_CHANNEL_OBJECT: $factId/$channelName.');
          allApplicablePass = false;
          continue;
        }
        final channel = Map<String, dynamic>.from(channelRaw);
        final isGeneralCurriculum =
            channelName == 'curriculum' && curriculum['scope'] == 'general';
        final channelResult = _validateChannel(
          factId: factId,
          channelName: channelName,
          channel: channel,
          allowNotApplicable: isGeneralCurriculum,
          issues: issues,
        );

        if (channelResult == _ChannelState.pass) {
          signedChannelReviews++;
        } else if (channelResult == _ChannelState.notApplicable) {
          notApplicableChannelReviews++;
        } else {
          allApplicablePass = false;
          if (channelResult == _ChannelState.fail) {
            signedChannelReviews++;
            anyFail = true;
          } else {
            pendingChannelReviews++;
          }
        }
      }

      final overall = review['overallDecision'];
      if (!const {'pending', 'accept', 'revise', 'reject'}.contains(overall)) {
        issues.add('ML9E_OVERALL_DECISION: $factId has invalid decision.');
        continue;
      }

      if (overall == 'accept') {
        acceptedFacts++;
        packetAccepted++;
        if (!allApplicablePass) {
          issues.add(
            'ML9E_ACCEPT_WITHOUT_ALL_PASS: $factId cannot be accepted until every applicable channel passes.',
          );
        }
        if (review['revisionNotes'] != null) {
          warnings.add(
            'ML9E_ACCEPT_WITH_REVISION_NOTES: $factId has revision notes despite accept.',
          );
        }
      } else if (overall == 'revise') {
        revisedFacts++;
        if (!anyFail) {
          issues.add(
            'ML9E_REVISE_WITHOUT_FAIL: $factId revise requires at least one failed channel.',
          );
        }
        if (!_nonEmpty(review['revisionNotes'])) {
          issues.add(
            'ML9E_REVISION_NOTES_REQUIRED: $factId revise requires revision notes.',
          );
        }
      } else if (overall == 'reject') {
        rejectedFacts++;
        if (!anyFail) {
          issues.add(
            'ML9E_REJECT_WITHOUT_FAIL: $factId reject requires at least one failed channel.',
          );
        }
        if (!_nonEmpty(review['revisionNotes'])) {
          issues.add(
            'ML9E_REJECTION_NOTES_REQUIRED: $factId reject requires notes.',
          );
        }
      } else {
        pendingFacts++;
      }
    }

    final packetComplete = packet['humanReviewComplete'] == true;
    final packetStatus = packet['reviewStatus'];
    if (packetComplete) {
      completedBatches++;
      if (packetStatus != 'completed' || packetAccepted != 10) {
        issues.add(
          'ML9E_PACKET_COMPLETION: $expectedId complete requires 10 accepted facts and reviewStatus=completed.',
        );
      }
    } else if (packetStatus == 'completed') {
      issues.add(
        'ML9E_PACKET_COMPLETION_FLAG: $expectedId cannot be completed while humanReviewComplete=false.',
      );
    }
  }

  if (seenFacts.length != 120) {
    issues.add(
      'ML9E_CORPUS_COVERAGE: expected 120 unique review facts, got ${seenFacts.length}.',
    );
  }

  if (requireComplete) {
    if (acceptedFacts != 120 ||
        pendingFacts != 0 ||
        revisedFacts != 0 ||
        rejectedFacts != 0 ||
        completedBatches != 12 ||
        manifest['humanReviewComplete'] != true ||
        manifest['status'] != 'completed') {
      issues.add(
        'ML9E_HUMAN_REVIEW_INCOMPLETE: require-complete needs 120 accepted facts, '
        '12 completed batches, and completed manifest state.',
      );
    }
  } else {
    if (manifest['humanReviewComplete'] == true ||
        manifest['status'] == 'completed') {
      if (acceptedFacts != 120 || completedBatches != 12) {
        issues.add(
          'ML9E_PREMATURE_MANIFEST_COMPLETION: manifest completion is not supported by packet state.',
        );
      }
    }
  }

  if (issues.isNotEmpty) {
    _fail(issues);
    return;
  }

  stdout.writeln(
    requireComplete
        ? 'ML-9E HUMAN REVIEW COMPLETE VALID'
        : 'ML-9E HUMAN REVIEW PACKAGE VALID',
  );
  stdout.writeln('Facts covered: ${seenFacts.length}');
  stdout.writeln('Accepted facts: $acceptedFacts');
  stdout.writeln('Pending facts: $pendingFacts');
  stdout.writeln('Revision facts: $revisedFacts');
  stdout.writeln('Rejected facts: $rejectedFacts');
  stdout.writeln('Completed batches: $completedBatches / 12');
  stdout.writeln('Signed channel reviews: $signedChannelReviews');
  stdout.writeln('Pending channel reviews: $pendingChannelReviews');
  stdout.writeln(
    'Not-applicable curriculum reviews: $notApplicableChannelReviews',
  );
  for (final warning in warnings) {
    stdout.writeln('WARNING $warning');
  }
}

_ChannelState _validateChannel({
  required String factId,
  required String channelName,
  required Map<String, dynamic> channel,
  required bool allowNotApplicable,
  required List<String> issues,
}) {
  final status = channel['status'];
  if (!const {'pending', 'pass', 'fail', 'not_applicable'}.contains(status)) {
    issues.add('ML9E_CHANNEL_STATUS: $factId/$channelName.');
    return _ChannelState.pending;
  }

  final requiredChecks = _stringSet(channel['requiredChecks']);
  final confirmedChecks = _stringSet(channel['confirmedChecks']);
  if (requiredChecks == null || confirmedChecks == null) {
    issues.add('ML9E_CHANNEL_CHECKS: $factId/$channelName.');
    return _ChannelState.pending;
  }
  if (!requiredChecks.containsAll(confirmedChecks)) {
    issues.add(
      'ML9E_UNKNOWN_CONFIRMED_CHECK: $factId/$channelName confirmed a check that is not required.',
    );
  }

  if (status == 'not_applicable') {
    if (!allowNotApplicable ||
        requiredChecks.isNotEmpty ||
        confirmedChecks.isNotEmpty ||
        channel['humanAttested'] != false ||
        channel['reviewerId'] != null ||
        channel['reviewerRole'] != null ||
        channel['reviewedAt'] != null ||
        channel['nextReviewDueAt'] != null) {
      issues.add('ML9E_NOT_APPLICABLE_INVALID: $factId/$channelName.');
    }
    return _ChannelState.notApplicable;
  }

  if (status == 'pending') {
    if (channel['humanAttested'] != false ||
        channel['reviewerId'] != null ||
        channel['reviewedAt'] != null ||
        channel['nextReviewDueAt'] != null ||
        confirmedChecks.isNotEmpty) {
      issues.add(
        'ML9E_PENDING_ATTESTATION: $factId/$channelName pending review cannot contain attested review data.',
      );
    }
    return _ChannelState.pending;
  }

  if (channel['humanAttested'] != true ||
      !_nonEmpty(channel['reviewerId']) ||
      !_nonEmpty(channel['reviewerRole']) ||
      !_nonEmpty(channel['rationale'])) {
    issues.add(
      'ML9E_HUMAN_ATTESTATION_REQUIRED: $factId/$channelName pass/fail requires human reviewer identity, role, attestation, and rationale.',
    );
  }

  final role = channel['reviewerRole'];
  final allowedRoles = _rolesByChannel[channelName] ?? const <String>{};
  if (role is! String || !allowedRoles.contains(role)) {
    issues.add(
      'ML9E_REVIEWER_ROLE: $factId/$channelName reviewer role is not allowed.',
    );
  }

  final reviewedAt = _parseDate(channel['reviewedAt']);
  final dueAt = _parseDate(channel['nextReviewDueAt']);
  if (reviewedAt == null || dueAt == null) {
    issues.add(
      'ML9E_REVIEW_DATES: $factId/$channelName pass/fail requires review and due dates.',
    );
  } else {
    if (dueAt.isBefore(reviewedAt)) {
      issues.add(
        'ML9E_REVIEW_DATE_ORDER: $factId/$channelName due date precedes review date.',
      );
    }
    if (dueAt.difference(reviewedAt).inDays > _maxReviewAgeDays) {
      issues.add(
        'ML9E_REVIEW_VALIDITY: $factId/$channelName exceeds 365-day review validity.',
      );
    }
  }

  if (status == 'pass' &&
      (requiredChecks.length != confirmedChecks.length ||
          !confirmedChecks.containsAll(requiredChecks))) {
    issues.add(
      'ML9E_PASS_CHECKS_INCOMPLETE: $factId/$channelName pass requires every required check.',
    );
  }

  return status == 'pass' ? _ChannelState.pass : _ChannelState.fail;
}

Set<String>? _stringSet(dynamic value) {
  if (value is! List || value.any((item) => item is! String)) return null;
  final values = value.cast<String>();
  if (values.toSet().length != values.length) return null;
  return values.toSet();
}

DateTime? _parseDate(dynamic value) {
  if (value is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
    return null;
  }
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return null;
  final normalized =
      '${parsed.year.toString().padLeft(4, '0')}-'
      '${parsed.month.toString().padLeft(2, '0')}-'
      '${parsed.day.toString().padLeft(2, '0')}';
  return normalized == value ? parsed : null;
}

bool _nonEmpty(dynamic value) => value is String && value.trim().isNotEmpty;

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

void _expect(
  dynamic actual,
  dynamic expected,
  List<String> issues,
  String path,
) {
  if (actual != expected) {
    issues.add('ML9E_VALUE_MISMATCH: $path expected $expected got $actual.');
  }
}

void _fail(List<String> issues) {
  stderr.writeln('ML-9E HUMAN REVIEW INVALID with ${issues.length} issue(s):');
  for (final issue in issues) {
    stderr.writeln(' - $issue');
  }
  exitCode = 1;
}

enum _ChannelState { pending, pass, fail, notApplicable }
