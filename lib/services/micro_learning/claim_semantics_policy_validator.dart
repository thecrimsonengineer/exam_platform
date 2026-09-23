import 'authority_registry_validator.dart';
import 'micro_fact_schema_validator.dart';
import 'micro_fact_source_gate_validator.dart';

class ClaimSemanticsPolicyIssue {
  const ClaimSemanticsPolicyIssue({
    required this.code,
    required this.path,
    required this.message,
  });

  final String code;
  final String path;
  final String message;

  @override
  String toString() => code + ' at ' + path + ': ' + message;
}

class ClaimSemanticsPolicyValidationResult {
  const ClaimSemanticsPolicyValidationResult(this.issues);

  final List<ClaimSemanticsPolicyIssue> issues;

  bool get isValid => issues.isEmpty;
}

class ClaimSemanticsPolicyValidator {
  static const String requiredPolicyVersion = '1.0.0';

  static const Set<String> requiredRootKeys = {
    'schemaVersion',
    'policyVersion',
    'status',
    'frozenAt',
    'authorityRegistryVersion',
    'microFactSchemaVersion',
    'failClosed',
    'sourceClassRules',
    'authorityAttributionTokens',
    'mandatoryTerms',
    'legalEquivalencePhrases',
    'nonApplicableCategories',
    'enhancedReview',
    'numericSignalPatterns',
    'authoritySpecificForbiddenPhrases',
    'technicalCategories',
    'genericSourceLocators',
  };

  static const Map<String, Set<String>> expectedLegalStatuses = {
    'federal_regulation': {'binding_requirement'},
    'regulatory_interpretation': {'regulatory_interpretation'},
    'enforcement_or_compliance_guidance': {'nonbinding_guidance'},
    'government_recommendation': {'recommendation', 'not_applicable'},
    'research_or_prevention_guidance': {
      'recommendation',
      'research_finding',
      'not_applicable',
    },
    'consensus_standard': {'consensus_standard'},
    'international_standard': {'international_standard'},
    'professional_guideline': {'professional_guideline', 'not_applicable'},
    'professional_framework': {'professional_framework', 'not_applicable'},
    'environmental_regulation': {'binding_requirement'},
    'transportation_regulation': {'binding_requirement'},
    'emergency_management_framework': {
      'professional_framework',
      'not_applicable',
    },
    'process_safety_framework': {'professional_framework'},
    'loss_prevention_guidance': {'professional_guideline'},
    'testing_or_certification_standard': {'certification_or_testing'},
  };

  static const Map<String, String> expectedJurisdictionRules = {
    'federal_regulation': 'required',
    'regulatory_interpretation': 'required',
    'enforcement_or_compliance_guidance': 'required',
    'government_recommendation': 'optional',
    'research_or_prevention_guidance': 'optional',
    'consensus_standard': 'optional',
    'international_standard': 'optional',
    'professional_guideline': 'optional',
    'professional_framework': 'optional',
    'environmental_regulation': 'required',
    'transportation_regulation': 'required',
    'emergency_management_framework': 'optional',
    'process_safety_framework': 'optional',
    'loss_prevention_guidance': 'optional',
    'testing_or_certification_standard': 'optional',
  };

  static const Map<String, String> expectedMandatoryModes = {
    'federal_regulation': 'allowed',
    'regulatory_interpretation': 'attributed_only',
    'enforcement_or_compliance_guidance': 'blocked',
    'government_recommendation': 'blocked',
    'research_or_prevention_guidance': 'blocked',
    'consensus_standard': 'attributed_only',
    'international_standard': 'attributed_only',
    'professional_guideline': 'blocked',
    'professional_framework': 'blocked',
    'environmental_regulation': 'allowed',
    'transportation_regulation': 'allowed',
    'emergency_management_framework': 'blocked',
    'process_safety_framework': 'blocked',
    'loss_prevention_guidance': 'blocked',
    'testing_or_certification_standard': 'attributed_only',
  };

  static const Set<String> expectedNonApplicableCategories = {
    'csp_tip',
    'learning_tip',
  };

  static const Set<String> expectedTechnicalCategories = {
    'safety_insight',
    'quick_recall',
    'think_about_it',
    'process_safety_insight',
    'ih_insight',
    'emergency_insight',
    'environmental_insight',
    'fire_electrical_insight',
    'management_insight',
    'transport_insight',
  };

