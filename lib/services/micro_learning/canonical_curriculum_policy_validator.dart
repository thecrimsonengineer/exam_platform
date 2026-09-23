import '../../data/csp11_blueprint.dart';
import 'claim_semantics_policy_validator.dart';
import 'micro_fact_schema_validator.dart';
import 'micro_fact_source_gate_validator.dart';
import 'rights_provenance_policy_validator.dart';

class CanonicalCurriculumPolicyIssue {
  const CanonicalCurriculumPolicyIssue({
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

class CanonicalCurriculumPolicyValidationResult {
  const CanonicalCurriculumPolicyValidationResult(this.issues);

  final List<CanonicalCurriculumPolicyIssue> issues;

  bool get isValid => issues.isEmpty;
}

class CanonicalCurriculumPolicyValidator {
  static const String requiredPolicyVersion = '1.0.0';
  static const String requiredNavigationRegistryVersion = '1.0.0';
  static const String requiredBlueprintVersion = 'V.2024.04.24';

  static const Set<String> requiredRootKeys = {
    'schemaVersion',
    'policyVersion',
    'status',
    'frozenAt',
    'authorityRegistryVersion',
    'microFactSchemaVersion',
    'claimPolicyVersion',
    'rightsPolicyVersion',
    'canonicalBlueprint',
    'navigationRegistryVersion',
    'failClosed',
    'principles',
    'scopeRules',
    'idPatterns',
    'nodeStatuses',
    'evidenceRules',
    'driftRules',
  };

  static const Set<String> reviewerRoles = {
    'curriculum_reviewer',
    'content_governance_reviewer',
    'subject_matter_reviewer',
  };

  static const Set<String> reviewStatuses = {'pending', 'pass', 'fail'};

  const CanonicalCurriculumPolicyValidator();

  CanonicalCurriculumPolicyValidationResult validateMap(
    Map<String, dynamic> policy,
  ) {
    final issues = <CanonicalCurriculumPolicyIssue>[];

    _exactKeys(policy, requiredRootKeys, r'$policy', issues);

    if (policy['schemaVersion'] != 1) {
      _add(
        issues,
        'ML6_POLICY_SCHEMA_VERSION',
        r'$policy.schemaVersion',
        'Curriculum policy schemaVersion must be 1.',
      );
    }

    if (policy['policyVersion'] != requiredPolicyVersion) {
      _add(
        issues,
        'ML6_POLICY_VERSION',
        r'$policy.policyVersion',
        'Curriculum policy version must be $requiredPolicyVersion.',
      );
    }

    if (policy['status'] != 'frozen' || policy['failClosed'] != true) {
      _add(
        issues,
        'ML6_POLICY_NOT_FROZEN',
        r'$policy',
        'ML-6 policy must remain frozen and fail closed.',
      );
    }

    if (!_isStrictDate(policy['frozenAt'])) {
      _add(
        issues,
        'ML6_POLICY_FROZEN_DATE',
        r'$policy.frozenAt',
        'frozenAt must be a valid YYYY-MM-DD date.',
      );
    }

    if (policy['authorityRegistryVersion'] !=
        MicroFactSourceGateValidator.requiredRegistryVersion) {
      _add(
        issues,
        'ML6_POLICY_AUTHORITY_VERSION',
        r'$policy.authorityRegistryVersion',
        'ML-6 must bind to the frozen ML-1 authority registry.',
      );
    }

    if (policy['microFactSchemaVersion'] !=
        MicroFactSchemaValidator.schemaVersion) {
      _add(
        issues,
        'ML6_POLICY_FACT_SCHEMA_VERSION',
        r'$policy.microFactSchemaVersion',
        'ML-6 must bind to MicroFact schema v1.',
      );
    }

    if (policy['claimPolicyVersion'] !=
        ClaimSemanticsPolicyValidator.requiredPolicyVersion) {
      _add(
        issues,
        'ML6_POLICY_CLAIM_VERSION',
        r'$policy.claimPolicyVersion',
        'ML-6 must bind to the frozen ML-4 claim policy.',
      );
    }

    if (policy['rightsPolicyVersion'] !=
        RightsProvenancePolicyValidator.requiredPolicyVersion) {
      _add(
        issues,
        'ML6_POLICY_RIGHTS_VERSION',
        r'$policy.rightsPolicyVersion',
        'ML-6 must bind to the frozen ML-5 rights policy.',
      );
    }

    if (policy['navigationRegistryVersion'] !=
        requiredNavigationRegistryVersion) {
      _add(
        issues,
        'ML6_POLICY_NAVIGATION_VERSION',
        r'$policy.navigationRegistryVersion',
        'ML-6 must bind to navigation registry 1.0.0.',
      );
    }

    _validateBlueprint(policy['canonicalBlueprint'], issues);
    _validatePrinciples(policy['principles'], issues);
    _validateScopeRules(policy['scopeRules'], issues);
    _validateIdPatterns(policy['idPatterns'], issues);
    _validateNodeStatuses(policy['nodeStatuses'], issues);
    _validateEvidenceRules(policy['evidenceRules'], issues);
    _validateDriftRules(policy['driftRules'], issues);

    return CanonicalCurriculumPolicyValidationResult(List.unmodifiable(issues));
  }

  void _validateBlueprint(
    dynamic value,
    List<CanonicalCurriculumPolicyIssue> issues,
  ) {
    final map = _requiredMap(
      value,
      r'$policy.canonicalBlueprint',
      'ML6_POLICY_BLUEPRINT',
      issues,
    );
    if (map == null) return;

    _exactKeys(
      map,
      const {
        'sourcePath',
        'blueprintVersion',
        'effectiveDate',
        'expectedDomainCount',
        'expectedCompetencyCount',
        'generatedRegistryPath',
      },
      r'$policy.canonicalBlueprint',
      issues,
    );

    if (map['sourcePath'] !=
            'docs/source_pipeline/CSP11_canonical_blueprint.json' ||
        map['blueprintVersion'] != requiredBlueprintVersion ||
        map['effectiveDate'] != '2025-08-01' ||
        map['generatedRegistryPath'] != 'lib/data/csp11_blueprint.dart') {
      _add(
        issues,
        'ML6_POLICY_BLUEPRINT_IDENTITY',
        r'$policy.canonicalBlueprint',
        'Canonical blueprint identity was altered.',
      );
    }

    final actualCompetencies = csp11Domains.fold<int>(
      0,
      (sum, domain) => sum + domain.competencies.length,
    );

    if (map['expectedDomainCount'] != 7 ||
        map['expectedDomainCount'] != csp11Domains.length ||
        map['expectedCompetencyCount'] != 47 ||
        map['expectedCompetencyCount'] != actualCompetencies) {
      _add(
        issues,
        'ML6_POLICY_BLUEPRINT_COUNTS',
        r'$policy.canonicalBlueprint',
        'Policy counts must match the generated canonical CSP11 registry.',
      );
    }
  }

  void _validatePrinciples(
    dynamic value,
    List<CanonicalCurriculumPolicyIssue> issues,
  ) {
    final map = _requiredMap(
      value,
      r'$policy.principles',
      'ML6_POLICY_PRINCIPLES',
      issues,
    );
    if (map == null) return;

    const keys = {
      'blueprintIsAuthoritativeForDomainAndCompetency',
      'navigationRegistryIsAuthoritativeForTopicAndSubtopic',
      'inferMappingFromTitle',
      'inferMappingFromTags',
      'inferMappingFromConceptIds',
      'inferMappingFromSource',
      'allowLegacyIdsInMicroFact',
      'allowUnknownNodes',
      'allowDeprecatedNodes',
      'allowAutomaticRemap',
      'requireExactParentage',
      'requireHumanMappingReviewForValidatedOrPublished',
      'runtimeNetworkLookupAllowed',
    };
    _exactKeys(map, keys, r'$policy.principles', issues);

    for (final key in const {
      'blueprintIsAuthoritativeForDomainAndCompetency',
      'navigationRegistryIsAuthoritativeForTopicAndSubtopic',
      'requireExactParentage',
      'requireHumanMappingReviewForValidatedOrPublished',
    }) {
      if (map[key] != true) {
        _add(
          issues,
          'ML6_POLICY_PRINCIPLE_WEAKENED',
          r'$policy.principles.$key',
          '$key must remain true.',
        );
      }
    }

    for (final key in const {
      'inferMappingFromTitle',
      'inferMappingFromTags',
      'inferMappingFromConceptIds',
      'inferMappingFromSource',
      'allowLegacyIdsInMicroFact',
      'allowUnknownNodes',
      'allowDeprecatedNodes',
      'allowAutomaticRemap',
      'runtimeNetworkLookupAllowed',
    }) {
      if (map[key] != false) {
        _add(
          issues,
          'ML6_POLICY_PRINCIPLE_WEAKENED',
          r'$policy.principles.$key',
          '$key must remain false.',
        );
      }
    }
  }

  void _validateScopeRules(
    dynamic value,
    List<CanonicalCurriculumPolicyIssue> issues,
  ) {
    final map = _requiredMap(
      value,
      r'$policy.scopeRules',
      'ML6_POLICY_SCOPE_RULES',
      issues,
    );
    if (map == null) return;

    _exactKeys(map, const {'general', 'mapped'}, r'$policy.scopeRules', issues);

    final general = _requiredMap(
      map['general'],
      r'$policy.scopeRules.general',
      'ML6_POLICY_GENERAL_SCOPE',
      issues,
    );
    if (general != null) {
      _exactKeys(
        general,
        const {'requireAllCurriculumIdsNull', 'mappingEvidenceAllowed'},
        r'$policy.scopeRules.general',
        issues,
      );
      if (general['requireAllCurriculumIdsNull'] != true ||
          general['mappingEvidenceAllowed'] != false) {
        _add(
          issues,
          'ML6_POLICY_GENERAL_SCOPE_WEAKENED',
          r'$policy.scopeRules.general',
          'General facts must remain unmapped and evidence-free.',
        );
      }
    }

    final mapped = _requiredMap(
      map['mapped'],
      r'$policy.scopeRules.mapped',
      'ML6_POLICY_MAPPED_SCOPE',
      issues,
    );
    if (mapped != null) {
      _exactKeys(
        mapped,
        const {
          'domainIdRequired',
          'competencyIdRequired',
          'topicIdOptional',
          'subtopicIdOptional',
          'subtopicRequiresTopic',
          'mappingEvidenceRequiredForStatuses',
          'startupEligibleRequiresPassingEvidence',
        },
        r'$policy.scopeRules.mapped',
        issues,
      );

      if (mapped['domainIdRequired'] != true ||
          mapped['competencyIdRequired'] != true ||
          mapped['topicIdOptional'] != true ||
          mapped['subtopicIdOptional'] != true ||
          mapped['subtopicRequiresTopic'] != true ||
          mapped['startupEligibleRequiresPassingEvidence'] != true ||
          !_sameSet(
            _stringSet(mapped['mappingEvidenceRequiredForStatuses']),
            const {'validated', 'published', 'review_due'},
          )) {
        _add(
          issues,
          'ML6_POLICY_MAPPED_SCOPE_WEAKENED',
          r'$policy.scopeRules.mapped',
          'Mapped-scope requirements were altered.',
        );
      }
    }
  }

  void _validateIdPatterns(
    dynamic value,
    List<CanonicalCurriculumPolicyIssue> issues,
  ) {
    final map = _requiredMap(
      value,
      r'$policy.idPatterns',
      'ML6_POLICY_ID_PATTERNS',
      issues,
    );
    if (map == null) return;

    const expected = {
      'domainId': r'^d0[1-7]$',
      'competencyId': r'^d0[1-7]_c[0-9]{2}$',
      'topicId': r'^d0[1-7]_c[0-9]{2}_t[0-9]{2}$',
      'subtopicId': r'^d0[1-7]_c[0-9]{2}_t[0-9]{2}_s[0-9]{2}$',
    };
    _exactKeys(map, expected.keys.toSet(), r'$policy.idPatterns', issues);

    for (final entry in expected.entries) {
      if (map[entry.key] != entry.value) {
        _add(
          issues,
          'ML6_POLICY_ID_PATTERN_WEAKENED',
          r'$policy.idPatterns.${entry.key}',
          'Canonical ID pattern was altered.',
        );
      }
    }
  }

  void _validateNodeStatuses(
    dynamic value,
    List<CanonicalCurriculumPolicyIssue> issues,
  ) {
    final map = _requiredMap(
      value,
      r'$policy.nodeStatuses',
      'ML6_POLICY_NODE_STATUSES',
      issues,
    );
    if (map == null) return;

    _exactKeys(
      map,
      const {'allowedRegistryStatuses', 'selectableStatuses'},
      r'$policy.nodeStatuses',
      issues,
    );

    if (!_sameSet(_stringSet(map['allowedRegistryStatuses']), const {
          'active',
          'deprecated',
          'retired',
        }) ||
        !_sameSet(_stringSet(map['selectableStatuses']), const {'active'})) {
      _add(
        issues,
        'ML6_POLICY_NODE_STATUS_WEAKENED',
        r'$policy.nodeStatuses',
        'Node lifecycle rules were altered.',
      );
    }
  }

  void _validateEvidenceRules(
    dynamic value,
    List<CanonicalCurriculumPolicyIssue> issues,
  ) {
    final map = _requiredMap(
      value,
      r'$policy.evidenceRules',
      'ML6_POLICY_EVIDENCE_RULES',
      issues,
    );
    if (map == null) return;

    _exactKeys(
      map,
      const {
        'evidenceSchemaVersion',
        'evidenceIdPattern',
        'reviewStatusValues',
        'reviewerRoleValues',
        'evidenceMustPassForStatuses',
        'maxEvidenceAgeDays',
        'exactMappingFingerprintRequired',
        'exactRegistryVersionRequired',
        'exactBlueprintVersionRequired',
      },
      r'$policy.evidenceRules',
      issues,
    );

    if (map['evidenceSchemaVersion'] != 1 ||
        map['evidenceIdPattern'] != r'^mfme_[a-z0-9][a-z0-9_-]{5,63}$' ||
        map['maxEvidenceAgeDays'] != 365 ||
        map['exactMappingFingerprintRequired'] != true ||
        map['exactRegistryVersionRequired'] != true ||
        map['exactBlueprintVersionRequired'] != true ||
        !_sameSet(_stringSet(map['reviewStatusValues']), reviewStatuses) ||
        !_sameSet(_stringSet(map['reviewerRoleValues']), reviewerRoles) ||
        !_sameSet(_stringSet(map['evidenceMustPassForStatuses']), const {
          'validated',
          'published',
        })) {
      _add(
        issues,
        'ML6_POLICY_EVIDENCE_RULE_WEAKENED',
        r'$policy.evidenceRules',
        'Curriculum evidence safeguards were altered.',
      );
    }
  }

  void _validateDriftRules(
    dynamic value,
    List<CanonicalCurriculumPolicyIssue> issues,
  ) {
    final map = _requiredMap(
      value,
      r'$policy.driftRules',
      'ML6_POLICY_DRIFT_RULES',
      issues,
    );
    if (map == null) return;

    const keys = {
      'contentVersionChangeInvalidatesEvidence',
      'curriculumIdChangeInvalidatesEvidence',
      'registryVersionChangeInvalidatesEvidence',
      'blueprintVersionChangeInvalidatesEvidence',
      'nodeDeprecationInvalidatesEvidence',
    };
    _exactKeys(map, keys, r'$policy.driftRules', issues);

    for (final key in keys) {
      if (map[key] != true) {
        _add(
          issues,
          'ML6_POLICY_DRIFT_RULE_WEAKENED',
          r'$policy.driftRules.$key',
          '$key must remain true.',
        );
      }
    }
  }

  static Map<String, dynamic>? _requiredMap(
    dynamic value,
    String path,
    String code,
    List<CanonicalCurriculumPolicyIssue> issues,
  ) {
    if (value is! Map) {
      _add(issues, code, path, 'A JSON object is required.');
      return null;
    }
    return Map<String, dynamic>.from(value);
  }

  static void _exactKeys(
    Map<String, dynamic> map,
    Set<String> expected,
    String path,
    List<CanonicalCurriculumPolicyIssue> issues,
  ) {
    final actual = map.keys.toSet();
    for (final missing in expected.difference(actual)) {
      _add(
        issues,
        'ML6_POLICY_REQUIRED_FIELD',
        '$path.$missing',
        'Required policy field is missing.',
      );
    }
    for (final extra in actual.difference(expected)) {
      _add(
        issues,
        'ML6_POLICY_UNKNOWN_FIELD',
        '$path.$extra',
        'Unknown policy field is not allowed.',
      );
    }
  }

  static Set<String> _stringSet(dynamic value) {
    if (value is! List) return <String>{};
    return value.whereType<String>().toSet();
  }

  static bool _sameSet(Set<String> a, Set<String> b) =>
      a.length == b.length && a.containsAll(b);

  static bool _isStrictDate(dynamic value) {
    if (value is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      return false;
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return false;
    final normalized =
        '${parsed.year.toString().padLeft(4, '0')}-'
        '${parsed.month.toString().padLeft(2, '0')}-'
        '${parsed.day.toString().padLeft(2, '0')}';
    return normalized == value;
  }

  static void _add(
    List<CanonicalCurriculumPolicyIssue> issues,
    String code,
    String path,
    String message,
  ) {
    issues.add(
      CanonicalCurriculumPolicyIssue(code: code, path: path, message: message),
    );
  }
}
