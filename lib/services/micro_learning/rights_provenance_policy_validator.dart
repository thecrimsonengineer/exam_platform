import 'authority_registry_validator.dart';
import 'claim_semantics_policy_validator.dart';
import 'micro_fact_schema_validator.dart';
import 'micro_fact_source_gate_validator.dart';

class RightsProvenancePolicyIssue {
  const RightsProvenancePolicyIssue({
    required this.code,
    required this.path,
    required this.message,
  });

  final String code;
  final String path;
  final String message;

  @override
  String toString() => '$code at $path: $message';
}

class RightsProvenancePolicyValidationResult {
  const RightsProvenancePolicyValidationResult(this.issues);

  final List<RightsProvenancePolicyIssue> issues;

  bool get isValid => issues.isEmpty;
}

class RightsProvenancePolicyValidator {
  static const String requiredPolicyVersion = '1.0.0';

  static const Set<String> requiredRootKeys = {
    'schemaVersion',
    'policyVersion',
    'status',
    'frozenAt',
    'authorityRegistryVersion',
    'microFactSchemaVersion',
    'claimPolicyVersion',
    'failClosed',
    'principles',
    'authorityRightsTiers',
    'rightsTreatments',
    'lifecycle',
    'prohibitedReuse',
    'evidenceRules',
    'rightsSensitiveRules',
    'governmentSourceRules',
  };

  static const Set<String> governmentAuthorityIds = {
    'SRC-01',
    'SRC-02',
    'SRC-08',
    'SRC-09',
    'SRC-10',
  };

  static const Set<String> rightsSensitiveAuthorityIds = {
    'SRC-03',
    'SRC-04',
    'SRC-05',
    'SRC-06',
    'SRC-07',
    'SRC-11',
    'SRC-12',
    'SRC-13',
    'SRC-14',
    'SRC-15',
  };

  static const Set<String> reviewerRoles = {
    'copyright_reviewer',
    'content_governance_reviewer',
    'legal_or_rights_reviewer',
  };

  static const Set<String> reviewStatuses = {'pending', 'pass', 'fail'};

  const RightsProvenancePolicyValidator();

  RightsProvenancePolicyValidationResult validateMap(
    Map<String, dynamic> policy,
  ) {
    final issues = <RightsProvenancePolicyIssue>[];

    _exactKeys(policy, requiredRootKeys, r'$policy', issues);

    if (policy['schemaVersion'] != 1) {
      _add(
        issues,
        'ML5_POLICY_SCHEMA_VERSION',
        r'$policy.schemaVersion',
        'Rights policy schemaVersion must be 1.',
      );
    }

    if (policy['policyVersion'] != requiredPolicyVersion) {
      _add(
        issues,
        'ML5_POLICY_VERSION',
        r'$policy.policyVersion',
        'Rights policy version must be $requiredPolicyVersion.',
      );
    }

    if (policy['status'] != 'frozen' || policy['failClosed'] != true) {
      _add(
        issues,
        'ML5_POLICY_NOT_FROZEN',
        r'$policy',
        'ML-5 policy must remain frozen and fail closed.',
      );
    }

    if (!_isStrictDate(policy['frozenAt'])) {
      _add(
        issues,
        'ML5_POLICY_FROZEN_DATE',
        r'$policy.frozenAt',
        'frozenAt must be a valid YYYY-MM-DD date.',
      );
    }

    if (policy['authorityRegistryVersion'] !=
        MicroFactSourceGateValidator.requiredRegistryVersion) {
      _add(
        issues,
        'ML5_POLICY_REGISTRY_VERSION',
        r'$policy.authorityRegistryVersion',
        'ML-5 must bind to the frozen ML-1 registry version.',
      );
    }

    if (policy['microFactSchemaVersion'] !=
        MicroFactSchemaValidator.schemaVersion) {
      _add(
        issues,
        'ML5_POLICY_FACT_SCHEMA_VERSION',
        r'$policy.microFactSchemaVersion',
        'ML-5 must bind to MicroFact schema v1.',
      );
    }

    if (policy['claimPolicyVersion'] !=
        ClaimSemanticsPolicyValidator.requiredPolicyVersion) {
      _add(
        issues,
        'ML5_POLICY_CLAIM_VERSION',
        r'$policy.claimPolicyVersion',
        'ML-5 must bind to the frozen ML-4 claim policy.',
      );
    }

    _validatePrinciples(policy['principles'], issues);
    _validateAuthorityTiers(policy['authorityRightsTiers'], issues);
    _validateRightsTreatments(policy['rightsTreatments'], issues);
    _validateLifecycle(policy['lifecycle'], issues);
    _validateProhibitedReuse(policy['prohibitedReuse'], issues);
    _validateEvidenceRules(policy['evidenceRules'], issues);
    _validateRightsSensitiveRules(policy['rightsSensitiveRules'], issues);
    _validateGovernmentRules(policy['governmentSourceRules'], issues);

    return RightsProvenancePolicyValidationResult(List.unmodifiable(issues));
  }

