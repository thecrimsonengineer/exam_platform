import 'startup_pedagogy_policy_validator.dart';

class StartupPedagogyEvidenceIssue {
  const StartupPedagogyEvidenceIssue({
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

class StartupPedagogyEvidenceValidationResult {
  const StartupPedagogyEvidenceValidationResult(this.issues);

  final List<StartupPedagogyEvidenceIssue> issues;

  bool get isValid => issues.isEmpty;
}

class StartupPedagogyEvidenceValidator {
  static const int schemaVersion = 1;

  const StartupPedagogyEvidenceValidator();

  StartupPedagogyEvidenceValidationResult validateMap(
    Map<String, dynamic> evidence,
  ) {
    final issues = <StartupPedagogyEvidenceIssue>[];

    _exactKeys(
      evidence,
      const {
        'schemaVersion',
        'evidenceId',
        'microFactId',
        'contentVersion',
        'pedagogyPolicyVersion',
        'contentFingerprint',
        'metrics',
        'pedagogyReview',
        'accessibilityReview',
      },
      r'$evidence',
      issues,
    );

    if (evidence['schemaVersion'] != schemaVersion) {
      _add(
        issues,
        'ML7_EVIDENCE_SCHEMA_VERSION',
        r'$evidence.schemaVersion',
        'Startup pedagogy evidence schemaVersion must be 1.',
      );
    }

    _patternString(
      evidence['evidenceId'],
      RegExp(r'^mfpe_[a-z0-9][a-z0-9_-]{5,63}$'),
      r'$evidence.evidenceId',
      'ML7_EVIDENCE_ID',
      issues,
    );
    _patternString(
      evidence['microFactId'],
      RegExp(r'^mf_[a-z0-9][a-z0-9_-]{5,63}$'),
      r'$evidence.microFactId',
      'ML7_EVIDENCE_FACT_ID',
      issues,
    );

    final contentVersion = evidence['contentVersion'];
    if (contentVersion is! int || contentVersion < 1) {
      _add(
        issues,
        'ML7_EVIDENCE_CONTENT_VERSION',
        r'$evidence.contentVersion',
        'contentVersion must be an integer greater than zero.',
      );
    }

    if (evidence['pedagogyPolicyVersion'] !=
        StartupPedagogyPolicyValidator.requiredPolicyVersion) {
      _add(
        issues,
        'ML7_EVIDENCE_POLICY_VERSION',
        r'$evidence.pedagogyPolicyVersion',
        'Evidence must bind to the frozen ML-7 policy version.',
      );
    }

    final fingerprint = _requiredMap(
      evidence['contentFingerprint'],
      r'$evidence.contentFingerprint',
      'ML7_EVIDENCE_FINGERPRINT',
      issues,
    );
    if (fingerprint != null) {
      _validateFingerprint(fingerprint, issues);
    }

    final metrics = _requiredMap(
      evidence['metrics'],
      r'$evidence.metrics',
      'ML7_EVIDENCE_METRICS',
      issues,
    );
    if (metrics != null) {
      _validateMetrics(metrics, issues);
    }

    final pedagogy = _requiredMap(
      evidence['pedagogyReview'],
      r'$evidence.pedagogyReview',
      'ML7_EVIDENCE_PEDAGOGY_REVIEW',
      issues,
    );
    if (pedagogy != null) {
      _validatePedagogyReview(pedagogy, issues);
    }

    final accessibility = _requiredMap(
      evidence['accessibilityReview'],
      r'$evidence.accessibilityReview',
      'ML7_EVIDENCE_ACCESSIBILITY_REVIEW',
      issues,
    );
    if (accessibility != null) {
      _validateAccessibilityReview(accessibility, issues);
    }

    return StartupPedagogyEvidenceValidationResult(List.unmodifiable(issues));
  }

  void _validateFingerprint(
    Map<String, dynamic> map,
    List<StartupPedagogyEvidenceIssue> issues,
  ) {
    _exactKeys(
      map,
      const {'displayTextSha256', 'shortVariantSha256', 'estimatedReadSeconds'},
      r'$evidence.contentFingerprint',
      issues,
    );

    _patternString(
      map['displayTextSha256'],
      RegExp(r'^[a-f0-9]{64}$'),
      r'$evidence.contentFingerprint.displayTextSha256',
      'ML7_EVIDENCE_DISPLAY_HASH',
      issues,
    );

    final shortHash = map['shortVariantSha256'];
    if (shortHash != null &&
        (shortHash is! String ||
            !RegExp(r'^[a-f0-9]{64}$').hasMatch(shortHash))) {
      _add(
        issues,
        'ML7_EVIDENCE_SHORT_HASH',
        r'$evidence.contentFingerprint.shortVariantSha256',
        'shortVariantSha256 must be null or a lowercase SHA-256 digest.',
      );
    }

    final seconds = map['estimatedReadSeconds'];
    if (seconds is! int || seconds < 1 || seconds > 30) {
      _add(
        issues,
        'ML7_EVIDENCE_READ_SECONDS',
        r'$evidence.contentFingerprint.estimatedReadSeconds',
        'estimatedReadSeconds must be an integer from 1 to 30.',
      );
    }
  }

  void _validateMetrics(
    Map<String, dynamic> map,
    List<StartupPedagogyEvidenceIssue> issues,
  ) {
    _exactKeys(
      map,
      const {
        'displayWordCount',
        'displaySentenceCount',
        'computedDisplayReadSeconds',
        'shortWordCount',
        'shortSentenceCount',
        'computedShortReadSeconds',
      },
      r'$evidence.metrics',
      issues,
    );

    for (final key in const {
      'displayWordCount',
      'displaySentenceCount',
      'computedDisplayReadSeconds',
    }) {
      final value = map[key];
      if (value is! int || value < 1) {
        _add(
          issues,
          'ML7_EVIDENCE_METRIC_VALUE',
          r'$evidence.metrics.' + key,
          key + ' must be a positive integer.',
        );
      }
    }

    for (final key in const {
      'shortWordCount',
      'shortSentenceCount',
      'computedShortReadSeconds',
    }) {
      final value = map[key];
      if (value != null && (value is! int || value < 1)) {
        _add(
          issues,
          'ML7_EVIDENCE_METRIC_VALUE',
          r'$evidence.metrics.' + key,
          key + ' must be null or a positive integer.',
        );
      }
    }

    final shortValues = <dynamic>[
      map['shortWordCount'],
      map['shortSentenceCount'],
      map['computedShortReadSeconds'],
    ];
    final nullCount = shortValues.where((value) => value == null).length;
    if (nullCount != 0 && nullCount != shortValues.length) {
      _add(
        issues,
        'ML7_EVIDENCE_SHORT_METRICS_PARTIAL',
        r'$evidence.metrics',
        'Short-variant metrics must be either all null or all populated.',
      );
    }
  }

  void _validatePedagogyReview(
    Map<String, dynamic> map,
    List<StartupPedagogyEvidenceIssue> issues,
  ) {
    _exactKeys(
      map,
      const {
        'status',
        'reviewerRole',
        'humanReviewed',
        'singleConceptConfirmed',
        'standaloneMeaningConfirmed',
        'cognitiveLoadAcceptable',
        'jargonLoadAcceptable',
        'shortVariantMeaningPreserved',
        'precisionPreserved',
        'assessmentLeakageReviewed',
        'reviewedAt',
        'nextReviewDueAt',
      },
      r'$evidence.pedagogyReview',
      issues,
    );

    if (!StartupPedagogyPolicyValidator.reviewStatuses.contains(
      map['status'],
    )) {
      _add(
        issues,
        'ML7_EVIDENCE_PEDAGOGY_STATUS',
        r'$evidence.pedagogyReview.status',
        'Unknown pedagogy review status.',
      );
    }

    if (!StartupPedagogyPolicyValidator.pedagogyReviewerRoles.contains(
      map['reviewerRole'],
    )) {
      _add(
        issues,
        'ML7_EVIDENCE_PEDAGOGY_ROLE',
        r'$evidence.pedagogyReview.reviewerRole',
        'Unknown pedagogy reviewer role.',
      );
    }

    const booleans = {
      'humanReviewed',
      'singleConceptConfirmed',
      'standaloneMeaningConfirmed',
      'cognitiveLoadAcceptable',
      'jargonLoadAcceptable',
      'shortVariantMeaningPreserved',
      'precisionPreserved',
      'assessmentLeakageReviewed',
    };
    _validateBooleans(map, booleans, r'$evidence.pedagogyReview', issues);

    _validateReviewDates(map, r'$evidence.pedagogyReview', issues);

    if (map['status'] == 'pass') {
      for (final key in booleans) {
        if (map[key] != true) {
          _add(
            issues,
            'ML7_EVIDENCE_PEDAGOGY_PASS_REQUIREMENTS',
            r'$evidence.pedagogyReview.' + key,
            'Passing pedagogy review requires ' + key + ' = true.',
          );
        }
      }
      if (_parseStrictDate(map['reviewedAt']) == null ||
          _parseStrictDate(map['nextReviewDueAt']) == null) {
        _add(
          issues,
          'ML7_EVIDENCE_PEDAGOGY_PASS_REQUIREMENTS',
          r'$evidence.pedagogyReview',
          'Passing pedagogy review requires valid review dates.',
        );
      }
    }
  }

  void _validateAccessibilityReview(
    Map<String, dynamic> map,
    List<StartupPedagogyEvidenceIssue> issues,
  ) {
    _exactKeys(
      map,
      const {
        'status',
        'reviewerRole',
        'humanReviewed',
        'screenReaderStandaloneConfirmed',
        'visualIndependenceConfirmed',
        'reducedMotionEquivalentConfirmed',
        'plainLanguageAccessibleConfirmed',
        'noForcedInteractionConfirmed',
        'reviewedAt',
        'nextReviewDueAt',
      },
      r'$evidence.accessibilityReview',
      issues,
    );

    if (!StartupPedagogyPolicyValidator.reviewStatuses.contains(
      map['status'],
    )) {
      _add(
        issues,
        'ML7_EVIDENCE_ACCESSIBILITY_STATUS',
        r'$evidence.accessibilityReview.status',
        'Unknown accessibility review status.',
      );
    }

    if (!StartupPedagogyPolicyValidator.accessibilityReviewerRoles.contains(
      map['reviewerRole'],
    )) {
      _add(
        issues,
        'ML7_EVIDENCE_ACCESSIBILITY_ROLE',
        r'$evidence.accessibilityReview.reviewerRole',
        'Unknown accessibility reviewer role.',
      );
    }

    const booleans = {
      'humanReviewed',
      'screenReaderStandaloneConfirmed',
      'visualIndependenceConfirmed',
      'reducedMotionEquivalentConfirmed',
      'plainLanguageAccessibleConfirmed',
      'noForcedInteractionConfirmed',
    };
    _validateBooleans(map, booleans, r'$evidence.accessibilityReview', issues);

    _validateReviewDates(map, r'$evidence.accessibilityReview', issues);

    if (map['status'] == 'pass') {
      for (final key in booleans) {
        if (map[key] != true) {
          _add(
            issues,
            'ML7_EVIDENCE_ACCESSIBILITY_PASS_REQUIREMENTS',
            r'$evidence.accessibilityReview.' + key,
            'Passing accessibility review requires ' + key + ' = true.',
          );
        }
      }
      if (_parseStrictDate(map['reviewedAt']) == null ||
          _parseStrictDate(map['nextReviewDueAt']) == null) {
        _add(
          issues,
          'ML7_EVIDENCE_ACCESSIBILITY_PASS_REQUIREMENTS',
          r'$evidence.accessibilityReview',
          'Passing accessibility review requires valid review dates.',
        );
      }
    }
  }

  void _validateBooleans(
    Map<String, dynamic> map,
    Set<String> keys,
    String path,
    List<StartupPedagogyEvidenceIssue> issues,
  ) {
    for (final key in keys) {
      if (map[key] is! bool) {
        _add(
          issues,
          'ML7_EVIDENCE_BOOLEAN',
          path + '.' + key,
          key + ' must be boolean.',
        );
      }
    }
  }

  void _validateReviewDates(
    Map<String, dynamic> map,
    String path,
    List<StartupPedagogyEvidenceIssue> issues,
  ) {
    for (final key in const {'reviewedAt', 'nextReviewDueAt'}) {
      final value = map[key];
      if (value != null && !_isStrictDate(value)) {
        _add(
          issues,
          'ML7_EVIDENCE_REVIEW_DATE',
          path + '.' + key,
          key + ' must be null or a valid YYYY-MM-DD date.',
        );
      }
    }

    final reviewedAt = _parseStrictDate(map['reviewedAt']);
    final dueAt = _parseStrictDate(map['nextReviewDueAt']);
    if (reviewedAt != null && dueAt != null && dueAt.isBefore(reviewedAt)) {
      _add(
        issues,
        'ML7_EVIDENCE_REVIEW_DATE_ORDER',
        path + '.nextReviewDueAt',
        'Review due date cannot precede the review date.',
      );
    }
  }

  static Map<String, dynamic>? _requiredMap(
    dynamic value,
    String path,
    String code,
    List<StartupPedagogyEvidenceIssue> issues,
  ) {
    if (value is! Map) {
      _add(issues, code, path, 'A JSON object is required.');
      return null;
    }
    return Map<String, dynamic>.from(value);
  }

  static void _patternString(
    dynamic value,
    RegExp pattern,
    String path,
    String code,
    List<StartupPedagogyEvidenceIssue> issues,
  ) {
    if (value is! String || !pattern.hasMatch(value)) {
      _add(issues, code, path, 'Value does not match the required pattern.');
    }
  }

  static DateTime? _parseStrictDate(dynamic value) {
    if (value is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      return null;
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return null;
    final normalized =
        parsed.year.toString().padLeft(4, '0') +
        '-' +
        parsed.month.toString().padLeft(2, '0') +
        '-' +
        parsed.day.toString().padLeft(2, '0');
    return normalized == value ? parsed : null;
  }

  static bool _isStrictDate(dynamic value) => _parseStrictDate(value) != null;

  static void _exactKeys(
    Map<String, dynamic> map,
    Set<String> expected,
    String path,
    List<StartupPedagogyEvidenceIssue> issues,
  ) {
    final actual = map.keys.toSet();
    for (final missing in expected.difference(actual)) {
      _add(
        issues,
        'ML7_EVIDENCE_REQUIRED_FIELD',
        path + '.' + missing,
        'Required evidence field is missing.',
      );
    }
    for (final extra in actual.difference(expected)) {
      _add(
        issues,
        'ML7_EVIDENCE_UNKNOWN_FIELD',
        path + '.' + extra,
        'Unknown evidence field is not allowed.',
      );
    }
  }

  static void _add(
    List<StartupPedagogyEvidenceIssue> issues,
    String code,
    String path,
    String message,
  ) {
    issues.add(
      StartupPedagogyEvidenceIssue(code: code, path: path, message: message),
    );
  }
}
