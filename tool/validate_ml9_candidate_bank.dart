import 'dart:convert';
import 'dart:io';

import 'package:exam_platform/services/micro_learning/micro_fact_claim_gate_validator.dart';
import 'package:exam_platform/services/micro_learning/micro_fact_corpus_integrity_validator.dart';
import 'package:exam_platform/services/micro_learning/micro_fact_schema_validator.dart';
import 'package:exam_platform/services/micro_learning/micro_fact_source_gate_validator.dart';
import 'package:exam_platform/services/micro_learning/startup_text_metrics.dart';

Future<void> main() async {
  const manifestPath =
      'content/micro_learning/curated_bank_manifest_v1.json';
  const bankPolicyPath =
      'content/micro_learning/curated_bank_policy_v1.json';
  const authorityPath =
      'content/micro_learning/authority_registry_v1.json';
  const claimPolicyPath =
      'content/micro_learning/claim_semantics_policy_v1.json';
  const duplicatePolicyPath =
      'content/micro_learning/duplicate_contradiction_policy_v1.json';
  const startupPolicyPath =
      'content/micro_learning/startup_pedagogy_policy_v1.json';

  final requiredPaths = [
    manifestPath,
    bankPolicyPath,
    authorityPath,
    claimPolicyPath,
    duplicatePolicyPath,
    startupPolicyPath,
  ];

  for (final path in requiredPaths) {
    if (!File(path).existsSync()) {
      stderr.writeln('ML-9 required file not found: $path');
      exitCode = 2;
      return;
    }
  }

  final manifest = await _readObject(manifestPath);
  final bankPolicy = await _readObject(bankPolicyPath);
  final authorityRegistry = await _readObject(authorityPath);
  final claimPolicy = await _readObject(claimPolicyPath);
  final duplicatePolicy = await _readObject(duplicatePolicyPath);
  final startupPolicy = await _readObject(startupPolicyPath);

  if (exitCode != 0) return;

  final issues = <String>[];
  final target = bankPolicy['targetFactCount'];
  final slots = manifest['slots'];

  if (target is! int || target != 120) {
    issues.add('ML9_TARGET_COUNT_INVALID: targetFactCount must remain 120.');
  }
  if (slots is! List || slots.length != target) {
    issues.add(
      'ML9_SLOT_COUNT_INVALID: manifest must contain exactly $target slots.',
    );
  }

  final slotIds = <String>{};
  final factIds = <String>{};
  final facts = <Map<String, dynamic>>[];

  if (slots is List) {
    for (var i = 0; i < slots.length; i++) {
      final rawSlot = slots[i];
      if (rawSlot is! Map) {
        issues.add('ML9_SLOT_INVALID: slot $i is not an object.');
        continue;
      }
      final slot = Map<String, dynamic>.from(rawSlot);
      final slotId = slot['slotId'];
      final factId = slot['microFactId'];
      final candidatePath = slot['candidatePath'];

      if (slotId is! String || !slotIds.add(slotId)) {
        issues.add('ML9_SLOT_ID_DUPLICATE_OR_INVALID at slot $i.');
      }
      if (factId is! String || !factIds.add(factId)) {
        issues.add('ML9_FACT_ID_DUPLICATE_OR_INVALID at slot $i.');
      }

      if (candidatePath == null) {
        if (slot['state'] != 'planned') {
          issues.add(
            'ML9_UNPOPULATED_SLOT_STATE_INVALID: $factId has no candidate path '
            'but state is ${slot['state']}.',
          );
        }
        continue;
      }

      if (candidatePath is! String || candidatePath.isEmpty) {
        issues.add('ML9_CANDIDATE_PATH_INVALID for $factId.');
        continue;
      }
      if (slot['state'] != 'candidate_review') {
        issues.add(
          'ML9_CANDIDATE_STATE_INVALID: $factId must remain candidate_review '
          'during ML-9B.',
        );
      }

      final file = File(candidatePath);
      if (!file.existsSync()) {
        issues.add('ML9_CANDIDATE_FILE_MISSING: $candidatePath');
        continue;
      }

      final fact = await _readObject(candidatePath);
      if (fact.isEmpty && exitCode != 0) return;

      if (fact['microFactId'] != factId) {
        issues.add(
          'ML9_SLOT_FACT_ID_MISMATCH: $candidatePath does not match $factId.',
        );
      }
      if (fact['category'] != slot['microFactCategory']) {
        issues.add(
          'ML9_SLOT_CATEGORY_MISMATCH: $factId category does not match manifest.',
        );
      }

      _validateCandidateLifecycle(fact, issues);
      _validateSchema(fact, candidatePath, issues);
      _validateSource(
        fact,
        candidatePath,
        authorityRegistry,
        issues,
      );
      _validateClaim(
        fact,
        candidatePath,
        authorityRegistry,
        claimPolicy,
        issues,
      );
      _validateStartupText(
        fact,
        candidatePath,
        startupPolicy,
        issues,
      );

      facts.add(fact);
    }
  }

  final declaredCandidateCount = manifest['candidateFactCount'];
  if (declaredCandidateCount != null &&
      declaredCandidateCount != facts.length) {
    issues.add(
      'ML9_CANDIDATE_COUNT_DRIFT: manifest declares '
      '$declaredCandidateCount but ${facts.length} candidate files are bound.',
    );
  }

  final corpusResult = const MicroFactCorpusIntegrityValidator().validate(
    facts: facts,
    policy: duplicatePolicy,
  );
  for (final issue in corpusResult.issues) {
    issues.add('ML8_CORPUS: $issue');
  }

  if (issues.isNotEmpty) {
    stderr.writeln(
      'ML-9 CANDIDATE BANK INVALID with ${issues.length} issue(s):',
    );
    for (final issue in issues) {
      stderr.writeln(' - $issue');
    }
    exitCode = 1;
    return;
  }

  final pairCount = facts.length * (facts.length - 1) ~/ 2;
  stdout.writeln('ML-9 CANDIDATE BANK VALID');
  stdout.writeln('Candidate facts: ${facts.length}');
  stdout.writeln('Pair comparisons: $pairCount');
  stdout.writeln(
    'ML-8 review candidates: ${corpusResult.reviewCandidates.length}',
  );
  stdout.writeln(
    'ML-8 concentration signals: ${corpusResult.concentrationSignals.length}',
  );
  stdout.writeln('Publication approvals asserted by this tool: 0');
}

