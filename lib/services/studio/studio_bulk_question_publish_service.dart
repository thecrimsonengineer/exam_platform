import 'dart:convert';

import '../../models/question.dart';
import '../../models/study_content.dart';
import '../study_content/content_repository_service.dart';
import 'studio_question_import_service.dart';
import 'studio_question_service.dart';

class StudioBulkQuestionPlan {
  final StudyContent sourceContent;
  final List<Question> questions;
  final Map<String, int> questionCountBySubtopic;

  const StudioBulkQuestionPlan({
    required this.sourceContent,
    required this.questions,
    required this.questionCountBySubtopic,
  });

  int get questionCount => questions.length;

  int get subtopicCount => questionCountBySubtopic.length;

  int get minimumRequiredQuestionCount => subtopicCount * 5;
}

class StudioBulkQuestionPublishResult {
  final StudyContent publishedContent;
  final int questionCount;
  final int linkedSubtopicCount;
  final int reusedQuestionCount;

  const StudioBulkQuestionPublishResult({
    required this.publishedContent,
    required this.questionCount,
    required this.linkedSubtopicCount,
    required this.reusedQuestionCount,
  });
}

/// Competency-wide managed-question workflow.
///
/// One JSON package may contain questions for every Topic/Subtopic in a
/// StudyContent competency. Placement is declared by canonical topicId and
/// subtopicId; quiz IDs and content-package IDs are derived by the Studio.
///
/// The workflow is intentionally fail-closed:
/// - every question must pass the current H0.3 quality gate;
/// - every content subtopic must receive at least five questions;
/// - unknown or mismatched Topic/Subtopic IDs are rejected;
/// - duplicate stems in the incoming package are rejected;
/// - existing managed-question identity rules remain authoritative.
///
/// After preflight, publishAndLink:
/// 1. creates a Draft revision when the source content is not Draft;
/// 2. publishes all prepared questions through QuestionBankService;
/// 3. links one stable quiz ID to every Subtopic;
/// 4. advances the content revision Draft -> Review -> Validated -> Published.
class StudioBulkQuestionPublishService {
  StudioBulkQuestionPublishService({
    required StudioQuestionService questionService,
    ContentRepositoryService? contentRepositoryService,
    StudioQuestionImportService? importer,
  }) : _questionService = questionService,
       _contentRepositoryService = contentRepositoryService,
       _importer = importer ?? const StudioQuestionImportService();

  final StudioQuestionService _questionService;
  final ContentRepositoryService? _contentRepositoryService;
  final StudioQuestionImportService _importer;

  StudioBulkQuestionPlan prepareFromJsonText({
    required String input,
    required StudyContent content,
  }) {
    final decoded = jsonDecode(input);
    return prepareFromDecoded(decoded: decoded, content: content);
  }

  StudioBulkQuestionPlan prepareFromDecoded({
    required dynamic decoded,
    required StudyContent content,
  }) {
    _validateTopLevelContext(decoded, content);

    final rawQuestions = _extractQuestionObjects(decoded);
    if (rawQuestions.isEmpty) {
      throw const FormatException(
        'No question objects were found in the bulk JSON package.',
      );
    }

    final topicsById = <String, StudyTopic>{
      for (final topic in content.topics) topic.id.trim(): topic,
    };

    final subtopicParent = <String, StudyTopic>{};
    final subtopicsById = <String, StudySubtopic>{};

    for (final topic in content.topics) {
      for (final subtopic in topic.subtopics) {
        final subtopicId = subtopic.id.trim();
        subtopicParent[subtopicId] = topic;
        subtopicsById[subtopicId] = subtopic;
      }
    }

    if (subtopicsById.isEmpty) {
      throw const FormatException(
        'The selected competency does not contain any Subtopics.',
      );
    }

    final questions = <Question>[];
    final normalizedStems = <String>{};
    final counts = <String, int>{
      for (final subtopicId in subtopicsById.keys) subtopicId: 0,
    };

    for (var index = 0; index < rawQuestions.length; index++) {
      final raw = rawQuestions[index];
      final topicId = _string(raw['topicId'] ?? raw['topic_id']);
      final subtopicId = _string(raw['subtopicId'] ?? raw['subtopic_id']);

      if (topicId.isEmpty || subtopicId.isEmpty) {
        throw FormatException(
          'Question ${index + 1} must declare both topicId and subtopicId.',
        );
      }

      final topic = topicsById[topicId];
      final subtopic = subtopicsById[subtopicId];

      if (topic == null) {
        throw FormatException(
          'Question ${index + 1} references unknown Topic ID "$topicId".',
        );
      }

      if (subtopic == null) {
        throw FormatException(
          'Question ${index + 1} references unknown Subtopic ID "$subtopicId".',
        );
      }

      if (subtopicParent[subtopicId]?.id != topic.id) {
        throw FormatException(
          'Question ${index + 1} maps Subtopic "$subtopicId" to Topic '
          '"$topicId", but that Subtopic belongs to '
          '"${subtopicParent[subtopicId]?.id}".',
        );
      }

      final declaredCompetency = _string(
        raw['competencyId'] ?? raw['competency_id'],
      );
      if (declaredCompetency.isNotEmpty &&
          declaredCompetency != content.competencyId.trim()) {
        throw FormatException(
          'Question ${index + 1} declares competencyId '
          '"$declaredCompetency", but the selected competency is '
          '"${content.competencyId}".',
        );
      }

      final sanitized = Map<String, dynamic>.from(raw)
        ..remove('id')
        ..remove('status')
        ..remove('quizId')
        ..remove('quiz_id')
        ..remove('contentPackageId')
        ..remove('content_package_id');

      final question = _importer
          .fromDecoded(
            decoded: <Map<String, dynamic>>[sanitized],
            nextId: _questionService.nextQuestionId,
            content: content,
            topic: topic,
            subtopic: subtopic,
            quizId: stableQuizId(subtopic),
          )
          .single;

      final normalizedStem = _normalizeStem(question.question);
      if (normalizedStem.isNotEmpty && !normalizedStems.add(normalizedStem)) {
        throw FormatException(
          'Question ${index + 1} duplicates another normalized question '
          'stem in the same bulk package.',
        );
      }

      final issues = _questionService.validate(question);
      final errors = issues.where((issue) => issue.isError).toList();

      if (errors.isNotEmpty) {
        throw FormatException(
          'Question ${index + 1} failed the CSP11 quality gate:\n'
          '${errors.map((issue) => '• ${issue.message}').join('\n')}',
        );
      }

      questions.add(question);
      counts[subtopicId] = (counts[subtopicId] ?? 0) + 1;
    }

    final insufficient =
        counts.entries.where((entry) => entry.value < 5).toList()
          ..sort((a, b) => a.key.compareTo(b.key));

    if (insufficient.isNotEmpty) {
      throw FormatException(
        'Bulk coverage gate failed. Every Subtopic requires at least '
        '5 valid questions. Missing coverage:\n'
        '${insufficient.map((entry) => '${entry.key}: ${entry.value}/5').join('\n')}',
      );
    }

    return StudioBulkQuestionPlan(
      sourceContent: content,
      questions: List<Question>.unmodifiable(questions),
      questionCountBySubtopic: Map<String, int>.unmodifiable(counts),
    );
  }

