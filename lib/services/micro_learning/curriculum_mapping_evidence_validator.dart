import 'canonical_curriculum_policy_validator.dart';

class CurriculumMappingEvidenceIssue {
  const CurriculumMappingEvidenceIssue({
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

class CurriculumMappingEvidenceValidationResult {
  const CurriculumMappingEvidenceValidationResult(this.issues);

  final List<CurriculumMappingEvidenceIssue> issues;

  bool get isValid => issues.isEmpty;
}

class CurriculumMappingEvidenceValidator {
  static const int schemaVersion = 1;

  const CurriculumMappingEvidenceValidator();

  CurriculumMappingEvidenceValidationResult validateMap(
    Map<String, dynamic> evidence,
  ) {
    final issues = <CurriculumMappingEvidenceIssue>[];

    _exactKeys(
      evidence,
      const {
        'schemaVersion',
        'evidenceId',
        'microFactId',
        'contentVersion',
        'blueprintVersion',
        'navigationRegistryVersion',
        'mapping',
        'review',
      },
      r'$evidence',
      issues,
    );

    if (evidence['schemaVersion'] != schemaVersion) {
      _add(
        issues,
        'ML6_EVIDENCE_SCHEMA_VERSION',
        r'$evidence.schemaVersion',
        'Curriculum mapping evidence schemaVersion must be 1.',
      );
    }

    _patternString(
      evidence['evidenceId'],
      RegExp(r'^mfme_[a-z0-9][a-z0-9_-]{5,63}$'),
      r'$evidence.evidenceId',
      'ML6_EVIDENCE_ID',
      issues,
    );

    _patternString(
      evidence['microFactId'],
      RegExp(r'^mf_[a-z0-9][a-z0-9_-]{5,63}$'),
      r'$evidence.microFactId',
      'ML6_EVIDENCE_FACT_ID',
      issues,
    );

    final contentVersion = evidence['contentVersion'];
    if (contentVersion is! int || contentVersion < 1) {
      _add(
        issues,
        'ML6_EVIDENCE_CONTENT_VERSION',
        r'$evidence.contentVersion',
        'contentVersion must be an integer greater than zero.',
      );
    }

    if (evidence['blueprintVersion'] !=
        CanonicalCurriculumPolicyValidator.requiredBlueprintVersion) {
      _add(
        issues,
        'ML6_EVIDENCE_BLUEPRINT_VERSION',
        r'$evidence.blueprintVersion',
        'Evidence must bind to the frozen canonical blueprint version.',
      );
    }

    if (evidence['navigationRegistryVersion'] !=
        CanonicalCurriculumPolicyValidator.requiredNavigationRegistryVersion) {
      _add(
        issues,
        'ML6_EVIDENCE_REGISTRY_VERSION',
        r'$evidence.navigationRegistryVersion',
        'Evidence must bind to the frozen navigation registry version.',
      );
    }

    final mapping = _requiredMap(
      evidence['mapping'],
      r'$evidence.mapping',
      'ML6_EVIDENCE_MAPPING',
      issues,
    );
    if (mapping != null) {
      _validateMapping(mapping, issues);
    }

    final review = _requiredMap(
      evidence['review'],
      r'$evidence.review',
      'ML6_EVIDENCE_REVIEW',
      issues,
    );
    if (review != null) {
      _validateReview(review, issues);
    }

    return CurriculumMappingEvidenceValidationResult(List.unmodifiable(issues));
  }

  void _validateMapping(
    Map<String, dynamic> mapping,
    List<CurriculumMappingEvidenceIssue> issues,
  ) {
    _exactKeys(
      mapping,
      const {
        'scope',
        'domainId',
        'competencyId',
        'topicId',
        'subtopicId',
        'mappingKey',
      },
      r'$evidence.mapping',
      issues,
    );

    if (mapping['scope'] != 'mapped') {
      _add(
        issues,
        'ML6_EVIDENCE_SCOPE',
        r'$evidence.mapping.scope',
        'Curriculum mapping evidence may only describe mapped facts.',
      );
    }

    _patternString(
      mapping['domainId'],
      RegExp(r'^d0[1-7]$'),
      r'$evidence.mapping.domainId',
      'ML6_EVIDENCE_DOMAIN_ID',
      issues,
    );
    _patternString(
      mapping['competencyId'],
      RegExp(r'^d0[1-7]_c[0-9]{2}$'),
      r'$evidence.mapping.competencyId',
      'ML6_EVIDENCE_COMPETENCY_ID',
      issues,
    );
    _nullablePatternString(
      mapping['topicId'],
      RegExp(r'^d0[1-7]_c[0-9]{2}_t[0-9]{2}$'),
      r'$evidence.mapping.topicId',
      'ML6_EVIDENCE_TOPIC_ID',
      issues,
    );
    _nullablePatternString(
      mapping['subtopicId'],
      RegExp(r'^d0[1-7]_c[0-9]{2}_t[0-9]{2}_s[0-9]{2}$'),
      r'$evidence.mapping.subtopicId',
      'ML6_EVIDENCE_SUBTOPIC_ID',
      issues,
    );

    if (mapping['subtopicId'] != null && mapping['topicId'] == null) {
      _add(
        issues,
        'ML6_EVIDENCE_SUBTOPIC_REQUIRES_TOPIC',
        r'$evidence.mapping.subtopicId',
        'Subtopic mapping requires a topic mapping.',
      );
    }

    final expectedKey = mappingKey(
      domainId: mapping['domainId'] is String
          ? mapping['domainId'] as String
          : '',
      competencyId: mapping['competencyId'] is String
          ? mapping['competencyId'] as String
          : '',
      topicId: mapping['topicId'] as String?,
      subtopicId: mapping['subtopicId'] as String?,
    );

    if (mapping['mappingKey'] != expectedKey) {
      _add(
        issues,
        'ML6_EVIDENCE_MAPPING_KEY',
        r'$evidence.mapping.mappingKey',
        'mappingKey must exactly fingerprint the curriculum mapping.',
      );
    }
  }

  void _validateReview(
    Map<String, dynamic> review,
    List<CurriculumMappingEvidenceIssue> issues,
  ) {
    _exactKeys(
      review,
      const {
        'status',
        'reviewerRole',
        'humanReviewed',
        'conceptAlignmentConfirmed',
        'placementRationale',
        'reviewedAt',
        'nextReviewDueAt',
      },
      r'$evidence.review',
      issues,
    );

    if (!CanonicalCurriculumPolicyValidator.reviewStatuses.contains(
      review['status'],
    )) {
      _add(
        issues,
        'ML6_EVIDENCE_REVIEW_STATUS',
        r'$evidence.review.status',
        'Unknown mapping review status.',
      );
    }

    if (!CanonicalCurriculumPolicyValidator.reviewerRoles.contains(
      review['reviewerRole'],
    )) {
      _add(
        issues,
        'ML6_EVIDENCE_REVIEWER_ROLE',
        r'$evidence.review.reviewerRole',
        'Unknown curriculum reviewer role.',
      );
    }

    if (review['humanReviewed'] is! bool) {
      _add(
        issues,
        'ML6_EVIDENCE_HUMAN_REVIEW',
        r'$evidence.review.humanReviewed',
        'humanReviewed must be boolean.',
      );
    }

    if (review['conceptAlignmentConfirmed'] is! bool) {
      _add(
        issues,
        'ML6_EVIDENCE_ALIGNMENT_FLAG',
        r'$evidence.review.conceptAlignmentConfirmed',
        'conceptAlignmentConfirmed must be boolean.',
      );
    }

    final rationale = review['placementRationale'];
    if (rationale is! String ||
        rationale.trim().isEmpty ||
        rationale.length > 500) {
      _add(
        issues,
        'ML6_EVIDENCE_PLACEMENT_RATIONALE',
        r'$evidence.review.placementRationale',
        'placementRationale must be a non-empty string up to 500 characters.',
      );
    }

    for (final key in const {'reviewedAt', 'nextReviewDueAt'}) {
      final value = review[key];
      if (value != null && !_isStrictDate(value)) {
        _add(
          issues,
          'ML6_EVIDENCE_REVIEW_DATE',
          r'$evidence.review.$key',
          '$key must be null or a valid YYYY-MM-DD date.',
        );
      }
    }

    final reviewedAt = _parseStrictDate(review['reviewedAt']);
    final dueAt = _parseStrictDate(review['nextReviewDueAt']);

    if (review['status'] == 'pass' &&
        (review['humanReviewed'] != true ||
            review['conceptAlignmentConfirmed'] != true ||
            reviewedAt == null ||
            dueAt == null)) {
      _add(
        issues,
        'ML6_EVIDENCE_PASS_REQUIREMENTS',
        r'$evidence.review',
        'Passing mapping evidence requires human review, confirmed concept alignment, and review dates.',
      );
    }

    if (reviewedAt != null && dueAt != null && dueAt.isBefore(reviewedAt)) {
      _add(
        issues,
        'ML6_EVIDENCE_REVIEW_DATE_ORDER',
        r'$evidence.review.nextReviewDueAt',
        'Mapping review due date cannot precede the review date.',
      );
    }
  }

  static String mappingKey({
    required String domainId,
    required String competencyId,
    String? topicId,
    String? subtopicId,
  }) {
    return [
      domainId,
      competencyId,
      topicId ?? '-',
      subtopicId ?? '-',
    ].join('|');
  }

  static Map<String, dynamic>? _requiredMap(
    dynamic value,
    String path,
    String code,
    List<CurriculumMappingEvidenceIssue> issues,
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
    List<CurriculumMappingEvidenceIssue> issues,
  ) {
    if (value is! String || !pattern.hasMatch(value)) {
      _add(issues, code, path, 'Value does not match the canonical pattern.');
    }
  }

  static void _nullablePatternString(
    dynamic value,
    RegExp pattern,
    String path,
    String code,
    List<CurriculumMappingEvidenceIssue> issues,
  ) {
    if (value == null) return;
    _patternString(value, pattern, path, code, issues);
  }

  static DateTime? _parseStrictDate(dynamic value) {
    if (value is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      return null;
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return null;
    final normalized =
        '\${parsed.year.toString().padLeft(4, '0')}-'
        '\${parsed.month.toString().padLeft(2, '0')}-'
        '\${parsed.day.toString().padLeft(2, '0')}';
    return normalized == value ? parsed : null;
  }

  static bool _isStrictDate(dynamic value) => _parseStrictDate(value) != null;

  static void _exactKeys(
    Map<String, dynamic> map,
    Set<String> expected,
    String path,
    List<CurriculumMappingEvidenceIssue> issues,
  ) {
    final actual = map.keys.toSet();
    for (final missing in expected.difference(actual)) {
      _add(
        issues,
        'ML6_EVIDENCE_REQUIRED_FIELD',
        '$path.$missing',
        'Required evidence field is missing.',
      );
    }
    for (final extra in actual.difference(expected)) {
      _add(
        issues,
        'ML6_EVIDENCE_UNKNOWN_FIELD',
        '$path.$extra',
        'Unknown evidence field is not allowed.',
      );
    }
  }

  static void _add(
    List<CurriculumMappingEvidenceIssue> issues,
    String code,
    String path,
    String message,
  ) {
    issues.add(
      CurriculumMappingEvidenceIssue(code: code, path: path, message: message),
    );
  }
}
