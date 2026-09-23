import '../../data/csp11_blueprint.dart';
import 'canonical_curriculum_policy_validator.dart';
import 'canonical_curriculum_registry_validator.dart';
import 'curriculum_mapping_evidence_validator.dart';
import 'micro_fact_rights_gate_validator.dart';

class MicroFactCurriculumGateIssue {
  const MicroFactCurriculumGateIssue({
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

class MicroFactCurriculumGateResult {
  const MicroFactCurriculumGateResult(this.issues);

  final List<MicroFactCurriculumGateIssue> issues;

  bool get isValid => issues.isEmpty;
}

class MicroFactCurriculumGateValidator {
  const MicroFactCurriculumGateValidator();

  MicroFactCurriculumGateResult validateMaps({
    required Map<String, dynamic> microFact,
    required Map<String, dynamic> authorityRegistry,
    required Map<String, dynamic> claimPolicy,
    required Map<String, dynamic> rightsPolicy,
    required Map<String, dynamic> rightsEvidence,
    required Map<String, dynamic> curriculumPolicy,
    required Map<String, dynamic> curriculumRegistry,
    Map<String, dynamic>? curriculumEvidence,
  }) {
    final issues = <MicroFactCurriculumGateIssue>[];

    final rightsResult = const MicroFactRightsGateValidator().validateMaps(
      microFact: microFact,
      authorityRegistry: authorityRegistry,
      claimPolicy: claimPolicy,
      rightsPolicy: rightsPolicy,
      rightsEvidence: rightsEvidence,
    );
    for (final issue in rightsResult.issues) {
      _add(
        issues,
        'ML6_RIGHTS_PREREQUISITE_INVALID',
        issue.path,
        issue.code + ': ' + issue.message,
      );
    }

    final policyResult = const CanonicalCurriculumPolicyValidator().validateMap(
      curriculumPolicy,
    );
    for (final issue in policyResult.issues) {
      _add(
        issues,
        'ML6_POLICY_PREREQUISITE_INVALID',
        issue.path,
        issue.code + ': ' + issue.message,
      );
    }

    final registryResult = const CanonicalCurriculumRegistryValidator()
        .validateMap(curriculumRegistry);
    for (final issue in registryResult.issues) {
      _add(
        issues,
        'ML6_REGISTRY_PREREQUISITE_INVALID',
        issue.path,
        issue.code + ': ' + issue.message,
      );
    }

    if (issues.isNotEmpty) {
      return MicroFactCurriculumGateResult(List.unmodifiable(issues));
    }

    final curriculum = Map<String, dynamic>.from(
      microFact['curriculum'] as Map,
    );
    final runtime = Map<String, dynamic>.from(microFact['runtime'] as Map);
    final factReview = Map<String, dynamic>.from(microFact['review'] as Map);
    final scope = curriculum['scope'] as String;

    if (scope == 'general') {
      _validateGeneralScope(curriculum, curriculumEvidence, issues);
      return MicroFactCurriculumGateResult(List.unmodifiable(issues));
    }

    if (scope != 'mapped') {
      _add(
        issues,
        'ML6_SCOPE_INVALID',
        r'$.curriculum.scope',
        'ML-6 only accepts general or mapped curriculum scope.',
      );
      return MicroFactCurriculumGateResult(List.unmodifiable(issues));
    }

    _validateMappedHierarchy(
      curriculum: curriculum,
      registry: curriculumRegistry,
      issues: issues,
    );

    final status = microFact['status'] as String;
    final mappedRules = Map<String, dynamic>.from(
      (curriculumPolicy['scopeRules'] as Map)['mapped'] as Map,
    );
    final evidenceRequiredStatuses =
        (mappedRules['mappingEvidenceRequiredForStatuses'] as List)
            .whereType<String>()
            .toSet();

    final evidenceRequired =
        evidenceRequiredStatuses.contains(status) ||
        runtime['startupEligible'] == true;

    if (curriculumEvidence == null) {
      if (evidenceRequired) {
        _add(
          issues,
          'ML6_MAPPING_EVIDENCE_REQUIRED',
          r'$evidence',
          'This mapped lifecycle/runtime state requires curriculum mapping evidence.',
        );
      }
      return MicroFactCurriculumGateResult(List.unmodifiable(issues));
    }

    final evidenceResult = const CurriculumMappingEvidenceValidator()
        .validateMap(curriculumEvidence);
    for (final issue in evidenceResult.issues) {
      _add(
        issues,
        'ML6_EVIDENCE_PREREQUISITE_INVALID',
        issue.path,
        issue.code + ': ' + issue.message,
      );
    }

    if (issues.isNotEmpty) {
      return MicroFactCurriculumGateResult(List.unmodifiable(issues));
    }

    _validateEvidenceBinding(
      microFact: microFact,
      curriculum: curriculum,
      registry: curriculumRegistry,
      evidence: curriculumEvidence,
      issues: issues,
    );

    final evidenceReview = Map<String, dynamic>.from(
      curriculumEvidence['review'] as Map,
    );
    final evidenceRules = Map<String, dynamic>.from(
      curriculumPolicy['evidenceRules'] as Map,
    );
    final mustPassStatuses =
        (evidenceRules['evidenceMustPassForStatuses'] as List)
            .whereType<String>()
            .toSet();

    if (mustPassStatuses.contains(status) &&
        evidenceReview['status'] != 'pass') {
      _add(
        issues,
        'ML6_MAPPING_EVIDENCE_NOT_PASS',
        r'$evidence.review.status',
        'Validated or published mapped facts require passing mapping evidence.',
      );
    }

    if (runtime['startupEligible'] == true &&
        evidenceReview['status'] != 'pass') {
      _add(
        issues,
        'ML6_STARTUP_MAPPING_EVIDENCE_NOT_PASS',
        r'$evidence.review.status',
        'Startup-eligible mapped facts require passing mapping evidence.',
      );
    }

    if ((mustPassStatuses.contains(status) ||
            runtime['startupEligible'] == true) &&
        (evidenceReview['humanReviewed'] != true ||
            evidenceReview['conceptAlignmentConfirmed'] != true)) {
      _add(
        issues,
        'ML6_HUMAN_MAPPING_REVIEW_REQUIRED',
        r'$evidence.review',
        'Mapped facts require human placement review with confirmed concept alignment.',
      );
    }

    _validateReviewChronology(
      factReview: factReview,
      evidenceReview: evidenceReview,
      maxAgeDays: evidenceRules['maxEvidenceAgeDays'] as int,
      issues: issues,
    );

    return MicroFactCurriculumGateResult(List.unmodifiable(issues));
  }

  void _validateGeneralScope(
    Map<String, dynamic> curriculum,
    Map<String, dynamic>? curriculumEvidence,
    List<MicroFactCurriculumGateIssue> issues,
  ) {
    for (final field in const {
      'domainId',
      'competencyId',
      'topicId',
      'subtopicId',
    }) {
      if (curriculum[field] != null) {
        _add(
          issues,
          'ML6_GENERAL_SCOPE_HAS_MAPPING',
          r'$.curriculum.' + field,
          'General-scope facts must not carry curriculum IDs.',
        );
      }
    }

    if (curriculumEvidence != null) {
      _add(
        issues,
        'ML6_GENERAL_SCOPE_EVIDENCE_FORBIDDEN',
        r'$evidence',
        'General-scope facts must not carry curriculum mapping evidence.',
      );
    }
  }

  void _validateMappedHierarchy({
    required Map<String, dynamic> curriculum,
    required Map<String, dynamic> registry,
    required List<MicroFactCurriculumGateIssue> issues,
  }) {
    final domainId = curriculum['domainId'] as String?;
    final competencyId = curriculum['competencyId'] as String?;
    final topicId = curriculum['topicId'] as String?;
    final subtopicId = curriculum['subtopicId'] as String?;

    if (domainId == null || domainForId(domainId) == null) {
      _add(
        issues,
        'ML6_DOMAIN_NOT_CANONICAL',
        r'$.curriculum.domainId',
        'Mapped fact must reference an existing canonical CSP11 domain.',
      );
    }

    if (competencyId == null || competencyForId(competencyId) == null) {
      _add(
        issues,
        'ML6_COMPETENCY_NOT_CANONICAL',
        r'$.curriculum.competencyId',
        'Mapped fact must reference an existing canonical CSP11 competency.',
      );
    }

    if (domainId != null &&
        competencyId != null &&
        !_competencyBelongsToDomain(domainId, competencyId)) {
      _add(
        issues,
        'ML6_COMPETENCY_WRONG_PARENT',
        r'$.curriculum.competencyId',
        'Competency does not belong to the declared canonical domain.',
      );
    }

    if (subtopicId != null && topicId == null) {
      _add(
        issues,
        'ML6_SUBTOPIC_REQUIRES_TOPIC',
        r'$.curriculum.subtopicId',
        'Subtopic mapping requires a topic mapping.',
      );
    }

    if (topicId == null) {
      return;
    }

    final topic = _findTopic(registry, topicId);
    if (topic == null) {
      _add(
        issues,
        'ML6_TOPIC_NOT_REGISTERED',
        r'$.curriculum.topicId',
        'Topic is not present in the frozen canonical navigation registry.',
      );
      return;
    }

    if (topic['status'] != 'active') {
      _add(
        issues,
        'ML6_TOPIC_NOT_ACTIVE',
        r'$.curriculum.topicId',
        'Deprecated or retired topics cannot receive MicroFact mappings.',
      );
    }

    if (topic['domainId'] != domainId ||
        topic['competencyId'] != competencyId) {
      _add(
        issues,
        'ML6_TOPIC_WRONG_PARENT',
        r'$.curriculum.topicId',
        'Topic does not belong to the declared Domain/Competency chain.',
      );
    }

    if (subtopicId == null) {
      return;
    }

    final subtopic = _findSubtopic(topic, subtopicId);
    if (subtopic == null) {
      _add(
        issues,
        'ML6_SUBTOPIC_NOT_REGISTERED',
        r'$.curriculum.subtopicId',
        'Subtopic is not present under the declared canonical topic.',
      );
      return;
    }

    if (subtopic['status'] != 'active') {
      _add(
        issues,
        'ML6_SUBTOPIC_NOT_ACTIVE',
        r'$.curriculum.subtopicId',
        'Deprecated or retired subtopics cannot receive MicroFact mappings.',
      );
    }
  }

  void _validateEvidenceBinding({
    required Map<String, dynamic> microFact,
    required Map<String, dynamic> curriculum,
    required Map<String, dynamic> registry,
    required Map<String, dynamic> evidence,
    required List<MicroFactCurriculumGateIssue> issues,
  }) {
    if (evidence['microFactId'] != microFact['microFactId']) {
      _add(
        issues,
        'ML6_EVIDENCE_FACT_ID_MISMATCH',
        r'$evidence.microFactId',
        'Mapping evidence belongs to a different MicroFact.',
      );
    }

    if (evidence['contentVersion'] != microFact['contentVersion']) {
      _add(
        issues,
        'ML6_EVIDENCE_CONTENT_VERSION_MISMATCH',
        r'$evidence.contentVersion',
        'Mapping evidence belongs to a different MicroFact content version.',
      );
    }

    if (evidence['blueprintVersion'] !=
        CanonicalCurriculumPolicyValidator.requiredBlueprintVersion) {
      _add(
        issues,
        'ML6_EVIDENCE_BLUEPRINT_DRIFT',
        r'$evidence.blueprintVersion',
        'Mapping evidence blueprint version no longer matches ML-6.',
      );
    }

    if (evidence['navigationRegistryVersion'] != registry['registryVersion']) {
      _add(
        issues,
        'ML6_EVIDENCE_REGISTRY_DRIFT',
        r'$evidence.navigationRegistryVersion',
        'Mapping evidence navigation registry version no longer matches.',
      );
    }

    final mapping = Map<String, dynamic>.from(evidence['mapping'] as Map);

    for (final field in const {
      'scope',
      'domainId',
      'competencyId',
      'topicId',
      'subtopicId',
    }) {
      if (mapping[field] != curriculum[field]) {
        _add(
          issues,
          'ML6_EVIDENCE_MAPPING_DRIFT',
          r'$evidence.mapping.' + field,
          'Mapping evidence no longer matches the MicroFact curriculum mapping.',
        );
      }
    }

    final expectedKey = CurriculumMappingEvidenceValidator.mappingKey(
      domainId: curriculum['domainId'] as String,
      competencyId: curriculum['competencyId'] as String,
      topicId: curriculum['topicId'] as String?,
      subtopicId: curriculum['subtopicId'] as String?,
    );

    if (mapping['mappingKey'] != expectedKey) {
      _add(
        issues,
        'ML6_EVIDENCE_MAPPING_KEY_DRIFT',
        r'$evidence.mapping.mappingKey',
        'Mapping fingerprint no longer matches the MicroFact.',
      );
    }
  }

  void _validateReviewChronology({
    required Map<String, dynamic> factReview,
    required Map<String, dynamic> evidenceReview,
    required int maxAgeDays,
    required List<MicroFactCurriculumGateIssue> issues,
  }) {
    final factReviewedAt = _parseStrictDate(factReview['reviewedAt']);
    final mappingReviewedAt = _parseStrictDate(evidenceReview['reviewedAt']);
    final mappingDueAt = _parseStrictDate(evidenceReview['nextReviewDueAt']);

    if (mappingReviewedAt != null &&
        factReviewedAt != null &&
        mappingReviewedAt.isAfter(factReviewedAt)) {
      _add(
        issues,
        'ML6_MAPPING_REVIEW_AFTER_FACT_REVIEW',
        r'$evidence.review.reviewedAt',
        'Final fact review cannot predate its curriculum mapping review.',
      );
    }

    if (mappingDueAt != null &&
        factReviewedAt != null &&
        mappingDueAt.isBefore(factReviewedAt)) {
      _add(
        issues,
        'ML6_MAPPING_EVIDENCE_ALREADY_STALE',
        r'$evidence.review.nextReviewDueAt',
        'Curriculum mapping evidence was already stale at final fact review.',
      );
    }

    if (mappingReviewedAt != null && factReviewedAt != null) {
      final ageDays = factReviewedAt.difference(mappingReviewedAt).inDays;
      if (ageDays > maxAgeDays) {
        _add(
          issues,
          'ML6_MAPPING_EVIDENCE_TOO_OLD',
          r'$evidence.review.reviewedAt',
          'Curriculum mapping evidence exceeds the frozen maximum age.',
        );
      }
    }
  }

  static bool _competencyBelongsToDomain(String domainId, String competencyId) {
    return competenciesForDomain(
      domainId,
    ).any((competency) => competency.id == competencyId);
  }

  static Map<String, dynamic>? _findTopic(
    Map<String, dynamic> registry,
    String topicId,
  ) {
    final topics = registry['topics'];
    if (topics is! List) return null;

    for (final item in topics) {
      if (item is Map && item['id'] == topicId) {
        return Map<String, dynamic>.from(item);
      }
    }
    return null;
  }

  static Map<String, dynamic>? _findSubtopic(
    Map<String, dynamic> topic,
    String subtopicId,
  ) {
    final subtopics = topic['subtopics'];
    if (subtopics is! List) return null;

    for (final item in subtopics) {
      if (item is Map && item['id'] == subtopicId) {
        return Map<String, dynamic>.from(item);
      }
    }
    return null;
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

  static void _add(
    List<MicroFactCurriculumGateIssue> issues,
    String code,
    String path,
    String message,
  ) {
    issues.add(
      MicroFactCurriculumGateIssue(code: code, path: path, message: message),
    );
  }
}