  void _validatePrinciples(
    dynamic value,
    List<RightsProvenancePolicyIssue> issues,
  ) {
    if (value is! Map) {
      _add(
        issues,
        'ML5_POLICY_PRINCIPLES',
        r'$policy.principles',
        'Rights principles object is required.',
      );
      return;
    }

    final map = Map<String, dynamic>.from(value);
    const keys = {
      'aiIsRightsAuthority',
      'publicDomainAssumptionAllowed',
      'fairUseAutoDeterminationAllowed',
      'sourceAvailabilityImpliesReusePermission',
      'citationAloneCreatesReusePermission',
      'preferOriginalParaphrase',
      'requireHumanCopyrightReviewForValidatedOrPublished',
      'requireRightsEvidenceForValidatedOrPublished',
      'rawProtectedSourceStorageInEvidence',
    };
    _exactKeys(map, keys, r'$policy.principles', issues);

    const mustBeFalse = {
      'aiIsRightsAuthority',
      'publicDomainAssumptionAllowed',
      'fairUseAutoDeterminationAllowed',
      'sourceAvailabilityImpliesReusePermission',
      'citationAloneCreatesReusePermission',
      'rawProtectedSourceStorageInEvidence',
    };
    for (final key in mustBeFalse) {
      if (map[key] != false) {
        _add(
          issues,
          'ML5_POLICY_PRINCIPLE_WEAKENED',
          r'$policy.principles.$key',
          '$key must remain false.',
        );
      }
    }

    const mustBeTrue = {
      'preferOriginalParaphrase',
      'requireHumanCopyrightReviewForValidatedOrPublished',
      'requireRightsEvidenceForValidatedOrPublished',
    };
    for (final key in mustBeTrue) {
      if (map[key] != true) {
        _add(
          issues,
          'ML5_POLICY_PRINCIPLE_WEAKENED',
          r'$policy.principles.$key',
          '$key must remain true.',
        );
      }
    }
  }

  void _validateAuthorityTiers(
    dynamic value,
    List<RightsProvenancePolicyIssue> issues,
  ) {
    if (value is! Map) {
      _add(
        issues,
        'ML5_POLICY_AUTHORITY_TIERS',
        r'$policy.authorityRightsTiers',
        'Authority rights tiers are required.',
      );
      return;
    }

    final map = Map<String, dynamic>.from(value);
    _exactKeys(
      map,
      const {
        'government_first_party',
        'rights_sensitive_professional_or_standards',
      },
      r'$policy.authorityRightsTiers',
      issues,
    );

    final government = _stringSet(map['government_first_party']);
    final sensitive = _stringSet(
      map['rights_sensitive_professional_or_standards'],
    );

    if (!_sameSet(government, governmentAuthorityIds)) {
      _add(
        issues,
        'ML5_POLICY_GOVERNMENT_TIER',
        r'$policy.authorityRightsTiers.government_first_party',
        'Government rights tier does not match the frozen ML-5 set.',
      );
    }

    if (!_sameSet(sensitive, rightsSensitiveAuthorityIds)) {
      _add(
        issues,
        'ML5_POLICY_SENSITIVE_TIER',
        r'$policy.authorityRightsTiers.rights_sensitive_professional_or_standards',
        'Rights-sensitive tier does not match the frozen ML-5 set.',
      );
    }

    final all = {...government, ...sensitive};
    if (!_sameSet(all, AuthorityRegistryValidator.requiredAuthorityIds) ||
        government.intersection(sensitive).isNotEmpty) {
      _add(
        issues,
        'ML5_POLICY_AUTHORITY_PARTITION',
        r'$policy.authorityRightsTiers',
        'Authority tiers must form a complete non-overlapping partition.',
      );
    }
  }

