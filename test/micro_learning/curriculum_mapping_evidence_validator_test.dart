import 'dart:convert';
import 'dart:io';

import 'package:exam_platform/services/micro_learning/curriculum_mapping_evidence_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const path =
      'test/fixtures/micro_learning/valid_curriculum_mapping_evidence_v1.json';
  const validator = CurriculumMappingEvidenceValidator();

  Map<String, dynamic> load() =>
      jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

  Map<String, dynamic> clone() =>
      jsonDecode(jsonEncode(load())) as Map<String, dynamic>;

  test('valid curriculum mapping evidence passes', () {
    final result = validator.validateMap(load());
    expect(result.issues, isEmpty, reason: result.issues.join('\n'));
  });

  test('unknown evidence field fails closed', () {
    final evidence = clone();
    evidence['shadowOverride'] = true;

    final result = validator.validateMap(evidence);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML6_EVIDENCE_UNKNOWN_FIELD'),
    );
  });

  test('mapping key must exactly fingerprint IDs', () {
    final evidence = clone();
    final mapping = Map<String, dynamic>.from(evidence['mapping'] as Map);
    mapping['mappingKey'] = 'wrong';
    evidence['mapping'] = mapping;

    final result = validator.validateMap(evidence);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML6_EVIDENCE_MAPPING_KEY'),
    );
  });

  test('subtopic mapping requires topic', () {
    final evidence = clone();
    final mapping = Map<String, dynamic>.from(evidence['mapping'] as Map);
    mapping
      ..['topicId'] = null
      ..['mappingKey'] = 'd01|d01_c03|-|d01_c03_t01_s01';
    evidence['mapping'] = mapping;

    final result = validator.validateMap(evidence);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML6_EVIDENCE_SUBTOPIC_REQUIRES_TOPIC'),
    );
  });

  test('passing evidence requires human review and concept alignment', () {
    final evidence = clone();
    final review = Map<String, dynamic>.from(evidence['review'] as Map);
    review
      ..['humanReviewed'] = false
      ..['conceptAlignmentConfirmed'] = false;
    evidence['review'] = review;

    final result = validator.validateMap(evidence);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML6_EVIDENCE_PASS_REQUIREMENTS'),
    );
  });

  test('passing evidence requires review dates', () {
    final evidence = clone();
    final review = Map<String, dynamic>.from(evidence['review'] as Map);
    review
      ..['reviewedAt'] = null
      ..['nextReviewDueAt'] = null;
    evidence['review'] = review;

    final result = validator.validateMap(evidence);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML6_EVIDENCE_PASS_REQUIREMENTS'),
    );
  });

  test('review due date cannot precede review date', () {
    final evidence = clone();
    final review = Map<String, dynamic>.from(evidence['review'] as Map);
    review['nextReviewDueAt'] = '2026-09-22';
    evidence['review'] = review;

    final result = validator.validateMap(evidence);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML6_EVIDENCE_REVIEW_DATE_ORDER'),
    );
  });

  test('blueprint version is frozen', () {
    final evidence = clone();
    evidence['blueprintVersion'] = 'OLD';

    final result = validator.validateMap(evidence);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML6_EVIDENCE_BLUEPRINT_VERSION'),
    );
  });

  test('navigation registry version is frozen', () {
    final evidence = clone();
    evidence['navigationRegistryVersion'] = '2.0.0';

    final result = validator.validateMap(evidence);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML6_EVIDENCE_REGISTRY_VERSION'),
    );
  });
}
