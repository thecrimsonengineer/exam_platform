import 'dart:convert';

import '../../models/question.dart';
import '../../models/question_quality_evidence.dart';
import '../../models/study_content.dart';
import '../dqg300_question_quality_validator.dart';
import '../study_content/content_repository_service.dart';
import '../ultra_hard_question_contract.dart';
import 'studio_bulk_question_publish_service.dart';
import 'studio_question_import_service.dart';
import 'studio_question_service.dart';

class StudioUltraHardQuestionPlan {
  const StudioUltraHardQuestionPlan({
    required this.sourceContent,
    required this.questions,
    required this.qualityEvidenceByQuestionId,
    required this.questionCountBySubtopic,
  });

  final StudyContent sourceContent;
  final List<Question> questions;
  final Map<int, QuestionQualityEvidence> qualityEvidenceByQuestionId;
  final Map<String, int> questionCountBySubtopic;

  int get questionCount => questions.length;
  int get subtopicCount => questionCountBySubtopic.length;
}

class StudioUltraHardPublishResult {
  const StudioUltraHardPublishResult({
    required this.publishedContent,
    required this.questionCount,
    required this.linkedSubtopicCount,
    required this.reusedQuestionCount,
  });

  final StudyContent publishedContent;
  final int questionCount;
  final int linkedSubtopicCount;
  final int reusedQuestionCount;
}

/// Separate strict DQG300 path for Ultra Hard questions.
/// The legacy bulk importer remains unchanged and continues to use H0.3.
class StudioUltraHardQuestionPublishService {
  StudioUltraHardQuestionPublishService({
    required StudioQuestionService questionService,
    ContentRepositoryService? contentRepositoryService,
    StudioQuestionImportService? importer,
  }) : _questionService = questionService,
       _contentRepositoryService = contentRepositoryService,
       _importer = importer ?? const StudioQuestionImportService();

  final StudioQuestionService _questionService;
  final ContentRepositoryService? _contentRepositoryService;
  final StudioQuestionImportService _importer;

  static const Dqg300QuestionQualityValidator _validator =
      Dqg300QuestionQualityValidator();

  StudioUltraHardQuestionPlan prepareFromJsonText({
    required String input,
    required StudyContent content,
  }) {
    return prepareFromDecoded(decoded: jsonDecode(input), content: content);
  }