  void _validateRightsTreatments(
    dynamic value,
    List<RightsProvenancePolicyIssue> issues,
  ) {
    if (value is! Map) {
      _add(
        issues,
        'ML5_POLICY_RIGHTS_TREATMENTS',
        r'$policy.rightsTreatments',
        'Rights-treatment policy is required.',
      );
      return;
    }

    final map = Map<String, dynamic>.from(value);
    if (!_sameSet(map.keys.toSet(), MicroFactSchemaValidator.rightsTreatments)) {
      _add(
        issues,
        'ML5_POLICY_RIGHTS_TREATMENT_COVERAGE',
        r'$policy.rightsTreatments',
        'Every frozen ML-2 rights treatment must be covered exactly once.',
      );
    }

    _validateParaphraseLikeRule(
      map['original_paraphrase'],
      r'$policy.rightsTreatments.original_paraphrase',
      issues,
    );
    _validateParaphraseLikeRule(
      map['brief_summary'],
      r'$policy.rightsTreatments.brief_summary',
      issues,
    );

    final minimal = _requiredMap(
      map['minimal_quote'],
      r'$policy.rightsTreatments.minimal_quote',
      'ML5_POLICY_MINIMAL_QUOTE_RULE',
      issues,
    );
    if (minimal != null) {
      _exactKeys(
        minimal,
        const {
          'directQuoteAllowed',
          'licenseRequired',
          'sourceComparisonRequired',
          'independentWordingRequired',
          'maxQuoteWordsPerFact',
          'maxQuoteSegmentsPerFact',
          'sourceLocationRequired',
          'quoteNecessityRequired',
          'quoteHashRequired',
          'protectedStructureCopyAllowed',
        },
        r'$policy.rightsTreatments.minimal_quote',
        issues,
      );
      if (minimal['directQuoteAllowed'] != true ||
          minimal['licenseRequired'] != false ||
          minimal['sourceComparisonRequired'] != true ||
          minimal['independentWordingRequired'] != false ||
          minimal['maxQuoteWordsPerFact'] != 12 ||
          minimal['maxQuoteSegmentsPerFact'] != 1 ||
          minimal['sourceLocationRequired'] != true ||
          minimal['quoteNecessityRequired'] != true ||
          minimal['quoteHashRequired'] != true ||
          minimal['protectedStructureCopyAllowed'] != false) {
        _add(
          issues,
          'ML5_POLICY_MINIMAL_QUOTE_WEAKENED',
          r'$policy.rightsTreatments.minimal_quote',
          'Minimal-quote safeguards do not match the frozen ML-5 policy.',
        );
      }
    }

    final licensed = _requiredMap(
      map['licensed_excerpt'],
      r'$policy.rightsTreatments.licensed_excerpt',
      'ML5_POLICY_LICENSED_RULE',
      issues,
    );
    if (licensed != null) {
      _exactKeys(
        licensed,
        const {
          'directQuoteAllowed',
          'licenseRequired',
          'sourceComparisonRequired',
          'independentWordingRequired',
          'sourceLocationRequired',
          'licenseMustPermitStartupDisplay',
          'licenseMustPermitDigitalRedistribution',
          'protectedStructureCopyAllowedOnlyIfExplicitlyLicensed',
        },
        r'$policy.rightsTreatments.licensed_excerpt',
        issues,
      );
      if (licensed['directQuoteAllowed'] != true ||
          licensed['licenseRequired'] != true ||
          licensed['sourceComparisonRequired'] != true ||
          licensed['independentWordingRequired'] != false ||
          licensed['sourceLocationRequired'] != true ||
          licensed['licenseMustPermitStartupDisplay'] != true ||
          licensed['licenseMustPermitDigitalRedistribution'] != true ||
          licensed['protectedStructureCopyAllowedOnlyIfExplicitlyLicensed'] !=
              true) {
        _add(
          issues,
          'ML5_POLICY_LICENSED_EXCERPT_WEAKENED',
          r'$policy.rightsTreatments.licensed_excerpt',
          'Licensed-excerpt safeguards do not match the frozen ML-5 policy.',
        );
      }
    }
  }

