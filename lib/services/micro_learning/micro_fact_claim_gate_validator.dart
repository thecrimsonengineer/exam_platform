import 'dart:convert';

import 'authority_registry_validator.dart';
import 'micro_fact_schema_validator.dart';
import 'micro_fact_source_gate_validator.dart';

class MicroFactClaimGateIssue {
  const MicroFactClaimGateIssue({
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

class MicroFactClaimGateResult {
  const MicroFactClaimGateResult(this.issues);

  final List<MicroFactClaimGateIssue> issues;

  bool get isValid => issues.isEmpty;
}

class MicroFactClaimGateValidator {
  static const String requiredPolicyVersion = '1.0.0';

  const MicroFactClaimGateValidator();

  MicroFactClaimGateResult validateJson({
    required String microFactJson,
    required String authorityRegistryJson,
    required String claimPolicyJson,
  }) {
    dynamic factDecoded;
    dynamic registryDecoded;
    dynamic policyDecoded;

    try {
      factDecoded = jsonDecode(microFactJson);
    } on FormatException catch (error) {
      return MicroFactClaimGateResult([
        MicroFactClaimGateIssue(
          code: 'ML4_FACT_JSON_INVALID',
          path: r'$',
          message: error.message,
        ),
      ]);
    }

    try {
      registryDecoded = jsonDecode(authorityRegistryJson);
    } on FormatException catch (error) {
      return MicroFactClaimGateResult([
        MicroFactClaimGateIssue(
          code: 'ML4_REGISTRY_JSON_INVALID',
          path: r'$registry',
          message: error.message,
        ),
      ]);
    }

    try {
      policyDecoded = jsonDecode(claimPolicyJson);
    } on FormatException catch (error) {
      return MicroFactClaimGateResult([
        MicroFactClaimGateIssue(
          code: 'ML4_POLICY_JSON_INVALID',
          path: r'$policy',
          message: error.message,
        ),
      ]);
    }

    if (factDecoded is! Map<String, dynamic>) {
      return const MicroFactClaimGateResult([
        MicroFactClaimGateIssue(
          code: 'ML4_FACT_ROOT_INVALID',
          path: r'$',
          message: 'MicroFact root must be a JSON object.',
        ),
      ]);
    }

    if (registryDecoded is! Map<String, dynamic>) {
      return const MicroFactClaimGateResult([
        MicroFactClaimGateIssue(
          code: 'ML4_REGISTRY_ROOT_INVALID',
          path: r'$registry',
          message: 'Authority registry root must be a JSON object.',
        ),
      ]);
    }

    if (policyDecoded is! Map<String, dynamic>) {
      return const MicroFactClaimGateResult([
        MicroFactClaimGateIssue(
          code: 'ML4_POLICY_ROOT_INVALID',
          path: r'$policy',
          message: 'Claim-semantics policy root must be a JSON object.',
        ),
      ]);
    }

    return validateMaps(
      microFact: factDecoded,
      authorityRegistry: registryDecoded,
      claimPolicy: policyDecoded,
    );
  }

  MicroFactClaimGateResult validateMaps({
    required Map<String, dynamic> microFact,
    required Map<String, dynamic> authorityRegistry,
    required Map<String, dynamic> claimPolicy,
  }) {
    final issues = <MicroFactClaimGateIssue>[];

    final sourceGate = const MicroFactSourceGateValidator().validateMaps(
      microFact: microFact,
      authorityRegistry: authorityRegistry,
    );
    if (!sourceGate.isValid) {
      for (final issue in sourceGate.issues) {
        _add(
          issues,
          'ML4_SOURCE_PREREQUISITE_INVALID',
          issue.path,
          issue.code + ': ' + issue.message,
        );
      }
    }

    _validatePolicy(claimPolicy, issues);

    if (issues.isNotEmpty) {
      return MicroFactClaimGateResult(List.unmodifiable(issues));
    }

    final provenance = Map<String, dynamic>.from(
      microFact['provenance'] as Map,
    );
    final claim = Map<String, dynamic>.from(microFact['claim'] as Map);
    final display = Map<String, dynamic>.from(microFact['display'] as Map);
    final review = Map<String, dynamic>.from(microFact['review'] as Map);

    final status = microFact['status'] as String;
    final category = microFact['category'] as String;
    final sourceRegistryId = provenance['sourceRegistryId'] as String;
    final sourceClass = provenance['sourceClass'] as String;
    final legalStatus = claim['legalStatus'] as String;
    final jurisdiction = claim['jurisdiction'] as String?;
    final numericalClaim = claim['numericalClaim'] as bool;
    final safetyCritical = claim['safetyCritical'] as bool;
    final simplificationRisk = claim['simplificationRisk'] as String;

    final sourceRule = _findSourceClassRule(claimPolicy, sourceClass);
    if (sourceRule == null) {
      _add(
        issues,
        'ML4_SOURCE_CLASS_POLICY_MISSING',
        r'$policy.sourceClassRules',
        'No ML-4 rule exists for source class ' + sourceClass + '.',
      );
      return MicroFactClaimGateResult(List.unmodifiable(issues));
    }

    final allowedLegalStatuses = (sourceRule['allowedLegalStatuses'] as List)
        .whereType<String>()
        .toSet();

    if (!allowedLegalStatuses.contains(legalStatus)) {
      _add(
        issues,
        'ML4_LEGAL_STATUS_SOURCE_CLASS_MISMATCH',
        r'$.claim.legalStatus',
        'Legal status ' +
            legalStatus +
            ' is not permitted for source class ' +
            sourceClass +
            '.',
      );
    }

    final authority = _findAuthority(authorityRegistry, sourceRegistryId);
    if (authority == null) {
      _add(
        issues,
        'ML4_AUTHORITY_MISSING',
        r'$.provenance.sourceRegistryId',
        'Authority disappeared after ML-3 prerequisite validation.',
      );
      return MicroFactClaimGateResult(List.unmodifiable(issues));
    }

    final regulatoryAuthority = authority['regulatoryAuthority'] as bool;
    if ((legalStatus == 'binding_requirement' ||
            legalStatus == 'regulatory_interpretation') &&
        !regulatoryAuthority) {
      _add(
        issues,
        'ML4_NONREGULATOR_CANNOT_CREATE_LEGAL_DUTY',
        r'$.claim.legalStatus',
        'A non-regulatory authority cannot be represented as creating a binding legal duty or regulatory interpretation.',
      );
    }

    final jurisdictionRule = sourceRule['jurisdiction'] as String;
    if (jurisdictionRule == 'required' && !_nonEmpty(jurisdiction)) {
      _add(
        issues,
        'ML4_JURISDICTION_REQUIRED',
        r'$.claim.jurisdiction',
        'Jurisdiction is required for source class ' + sourceClass + '.',
      );
    }

    if ((legalStatus == 'binding_requirement' ||
            legalStatus == 'regulatory_interpretation') &&
        !_nonEmpty(jurisdiction)) {
      _add(
        issues,
        'ML4_LEGAL_CLAIM_JURISDICTION_REQUIRED',
        r'$.claim.jurisdiction',
        'Binding and interpretive legal claims require explicit jurisdiction.',
      );
    }

    final nonApplicableCategories = (claimPolicy['nonApplicableCategories'] as List)
        .whereType<String>()
        .toSet();

    if (legalStatus == 'not_applicable' &&
        !nonApplicableCategories.contains(category)) {
      _add(
        issues,
        'ML4_NOT_APPLICABLE_CATEGORY_MISMATCH',
        r'$.claim.legalStatus',
        'not_applicable legal status is reserved for CSP and learning tips.',
      );
    }

    if (nonApplicableCategories.contains(category) &&
        legalStatus != 'not_applicable') {
      _add(
        issues,
        'ML4_TIP_LEGAL_STATUS_NOT_APPLICABLE_REQUIRED',
        r'$.claim.legalStatus',
        'CSP and learning tips must use not_applicable legal status.',
      );
    }

    if (legalStatus == 'not_applicable' && _nonEmpty(jurisdiction)) {
      _add(
        issues,
        'ML4_NOT_APPLICABLE_JURISDICTION_PRESENT',
        r'$.claim.jurisdiction',
        'A not_applicable legal-status claim must not carry jurisdiction.',
      );
    }

    final variants = <MapEntry<String, String>>[
      MapEntry(r'$.display.displayText', display['displayText'] as String),
    ];
    final shortVariant = display['shortVariant'] as String?;
    if (shortVariant != null) {
      variants.add(
        MapEntry(r'$.display.shortVariant', shortVariant),
      );
    }

    for (final variant in variants) {
      _validateVariantWording(
        text: variant.value,
        path: variant.key,
        sourceRegistryId: sourceRegistryId,
        sourceClass: sourceClass,
        legalStatus: legalStatus,
        sourceRule: sourceRule,
        claimPolicy: claimPolicy,
        numericalClaim: numericalClaim,
        issues: issues,
      );
    }

    final enhancedReview = Map<String, dynamic>.from(
      claimPolicy['enhancedReview'] as Map,
    );
    final reviewStatuses = (enhancedReview['appliesWhenStatusIn'] as List)
        .whereType<String>()
        .toSet();

    if (reviewStatuses.contains(status)) {
      _requireReviewPasses(
        review: review,
        fields: (enhancedReview['validatedOrPublishedRequiresPass'] as List)
            .whereType<String>(),
        code: 'ML4_FACTUAL_REVIEW_REQUIRED',
        issues: issues,
      );

      final technicalCategories = (claimPolicy['technicalCategories'] as List)
          .whereType<String>()
          .toSet();
      if (technicalCategories.contains(category) &&
          enhancedReview['technicalCategoryRequiresHumanPass'] == true &&
          review['humanTechnicalStatus'] != 'pass') {
        _add(
          issues,
          'ML4_HUMAN_TECHNICAL_REVIEW_REQUIRED',
          r'$.review.humanTechnicalStatus',
          'Validated or published technical facts require human technical approval.',
        );
      }

      if (numericalClaim) {
        _requireReviewPasses(
          review: review,
          fields: (enhancedReview['numericalClaimRequiresPass'] as List)
              .whereType<String>(),
          code: 'ML4_NUMERICAL_REVIEW_REQUIRED',
          issues: issues,
        );

        final evidenceFields =
            (enhancedReview['numericalEvidenceRequiresOneOf'] as List)
                .whereType<String>();
        final hasEvidenceLocator = evidenceFields.any(
          (field) => _nonEmpty(provenance[field] as String?),
        );
        if (!hasEvidenceLocator) {
          _add(
            issues,
            'ML4_NUMERICAL_EVIDENCE_LOCATOR_REQUIRED',
            r'$.provenance',
            'Validated or published numerical claims require edition, section, or page evidence metadata.',
          );
        }
      }

      if (safetyCritical) {
        _requireReviewPasses(
          review: review,
          fields: (enhancedReview['safetyCriticalRequiresPass'] as List)
              .whereType<String>(),
          code: 'ML4_SAFETY_CRITICAL_REVIEW_REQUIRED',
          issues: issues,
        );
      }

      if (simplificationRisk == 'high') {
        _requireReviewPasses(
          review: review,
          fields: (enhancedReview['highSimplificationRiskRequiresPass'] as List)
              .whereType<String>(),
          code: 'ML4_HIGH_SIMPLIFICATION_REVIEW_REQUIRED',
          issues: issues,
        );
      }

      final genericLocators = (claimPolicy['genericSourceLocators'] as List)
          .whereType<String>()
          .map(_normalize)
          .toSet();
      final sourceLocator = provenance['sourceLocator'] as String;
      if (genericLocators.contains(_normalize(sourceLocator))) {
        _add(
          issues,
          'ML4_SOURCE_LOCATOR_TOO_GENERIC',
          r'$.provenance.sourceLocator',
          'Validated or published facts require a specific source locator.',
        );
      }

      if ((legalStatus == 'binding_requirement' ||
              legalStatus == 'regulatory_interpretation') &&
          !_nonEmpty(provenance['sourceSection'] as String?) &&
          !_nonEmpty(provenance['sourcePage'] as String?)) {
        _add(
          issues,
          'ML4_LEGAL_SOURCE_LOCATION_REQUIRED',
          r'$.provenance',
          'Validated or published legal claims require a source section or page in addition to the general locator.',
        );
      }
    }

    return MicroFactClaimGateResult(List.unmodifiable(issues));
  }

  void _validateVariantWording({
    required String text,
    required String path,
    required String sourceRegistryId,
    required String sourceClass,
    required String legalStatus,
    required Map<String, dynamic> sourceRule,
    required Map<String, dynamic> claimPolicy,
    required bool numericalClaim,
    required List<MicroFactClaimGateIssue> issues,
  }) {
    final normalizedText = _normalize(text);
    final mandatoryTerms = (claimPolicy['mandatoryTerms'] as List)
        .whereType<String>();
    final hasMandatoryLanguage = mandatoryTerms.any(
      (term) => _containsPhrase(normalizedText, _normalize(term)),
    );

    final attributionTokensRaw = Map<String, dynamic>.from(
      claimPolicy['authorityAttributionTokens'] as Map,
    );
    final attributionTokens =
        (attributionTokensRaw[sourceRegistryId] as List).whereType<String>();
    final hasAttribution = attributionTokens.any(
      (token) => _containsPhrase(normalizedText, _normalize(token)),
    );

    final mandatoryMode = sourceRule['mandatoryLanguage'] as String;
    if (hasMandatoryLanguage && mandatoryMode == 'blocked') {
      _add(
        issues,
        'ML4_NONBINDING_MANDATORY_LANGUAGE',
        path,
        'Mandatory legal wording is not allowed for source class ' +
            sourceClass +
            '.',
      );
    }

    if (hasMandatoryLanguage &&
        mandatoryMode == 'attributed_only' &&
        !hasAttribution) {
      _add(
        issues,
        'ML4_MANDATORY_LANGUAGE_REQUIRES_ATTRIBUTION',
        path,
        'Mandatory wording from this source class must be explicitly attributed to the authority or standard.',
      );
    }

    if (hasMandatoryLanguage &&
        legalStatus == 'binding_requirement' &&
        !hasAttribution) {
      _add(
        issues,
        'ML4_BINDING_MANDATE_REQUIRES_ATTRIBUTION',
        path,
        'A binding mandate shown to the learner must identify its regulatory authority or CFR context.',
      );
    }

    if (legalStatus == 'regulatory_interpretation' && !hasAttribution) {
      _add(
        issues,
        'ML4_INTERPRETATION_REQUIRES_ATTRIBUTION',
        path,
        'Regulatory interpretation wording must identify the interpreting authority.',
      );
    }

    final legalEquivalencePhrases = (claimPolicy['legalEquivalencePhrases'] as List)
        .whereType<String>();
    final containsLegalEquivalence = legalEquivalencePhrases.any(
      (phrase) => _containsPhrase(normalizedText, _normalize(phrase)),
    );
    if (containsLegalEquivalence && legalStatus != 'binding_requirement') {
      _add(
        issues,
        'ML4_FALSE_LEGAL_EQUIVALENCE',
        path,
        'Non-binding material cannot be described as having binding legal force.',
      );
    }

    final forbiddenByAuthority = Map<String, dynamic>.from(
      claimPolicy['authoritySpecificForbiddenPhrases'] as Map,
    );
    final forbiddenPhrases = forbiddenByAuthority[sourceRegistryId];
    if (forbiddenPhrases is List) {
      for (final phrase in forbiddenPhrases.whereType<String>()) {
        if (_containsPhrase(normalizedText, _normalize(phrase))) {
          _add(
            issues,
            'ML4_AUTHORITY_SPECIFIC_MISATTRIBUTION',
            path,
            'Wording conflicts with frozen authority semantics: ' + phrase + '.',
          );
        }
      }
    }

    final numericPatterns = (claimPolicy['numericSignalPatterns'] as List)
        .whereType<String>();
    final hasNumericSignal = numericPatterns.any(
      (pattern) => RegExp(pattern, caseSensitive: false).hasMatch(text),
    );
    if (hasNumericSignal && !numericalClaim) {
      _add(
        issues,
        'ML4_NUMERICAL_FLAG_MISMATCH',
        path,
        'Display wording contains a numerical safety signal but numericalClaim is false.',
      );
    }
  }

  void _validatePolicy(
    Map<String, dynamic> policy,
    List<MicroFactClaimGateIssue> issues,
  ) {
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
        'Claim-semantics policy version must be ' +
            requiredPolicyVersion +
            '.',
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

    final sourceRules = policy['sourceClassRules'];
    if (sourceRules is! List) {
      _add(
        issues,
        'ML4_POLICY_SOURCE_RULES',
        r'$policy.sourceClassRules',
        'sourceClassRules must be a list.',
      );
      return;
    }

    final seenClasses = <String>{};
    for (var i = 0; i < sourceRules.length; i++) {
      final item = sourceRules[i];
      if (item is! Map) {
        _add(
          issues,
          'ML4_POLICY_SOURCE_RULE_OBJECT',
          r'$policy.sourceClassRules[' + i.toString() + ']',
          'Source-class policy entry must be an object.',
        );
        continue;
      }

      final rule = Map<String, dynamic>.from(item);
      final sourceClass = rule['sourceClass'];
      if (sourceClass is! String ||
          !MicroFactSchemaValidator.sourceClasses.contains(sourceClass)) {
        _add(
          issues,
          'ML4_POLICY_SOURCE_CLASS',
          r'$policy.sourceClassRules[' + i.toString() + '].sourceClass',
          'Unknown source class in ML-4 policy.',
        );
        continue;
      }

      if (!seenClasses.add(sourceClass)) {
        _add(
          issues,
          'ML4_POLICY_DUPLICATE_SOURCE_CLASS',
          r'$policy.sourceClassRules[' + i.toString() + '].sourceClass',
          'Duplicate source-class rule.',
        );
      }

      final legalStatuses = rule['allowedLegalStatuses'];
      if (legalStatuses is! List ||
          legalStatuses.isEmpty ||
          legalStatuses.any(
            (value) =>
                value is! String ||
                !MicroFactSchemaValidator.legalStatuses.contains(value),
          )) {
        _add(
          issues,
          'ML4_POLICY_LEGAL_STATUSES',
          r'$policy.sourceClassRules[' +
              i.toString() +
              '].allowedLegalStatuses',
          'Each source class requires valid allowed legal statuses.',
        );
      }

      if (!{'required', 'optional'}.contains(rule['jurisdiction'])) {
        _add(
          issues,
          'ML4_POLICY_JURISDICTION_RULE',
          r'$policy.sourceClassRules[' + i.toString() + '].jurisdiction',
          'Jurisdiction rule must be required or optional.',
        );
      }

      if (!{'allowed', 'blocked', 'attributed_only'}
          .contains(rule['mandatoryLanguage'])) {
        _add(
          issues,
          'ML4_POLICY_MANDATORY_RULE',
          r'$policy.sourceClassRules[' +
              i.toString() +
              '].mandatoryLanguage',
          'Unknown mandatory-language policy.',
        );
      }
    }

    if (seenClasses.length != MicroFactSchemaValidator.sourceClasses.length ||
        !seenClasses.containsAll(MicroFactSchemaValidator.sourceClasses)) {
      _add(
        issues,
        'ML4_POLICY_SOURCE_CLASS_COVERAGE',
        r'$policy.sourceClassRules',
        'ML-4 policy must cover every frozen ML-2 source class exactly once.',
      );
    }

    final attribution = policy['authorityAttributionTokens'];
    if (attribution is! Map) {
      _add(
        issues,
        'ML4_POLICY_ATTRIBUTION_TOKENS',
        r'$policy.authorityAttributionTokens',
        'Authority attribution token map is required.',
      );
    } else {
      final keys = attribution.keys.whereType<String>().toSet();
      if (keys.length != AuthorityRegistryValidator.requiredAuthorityIds.length ||
          !keys.containsAll(
            AuthorityRegistryValidator.requiredAuthorityIds,
          )) {
        _add(
          issues,
          'ML4_POLICY_AUTHORITY_COVERAGE',
          r'$policy.authorityAttributionTokens',
          'Attribution policy must cover all 15 frozen authority families.',
        );
      }
      for (final key in keys) {
        final values = attribution[key];
        if (values is! List ||
            values.isEmpty ||
            values.any((value) => value is! String || value.trim().isEmpty)) {
          _add(
            issues,
            'ML4_POLICY_ATTRIBUTION_VALUES',
            r'$policy.authorityAttributionTokens.' + key,
            'Each authority requires at least one attribution token.',
          );
        }
      }
    }

    for (final field in [
      'mandatoryTerms',
      'legalEquivalencePhrases',
      'nonApplicableCategories',
      'technicalCategories',
      'genericSourceLocators',
      'numericSignalPatterns',
    ]) {
      final value = policy[field];
      if (value is! List ||
          value.isEmpty ||
          value.any((item) => item is! String || item.trim().isEmpty)) {
        _add(
          issues,
          'ML4_POLICY_LIST_INVALID',
          r'$policy.' + field,
          field + ' must be a non-empty string list.',
        );
      }
    }

    if (policy['enhancedReview'] is! Map) {
      _add(
        issues,
        'ML4_POLICY_ENHANCED_REVIEW',
        r'$policy.enhancedReview',
        'Enhanced review policy is required.',
      );
    }

    if (policy['authoritySpecificForbiddenPhrases'] is! Map) {
      _add(
        issues,
        'ML4_POLICY_AUTHORITY_FORBIDDEN_PHRASES',
        r'$policy.authoritySpecificForbiddenPhrases',
        'Authority-specific forbidden phrase map is required.',
      );
    }
  }

  static Map<String, dynamic>? _findSourceClassRule(
    Map<String, dynamic> policy,
    String sourceClass,
  ) {
    final rules = policy['sourceClassRules'];
    if (rules is! List) {
      return null;
    }

    for (final item in rules) {
      if (item is Map && item['sourceClass'] == sourceClass) {
        return Map<String, dynamic>.from(item);
      }
    }
    return null;
  }

  static Map<String, dynamic>? _findAuthority(
    Map<String, dynamic> registry,
    String sourceRegistryId,
  ) {
    final authorities = registry['authorities'];
    if (authorities is! List) {
      return null;
    }

    for (final item in authorities) {
      if (item is Map && item['id'] == sourceRegistryId) {
        return Map<String, dynamic>.from(item);
      }
    }
    return null;
  }

  static void _requireReviewPasses({
    required Map<String, dynamic> review,
    required Iterable<String> fields,
    required String code,
    required List<MicroFactClaimGateIssue> issues,
  }) {
    for (final field in fields) {
      if (review[field] != 'pass') {
        _add(
          issues,
          code,
          r'$.review.' + field,
          field + ' must be pass at this lifecycle stage.',
        );
      }
    }
  }

  static bool _nonEmpty(String? value) =>
      value != null && value.trim().isNotEmpty;

  static String _normalize(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

  static bool _containsPhrase(String normalizedText, String normalizedPhrase) {
    final escaped = RegExp.escape(normalizedPhrase);
    return RegExp(
      '(^|[^a-z0-9])' + escaped + r'($|[^a-z0-9])',
      caseSensitive: false,
    ).hasMatch(normalizedText);
  }

  static void _add(
    List<MicroFactClaimGateIssue> issues,
    String code,
    String path,
    String message,
  ) {
    issues.add(MicroFactClaimGateIssue(
      code: code,
      path: path,
      message: message,
    ));
  }
}
