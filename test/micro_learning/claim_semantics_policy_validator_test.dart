import 'dart:convert';
import 'dart:io';

import 'package:exam_platform/services/micro_learning/claim_semantics_policy_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const policyPath = 'content/micro_learning/claim_semantics_policy_v1.json';
  const validator = ClaimSemanticsPolicyValidator();

  Map<String, dynamic> loadPolicy() {
    return jsonDecode(File(policyPath).readAsStringSync())
        as Map<String, dynamic>;
  }

  Map<String, dynamic> clonePolicy() {
    return jsonDecode(jsonEncode(loadPolicy())) as Map<String, dynamic>;
  }

  test('frozen ML-4 claim-semantics policy passes validation', () {
    final result = validator.validateMap(loadPolicy());

    expect(result.issues, isEmpty, reason: result.issues.join('\n'));
  });

  test('unknown policy root field fails closed', () {
    final policy = clonePolicy();
    policy['hiddenOverride'] = true;

    final result = validator.validateMap(policy);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML4_POLICY_UNKNOWN_FIELD'),
    );
  });

  test('legal-status broadening fails even without version change', () {
    final policy = clonePolicy();
    final rules = (policy['sourceClassRules'] as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    final federal = rules.firstWhere(
      (rule) => rule['sourceClass'] == 'federal_regulation',
    );
    federal['allowedLegalStatuses'] = [
      'binding_requirement',
      'recommendation',
    ];
    policy['sourceClassRules'] = rules;

    final result = validator.validateMap(policy);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML4_POLICY_LEGAL_STATUSES'),
    );
  });

  test('mandatory-language weakening fails closed', () {
    final policy = clonePolicy();
    final rules = (policy['sourceClassRules'] as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    final nioshRule = rules.firstWhere(
      (rule) => rule['sourceClass'] == 'research_or_prevention_guidance',
    );
    nioshRule['mandatoryLanguage'] = 'allowed';
    policy['sourceClassRules'] = rules;

    final result = validator.validateMap(policy);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML4_POLICY_MANDATORY_RULE'),
    );
  });

  test('missing frozen source-class rule fails closed', () {
    final policy = clonePolicy();
    final rules = (policy['sourceClassRules'] as List)
        .where(
          (item) =>
              (item as Map)['sourceClass'] != 'transportation_regulation',
        )
        .toList();
    policy['sourceClassRules'] = rules;

    final result = validator.validateMap(policy);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML4_POLICY_SOURCE_CLASS_COVERAGE'),
    );
  });

  test('missing authority attribution family fails closed', () {
    final policy = clonePolicy();
    final tokens = Map<String, dynamic>.from(
      policy['authorityAttributionTokens'] as Map,
    );
    tokens.remove('SRC-06');
    policy['authorityAttributionTokens'] = tokens;

    final result = validator.validateMap(policy);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML4_POLICY_AUTHORITY_COVERAGE'),
    );
  });

  test('mandatory term set cannot be silently reduced', () {
    final policy = clonePolicy();
    policy['mandatoryTerms'] = ['must', 'shall'];

    final result = validator.validateMap(policy);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML4_POLICY_MANDATORY_TERMS'),
    );
  });

  test('human technical review cannot be disabled', () {
    final policy = clonePolicy();
    final review = Map<String, dynamic>.from(policy['enhancedReview'] as Map);
    review['technicalCategoryRequiresHumanPass'] = false;
    policy['enhancedReview'] = review;

    final result = validator.validateMap(policy);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML4_POLICY_HUMAN_REVIEW'),
    );
  });

  test('numeric detector must retain broad regex coverage', () {
    final policy = clonePolicy();
    policy['numericSignalPatterns'] = [
      r'\b\d+\s*%',
      r'\b\d+\s*ppm\b',
    ];

    final result = validator.validateMap(policy);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML4_POLICY_NUMERIC_PATTERN_COVERAGE'),
    );
  });

  test('invalid numeric regex fails closed', () {
    final policy = clonePolicy();
    final patterns = List<String>.from(
      policy['numericSignalPatterns'] as List,
    );
    patterns[0] = '[';
    policy['numericSignalPatterns'] = patterns;

    final result = validator.validateMap(policy);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML4_POLICY_NUMERIC_PATTERN_REGEX'),
    );
  });
}
