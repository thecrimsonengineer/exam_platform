import 'micro_fact_schema_validator.dart';
import 'rights_provenance_policy_validator.dart';

class RightsEvidenceIssue {
  const RightsEvidenceIssue({
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

class RightsEvidenceValidationResult {
  const RightsEvidenceValidationResult(this.issues);

  final List<RightsEvidenceIssue> issues;

  bool get isValid => issues.isEmpty;
}

class RightsEvidenceValidator {
  static const int schemaVersion = 1;

  static const Set<String> rootKeys = {
    'schemaVersion',
    'evidenceId',
    'microFactId',
    'contentVersion',
    'rightsTreatment',
    'sourceFingerprint',
    'transformation',
    'license',
    'review',
    'restrictedMaterial',
  };

  const RightsEvidenceValidator();

  RightsEvidenceValidationResult validateMap(Map<String, dynamic> evidence) {
    final issues = <RightsEvidenceIssue>[];

    _exactKeys(evidence, rootKeys, r'$evidence', issues);

    if (evidence['schemaVersion'] != schemaVersion) {
      _add(
        issues,
        'ML5_EVIDENCE_SCHEMA_VERSION',
        r'$evidence.schemaVersion',
        'Rights evidence schemaVersion must be 1.',
      );
    }

    _validatePattern(
      evidence['evidenceId'],
      RegExp(r'^mfre_[a-z0-9][a-z0-9_-]{5,63}$'),
      r'$evidence.evidenceId',
      'ML5_EVIDENCE_ID',
      issues,
    );
    _validatePattern(
      evidence['microFactId'],
      RegExp(r'^mf_[a-z0-9][a-z0-9_-]{5,63}$'),
      r'$evidence.microFactId',
      'ML5_EVIDENCE_FACT_ID',
      issues,
    );

    final contentVersion = evidence['contentVersion'];
    if (contentVersion is! int || contentVersion < 1) {
      _add(
        issues,
        'ML5_EVIDENCE_CONTENT_VERSION',
        r'$evidence.contentVersion',
        'contentVersion must be an integer greater than zero.',
      );
    }

    final rightsTreatment = evidence['rightsTreatment'];
    if (rightsTreatment is! String ||
        !MicroFactSchemaValidator.rightsTreatments.contains(rightsTreatment)) {
      _add(
        issues,
        'ML5_EVIDENCE_RIGHTS_TREATMENT',
        r'$evidence.rightsTreatment',
        'Unknown rights treatment.',
      );
    }

    final fingerprint = _requiredMap(
      evidence['sourceFingerprint'],
      r'$evidence.sourceFingerprint',
      'ML5_EVIDENCE_SOURCE_FINGERPRINT',
      issues,
    );
    if (fingerprint != null) {
      _validateFingerprint(fingerprint, issues);
    }

    final transformation = _requiredMap(
      evidence['transformation'],
      r'$evidence.transformation',
      'ML5_EVIDENCE_TRANSFORMATION',
      issues,
    );
    if (transformation != null) {
      _validateTransformation(transformation, issues);
    }

    final license = _requiredMap(
      evidence['license'],
      r'$evidence.license',
      'ML5_EVIDENCE_LICENSE',
      issues,
    );
    if (license != null) {
      _validateLicense(license, issues);
    }

    final review = _requiredMap(
      evidence['review'],
      r'$evidence.review',
      'ML5_EVIDENCE_REVIEW',
      issues,
    );
    if (review != null) {
      _validateReview(review, issues);
    }

    final restricted = _requiredMap(
      evidence['restrictedMaterial'],
      r'$evidence.restrictedMaterial',
      'ML5_EVIDENCE_RESTRICTED_MATERIAL',
      issues,
    );
    if (restricted != null) {
      _validateRestrictedMaterial(restricted, issues);
    }

    if (rightsTreatment is String &&
        transformation != null &&
        license != null) {
      _validateTreatmentConsistency(
        rightsTreatment,
        transformation,
        license,
        issues,
      );
    }

    return RightsEvidenceValidationResult(List.unmodifiable(issues));
  }

  void _validateFingerprint(
    Map<String, dynamic> fingerprint,
    List<RightsEvidenceIssue> issues,
  ) {
    const keys = {
      'sourceRegistryId',
      'officialUrl',
      'sourceLocator',
      'editionOrRevision',
    };
    _exactKeys(fingerprint, keys, r'$evidence.sourceFingerprint', issues);

    _validatePattern(
      fingerprint['sourceRegistryId'],
      RegExp(r'^SRC-[0-9]{2}$'),
      r'$evidence.sourceFingerprint.sourceRegistryId',
      'ML5_EVIDENCE_SOURCE_ID',
      issues,
    );

    final url = fingerprint['officialUrl'];
    final uri = url is String ? Uri.tryParse(url) : null;
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      _add(
        issues,
        'ML5_EVIDENCE_SOURCE_URL',
        r'$evidence.sourceFingerprint.officialUrl',
        'officialUrl must be an absolute credential-free HTTPS URL.',
      );
    }

    if (!_nonEmptyString(fingerprint['sourceLocator'])) {
      _add(
        issues,
        'ML5_EVIDENCE_SOURCE_LOCATOR',
        r'$evidence.sourceFingerprint.sourceLocator',
        'sourceLocator is required.',
      );
    }

    final edition = fingerprint['editionOrRevision'];
    if (edition != null && !_nonEmptyString(edition)) {
      _add(
        issues,
        'ML5_EVIDENCE_EDITION',
        r'$evidence.sourceFingerprint.editionOrRevision',
        'editionOrRevision must be null or a non-empty string.',
      );
    }
  }

  void _validateTransformation(
    Map<String, dynamic> transformation,
    List<RightsEvidenceIssue> issues,
  ) {
    const keys = {
      'sourceComparisonPerformed',
      'independentWordingConfirmed',
      'directQuoteUsed',
      'quoteWordCount',
      'quoteSegmentCount',
      'quoteTextSha256',
      'quoteNecessity',
      'longestVerbatimRunWords',
      'sourceStructureCopied',
      'tableCopied',
      'figureOrDiagramCopied',
      'checklistCopied',
      'questionOrAnswerCopied',
      'workedExampleCopied',
    };
    _exactKeys(transformation, keys, r'$evidence.transformation', issues);

    for (final key in const {
      'sourceComparisonPerformed',
      'independentWordingConfirmed',
      'directQuoteUsed',
      'sourceStructureCopied',
      'tableCopied',
      'figureOrDiagramCopied',
      'checklistCopied',
      'questionOrAnswerCopied',
      'workedExampleCopied',
    }) {
      if (transformation[key] is! bool) {
        _add(
          issues,
          'ML5_EVIDENCE_BOOLEAN',
          r'$evidence.transformation.$key',
          '$key must be boolean.',
        );
      }
    }

    for (final key in const {
      'quoteWordCount',
      'quoteSegmentCount',
      'longestVerbatimRunWords',
    }) {
      final value = transformation[key];
      if (value is! int || value < 0) {
        _add(
          issues,
          'ML5_EVIDENCE_NONNEGATIVE_INT',
          r'$evidence.transformation.$key',
          '$key must be a non-negative integer.',
        );
      }
    }

    final hash = transformation['quoteTextSha256'];
    if (hash != null &&
        (hash is! String || !RegExp(r'^[a-f0-9]{64}$').hasMatch(hash))) {
      _add(
        issues,
        'ML5_EVIDENCE_QUOTE_HASH',
        r'$evidence.transformation.quoteTextSha256',
        'quoteTextSha256 must be null or a lowercase SHA-256 digest.',
      );
    }

    final necessity = transformation['quoteNecessity'];
    if (necessity != null && !_nonEmptyString(necessity)) {
      _add(
        issues,
        'ML5_EVIDENCE_QUOTE_NECESSITY',
        r'$evidence.transformation.quoteNecessity',
        'quoteNecessity must be null or a non-empty string.',
      );
    }
  }

  void _validateLicense(
    Map<String, dynamic> license,
    List<RightsEvidenceIssue> issues,
  ) {
    const keys = {
      'required',
      'licenseId',
      'licensor',
      'scope',
      'effectiveDate',
      'expiresAt',
      'startupDisplayPermitted',
      'digitalRedistributionPermitted',
      'protectedStructureReusePermitted',
    };
    _exactKeys(license, keys, r'$evidence.license', issues);

    if (license['required'] is! bool) {
      _add(
        issues,
        'ML5_EVIDENCE_LICENSE_REQUIRED',
        r'$evidence.license.required',
        'license.required must be boolean.',
      );
    }

    for (final key in const {'licenseId', 'licensor', 'scope'}) {
      final value = license[key];
      if (value != null && !_nonEmptyString(value)) {
        _add(
          issues,
          'ML5_EVIDENCE_LICENSE_TEXT',
          r'$evidence.license.$key',
          '$key must be null or a non-empty string.',
        );
      }
    }

    for (final key in const {'effectiveDate', 'expiresAt'}) {
      final value = license[key];
      if (value != null && !_isStrictDate(value)) {
        _add(
          issues,
          'ML5_EVIDENCE_LICENSE_DATE',
          r'$evidence.license.$key',
          '$key must be null or a valid YYYY-MM-DD date.',
        );
      }
    }

    for (final key in const {
      'startupDisplayPermitted',
      'digitalRedistributionPermitted',
      'protectedStructureReusePermitted',
    }) {
      final value = license[key];
      if (value != null && value is! bool) {
        _add(
          issues,
          'ML5_EVIDENCE_LICENSE_BOOLEAN',
          r'$evidence.license.$key',
          '$key must be null or boolean.',
        );
      }
    }

    final effective = _parseStrictDate(license['effectiveDate']);
    final expires = _parseStrictDate(license['expiresAt']);
    if (effective != null && expires != null && expires.isBefore(effective)) {
      _add(
        issues,
        'ML5_EVIDENCE_LICENSE_DATE_ORDER',
        r'$evidence.license.expiresAt',
        'License expiry cannot precede the effective date.',
      );
    }
  }

  void _validateReview(
    Map<String, dynamic> review,
    List<RightsEvidenceIssue> issues,
  ) {
    const keys = {
      'status',
      'reviewerRole',
      'humanReviewed',
      'reviewedAt',
      'nextReviewDueAt',
    };
    _exactKeys(review, keys, r'$evidence.review', issues);

    if (!RightsProvenancePolicyValidator.reviewStatuses.contains(
      review['status'],
    )) {
      _add(
        issues,
        'ML5_EVIDENCE_REVIEW_STATUS',
        r'$evidence.review.status',
        'Unknown rights review status.',
      );
    }

    if (!RightsProvenancePolicyValidator.reviewerRoles.contains(
      review['reviewerRole'],
    )) {
      _add(
        issues,
        'ML5_EVIDENCE_REVIEWER_ROLE',
        r'$evidence.review.reviewerRole',
        'Unknown rights reviewer role.',
      );
    }

    if (review['humanReviewed'] is! bool) {
      _add(
        issues,
        'ML5_EVIDENCE_HUMAN_REVIEW',
        r'$evidence.review.humanReviewed',
        'humanReviewed must be boolean.',
      );
    }

    for (final key in const {'reviewedAt', 'nextReviewDueAt'}) {
      final value = review[key];
      if (value != null && !_isStrictDate(value)) {
        _add(
          issues,
          'ML5_EVIDENCE_REVIEW_DATE',
          r'$evidence.review.$key',
          '$key must be null or a valid YYYY-MM-DD date.',
        );
      }
    }

    final reviewedAt = _parseStrictDate(review['reviewedAt']);
    final dueAt = _parseStrictDate(review['nextReviewDueAt']);
    if (reviewedAt != null && dueAt != null && dueAt.isBefore(reviewedAt)) {
      _add(
        issues,
        'ML5_EVIDENCE_REVIEW_DATE_ORDER',
        r'$evidence.review.nextReviewDueAt',
        'Rights review due date cannot precede the review date.',
      );
    }

    if (review['status'] == 'pass') {
      if (review['humanReviewed'] != true ||
          reviewedAt == null ||
          dueAt == null) {
        _add(
          issues,
          'ML5_EVIDENCE_PASS_REQUIRES_HUMAN_REVIEW',
          r'$evidence.review',
          'Passing rights evidence requires human review and review dates.',
        );
      }
    }
  }

  void _validateRestrictedMaterial(
    Map<String, dynamic> restricted,
    List<RightsEvidenceIssue> issues,
  ) {
    const keys = {
      'rawSourceDocumentStored',
      'fullStandardStored',
      'fullBookChapterStored',
      'paywalledSnapshotStored',
      'copyrightedTableImageStored',
      'thirdPartyMaterialPresent',
      'thirdPartyMaterialCleared',
    };
    _exactKeys(restricted, keys, r'$evidence.restrictedMaterial', issues);

    for (final key in keys) {
      if (restricted[key] is! bool) {
        _add(
          issues,
          'ML5_EVIDENCE_RESTRICTED_BOOLEAN',
          r'$evidence.restrictedMaterial.$key',
          '$key must be boolean.',
        );
      }
    }

    for (final key in const {
      'rawSourceDocumentStored',
      'fullStandardStored',
      'fullBookChapterStored',
      'paywalledSnapshotStored',
      'copyrightedTableImageStored',
    }) {
      if (restricted[key] == true) {
        _add(
          issues,
          'ML5_EVIDENCE_PROTECTED_SOURCE_STORED',
          r'$evidence.restrictedMaterial.$key',
          'Protected source material must not be embedded in MicroFact evidence.',
        );
      }
    }

    if (restricted['thirdPartyMaterialPresent'] == true &&
        restricted['thirdPartyMaterialCleared'] != true) {
      _add(
        issues,
        'ML5_EVIDENCE_THIRD_PARTY_NOT_CLEARED',
        r'$evidence.restrictedMaterial.thirdPartyMaterialCleared',
        'Third-party material must be separately cleared.',
      );
    }
  }

  void _validateTreatmentConsistency(
    String treatment,
    Map<String, dynamic> transformation,
    Map<String, dynamic> license,
    List<RightsEvidenceIssue> issues,
  ) {
    final sourceCompared = transformation['sourceComparisonPerformed'] == true;
    if (!sourceCompared) {
      _add(
        issues,
        'ML5_EVIDENCE_SOURCE_COMPARISON_REQUIRED',
        r'$evidence.transformation.sourceComparisonPerformed',
        'Every ML-5 rights treatment requires source comparison.',
      );
    }

    if (treatment == 'original_paraphrase' || treatment == 'brief_summary') {
      if (transformation['directQuoteUsed'] != false ||
          transformation['quoteWordCount'] != 0 ||
          transformation['quoteSegmentCount'] != 0 ||
          transformation['quoteTextSha256'] != null ||
          transformation['quoteNecessity'] != null) {
        _add(
          issues,
          'ML5_EVIDENCE_PARAPHRASE_CONTAINS_QUOTE',
          r'$evidence.transformation',
          'Paraphrase/summary evidence cannot declare or retain direct quotation.',
        );
      }

      if (transformation['independentWordingConfirmed'] != true) {
        _add(
          issues,
          'ML5_EVIDENCE_INDEPENDENT_WORDING_REQUIRED',
          r'$evidence.transformation.independentWordingConfirmed',
          'Paraphrase/summary requires independent wording confirmation.',
        );
      }

      final longestRun = transformation['longestVerbatimRunWords'];
      if (longestRun is int && longestRun > 5) {
        _add(
          issues,
          'ML5_EVIDENCE_VERBATIM_RUN_TOO_LONG',
          r'$evidence.transformation.longestVerbatimRunWords',
          'Paraphrase/summary may not retain a verbatim run longer than five words.',
        );
      }

      _requireNoLicense(license, issues);
    } else if (treatment == 'minimal_quote') {
      if (transformation['directQuoteUsed'] != true) {
        _add(
          issues,
          'ML5_EVIDENCE_MINIMAL_QUOTE_MISSING',
          r'$evidence.transformation.directQuoteUsed',
          'minimal_quote requires a direct quote.',
        );
      }

      final wordCount = transformation['quoteWordCount'];
      if (wordCount is! int || wordCount < 1 || wordCount > 12) {
        _add(
          issues,
          'ML5_EVIDENCE_QUOTE_WORD_LIMIT',
          r'$evidence.transformation.quoteWordCount',
          'Minimal quote must contain 1 to 12 quoted words.',
        );
      }

      if (transformation['quoteSegmentCount'] != 1) {
        _add(
          issues,
          'ML5_EVIDENCE_QUOTE_SEGMENT_LIMIT',
          r'$evidence.transformation.quoteSegmentCount',
          'Minimal quote is limited to one quote segment.',
        );
      }

      final hash = transformation['quoteTextSha256'];
      if (hash is! String || !RegExp(r'^[a-f0-9]{64}$').hasMatch(hash)) {
        _add(
          issues,
          'ML5_EVIDENCE_QUOTE_HASH_REQUIRED',
          r'$evidence.transformation.quoteTextSha256',
          'Minimal quote requires a SHA-256 quote fingerprint.',
        );
      }

      if (!_nonEmptyString(transformation['quoteNecessity'])) {
        _add(
          issues,
          'ML5_EVIDENCE_QUOTE_NECESSITY_REQUIRED',
          r'$evidence.transformation.quoteNecessity',
          'Minimal quote requires a documented necessity.',
        );
      }

      _requireNoLicense(license, issues);
    } else if (treatment == 'licensed_excerpt') {
      if (transformation['directQuoteUsed'] != true) {
        _add(
          issues,
          'ML5_EVIDENCE_LICENSED_EXCERPT_QUOTE_REQUIRED',
          r'$evidence.transformation.directQuoteUsed',
          'licensed_excerpt must identify direct excerpt use.',
        );
      }

      if (license['required'] != true ||
          !_nonEmptyString(license['licenseId']) ||
          !_nonEmptyString(license['licensor']) ||
          !_nonEmptyString(license['scope']) ||
          _parseStrictDate(license['effectiveDate']) == null ||
          license['startupDisplayPermitted'] != true ||
          license['digitalRedistributionPermitted'] != true) {
        _add(
          issues,
          'ML5_EVIDENCE_LICENSE_INCOMPLETE',
          r'$evidence.license',
          'Licensed excerpt requires a complete license permitting startup display and digital redistribution.',
        );
      }
    }

    final protectedCopyUsed =
        transformation['sourceStructureCopied'] == true ||
        transformation['tableCopied'] == true ||
        transformation['figureOrDiagramCopied'] == true ||
        transformation['checklistCopied'] == true ||
        transformation['questionOrAnswerCopied'] == true ||
        transformation['workedExampleCopied'] == true;

    if (protectedCopyUsed &&
        !(treatment == 'licensed_excerpt' &&
            license['protectedStructureReusePermitted'] == true)) {
      _add(
        issues,
        'ML5_EVIDENCE_PROTECTED_STRUCTURE_NOT_LICENSED',
        r'$evidence.transformation',
        'Protected structure, table, figure, checklist, question or worked example requires explicit licensed reuse.',
      );
    }
  }

  void _requireNoLicense(
    Map<String, dynamic> license,
    List<RightsEvidenceIssue> issues,
  ) {
    if (license['required'] != false ||
        license['licenseId'] != null ||
        license['licensor'] != null ||
        license['scope'] != null ||
        license['effectiveDate'] != null ||
        license['expiresAt'] != null ||
        license['startupDisplayPermitted'] != null ||
        license['digitalRedistributionPermitted'] != null ||
        license['protectedStructureReusePermitted'] != null) {
      _add(
        issues,
        'ML5_EVIDENCE_UNEXPECTED_LICENSE',
        r'$evidence.license',
        'This rights treatment must not carry license metadata.',
      );
    }
  }

  static Map<String, dynamic>? _requiredMap(
    dynamic value,
    String path,
    String code,
    List<RightsEvidenceIssue> issues,
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
    List<RightsEvidenceIssue> issues,
  ) {
    final actual = map.keys.toSet();
    for (final missing in expected.difference(actual)) {
      _add(
        issues,
        'ML5_EVIDENCE_REQUIRED_FIELD',
        '$path.$missing',
        'Required evidence field is missing.',
      );
    }
    for (final extra in actual.difference(expected)) {
      _add(
        issues,
        'ML5_EVIDENCE_UNKNOWN_FIELD',
        '$path.$extra',
        'Unknown evidence field is not allowed.',
      );
    }
  }

  static void _validatePattern(
    dynamic value,
    RegExp pattern,
    String path,
    String code,
    List<RightsEvidenceIssue> issues,
  ) {
    if (value is! String || !pattern.hasMatch(value)) {
      _add(issues, code, path, 'Value does not match the required pattern.');
    }
  }

  static bool _nonEmptyString(dynamic value) =>
      value is String && value.trim().isNotEmpty;

  static DateTime? _parseStrictDate(dynamic value) {
    if (value is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      return null;
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return null;
    }
    final normalized =
        '${parsed.year.toString().padLeft(4, '0')}-'
        '${parsed.month.toString().padLeft(2, '0')}-'
        '${parsed.day.toString().padLeft(2, '0')}';
    return normalized == value ? parsed : null;
  }

  static bool _isStrictDate(dynamic value) => _parseStrictDate(value) != null;

  static void _add(
    List<RightsEvidenceIssue> issues,
    String code,
    String path,
    String message,
  ) {
    issues.add(RightsEvidenceIssue(code: code, path: path, message: message));
  }
}
