import 'dart:convert';
import 'dart:io';

import 'package:exam_platform/services/micro_learning/rights_provenance_policy_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const policyPath = 'content/micro_learning/rights_provenance_policy_v1.json';
  const validator = RightsProvenancePolicyValidator();

  Map<String, dynamic> loadPolicy() {
    return jsonDecode(File(policyPath).readAsStringSync())
        as Map<String, dynamic>;
  }

  Map<String, dynamic> clonePolicy() {
    return jsonDecode(jsonEncode(loadPolicy())) as Map<String, dynamic>;
  }

  test('frozen ML-5 rights policy passes validation', () {
    final result = validator.validateMap(loadPolicy());

    expect(result.issues, isEmpty, reason: result.issues.join('\n'));
  });

  test('unknown root policy field fails closed', () {
    final policy = clonePolicy();
    policy['shadowOverride'] = true;

    final result = validator.validateMap(policy);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML5_POLICY_UNKNOWN_FIELD'),
    );
  });

  test('unknown nested rights-treatment field fails closed', () {
    final policy = clonePolicy();
    final treatments = Map<String, dynamic>.from(
      policy['rightsTreatments'] as Map,
    );
    final paraphrase = Map<String, dynamic>.from(
      treatments['original_paraphrase'] as Map,
    );
    paraphrase['ignoreSimilarity'] = true;
    treatments['original_paraphrase'] = paraphrase;
    policy['rightsTreatments'] = treatments;

    final result = validator.validateMap(policy);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML5_POLICY_UNKNOWN_FIELD'),
    );
  });

  test('AI cannot be promoted to a rights authority', () {
    final policy = clonePolicy();
    final principles = Map<String, dynamic>.from(policy['principles'] as Map);
    principles['aiIsRightsAuthority'] = true;
    policy['principles'] = principles;

    final result = validator.validateMap(policy);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML5_POLICY_PRINCIPLE_WEAKENED'),
    );
  });

  test('automatic fair-use determination cannot be enabled', () {
    final policy = clonePolicy();
    final principles = Map<String, dynamic>.from(policy['principles'] as Map);
    principles['fairUseAutoDeterminationAllowed'] = true;
    policy['principles'] = principles;

    final result = validator.validateMap(policy);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML5_POLICY_PRINCIPLE_WEAKENED'),
    );
  });

  test('government-hosted content cannot be presumed public domain', () {
    final policy = clonePolicy();
    final principles = Map<String, dynamic>.from(policy['principles'] as Map);
    principles['publicDomainAssumptionAllowed'] = true;
    policy['principles'] = principles;

    final result = validator.validateMap(policy);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML5_POLICY_PRINCIPLE_WEAKENED'),
    );
  });

  test('authority rights tiers must remain complete and non-overlapping', () {
    final policy = clonePolicy();
    final tiers = Map<String, dynamic>.from(
      policy['authorityRightsTiers'] as Map,
    );
    final government = List<String>.from(
      tiers['government_first_party'] as List,
    );
    government.add('SRC-03');
    tiers['government_first_party'] = government;
    policy['authorityRightsTiers'] = tiers;

    final result = validator.validateMap(policy);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      anyOf(
        contains('ML5_POLICY_GOVERNMENT_TIER'),
        contains('ML5_POLICY_AUTHORITY_PARTITION'),
      ),
    );
  });

  test('minimal quote limit cannot be broadened beyond 12 words', () {
    final policy = clonePolicy();
    final treatments = Map<String, dynamic>.from(
      policy['rightsTreatments'] as Map,
    );
    final minimal = Map<String, dynamic>.from(
      treatments['minimal_quote'] as Map,
    );
    minimal['maxQuoteWordsPerFact'] = 25;
    treatments['minimal_quote'] = minimal;
    policy['rightsTreatments'] = treatments;

    final result = validator.validateMap(policy);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML5_POLICY_MINIMAL_QUOTE_WEAKENED'),
    );
  });

  test('paraphrase verbatim-run ceiling cannot be broadened', () {
    final policy = clonePolicy();
    final treatments = Map<String, dynamic>.from(
      policy['rightsTreatments'] as Map,
    );
    final paraphrase = Map<String, dynamic>.from(
      treatments['original_paraphrase'] as Map,
    );
    paraphrase['maxLongestVerbatimRunWords'] = 12;
    treatments['original_paraphrase'] = paraphrase;
    policy['rightsTreatments'] = treatments;

    final result = validator.validateMap(policy);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML5_POLICY_PARAPHRASE_RULE_WEAKENED'),
    );
  });

  test(
    'licensed excerpt must retain startup and redistribution permission',
    () {
      final policy = clonePolicy();
      final treatments = Map<String, dynamic>.from(
        policy['rightsTreatments'] as Map,
      );
      final licensed = Map<String, dynamic>.from(
        treatments['licensed_excerpt'] as Map,
      );
      licensed['licenseMustPermitStartupDisplay'] = false;
      treatments['licensed_excerpt'] = licensed;
      policy['rightsTreatments'] = treatments;

      final result = validator.validateMap(policy);

      expect(result.isValid, isFalse);
      expect(
        result.issues.map((issue) => issue.code),
        contains('ML5_POLICY_LICENSED_EXCERPT_WEAKENED'),
      );
    },
  );

  test('rights evidence freshness window cannot be silently widened', () {
    final policy = clonePolicy();
    final rules = Map<String, dynamic>.from(policy['evidenceRules'] as Map);
    rules['maxEvidenceAgeDays'] = 3650;
    policy['evidenceRules'] = rules;

    final result = validator.validateMap(policy);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML5_POLICY_EVIDENCE_CONTRACT'),
    );
  });

  test('human rights review requirement cannot be disabled', () {
    final policy = clonePolicy();
    final principles = Map<String, dynamic>.from(policy['principles'] as Map);
    principles['requireHumanCopyrightReviewForValidatedOrPublished'] = false;
    policy['principles'] = principles;

    final result = validator.validateMap(policy);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML5_POLICY_PRINCIPLE_WEAKENED'),
    );
  });

  test('government third-party clearance protection cannot be disabled', () {
    final policy = clonePolicy();
    final rules = Map<String, dynamic>.from(
      policy['governmentSourceRules'] as Map,
    );
    rules['thirdPartyMaterialMustBeExcludedUnlessSeparatelyCleared'] = false;
    policy['governmentSourceRules'] = rules;

    final result = validator.validateMap(policy);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML5_POLICY_GOVERNMENT_RULE_WEAKENED'),
    );
  });

  test('rights-sensitive similarity review cannot be disabled', () {
    final policy = clonePolicy();
    final rules = Map<String, dynamic>.from(
      policy['rightsSensitiveRules'] as Map,
    );
    rules['derivativeSimilarityReviewRequired'] = false;
    policy['rightsSensitiveRules'] = rules;

    final result = validator.validateMap(policy);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML5_POLICY_SENSITIVE_RULE_WEAKENED'),
    );
  });
}