  static const Set<String> expectedMandatoryTerms = {
    'must',
    'shall',
    'required',
    'requires',
    'mandated',
    'mandates',
    'prohibited',
    'prohibits',
    'may not',
  };

  static const Set<String> expectedLegalEquivalencePhrases = {
    'required by law',
    'legally required',
    'federal law requires',
    'statutory requirement',
    'has the force of law',
  };

  const ClaimSemanticsPolicyValidator();

  ClaimSemanticsPolicyValidationResult validateMap(
    Map<String, dynamic> policy,
  ) {
    final issues = <ClaimSemanticsPolicyIssue>[];

    _exactKeys(policy, requiredRootKeys, r'$policy', issues);

    if (policy['schemaVersion'] != 1) {
      _add(
        issues,
        'ML4_POLICY_SCHEMA_VERSION',
        r'$policy.schemaVersion',
        'Claim-semantics policy schemaVersion must be 1.',
      );
    }

    if (policy['policyVersion'] != requiredPolicyVersion) {
      _add(
        issues,
        'ML4_POLICY_VERSION',
        r'$policy.policyVersion',
        'Claim-semantics policy version must be ' + requiredPolicyVersion + '.',
      );
    }

    if (policy['status'] != 'frozen' || policy['failClosed'] != true) {
      _add(
        issues,
        'ML4_POLICY_NOT_FROZEN',
        r'$policy',
        'ML-4 policy must remain frozen and fail closed.',
      );
    }

    if (!_isStrictDate(policy['frozenAt'])) {
      _add(
        issues,
        'ML4_POLICY_FROZEN_DATE',
        r'$policy.frozenAt',
        'frozenAt must be a valid YYYY-MM-DD date.',
      );
    }

    if (policy['authorityRegistryVersion'] !=
        MicroFactSourceGateValidator.requiredRegistryVersion) {
      _add(
        issues,
        'ML4_POLICY_REGISTRY_VERSION',
        r'$policy.authorityRegistryVersion',
        'ML-4 policy must bind to the frozen ML-1 registry version.',
      );
    }

    if (policy['microFactSchemaVersion'] !=
        MicroFactSchemaValidator.schemaVersion) {
      _add(
        issues,
        'ML4_POLICY_FACT_SCHEMA_VERSION',
        r'$policy.microFactSchemaVersion',
        'ML-4 policy must bind to MicroFact schema v1.',
      );
    }

    _validateSourceClassRules(policy['sourceClassRules'], issues);
    _validateAttributionTokens(policy['authorityAttributionTokens'], issues);

    _expectExactStringSet(
      policy['mandatoryTerms'],
      expectedMandatoryTerms,
      r'$policy.mandatoryTerms',
      'ML4_POLICY_MANDATORY_TERMS',
      issues,
    );

    _expectExactStringSet(
      policy['legalEquivalencePhrases'],
      expectedLegalEquivalencePhrases,
      r'$policy.legalEquivalencePhrases',
      'ML4_POLICY_LEGAL_EQUIVALENCE',
      issues,
    );

    _expectExactStringSet(
      policy['nonApplicableCategories'],
      expectedNonApplicableCategories,
      r'$policy.nonApplicableCategories',
      'ML4_POLICY_NON_APPLICABLE_CATEGORIES',
      issues,
    );

    _expectExactStringSet(
      policy['technicalCategories'],
      expectedTechnicalCategories,
      r'$policy.technicalCategories',
      'ML4_POLICY_TECHNICAL_CATEGORIES',
      issues,
    );

    _validateEnhancedReview(policy['enhancedReview'], issues);
    _validateNumericPatterns(policy['numericSignalPatterns'], issues);
    _validateForbiddenPhrases(
      policy['authoritySpecificForbiddenPhrases'],
      issues,
    );
    _validateNonEmptyUniqueStringList(
      policy['genericSourceLocators'],
      r'$policy.genericSourceLocators',
      'ML4_POLICY_GENERIC_LOCATORS',
      issues,
    );

    return ClaimSemanticsPolicyValidationResult(List.unmodifiable(issues));
  }

