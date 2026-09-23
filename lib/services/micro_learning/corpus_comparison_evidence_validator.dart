import 'duplicate_contradiction_policy_validator.dart';

class CorpusComparisonEvidenceIssue {
  const CorpusComparisonEvidenceIssue({
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

class CorpusComparisonEvidenceValidationResult {
  const CorpusComparisonEvidenceValidationResult(this.issues);

  final List<CorpusComparisonEvidenceIssue> issues;

  bool get isValid => issues.isEmpty;
}

class CorpusComparisonEvidenceValidator {
  static const int schemaVersion = 1;

  const CorpusComparisonEvidenceValidator();

  CorpusComparisonEvidenceValidationResult validateMap(
    Map<String, dynamic> evidence,
  ) {
    final issues = <CorpusComparisonEvidenceIssue>[];

    _exactKeys(
      evidence,
      const {
        'schemaVersion',
        'evidenceId',
        'policyVersion',
        'pairKey',
        'left',
        'right',
        'detectedSignals',
        'decision',
        'review',
      },
      r'$evidence',
      issues,
    );

    if (evidence['schemaVersion'] != schemaVersion) {
      _add(
        issues,
        'ML8_EVIDENCE_SCHEMA_VERSION',
        r'$evidence.schemaVersion',
        'Corpus comparison evidence schemaVersion must be 1.',
      );
    }

    _patternString(
      evidence['evidenceId'],
      RegExp(r'^mfce_[a-z0-9][a-z0-9_-]{5,63}$'),
      r'$evidence.evidenceId',
      'ML8_EVIDENCE_ID',
      issues,
    );

    if (evidence['policyVersion'] !=
        DuplicateContradictionPolicyValidator.requiredPolicyVersion) {
      _add(
        issues,
        'ML8_EVIDENCE_POLICY_VERSION',
        r'$evidence.policyVersion',
        'Evidence must bind to the frozen ML-8 policy version.',
      );
    }

    final left = _requiredMap(
      evidence['left'],
      r'$evidence.left',
      'ML8_EVIDENCE_LEFT',
      issues,
    );
    final right = _requiredMap(
      evidence['right'],
      r'$evidence.right',
      'ML8_EVIDENCE_RIGHT',
      issues,
    );

    if (left != null) {
      _validateFactRef(left, r'$evidence.left', issues);
    }
    if (right != null) {
      _validateFactRef(right, r'$evidence.right', issues);
    }

    if (left != null && right != null) {
      final leftKey = _factVersionKey(left);
      final rightKey = _factVersionKey(right);
      if (leftKey.compareTo(rightKey) >= 0) {
        _add(
          issues,
          'ML8_EVIDENCE_PAIR_ORDER',
          r'$evidence',
          'Pair evidence must use canonical lexical left/right ordering.',
        );
      }

      final expectedPairKey = leftKey + '||' + rightKey;
      if (evidence['pairKey'] != expectedPairKey) {
        _add(
          issues,
          'ML8_EVIDENCE_PAIR_KEY',
          r'$evidence.pairKey',
          'pairKey must exactly match the canonical fact-version pair.',
        );
      }
    }

    final signals = evidence['detectedSignals'];
    if (signals is! List || signals.isEmpty) {
      _add(
        issues,
        'ML8_EVIDENCE_SIGNALS',
        r'$evidence.detectedSignals',
        'At least one detected comparison signal is required.',
      );
    } else {
      final typed = signals.whereType<String>().toList();
      if (typed.length != signals.length ||
          typed.toSet().length != typed.length ||
          typed.any(
            (signal) => !DuplicateContradictionPolicyValidator.comparisonSignals
                .contains(signal),
          )) {
        _add(
          issues,
          'ML8_EVIDENCE_SIGNALS',
          r'$evidence.detectedSignals',
          'Detected signals must be unique frozen ML-8 signal values.',
        );
      }
    }

    final decisions = {
      ...DuplicateContradictionPolicyValidator.passDecisions,
      ...DuplicateContradictionPolicyValidator.blockDecisions,
    };
    if (!decisions.contains(evidence['decision'])) {
      _add(
        issues,
        'ML8_EVIDENCE_DECISION',
        r'$evidence.decision',
        'Unknown ML-8 adjudication decision.',
      );
    }

    final review = _requiredMap(
      evidence['review'],
      r'$evidence.review',
      'ML8_EVIDENCE_REVIEW',
      issues,
    );
    if (review != null) {
      _validateReview(review, issues);
    }

    return CorpusComparisonEvidenceValidationResult(List.unmodifiable(issues));
  }

  void _validateFactRef(
    Map<String, dynamic> ref,
    String path,
    List<CorpusComparisonEvidenceIssue> issues,
  ) {
    _exactKeys(
      ref,
      const {'microFactId', 'contentVersion', 'comparisonFingerprintSha256'},
      path,
      issues,
    );

    _patternString(
      ref['microFactId'],
      RegExp(r'^mf_[a-z0-9][a-z0-9_-]{5,63}$'),
      path + '.microFactId',
      'ML8_EVIDENCE_FACT_ID',
      issues,
    );

    final version = ref['contentVersion'];
    if (version is! int || version < 1) {
      _add(
        issues,
        'ML8_EVIDENCE_CONTENT_VERSION',
        path + '.contentVersion',
        'contentVersion must be an integer greater than zero.',
      );
    }

    _patternString(
      ref['comparisonFingerprintSha256'],
      RegExp(r'^[a-f0-9]{64}$'),
      path + '.comparisonFingerprintSha256',
      'ML8_EVIDENCE_FINGERPRINT',
      issues,
    );
  }

  void _validateReview(
    Map<String, dynamic> review,
    List<CorpusComparisonEvidenceIssue> issues,
  ) {
    _exactKeys(
      review,
      const {
        'status',
        'reviewerRole',
        'humanReviewed',
        'rationale',
        'reviewedAt',
        'nextReviewDueAt',
      },
      r'$evidence.review',
      issues,
    );

    if (!DuplicateContradictionPolicyValidator.reviewStatuses.contains(
      review['status'],
    )) {
      _add(
        issues,
        'ML8_EVIDENCE_REVIEW_STATUS',
        r'$evidence.review.status',
        'Unknown adjudication review status.',
      );
    }

    if (!DuplicateContradictionPolicyValidator.reviewerRoles.contains(
      review['reviewerRole'],
    )) {
      _add(
        issues,
        'ML8_EVIDENCE_REVIEWER_ROLE',
        r'$evidence.review.reviewerRole',
        'Unknown adjudication reviewer role.',
      );
    }

    if (review['humanReviewed'] is! bool) {
      _add(
        issues,
        'ML8_EVIDENCE_HUMAN_REVIEW',
        r'$evidence.review.humanReviewed',
        'humanReviewed must be boolean.',
      );
    }

    final rationale = review['rationale'];
    if (rationale is! String ||
        rationale.trim().isEmpty ||
        rationale.length > 1000) {
      _add(
        issues,
        'ML8_EVIDENCE_RATIONALE',
        r'$evidence.review.rationale',
        'rationale must be a non-empty string up to 1000 characters.',
      );
    }

    for (final key in const {'reviewedAt', 'nextReviewDueAt'}) {
      final value = review[key];
      if (value != null && !_isStrictDate(value)) {
        _add(
          issues,
          'ML8_EVIDENCE_REVIEW_DATE',
          r'$evidence.review.' + key,
          key + ' must be null or a valid YYYY-MM-DD date.',
        );
      }
    }

    final reviewedAt = _parseStrictDate(review['reviewedAt']);
    final dueAt = _parseStrictDate(review['nextReviewDueAt']);
    if (reviewedAt != null && dueAt != null && dueAt.isBefore(reviewedAt)) {
      _add(
        issues,
        'ML8_EVIDENCE_REVIEW_DATE_ORDER',
        r'$evidence.review.nextReviewDueAt',
        'Review due date cannot precede the review date.',
      );
    }

    if (review['status'] == 'pass' &&
        (review['humanReviewed'] != true ||
            reviewedAt == null ||
            dueAt == null)) {
      _add(
        issues,
        'ML8_EVIDENCE_PASS_REQUIREMENTS',
        r'$evidence.review',
        'Passing adjudication requires human review and valid review dates.',
      );
    }
  }

  static String _factVersionKey(Map<String, dynamic> ref) {
    final id = ref['microFactId'];
    final version = ref['contentVersion'];
    if (id is! String || version is! int) return '';
    return id + '@' + version.toString();
  }

  static Map<String, dynamic>? _requiredMap(
    dynamic value,
    String path,
    String code,
    List<CorpusComparisonEvidenceIssue> issues,
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
    List<CorpusComparisonEvidenceIssue> issues,
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
    List<CorpusComparisonEvidenceIssue> issues,
  ) {
    final actual = map.keys.toSet();
    for (final missing in expected.difference(actual)) {
      _add(
        issues,
        'ML8_EVIDENCE_REQUIRED_FIELD',
        path + '.' + missing,
        'Required evidence field is missing.',
      );
    }
    for (final extra in actual.difference(expected)) {
      _add(
        issues,
        'ML8_EVIDENCE_UNKNOWN_FIELD',
        path + '.' + extra,
        'Unknown evidence field is not allowed.',
      );
    }
  }

  static void _add(
    List<CorpusComparisonEvidenceIssue> issues,
    String code,
    String path,
    String message,
  ) {
    issues.add(
      CorpusComparisonEvidenceIssue(code: code, path: path, message: message),
    );
  }
}
