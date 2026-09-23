import 'dart:convert';
import 'dart:io';

import 'package:exam_platform/services/micro_learning/canonical_curriculum_registry_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const productionPath =
      'content/micro_learning/canonical_curriculum_registry_v1.json';
  const testPath =
      'test/fixtures/micro_learning/canonical_curriculum_registry_test_v1.json';
  const validator = CanonicalCurriculumRegistryValidator();

  Map<String, dynamic> load(String path) =>
      jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

  Map<String, dynamic> clone(String path) =>
      jsonDecode(jsonEncode(load(path))) as Map<String, dynamic>;

  test('production domain/competency-only registry passes', () {
    final result = validator.validateMap(load(productionPath));
    expect(result.issues, isEmpty, reason: result.issues.join('\n'));
  });

  test('test navigation registry with canonical nodes passes', () {
    final result = validator.validateMap(load(testPath));
    expect(result.issues, isEmpty, reason: result.issues.join('\n'));
  });

  test('topic count mismatch fails closed', () {
    final registry = clone(testPath);
    registry['topicCount'] = 99;

    final result = validator.validateMap(registry);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML6_REGISTRY_TOPIC_COUNT'),
    );
  });

  test('population state cannot claim empty registry while nodes exist', () {
    final registry = clone(testPath);
    registry['populationStatus'] = 'domain_competency_only';

    final result = validator.validateMap(registry);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML6_REGISTRY_POPULATION_MISMATCH'),
    );
  });

  test('topic cannot point to unknown canonical competency', () {
    final registry = clone(testPath);
    final topics = (registry['topics'] as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    topics.first['competencyId'] = 'd01_c99';
    registry['topics'] = topics;

    final result = validator.validateMap(registry);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML6_REGISTRY_TOPIC_COMPETENCY'),
    );
  });

  test('topic competency must belong to declared domain', () {
    final registry = clone(testPath);
    final topics = (registry['topics'] as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    topics.first['domainId'] = 'd02';
    registry['topics'] = topics;

    final result = validator.validateMap(registry);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML6_REGISTRY_COMPETENCY_PARENT'),
    );
  });

  test('topic ID prefix must match competency parent', () {
    final registry = clone(testPath);
    final topics = (registry['topics'] as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    topics.first['id'] = 'd01_c04_t01';
    registry['topics'] = topics;

    final result = validator.validateMap(registry);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML6_REGISTRY_TOPIC_PARENTAGE'),
    );
  });

  test('subtopic ID prefix must match topic parent', () {
    final registry = clone(testPath);
    final topics = (registry['topics'] as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    final subtopics = (topics.first['subtopics'] as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    subtopics.first['id'] = 'd01_c03_t02_s01';
    topics.first['subtopics'] = subtopics;
    registry['topics'] = topics;

    final result = validator.validateMap(registry);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML6_REGISTRY_SUBTOPIC_PARENTAGE'),
    );
  });

  test('registry policy cannot allow automatic remap', () {
    final registry = clone(productionPath);
    final policy = Map<String, dynamic>.from(registry['policy'] as Map);
    policy['automaticRemap'] = true;
    registry['policy'] = policy;

    final result = validator.validateMap(registry);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML6_REGISTRY_POLICY_WEAKENED'),
    );
  });
}