void _validateCandidateLifecycle(
  Map<String, dynamic> fact,
  List<String> issues,
) {
  final id = fact['microFactId'];
  if (fact['status'] != 'review') {
    issues.add('ML9_LIFECYCLE_STATUS: $id must remain in review during ML-9B.');
  }

  final runtime = fact['runtime'];
  if (runtime is! Map || runtime['startupEligible'] != false) {
    issues.add('ML9_STARTUP_PREMATURE: $id cannot be startup eligible.');
  }

  final review = fact['review'];
  if (review is! Map) {
    issues.add('ML9_REVIEW_OBJECT_INVALID: $id review object missing.');
    return;
  }

  for (final key in [
    'technicalStatus',
    'sourceStatus',
    'pedagogyStatus',
    'copyrightStatus',
    'uiStatus',
    'humanTechnicalStatus',
  ]) {
    if (review[key] != 'pending') {
      issues.add(
        'ML9_REVIEW_PREMATURE: $id $key must remain pending until '
        'genuine review occurs.',
      );
    }
  }

  if (review['reviewedAt'] != null || review['nextReviewDueAt'] != null) {
    issues.add(
      'ML9_REVIEW_DATE_PREMATURE: $id cannot carry final review dates in ML-9B.',
    );
  }
}

void _validateSchema(
  Map<String, dynamic> fact,
  String path,
  List<String> issues,
) {
  final result = MicroFactSchemaValidator().validateMap(fact);
  for (final issue in result.issues) {
    issues.add('ML2_SCHEMA $path: $issue');
  }
}

void _validateSource(
  Map<String, dynamic> fact,
  String path,
  Map<String, dynamic> authorityRegistry,
  List<String> issues,
) {
  final result = const MicroFactSourceGateValidator().validateMaps(
    microFact: fact,
    authorityRegistry: authorityRegistry,
  );
  for (final issue in result.issues) {
    issues.add('ML3_SOURCE $path: $issue');
  }
}

void _validateClaim(
  Map<String, dynamic> fact,
  String path,
  Map<String, dynamic> authorityRegistry,
  Map<String, dynamic> claimPolicy,
  List<String> issues,
) {
  final result = const MicroFactClaimGateValidator().validateMaps(
    microFact: fact,
    authorityRegistry: authorityRegistry,
    claimPolicy: claimPolicy,
  );
  for (final issue in result.issues) {
    issues.add('ML4_CLAIM $path: $issue');
  }
}