  void _validateParaphraseLikeRule(
    dynamic value,
    String path,
    List<RightsProvenancePolicyIssue> issues,
  ) {
    final map = _requiredMap(
      value,
      path,
      'ML5_POLICY_PARAPHRASE_RULE',
      issues,
    );
    if (map == null) {
      return;
    }

    _exactKeys(
      map,
      const {
        'directQuoteAllowed',
        'licenseRequired',
        'sourceComparisonRequired',
        'independentWordingRequired',
        'maxLongestVerbatimRunWords',
        'protectedStructureCopyAllowed',
      },
      path,
      issues,
    );

    if (map['directQuoteAllowed'] != false ||
        map['licenseRequired'] != false ||
        map['sourceComparisonRequired'] != true ||
        map['independentWordingRequired'] != true ||
        map['maxLongestVerbatimRunWords'] != 5 ||
        map['protectedStructureCopyAllowed'] != false) {
      _add(
        issues,
        'ML5_POLICY_PARAPHRASE_RULE_WEAKENED',
        path,
        'Paraphrase/summary safeguards do not match frozen ML-5 policy.',
      );
    }
  }

  void _validateLifecycle(
    dynamic value,
    List<RightsProvenancePolicyIssue> issues,
  ) {
    final map = _requiredMap(
      value,
      r'$policy.lifecycle',
      'ML5_POLICY_LIFECYCLE',
      issues,
    );
    if (map == null) {
      return;
    }

    _exactKeys(
      map,
      const {
        'evidenceRequiredForStatuses',
        'evidenceMustPassForStatuses',
        'startupEligibleRequiresPassingEvidence',
      },
      r'$policy.lifecycle',
      issues,
    );

    if (!_sameSet(
      _stringSet(map['evidenceRequiredForStatuses']),
      const {'validated', 'published', 'review_due'},
    )) {
      _add(
        issues,
        'ML5_POLICY_EVIDENCE_STATUS',
        r'$policy.lifecycle.evidenceRequiredForStatuses',
        'Evidence-required lifecycle statuses were altered.',
      );
    }

    if (!_sameSet(
      _stringSet(map['evidenceMustPassForStatuses']),
      const {'validated', 'published'},
    )) {
      _add(
        issues,
        'ML5_POLICY_PASS_STATUS',
        r'$policy.lifecycle.evidenceMustPassForStatuses',
        'Evidence-pass lifecycle statuses were altered.',
      );
    }

    if (map['startupEligibleRequiresPassingEvidence'] != true) {
      _add(
        issues,
        'ML5_POLICY_STARTUP_EVIDENCE',
        r'$policy.lifecycle.startupEligibleRequiresPassingEvidence',
        'Startup eligibility must continue to require passing rights evidence.',
      );
    }
  }

