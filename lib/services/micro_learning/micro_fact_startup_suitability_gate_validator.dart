import 'micro_fact_curriculum_gate_validator.dart';
import 'startup_pedagogy_evidence_validator.dart';
import 'startup_pedagogy_policy_validator.dart';
import 'startup_text_metrics.dart';

class MicroFactStartupSuitabilityIssue {
  const MicroFactStartupSuitabilityIssue({
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

class MicroFactStartupSuitabilityResult {
  const MicroFactStartupSuitabilityResult(this.issues);

  final List<MicroFactStartupSuitabilityIssue> issues;

  bool get isValid => issues.isEmpty;
}

class MicroFactStartupSuitabilityGateValidator {
  const MicroFactStartupSuitabilityGateValidator();

  MicroFactStartupSuitabilityResult validateMaps({
    required Map<String, dynamic> microFact,
    required Map<String, dynamic> authorityRegistry,
    required Map<String, dynamic> claimPolicy,
    required Map<String, dynamic> rightsPolicy,
    required Map<String, dynamic> rightsEvidence,
    required Map<String, dynamic> curriculumPolicy,
    required Map<String, dynamic> curriculumRegistry,
    Map<String, dynamic>? curriculumEvidence,
    required Map<String, dynamic> pedagogyPolicy,
    Map<String, dynamic>? pedagogyEvidence,
  }) {
    final issues = <MicroFactStartupSuitabilityIssue>[];

    final curriculumResult = const MicroFactCurriculumGateValidator()
        .validateMaps(
          microFact: microFact,
          authorityRegistry: authorityRegistry,
          claimPolicy: claimPolicy,
          rightsPolicy: rightsPolicy,
          rightsEvidence: rightsEvidence,
          curriculumPolicy: curriculumPolicy,
          curriculumRegistry: curriculumRegistry,
          curriculumEvidence: curriculumEvidence,
        );
    for (final issue in curriculumResult.issues) {
      _add(
        issues,
        'ML7_CURRICULUM_PREREQUISITE_INVALID',
        issue.path,
        issue.code + ': ' + issue.message,
      );
    }

    final policyResult = const StartupPedagogyPolicyValidator().validateMap(
      pedagogyPolicy,
    );
    for (final issue in policyResult.issues) {
      _add(
        issues,
        'ML7_POLICY_PREREQUISITE_INVALID',
        issue.path,
        issue.code + ': ' + issue.message,
      );
    }

    if (issues.isNotEmpty) {
      return MicroFactStartupSuitabilityResult(List.unmodifiable(issues));
    }

    final runtime = Map<String, dynamic>.from(microFact['runtime'] as Map);
    final startupEligible = runtime['startupEligible'] == true;

    if (!startupEligible) {
      return MicroFactStartupSuitabilityResult(List.unmodifiable(issues));
    }

    final display = Map<String, dynamic>.from(microFact['display'] as Map);
    final review = Map<String, dynamic>.from(microFact['review'] as Map);
    final assessment = Map<String, dynamic>.from(
      microFact['assessment'] as Map,
    );
    final category = microFact['category'] as String;
    final status = microFact['status'] as String;

    _validateStartupText(
      display: display,
      category: category,
      policy: pedagogyPolicy,
      issues: issues,
    );
    _validateAssessment(
      assessment: assessment,
      policy: pedagogyPolicy,
      issues: issues,
    );

    final evidenceRules = Map<String, dynamic>.from(
      pedagogyPolicy['evidenceRules'] as Map,
    );
    final requiredStatuses =
        (evidenceRules['requiredForStartupEligibleStatuses'] as List)
            .whereType<String>()
            .toSet();
    final mustPassStatuses =
        (evidenceRules['mustPassForStartupEligibleStatuses'] as List)
            .whereType<String>()
            .toSet();

    if (pedagogyEvidence == null) {
      if (requiredStatuses.contains(status)) {
        _add(
          issues,
          'ML7_PEDAGOGY_EVIDENCE_REQUIRED',
          r'$evidence',
          'Startup-eligible validated, published or review-due facts require ML-7 evidence.',
        );
      }
      return MicroFactStartupSuitabilityResult(List.unmodifiable(issues));
    }

    final evidenceResult = const StartupPedagogyEvidenceValidator().validateMap(
      pedagogyEvidence,
    );
    for (final issue in evidenceResult.issues) {
      _add(
        issues,
        'ML7_EVIDENCE_PREREQUISITE_INVALID',
        issue.path,
        issue.code + ': ' + issue.message,
      );
    }

    if (issues.isNotEmpty) {
      return MicroFactStartupSuitabilityResult(List.unmodifiable(issues));
    }

    _validateEvidenceBinding(
      microFact: microFact,
      display: display,
      evidence: pedagogyEvidence,
      policy: pedagogyPolicy,
      issues: issues,
    );

    final pedagogyReview = Map<String, dynamic>.from(
      pedagogyEvidence['pedagogyReview'] as Map,
    );
    final accessibilityReview = Map<String, dynamic>.from(
      pedagogyEvidence['accessibilityReview'] as Map,
    );

    if (mustPassStatuses.contains(status) &&
        (pedagogyReview['status'] != 'pass' ||
            accessibilityReview['status'] != 'pass')) {
      _add(
        issues,
        'ML7_EVIDENCE_NOT_PASS',
        r'$evidence',
        'Startup-eligible validated or published facts require passing pedagogy and accessibility evidence.',
      );
    }

    if (mustPassStatuses.contains(status) &&
        (review['pedagogyStatus'] != 'pass' || review['uiStatus'] != 'pass')) {
      _add(
        issues,
        'ML7_FACT_REVIEW_NOT_PASS',
        r'$.review',
        'MicroFact pedagogyStatus and uiStatus must both pass for startup use.',
      );
    }

    _validateReviewChronology(
      factReview: review,
      pedagogyReview: pedagogyReview,
      accessibilityReview: accessibilityReview,
      maxAgeDays: evidenceRules['maxEvidenceAgeDays'] as int,
      issues: issues,
    );

    _validatePrecisionReview(
      microFact: microFact,
      pedagogyReview: pedagogyReview,
      issues: issues,
    );

    return MicroFactStartupSuitabilityResult(List.unmodifiable(issues));
  }

  void _validateStartupText({
    required Map<String, dynamic> display,
    required String category,
    required Map<String, dynamic> policy,
    required List<MicroFactStartupSuitabilityIssue> issues,
  }) {
    final textRules = Map<String, dynamic>.from(policy['textRules'] as Map);
    final displayRules = Map<String, dynamic>.from(
      textRules['displayText'] as Map,
    );
    final shortRules = Map<String, dynamic>.from(
      textRules['shortVariant'] as Map,
    );
    final plainRules = Map<String, dynamic>.from(
      policy['plainTextRules'] as Map,
    );
    final abbreviationRules = Map<String, dynamic>.from(
      policy['abbreviationRules'] as Map,
    );
    final visualRules = Map<String, dynamic>.from(
      policy['visualIndependenceRules'] as Map,
    );

    final fullText = display['displayText'] as String;
    final shortText = display['shortVariant'] as String?;
    final estimatedReadSeconds = display['estimatedReadSeconds'] as int;
    final wordsPerMinute = textRules['nominalReadingWordsPerMinute'] as int;
    final tolerance = textRules['estimatedReadSecondsTolerance'] as int;

    final fullWords = StartupTextMetrics.wordCount(fullText);
    final fullSentences = StartupTextMetrics.sentenceCount(fullText);
    final computedFullSeconds = StartupTextMetrics.readSeconds(
      fullText,
      wordsPerMinute,
    );

    if (fullWords < displayRules['minWords'] as int ||
        fullWords > displayRules['maxWords'] as int ||
        fullText.length > displayRules['maxCharacters'] as int ||
        fullSentences > displayRules['maxSentences'] as int ||
        estimatedReadSeconds > displayRules['maxEstimatedReadSeconds'] as int) {
      _add(
        issues,
        'ML7_DISPLAY_TEXT_LIMIT',
        r'$.display.displayText',
        'Full MicroFact text exceeds the frozen startup readability limits.',
      );
    }

    if ((estimatedReadSeconds - computedFullSeconds).abs() > tolerance) {
      _add(
        issues,
        'ML7_ESTIMATED_READ_SECONDS_MISMATCH',
        r'$.display.estimatedReadSeconds',
        'estimatedReadSeconds is inconsistent with the frozen 150-wpm metric.',
      );
    }

    if (shortText == null || shortText.trim().isEmpty) {
      _add(
        issues,
        'ML7_SHORT_VARIANT_REQUIRED',
        r'$.display.shortVariant',
        'Startup-eligible MicroFacts require a non-empty short variant.',
      );
    } else {
      final shortWords = StartupTextMetrics.wordCount(shortText);
      final shortSentences = StartupTextMetrics.sentenceCount(shortText);
      final shortSeconds = StartupTextMetrics.readSeconds(
        shortText,
        wordsPerMinute,
      );

      if (shortWords < shortRules['minWords'] as int ||
          shortWords > shortRules['maxWords'] as int ||
          shortText.length > shortRules['maxCharacters'] as int ||
          shortSentences > shortRules['maxSentences'] as int ||
          shortSeconds > shortRules['maxComputedReadSeconds'] as int) {
        _add(
          issues,
          'ML7_SHORT_VARIANT_LIMIT',
          r'$.display.shortVariant',
          'Startup short copy exceeds the frozen rapid-reading limits.',
        );
      }

      final ratio = fullWords == 0 ? 1.0 : shortWords / fullWords;
      if (shortRules['mustBeShorterThanDisplayText'] == true &&
          shortWords >= fullWords) {
        _add(
          issues,
          'ML7_SHORT_NOT_SHORTER',
          r'$.display.shortVariant',
          'Startup short copy must contain fewer words than displayText.',
        );
      }
      if (ratio > (shortRules['maxWordRatioToDisplay'] as num).toDouble()) {
        _add(
          issues,
          'ML7_SHORT_COMPRESSION_INSUFFICIENT',
          r'$.display.shortVariant',
          'Startup short copy is not sufficiently compressed from displayText.',
        );
      }
    }

    for (final entry in <MapEntry<String, String?>>[
      MapEntry(r'$.display.displayText', fullText),
      MapEntry(r'$.display.shortVariant', shortText),
    ]) {
      final value = entry.value;
      if (value == null) continue;

      _validatePlainText(
        value: value,
        path: entry.key,
        plainRules: plainRules,
        textRules: textRules,
        abbreviationRules: abbreviationRules,
        visualRules: visualRules,
        category: category,
        issues: issues,
      );
    }
  }

  void _validatePlainText({
    required String value,
    required String path,
    required Map<String, dynamic> plainRules,
    required Map<String, dynamic> textRules,
    required Map<String, dynamic> abbreviationRules,
    required Map<String, dynamic> visualRules,
    required String category,
    required List<MicroFactStartupSuitabilityIssue> issues,
  }) {
    if ((plainRules['newlinesAllowed'] == false &&
            StartupTextMetrics.hasNewline(value)) ||
        (plainRules['tabsAllowed'] == false &&
            StartupTextMetrics.hasTab(value)) ||
        (plainRules['htmlAllowed'] == false &&
            StartupTextMetrics.hasHtml(value)) ||
        (plainRules['markdownLinksAllowed'] == false &&
            StartupTextMetrics.hasMarkdownLink(value)) ||
        (plainRules['rawUrlsAllowed'] == false &&
            StartupTextMetrics.hasRawUrl(value)) ||
        (plainRules['emojiAllowed'] == false &&
            StartupTextMetrics.hasEmoji(value)) ||
        (plainRules['bulletPrefixesAllowed'] == false &&
            StartupTextMetrics.hasBulletPrefix(value)) ||
        (plainRules['sourceLabelPrefixesAllowed'] == false &&
            StartupTextMetrics.hasSourceLabelPrefix(value)) ||
        (plainRules['repeatedWhitespaceAllowed'] == false &&
            StartupTextMetrics.hasRepeatedWhitespace(value))) {
      _add(
        issues,
        'ML7_PLAIN_TEXT_VIOLATION',
        path,
        'Startup copy must remain compact plain text without embedded formatting or source clutter.',
      );
    }

    if (StartupTextMetrics.parentheticalGroupCount(value) >
            textRules['maxParentheticalGroups']
        as int) {
      _add(
        issues,
        'ML7_PARENTHETICAL_OVERLOAD',
        path,
        'Startup copy contains too many parenthetical groups.',
      );
    }

    if (StartupTextMetrics.hasRepeatedPunctuation(value)) {
      _add(
        issues,
        'ML7_REPEATED_PUNCTUATION',
        path,
        'Repeated punctuation is not allowed in startup learning copy.',
      );
    }

    if (value.contains('?')) {
      final allowedCategories =
          (textRules['allowQuestionMarkForCategories'] as List)
              .whereType<String>()
              .toSet();
      if (!allowedCategories.contains(category)) {
        _add(
          issues,
          'ML7_QUESTION_MARK_CATEGORY',
          path,
          'Question-form startup copy is reserved for approved reflective categories.',
        );
      }
    }

    final approvedUppercase =
        (abbreviationRules['approvedUppercaseTokens'] as List)
            .whereType<String>()
            .map((token) => token.toUpperCase())
            .toSet();
    final unknownUppercase = StartupTextMetrics.uppercaseTokens(value)
        .where((token) => !approvedUppercase.contains(token.toUpperCase()))
        .toSet();

    if (unknownUppercase.length > abbreviationRules['maxUnknownUppercaseTokens']
        as int) {
      _add(
        issues,
        'ML7_UNKNOWN_UPPERCASE_JARGON',
        path,
        'Startup copy contains unapproved all-caps jargon: ' +
            unknownUppercase.join(', '),
      );
    }

    final blockedPhrases = (visualRules['blockedPhrases'] as List)
        .whereType<String>();
    if (StartupTextMetrics.containsAnyPhrase(value, blockedPhrases)) {
      _add(
        issues,
        'ML7_VISUAL_DEPENDENCY_LANGUAGE',
        path,
        'Startup copy must make sense without color, icons, animation, position or touch gestures.',
      );
    }

    if (StartupTextMetrics.containsAnswerKeyLanguage(value)) {
      _add(
        issues,
        'ML7_ANSWER_KEY_LANGUAGE',
        path,
        'Startup learning copy may not disclose answer-key language.',
      );
    }
  }

  void _validateAssessment({
    required Map<String, dynamic> assessment,
    required Map<String, dynamic> policy,
    required List<MicroFactStartupSuitabilityIssue> issues,
  }) {
    final rules = Map<String, dynamic>.from(policy['assessmentRules'] as Map);
    final blocked = (rules['blockedStartupSensitivities'] as List)
        .whereType<String>()
        .toSet();
    if (blocked.contains(assessment['sensitivity'])) {
      _add(
        issues,
        'ML7_ASSESSMENT_SENSITIVITY_BLOCKED',
        r'$.assessment.sensitivity',
        'High-sensitivity or assessment-blocked content cannot be startup eligible.',
      );
    }
  }

  void _validateEvidenceBinding({
    required Map<String, dynamic> microFact,
    required Map<String, dynamic> display,
    required Map<String, dynamic> evidence,
    required Map<String, dynamic> policy,
    required List<MicroFactStartupSuitabilityIssue> issues,
  }) {
    if (evidence['microFactId'] != microFact['microFactId']) {
      _add(
        issues,
        'ML7_EVIDENCE_FACT_ID_MISMATCH',
        r'$evidence.microFactId',
        'Pedagogy evidence belongs to a different MicroFact.',
      );
    }
    if (evidence['contentVersion'] != microFact['contentVersion']) {
      _add(
        issues,
        'ML7_EVIDENCE_CONTENT_VERSION_MISMATCH',
        r'$evidence.contentVersion',
        'Pedagogy evidence belongs to a different MicroFact content version.',
      );
    }
    if (evidence['pedagogyPolicyVersion'] !=
        StartupPedagogyPolicyValidator.requiredPolicyVersion) {
      _add(
        issues,
        'ML7_EVIDENCE_POLICY_DRIFT',
        r'$evidence.pedagogyPolicyVersion',
        'Pedagogy evidence policy version no longer matches ML-7.',
      );
    }

    final fingerprint = Map<String, dynamic>.from(
      evidence['contentFingerprint'] as Map,
    );
    final displayText = display['displayText'] as String;
    final shortVariant = display['shortVariant'] as String?;

    if (fingerprint['displayTextSha256'] !=
        StartupTextMetrics.sha256Text(displayText)) {
      _add(
        issues,
        'ML7_DISPLAY_TEXT_FINGERPRINT_DRIFT',
        r'$evidence.contentFingerprint.displayTextSha256',
        'displayText changed after pedagogy/accessibility review.',
      );
    }

    final expectedShortHash = shortVariant == null
        ? null
        : StartupTextMetrics.sha256Text(shortVariant);
    if (fingerprint['shortVariantSha256'] != expectedShortHash) {
      _add(
        issues,
        'ML7_SHORT_VARIANT_FINGERPRINT_DRIFT',
        r'$evidence.contentFingerprint.shortVariantSha256',
        'shortVariant changed after pedagogy/accessibility review.',
      );
    }

    if (fingerprint['estimatedReadSeconds'] !=
        display['estimatedReadSeconds']) {
      _add(
        issues,
        'ML7_READ_SECONDS_FINGERPRINT_DRIFT',
        r'$evidence.contentFingerprint.estimatedReadSeconds',
        'estimatedReadSeconds changed after pedagogy/accessibility review.',
      );
    }

    final metrics = Map<String, dynamic>.from(evidence['metrics'] as Map);
    final textRules = Map<String, dynamic>.from(policy['textRules'] as Map);
    final wordsPerMinute = textRules['nominalReadingWordsPerMinute'] as int;

    final expectedMetrics = <String, dynamic>{
      'displayWordCount': StartupTextMetrics.wordCount(displayText),
      'displaySentenceCount': StartupTextMetrics.sentenceCount(displayText),
      'computedDisplayReadSeconds': StartupTextMetrics.readSeconds(
        displayText,
        wordsPerMinute,
      ),
      'shortWordCount': shortVariant == null
          ? null
          : StartupTextMetrics.wordCount(shortVariant),
      'shortSentenceCount': shortVariant == null
          ? null
          : StartupTextMetrics.sentenceCount(shortVariant),
      'computedShortReadSeconds': shortVariant == null
          ? null
          : StartupTextMetrics.readSeconds(shortVariant, wordsPerMinute),
    };

    for (final entry in expectedMetrics.entries) {
      if (metrics[entry.key] != entry.value) {
        _add(
          issues,
          'ML7_METRIC_DRIFT',
          r'$evidence.metrics.' + entry.key,
          'Stored startup text metric no longer matches the MicroFact.',
        );
      }
    }
  }

  void _validatePrecisionReview({
    required Map<String, dynamic> microFact,
    required Map<String, dynamic> pedagogyReview,
    required List<MicroFactStartupSuitabilityIssue> issues,
  }) {
    final claim = Map<String, dynamic>.from(microFact['claim'] as Map);
    final needsPrecisionReview =
        claim['safetyCritical'] == true ||
        claim['numericalClaim'] == true ||
        claim['simplificationRisk'] == 'medium' ||
        claim['simplificationRisk'] == 'high';

    if (needsPrecisionReview &&
        (pedagogyReview['precisionPreserved'] != true ||
            pedagogyReview['shortVariantMeaningPreserved'] != true)) {
      _add(
        issues,
        'ML7_PRECISION_REVIEW_REQUIRED',
        r'$evidence.pedagogyReview',
        'Safety-critical, numerical or simplification-sensitive facts require explicit precision and short-copy meaning review.',
      );
    }
  }

  void _validateReviewChronology({
    required Map<String, dynamic> factReview,
    required Map<String, dynamic> pedagogyReview,
    required Map<String, dynamic> accessibilityReview,
    required int maxAgeDays,
    required List<MicroFactStartupSuitabilityIssue> issues,
  }) {
    final factReviewedAt = _parseStrictDate(factReview['reviewedAt']);

    for (final entry in <MapEntry<String, Map<String, dynamic>>>[
      MapEntry('pedagogyReview', pedagogyReview),
      MapEntry('accessibilityReview', accessibilityReview),
    ]) {
      final reviewedAt = _parseStrictDate(entry.value['reviewedAt']);
      final dueAt = _parseStrictDate(entry.value['nextReviewDueAt']);

      if (reviewedAt != null &&
          factReviewedAt != null &&
          reviewedAt.isAfter(factReviewedAt)) {
        _add(
          issues,
          'ML7_REVIEW_AFTER_FACT_REVIEW',
          r'$evidence.' + entry.key + '.reviewedAt',
          'Final MicroFact review cannot predate its startup suitability review.',
        );
      }

      if (dueAt != null &&
          factReviewedAt != null &&
          dueAt.isBefore(factReviewedAt)) {
        _add(
          issues,
          'ML7_EVIDENCE_ALREADY_STALE',
          r'$evidence.' + entry.key + '.nextReviewDueAt',
          'Startup suitability evidence was already stale at final fact review.',
        );
      }

      if (reviewedAt != null && factReviewedAt != null) {
        final ageDays = factReviewedAt.difference(reviewedAt).inDays;
        if (ageDays > maxAgeDays) {
          _add(
            issues,
            'ML7_EVIDENCE_TOO_OLD',
            r'$evidence.' + entry.key + '.reviewedAt',
            'Startup suitability evidence exceeds the frozen maximum age.',
          );
        }
      }
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

  static void _add(
    List<MicroFactStartupSuitabilityIssue> issues,
    String code,
    String path,
    String message,
  ) {
    issues.add(
      MicroFactStartupSuitabilityIssue(
        code: code,
        path: path,
        message: message,
      ),
    );
  }
}
