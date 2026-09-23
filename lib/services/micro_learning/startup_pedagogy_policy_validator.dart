import 'canonical_curriculum_policy_validator.dart';
import 'claim_semantics_policy_validator.dart';
import 'micro_fact_schema_validator.dart';
import 'micro_fact_source_gate_validator.dart';
import 'rights_provenance_policy_validator.dart';

class StartupPedagogyPolicyIssue {
  const StartupPedagogyPolicyIssue({
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

class StartupPedagogyPolicyValidationResult {
  const StartupPedagogyPolicyValidationResult(this.issues);

  final List<StartupPedagogyPolicyIssue> issues;

  bool get isValid => issues.isEmpty;
}

class StartupPedagogyPolicyValidator {
  static const String requiredPolicyVersion = '1.0.0';

  static const Set<String> pedagogyReviewerRoles = {
    'pedagogy_reviewer',
    'content_governance_reviewer',
    'subject_matter_reviewer',
  };

  static const Set<String> accessibilityReviewerRoles = {
    'accessibility_reviewer',
    'content_governance_reviewer',
  };

  static const Set<String> reviewStatuses = {'pending', 'pass', 'fail'};

  const StartupPedagogyPolicyValidator();

  StartupPedagogyPolicyValidationResult validateMap(
    Map<String, dynamic> policy,
  ) {
    final issues = <StartupPedagogyPolicyIssue>[];

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
        'failClosed',
        'startupContract',
        'textRules',
        'plainTextRules',
        'abbreviationRules',
        'visualIndependenceRules',
        'assessmentRules',
        'precisionRules',
        'accessibilityRules',
        'evidenceRules',
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
        'ML7_POLICY_IDENTITY',
        r'$policy',
        'ML-7 policy identity, frozen state or date is invalid.',
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
            CanonicalCurriculumPolicyValidator.requiredPolicyVersion) {
      _add(
        issues,
        'ML7_POLICY_PREREQUISITE_VERSION',
        r'$policy',
        'ML-7 must bind exactly to the frozen ML-1 through ML-6 contracts.',
      );
    }

    _validateStartupContract(policy['startupContract'], issues);
    _validateTextRules(policy['textRules'], issues);
    _validatePlainTextRules(policy['plainTextRules'], issues);
    _validateAbbreviationRules(policy['abbreviationRules'], issues);
    _validateVisualRules(policy['visualIndependenceRules'], issues);
    _validateAssessmentRules(policy['assessmentRules'], issues);
    _validatePrecisionRules(policy['precisionRules'], issues);
    _validateAccessibilityRules(policy['accessibilityRules'], issues);
    _validateEvidenceRules(policy['evidenceRules'], issues);
    _validateDriftRules(policy['driftRules'], issues);

    return StartupPedagogyPolicyValidationResult(List.unmodifiable(issues));
  }

  void _validateStartupContract(
    dynamic value,
    List<StartupPedagogyPolicyIssue> issues,
  ) {
    final map = _requiredMap(
      value,
      r'$policy.startupContract',
      'ML7_POLICY_STARTUP_CONTRACT',
      issues,
    );
    if (map == null) return;

    _exactKeys(
      map,
      const {
        'fullMotionDurationMs',
        'reducedMotionDurationMs',
        'watchdogCeilingMs',
        'artificialDelayAllowed',
        'microFactMayBlockStartup',
        'runtimeNetworkReadAllowed',
        'shortVariantIsPrimaryStartupCopy',
      },
      r'$policy.startupContract',
      issues,
    );

    if (map['fullMotionDurationMs'] != 4800 ||
        map['reducedMotionDurationMs'] != 250 ||
        map['watchdogCeilingMs'] != 7000 ||
        map['artificialDelayAllowed'] != false ||
        map['microFactMayBlockStartup'] != false ||
        map['runtimeNetworkReadAllowed'] != false ||
        map['shortVariantIsPrimaryStartupCopy'] != true) {
      _add(
        issues,
        'ML7_POLICY_STARTUP_CONTRACT_WEAKENED',
        r'$policy.startupContract',
        'Startup timing, fail-open or local-only invariants were weakened.',
      );
    }
  }

  void _validateTextRules(
    dynamic value,
    List<StartupPedagogyPolicyIssue> issues,
  ) {
    final map = _requiredMap(
      value,
      r'$policy.textRules',
      'ML7_POLICY_TEXT_RULES',
      issues,
    );
    if (map == null) return;

    _exactKeys(
      map,
      const {
        'displayText',
        'shortVariant',
        'nominalReadingWordsPerMinute',
        'estimatedReadSecondsTolerance',
        'maxParentheticalGroups',
        'maxConsecutivePunctuationMarks',
        'allowQuestionMarkForCategories',
      },
      r'$policy.textRules',
      issues,
    );

    final display = _requiredMap(
      map['displayText'],
      r'$policy.textRules.displayText',
      'ML7_POLICY_DISPLAY_RULES',
      issues,
    );
    if (display != null) {
      _exactKeys(
        display,
        const {
          'minWords',
          'maxWords',
          'maxCharacters',
          'maxSentences',
          'maxEstimatedReadSeconds',
        },
        r'$policy.textRules.displayText',
        issues,
      );
      if (display['minWords'] != 6 ||
          display['maxWords'] != 32 ||
          display['maxCharacters'] != 260 ||
          display['maxSentences'] != 2 ||
          display['maxEstimatedReadSeconds'] != 10) {
        _add(
          issues,
          'ML7_POLICY_DISPLAY_RULES_WEAKENED',
          r'$policy.textRules.displayText',
          'Display-text startup suitability limits were altered.',
        );
      }
    }

    final short = _requiredMap(
      map['shortVariant'],
      r'$policy.textRules.shortVariant',
      'ML7_POLICY_SHORT_RULES',
      issues,
    );
    if (short != null) {
      _exactKeys(
        short,
        const {
          'requiredWhenStartupEligible',
          'minWords',
          'maxWords',
          'maxCharacters',
          'maxSentences',
          'maxComputedReadSeconds',
        },
        r'$policy.textRules.shortVariant',
        issues,
      );
      if (short['requiredWhenStartupEligible'] != true ||
          short['minWords'] != 4 ||
          short['maxWords'] != 18 ||
          short['maxCharacters'] != 140 ||
          short['maxSentences'] != 1 ||
          short['maxComputedReadSeconds'] != 6) {
        _add(
          issues,
          'ML7_POLICY_SHORT_RULES_WEAKENED',
          r'$policy.textRules.shortVariant',
          'Startup short-copy limits were altered.',
        );
      }
    }

    if (map['nominalReadingWordsPerMinute'] != 150 ||
        map['estimatedReadSecondsTolerance'] != 2 ||
        map['maxParentheticalGroups'] != 1 ||
        map['maxConsecutivePunctuationMarks'] != 1 ||
        !_sameSet(
          _stringSet(map['allowQuestionMarkForCategories']),
          const {'think_about_it'},
        )) {
      _add(
        issues,
        'ML7_POLICY_TEXT_METRIC_RULES_WEAKENED',
        r'$policy.textRules',
        'Reading-speed, punctuation or category rules were altered.',
      );
    }
  }

  void _validatePlainTextRules(
    dynamic value,
    List<StartupPedagogyPolicyIssue> issues,
  ) {
    final map = _requiredMap(
      value,
      r'$policy.plainTextRules',
      'ML7_POLICY_PLAIN_TEXT',
      issues,
    );
    if (map == null) return;

    const keys = {
      'newlinesAllowed',
      'tabsAllowed',
      'htmlAllowed',
      'markdownLinksAllowed',
      'rawUrlsAllowed',
      'emojiAllowed',
      'bulletPrefixesAllowed',
      'sourceLabelPrefixesAllowed',
      'repeatedWhitespaceAllowed',
    };
    _exactKeys(map, keys, r'$policy.plainTextRules', issues);

    for (final key in keys) {
      if (map[key] != false) {
        _add(
          issues,
          'ML7_POLICY_PLAIN_TEXT_WEAKENED',
          r'$policy.plainTextRules.' + key,
          key + ' must remain false.',
        );
      }
    }
  }

  void _validateAbbreviationRules(
    dynamic value,
    List<StartupPedagogyPolicyIssue> issues,
  ) {
    final map = _requiredMap(
      value,
      r'$policy.abbreviationRules',
      'ML7_POLICY_ABBREVIATIONS',
      issues,
    );
    if (map == null) return;

    _exactKeys(
      map,
      const {'maxUnknownUppercaseTokens', 'approvedUppercaseTokens'},
      r'$policy.abbreviationRules',
      issues,
    );

    if (map['maxUnknownUppercaseTokens'] != 0) {
      _add(
        issues,
        'ML7_POLICY_ABBREVIATION_LIMIT_WEAKENED',
        r'$policy.abbreviationRules.maxUnknownUppercaseTokens',
        'Unknown all-caps jargon must remain blocked.',
      );
    }

    final approved = _stringSet(map['approvedUppercaseTokens']);
    if (!approved.containsAll(const {
      'CSP',
      'OSHA',
      'NIOSH',
      'ISO',
      'NFPA',
      'PPE',
      'PSM',
      'LOTO',
      'BEST',
    })) {
      _add(
        issues,
        'ML7_POLICY_ABBREVIATION_ALLOWLIST',
        r'$policy.abbreviationRules.approvedUppercaseTokens',
        'Required known safety/exam abbreviations are missing.',
      );
    }
  }

  void _validateVisualRules(
    dynamic value,
    List<StartupPedagogyPolicyIssue> issues,
  ) {
    final map = _requiredMap(
      value,
      r'$policy.visualIndependenceRules',
      'ML7_POLICY_VISUAL_RULES',
      issues,
    );
    if (map == null) return;

    _exactKeys(
      map,
      const {
        'blockedPhrases',
        'meaningMayDependOnColor',
        'meaningMayDependOnMotion',
        'meaningMayDependOnIcon',
        'meaningMayDependOnPosition',
      },
      r'$policy.visualIndependenceRules',
      issues,
    );

    if (map['meaningMayDependOnColor'] != false ||
        map['meaningMayDependOnMotion'] != false ||
        map['meaningMayDependOnIcon'] != false ||
        map['meaningMayDependOnPosition'] != false ||
        _stringList(map['blockedPhrases']).isEmpty) {
      _add(
        issues,
        'ML7_POLICY_VISUAL_RULES_WEAKENED',
        r'$policy.visualIndependenceRules',
        'Visual-independence requirements were weakened.',
      );
    }
  }

  void _validateAssessmentRules(
    dynamic value,
    List<StartupPedagogyPolicyIssue> issues,
  ) {
    final map = _requiredMap(
      value,
      r'$policy.assessmentRules',
      'ML7_POLICY_ASSESSMENT_RULES',
      issues,
    );
    if (map == null) return;

    _exactKeys(
      map,
      const {
        'blockedStartupSensitivities',
        'answerKeyLanguageAllowed',
        'exactQuestionAnswerDisclosureAllowed',
        'assessmentReviewRequired',
      },
      r'$policy.assessmentRules',
      issues,
    );

    if (!_sameSet(
          _stringSet(map['blockedStartupSensitivities']),
          const {'high', 'block_during_linked_assessment'},
        ) ||
        map['answerKeyLanguageAllowed'] != false ||
        map['exactQuestionAnswerDisclosureAllowed'] != false ||
        map['assessmentReviewRequired'] != true) {
      _add(
        issues,
        'ML7_POLICY_ASSESSMENT_RULES_WEAKENED',
        r'$policy.assessmentRules',
        'Assessment-leakage safeguards were weakened.',
      );
    }
  }

  void _validatePrecisionRules(
    dynamic value,
    List<StartupPedagogyPolicyIssue> issues,
  ) {
    final map = _requiredMap(
      value,
      r'$policy.precisionRules',
      'ML7_POLICY_PRECISION_RULES',
      issues,
    );
    if (map == null) return;

    const keys = {
      'safetyCriticalRequiresHumanPrecisionReview',
      'mediumOrHighSimplificationRiskRequiresMeaningPreservationReview',
      'numericalClaimRequiresHumanPresentationReview',
      'legalStatusQualifierMayNotBeRemovedInShortVariant',
      'sourceAttributionMayBeOmittedFromShortVariantOnlyWhenClaimMeaningRemainsCorrect',
    };
    _exactKeys(map, keys, r'$policy.precisionRules', issues);

    for (final key in keys) {
      if (map[key] != true) {
        _add(
          issues,
          'ML7_POLICY_PRECISION_RULES_WEAKENED',
          r'$policy.precisionRules.' + key,
          key + ' must remain true.',
        );
      }
    }
  }

  void _validateAccessibilityRules(
    dynamic value,
    List<StartupPedagogyPolicyIssue> issues,
  ) {
    final map = _requiredMap(
      value,
      r'$policy.accessibilityRules',
      'ML7_POLICY_ACCESSIBILITY_RULES',
      issues,
    );
    if (map == null) return;

    const keys = {
      'semanticMeaningMustStandAlone',
      'reducedMotionMeaningMustBeEquivalent',
      'screenReaderMeaningMustBeEquivalent',
      'decorativeAnimationCannotCarryMeaning',
      'noForcedInteraction',
      'noTimeCriticalResponse',
      'noFlashingInstruction',
    };
    _exactKeys(map, keys, r'$policy.accessibilityRules', issues);

    for (final key in keys) {
      if (map[key] != true) {
        _add(
          issues,
          'ML7_POLICY_ACCESSIBILITY_RULES_WEAKENED',
          r'$policy.accessibilityRules.' + key,
          key + ' must remain true.',
        );
      }
    }
  }

  void _validateEvidenceRules(
    dynamic value,
    List<StartupPedagogyPolicyIssue> issues,
  ) {
    final map = _requiredMap(
      value,
      r'$policy.evidenceRules',
      'ML7_POLICY_EVIDENCE_RULES',
      issues,
    );
    if (map == null) return;

    _exactKeys(
      map,
      const {
        'evidenceSchemaVersion',
        'evidenceIdPattern',
        'sha256Pattern',
        'requiredForStartupEligibleStatuses',
        'mustPassForStartupEligibleStatuses',
        'maxEvidenceAgeDays',
        'exactContentFingerprintRequired',
        'pedagogyReviewerRoles',
        'accessibilityReviewerRoles',
        'reviewStatusValues',
      },
      r'$policy.evidenceRules',
      issues,
    );

    if (map['evidenceSchemaVersion'] != 1 ||
        map['evidenceIdPattern'] != r'^mfpe_[a-z0-9][a-z0-9_-]{5,63}$' ||
        map['sha256Pattern'] != r'^[a-f0-9]{64}$' ||
        map['maxEvidenceAgeDays'] != 365 ||
        map['exactContentFingerprintRequired'] != true ||
        !_sameSet(
          _stringSet(map['requiredForStartupEligibleStatuses']),
          const {'validated', 'published', 'review_due'},
        ) ||
        !_sameSet(
          _stringSet(map['mustPassForStartupEligibleStatuses']),
          const {'validated', 'published'},
        ) ||
        !_sameSet(
          _stringSet(map['pedagogyReviewerRoles']),
          pedagogyReviewerRoles,
        ) ||
        !_sameSet(
          _stringSet(map['accessibilityReviewerRoles']),
          accessibilityReviewerRoles,
        ) ||
        !_sameSet(
          _stringSet(map['reviewStatusValues']),
          reviewStatuses,
        )) {
      _add(
        issues,
        'ML7_POLICY_EVIDENCE_RULES_WEAKENED',
        r'$policy.evidenceRules',
        'Startup pedagogy evidence safeguards were altered.',
      );
    }
  }

  void _validateDriftRules(
    dynamic value,
    List<StartupPedagogyPolicyIssue> issues,
  ) {
    final map = _requiredMap(
      value,
      r'$policy.driftRules',
      'ML7_POLICY_DRIFT_RULES',
      issues,
    );
    if (map == null) return;

    const keys = {
      'contentVersionChangeInvalidatesEvidence',
      'displayTextChangeInvalidatesEvidence',
      'shortVariantChangeInvalidatesEvidence',
      'estimatedReadSecondsChangeInvalidatesEvidence',
      'startupEligibilityChangeRequiresReevaluation',
      'policyVersionChangeInvalidatesEvidence',
    };
    _exactKeys(map, keys, r'$policy.driftRules', issues);

    for (final key in keys) {
      if (map[key] != true) {
        _add(
          issues,
          'ML7_POLICY_DRIFT_RULES_WEAKENED',
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
    List<StartupPedagogyPolicyIssue> issues,
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
    List<StartupPedagogyPolicyIssue> issues,
  ) {
    final actual = map.keys.toSet();
    for (final missing in expected.difference(actual)) {
      _add(
        issues,
        'ML7_POLICY_REQUIRED_FIELD',
        path + '.' + missing,
        'Required policy field is missing.',
      );
    }
    for (final extra in actual.difference(expected)) {
      _add(
        issues,
        'ML7_POLICY_UNKNOWN_FIELD',
        path + '.' + extra,
        'Unknown policy field is not allowed.',
      );
    }
  }

  static Set<String> _stringSet(dynamic value) => _stringList(value).toSet();

  static List<String> _stringList(dynamic value) {
    if (value is! List) return const <String>[];
    return value.whereType<String>().toList(growable: false);
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
        parsed.year.toString().padLeft(4, '0') +
        '-' +
        parsed.month.toString().padLeft(2, '0') +
        '-' +
        parsed.day.toString().padLeft(2, '0');
    return normalized == value;
  }

  static void _add(
    List<StartupPedagogyPolicyIssue> issues,
    String code,
    String path,
    String message,
  ) {
    issues.add(
      StartupPedagogyPolicyIssue(
        code: code,
        path: path,
        message: message,
      ),
    );
  }
}