  void _validateSourceClassRules(
    dynamic value,
    List<ClaimSemanticsPolicyIssue> issues,
  ) {
    if (value is! List) {
      _add(
        issues,
        'ML4_POLICY_SOURCE_RULES',
        r'$policy.sourceClassRules',
        'sourceClassRules must be a list.',
      );
      return;
    }

    final seen = <String>{};
    for (var i = 0; i < value.length; i++) {
      final item = value[i];
      final path = r'$policy.sourceClassRules[' + i.toString() + ']';
      if (item is! Map) {
        _add(
          issues,
          'ML4_POLICY_SOURCE_RULE_OBJECT',
          path,
          'Source-class policy entry must be an object.',
        );
        continue;
      }

      final rule = Map<String, dynamic>.from(item);
      _exactKeys(
        rule,
        const {
          'sourceClass',
          'allowedLegalStatuses',
          'jurisdiction',
          'mandatoryLanguage',
        },
        path,
        issues,
      );

      final sourceClass = rule['sourceClass'];
      if (sourceClass is! String ||
          !MicroFactSchemaValidator.sourceClasses.contains(sourceClass)) {
        _add(
          issues,
          'ML4_POLICY_SOURCE_CLASS',
          path + '.sourceClass',
          'Unknown source class in ML-4 policy.',
        );
        continue;
      }

      if (!seen.add(sourceClass)) {
        _add(
          issues,
          'ML4_POLICY_DUPLICATE_SOURCE_CLASS',
          path + '.sourceClass',
          'Duplicate source-class rule.',
        );
      }

      final actualLegalStatuses = _stringSet(rule['allowedLegalStatuses']);
      final expectedStatuses = expectedLegalStatuses[sourceClass];
      if (expectedStatuses == null ||
          !_sameSet(actualLegalStatuses, expectedStatuses)) {
        _add(
          issues,
          'ML4_POLICY_LEGAL_STATUSES',
          path + '.allowedLegalStatuses',
          'Allowed legal statuses do not match the frozen ML-4 semantics.',
        );
      }

      if (rule['jurisdiction'] != expectedJurisdictionRules[sourceClass]) {
        _add(
          issues,
          'ML4_POLICY_JURISDICTION_RULE',
          path + '.jurisdiction',
          'Jurisdiction rule does not match the frozen ML-4 semantics.',
        );
      }

      if (rule['mandatoryLanguage'] != expectedMandatoryModes[sourceClass]) {
        _add(
          issues,
          'ML4_POLICY_MANDATORY_RULE',
          path + '.mandatoryLanguage',
          'Mandatory-language rule does not match the frozen ML-4 semantics.',
        );
      }
    }

    if (!_sameSet(seen, MicroFactSchemaValidator.sourceClasses)) {
      _add(
        issues,
        'ML4_POLICY_SOURCE_CLASS_COVERAGE',
        r'$policy.sourceClassRules',
        'ML-4 policy must cover every frozen source class exactly once.',
      );
    }
  }

  void _validateAttributionTokens(
    dynamic value,
    List<ClaimSemanticsPolicyIssue> issues,
  ) {
    if (value is! Map) {
      _add(
        issues,
        'ML4_POLICY_ATTRIBUTION_TOKENS',
        r'$policy.authorityAttributionTokens',
        'Authority attribution token map is required.',
      );
      return;
    }

    final map = Map<String, dynamic>.from(value);
    final keys = map.keys.toSet();
    if (!_sameSet(keys, AuthorityRegistryValidator.requiredAuthorityIds)) {
      _add(
        issues,
        'ML4_POLICY_AUTHORITY_COVERAGE',
        r'$policy.authorityAttributionTokens',
        'Attribution policy must cover all 15 frozen authority families.',
      );
    }

    for (final entry in map.entries) {
      _validateNonEmptyUniqueStringList(
        entry.value,
        r'$policy.authorityAttributionTokens.' + entry.key,
        'ML4_POLICY_ATTRIBUTION_VALUES',
        issues,
      );
    }
  }