  void _validateProhibitedReuse(
    dynamic value,
    List<RightsProvenancePolicyIssue> issues,
  ) {
    final map = _requiredMap(
      value,
      r'$policy.prohibitedReuse',
      'ML5_POLICY_PROHIBITED_REUSE',
      issues,
    );
    if (map == null) {
      return;
    }

    _exactKeys(
      map,
      const {
        'withoutExplicitLicense',
        'alwaysBlockedInMicroFactEvidence',
      },
      r'$policy.prohibitedReuse',
      issues,
    );

    _validateNonEmptyUniqueStringList(
      map['withoutExplicitLicense'],
      r'$policy.prohibitedReuse.withoutExplicitLicense',
      'ML5_POLICY_PROHIBITED_REUSE_VALUES',
      issues,
    );
    _validateNonEmptyUniqueStringList(
      map['alwaysBlockedInMicroFactEvidence'],
      r'$policy.prohibitedReuse.alwaysBlockedInMicroFactEvidence',
      'ML5_POLICY_BLOCKED_EVIDENCE_VALUES',
      issues,
    );

    final blocked = _stringSet(map['alwaysBlockedInMicroFactEvidence']);
    const requiredBlocked = {
      'raw_source_document',
      'full_standard',
      'full_book_chapter',
      'paywalled_source_snapshot',
      'copyrighted_table_image',
    };
    if (!blocked.containsAll(requiredBlocked)) {
      _add(
        issues,
        'ML5_POLICY_BLOCKED_EVIDENCE_WEAKENED',
        r'$policy.prohibitedReuse.alwaysBlockedInMicroFactEvidence',
        'Protected source-storage prohibitions were weakened.',
      );
    }
  }

  void _validateEvidenceRules(
    dynamic value,
    List<RightsProvenancePolicyIssue> issues,
  ) {
    final map = _requiredMap(
      value,
      r'$policy.evidenceRules',
      'ML5_POLICY_EVIDENCE_RULES',
      issues,
    );
    if (map == null) {
      return;
    }

    _exactKeys(
      map,
      const {
        'evidenceSchemaVersion',
        'evidenceIdPattern',
        'reviewerRoleValues',
        'reviewStatusValues',
        'sha256Pattern',
        'maxEvidenceAgeDays',
        'sourceFingerprintFields',
      },
      r'$policy.evidenceRules',
      issues,
    );

    if (map['evidenceSchemaVersion'] != 1 ||
        map['evidenceIdPattern'] != r'^mfre_[a-z0-9][a-z0-9_-]{5,63}$' ||
        map['sha256Pattern'] != r'^[a-f0-9]{64}$' ||
        map['maxEvidenceAgeDays'] != 365) {
      _add(
        issues,
        'ML5_POLICY_EVIDENCE_CONTRACT',
        r'$policy.evidenceRules',
        'Evidence schema, identifier, hash or freshness contract was altered.',
      );
    }

    if (!_sameSet(_stringSet(map['reviewerRoleValues']), reviewerRoles)) {
      _add(
        issues,
        'ML5_POLICY_REVIEWER_ROLES',
        r'$policy.evidenceRules.reviewerRoleValues',
        'Reviewer roles do not match the frozen ML-5 set.',
      );
    }

    if (!_sameSet(_stringSet(map['reviewStatusValues']), reviewStatuses)) {
      _add(
        issues,
        'ML5_POLICY_REVIEW_STATUSES',
        r'$policy.evidenceRules.reviewStatusValues',
        'Rights review statuses do not match the frozen ML-5 set.',
      );
    }

    if (!_sameSet(
      _stringSet(map['sourceFingerprintFields']),
      const {
        'sourceRegistryId',
        'officialUrl',
        'sourceLocator',
        'editionOrRevision',
      },
    )) {
      _add(
        issues,
        'ML5_POLICY_SOURCE_FINGERPRINT',
        r'$policy.evidenceRules.sourceFingerprintFields',
        'Source fingerprint fields were altered.',
      );
    }
  }

