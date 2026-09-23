import 'dart:convert';
import 'dart:io';

import 'package:exam_platform/services/micro_learning/startup_pedagogy_policy_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const path = 'content/micro_learning/startup_pedagogy_policy_v1.json';
  const validator = StartupPedagogyPolicyValidator();

  Map<String, dynamic> load() =>
      jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

  Map<String, dynamic> clone() =>
      jsonDecode(jsonEncode(load())) as Map<String, dynamic>;

  test('frozen ML-7 startup pedagogy policy passes', () {
    final result = validator.validateMap(load());
    expect(result.issues, isEmpty, reason: result.issues.join('\n'));
  });

  test('unknown nested field fails closed', () {
    final policy = clone();
    final rules = Map<String, dynamic>.from(policy['textRules'] as Map);
    rules['shadowOverride'] = true;
    policy['textRules'] = rules;

    final result = validator.validateMap(policy);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML7_POLICY_UNKNOWN_FIELD'),
    );
  });

  test('startup cannot be artificially delayed', () {
    final policy = clone();
    final contract = Map<String, dynamic>.from(
      policy['startupContract'] as Map,
    );
    contract['artificialDelayAllowed'] = true;
    policy['startupContract'] = contract;

    final result = validator.validateMap(policy);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML7_POLICY_STARTUP_CONTRACT_WEAKENED'),
    );
  });

  test('micro-learning cannot introduce a runtime network read', () {
    final policy = clone();
    final contract = Map<String, dynamic>.from(
      policy['startupContract'] as Map,
    );
    contract['runtimeNetworkReadAllowed'] = true;
    policy['startupContract'] = contract;

    final result = validator.validateMap(policy);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML7_POLICY_STARTUP_CONTRACT_WEAKENED'),
    );
  });

  test('short copy maximum cannot be broadened', () {
    final policy = clone();
    final rules = Map<String, dynamic>.from(policy['textRules'] as Map);
    final short = Map<String, dynamic>.from(rules['shortVariant'] as Map);
    short['maxWords'] = 40;
    rules['shortVariant'] = short;
    policy['textRules'] = rules;

    final result = validator.validateMap(policy);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML7_POLICY_SHORT_RULES_WEAKENED'),
    );
  });

  test('short copy compression cannot be weakened', () {
    final policy = clone();
    final rules = Map<String, dynamic>.from(policy['textRules'] as Map);
    final short = Map<String, dynamic>.from(rules['shortVariant'] as Map);
    short['maxWordRatioToDisplay'] = 1.0;
    rules['shortVariant'] = short;
    policy['textRules'] = rules;

    final result = validator.validateMap(policy);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML7_POLICY_SHORT_RULES_WEAKENED'),
    );
  });

  test('HTML cannot be enabled', () {
    final policy = clone();
    final rules = Map<String, dynamic>.from(policy['plainTextRules'] as Map);
    rules['htmlAllowed'] = true;
    policy['plainTextRules'] = rules;

    final result = validator.validateMap(policy);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML7_POLICY_PLAIN_TEXT_WEAKENED'),
    );
  });

  test('visual meaning cannot depend on motion', () {
    final policy = clone();
    final rules = Map<String, dynamic>.from(
      policy['visualIndependenceRules'] as Map,
    );
    rules['meaningMayDependOnMotion'] = true;
    policy['visualIndependenceRules'] = rules;

    final result = validator.validateMap(policy);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML7_POLICY_VISUAL_RULES_WEAKENED'),
    );
  });

  test('high assessment sensitivity cannot become startup eligible', () {
    final policy = clone();
    final rules = Map<String, dynamic>.from(policy['assessmentRules'] as Map);
    rules['blockedStartupSensitivities'] = ['block_during_linked_assessment'];
    policy['assessmentRules'] = rules;

    final result = validator.validateMap(policy);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML7_POLICY_ASSESSMENT_RULES_WEAKENED'),
    );
  });

  test('precision review cannot be disabled', () {
    final policy = clone();
    final rules = Map<String, dynamic>.from(policy['precisionRules'] as Map);
    rules['safetyCriticalRequiresHumanPrecisionReview'] = false;
    policy['precisionRules'] = rules;

    final result = validator.validateMap(policy);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML7_POLICY_PRECISION_RULES_WEAKENED'),
    );
  });

  test('reduced-motion meaning equivalence cannot be disabled', () {
    final policy = clone();
    final rules = Map<String, dynamic>.from(
      policy['accessibilityRules'] as Map,
    );
    rules['reducedMotionMeaningMustBeEquivalent'] = false;
    policy['accessibilityRules'] = rules;

    final result = validator.validateMap(policy);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML7_POLICY_ACCESSIBILITY_RULES_WEAKENED'),
    );
  });

  test('evidence freshness cannot be silently widened', () {
    final policy = clone();
    final rules = Map<String, dynamic>.from(policy['evidenceRules'] as Map);
    rules['maxEvidenceAgeDays'] = 3650;
    policy['evidenceRules'] = rules;

    final result = validator.validateMap(policy);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML7_POLICY_EVIDENCE_RULES_WEAKENED'),
    );
  });

  test('display drift invalidation cannot be disabled', () {
    final policy = clone();
    final rules = Map<String, dynamic>.from(policy['driftRules'] as Map);
    rules['displayTextChangeInvalidatesEvidence'] = false;
    policy['driftRules'] = rules;

    final result = validator.validateMap(policy);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML7_POLICY_DRIFT_RULES_WEAKENED'),
    );
  });
}
