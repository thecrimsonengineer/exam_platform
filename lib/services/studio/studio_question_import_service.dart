import '../../models/question.dart';
import '../../models/study_content.dart';
import '../complete_question_paste_parser.dart';
import '../questions/canonical_question_parser.dart';

/// Conversion layer for Studio question imports.
///
/// Raw question fields are parsed by [CanonicalQuestionParser]. This service
/// owns only Studio context validation and attachment before persistence.
class StudioQuestionImportService {
  const StudioQuestionImportService({
    this.parser = const CanonicalQuestionParser(),
  });

  final CanonicalQuestionParser parser;

  Question fromPaste({
    required CompleteQuestionPasteResult parsed,
    required int id,
    required StudyContent content,
    required StudyTopic topic,
    required StudySubtopic subtopic,
    required String quizId,
  }) {
    return parsed.toQuestion(
      id: id,
      domain: _domainNumber(content.domainId),
      competencyId: content.competencyId,
      subtopicId: subtopic.id,
      topicId: topic.id,
      quizId: quizId,
      contentPackageId: content.id,
    );
  }

  List<Question> fromJsonText({
    required String input,
    required int Function() nextId,
    required StudyContent content,
    required StudyTopic topic,
    required StudySubtopic subtopic,
    required String quizId,
  }) {
    final decoded = parser.decodeJson(input);
    return fromDecoded(
      decoded: decoded,
      nextId: nextId,
      content: content,
      topic: topic,
      subtopic: subtopic,
      quizId: quizId,
    );
  }

  List<Question> fromDecoded({
    required dynamic decoded,
    required int Function() nextId,
    required StudyContent content,
    required StudyTopic topic,
    required StudySubtopic subtopic,
    required String quizId,
  }) {
    _validateDeclaredContext(
      decoded,
      content: content,
      topic: topic,
      subtopic: subtopic,
      quizId: quizId,
    );

    final rawQuestions = parser.questionObjectsFromDecoded(decoded);

    if (rawQuestions.isEmpty) {
      throw const FormatException(
        'No question objects were found in the JSON file.',
      );
    }

    final drafts = <CanonicalQuestionDraft>[];
    final questions = <Question>[];

    for (final raw in rawQuestions) {
      _validateDeclaredContext(
        raw,
        content: content,
        topic: topic,
        subtopic: subtopic,
        quizId: quizId,
      );

      final draft = parser.parseQuestion(raw);
      drafts.add(draft);
      questions.add(
        _questionFromDraft(
          draft,
          id: nextId(),
          content: content,
          topic: topic,
          subtopic: subtopic,
          quizId: quizId,
        ),
      );
    }

    parser.validateUniqueQuestionStems(drafts);
    return questions;
  }

  Question _questionFromDraft(
    CanonicalQuestionDraft draft, {
    required int id,
    required StudyContent content,
    required StudyTopic topic,
    required StudySubtopic subtopic,
    required String quizId,
  }) {
    return Question(
      id: id,
      domain: _domainNumber(content.domainId),
      competencyId: content.competencyId,
      subtopicId: subtopic.id,
      topicId: topic.id,
      quizId: quizId,
      contentPackageId: content.id,
      question: draft.question,
      options: List<String>.from(draft.options),
      correctAnswer: draft.correctAnswer,
      explanation: draft.explanation,
      bestAnswerRationale: draft.bestAnswerRationale,
      reference: draft.reference,
      difficulty: draft.difficulty,
      cognitiveLevel: draft.cognitiveLevel,
      questionType: draft.questionType,
      status: 'draft',
      version: draft.version,
      tags: List<String>.from(draft.tags),
    );
  }

  void _validateDeclaredContext(
    dynamic source, {
    required StudyContent content,
    required StudyTopic topic,
    required StudySubtopic subtopic,
    required String quizId,
  }) {
    if (source is! Map) {
      return;
    }

    final map = Map<String, dynamic>.from(source);
    final nestedContext = map['context'];

    if (nestedContext is Map) {
      _validateDeclaredContext(
        Map<String, dynamic>.from(nestedContext),
        content: content,
        topic: topic,
        subtopic: subtopic,
        quizId: quizId,
      );
    }

    _assertStringContext(
      label: 'competencyId',
      declared: _firstString(map, const [
        'competencyId',
        'competency_id',
        'competency',
      ]),
      expected: content.competencyId,
    );

    _assertStringContext(
      label: 'topicId',
      declared: _firstString(map, const ['topicId', 'topic_id', 'topic']),
      expected: topic.id,
    );

    _assertStringContext(
      label: 'subtopicId',
      declared: _firstString(map, const [
        'subtopicId',
        'subtopic_id',
        'subtopic',
      ]),
      expected: subtopic.id,
    );

    _assertStringContext(
      label: 'quizId',
      declared: _firstString(map, const ['quizId', 'quiz_id']),
      expected: quizId,
    );

    _assertStringContext(
      label: 'contentPackageId',
      declared: _firstString(map, const [
        'contentPackageId',
        'content_package_id',
        'contentId',
        'content_id',
      ]),
      expected: content.id,
    );

    final declaredDomain = _firstString(map, const [
      'domain',
      'domainId',
      'domain_id',
    ]);

    if (declaredDomain.isNotEmpty) {
      final parsedDomain = _domainNumber(declaredDomain);
      final expectedDomain = _domainNumber(content.domainId);

      if (parsedDomain != expectedDomain) {
        throw FormatException(
          'JSON context mismatch for domain: file declares '
          '"$declaredDomain" but the selected Studio context is '
          '"${content.domainId}". Open the matching subtopic before import.',
        );
      }
    }
  }

  void _assertStringContext({
    required String label,
    required String declared,
    required String expected,
  }) {
    if (declared.isEmpty) {
      return;
    }

    if (declared.trim() != expected.trim()) {
      throw FormatException(
        'JSON context mismatch for $label: file declares "$declared" '
        'but the selected Studio context is "$expected". '
        'Open the matching subtopic before import.',
      );
    }
  }

  String _firstString(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
      if (value is num) {
        return value.toString();
      }
    }
    return '';
  }

  int _domainNumber(String domainId) {
    final match = RegExp(r'\d+').firstMatch(domainId);
    return int.tryParse(match?.group(0) ?? '') ?? 0;
  }
}
