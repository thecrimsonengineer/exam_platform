import 'dart:convert';
import 'dart:io';

import 'package:exam_platform/services/micro_learning/micro_fact_corpus_integrity_validator.dart';

Future<void> main() async {
  const manifestPath = 'content/micro_learning/curated_bank_manifest_v1.json';
  const policyPath =
      'content/micro_learning/duplicate_contradiction_policy_v1.json';
  const ml9cManifestPath =
      'content/micro_learning/evidence/ml9c_gate_evidence_manifest_v1.json';

  final manifest = await _readObject(manifestPath);
  final policy = await _readObject(policyPath);
  final ml9cManifest = await _readObject(ml9cManifestPath);
  if (exitCode != 0) return;

  final issues = <String>[];

  if (manifest['candidateFactCount'] != 120) {
    issues.add(
      'ML9D_CANDIDATE_COUNT: expected 120, got '
      '${manifest['candidateFactCount']}.',
    );
  }

  final coverage = ml9cManifest['coverage'];
  if (coverage is! Map ||
      coverage['candidateFacts'] != 120 ||
      coverage['rightsEvidenceRecords'] != 120 ||
      coverage['mappedCurriculumEvidenceRecords'] != 114 ||
      coverage['generalScopeCurriculumExemptions'] != 6 ||
      coverage['pedagogyEvidenceRecords'] != 120 ||
      coverage['accessibilityReviewTracks'] != 120) {
    issues.add(
      'ML9D_ML9C_EVIDENCE_COVERAGE: ML-9C evidence manifest is not the '
      'closed 120-fact evidence-bound corpus.',
    );
  }

  final humanBoundary = ml9cManifest['humanReviewBoundary'];
  if (humanBoundary is! Map ||
      humanBoundary['humanApprovalsGeneratedByAutomation'] != false ||
      humanBoundary['factsPromotedToValidated'] != 0 ||
      humanBoundary['factsPromotedToPublished'] != 0 ||
      humanBoundary['factsMadeStartupEligible'] != 0) {
    issues.add(
      'ML9D_ML9C_BOUNDARY: ML-9C human-review/lifecycle boundary drifted.',
    );
  }

  final rawSlots = manifest['slots'];
  if (rawSlots is! List || rawSlots.length != 120) {
    issues.add('ML9D_MANIFEST_SLOTS: expected exactly 120 manifest slots.');
  }

  if (issues.isNotEmpty) {
    _fail(issues);
    return;
  }

  final facts = <Map<String, dynamic>>[];
  final ids = <String>{};

  for (final raw in rawSlots as List) {
    if (raw is! Map) {
      issues.add('ML9D_SLOT_OBJECT: manifest contains a non-object slot.');
      continue;
    }
    final slot = Map<String, dynamic>.from(raw);
    final id = slot['microFactId'];
    final path = slot['candidatePath'];

    if (id is! String || !ids.add(id)) {
      issues.add('ML9D_FACT_ID: invalid or duplicate manifest ID $id.');
      continue;
    }
    if (slot['state'] != 'candidate_review') {
      issues.add('ML9D_SLOT_STATE: $id is not candidate_review.');
    }
    if (path is! String || path.isEmpty) {
      issues.add('ML9D_CANDIDATE_PATH: missing candidatePath for $id.');
      continue;
    }

    final fact = await _readObject(path);
    if (fact.isEmpty && exitCode != 0) return;

    if (fact['microFactId'] != id) {
      issues.add('ML9D_FACT_BINDING: $path does not bind to $id.');
    }
    if (fact['status'] != 'review') {
      issues.add('ML9D_LIFECYCLE: $id must remain review-state.');
    }
    final runtime = fact['runtime'];
    if (runtime is! Map || runtime['startupEligible'] != false) {
      issues.add('ML9D_STARTUP_STATE: $id must remain startup-ineligible.');
    }
    facts.add(fact);
  }

  if (facts.length != 120 || ids.length != 120) {
    issues.add(
      'ML9D_CORPUS_COVERAGE: expected 120 unique facts, got '
      'facts=${facts.length}, ids=${ids.length}.',
    );
  }

  if (issues.isNotEmpty) {
    _fail(issues);
    return;
  }

  const expectedPairs = 7140;
  final calculatedPairs = facts.length * (facts.length - 1) ~/ 2;
  if (calculatedPairs != expectedPairs) {
    issues.add(
      'ML9D_PAIR_COUNT: expected $expectedPairs, got $calculatedPairs.',
    );
  }

  final result = const MicroFactCorpusIntegrityValidator().validate(
    facts: facts,
    policy: policy,
    adjudications: const [],
  );

  for (final issue in result.issues) {
    issues.add('ML9D_CORPUS_ISSUE: $issue');
  }

  if (result.reviewCandidates.isNotEmpty) {
    for (final candidate in result.reviewCandidates) {
      issues.add(
        'ML9D_REVIEW_CANDIDATE: ${candidate.pairKey} '
        'signals=${candidate.signals.toList()..sort()} '
        'display=${candidate.displayJaccard.toStringAsFixed(6)} '
        'short=${candidate.shortJaccard.toStringAsFixed(6)} '
        'concept=${candidate.conceptJaccard.toStringAsFixed(6)}',
      );
    }
  }

  if (issues.isNotEmpty) {
    _fail(issues);
    return;
  }

  final concentration = result.concentrationSignals.toList()
    ..sort((a, b) {
      final byCode = a.code.compareTo(b.code);
      return byCode != 0 ? byCode : a.key.compareTo(b.key);
    });

  stdout.writeln('ML-9D WHOLE-CORPUS ML-8 PASS VALID');
  stdout.writeln('Evidence-bound facts: 120');
  stdout.writeln('Pairwise comparisons: $expectedPairs');
  stdout.writeln('Exact duplicates: 0');
  stdout.writeln('Unresolved review candidates: 0');
  stdout.writeln('Blocking corpus issues: 0');
  stdout.writeln('Adjudications required: 0');
  stdout.writeln('Concentration signals: ${concentration.length}');
  for (final signal in concentration) {
    stdout.writeln(
      'CONCENTRATION ${signal.code} key=${signal.key} '
      'count=${signal.count} '
      'share=${signal.share?.toStringAsFixed(6) ?? '-'}',
    );
  }
}

Future<Map<String, dynamic>> _readObject(String path) async {
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('ML-9D required file not found: $path');
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

void _fail(List<String> issues) {
  stderr.writeln(
    'ML-9D WHOLE-CORPUS ML-8 PASS INVALID with '
    '${issues.length} issue(s):',
  );
  for (final issue in issues) {
    stderr.writeln(' - $issue');
  }
  exitCode = 1;
}