  void _validateEnhancedReview(
    dynamic value,
    List<ClaimSemanticsPolicyIssue> issues,
  ) {
    if (value is! Map) {
      _add(
        issues,
        'ML4_POLICY_ENHANCED_REVIEW',
        r'$policy.enhancedReview',
        'Enhanced review policy is required.',
      );
      return;
    }

    final review = Map<String, dynamic>.from(value);
    _exactKeys(
      review,
      const {
        'appliesWhenStatusIn',
        'numericalClaimRequiresPass',
        'safetyCriticalRequiresPass',
        'highSimplificationRiskRequiresPass',
        'numericalEvidenceRequiresOneOf',
        'validatedOrPublishedRequiresPass',
        'technicalCategoryRequiresHumanPass',
      },
      r'$policy.enhancedReview',
      issues,
    );

    _expectExactStringSet(
      review['appliesWhenStatusIn'],
      const {'validated', 'published'},
      r'$policy.enhancedReview.appliesWhenStatusIn',
      'ML4_POLICY_REVIEW_LIFECYCLE',
      issues,
    );

    for (final field in [
      'numericalClaimRequiresPass',
      'safetyCriticalRequiresPass',
      'highSimplificationRiskRequiresPass',
    ]) {
      _expectExactStringSet(
        review[field],
        const {'technicalStatus', 'sourceStatus', 'humanTechnicalStatus'},
        r'$policy.enhancedReview.' + field,
        'ML4_POLICY_ENHANCED_REVIEW_FIELDS',
        issues,
      );
    }

    _expectExactStringSet(
      review['validatedOrPublishedRequiresPass'],
      const {'technicalStatus', 'sourceStatus'},
      r'$policy.enhancedReview.validatedOrPublishedRequiresPass',
      'ML4_POLICY_BASE_REVIEW_FIELDS',
      issues,
    );

    _expectExactStringSet(
      review['numericalEvidenceRequiresOneOf'],
      const {'editionOrRevision', 'sourceSection', 'sourcePage'},
      r'$policy.enhancedReview.numericalEvidenceRequiresOneOf',
      'ML4_POLICY_NUMERICAL_EVIDENCE_FIELDS',
      issues,
    );

    if (review['technicalCategoryRequiresHumanPass'] != true) {
      _add(
        issues,
        'ML4_POLICY_HUMAN_REVIEW',
        r'$policy.enhancedReview.technicalCategoryRequiresHumanPass',
        'Technical categories must continue to require human approval.',
      );
    }
  }

  void _validateNumericPatterns(
    dynamic value,
    List<ClaimSemanticsPolicyIssue> issues,
  ) {
    if (value is! List || value.isEmpty) {
      _add(
        issues,
        'ML4_POLICY_NUMERIC_PATTERNS',
        r'$policy.numericSignalPatterns',
        'Numeric signal patterns are required.',
      );
      return;
    }

    final seen = <String>{};
    for (var i = 0; i < value.length; i++) {
      final pattern = value[i];
      if (pattern is! String || pattern.isEmpty || !seen.add(pattern)) {
        _add(
          issues,
          'ML4_POLICY_NUMERIC_PATTERN',
          r'$policy.numericSignalPatterns[' + i.toString() + ']',
          'Numeric pattern must be a unique non-empty string.',
        );
        continue;
      }

      try {
        RegExp(pattern, caseSensitive: false);
      } on FormatException {
        _add(
          issues,
          'ML4_POLICY_NUMERIC_PATTERN_REGEX',
          r'$policy.numericSignalPatterns[' + i.toString() + ']',
          'Numeric signal pattern must compile as a regular expression.',
        );
      }
    }

    if (seen.length < 10) {
      _add(
        issues,
        'ML4_POLICY_NUMERIC_PATTERN_COVERAGE',
        r'$policy.numericSignalPatterns',
        'Numeric signal policy must retain broad measurement coverage.',
      );
    }
  }

