import 'dart:convert';
import 'dart:io';

import 'package:exam_platform/services/micro_learning/micro_fact_startup_suitability_gate_validator.dart';
import 'package:exam_platform/services/micro_learning/startup_pedagogy_evidence_validator.dart';
import 'package:exam_platform/services/micro_learning/startup_pedagogy_policy_validator.dart';
import 'package:exam_platform/services/micro_learning/startup_text_metrics.dart';

Future<void> main(List<String> args) async {
  const factPath = 'test/fixtures/micro_learning/valid_micro_fact_v1.json';
  const authorityPath = 'content/micro_learning/authority_registry_v1.json';
  const claimPolicyPath =
      'content/micro_learning/claim_semantics_policy_v1.json';
  const rightsPolicyPath =
      'content/micro_learning/rights_provenance_policy_v1.json';
  const rightsEvidencePath =
      'test/fixtures/micro_learning/valid_rights_evidence_v1.json';
  const curriculumPolicyPath =
      'content/micro_learning/canonical_curriculum_policy_v1.json';
  const curriculumRegistryPath =
      'content/micro_learning/canonical_curriculum_registry_v1.json';
  const pedagogyPolicyPath =
      'content/micro_learning/startup_pedagogy_policy_v1.json';
  const pedagogyEvidencePath =
      'test/fixtures/micro_learning/valid_startup_pedagogy_evidence_v1.json';

  final paths = <String>[
    factPath,
    authorityPath,
    claimPolicyPath,
    rightsPolicyPath,
    rightsEvidencePath,
    curriculumPolicyPath,
    curriculumRegistryPath,
    pedagogyPolicyPath,
    pedagogyEvidencePath,
  ];

  for (final path in paths) {
    if (!File(path).existsSync()) {
      stderr.writeln('ML-7 required file not found: ' + path);
      exitCode = 2;
      return;
    }
  }

  final fact = await _readObject(factPath);
  final authority = await _readObject(authorityPath);
  final claimPolicy = await _readObject(claimPolicyPath);
  final rightsPolicy = await _readObject(rightsPolicyPath);
  final rightsEvidence = await _readObject(rightsEvidencePath);
  final curriculumPolicy = await _readObject(curriculumPolicyPath);
  final curriculumRegistry = await _readObject(curriculumRegistryPath);
  final pedagogyPolicy = await _readObject(pedagogyPolicyPath);
  final pedagogyEvidence = await _readObject(pedagogyEvidencePath);

  if (exitCode != 0) return;

  final policyResult = const StartupPedagogyPolicyValidator().validateMap(
    pedagogyPolicy,
  );
  if (!policyResult.isValid) {
    _printIssues('ML-7 startup pedagogy policy', policyResult.issues);
    exitCode = 1;
    return;
  }

  final evidenceResult = const StartupPedagogyEvidenceValidator().validateMap(
    pedagogyEvidence,
  );
  if (!evidenceResult.isValid) {
    _printIssues('ML-7 startup pedagogy evidence', evidenceResult.issues);
    exitCode = 1;
    return;
  }

  final gateResult = const MicroFactStartupSuitabilityGateValidator()
      .validateMaps(
        microFact: fact,
        authorityRegistry: authority,
        claimPolicy: claimPolicy,
        rightsPolicy: rightsPolicy,
        rightsEvidence: rightsEvidence,
        curriculumPolicy: curriculumPolicy,
        curriculumRegistry: curriculumRegistry,
        curriculumEvidence: null,
        pedagogyPolicy: pedagogyPolicy,
        pedagogyEvidence: pedagogyEvidence,
      );

  if (!gateResult.isValid) {
    _printIssues('ML-7 startup suitability gate', gateResult.issues);
    exitCode = 1;
    return;
  }

  final display = Map<String, dynamic>.from(fact['display'] as Map);
  final shortVariant = display['shortVariant'] as String;

  stdout.writeln(
    'ML-7 STARTUP PEDAGOGY / READABILITY / ACCESSIBILITY GATES VALID',
  );
  stdout.writeln(
    'Policy version: ' + StartupPedagogyPolicyValidator.requiredPolicyVersion,
  );
  stdout.writeln(
    'Display words: ' +
        StartupTextMetrics.wordCount(
          display['displayText'] as String,
        ).toString(),
  );
  stdout.writeln(
    'Short words: ' + StartupTextMetrics.wordCount(shortVariant).toString(),
  );
  stdout.writeln(
    'Short computed read seconds: ' +
        StartupTextMetrics.readSeconds(shortVariant, 150).toString(),
  );
}

Future<Map<String, dynamic>> _readObject(String path) async {
  try {
    final decoded = jsonDecode(await File(path).readAsString());
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
  } on FormatException catch (error) {
    stderr.writeln('ML-7 invalid JSON in ' + path + ': ' + error.message);
    exitCode = 2;
    return <String, dynamic>{};
  }

  stderr.writeln('ML-7 JSON root must be an object: ' + path);
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
