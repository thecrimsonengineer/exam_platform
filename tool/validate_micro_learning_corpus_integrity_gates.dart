import 'dart:convert';
import 'dart:io';

import 'package:exam_platform/services/micro_learning/duplicate_contradiction_policy_validator.dart';
import 'package:exam_platform/services/micro_learning/micro_fact_corpus_comparison.dart';
import 'package:exam_platform/services/micro_learning/micro_fact_corpus_integrity_validator.dart';

Future<void> main(List<String> args) async {
  const policyPath =
      'content/micro_learning/duplicate_contradiction_policy_v1.json';
  const basePath = 'test/fixtures/micro_learning/valid_micro_fact_v1.json';
  const distinctPath =
      'test/fixtures/micro_learning/distinct_micro_fact_v1.json';
  const nearPath =
      'test/fixtures/micro_learning/near_duplicate_micro_fact_v1.json';

  for (final path in [policyPath, basePath, distinctPath, nearPath]) {
    if (!File(path).existsSync()) {
      stderr.writeln('ML-8 required file not found: ' + path);
      exitCode = 2;
      return;
    }
  }

  final policy = await _readObject(policyPath);
  final base = await _readObject(basePath);
  final distinct = await _readObject(distinctPath);
  final near = await _readObject(nearPath);

  if (exitCode != 0) return;

  final policyResult = const DuplicateContradictionPolicyValidator()
      .validateMap(policy);
  if (!policyResult.isValid) {
    _printIssues('ML-8 duplicate/contradiction policy', policyResult.issues);
    exitCode = 1;
    return;
  }

  final validator = const MicroFactCorpusIntegrityValidator();

  final distinctResult = validator.validate(
    facts: [base, distinct],
    policy: policy,
  );
  if (!distinctResult.isValid) {
    _printIssues('ML-8 distinct corpus', distinctResult.issues);
    exitCode = 1;
    return;
  }

  final comparison = const MicroFactCorpusComparison();
  final pair = comparison.compare(left: base, right: near, policy: policy);

  if (!pair.requiresAdjudication || pair.hasExactDuplicate) {
    stderr.writeln(
      'ML-8 near-duplicate fixture did not produce the expected review candidate.',
    );
    exitCode = 1;
    return;
  }

  final ordered = [base, near]
    ..sort(
      (a, b) => MicroFactCorpusComparison.factVersionKey(
        a,
      ).compareTo(MicroFactCorpusComparison.factVersionKey(b)),
    );

  Map<String, dynamic> ref(Map<String, dynamic> fact) => {
    'microFactId': fact['microFactId'],
    'contentVersion': fact['contentVersion'],
    'comparisonFingerprintSha256':
        MicroFactCorpusComparison.comparisonFingerprint(fact),
  };

  final evidence = <String, dynamic>{
    'schemaVersion': 1,
    'evidenceId': 'mfce_cli_pair_0001',
    'policyVersion': '1.0.0',
    'pairKey': pair.pairKey,
    'left': ref(ordered[0]),
    'right': ref(ordered[1]),
    'detectedSignals': pair.signals.toList()..sort(),
    'decision': 'distinct_valid',
    'review': {
      'status': 'pass',
      'reviewerRole': 'content_governance_reviewer',
      'humanReviewed': true,
      'rationale':
          'CLI fixture demonstrates a human-reviewed coexistence decision.',
      'reviewedAt': '2026-09-23',
      'nextReviewDueAt': '2027-09-23',
    },
  };

  final adjudicatedResult = validator.validate(
    facts: [base, near],
    policy: policy,
    adjudications: [evidence],
  );

  if (!adjudicatedResult.isValid) {
    _printIssues('ML-8 adjudicated candidate corpus', adjudicatedResult.issues);
    exitCode = 1;
    return;
  }

  stdout.writeln('ML-8 DUPLICATE / CONTRADICTION DETECTION VALID');
  stdout.writeln(
    'Policy version: ' +
        DuplicateContradictionPolicyValidator.requiredPolicyVersion,
  );
  stdout.writeln(
    'Candidate pair: ' + adjudicatedResult.reviewCandidates.single.pairKey,
  );
  stdout.writeln(
    'Signals: ' +
        (adjudicatedResult.reviewCandidates.single.signals.toList()..sort())
            .join(', '),
  );
  stdout.writeln(
    'Distinct corpus concentration signals: ' +
        distinctResult.concentrationSignals.length.toString(),
  );
}

Future<Map<String, dynamic>> _readObject(String path) async {
  try {
    final decoded = jsonDecode(await File(path).readAsString());
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
  } on FormatException catch (error) {
    stderr.writeln('ML-8 invalid JSON in ' + path + ': ' + error.message);
    exitCode = 2;
    return <String, dynamic>{};
  }

  stderr.writeln('ML-8 JSON root must be an object: ' + path);
  exitCode = 2;
  return <String, dynamic>{};
}

void _printIssues(String label, Iterable<dynamic> issues) {
  final list = issues.toList();
  stderr.writeln(
    label + ' validation failed with ' + list.length.toString() + ' issue(s):',
  );
  for (final issue in list) {
    stderr.writeln(' - ' + issue.toString());
  }
}
