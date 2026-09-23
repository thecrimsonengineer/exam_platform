import 'canonical_curriculum_policy_validator.dart';
import 'claim_semantics_policy_validator.dart';
import 'micro_fact_schema_validator.dart';
import 'micro_fact_source_gate_validator.dart';
import 'rights_provenance_policy_validator.dart';
import 'startup_pedagogy_policy_validator.dart';

class DuplicateContradictionPolicyIssue {
  const DuplicateContradictionPolicyIssue({
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

class DuplicateContradictionPolicyValidationResult {
  const DuplicateContradictionPolicyValidationResult(this.issues);

  final List<DuplicateContradictionPolicyIssue> issues;

  bool get isValid => issues.isEmpty;
}

class DuplicateContradictionPolicyValidator {
  static const String requiredPolicyVersion = '1.0.0';

  static const Set<String> comparisonStatuses = {
    'draft',
    'review',
    'validated',
    'published',
    'review_due',
  };

  static const Set<String> excludedStatuses = {
    'superseded',
    'withdrawn',
    'rejected',
  };

  static const Set<String> reviewerRoles = {
    'content_governance_reviewer',
    'subject_matter_reviewer',
    'technical_reviewer',
  };

  static const Set<String> reviewStatuses = {'pending', 'pass', 'fail'};

  static const Set<String> passDecisions = {
    'distinct_valid',
    'scope_difference_valid',
    'source_context_difference_valid',
  };

  static const Set<String> blockDecisions = {
    'duplicate_block',
    'contradiction_block',
    'merge_required',
    'supersession_required',
  };

  static const Set<String> comparisonSignals = {
    'near_duplicate',
    'concept_assisted_duplicate',
    'same_source_locator_overlap',
    'polarity_conflict',
    'legal_status_conflict',
    'numerical_conflict',
    'edition_drift',
  };

  const DuplicateContradictionPolicyValidator();

  DuplicateContradictionPolicyValidationResult validateMap(
    Map<String, dynamic> policy,
  ) {
    final issues = <DuplicateContradictionPolicyIssue>[];

    _exactKeys(
      policy,
      const {
        'schemaVersion',
        'policyVersion',
        'status',
        'frozenAt',
        'authorityRegistryVersion',
        'microFactSchemaVersion',
        'claimPolicyVersion',
        'rightsPolicyVersion',
        'curriculumPolicyVersion',
        'startupPedagogyPolicyVersion',
        'failClosed',
        'corpusScope',
        'normalization',
        'duplicateRules',
        'contradictionRules',
        'numericNormalization',
        'adjudicationRules',
        'concentrationAudit',
        'driftRules',
      },
      r'$policy',
      issues,
    );

    if (policy['schemaVersion'] != 1 ||
        policy['policyVersion'] != requiredPolicyVersion ||
        policy['status'] != 'frozen' ||
        policy['failClosed'] != true ||
        !_isStrictDate(policy['frozenAt'])) {
      _add(
        issues,
        'ML8_POLICY_IDENTITY',
        r'$policy',
        'ML-8 policy identity, frozen state or date is invalid.',
      );
    }

    if (policy['authorityRegistryVersion'] !=
            MicroFactSourceGateValidator.requiredRegistryVersion ||
        policy['microFactSchemaVersion'] !=
            MicroFactSchemaValidator.schemaVersion ||
        policy['claimPolicyVersion'] !=
            ClaimSemanticsPolicyValidator.requiredPolicyVersion ||
        policy['rightsPolicyVersion'] !=
            RightsProvenancePolicyValidator.requiredPolicyVersion ||
        policy['curriculumPolicyVersion'] !=
            CanonicalCurriculumPolicyValidator.requiredPolicyVersion ||
        policy['startupPedagogyPolicyVersion'] !=
            StartupPedagogyPolicyValidator.requiredPolicyVersion) {
      _add(
        issues,
        'ML8_POLICY_PREREQUISITE_VERSION',
        r'$policy',
        'ML-8 must bind exactly to the frozen ML-1 through ML-7 contracts.',
      );
    }

    _validateCorpusScope(policy['corpusScope'], issues);
    _validateNormalization(policy['normalization'], issues);
    _validateDuplicateRules(policy['duplicateRules'], issues);
    _validateContradictionRules(policy['contradictionRules'], issues);
    _validateNumericRules(policy['numericNormalization'], issues);
    _validateAdjudicationRules(policy['adjudicationRules'], issues);
    _validateConcentrationAudit(policy['concentrationAudit'], issues);
    _validateDriftRules(policy['driftRules'], issues);

    return DuplicateContradictionPolicyValidationResult(
      List.unmodifiable(issues),
    );
  }

  void _validateCorpusScope(
    dynamic value,
    List<DuplicateContradictionPolicyIssue> issues,
  ) {
    final map = _requiredMap(
      value,
      r'$policy.corpusScope',
      'ML8_POLICY_CORPUS_SCOPE',
      issues,
    );
    if (map == null) return;

    _exactKeys(
      map,
      const {
        'comparisonStatuses',
        'excludedStatuses',
        'requireUniqueActiveMicroFactId',
        'compareDifferentContentVersionsOfSameId',
        'minimumFactsForPairwiseScan',
      },
      r'$policy.corpusScope',
      issues,
    );

    if (!_sameSet(
          _stringSet(map['comparisonStatuses']),
          comparisonStatuses,
        ) ||
        !_sameSet(_stringSet(map['excludedStatuses']), excludedStatuses) ||
        map['requireUniqueActiveMicroFactId'] != true ||
        map['compareDifferentContentVersionsOfSameId'] != false ||
        map['minimumFactsForPairwiseScan'] != 2) {
      _add(
        issues,
        'ML8_POLICY_CORPUS_SCOPE_WEAKENED',
        r'$policy.corpusScope',
        'Corpus comparison lifecycle rules were altered.',
      );
    }
  }

  void _validateNormalization(
    dynamic value,
    List<DuplicateContradictionPolicyIssue> issues,
  ) {
    final map = _requiredMap(
      value,
      r'$policy.normalization',
      'ML8_POLICY_NORMALIZATION',
      issues,
    );
    if (map == null) return;

    _exactKeys(
      map,
      const {
        'lowercase',
        'collapseWhitespace',
        'stripPunctuation',
        'preserveNumbers',
        'preserveNegationTokens',
        'stopWords',
        'protectedTokens',
      },
      r'$policy.normalization',
      issues,
    );

    if (map['lowercase'] != true ||
        map['collapseWhitespace'] != true ||
        map['stripPunctuation'] != true ||
        map['preserveNumbers'] != true ||
        map['preserveNegationTokens'] != true) {
      _add(
        issues,
        'ML8_POLICY_NORMALIZATION_WEAKENED',
        r'$policy.normalization',
        'Deterministic normalization invariants were weakened.',
      );
    }

    final stopWords = _stringSet(map['stopWords']);
    final protected = _stringSet(map['protectedTokens']);
    if (stopWords.isEmpty ||
        !protected.containsAll(
          const {
            'no',
            'not',
            'never',
            'without',
            'cannot',
            'must',
            'shall',
            'required',
            'prohibited',
            'may',
          },
        ) ||
        stopWords.intersection(protected).isNotEmpty) {
      _add(
        issues,
        'ML8_POLICY_NORMALIZATION_TOKENS',
        r'$policy.normalization',
        'Stop-word and protected-token rules are invalid.',
      );
    }
  }

  void _validateDuplicateRules(
    dynamic value,
    List<DuplicateContradictionPolicyIssue> issues,
  ) {
    final map = _requiredMap(
      value,
      r'$policy.duplicateRules',
      'ML8_POLICY_DUPLICATE_RULES',
      issues,
    );
    if (map == null) return;

    _exactKeys(
      map,
      const {
        'exactNormalizedDisplayText',
        'exactNormalizedShortVariant',
        'exactDisplayHashAcrossDifferentFacts',
        'nearDuplicateDisplayJaccardThreshold',
        'nearDuplicateShortJaccardThreshold',
        'conceptAssistedDisplayJaccardThreshold',
        'minimumConceptJaccardForNearDuplicate',
        'exactConceptSetRequiresSameCategoryForAssistedRule',
        'sameSourceLocatorConceptAssistedThreshold',
        'nearDuplicateDisposition',
        'exactDuplicateDisposition',
      },
      r'$policy.duplicateRules',
      issues,
    );

    if (map['exactNormalizedDisplayText'] != 'block' ||
        map['exactNormalizedShortVariant'] != 'block' ||
        map['exactDisplayHashAcrossDifferentFacts'] != 'block' ||
        !_sameNumber(map['nearDuplicateDisplayJaccardThreshold'], 0.8) ||
        !_sameNumber(map['nearDuplicateShortJaccardThreshold'], 0.85) ||
        !_sameNumber(map['conceptAssistedDisplayJaccardThreshold'], 0.6) ||
        !_sameNumber(map['minimumConceptJaccardForNearDuplicate'], 0.5) ||
        map['exactConceptSetRequiresSameCategoryForAssistedRule'] != true ||
        !_sameNumber(map['sameSourceLocatorConceptAssistedThreshold'], 0.5) ||
        map['nearDuplicateDisposition'] != 'human_adjudication_required' ||
        map['exactDuplicateDisposition'] != 'block') {
      _add(
        issues,
        'ML8_POLICY_DUPLICATE_RULES_WEAKENED',
        r'$policy.duplicateRules',
        'Duplicate thresholds or dispositions were altered.',
      );
    }
  }

  void _validateContradictionRules(
    dynamic value,
    List<DuplicateContradictionPolicyIssue> issues,
  ) {
    final map = _requiredMap(
      value,
      r'$policy.contradictionRules',
      'ML8_POLICY_CONTRADICTION_RULES',
      issues,
    );
    if (map == null) return;

    _exactKeys(
      map,
      const {
        'polarityConflictMinTextJaccard',
        'polarityConflictMinConceptJaccard',
        'legalStatusConflictMinConceptJaccard',
        'legalStatusConflictMinTextJaccard',
        'numericalConflictMinConceptJaccard',
        'numericalConflictMinTextJaccard',
        'numericalConflictRequiresSameJurisdictionWhenBothPresent',
        'legalStatusConflictRequiresSameJurisdictionWhenBothBinding',
        'editionDriftSameSourceLocator',
        'unresolvedContradictionDisposition',
      },
      r'$policy.contradictionRules',
      issues,
    );

    if (!_sameNumber(map['polarityConflictMinTextJaccard'], 0.65) ||
        !_sameNumber(map['polarityConflictMinConceptJaccard'], 0.5) ||
        !_sameNumber(map['legalStatusConflictMinConceptJaccard'], 0.75) ||
        !_sameNumber(map['legalStatusConflictMinTextJaccard'], 0.4) ||
        !_sameNumber(map['numericalConflictMinConceptJaccard'], 0.5) ||
        !_sameNumber(map['numericalConflictMinTextJaccard'], 0.4) ||
        map['numericalConflictRequiresSameJurisdictionWhenBothPresent'] !=
            true ||
        map['legalStatusConflictRequiresSameJurisdictionWhenBothBinding'] !=
            true ||
        map['editionDriftSameSourceLocator'] !=
            'human_adjudication_required' ||
        map['unresolvedContradictionDisposition'] != 'block') {
      _add(
        issues,
        'ML8_POLICY_CONTRADICTION_RULES_WEAKENED',
        r'$policy.contradictionRules',
        'Contradiction thresholds or fail-closed rules were altered.',
      );
    }
  }

  void _validateNumericRules(
    dynamic value,
    List<DuplicateContradictionPolicyIssue> issues,
  ) {
    final map = _requiredMap(
      value,
      r'$policy.numericNormalization',
      'ML8_POLICY_NUMERIC_RULES',
      issues,
    );
    if (map == null) return;

    _exactKeys(
      map,
      const {
        'supportedUnits',
        'compareValuesOnlyWithinMatchingNormalizedUnit',
        'unitConversionAllowed',
        'automaticNumericReconciliationAllowed',
      },
      r'$policy.numericNormalization',
      issues,
    );

    final units = _stringSet(map['supportedUnits']);
    if (!units.containsAll(
          const {'%', 'ppm', 'ppb', 'dba', 'db', 'kv', 'psi', 'ft', 'm'},
        ) ||
        map['compareValuesOnlyWithinMatchingNormalizedUnit'] != true ||
        map['unitConversionAllowed'] != false ||
        map['automaticNumericReconciliationAllowed'] != false) {
      _add(
        issues,
        'ML8_POLICY_NUMERIC_RULES_WEAKENED',
        r'$policy.numericNormalization',
        'Numeric comparison controls were altered.',
      );
    }
  }

  void _validateAdjudicationRules(
    dynamic value,
    List<DuplicateContradictionPolicyIssue> issues,
  ) {
    final map = _requiredMap(
      value,
      r'$policy.adjudicationRules',
      'ML8_POLICY_ADJUDICATION_RULES',
      issues,
    );
    if (map == null) return;

    _exactKeys(
      map,
      const {
        'evidenceSchemaVersion',
        'evidenceIdPattern',
        'sha256Pattern',
        'pairKeySeparator',
        'canonicalPairOrderingRequired',
        'reviewerRoles',
        'reviewStatusValues',
        'passDecisions',
        'blockDecisions',
        'maxEvidenceAgeDays',
        'exactFactFingerprintRequired',
        'exactSignalSetRequired',
        'humanReviewRequired',
      },
      r'$policy.adjudicationRules',
      issues,
    );

    if (map['evidenceSchemaVersion'] != 1 ||
        map['evidenceIdPattern'] != r'^mfce_[a-z0-9][a-z0-9_-]{5,63}$' ||
        map['sha256Pattern'] != r'^[a-f0-9]{64}$' ||
        map['pairKeySeparator'] != '||' ||
        map['canonicalPairOrderingRequired'] != true ||
        !_sameSet(_stringSet(map['reviewerRoles']), reviewerRoles) ||
        !_sameSet(_stringSet(map['reviewStatusValues']), reviewStatuses) ||
        !_sameSet(_stringSet(map['passDecisions']), passDecisions) ||
        !_sameSet(_stringSet(map['blockDecisions']), blockDecisions) ||
        map['maxEvidenceAgeDays'] != 365 ||
        map['exactFactFingerprintRequired'] != true ||
        map['exactSignalSetRequired'] != true ||
        map['humanReviewRequired'] != true) {
      _add(
        issues,
        'ML8_POLICY_ADJUDICATION_RULES_WEAKENED',
        r'$policy.adjudicationRules',
        'Pairwise adjudication safeguards were altered.',
      );
    }
  }

  void _validateConcentrationAudit(
    dynamic value,
    List<DuplicateContradictionPolicyIssue> issues,
  ) {
    final map = _requiredMap(
      value,
      r'$policy.concentrationAudit',
      'ML8_POLICY_CONCENTRATION_AUDIT',
      issues,
    );
    if (map == null) return;

    _exactKeys(
      map,
      const {
        'enabled',
        'exactConceptSetReviewThreshold',
        'sameSourceLocatorReviewThreshold',
        'authorityShareReviewThreshold',
        'authorityShareMinimumCorpusSize',
        'concentrationSignalsAreBlocking',
      },
      r'$policy.concentrationAudit',
      issues,
    );

    if (map['enabled'] != true ||
        map['exactConceptSetReviewThreshold'] != 4 ||
        map['sameSourceLocatorReviewThreshold'] != 3 ||
        !_sameNumber(map['authorityShareReviewThreshold'], 0.4) ||
        map['authorityShareMinimumCorpusSize'] != 20 ||
        map['concentrationSignalsAreBlocking'] != false) {
      _add(
        issues,
        'ML8_POLICY_CONCENTRATION_AUDIT_WEAKENED',
        r'$policy.concentrationAudit',
        'Corpus concentration audit rules were altered.',
      );
    }
  }

  void _validateDriftRules(
    dynamic value,
    List<DuplicateContradictionPolicyIssue> issues,
  ) {
    final map = _requiredMap(
      value,
      r'$policy.driftRules',
      'ML8_POLICY_DRIFT_RULES',
      issues,
    );
    if (map == null) return;

    const keys = {
      'contentVersionChangeInvalidatesEvidence',
      'displayTextChangeInvalidatesEvidence',
      'shortVariantChangeInvalidatesEvidence',
      'conceptIdsChangeInvalidatesEvidence',
      'legalStatusChangeInvalidatesEvidence',
      'jurisdictionChangeInvalidatesEvidence',
      'numericalClaimChangeInvalidatesEvidence',
      'sourceLocatorChangeInvalidatesEvidence',
      'editionChangeInvalidatesEvidence',
      'policyVersionChangeInvalidatesEvidence',
    };
    _exactKeys(map, keys, r'$policy.driftRules', issues);

    for (final key in keys) {
      if (map[key] != true) {
        _add(
          issues,
          'ML8_POLICY_DRIFT_RULES_WEAKENED',
          r'$policy.driftRules.' + key,
          key + ' must remain true.',
        );
      }
    }
  }

  static Map<String, dynamic>? _requiredMap(
    dynamic value,
    String path,
    String code,
    List<DuplicateContradictionPolicyIssue> issues,
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
    List<DuplicateContradictionPolicyIssue> issues,
  ) {
    final actual = map.keys.toSet();
    for (final missing in expected.difference(actual)) {
      _add(
        issues,
        'ML8_POLICY_REQUIRED_FIELD',
        path + '.' + missing,
        'Required policy field is missing.',
      );
    }
    for (final extra in actual.difference(expected)) {
      _add(
        issues,
        'ML8_POLICY_UNKNOWN_FIELD',
        path + '.' + extra,
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

  static bool _sameNumber(dynamic value, double expected) =>
      value is num && (value.toDouble() - expected).abs() < 0.0000001;

  static bool _isStrictDate(dynamic value) {
    if (value is! String ||
        !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      return false;
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return false;
    final normalized =
        parsed.year.toString().padLeft(4, '0') +
        '-' +
        parsed.month.toString().padLeft(2, '0') +
        '-' +
        parsed.day.toString().padLeft(2, '0');
    return normalized == value;
  }

  static void _add(
    List<DuplicateContradictionPolicyIssue> issues,
    String code,
    String path,
    String message,
  ) {
    issues.add(
      DuplicateContradictionPolicyIssue(
        code: code,
        path: path,
        message: message,
      ),
    );
  }
}
