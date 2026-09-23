import 'dart:convert';
import 'dart:io';

import 'package:exam_platform/services/micro_learning/canonical_curriculum_policy_validator.dart';
import 'package:exam_platform/services/micro_learning/canonical_curriculum_registry_validator.dart';
import 'package:exam_platform/services/micro_learning/curriculum_mapping_evidence_validator.dart';
import 'package:exam_platform/services/micro_learning/micro_fact_curriculum_gate_validator.dart';

Future<void> main(List<String> args) async {
  const factPath = 'test/fixtures/micro_learning/valid_micro_fact_v1.json';
  const mappedFactPath =
      'test/fixtures/micro_learning/valid_mapped_micro_fact_v1.json';
  const rightsEvidencePath =
      'test/fixtures/micro_learning/valid_rights_evidence_v1.json';
  const mappingEvidencePath =
      'test/fixtures/micro_learning/valid_curriculum_mapping_evidence_v1.json';
  const authorityRegistryPath =
      'content/micro_learning/authority_registry_v1.json';
  const claimPolicyPath =
      'content/micro_learning/claim_semantics_policy_v1.json';
  const rightsPolicyPath =
      'content/micro_learning/rights_provenance_policy_v1.json';
  const curriculumPolicyPath =
      'content/micro_learning/canonical_curriculum_policy_v1.json';
  const productionRegistryPath =
      'content/micro_learning/canonical_curriculum_registry_v1.json';
  const testRegistryPath =
      'test/fixtures/micro_learning/canonical_curriculum_registry_test_v1.json';

  final requiredPaths = <String>[
    factPath,
    mappedFactPath,
    rightsEvidencePath,
    mappingEvidencePath,
    authorityRegistryPath,
    claimPolicyPath,
    rightsPolicyPath,
    curriculumPolicyPath,
    productionRegistryPath,
    testRegistryPath,
  ];

  for (final path in requiredPaths) {
    if (!File(path).existsSync()) {
      stderr.writeln('ML-6 required file not found: ' + path);
      exitCode = 2;
      return;
    }
  }

  final fact = await _readObject(factPath);
  final mappedFact = await _readObject(mappedFactPath);
  final rightsEvidence = await _readObject(rightsEvidencePath);
  final mappingEvidence = await _readObject(mappingEvidencePath);
  final authorityRegistry = await _readObject(authorityRegistryPath);
  final claimPolicy = await _readObject(claimPolicyPath);
  final rightsPolicy = await _readObject(rightsPolicyPath);
  final curriculumPolicy = await _readObject(curriculumPolicyPath);
  final productionRegistry = await _readObject(productionRegistryPath);
  final testRegistry = await _readObject(testRegistryPath);

  if (exitCode != 0) return;

  final policyResult =
      const CanonicalCurriculumPolicyValidator().validateMap(
        curriculumPolicy,
      );
  if (!policyResult.isValid) {
    _printIssues('ML-6 curriculum policy', policyResult.issues);
    exitCode = 1;
    return;
  }

  final productionRegistryResult =
      const CanonicalCurriculumRegistryValidator().validateMap(
        productionRegistry,
      );
  if (!productionRegistryResult.isValid) {
    _printIssues(
      'ML-6 production navigation registry',
      productionRegistryResult.issues,
    );
    exitCode = 1;
    return;
  }

  final testRegistryResult =
      const CanonicalCurriculumRegistryValidator().validateMap(
        testRegistry,
      );
  if (!testRegistryResult.isValid) {
    _printIssues(
      'ML-6 test navigation registry',
      testRegistryResult.issues,
    );
    exitCode = 1;
    return;
  }

  final evidenceResult =
      const CurriculumMappingEvidenceValidator().validateMap(
        mappingEvidence,
      );
  if (!evidenceResult.isValid) {
    _printIssues('ML-6 mapping evidence', evidenceResult.issues);
    exitCode = 1;
    return;
  }

  final generalResult = const MicroFactCurriculumGateValidator().validateMaps(
    microFact: fact,
    authorityRegistry: authorityRegistry,
    claimPolicy: claimPolicy,
    rightsPolicy: rightsPolicy,
    rightsEvidence: rightsEvidence,
    curriculumPolicy: curriculumPolicy,
    curriculumRegistry: productionRegistry,
    curriculumEvidence: null,
  );
  if (!generalResult.isValid) {
    _printIssues('ML-6 general MicroFact gate', generalResult.issues);
    exitCode = 1;
    return;
  }

  final mappedResult = const MicroFactCurriculumGateValidator().validateMaps(
    microFact: mappedFact,
    authorityRegistry: authorityRegistry,
    claimPolicy: claimPolicy,
    rightsPolicy: rightsPolicy,
    rightsEvidence: rightsEvidence,
    curriculumPolicy: curriculumPolicy,
    curriculumRegistry: testRegistry,
    curriculumEvidence: mappingEvidence,
  );
  if (!mappedResult.isValid) {
    _printIssues('ML-6 mapped MicroFact gate', mappedResult.issues);
    exitCode = 1;
    return;
  }

  stdout.writeln('ML-6 CANONICAL CURRICULUM MAPPING GATES VALID');
  stdout.writeln(
    'Blueprint version: ' +
        CanonicalCurriculumPolicyValidator.requiredBlueprintVersion,
  );
  stdout.writeln(
    'Navigation registry version: ' +
        CanonicalCurriculumRegistryValidator.requiredRegistryVersion,
  );
  stdout.writeln(
    'Production navigation population: ' +
        productionRegistry['populationStatus'].toString(),
  );
  stdout.writeln(
    'Production registered topics: ' +
        productionRegistry['topicCount'].toString(),
  );
  stdout.writeln(
    'Production registered subtopics: ' +
        productionRegistry['subtopicCount'].toString(),
  );
}

Future<Map<String, dynamic>> _readObject(String path) async {
  try {
    final decoded = jsonDecode(await File(path).readAsString());
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
  } on FormatException catch (error) {
    stderr.writeln('ML-6 invalid JSON in ' + path + ': ' + error.message);
    exitCode = 2;
    return <String, dynamic>{};
  }

  stderr.writeln('ML-6 JSON root must be an object: ' + path);
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
