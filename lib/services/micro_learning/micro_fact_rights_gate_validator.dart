import 'micro_fact_claim_gate_validator.dart';
import 'rights_evidence_validator.dart';
import 'rights_provenance_policy_validator.dart';

class MicroFactRightsGateIssue {
  const MicroFactRightsGateIssue({
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

class MicroFactRightsGateResult {
  const MicroFactRightsGateResult(this.issues);

  final List<MicroFactRightsGateIssue> issues;

  bool get isValid => issues.isEmpty;
}

class MicroFactRightsGateValidator {
  const MicroFactRightsGateValidator();

  MicroFactRightsGateResult validateMaps({
    required Map<String, dynamic> microFact,
    required Map<String, dynamic> authorityRegistry,
    required Map<String, dynamic> claimPolicy,
    required Map<String, dynamic> rightsPolicy,
    Map<String, dynamic>? rightsEvidence,
  }) {
    final issues = <MicroFactRightsGateIssue>[];

    final claimGate = const MicroFactClaimGateValidator().validateMaps(
      microFact: microFact,
      authorityRegistry: authorityRegistry,
      claimPolicy: claimPolicy,
    );
    for (final issue in claimGate.issues) {
      _add(
        issues,
        'ML5_CLAIM_PREREQUISITE_INVALID',
        issue.path,
        '${issue.code}: ${issue.message}',
      );
    }

    final policyResult = const RightsProvenancePolicyValidator().validateMap(
      rightsPolicy,
    );
    for (final issue in policyResult.issues) {
      _add(
        issues,
        'ML5_POLICY_PREREQUISITE_INVALID',
        issue.path,
        '${issue.code}: ${issue.message}',
      );
    }

    if (issues.isNotEmpty) {
      return MicroFactRightsGateResult(List.unmodifiable(issues));
    }

    final status = microFact['status'] as String;
    final runtime = Map<String, dynamic>.from(microFact['runtime'] as Map);
    final provenance = Map<String, dynamic>.from(
      microFact['provenance'] as Map,
    );
    final review = Map<String, dynamic>.from(microFact['review'] as Map);
    final display = Map<String, dynamic>.from(microFact['display'] as Map);

    final lifecycle = Map<String, dynamic>.from(
      rightsPolicy['lifecycle'] as Map,
    );
    final evidenceRequiredStatuses =
        (lifecycle['evidenceRequiredForStatuses'] as List)
            .whereType<String>()
            .toSet();
    final evidenceMustPassStatuses =
        (lifecycle['evidenceMustPassForStatuses'] as List)
            .whereType<String>()
            .toSet();

    final evidenceRequired =
        evidenceRequiredStatuses.contains(status) ||
        runtime['startupEligible'] == true;

    if (rightsEvidence == null) {
      if (evidenceRequired) {
        _add(
          issues,
          'ML5_RIGHTS_EVIDENCE_REQUIRED',
          r'$evidence',
          'This lifecycle/runtime state requires a rights-evidence record.',
        );
      }
      return MicroFactRightsGateResult(List.unmodifiable(issues));
    }

    final evidenceResult = const RightsEvidenceValidator().validateMap(
      rightsEvidence,
    );
    for (final issue in evidenceResult.issues) {
      _add(
        issues,
        'ML5_EVIDENCE_PREREQUISITE_INVALID',
        issue.path,
        '${issue.code}: ${issue.message}',
      );
    }

    if (issues.isNotEmpty) {
      return MicroFactRightsGateResult(List.unmodifiable(issues));
    }

    _validateIdentityBinding(microFact, rightsEvidence, issues);
    _validateSourceFingerprint(provenance, rightsEvidence, issues);

    final evidenceReview = Map<String, dynamic>.from(
      rightsEvidence['review'] as Map,
    );
    final evidenceTreatment = rightsEvidence['rightsTreatment'] as String;
    final factTreatment = provenance['rightsTreatment'] as String;

    if (factTreatment != evidenceTreatment) {
      _add(
        issues,
        'ML5_RIGHTS_TREATMENT_MISMATCH',
        r'$evidence.rightsTreatment',
        'Evidence rights treatment must exactly match the MicroFact.',
      );
    }

    if (evidenceMustPassStatuses.contains(status) &&
        evidenceReview['status'] != 'pass') {
      _add(
        issues,
        'ML5_RIGHTS_EVIDENCE_NOT_PASS',
        r'$evidence.review.status',
        'Validated or published facts require passing rights evidence.',
      );
    }

    if (runtime['startupEligible'] == true &&
        (lifecycle['startupEligibleRequiresPassingEvidence'] != true ||
            evidenceReview['status'] != 'pass')) {
      _add(
        issues,
        'ML5_STARTUP_RIGHTS_EVIDENCE_NOT_PASS',
        r'$evidence.review.status',
        'Startup-eligible facts require passing rights evidence.',
      );
    }

    if ((evidenceMustPassStatuses.contains(status) ||
            runtime['startupEligible'] == true) &&
        review['copyrightStatus'] != 'pass') {
      _add(
        issues,
        'ML5_COPYRIGHT_REVIEW_NOT_PASS',
        r'$.review.copyrightStatus',
        'Fact copyrightStatus must be pass before validated/published/startup use.',
      );
    }

    _validateReviewChronology(
      provenance: provenance,
      factReview: review,
      evidenceReview: evidenceReview,
      rightsPolicy: rightsPolicy,
      issues: issues,
    );

    final authority = _findAuthority(
      authorityRegistry,
      provenance['sourceRegistryId'] as String,
    );
    if (authority == null) {
      _add(
        issues,
        'ML5_AUTHORITY_MISSING',
        r'$.provenance.sourceRegistryId',
        'Authority disappeared after lower-gate validation.',
      );
      return MicroFactRightsGateResult(List.unmodifiable(issues));
    }

    _validateAuthorityRightsContext(
      authority: authority,
      provenance: provenance,
      rightsPolicy: rightsPolicy,
      evidence: rightsEvidence,
      issues: issues,
    );

    _validateQuotePresentation(
      display: display,
      provenance: provenance,
      treatment: evidenceTreatment,
      evidence: rightsEvidence,
      issues: issues,
    );

    _validateLicenseCurrency(
      factReview: review,
      treatment: evidenceTreatment,
      evidence: rightsEvidence,
      issues: issues,
    );

    return MicroFactRightsGateResult(List.unmodifiable(issues));
  }

  void _validateIdentityBinding(
    Map<String, dynamic> fact,
    Map<String, dynamic> evidence,
    List<MicroFactRightsGateIssue> issues,
  ) {
    if (evidence['microFactId'] != fact['microFactId']) {
      _add(
        issues,
        'ML5_EVIDENCE_FACT_ID_MISMATCH',
        r'$evidence.microFactId',
        'Rights evidence belongs to a different MicroFact.',
      );
    }

    if (evidence['contentVersion'] != fact['contentVersion']) {
      _add(
        issues,
        'ML5_EVIDENCE_CONTENT_VERSION_MISMATCH',
        r'$evidence.contentVersion',
        'Rights evidence belongs to a different MicroFact content version.',
      );
    }
  }

  void _validateSourceFingerprint(
    Map<String, dynamic> provenance,
    Map<String, dynamic> evidence,
    List<MicroFactRightsGateIssue> issues,
  ) {
    final fingerprint = Map<String, dynamic>.from(
      evidence['sourceFingerprint'] as Map,
    );

    for (final field in const {
      'sourceRegistryId',
      'officialUrl',
      'sourceLocator',
      'editionOrRevision',
    }) {
      if (fingerprint[field] != provenance[field]) {
        _add(
          issues,
          'ML5_SOURCE_FINGERPRINT_MISMATCH',
          r'$evidence.sourceFingerprint.' + field,
          'Rights evidence source fingerprint does not match MicroFact provenance.',
        );
      }
    }
  }

  void _validateReviewChronology({
    required Map<String, dynamic> provenance,
    required Map<String, dynamic> factReview,
    required Map<String, dynamic> evidenceReview,
    required Map<String, dynamic> rightsPolicy,
    required List<MicroFactRightsGateIssue> issues,
  }) {
    final sourceVerifiedAt = _parseStrictDate(provenance['sourceVerifiedAt']);
    final evidenceReviewedAt = _parseStrictDate(evidenceReview['reviewedAt']);
    final evidenceDueAt = _parseStrictDate(evidenceReview['nextReviewDueAt']);
    final factReviewedAt = _parseStrictDate(factReview['reviewedAt']);

    if (sourceVerifiedAt != null &&
        evidenceReviewedAt != null &&
        evidenceReviewedAt.isBefore(sourceVerifiedAt)) {
      _add(
        issues,
        'ML5_RIGHTS_REVIEW_BEFORE_SOURCE_VERIFICATION',
        r'$evidence.review.reviewedAt',
        'Rights review cannot predate source verification.',
      );
    }

    if (evidenceReviewedAt != null &&
        factReviewedAt != null &&
        evidenceReviewedAt.isAfter(factReviewedAt)) {
      _add(
        issues,
        'ML5_RIGHTS_REVIEW_AFTER_FACT_REVIEW',
        r'$evidence.review.reviewedAt',
        'Final fact review cannot predate the rights review it depends on.',
      );
    }

    if (evidenceDueAt != null &&
        factReviewedAt != null &&
        evidenceDueAt.isBefore(factReviewedAt)) {
      _add(
        issues,
        'ML5_RIGHTS_EVIDENCE_ALREADY_STALE',
        r'$evidence.review.nextReviewDueAt',
        'Rights evidence was already stale when the fact was reviewed.',
      );
    }

    final evidenceRules = Map<String, dynamic>.from(
      rightsPolicy['evidenceRules'] as Map,
    );
    final maxAgeDays = evidenceRules['maxEvidenceAgeDays'] as int;
    if (evidenceReviewedAt != null && factReviewedAt != null) {
      final ageDays = factReviewedAt.difference(evidenceReviewedAt).inDays;
      if (ageDays > maxAgeDays) {
        _add(
          issues,
          'ML5_RIGHTS_EVIDENCE_TOO_OLD',
          r'$evidence.review.reviewedAt',
          'Rights evidence exceeds the frozen maximum evidence age.',
        );
      }
    }
  }

  void _validateAuthorityRightsContext({
    required Map<String, dynamic> authority,
    required Map<String, dynamic> provenance,
    required Map<String, dynamic> rightsPolicy,
    required Map<String, dynamic> evidence,
    required List<MicroFactRightsGateIssue> issues,
  }) {
    final sourceId = provenance['sourceRegistryId'] as String;
    final tiers = Map<String, dynamic>.from(
      rightsPolicy['authorityRightsTiers'] as Map,
    );
    final sensitiveIds =
        (tiers['rights_sensitive_professional_or_standards'] as List)
            .whereType<String>()
            .toSet();

    if (sensitiveIds.contains(sourceId)) {
      final sensitiveRules = Map<String, dynamic>.from(
        rightsPolicy['rightsSensitiveRules'] as Map,
      );
      final editionPolicies =
          (sensitiveRules['requireEditionOrRevisionWhenAuthorityPolicyIn']
                  as List)
              .whereType<String>()
              .toSet();

      if (editionPolicies.contains(authority['editionPolicy']) &&
          !_nonEmptyString(provenance['editionOrRevision'])) {
        _add(
          issues,
          'ML5_RIGHTS_SENSITIVE_EDITION_REQUIRED',
          r'$.provenance.editionOrRevision',
          'Rights-sensitive source requires edition/revision provenance.',
        );
      }

      final treatment = provenance['rightsTreatment'] as String;
      final evidenceReview = Map<String, dynamic>.from(
        evidence['review'] as Map,
      );
      if ((treatment == 'minimal_quote' || treatment == 'licensed_excerpt') &&
          evidenceReview['humanReviewed'] != true) {
        _add(
          issues,
          'ML5_RIGHTS_SENSITIVE_HUMAN_REVIEW_REQUIRED',
          r'$evidence.review.humanReviewed',
          'Quotation/excerpt from a rights-sensitive source requires human rights review.',
        );
      }
    }

    final governmentIds = (tiers['government_first_party'] as List)
        .whereType<String>()
        .toSet();
    if (governmentIds.contains(sourceId)) {
      final restricted = Map<String, dynamic>.from(
        evidence['restrictedMaterial'] as Map,
      );
      if (restricted['thirdPartyMaterialPresent'] == true &&
          restricted['thirdPartyMaterialCleared'] != true) {
        _add(
          issues,
          'ML5_GOVERNMENT_THIRD_PARTY_MATERIAL_NOT_CLEARED',
          r'$evidence.restrictedMaterial.thirdPartyMaterialCleared',
          'Government-hosted third-party material requires separate clearance.',
        );
      }
    }
  }

  void _validateQuotePresentation({
    required Map<String, dynamic> display,
    required Map<String, dynamic> provenance,
    required String treatment,
    required Map<String, dynamic> evidence,
    required List<MicroFactRightsGateIssue> issues,
  }) {
    final fullText = display['displayText'] as String;
    final shortText = display['shortVariant'] as String?;
    final combined = shortText == null ? fullText : '$fullText $shortText';

    if (treatment == 'minimal_quote' || treatment == 'licensed_excerpt') {
      if (!_containsQuoteMarkers(combined)) {
        _add(
          issues,
          'ML5_QUOTE_NOT_VISIBLY_MARKED',
          r'$.display',
          'Quoted or licensed excerpt wording must be visibly marked as quotation.',
        );
      }

      final sourceSection = provenance['sourceSection'] as String?;
      final sourcePage = provenance['sourcePage'] as String?;
      if (!_nonEmptyString(sourceSection) && !_nonEmptyString(sourcePage)) {
        _add(
          issues,
          'ML5_QUOTE_SOURCE_LOCATION_REQUIRED',
          r'$.provenance',
          'Quoted or licensed excerpt requires a source section or page.',
        );
      }

      final transformation = Map<String, dynamic>.from(
        evidence['transformation'] as Map,
      );
      if (transformation['sourceComparisonPerformed'] != true) {
        _add(
          issues,
          'ML5_QUOTE_SOURCE_COMPARISON_REQUIRED',
          r'$evidence.transformation.sourceComparisonPerformed',
          'Quotation/excerpt requires source comparison.',
        );
      }
    } else if (_containsQuoteMarkers(combined)) {
      _add(
        issues,
        'ML5_UNDECLARED_QUOTATION_MARKERS',
        r'$.display',
        'Paraphrase/summary treatment cannot contain quotation markers.',
      );
    }
  }

  void _validateLicenseCurrency({
    required Map<String, dynamic> factReview,
    required String treatment,
    required Map<String, dynamic> evidence,
    required List<MicroFactRightsGateIssue> issues,
  }) {
    if (treatment != 'licensed_excerpt') {
      return;
    }

    final license = Map<String, dynamic>.from(evidence['license'] as Map);
    final expiresAt = _parseStrictDate(license['expiresAt']);
    final factReviewedAt = _parseStrictDate(factReview['reviewedAt']);

    if (expiresAt != null &&
        factReviewedAt != null &&
        expiresAt.isBefore(factReviewedAt)) {
      _add(
        issues,
        'ML5_LICENSE_EXPIRED_AT_REVIEW',
        r'$evidence.license.expiresAt',
        'License was expired when the MicroFact was reviewed.',
      );
    }
  }

  static Map<String, dynamic>? _findAuthority(
    Map<String, dynamic> registry,
    String sourceId,
  ) {
    final authorities = registry['authorities'];
    if (authorities is! List) {
      return null;
    }

    for (final item in authorities) {
      if (item is Map && item['id'] == sourceId) {
        return Map<String, dynamic>.from(item);
      }
    }
    return null;
  }

  static bool _containsQuoteMarkers(String value) =>
      value.contains('"') || value.contains('“') || value.contains('”');

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

  static void _add(
    List<MicroFactRightsGateIssue> issues,
    String code,
    String path,
    String message,
  ) {
    issues.add(
      MicroFactRightsGateIssue(code: code, path: path, message: message),
    );
  }
}