  StudioUltraHardQuestionPlan prepareFromDecoded({
    required dynamic decoded,
    required StudyContent content,
  }) {
    final root = _asMap(decoded, label: 'Ultra Hard package');
    final declaredCompetency = _string(
      root['competencyId'] ?? root['competency_id'],
    );

    if (declaredCompetency.isNotEmpty &&
        declaredCompetency != content.competencyId.trim()) {
      throw FormatException(
        'Ultra Hard JSON declares competencyId "$declaredCompetency", '
        'but the selected competency is "${content.competencyId}".',
      );
    }

    final rawQuestions = _objectList(
      root['questions'] ?? root['items'] ?? root['data'],
      label: 'questions',
    );

    if (rawQuestions.isEmpty) {
      throw const FormatException(
        'Ultra Hard JSON must contain at least one question.',
      );
    }

    final topicsById = <String, StudyTopic>{
      for (final topic in content.topics) topic.id.trim(): topic,
    };
    final subtopicsById = <String, StudySubtopic>{};
    final parentBySubtopic = <String, StudyTopic>{};

    for (final topic in content.topics) {
      for (final subtopic in topic.subtopics) {
        subtopicsById[subtopic.id.trim()] = subtopic;
        parentBySubtopic[subtopic.id.trim()] = topic;
      }
    }

    if (subtopicsById.isEmpty) {
      throw const FormatException(
        'The selected competency does not contain any Subtopics.',
      );
    }

    final questions = <Question>[];
    final evidenceById = <int, QuestionQualityEvidence>{};
    final counts = <String, int>{
      for (final id in subtopicsById.keys) id: 0,
    };
    final normalizedStems = <String>{};

    for (var index = 0; index < rawQuestions.length; index++) {
      final raw = rawQuestions[index];
      final number = index + 1;
      final topicId = _string(raw['topicId'] ?? raw['topic_id']);
      final subtopicId = _string(raw['subtopicId'] ?? raw['subtopic_id']);

      if (topicId.isEmpty || subtopicId.isEmpty) {
        throw FormatException(
          'Ultra Hard question $number must declare topicId and subtopicId.',
        );
      }

      final topic = topicsById[topicId];
      final subtopic = subtopicsById[subtopicId];

      if (topic == null || subtopic == null) {
        throw FormatException(
          'Ultra Hard question $number references an unknown Topic/Subtopic.',
        );
      }

      if (parentBySubtopic[subtopicId]?.id != topicId) {
        throw FormatException(
          'Ultra Hard question $number maps "$subtopicId" to "$topicId", '
          'but that Subtopic belongs to "${parentBySubtopic[subtopicId]?.id}".',
        );
      }

      final rawQuestion = Map<String, dynamic>.from(raw)
        ..remove('id')
        ..remove('status')
        ..remove('dqg300Evidence')
        ..remove('dqg300_evidence');

      final question = _importer
          .fromDecoded(
            decoded: <Map<String, dynamic>>[rawQuestion],
            nextId: _questionService.nextQuestionId,
            content: content,
            topic: topic,
            subtopic: subtopic,
            quizId:
                StudioBulkQuestionPublishService.stableQuizIdForSubtopicId(
                  subtopicId,
                ),
          )
          .single;

      final normalizedStem = _normalize(question.question);
      if (normalizedStem.isEmpty || !normalizedStems.add(normalizedStem)) {
        throw FormatException(
          'Ultra Hard question $number has an empty or duplicate stem.',
        );
      }

      final evidenceMap = _asMap(
        raw['dqg300Evidence'] ?? raw['dqg300_evidence'],
        label: 'dqg300Evidence for question $number',
      );
      final evidence = _parseEvidence(evidenceMap);

      final taggedQuestion = Question.fromJson({
        ...question.toJson(),
        'difficulty': 'Hard',
        'tags': <String>{
          ...question.tags,
          UltraHardQuestionContract.classificationTag,
        }.toList(),
      });

      final result = _validator.validate(
        question: taggedQuestion,
        evidence: evidence,
      );

      if (!result.isPublishable ||
          result.passedRuleCount != 300 ||
          result.failedRuleCount != 0 ||
          result.dqs != 100) {
        throw FormatException(
          'Ultra Hard question $number failed DQG300: '
          '${result.passedRuleCount}/300 passed, '
          '${result.failedRuleCount} failed, DQS ${result.dqs}/100.',
        );
      }

      questions.add(taggedQuestion);
      evidenceById[taggedQuestion.id] = evidence;
      counts[subtopicId] = (counts[subtopicId] ?? 0) + 1;
    }

    final insufficient =
        counts.entries.where((entry) => entry.value < 5).toList()
          ..sort((a, b) => a.key.compareTo(b.key));

    if (insufficient.isNotEmpty) {
      throw FormatException(
        'Ultra Hard coverage gate failed. Every Subtopic requires at least '
        '5 DQG300-passing questions. Missing coverage:\n'
        '${insufficient.map((e) => '${e.key}: ${e.value}/5').join('\n')}',
      );
    }

    return StudioUltraHardQuestionPlan(
      sourceContent: content,
      questions: List<Question>.unmodifiable(questions),
      qualityEvidenceByQuestionId:
          Map<int, QuestionQualityEvidence>.unmodifiable(evidenceById),
      questionCountBySubtopic: Map<String, int>.unmodifiable(counts),
    );
  }

