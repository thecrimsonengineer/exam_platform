import 'dart:convert';
import 'dart:io';

import 'package:exam_platform/services/micro_learning/canonical_curriculum_policy_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const path = 'content/micro_learning/canonical_curriculum_policy_v1.json';
  const validator = CanonicalCurriculumPolicyValidator();

  Map<String, dynamic> load() =>
      jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

  Map<String, dynamic> clone() =>
      jsonDecode(jsonEncode(load())) as Map<String, dynamic>;

  test('frozen ML-6 curriculum policy passes', () {
    final result = validator.validateMap(load());
    expect(result.issues, isEmpty, reason: result.issues.join('\n'));
  });

  test('unknown nested policy field fails closed', () {
    final policy = clone();
    final principles = Map<String, dynamic>.from(policy['principles'] as Map);
    principles['shadowOverride'] = true;
    policy['principles'] = principles;

    final result = validator.validateMap(policy);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML6_POLICY_UNKNOWN_FIELD'),
    );
  });

  test('title inference cannot be enabled', () {
    final policy = clone();
    final principles = Map<String, dynamic>.from(policy['principles'] as Map);
    principles['inferMappingFromTitle'] = true;
    policy['principles'] = principles;

    final result = validator.validateMap(policy);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML6_POLICY_PRINCIPLE_WEAKENED'),
    );
  });

  test('legacy IDs cannot be enabled', () {
    final policy = clone();
    final principles = Map<String, dynamic>.from(policy['principles'] as Map);
    principles['allowLegacyIdsInMicroFact'] = true;
    policy['principles'] = principles;

    final result = validator.validateMap(policy);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML6_POLICY_PRINCIPLE_WEAKENED'),
    );
  });

  test('automatic remap cannot be enabled', () {
    final policy = clone();
    final principles = Map<String, dynamic>.from(policy['principles'] as Map);
    principles['allowAutomaticRemap'] = true;
    policy['principles'] = principles;

    final result = validator.validateMap(policy);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML6_POLICY_PRINCIPLE_WEAKENED'),
    );
  });

  test('blueprint domain or competency counts cannot drift', () {
    final policy = clone();
    final blueprint = Map<String, dynamic>.from(
      policy['canonicalBlueprint'] as Map,
    );
    blueprint['expectedCompetencyCount'] = 48;
    policy['canonicalBlueprint'] = blueprint;

    final result = validator.validateMap(policy);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML6_POLICY_BLUEPRINT_COUNTS'),
    );
  });

  test('canonical ID patterns cannot be broadened', () {
    final policy = clone();
    final patterns = Map<String, dynamic>.from(policy['idPatterns'] as Map);
    patterns['competencyId'] = r'^.+$';
    policy['idPatterns'] = patterns;

    final result = validator.validateMap(policy);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML6_POLICY_ID_PATTERN_WEAKENED'),
    );
  });

  test('deprecated nodes cannot become selectable', () {
    final policy = clone();
    final statuses = Map<String, dynamic>.from(policy['nodeStatuses'] as Map);
    statuses['selectableStatuses'] = ['active', 'deprecated'];
    policy['nodeStatuses'] = statuses;

    final result = validator.validateMap(policy);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML6_POLICY_NODE_STATUS_WEAKENED'),
    );
  });

  test('mapping evidence freshness cannot be silently widened', () {
    final policy = clone();
    final evidence = Map<String, dynamic>.from(policy['evidenceRules'] as Map);
    evidence['maxEvidenceAgeDays'] = 3650;
    policy['evidenceRules'] = evidence;

    final result = validator.validateMap(policy);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML6_POLICY_EVIDENCE_RULE_WEAKENED'),
    );
  });

  test('mapping drift invalidation cannot be disabled', () {
    final policy = clone();
    final drift = Map<String, dynamic>.from(policy['driftRules'] as Map);
    drift['nodeDeprecationInvalidatesEvidence'] = false;
    policy['driftRules'] = drift;

    final result = validator.validateMap(policy);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML6_POLICY_DRIFT_RULE_WEAKENED'),
    );
  });
}