  Future<StudioBulkQuestionPublishResult> publishAndLink(
    StudioBulkQuestionPlan plan,
  ) async {
    final contentRepositoryService = _contentRepositoryService;
    if (contentRepositoryService == null) {
      throw StateError(
        'A content repository service is required for bulk publication.',
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
            'quizId': stableQuizIdForSubtopicId(question.subtopicId),
            'contentPackageId': workingContent.id,
            'status': 'draft',
          }),
        )
        .toList();

    final linkedTopics = workingContent.topics.map((topic) {
      final linkedSubtopics = topic.subtopics.map((subtopic) {
        return subtopic.copyWith(
          quizzes: <QuizReference>[
            QuizReference(quizId: stableQuizId(subtopic)),
          ],
        );
      }).toList();

      return topic.copyWith(subtopics: linkedSubtopics);
    }).toList();

    final linkedContent = workingContent.copyWith(
      status: 'draft',
      topics: linkedTopics,
    );

    // Validate the complete linked content before any question publication.
    final contentErrors = await contentRepositoryService.validatePackage(
      linkedContent,
    );
    if (contentErrors.isNotEmpty) {
      throw StateError(
        'Bulk publish is blocked because the linked content revision '
        'failed validation:\n${contentErrors.join('\n')}',
      );
    }

    final publishResult = await _questionService.publishPreparedBatch(
      preparedQuestions,
    );

    await contentRepositoryService.saveDraft(linkedContent);
    await contentRepositoryService.submitForReview(linkedContent);
    await contentRepositoryService.validateAndMark(linkedContent);
    await contentRepositoryService.publish(linkedContent);

    return StudioBulkQuestionPublishResult(
      publishedContent: linkedContent.copyWith(status: 'published'),
      questionCount: preparedQuestions.length,
      linkedSubtopicCount: plan.questionCountBySubtopic.length,
      reusedQuestionCount: publishResult.reusedQuestionCount,
    );
  }

  static String stableQuizId(StudySubtopic subtopic) {
    return stableQuizIdForSubtopicId(subtopic.id);
  }

  static String stableQuizIdForSubtopicId(String subtopicId) {
    final normalized = subtopicId.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(
        subtopicId,
        'subtopicId',
        'Subtopic ID cannot be empty.',
      );
    }

    return '${normalized}_quiz';
  }

  void _validateTopLevelContext(dynamic decoded, StudyContent content) {
    if (decoded is! Map) {
      return;
    }

    final map = Map<String, dynamic>.from(decoded);
    final competencyId = _string(map['competencyId'] ?? map['competency_id']);

    if (competencyId.isNotEmpty &&
        competencyId != content.competencyId.trim()) {
      throw FormatException(
        'Bulk JSON declares competencyId "$competencyId", but the selected '
        'competency is "${content.competencyId}".',
      );
    }
  }

  List<Map<String, dynamic>> _extractQuestionObjects(dynamic decoded) {
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    if (decoded is Map) {
      final map = Map<String, dynamic>.from(decoded);
      final questions = map['questions'] ?? map['items'] ?? map['data'];

      if (questions is List) {
        return questions
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }

      if (_looksLikeQuestion(map)) {
        return <Map<String, dynamic>>[map];
      }
    }

    throw const FormatException(
      'Bulk question JSON must be an array or an object containing a '
      '"questions" array.',
    );
  }

  bool _looksLikeQuestion(Map<String, dynamic> map) {
    return map.containsKey('question') || map.containsKey('stem');
  }

  String _normalizeStem(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9 ]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _string(dynamic value) => value?.toString().trim() ?? '';
}
