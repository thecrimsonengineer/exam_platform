import 'dart:convert';

class MicroFactSchemaIssue {
  const MicroFactSchemaIssue({
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

class MicroFactSchemaValidationResult {
  const MicroFactSchemaValidationResult(this.issues);

  final List<MicroFactSchemaIssue> issues;

  bool get isValid => issues.isEmpty;
}

class MicroFactSchemaValidator {
  static const int schemaVersion = 1;

  static const Set<String> statuses = {
    'draft',
    'review',
    'validated',
    'published',
    'review_due',
    'superseded',
    'withdrawn',
    'rejected',
  };

  static const Set<String> categories = {
    'safety_insight',
    'csp_tip',
    'learning_tip',
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

  static const Set<String> sourceClasses = {
    'federal_regulation',
    'regulatory_interpretation',
    'enforcement_or_compliance_guidance',
    'government_recommendation',
    'research_or_prevention_guidance',
    'consensus_standard',
    'international_standard',
    'professional_guideline',
    'professional_framework',
    'environmental_regulation',
    'transportation_regulation',
    'emergency_management_framework',
    'process_safety_framework',
    'loss_prevention_guidance',
    'testing_or_certification_standard',
  };

  static const Set<String> legalStatuses = {
    'binding_requirement',
    'regulatory_interpretation',
    'nonbinding_guidance',
    'recommendation',
    'consensus_standard',
    'international_standard',
    'professional_guideline',
    'professional_framework',
    'research_finding',
    'certification_or_testing',
    'not_applicable',
  };

  static const Set<String> reviewStatuses = {'pending', 'pass', 'fail'};

  static const Set<String> rightsTreatments = {
    'original_paraphrase',
    'brief_summary',
    'minimal_quote',
    'licensed_excerpt',
  };

  static const Set<String> assessmentSensitivities = {
    'none',
    'low',
    'medium',
    'high',
    'block_during_linked_assessment',
  };

  static const Set<String> simplificationRisks = {'low', 'medium', 'high'};

  static const Set<String> curriculumScopes = {'mapped', 'general'};

  static const Set<String> rootKeys = {
    'schemaVersion',
    'microFactId',
    'contentVersion',
    'status',
    'category',
    'display',
    'curriculum',
    'provenance',
    'claim',
    'assessment',
    'review',
    'runtime',
    'supersession',
    'tags',
  };

  MicroFactSchemaValidationResult validateJson(String rawJson) {
    dynamic decoded;
    try {
      decoded = jsonDecode(rawJson);
    } on FormatException catch (error) {
      return MicroFactSchemaValidationResult([
        MicroFactSchemaIssue(
          code: 'ML2_JSON_INVALID',
          path: r'$',
          message: error.message,
        ),
      ]);
    }

    if (decoded is! Map<String, dynamic>) {
      return const MicroFactSchemaValidationResult([
        MicroFactSchemaIssue(
          code: 'ML2_ROOT_NOT_OBJECT',
          path: r'$',
          message: 'MicroFact root must be a JSON object.',
        ),
      ]);
    }

    return validateMap(decoded);
  }

  MicroFactSchemaValidationResult validateMap(Map<String, dynamic> root) {
    final issues = <MicroFactSchemaIssue>[];

    _exactKeys(root, rootKeys, r'$', issues);

    if (root['schemaVersion'] != schemaVersion) {
      _add(
        issues,
        'ML2_SCHEMA_VERSION',
        r'$.schemaVersion',
        'schemaVersion must be 1.',
      );
    }

    _validateId(root['microFactId'], r'$.microFactId', issues);

    final contentVersion = root['contentVersion'];
    if (contentVersion is! int || contentVersion < 1) {
      _add(
        issues,
        'ML2_CONTENT_VERSION',
        r'$.contentVersion',
        'contentVersion must be an integer greater than zero.',
      );
    }

    final status = root['status'];
    _enumValue(status, statuses, r'$.status', 'ML2_STATUS', issues);

    _enumValue(
      root['category'],
      categories,
      r'$.category',
      'ML2_CATEGORY',
      issues,
    );

    final display = _requiredMap(root['display'], r'$.display', issues);
    if (display != null) {
      _validateDisplay(display, issues);
    }

    final curriculum = _requiredMap(
      root['curriculum'],
      r'$.curriculum',
      issues,
    );
    if (curriculum != null) {
      _validateCurriculum(curriculum, issues);
    }

    final provenance = _requiredMap(
      root['provenance'],
      r'$.provenance',
      issues,
    );
    if (provenance != null) {
      _validateProvenance(provenance, issues);
    }

    final claim = _requiredMap(root['claim'], r'$.claim', issues);
    if (claim != null) {
      _validateClaim(claim, issues);
    }

    final assessment = _requiredMap(
      root['assessment'],
      r'$.assessment',
      issues,
    );
    if (assessment != null) {
      _validateAssessment(assessment, issues);
    }

    final review = _requiredMap(root['review'], r'$.review', issues);
    if (review != null) {
      _validateReview(review, issues);
    }

    final runtime = _requiredMap(root['runtime'], r'$.runtime', issues);
    if (runtime != null) {
      _validateRuntime(runtime, issues);
    }

    final supersession = _requiredMap(
      root['supersession'],
      r'$.supersession',
      issues,
    );
    if (supersession != null) {
      _validateSupersession(supersession, issues);
    }

    _validateStringList(
      root['tags'],
      r'$.tags',
      issues,
      code: 'ML2_TAGS',
      minItems: 2,
      maxItems: 20,
      pattern: RegExp(r'^[a-z0-9][a-z0-9_-]{1,63}$'),
    );

    _validateCrossFieldRules(
      root: root,
      status: status is String ? status : null,
      curriculum: curriculum,
      provenance: provenance,
      assessment: assessment,
      review: review,
      runtime: runtime,
      supersession: supersession,
      issues: issues,
    );

    return MicroFactSchemaValidationResult(List.unmodifiable(issues));
  }

  void _validateDisplay(
    Map<String, dynamic> display,
    List<MicroFactSchemaIssue> issues,
  ) {
    const keys = {'displayText', 'shortVariant', 'estimatedReadSeconds'};
    _exactKeys(display, keys, r'$.display', issues);

    _requiredString(
      display['displayText'],
      r'$.display.displayText',
      issues,
      code: 'ML2_DISPLAY_TEXT',
      maxLength: 500,
    );

    _nullableString(
      display['shortVariant'],
      r'$.display.shortVariant',
      issues,
      code: 'ML2_SHORT_VARIANT',
      maxLength: 180,
    );

    final readSeconds = display['estimatedReadSeconds'];
    if (readSeconds is! int || readSeconds < 1 || readSeconds > 30) {
      _add(
        issues,
        'ML2_READ_SECONDS',
        r'$.display.estimatedReadSeconds',
        'estimatedReadSeconds must be an integer from 1 to 30.',
      );
    }
  }

  void _validateCurriculum(
    Map<String, dynamic> curriculum,
    List<MicroFactSchemaIssue> issues,
  ) {
    const keys = {
      'scope',
      'domainId',
      'competencyId',
      'topicId',
      'subtopicId',
      'conceptIds',
    };
    _exactKeys(curriculum, keys, r'$.curriculum', issues);

    _enumValue(
      curriculum['scope'],
      curriculumScopes,
      r'$.curriculum.scope',
      'ML2_CURRICULUM_SCOPE',
      issues,
    );

    _nullablePatternString(
      curriculum['domainId'],
      r'$.curriculum.domainId',
      RegExp(r'^d0[1-7]$'),
      'ML2_DOMAIN_ID',
      issues,
    );
    _nullablePatternString(
      curriculum['competencyId'],
      r'$.curriculum.competencyId',
      RegExp(r'^d0[1-7]_c[0-9]{2}$'),
      'ML2_COMPETENCY_ID',
      issues,
    );
    _nullablePatternString(
      curriculum['topicId'],
      r'$.curriculum.topicId',
      RegExp(r'^d0[1-7]_c[0-9]{2}_t[0-9]{2}$'),
      'ML2_TOPIC_ID',
      issues,
    );
    _nullablePatternString(
      curriculum['subtopicId'],
      r'$.curriculum.subtopicId',
      RegExp(r'^d0[1-7]_c[0-9]{2}_t[0-9]{2}_s[0-9]{2}$'),
      'ML2_SUBTOPIC_ID',
      issues,
    );

    _validateStringList(
      curriculum['conceptIds'],
      r'$.curriculum.conceptIds',
      issues,
      code: 'ML2_CONCEPT_IDS',
      minItems: 1,
      maxItems: 20,
      pattern: RegExp(r'^[a-z0-9][a-z0-9_:-]{1,63}$'),
    );
  }

  void _validateProvenance(
    Map<String, dynamic> provenance,
    List<MicroFactSchemaIssue> issues,
  ) {
    const keys = {
      'sourceRegistryId',
      'sourceClass',
      'sourceTitle',
      'officialUrl',
      'sourceLocator',
      'editionOrRevision',
      'sourceSection',
      'sourcePage',
      'sourcePublishedAt',
      'sourceVerifiedAt',
      'rightsTreatment',
    };
    _exactKeys(provenance, keys, r'$.provenance', issues);

    _patternString(
      provenance['sourceRegistryId'],
      r'$.provenance.sourceRegistryId',
      RegExp(r'^SRC-[0-9]{2}$'),
      'ML2_SOURCE_REGISTRY_ID',
      issues,
    );

    _enumValue(
      provenance['sourceClass'],
      sourceClasses,
      r'$.provenance.sourceClass',
      'ML2_SOURCE_CLASS',
      issues,
    );

    _requiredString(
      provenance['sourceTitle'],
      r'$.provenance.sourceTitle',
      issues,
      code: 'ML2_SOURCE_TITLE',
      maxLength: 250,
    );

    final officialUrl = provenance['officialUrl'];
    if (officialUrl is! String ||
        officialUrl.trim().isEmpty ||
        officialUrl.length > 1000) {
      _add(
        issues,
        'ML2_OFFICIAL_URL',
        r'$.provenance.officialUrl',
        'officialUrl must be a non-empty HTTPS URL up to 1000 characters.',
      );
    } else {
      final uri = Uri.tryParse(officialUrl);
      if (uri == null ||
          uri.scheme != 'https' ||
          uri.host.isEmpty ||
          uri.userInfo.isNotEmpty) {
        _add(
          issues,
          'ML2_OFFICIAL_URL',
          r'$.provenance.officialUrl',
          'officialUrl must be an absolute HTTPS URL without embedded credentials.',
        );
      }
    }

    _requiredString(
      provenance['sourceLocator'],
      r'$.provenance.sourceLocator',
      issues,
      code: 'ML2_SOURCE_LOCATOR',
      maxLength: 300,
    );

    _nullableString(
      provenance['editionOrRevision'],
      r'$.provenance.editionOrRevision',
      issues,
      code: 'ML2_EDITION_REVISION',
      maxLength: 100,
    );
    _nullableString(
      provenance['sourceSection'],
      r'$.provenance.sourceSection',
      issues,
      code: 'ML2_SOURCE_SECTION',
      maxLength: 200,
    );
    _nullableString(
      provenance['sourcePage'],
      r'$.provenance.sourcePage',
      issues,
      code: 'ML2_SOURCE_PAGE',
      maxLength: 50,
    );

    _nullableDate(
      provenance['sourcePublishedAt'],
      r'$.provenance.sourcePublishedAt',
      'ML2_SOURCE_PUBLISHED_DATE',
      issues,
    );
    _requiredDate(
      provenance['sourceVerifiedAt'],
      r'$.provenance.sourceVerifiedAt',
      'ML2_SOURCE_VERIFIED_DATE',
      issues,
    );

    _enumValue(
      provenance['rightsTreatment'],
      rightsTreatments,
      r'$.provenance.rightsTreatment',
      'ML2_RIGHTS_TREATMENT',
      issues,
    );
  }

  void _validateClaim(
    Map<String, dynamic> claim,
    List<MicroFactSchemaIssue> issues,
  ) {
    const keys = {
      'legalStatus',
      'jurisdiction',
      'numericalClaim',
      'safetyCritical',
      'simplificationRisk',
    };
    _exactKeys(claim, keys, r'$.claim', issues);

    _enumValue(
      claim['legalStatus'],
      legalStatuses,
      r'$.claim.legalStatus',
      'ML2_LEGAL_STATUS',
      issues,
    );

    _nullableString(
      claim['jurisdiction'],
      r'$.claim.jurisdiction',
      issues,
      code: 'ML2_JURISDICTION',
      maxLength: 120,
    );

    _requiredBool(
      claim['numericalClaim'],
      r'$.claim.numericalClaim',
      'ML2_NUMERICAL_FLAG',
      issues,
    );
    _requiredBool(
      claim['safetyCritical'],
      r'$.claim.safetyCritical',
      'ML2_SAFETY_CRITICAL_FLAG',
      issues,
    );

    _enumValue(
      claim['simplificationRisk'],
      simplificationRisks,
      r'$.claim.simplificationRisk',
      'ML2_SIMPLIFICATION_RISK',
      issues,
    );
  }

  void _validateAssessment(
    Map<String, dynamic> assessment,
    List<MicroFactSchemaIssue> issues,
  ) {
    const keys = {'sensitivity', 'linkedQuestionConcepts'};
    _exactKeys(assessment, keys, r'$.assessment', issues);

    _enumValue(
      assessment['sensitivity'],
      assessmentSensitivities,
      r'$.assessment.sensitivity',
      'ML2_ASSESSMENT_SENSITIVITY',
      issues,
    );

    _validateStringList(
      assessment['linkedQuestionConcepts'],
      r'$.assessment.linkedQuestionConcepts',
      issues,
      code: 'ML2_LINKED_QUESTION_CONCEPTS',
      minItems: 0,
      maxItems: 30,
      pattern: RegExp(r'^[a-z0-9][a-z0-9_:-]{1,63}$'),
    );
  }

  void _validateReview(
    Map<String, dynamic> review,
    List<MicroFactSchemaIssue> issues,
  ) {
    const keys = {
      'technicalStatus',
      'sourceStatus',
      'pedagogyStatus',
      'copyrightStatus',
      'uiStatus',
      'humanTechnicalStatus',
      'reviewedAt',
      'nextReviewDueAt',
    };
    _exactKeys(review, keys, r'$.review', issues);

    for (final field in [
      'technicalStatus',
      'sourceStatus',
      'pedagogyStatus',
      'copyrightStatus',
      'uiStatus',
      'humanTechnicalStatus',
    ]) {
      _enumValue(
        review[field],
        reviewStatuses,
        r'$.review.' + field,
        'ML2_REVIEW_STATUS',
        issues,
      );
    }

    _nullableDate(
      review['reviewedAt'],
      r'$.review.reviewedAt',
      'ML2_REVIEWED_DATE',
      issues,
    );
    _nullableDate(
      review['nextReviewDueAt'],
      r'$.review.nextReviewDueAt',
      'ML2_REVIEW_DUE_DATE',
      issues,
    );
  }

  void _validateRuntime(
    Map<String, dynamic> runtime,
    List<MicroFactSchemaIssue> issues,
  ) {
    const keys = {'startupEligible'};
    _exactKeys(runtime, keys, r'$.runtime', issues);

    _requiredBool(
      runtime['startupEligible'],
      r'$.runtime.startupEligible',
      'ML2_STARTUP_ELIGIBLE',
      issues,
    );
  }

  void _validateSupersession(
    Map<String, dynamic> supersession,
    List<MicroFactSchemaIssue> issues,
  ) {
    const keys = {'supersedesMicroFactId', 'supersededByMicroFactId'};
    _exactKeys(supersession, keys, r'$.supersession', issues);

    _nullableId(
      supersession['supersedesMicroFactId'],
      r'$.supersession.supersedesMicroFactId',
      issues,
    );
    _nullableId(
      supersession['supersededByMicroFactId'],
      r'$.supersession.supersededByMicroFactId',
      issues,
    );
  }

  void _validateCrossFieldRules({
    required Map<String, dynamic> root,
    required String? status,
    required Map<String, dynamic>? curriculum,
    required Map<String, dynamic>? provenance,
    required Map<String, dynamic>? assessment,
    required Map<String, dynamic>? review,
    required Map<String, dynamic>? runtime,
    required Map<String, dynamic>? supersession,
    required List<MicroFactSchemaIssue> issues,
  }) {
    if (curriculum != null) {
      final scope = curriculum['scope'];
      final domainId = curriculum['domainId'];
      final competencyId = curriculum['competencyId'];
      final topicId = curriculum['topicId'];
      final subtopicId = curriculum['subtopicId'];

      if (scope == 'mapped') {
        if (domainId is! String || domainId.isEmpty) {
          _add(
            issues,
            'ML2_MAPPED_DOMAIN_REQUIRED',
            r'$.curriculum.domainId',
            'Mapped facts require domainId.',
          );
        }
        if (competencyId is! String || competencyId.isEmpty) {
          _add(
            issues,
            'ML2_MAPPED_COMPETENCY_REQUIRED',
            r'$.curriculum.competencyId',
            'Mapped facts require competencyId.',
          );
        }

        if (domainId is String &&
            competencyId is String &&
            !competencyId.startsWith(domainId + '_c')) {
          _add(
            issues,
            'ML2_COMPETENCY_DOMAIN_MISMATCH',
            r'$.curriculum.competencyId',
            'competencyId must belong to domainId.',
          );
        }

        if (topicId is String &&
            competencyId is String &&
            !topicId.startsWith(competencyId + '_t')) {
          _add(
            issues,
            'ML2_TOPIC_COMPETENCY_MISMATCH',
            r'$.curriculum.topicId',
            'topicId must belong to competencyId.',
          );
        }

        if (subtopicId is String) {
          if (topicId is! String || topicId.isEmpty) {
            _add(
              issues,
              'ML2_SUBTOPIC_REQUIRES_TOPIC',
              r'$.curriculum.subtopicId',
              'subtopicId requires topicId.',
            );
          } else if (!subtopicId.startsWith(topicId + '_s')) {
            _add(
              issues,
              'ML2_SUBTOPIC_TOPIC_MISMATCH',
              r'$.curriculum.subtopicId',
              'subtopicId must belong to topicId.',
            );
          }
        }
      }

      if (scope == 'general') {
        for (final field in [
          'domainId',
          'competencyId',
          'topicId',
          'subtopicId',
        ]) {
          if (curriculum[field] != null) {
            _add(
              issues,
              'ML2_GENERAL_MAPPING_NOT_NULL',
              r'$.curriculum.' + field,
              'General-scope facts must not carry hierarchy placement.',
            );
          }
        }
      }
    }

    if (assessment != null) {
      final sensitivity = assessment['sensitivity'];
      final linked = assessment['linkedQuestionConcepts'];
      final linkedCount = linked is List ? linked.length : 0;

      if (sensitivity == 'none' && linkedCount != 0) {
        _add(
          issues,
          'ML2_ASSESSMENT_NONE_WITH_LINKS',
          r'$.assessment.linkedQuestionConcepts',
          'Assessment sensitivity none requires no linked question concepts.',
        );
      }
      if (sensitivity is String && sensitivity != 'none' && linkedCount == 0) {
        _add(
          issues,
          'ML2_ASSESSMENT_LINK_REQUIRED',
          r'$.assessment.linkedQuestionConcepts',
          'Non-none assessment sensitivity requires linked question concepts.',
        );
      }
    }

    if (runtime != null &&
        runtime['startupEligible'] == true &&
        status != 'published') {
      _add(
        issues,
        'ML2_STARTUP_REQUIRES_PUBLISHED',
        r'$.runtime.startupEligible',
        'Only published facts may be startup eligible.',
      );
    }

    if (status == 'published' && review != null) {
      for (final field in [
        'technicalStatus',
        'sourceStatus',
        'pedagogyStatus',
        'copyrightStatus',
        'uiStatus',
        'humanTechnicalStatus',
      ]) {
        if (review[field] != 'pass') {
          _add(
            issues,
            'ML2_PUBLISHED_REVIEW_NOT_PASS',
            r'$.review.' + field,
            'Published facts require every review status to pass.',
          );
        }
      }

      if (review['reviewedAt'] == null) {
        _add(
          issues,
          'ML2_PUBLISHED_REVIEW_DATE',
          r'$.review.reviewedAt',
          'Published facts require reviewedAt.',
        );
      }
      if (review['nextReviewDueAt'] == null) {
        _add(
          issues,
          'ML2_PUBLISHED_REVIEW_DUE',
          r'$.review.nextReviewDueAt',
          'Published facts require nextReviewDueAt.',
        );
      }
    }

    if (review != null) {
      final reviewedAt = _dateOrNull(review['reviewedAt']);
      final nextReviewDueAt = _dateOrNull(review['nextReviewDueAt']);
      if (reviewedAt != null &&
          nextReviewDueAt != null &&
          nextReviewDueAt.isBefore(reviewedAt)) {
        _add(
          issues,
          'ML2_REVIEW_DATE_ORDER',
          r'$.review.nextReviewDueAt',
          'nextReviewDueAt cannot be before reviewedAt.',
        );
      }

      final sourceVerifiedAt = provenance == null
          ? null
          : _dateOrNull(provenance['sourceVerifiedAt']);
      if (status == 'published' &&
          reviewedAt != null &&
          sourceVerifiedAt != null &&
          reviewedAt.isBefore(sourceVerifiedAt)) {
        _add(
          issues,
          'ML2_REVIEW_BEFORE_SOURCE_VERIFICATION',
          r'$.review.reviewedAt',
          'Published fact review cannot predate source verification.',
        );
      }
    }

    if (supersession != null) {
      final currentId = root['microFactId'];
      final supersedes = supersession['supersedesMicroFactId'];
      final supersededBy = supersession['supersededByMicroFactId'];

      if (currentId is String &&
          (supersedes == currentId || supersededBy == currentId)) {
        _add(
          issues,
          'ML2_SUPERSESSION_SELF_REFERENCE',
          r'$.supersession',
          'A MicroFact cannot supersede or be superseded by itself.',
        );
      }

      if (status == 'superseded' && supersededBy == null) {
        _add(
          issues,
          'ML2_SUPERSEDED_REPLACEMENT_REQUIRED',
          r'$.supersession.supersededByMicroFactId',
          'Superseded facts require supersededByMicroFactId.',
        );
      }

      if (status != 'superseded' && supersededBy != null) {
        _add(
          issues,
          'ML2_SUPERSEDED_BY_STATUS_MISMATCH',
          r'$.supersession.supersededByMicroFactId',
          'supersededByMicroFactId is only valid when status is superseded.',
        );
      }
    }
  }

  static Map<String, dynamic>? _requiredMap(
    dynamic value,
    String path,
    List<MicroFactSchemaIssue> issues,
  ) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    _add(issues, 'ML2_OBJECT_REQUIRED', path, 'A JSON object is required.');
    return null;
  }

  static void _exactKeys(
    Map<String, dynamic> map,
    Set<String> expected,
    String path,
    List<MicroFactSchemaIssue> issues,
  ) {
    final actual = map.keys.toSet();

    for (final missing in expected.difference(actual)) {
      _add(
        issues,
        'ML2_REQUIRED_FIELD',
        path + '.' + missing,
        'Required field is missing.',
      );
    }

    for (final extra in actual.difference(expected)) {
      _add(
        issues,
        'ML2_UNKNOWN_FIELD',
        path + '.' + extra,
        'Unknown field is not allowed by MicroFact v1.',
      );
    }
  }

  static void _enumValue(
    dynamic value,
    Set<String> allowed,
    String path,
    String code,
    List<MicroFactSchemaIssue> issues,
  ) {
    if (value is! String || !allowed.contains(value)) {
      _add(
        issues,
        code,
        path,
        'Value is outside the frozen MicroFact v1 vocabulary.',
      );
    }
  }

  static void _requiredString(
    dynamic value,
    String path,
    List<MicroFactSchemaIssue> issues, {
    required String code,
    required int maxLength,
  }) {
    if (value is! String || value.trim().isEmpty || value.length > maxLength) {
      _add(
        issues,
        code,
        path,
        'A non-empty string up to ' +
            maxLength.toString() +
            ' characters is required.',
      );
    }
  }

  static void _nullableString(
    dynamic value,
    String path,
    List<MicroFactSchemaIssue> issues, {
    required String code,
    required int maxLength,
  }) {
    if (value == null) {
      return;
    }
    _requiredString(value, path, issues, code: code, maxLength: maxLength);
  }

  static void _patternString(
    dynamic value,
    String path,
    RegExp pattern,
    String code,
    List<MicroFactSchemaIssue> issues,
  ) {
    if (value is! String || !pattern.hasMatch(value)) {
      _add(issues, code, path, 'Value does not match the required format.');
    }
  }

  static void _nullablePatternString(
    dynamic value,
    String path,
    RegExp pattern,
    String code,
    List<MicroFactSchemaIssue> issues,
  ) {
    if (value == null) {
      return;
    }
    _patternString(value, path, pattern, code, issues);
  }

  static void _validateId(
    dynamic value,
    String path,
    List<MicroFactSchemaIssue> issues,
  ) {
    _patternString(
      value,
      path,
      RegExp(r'^mf_[a-z0-9][a-z0-9_-]{5,63}$'),
      'ML2_MICRO_FACT_ID',
      issues,
    );
  }

  static void _nullableId(
    dynamic value,
    String path,
    List<MicroFactSchemaIssue> issues,
  ) {
    if (value == null) {
      return;
    }
    _validateId(value, path, issues);
  }

  static void _requiredBool(
    dynamic value,
    String path,
    String code,
    List<MicroFactSchemaIssue> issues,
  ) {
    if (value is! bool) {
      _add(issues, code, path, 'A boolean value is required.');
    }
  }

  static void _validateStringList(
    dynamic value,
    String path,
    List<MicroFactSchemaIssue> issues, {
    required String code,
    required int minItems,
    required int maxItems,
    required RegExp pattern,
  }) {
    if (value is! List) {
      _add(issues, code, path, 'A list is required.');
      return;
    }

    if (value.length < minItems || value.length > maxItems) {
      _add(
        issues,
        code,
        path,
        'List must contain from ' +
            minItems.toString() +
            ' to ' +
            maxItems.toString() +
            ' items.',
      );
    }

    final seen = <String>{};
    for (var index = 0; index < value.length; index++) {
      final item = value[index];
      final itemPath = path + '[' + index.toString() + ']';

      if (item is! String || !pattern.hasMatch(item)) {
        _add(
          issues,
          code,
          itemPath,
          'List item does not match the required format.',
        );
        continue;
      }

      if (!seen.add(item)) {
        _add(issues, code, itemPath, 'Duplicate list item is not allowed.');
      }
    }
  }

  static void _requiredDate(
    dynamic value,
    String path,
    String code,
    List<MicroFactSchemaIssue> issues,
  ) {
    if (_dateOrNull(value) == null) {
      _add(issues, code, path, 'A valid YYYY-MM-DD date is required.');
    }
  }

  static void _nullableDate(
    dynamic value,
    String path,
    String code,
    List<MicroFactSchemaIssue> issues,
  ) {
    if (value == null) {
      return;
    }
    _requiredDate(value, path, code, issues);
  }

  static DateTime? _dateOrNull(dynamic value) {
    if (value is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      return null;
    }

    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return null;
    }

    final normalized =
        parsed.year.toString().padLeft(4, '0') +
        '-' +
        parsed.month.toString().padLeft(2, '0') +
        '-' +
        parsed.day.toString().padLeft(2, '0');

    return normalized == value ? parsed : null;
  }

  static void _add(
    List<MicroFactSchemaIssue> issues,
    String code,
    String path,
    String message,
  ) {
    issues.add(MicroFactSchemaIssue(code: code, path: path, message: message));
  }
}