  Future<StudioUltraHardPublishResult> publishAndLink(
    StudioUltraHardQuestionPlan plan,
  ) async {
    final contentRepositoryService = _contentRepositoryService;
    if (contentRepositoryService == null) {
      throw StateError(
        'A content repository service is required for Ultra Hard publication.',
      );
    }

    final source = plan.sourceContent;
    final workingContent = source.status.trim().toLowerCase() == 'draft'
        ? source
        : await contentRepositoryService.createRevision(source);

    final preparedQuestions = plan.questions
        .map(
          (question) => Question.fromJson({
            ...question.toJson(),
            'quizId':
                StudioBulkQuestionPublishService.stableQuizIdForSubtopicId(
                  question.subtopicId,
                ),
            'contentPackageId': workingContent.id,
            'status': 'draft',
          }),
        )
        .toList(growable: false);

    final evidenceForPrepared = <int, QuestionQualityEvidence>{
      for (final question in preparedQuestions)
        question.id: plan.qualityEvidenceByQuestionId[question.id]!,
    };

    final linkedTopics = workingContent.topics.map((topic) {
      final linkedSubtopics = topic.subtopics.map((subtopic) {
        return subtopic.copyWith(
          quizzes: <QuizReference>[
            QuizReference(
              quizId:
                  StudioBulkQuestionPublishService.stableQuizIdForSubtopicId(
                    subtopic.id,
                  ),
            ),
          ],
        );
      }).toList();

      return topic.copyWith(subtopics: linkedSubtopics);
    }).toList();

    final linkedContent = workingContent.copyWith(
      status: 'draft',
      topics: linkedTopics,
    );

    final contentErrors = await contentRepositoryService.validatePackage(
      linkedContent,
    );
    if (contentErrors.isNotEmpty) {
      throw StateError(
        'Ultra Hard publish is blocked because linked content failed '
        'validation:\n${contentErrors.join('\n')}',
      );
    }

    final publishResult = await _questionService.publishPreparedUltraHardBatch(
      preparedQuestions,
      qualityEvidenceByQuestionId: evidenceForPrepared,
    );

    await contentRepositoryService.saveDraft(linkedContent);
    await contentRepositoryService.submitForReview(linkedContent);
    await contentRepositoryService.validateAndMark(linkedContent);
    await contentRepositoryService.publish(linkedContent);

    return StudioUltraHardPublishResult(
      publishedContent: linkedContent.copyWith(status: 'published'),
      questionCount: preparedQuestions.length,
      linkedSubtopicCount: plan.questionCountBySubtopic.length,
      reusedQuestionCount: publishResult.reusedQuestionCount,
    );
  }

  QuestionQualityEvidence _parseEvidence(Map<String, dynamic> map) {
    return QuestionQualityEvidence(
      difficultyLevel: _requiredString(map, 'difficultyLevel'),
      distractors: _objectList(map['distractors'], label: 'distractors')
          .map(_parseDistractor)
          .toList(growable: false),
      decisiveScenarioFacts: _stringList(map['decisiveScenarioFacts']),
      materialCriteria: _stringList(map['materialCriteria']),
      keySatisfiedCriteria: _stringList(map['keySatisfiedCriteria']),
      distractorFailedCriteria: _intStringListMap(
        map['distractorFailedCriteria'],
      ),
      criterionMatrixComplete: _requiredBool(map, 'criterionMatrixComplete'),
      keySuperiorityProof: _intStringMap(map['keySuperiorityProof']),
      keyCompleteness: _stringBoolMap(map['keyCompleteness']),
      defensibleBestAnswerCount:
          _requiredInt(map, 'defensibleBestAnswerCount'),
      reviewComplete: _requiredBool(map, 'reviewComplete'),
      manualOverrideRequested: _requiredBool(map, 'manualOverrideRequested'),
      unresolvedBlockCount: _requiredInt(map, 'unresolvedBlockCount'),
      unresolvedFailCount: _requiredInt(map, 'unresolvedFailCount'),
      unresolvedWarningCount: _requiredInt(map, 'unresolvedWarningCount'),
      keyRequiresNoUnstatedAssumption:
          _requiredBool(map, 'keyRequiresNoUnstatedAssumption'),
      assumptionsDocumented: _requiredBool(map, 'assumptionsDocumented'),
      keyAssumptionsSupported: _requiredBool(map, 'keyAssumptionsSupported'),
      noEquivalenceFromUnstatedAssumption:
          _requiredBool(map, 'noEquivalenceFromUnstatedAssumption'),
      assumptions: _objectList(map['assumptions'], label: 'assumptions')
          .map(
            (item) => AssumptionEvidence(
              subject: _requiredString(item, 'subject'),
              assumptionUsed: _requiredString(item, 'assumptionUsed'),
              scenarioSupport: _requiredString(item, 'scenarioSupport'),
              supported: _requiredBool(item, 'supported'),
              intentionalDistractorTrap:
                  _requiredBool(item, 'intentionalDistractorTrap'),
            ),
          )
          .toList(growable: false),
      authoritativeSources: _stringList(map['authoritativeSources']),
      sourceAuthorityVerified: _requiredBool(map, 'sourceAuthorityVerified'),
      sourceSupportsKey: _requiredBool(map, 'sourceSupportsKey'),
      noUnsupportedMicroscopicDistinction:
          _requiredBool(map, 'noUnsupportedMicroscopicDistinction'),
      ambiguityDetected: _requiredBool(map, 'ambiguityDetected'),
      semanticDuplicateOptionsDetected:
          _requiredBool(map, 'semanticDuplicateOptionsDetected'),
      answerPositionCueDetected:
          _requiredBool(map, 'answerPositionCueDetected'),
      answerKeyVerified: _requiredBool(map, 'answerKeyVerified'),
      stemSufficient: _requiredBool(map, 'stemSufficient'),
      testsIntendedCompetency: _requiredBool(map, 'testsIntendedCompetency'),
      numericQuestion: _requiredBool(map, 'numericQuestion'),
      wrongLevelCorrectnessApplicable:
          _requiredBool(map, 'wrongLevelCorrectnessApplicable'),
      wrongLevelDistinctionDocumented:
          _requiredBool(map, 'wrongLevelDistinctionDocumented'),
      sophisticationParityApplicable:
          _requiredBool(map, 'sophisticationParityApplicable'),
      sophisticationParitySatisfied:
          _requiredBool(map, 'sophisticationParitySatisfied'),
      advancedDistractorPresentWhenApplicable:
          _requiredBool(map, 'advancedDistractorPresentWhenApplicable'),
      optionSurfaceMetrics:
          _objectList(
            map['optionSurfaceMetrics'],
            label: 'optionSurfaceMetrics',
          )
              .map(
                (item) => OptionSurfaceMetrics(
                  optionIndex: _requiredInt(item, 'optionIndex'),
                  characterCount: _requiredInt(item, 'characterCount'),
                  wordCount: _requiredInt(item, 'wordCount'),
                  clauseCount: _requiredInt(item, 'clauseCount'),
                  technicalTermCount: _requiredInt(
                    item,
                    'technicalTermCount',
                  ),
                  qualifierCount: _requiredInt(item, 'qualifierCount'),
                ),
              )
              .toList(growable: false),
      noMaterialLengthCue: _requiredBool(map, 'noMaterialLengthCue'),
      ruleEvidence: _parseRuleEvidence(map['ruleEvidence']),
    );
  }