void _validateStartupText(
  Map<String, dynamic> fact,
  String path,
  Map<String, dynamic> policy,
  List<String> issues,
) {
  final display = Map<String, dynamic>.from(fact['display'] as Map);
  final category = fact['category'] as String;
  final full = display['displayText'] as String;
  final short = display['shortVariant'] as String?;
  final estimated = display['estimatedReadSeconds'] as int;

  final textRules = Map<String, dynamic>.from(policy['textRules'] as Map);
  final fullRules =
      Map<String, dynamic>.from(textRules['displayText'] as Map);
  final shortRules =
      Map<String, dynamic>.from(textRules['shortVariant'] as Map);
  final plain =
      Map<String, dynamic>.from(policy['plainTextRules'] as Map);
  final abbreviation =
      Map<String, dynamic>.from(policy['abbreviationRules'] as Map);
  final visual =
      Map<String, dynamic>.from(policy['visualIndependenceRules'] as Map);

  final wpm = textRules['nominalReadingWordsPerMinute'] as int;
  final tolerance = textRules['estimatedReadSecondsTolerance'] as int;
  final fullWords = StartupTextMetrics.wordCount(full);
  final fullSentences = StartupTextMetrics.sentenceCount(full);
  final fullRead = StartupTextMetrics.readSeconds(full, wpm);

  if (fullWords < (fullRules['minWords'] as int) ||
      fullWords > (fullRules['maxWords'] as int) ||
      full.length > (fullRules['maxCharacters'] as int) ||
      fullSentences > (fullRules['maxSentences'] as int) ||
      estimated > (fullRules['maxEstimatedReadSeconds'] as int)) {
    issues.add('ML7_TEXT_FULL_LIMIT $path');
  }
  if ((estimated - fullRead).abs() > tolerance) {
    issues.add('ML7_TEXT_READ_TIME $path');
  }

  if (short == null || short.trim().isEmpty) {
    issues.add('ML7_TEXT_SHORT_REQUIRED $path');
  } else {
    final shortWords = StartupTextMetrics.wordCount(short);
    final shortSentences = StartupTextMetrics.sentenceCount(short);
    final shortRead = StartupTextMetrics.readSeconds(short, wpm);

    if (shortWords < (shortRules['minWords'] as int) ||
        shortWords > (shortRules['maxWords'] as int) ||
        short.length > (shortRules['maxCharacters'] as int) ||
        shortSentences > (shortRules['maxSentences'] as int) ||
        shortRead > (shortRules['maxComputedReadSeconds'] as int)) {
      issues.add('ML7_TEXT_SHORT_LIMIT $path');
    }

    if ((shortRules['mustBeShorterThanDisplayText'] == true &&
            shortWords >= fullWords) ||
        shortWords / fullWords >
            (shortRules['maxWordRatioToDisplay'] as num).toDouble()) {
      issues.add('ML7_TEXT_SHORT_RATIO $path');
    }
  }

  final combined = short == null ? full : '$full $short';

  if (plain['newlinesAllowed'] == false &&
      StartupTextMetrics.hasNewline(combined)) {
    issues.add('ML7_TEXT_NEWLINE $path');
  }
  if (plain['tabsAllowed'] == false &&
      StartupTextMetrics.hasTab(combined)) {
    issues.add('ML7_TEXT_TAB $path');
  }
  if (plain['htmlAllowed'] == false &&
      StartupTextMetrics.hasHtml(combined)) {
    issues.add('ML7_TEXT_HTML $path');
  }
  if (plain['markdownLinksAllowed'] == false &&
      StartupTextMetrics.hasMarkdownLink(combined)) {
    issues.add('ML7_TEXT_MARKDOWN_LINK $path');
  }
  if (plain['rawUrlsAllowed'] == false &&
      StartupTextMetrics.hasRawUrl(combined)) {
    issues.add('ML7_TEXT_RAW_URL $path');
  }
  if (plain['emojiAllowed'] == false &&
      StartupTextMetrics.hasEmoji(combined)) {
    issues.add('ML7_TEXT_EMOJI $path');
  }
  if (plain['bulletPrefixesAllowed'] == false &&
      StartupTextMetrics.hasBulletPrefix(combined)) {
    issues.add('ML7_TEXT_BULLET $path');
  }
  if (plain['sourceLabelPrefixesAllowed'] == false &&
      StartupTextMetrics.hasSourceLabelPrefix(combined)) {
    issues.add('ML7_TEXT_SOURCE_LABEL $path');
  }
  if (plain['repeatedWhitespaceAllowed'] == false &&
      StartupTextMetrics.hasRepeatedWhitespace(combined)) {
    issues.add('ML7_TEXT_WHITESPACE $path');
  }

  final allowedUpper = (abbreviation['approvedUppercaseTokens'] as List)
      .whereType<String>()
      .toSet();
  final unknownUpper =
      StartupTextMetrics.uppercaseTokens(combined).difference(allowedUpper);
  if (unknownUpper.length >
      (abbreviation['maxUnknownUppercaseTokens'] as int)) {
    issues.add(
      'ML7_TEXT_ABBREVIATION $path: ${unknownUpper.toList()..sort()}',
    );
  }

  final blockedPhrases =
      (visual['blockedPhrases'] as List).whereType<String>();
  if (StartupTextMetrics.containsAnyPhrase(combined, blockedPhrases)) {
    issues.add('ML7_TEXT_VISUAL_DEPENDENCY $path');
  }

  final allowedQuestionCategories =
      (fullRules['allowQuestionMarkForCategories'] as List?)
          ?.whereType<String>()
          .toSet() ??
      const <String>{};
  if (combined.contains('?') &&
      !allowedQuestionCategories.contains(category)) {
    issues.add('ML7_TEXT_QUESTION_MARK $path');
  }
}

Future<Map<String, dynamic>> _readObject(String path) async {
  try {
    final decoded = jsonDecode(await File(path).readAsString());
    if (decoded is Map<String, dynamic>) return decoded;
  } on FormatException catch (error) {
    stderr.writeln('Invalid JSON in $path: ${error.message}');
    exitCode = 2;
    return <String, dynamic>{};
  }

  stderr.writeln('JSON root must be an object: $path');
  exitCode = 2;
  return <String, dynamic>{};
}
