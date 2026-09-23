import 'dart:convert';
import 'dart:io';

import 'package:exam_platform/services/micro_learning/micro_fact_claim_gate_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const factPath = 'test/fixtures/micro_learning/valid_micro_fact_v1.json';
  const registryPath = 'content/micro_learning/authority_registry_v1.json';
  const policyPath = 'content/micro_learning/claim_semantics_policy_v1.json';

  const validator = MicroFactClaimGateValidator();

  Map<String, dynamic> loadJson(String path) {
    return jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
  }

  Map<String, dynamic> loadFact() => loadJson(factPath);

  Map<String, dynamic> loadRegistry() => loadJson(registryPath);

  Map<String, dynamic> loadPolicy() => loadJson(policyPath);

  Map<String, dynamic> cloneMap(Map<String, dynamic> value) {
    return jsonDecode(jsonEncode(value)) as Map<String, dynamic>;
  }

  Map<String, dynamic> cloneFact() => cloneMap(loadFact());

  Map<String, dynamic> authorityById(
    Map<String, dynamic> registry,
    String id,
  ) {
    return (registry['authorities'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((authority) => authority['id'] == id);
  }

  Map<String, dynamic> configureSource({
    required Map<String, dynamic> fact,
    required Map<String, dynamic> registry,
    required String sourceRegistryId,
    required String sourceClass,
    required String legalStatus,
    required String displayText,
    String? shortVariant,
    String? jurisdiction,
    String category = 'safety_insight',
  }) {
    final authority = authorityById(registry, sourceRegistryId);
    final provenance = Map<String, dynamic>.from(fact['provenance'] as Map);
    provenance
      ..['sourceRegistryId'] = sourceRegistryId
      ..['sourceClass'] = sourceClass
      ..['sourceTitle'] = authority['displayName'].toString()
      ..['officialUrl'] =
          (authority['officialEntryPoints'] as List).first as String
      ..['sourceLocator'] = 'ML-4 test source locator'
      ..['editionOrRevision'] = 'ML-4 test edition'
      ..['sourceSection'] = 'ML-4 test section'
      ..['sourcePage'] = null
      ..['sourcePublishedAt'] = null
      ..['sourceVerifiedAt'] = authority['verifiedAt'].toString();
    fact['provenance'] = provenance;

    final claim = Map<String, dynamic>.from(fact['claim'] as Map);
    claim
      ..['legalStatus'] = legalStatus
      ..['jurisdiction'] = jurisdiction
      ..['numericalClaim'] = false
      ..['safetyCritical'] = false
      ..['simplificationRisk'] = 'low';
    fact['claim'] = claim;

    final display = Map<String, dynamic>.from(fact['display'] as Map);
    display
      ..['displayText'] = displayText
      ..['shortVariant'] = shortVariant;
    fact['display'] = display;

    fact['category'] = category;

    final review = Map<String, dynamic>.from(fact['review'] as Map);
    review
      ..['technicalStatus'] = 'pass'
      ..['sourceStatus'] = 'pass'
      ..['pedagogyStatus'] = 'pass'
      ..['copyrightStatus'] = 'pass'
      ..['uiStatus'] = 'pass'
      ..['humanTechnicalStatus'] = 'pass'
      ..['reviewedAt'] = authority['verifiedAt'].toString()
      ..['nextReviewDueAt'] = '2027-09-23';
    fact['review'] = review;

    fact['status'] = 'published';
    final runtime = Map<String, dynamic>.from(fact['runtime'] as Map);
    runtime['startupEligible'] = true;
    fact['runtime'] = runtime;

    return fact;
  }

  MicroFactClaimGateResult validate(Map<String, dynamic> fact) {
    return validator.validateMaps(
      microFact: fact,
      authorityRegistry: loadRegistry(),
      claimPolicy: loadPolicy(),
    );
  }

  test('valid ML-2 fixture passes ML-4 factual and legal-status gates', () {
    final result = validate(loadFact());

    expect(result.issues, isEmpty, reason: result.issues.join('\n'));
  });

  test('all frozen source classes have at least one valid authority path', () {
    final registry = loadRegistry();
    final policy = loadPolicy();
    final rules = (policy['sourceClassRules'] as List)
        .cast<Map<String, dynamic>>();
    final tokens = Map<String, dynamic>.from(
      policy['authorityAttributionTokens'] as Map,
    );

    for (final rule in rules) {
      final sourceClass = rule['sourceClass'] as String;
      final authority = (registry['authorities'] as List)
          .cast<Map<String, dynamic>>()
          .firstWhere(
            (candidate) => (candidate['permittedSourceClasses'] as List)
                .contains(sourceClass),
          );
      final sourceId = authority['id'] as String;
      final legalStatus =
          (rule['allowedLegalStatuses'] as List).first as String;
      final jurisdiction = rule['jurisdiction'] == 'required'
          ? 'ML-4 test jurisdiction'
          : null;
      final attribution =
          (tokens[sourceId] as List).first.toString();

      final fact = configureSource(
        fact: cloneFact(),
        registry: registry,
        sourceRegistryId: sourceId,
        sourceClass: sourceClass,
        legalStatus: legalStatus,
        jurisdiction: jurisdiction,
        displayText: attribution + ' describes this safety concept.',
        shortVariant: null,
      );

      final result = validator.validateMaps(
        microFact: fact,
        authorityRegistry: registry,
        claimPolicy: policy,
      );

      expect(
        result.issues,
        isEmpty,
        reason: sourceClass + ': ' + result.issues.join('\n'),
      );
    }
  });

  test('non-regulatory authority cannot create a binding legal duty', () {
    final registry = loadRegistry();
    final fact = configureSource(
      fact: cloneFact(),
      registry: registry,
      sourceRegistryId: 'SRC-02',
      sourceClass: 'research_or_prevention_guidance',
      legalStatus: 'binding_requirement',
      jurisdiction: 'US',
      displayText: 'NIOSH describes this prevention measure.',
    );

    final result = validate(fact);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML4_LEGAL_STATUS_SOURCE_CLASS_MISMATCH'),
    );
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML4_NONREGULATOR_CANNOT_CREATE_LEGAL_DUTY'),
    );
  });

  test('binding regulatory claim requires jurisdiction', () {
    final fact = cloneFact();
    final claim = Map<String, dynamic>.from(fact['claim'] as Map);
    claim['jurisdiction'] = null;
    fact['claim'] = claim;

    final result = validate(fact);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML4_JURISDICTION_REQUIRED'),
    );
  });

  test('NIOSH recommendation cannot use mandatory legal wording', () {
    final registry = loadRegistry();
    final fact = configureSource(
      fact: cloneFact(),
      registry: registry,
      sourceRegistryId: 'SRC-02',
      sourceClass: 'research_or_prevention_guidance',
      legalStatus: 'recommendation',
      displayText: 'NIOSH requires employers to use this control.',
    );

    final result = validate(fact);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML4_NONBINDING_MANDATORY_LANGUAGE'),
    );
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML4_AUTHORITY_SPECIFIC_MISATTRIBUTION'),
    );
  });

  test('ACGIH cannot be described as creating an ACGIH PEL', () {
    final registry = loadRegistry();
    final fact = configureSource(
      fact: cloneFact(),
      registry: registry,
      sourceRegistryId: 'SRC-06',
      sourceClass: 'professional_guideline',
      legalStatus: 'professional_guideline',
      displayText: 'The ACGIH PEL is used as a legal exposure limit.',
    );

    final result = validate(fact);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML4_AUTHORITY_SPECIFIC_MISATTRIBUTION'),
    );
  });

  test('ISO requirement wording is allowed when explicitly attributed', () {
    final registry = loadRegistry();
    final fact = configureSource(
      fact: cloneFact(),
      registry: registry,
      sourceRegistryId: 'SRC-04',
      sourceClass: 'international_standard',
      legalStatus: 'international_standard',
      displayText: 'ISO 45001 requires documented information in specified areas.',
      shortVariant: 'ISO 45001 requires specified documented information.',
    );

    final result = validate(fact);

    expect(result.issues, isEmpty, reason: result.issues.join('\n'));
  });

  test('ISO mandatory wording without attribution is blocked', () {
    final registry = loadRegistry();
    final fact = configureSource(
      fact: cloneFact(),
      registry: registry,
      sourceRegistryId: 'SRC-04',
      sourceClass: 'international_standard',
      legalStatus: 'international_standard',
      displayText: 'Organizations must maintain specified documented information.',
    );

    final result = validate(fact);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML4_MANDATORY_LANGUAGE_REQUIRES_ATTRIBUTION'),
    );
  });

  test('non-binding standard cannot be described as federal law', () {
    final registry = loadRegistry();
    final fact = configureSource(
      fact: cloneFact(),
      registry: registry,
      sourceRegistryId: 'SRC-04',
      sourceClass: 'international_standard',
      legalStatus: 'international_standard',
      displayText: 'ISO 45001 is required by law for every employer.',
    );

    final result = validate(fact);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML4_FALSE_LEGAL_EQUIVALENCE'),
    );
  });

  test('short variant is checked independently for legal wording', () {
    final registry = loadRegistry();
    final fact = configureSource(
      fact: cloneFact(),
      registry: registry,
      sourceRegistryId: 'SRC-04',
      sourceClass: 'international_standard',
      legalStatus: 'international_standard',
      displayText: 'ISO 45001 requires specified documented information.',
      shortVariant: 'Organizations must keep the required documents.',
    );

    final result = validate(fact);

    expect(result.isValid, isFalse);
    final matching = result.issues.where(
      (issue) =>
          issue.code == 'ML4_MANDATORY_LANGUAGE_REQUIRES_ATTRIBUTION' &&
          issue.path == r'$.display.shortVariant',
    );
    expect(matching, isNotEmpty);
  });

  test('OSHA interpretation requires explicit OSHA attribution', () {
    final registry = loadRegistry();
    final fact = configureSource(
      fact: cloneFact(),
      registry: registry,
      sourceRegistryId: 'SRC-01',
      sourceClass: 'regulatory_interpretation',
      legalStatus: 'regulatory_interpretation',
      jurisdiction: 'US Federal OSHA',
      displayText: 'This interpretation explains how the requirement applies.',
    );

    final result = validate(fact);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML4_INTERPRETATION_REQUIRES_ATTRIBUTION'),
    );
  });

  test('attributed OSHA interpretation can pass', () {
    final registry = loadRegistry();
    final fact = configureSource(
      fact: cloneFact(),
      registry: registry,
      sourceRegistryId: 'SRC-01',
      sourceClass: 'regulatory_interpretation',
      legalStatus: 'regulatory_interpretation',
      jurisdiction: 'US Federal OSHA',
      displayText: 'OSHA interprets how this requirement applies in the stated circumstances.',
      shortVariant: 'OSHA interprets the requirement in the stated circumstances.',
    );

    final result = validate(fact);

    expect(result.issues, isEmpty, reason: result.issues.join('\n'));
  });

  test('not_applicable legal status is reserved for CSP and learning tips', () {
    final registry = loadRegistry();
    final fact = configureSource(
      fact: cloneFact(),
      registry: registry,
      sourceRegistryId: 'SRC-02',
      sourceClass: 'research_or_prevention_guidance',
      legalStatus: 'not_applicable',
      displayText: 'NIOSH describes this safety concept.',
    );

    final result = validate(fact);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML4_NOT_APPLICABLE_CATEGORY_MISMATCH'),
    );
  });

  test('CSP tip must use not_applicable legal status', () {
    final registry = loadRegistry();
    final fact = configureSource(
      fact: cloneFact(),
      registry: registry,
      sourceRegistryId: 'SRC-13',
      sourceClass: 'professional_guideline',
      legalStatus: 'professional_guideline',
      category: 'csp_tip',
      displayText: 'ASSP professional literature can support structured safety reasoning.',
    );

    final result = validate(fact);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML4_TIP_LEGAL_STATUS_NOT_APPLICABLE_REQUIRED'),
    );
  });

  test('CSP tip with not_applicable legal status can pass', () {
    final registry = loadRegistry();
    final fact = configureSource(
      fact: cloneFact(),
      registry: registry,
      sourceRegistryId: 'SRC-13',
      sourceClass: 'professional_guideline',
      legalStatus: 'not_applicable',
      category: 'csp_tip',
      displayText: 'ASSP professional literature can support structured safety reasoning.',
    );

    final result = validate(fact);

    expect(result.issues, isEmpty, reason: result.issues.join('\n'));
  });

  test('numerical wording requires numericalClaim flag', () {
    final fact = cloneFact();
    final display = Map<String, dynamic>.from(fact['display'] as Map);
    display['displayText'] =
        'OSHA addresses occupational noise exposures at levels such as 90 dBA.';
    fact['display'] = display;

    final result = validate(fact);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML4_NUMERICAL_FLAG_MISMATCH'),
    );
  });

  test('validated numerical claim requires evidence-location metadata', () {
    final fact = cloneFact();
    fact['status'] = 'validated';

    final runtime = Map<String, dynamic>.from(fact['runtime'] as Map);
    runtime['startupEligible'] = false;
    fact['runtime'] = runtime;

    final claim = Map<String, dynamic>.from(fact['claim'] as Map);
    claim['numericalClaim'] = true;
    fact['claim'] = claim;

    final provenance = Map<String, dynamic>.from(fact['provenance'] as Map);
    provenance
      ..['editionOrRevision'] = null
      ..['sourceSection'] = null
      ..['sourcePage'] = null;
    fact['provenance'] = provenance;

    final result = validate(fact);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML4_NUMERICAL_EVIDENCE_LOCATOR_REQUIRED'),
    );
  });

  test('validated numerical claim requires enhanced human review', () {
    final fact = cloneFact();
    fact['status'] = 'validated';

    final runtime = Map<String, dynamic>.from(fact['runtime'] as Map);
    runtime['startupEligible'] = false;
    fact['runtime'] = runtime;

    final claim = Map<String, dynamic>.from(fact['claim'] as Map);
    claim['numericalClaim'] = true;
    fact['claim'] = claim;

    final review = Map<String, dynamic>.from(fact['review'] as Map);
    review['humanTechnicalStatus'] = 'pending';
    fact['review'] = review;

    final result = validate(fact);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML4_NUMERICAL_REVIEW_REQUIRED'),
    );
  });

  test('validated technical fact requires human technical approval', () {
    final fact = cloneFact();
    fact['status'] = 'validated';

    final runtime = Map<String, dynamic>.from(fact['runtime'] as Map);
    runtime['startupEligible'] = false;
    fact['runtime'] = runtime;

    final review = Map<String, dynamic>.from(fact['review'] as Map);
    review['humanTechnicalStatus'] = 'pending';
    fact['review'] = review;

    final result = validate(fact);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML4_HUMAN_TECHNICAL_REVIEW_REQUIRED'),
    );
  });

  test('validated fact requires technical and source review to pass', () {
    final fact = cloneFact();
    fact['status'] = 'validated';

    final runtime = Map<String, dynamic>.from(fact['runtime'] as Map);
    runtime['startupEligible'] = false;
    fact['runtime'] = runtime;

    final review = Map<String, dynamic>.from(fact['review'] as Map);
    review['sourceStatus'] = 'pending';
    fact['review'] = review;

    final result = validate(fact);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML4_FACTUAL_REVIEW_REQUIRED'),
    );
  });

  test('generic source locator is rejected at validated lifecycle', () {
    final fact = cloneFact();
    fact['status'] = 'validated';

    final runtime = Map<String, dynamic>.from(fact['runtime'] as Map);
    runtime['startupEligible'] = false;
    fact['runtime'] = runtime;

    final provenance = Map<String, dynamic>.from(fact['provenance'] as Map);
    provenance['sourceLocator'] = 'homepage';
    fact['provenance'] = provenance;

    final result = validate(fact);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML4_SOURCE_LOCATOR_TOO_GENERIC'),
    );
  });

  test('validated legal claim requires section or page location', () {
    final fact = cloneFact();
    fact['status'] = 'validated';

    final runtime = Map<String, dynamic>.from(fact['runtime'] as Map);
    runtime['startupEligible'] = false;
    fact['runtime'] = runtime;

    final provenance = Map<String, dynamic>.from(fact['provenance'] as Map);
    provenance
      ..['sourceSection'] = null
      ..['sourcePage'] = null;
    fact['provenance'] = provenance;

    final result = validate(fact);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML4_LEGAL_SOURCE_LOCATION_REQUIRED'),
    );
  });

  test('tampered ML-4 policy fails before claim approval', () {
    final policy = loadPolicy();
    policy['failClosed'] = false;

    final result = validator.validateMaps(
      microFact: loadFact(),
      authorityRegistry: loadRegistry(),
      claimPolicy: policy,
    );

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('ML4_POLICY_PREREQUISITE_INVALID'),
    );
  });
}
