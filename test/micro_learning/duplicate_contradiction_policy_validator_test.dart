import 'dart:convert';
import 'dart:io';

import 'package:exam_platform/services/micro_learning/duplicate_contradiction_policy_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const path = 'content/micro_learning/duplicate_contradiction_policy_v1.json';
  const validator = DuplicateContradictionPolicyValidator();

  Map<String, dynamic> load() =>
      jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

  Map<String, dynamic> clone() =>
      jsonDecode(jsonEncode(load())) as Map<String, dynamic>;

  test('frozen ML-8 duplicate contradiction policy passes', () {
    final result = validator.validateMap(load());
    expect(result.issues, isEmpty, reason: result.issues.join('\n'));
  });

  test('unknown nested policy field fails closed', () {
    final policy = clone();
    final rules = Map<String, dynamic>.from(policy['duplicateRules'] as Map);
    rules['shadowOverride'] = true;
    policy['duplicateRules'] = rules;

    final result = validator.validateMap(policy);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML8_POLICY_UNKNOWN_FIELD'),
    );
  });

  test('exact duplicates cannot be downgraded from block', () {
    final policy = clone();
    final rules = Map<String, dynamic>.from(policy['duplicateRules'] as Map);
    rules['exactDuplicateDisposition'] = 'human_adjudication_required';
    policy['duplicateRules'] = rules;

    final result = validator.validateMap(policy);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML8_POLICY_DUPLICATE_RULES_WEAKENED'),
    );
  });

  test('near duplicate threshold cannot be silently raised', () {
    final policy = clone();
    final rules = Map<String, dynamic>.from(policy['duplicateRules'] as Map);
    rules['nearDuplicateDisplayJaccardThreshold'] = 0.95;
    policy['duplicateRules'] = rules;

    final result = validator.validateMap(policy);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML8_POLICY_DUPLICATE_RULES_WEAKENED'),
    );
  });

  test('negation protection cannot be removed', () {
    final policy = clone();
    final normalization = Map<String, dynamic>.from(
      policy['normalization'] as Map,
    );
    normalization['protectedTokens'] = ['must', 'shall'];
    policy['normalization'] = normalization;

    final result = validator.validateMap(policy);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML8_POLICY_NORMALIZATION_TOKENS'),
    );
  });

  test('automatic numeric reconciliation cannot be enabled', () {
    final policy = clone();
    final rules = Map<String, dynamic>.from(
      policy['numericNormalization'] as Map,
    );
    rules['automaticNumericReconciliationAllowed'] = true;
    policy['numericNormalization'] = rules;

    final result = validator.validateMap(policy);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML8_POLICY_NUMERIC_RULES_WEAKENED'),
    );
  });

  test('unresolved contradictions must remain blocking', () {
    final policy = clone();
    final rules = Map<String, dynamic>.from(
      policy['contradictionRules'] as Map,
    );
    rules['unresolvedContradictionDisposition'] = 'warn';
    policy['contradictionRules'] = rules;

    final result = validator.validateMap(policy);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML8_POLICY_CONTRADICTION_RULES_WEAKENED'),
    );
  });

  test('human adjudication cannot be disabled', () {
    final policy = clone();
    final rules = Map<String, dynamic>.from(policy['adjudicationRules'] as Map);
    rules['humanReviewRequired'] = false;
    policy['adjudicationRules'] = rules;

    final result = validator.validateMap(policy);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML8_POLICY_ADJUDICATION_RULES_WEAKENED'),
    );
  });

  test('signal-set binding cannot be disabled', () {
    final policy = clone();
    final rules = Map<String, dynamic>.from(policy['adjudicationRules'] as Map);
    rules['exactSignalSetRequired'] = false;
    policy['adjudicationRules'] = rules;

    final result = validator.validateMap(policy);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML8_POLICY_ADJUDICATION_RULES_WEAKENED'),
    );
  });

  test('concentration signals remain audit-only in ML-8', () {
    final policy = clone();
    final rules = Map<String, dynamic>.from(
      policy['concentrationAudit'] as Map,
    );
    rules['concentrationSignalsAreBlocking'] = true;
    policy['concentrationAudit'] = rules;

    final result = validator.validateMap(policy);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML8_POLICY_CONCENTRATION_AUDIT_WEAKENED'),
    );
  });

  test('content drift invalidation cannot be disabled', () {
    final policy = clone();
    final rules = Map<String, dynamic>.from(policy['driftRules'] as Map);
    rules['displayTextChangeInvalidatesEvidence'] = false;
    policy['driftRules'] = rules;

    final result = validator.validateMap(policy);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML8_POLICY_DRIFT_RULES_WEAKENED'),
    );
  });
}
