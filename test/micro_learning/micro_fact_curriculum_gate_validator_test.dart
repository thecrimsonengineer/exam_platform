import 'dart:convert';
import 'dart:io';

import 'package:exam_platform/services/micro_learning/curriculum_mapping_evidence_validator.dart';
import 'package:exam_platform/services/micro_learning/micro_fact_curriculum_gate_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const factPath = 'test/fixtures/micro_learning/valid_micro_fact_v1.json';
  const mappedFactPath =
      'test/fixtures/micro_learning/valid_mapped_micro_fact_v1.json';
  const rightsEvidencePath =
      'test/fixtures/micro_learning/valid_rights_evidence_v1.json';
  const mappingEvidencePath =
      'test/fixtures/micro_learning/valid_curriculum_mapping_evidence_v1.json';
  const registryPath = 'content/micro_learning/authority_registry_v1.json';
  const claimPolicyPath =
      'content/micro_learning/claim_semantics_policy_v1.json';
  const rightsPolicyPath =
      'content/micro_learning/rights_provenance_policy_v1.json';
  const curriculumPolicyPath =
      'content/micro_learning/canonical_curriculum_policy_v1.json';
  const productionCurriculumRegistryPath =
      'content/micro_learning/canonical_curriculum_registry_v1.json';
  const testCurriculumRegistryPath =
      'test/fixtures/micro_learning/canonical_curriculum_registry_test_v1.json';

  const validator = MicroFactCurriculumGateValidator();

  Map<String, dynamic> loadJson(String path) =>
      jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

  Map<String, dynamic> cloneMap(Map<String, dynamic> value) =>
      jsonDecode(jsonEncode(value)) as Map<String, dynamic>;

  Map<String, dynamic> loadFact() => loadJson(factPath);
  Map<String, dynamic> loadMappedFact() => loadJson(mappedFactPath);
  Map<String, dynamic> loadRightsEvidence() => loadJson(rightsEvidencePath);
  Map<String, dynamic> loadMappingEvidence() => loadJson(mappingEvidencePath);
  Map<String, dynamic> loadAuthorityRegistry() => loadJson(registryPath);
  Map<String, dynamic> loadClaimPolicy() => loadJson(claimPolicyPath);
  Map<String, dynamic> loadRightsPolicy() => loadJson(rightsPolicyPath);
  Map<String, dynamic> loadCurriculumPolicy() => loadJson(curriculumPolicyPath);
  Map<String, dynamic> loadProductionRegistry() =>
      loadJson(productionCurriculumRegistryPath);
  Map<String, dynamic> loadTestRegistry() =>
      loadJson(testCurriculumRegistryPath);

  MicroFactCurriculumGateResult validate(
    Map<String, dynamic> fact, {
    Map<String, dynamic>? curriculumEvidence,
    Map<String, dynamic>? curriculumRegistry,
  }) {
    return validator.validateMaps(
      microFact: fact,
      authorityRegistry: loadAuthorityRegistry(),
      claimPolicy: loadClaimPolicy(),
      rightsPolicy: loadRightsPolicy(),
      rightsEvidence: loadRightsEvidence(),
      curriculumPolicy: loadCurriculumPolicy(),
      curriculumRegistry: curriculumRegistry ?? loadProductionRegistry(),
      curriculumEvidence: curriculumEvidence,
    );
  }

  test('general MicroFact passes without curriculum evidence', () {
    final result = validate(loadFact());

    expect(result.issues, isEmpty, reason: result.issues.join('\n'));
  });

  test('general MicroFact cannot carry curriculum IDs', () {
    final fact = loadFact();
    final curriculum = Map<String, dynamic>.from(fact['curriculum'] as Map);
    curriculum
      ..['domainId'] = 'd01'
      ..['competencyId'] = 'd01_c03';
    fact['curriculum'] = curriculum;

    final result = validate(fact);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML6_GENERAL_SCOPE_HAS_MAPPING'),
    );
  });

  test('general MicroFact cannot carry mapping evidence', () {
    final result = validate(
      loadFact(),
      curriculumEvidence: loadMappingEvidence(),
    );

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML6_GENERAL_SCOPE_EVIDENCE_FORBIDDEN'),
    );
  });

  test('competency-level mapped fact can pass production registry', () {
    final fact = loadMappedFact();
    final curriculum = Map<String, dynamic>.from(fact['curriculum'] as Map);
    curriculum
      ..['topicId'] = null
      ..['subtopicId'] = null;
    fact['curriculum'] = curriculum;

    final evidence = loadMappingEvidence();
    final mapping = Map<String, dynamic>.from(evidence['mapping'] as Map);
    mapping
      ..['topicId'] = null
      ..['subtopicId'] = null
      ..['mappingKey'] = CurriculumMappingEvidenceValidator.mappingKey(
        domainId: 'd01',
        competencyId: 'd01_c03',
      );
    evidence['mapping'] = mapping;

    final result = validate(fact, curriculumEvidence: evidence);

    expect(result.issues, isEmpty, reason: result.issues.join('\n'));
  });

  test('full Topic/Subtopic mapped fact passes explicit test registry', () {
    final result = validate(
      loadMappedFact(),
      curriculumEvidence: loadMappingEvidence(),
      curriculumRegistry: loadTestRegistry(),
    );

    expect(result.issues, isEmpty, reason: result.issues.join('\n'));
  });

  test('mapped fact cannot use unknown canonical competency', () {
    final fact = loadMappedFact();
    final curriculum = Map<String, dynamic>.from(fact['curriculum'] as Map);
    curriculum
      ..['competencyId'] = 'd01_c99'
      ..['topicId'] = null
      ..['subtopicId'] = null;
    fact['curriculum'] = curriculum;

    final result = validate(fact);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML6_COMPETENCY_NOT_CANONICAL'),
    );
  });

  test('competency must belong to declared domain', () {
    final fact = loadMappedFact();
    final curriculum = Map<String, dynamic>.from(fact['curriculum'] as Map);
    curriculum
      ..['domainId'] = 'd02'
      ..['topicId'] = null
      ..['subtopicId'] = null;
    fact['curriculum'] = curriculum;

    final result = validate(fact);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML6_COMPETENCY_WRONG_PARENT'),
    );
  });

  test('production registry blocks unregistered Topic mapping', () {
    final result = validate(
      loadMappedFact(),
      curriculumEvidence: loadMappingEvidence(),
    );

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML6_TOPIC_NOT_REGISTERED'),
    );
  });

  test('unregistered Subtopic fails closed', () {
    final fact = loadMappedFact();
    final curriculum = Map<String, dynamic>.from(fact['curriculum'] as Map);
    curriculum['subtopicId'] = 'd01_c03_t01_s99';
    fact['curriculum'] = curriculum;

    final evidence = loadMappingEvidence();
    final mapping = Map<String, dynamic>.from(evidence['mapping'] as Map);
    mapping
      ..['subtopicId'] = 'd01_c03_t01_s99'
      ..['mappingKey'] = CurriculumMappingEvidenceValidator.mappingKey(
        domainId: 'd01',
        competencyId: 'd01_c03',
        topicId: 'd01_c03_t01',
        subtopicId: 'd01_c03_t01_s99',
      );
    evidence['mapping'] = mapping;

    final result = validate(
      fact,
      curriculumEvidence: evidence,
      curriculumRegistry: loadTestRegistry(),
    );

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML6_SUBTOPIC_NOT_REGISTERED'),
    );
  });

  test('deprecated Topic cannot receive MicroFact mapping', () {
    final fact = loadMappedFact();
    final curriculum = Map<String, dynamic>.from(fact['curriculum'] as Map);
    curriculum
      ..['topicId'] = 'd01_c03_t02'
      ..['subtopicId'] = null;
    fact['curriculum'] = curriculum;

    final evidence = loadMappingEvidence();
    final mapping = Map<String, dynamic>.from(evidence['mapping'] as Map);
    mapping
      ..['topicId'] = 'd01_c03_t02'
      ..['subtopicId'] = null
      ..['mappingKey'] = CurriculumMappingEvidenceValidator.mappingKey(
        domainId: 'd01',
        competencyId: 'd01_c03',
        topicId: 'd01_c03_t02',
      );
    evidence['mapping'] = mapping;

    final result = validate(
      fact,
      curriculumEvidence: evidence,
      curriculumRegistry: loadTestRegistry(),
    );

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML6_TOPIC_NOT_ACTIVE'),
    );
  });

  test('retired Subtopic cannot receive MicroFact mapping', () {
    final fact = loadMappedFact();
    final curriculum = Map<String, dynamic>.from(fact['curriculum'] as Map);
    curriculum['subtopicId'] = 'd01_c03_t01_s02';
    fact['curriculum'] = curriculum;

    final evidence = loadMappingEvidence();
    final mapping = Map<String, dynamic>.from(evidence['mapping'] as Map);
    mapping
      ..['subtopicId'] = 'd01_c03_t01_s02'
      ..['mappingKey'] = CurriculumMappingEvidenceValidator.mappingKey(
        domainId: 'd01',
        competencyId: 'd01_c03',
        topicId: 'd01_c03_t01',
        subtopicId: 'd01_c03_t01_s02',
      );
    evidence['mapping'] = mapping;

    final result = validate(
      fact,
      curriculumEvidence: evidence,
      curriculumRegistry: loadTestRegistry(),
    );

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML6_SUBTOPIC_NOT_ACTIVE'),
    );
  });

  test('published mapped fact cannot omit mapping evidence', () {
    final fact = loadMappedFact();
    final curriculum = Map<String, dynamic>.from(fact['curriculum'] as Map);
    curriculum
      ..['topicId'] = null
      ..['subtopicId'] = null;
    fact['curriculum'] = curriculum;

    final result = validate(fact);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML6_MAPPING_EVIDENCE_REQUIRED'),
    );
  });

  test('evidence from another content version is rejected', () {
    final evidence = loadMappingEvidence();
    evidence['contentVersion'] = 2;

    final result = validate(
      loadMappedFact(),
      curriculumEvidence: evidence,
      curriculumRegistry: loadTestRegistry(),
    );

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML6_EVIDENCE_CONTENT_VERSION_MISMATCH'),
    );
  });

  test('mapping ID drift invalidates old evidence', () {
    final fact = loadMappedFact();
    final curriculum = Map<String, dynamic>.from(fact['curriculum'] as Map);
    curriculum
      ..['topicId'] = null
      ..['subtopicId'] = null;
    fact['curriculum'] = curriculum;

    final result = validate(
      fact,
      curriculumEvidence: loadMappingEvidence(),
      curriculumRegistry: loadTestRegistry(),
    );

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML6_EVIDENCE_MAPPING_DRIFT'),
    );
  });

  test('startup mapped fact requires passing mapping evidence', () {
    final evidence = loadMappingEvidence();
    final review = Map<String, dynamic>.from(evidence['review'] as Map);
    review['status'] = 'pending';
    evidence['review'] = review;

    final result = validate(
      loadMappedFact(),
      curriculumEvidence: evidence,
      curriculumRegistry: loadTestRegistry(),
    );

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML6_STARTUP_MAPPING_EVIDENCE_NOT_PASS'),
    );
  });

  test('mapping review cannot occur after final fact review', () {
    final evidence = loadMappingEvidence();
    final review = Map<String, dynamic>.from(evidence['review'] as Map);
    review
      ..['reviewedAt'] = '2026-09-24'
      ..['nextReviewDueAt'] = '2027-09-24';
    evidence['review'] = review;

    final result = validate(
      loadMappedFact(),
      curriculumEvidence: evidence,
      curriculumRegistry: loadTestRegistry(),
    );

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML6_MAPPING_REVIEW_AFTER_FACT_REVIEW'),
    );
  });

  test('formal mapping evidence schema remains fail closed', () {
    final schema = loadJson(
      'content/micro_learning/curriculum_mapping_evidence_schema_v1.json',
    );
    final extension = Map<String, dynamic>.from(schema['x-csp11'] as Map);

    expect(schema['additionalProperties'], isFalse);
    expect(extension['phase'], 'ML-6');
    expect(extension['curriculumPolicyVersion'], '1.0.0');
    expect(extension['failClosed'], isTrue);
  });
}