  void _validateRightsSensitiveRules(
    dynamic value,
    List<RightsProvenancePolicyIssue> issues,
  ) {
    final map = _requiredMap(
      value,
      r'$policy.rightsSensitiveRules',
      'ML5_POLICY_SENSITIVE_RULES',
      issues,
    );
    if (map == null) {
      return;
    }

    _exactKeys(
      map,
      const {
        'requireEditionOrRevisionWhenAuthorityPolicyIn',
        'minimalQuoteRequiresHumanReview',
        'licensedExcerptRequiresHumanReview',
        'derivativeSimilarityReviewRequired',
      },
      r'$policy.rightsSensitiveRules',
      issues,
    );

    if (!_sameSet(
      _stringSet(map['requireEditionOrRevisionWhenAuthorityPolicyIn']),
      const {
        'revision_tracked',
        'annual_or_revision_check',
        'publication_specific',
      },
    ) ||
        map['minimalQuoteRequiresHumanReview'] != true ||
        map['licensedExcerptRequiresHumanReview'] != true ||
        map['derivativeSimilarityReviewRequired'] != true) {
      _add(
        issues,
        'ML5_POLICY_SENSITIVE_RULE_WEAKENED',
        r'$policy.rightsSensitiveRules',
        'Rights-sensitive authority safeguards were weakened.',
      );
    }
  }

  void _validateGovernmentRules(
    dynamic value,
    List<RightsProvenancePolicyIssue> issues,
  ) {
    final map = _requiredMap(
      value,
      r'$policy.governmentSourceRules',
      'ML5_POLICY_GOVERNMENT_RULES',
      issues,
    );
    if (map == null) {
      return;
    }

    _exactKeys(
      map,
      const {
        'doNotAssumeEntirePagePublicDomain',
        'thirdPartyMaterialMustBeExcludedUnlessSeparatelyCleared',
        'logosSealsAndTrademarksAreNotClearedByDefault',
      },
      r'$policy.governmentSourceRules',
      issues,
    );

    for (final key in const {
      'doNotAssumeEntirePagePublicDomain',
      'thirdPartyMaterialMustBeExcludedUnlessSeparatelyCleared',
      'logosSealsAndTrademarksAreNotClearedByDefault',
    }) {
      if (map[key] != true) {
        _add(
          issues,
          'ML5_POLICY_GOVERNMENT_RULE_WEAKENED',
          r'$policy.governmentSourceRules.$key',
          '$key must remain true.',
        );
      }
    }
  }

  static Map<String, dynamic>? _requiredMap(
    dynamic value,
    String path,
    String code,
    List<RightsProvenancePolicyIssue> issues,
  ) {
    if (value is! Map) {
      _add(issues, code, path, 'A JSON object is required.');
      return null;
    }
    return Map<String, dynamic>.from(value);
  }

  static void _validateNonEmptyUniqueStringList(
    dynamic value,
    String path,
    String code,
    List<RightsProvenancePolicyIssue> issues,
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
          '$path[$i]',
          'Items must be unique non-empty strings.',
        );
      }
    }
  }

  static void _exactKeys(
    Map<String, dynamic> map,
    Set<String> expected,
    String path,
    List<RightsProvenancePolicyIssue> issues,
  ) {
    final actual = map.keys.toSet();
    for (final missing in expected.difference(actual)) {
      _add(
        issues,
        'ML5_POLICY_REQUIRED_FIELD',
        '$path.$missing',
        'Required policy field is missing.',
      );
    }
    for (final extra in actual.difference(expected)) {
      _add(
        issues,
        'ML5_POLICY_UNKNOWN_FIELD',
        '$path.$extra',
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
    if (value is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      return false;
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return false;
    }
    final normalized =
        '${parsed.year.toString().padLeft(4, '0')}-'
        '${parsed.month.toString().padLeft(2, '0')}-'
        '${parsed.day.toString().padLeft(2, '0')}';
    return normalized == value;
  }

  static void _add(
    List<RightsProvenancePolicyIssue> issues,
    String code,
    String path,
    String message,
  ) {
    issues.add(
      RightsProvenancePolicyIssue(code: code, path: path, message: message),
    );
  }
}