  DistractorQualityEvidence _parseDistractor(Map<String, dynamic> map) {
    return DistractorQualityEvidence(
      optionIndex: _requiredInt(map, 'optionIndex'),
      role: _requiredString(map, 'role'),
      difficultyLevel: _requiredString(map, 'difficultyLevel'),
      plausibilityScore: _requiredInt(map, 'plausibilityScore'),
      truthComponentScore: _requiredInt(map, 'truthComponentScore'),
      confusabilityScore: _requiredInt(map, 'confusabilityScore'),
      family: _requiredString(map, 'family'),
      familyJustification: _string(map['familyJustification']),
      misconceptionFingerprint:
          _requiredString(map, 'misconceptionFingerprint'),
      targetedMisconception: _requiredString(map, 'targetedMisconception'),
      whyTempting: _requiredString(map, 'whyTempting'),
      fatalFlaw: _requiredString(map, 'fatalFlaw'),
      scenarioEvidence: _stringList(map['scenarioEvidence']),
      scenarioAnchorsValid: _requiredBool(map, 'scenarioAnchorsValid'),
      technicalTruth: _requiredString(map, 'technicalTruth'),
      keyDifference: _requiredString(map, 'keyDifference'),
      counterfactualToBecomeCorrect:
          _requiredString(map, 'counterfactualToBecomeCorrect'),
      sameTechnicalUniverse: _requiredBool(map, 'sameTechnicalUniverse'),
      sameProfessionalLevel: _requiredBool(map, 'sameProfessionalLevel'),
      substantiallyTechnicallyCorrect:
          _requiredBool(map, 'substantiallyTechnicallyCorrect'),
      professionalTerminologyValid:
          _requiredBool(map, 'professionalTerminologyValid'),
      addressesActualDecisionOrHazard:
          _requiredBool(map, 'addressesActualDecisionOrHazard'),
      credibleInProfessionalPractice:
          _requiredBool(map, 'credibleInProfessionalPractice'),
      singleFatalFlaw: _requiredBool(map, 'singleFatalFlaw'),
      multipleUnrelatedDefectsDetected:
          _requiredBool(map, 'multipleUnrelatedDefectsDetected'),
      sophisticatedReasoningPath:
          _requiredBool(map, 'sophisticatedReasoningPath'),
      counterfactualMinimalAndPlausible:
          _requiredBool(map, 'counterfactualMinimalAndPlausible'),
      grammarParallel: _requiredBool(map, 'grammarParallel'),
      specificityAndDetailParallel:
          _requiredBool(map, 'specificityAndDetailParallel'),
      lengthAndClauseParallel: _requiredBool(map, 'lengthAndClauseParallel'),
      terminologyUnitsPrecisionParallel:
          _requiredBool(map, 'terminologyUnitsPrecisionParallel'),
      conditionalWordingParallel:
          _requiredBool(map, 'conditionalWordingParallel'),
      linguisticCueDetected: _requiredBool(map, 'linguisticCueDetected'),
      keywordLeakageDetected: _requiredBool(map, 'keywordLeakageDetected'),
      absoluteLanguageShortcutDetected:
          _requiredBool(map, 'absoluteLanguageShortcutDetected'),
      nonTechnicalEliminationShortcutDetected:
          _requiredBool(map, 'nonTechnicalEliminationShortcutDetected'),
      sourceSupportsRejectionDistinction:
          _requiredBool(map, 'sourceSupportsRejectionDistinction'),
      smeRejectionProof: _requiredString(map, 'smeRejectionProof'),
      distractorCalculationPath: _string(map['distractorCalculationPath']),
      calculationConsistent: _requiredBool(map, 'calculationConsistent'),
    );
  }