  void _validateForbiddenPhrases(
    dynamic value,
    List<ClaimSemanticsPolicyIssue> issues,
  ) {
    if (value is! Map) {
      _add(
        issues,
        'ML4_POLICY_AUTHORITY_FORBIDDEN_PHRASES',
        r'$policy.authoritySpecificForbiddenPhrases',
        'Authority-specific forbidden phrase map is required.',
      );
      return;
    }

    final map = Map<String, dynamic>.from(value);
    for (final entry in map.entries) {
      if (!AuthorityRegistryValidator.requiredAuthorityIds.contains(
        entry.key,
      )) {
        _add(
          issues,
          'ML4_POLICY_FORBIDDEN_UNKNOWN_AUTHORITY',
          r'$policy.authoritySpecificForbiddenPhrases.' + entry.key,
          'Forbidden-phrase policy references an unknown authority.',
        );
      }

      _validateNonEmptyUniqueStringList(
        entry.value,
        r'$policy.authoritySpecificForbiddenPhrases.' + entry.key,
        'ML4_POLICY_FORBIDDEN_VALUES',
        issues,
      );
    }

    for (final requiredId in const {
      'SRC-02',
      'SRC-06',
      'SRC-11',
      'SRC-14',
      'SRC-15',
    }) {
      if (!map.containsKey(requiredId)) {
        _add(
          issues,
          'ML4_POLICY_FORBIDDEN_COVERAGE',
          r'$policy.authoritySpecificForbiddenPhrases',
          'Frozen authority-specific safeguards are missing for ' +
              requiredId +
              '.',
        );
      }
    }
  }

  static void _expectExactStringSet(
    dynamic value,
    Set<String> expected,
    String path,
    String code,
    List<ClaimSemanticsPolicyIssue> issues,
  ) {
    final actual = _stringSet(value);
    if (!_sameSet(actual, expected)) {
      _add(
        issues,
        code,
        path,
        'Value set does not match the frozen ML-4 policy.',
      );
    }
  }

  static void _validateNonEmptyUniqueStringList(
    dynamic value,
    String path,
    String code,
    List<ClaimSemanticsPolicyIssue> issues,
  ) {
    if (value is! List || value.isEmpty) {
      _add(issues, code, path, 'A non-empty string list is required.');
      return;
    }

    final seen = <String>{};
    for (var i = 0; i < value.length; i++) {
      final item = value[i];
      if (item is! String || item.trim().isEmpty || !seen.add(item)) {
        _add(
          issues,
          code,
          path + '[' + i.toString() + ']',
          'Items must be unique non-empty strings.',
        );
      }
    }
  }

  static void _exactKeys(
    Map<String, dynamic> map,
    Set<String> expected,
    String path,
    List<ClaimSemanticsPolicyIssue> issues,
  ) {
    final actual = map.keys.toSet();

    for (final missing in expected.difference(actual)) {
      _add(
        issues,
        'ML4_POLICY_REQUIRED_FIELD',
        path + '.' + missing,
        'Required policy field is missing.',
      );
    }

    for (final extra in actual.difference(expected)) {
      _add(
        issues,
        'ML4_POLICY_UNKNOWN_FIELD',
        path + '.' + extra,
        'Unknown policy field is not allowed.',
      );
    }
  }

  static Set<String> _stringSet(dynamic value) {
    if (value is! List) {
      return <String>{};
    }
    return value.whereType<String>().toSet();
  }

  static bool _sameSet(Set<String> a, Set<String> b) =>
      a.length == b.length && a.containsAll(b);

  static bool _isStrictDate(dynamic value) {
    if (value is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}
      return false;
    }

    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return false;
    }

    final normalized =
        parsed.year.toString().padLeft(4, '0') +
        '-' +
        parsed.month.toString().padLeft(2, '0') +
        '-' +
        parsed.day.toString().padLeft(2, '0');

    return normalized == value;
  }

  static void _add(
    List<ClaimSemanticsPolicyIssue> issues,
    String code,
    String path,
    String message,
  ) {
    issues.add(
      ClaimSemanticsPolicyIssue(code: code, path: path, message: message),
    );
  }
}
).hasMatch(value)) {
      return false;
    }

    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return false;
    }

    final normalized =
        parsed.year.toString().padLeft(4, '0') +
        '-' +
        parsed.month.toString().padLeft(2, '0') +
        '-' +
        parsed.day.toString().padLeft(2, '0');

    return normalized == value;
  }

  static void _add(
    List<ClaimSemanticsPolicyIssue> issues,
    String code,
    String path,
    String message,
  ) {
    issues.add(
      ClaimSemanticsPolicyIssue(code: code, path: path, message: message),
    );
  }
}