  Map<String, DqgEvidenceRecord> _parseRuleEvidence(dynamic value) {
    final map = _asMap(value, label: 'ruleEvidence');
    return map.map((key, raw) {
      final item = _asMap(raw, label: 'ruleEvidence.$key');
      return MapEntry(
        key,
        DqgEvidenceRecord(
          ruleId: _requiredString(item, 'ruleId'),
          satisfied: _requiredBool(item, 'satisfied'),
          proof: _requiredString(item, 'proof'),
          evidenceRefs: _stringList(item['evidenceRefs']),
          reviewerId: _requiredString(item, 'reviewerId'),
          reviewedAtIso: _requiredString(item, 'reviewedAtIso'),
        ),
      );
    });
  }

  Map<String, dynamic> _asMap(dynamic value, {required String label}) {
    if (value is! Map) {
      throw FormatException('$label must be a JSON object.');
    }
    return Map<String, dynamic>.from(value);
  }

  List<Map<String, dynamic>> _objectList(
    dynamic value, {
    required String label,
  }) {
    if (value is! List) {
      throw FormatException('$label must be a JSON array.');
    }

    return value.map((item) {
      if (item is! Map) {
        throw FormatException('$label contains a non-object item.');
      }
      return Map<String, dynamic>.from(item);
    }).toList(growable: false);
  }

  String _requiredString(Map<String, dynamic> map, String key) {
    final value = _string(map[key]);
    if (value.isEmpty) {
      throw FormatException('DQG300 evidence field "$key" is required.');
    }
    return value;
  }

  bool _requiredBool(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is! bool) {
      throw FormatException('DQG300 evidence field "$key" must be boolean.');
    }
    return value;
  }

  int _requiredInt(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    throw FormatException('DQG300 evidence field "$key" must be numeric.');
  }

  String _string(dynamic value) => value?.toString().trim() ?? '';

  List<String> _stringList(dynamic value) {
    if (value is! List) {
      throw const FormatException(
        'DQG300 evidence string-list field must be a JSON array.',
      );
    }
    return value.map((item) => _string(item)).toList(growable: false);
  }

  Map<int, List<String>> _intStringListMap(dynamic value) {
    final map = _asMap(value, label: 'distractorFailedCriteria');
    return {
      for (final entry in map.entries)
        int.parse(entry.key): _stringList(entry.value),
    };
  }

  Map<int, String> _intStringMap(dynamic value) {
    final map = _asMap(value, label: 'keySuperiorityProof');
    return {
      for (final entry in map.entries) int.parse(entry.key): _string(entry.value),
    };
  }

  Map<String, bool> _stringBoolMap(dynamic value) {
    final map = _asMap(value, label: 'keyCompleteness');
    return map.map((key, raw) {
      if (raw is! bool) {
        throw FormatException('keyCompleteness.$key must be boolean.');
      }
      return MapEntry(key, raw);
    });
  }

  String _normalize(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9 ]'), '')
      .replaceAll(RegExp(r'\s+'), ' ');
}
