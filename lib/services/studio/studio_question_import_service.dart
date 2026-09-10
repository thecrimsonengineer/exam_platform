import 'dart:convert';

import '../../models/question.dart';
import '../../models/study_content.dart';
import '../complete_question_paste_parser.dart';

/// Canonical conversion layer for Studio question imports.
///
/// All imported questions are converted into the normal Question model with
/// the active Studio context attached before validation and persistence.
class StudioQuestionImportService {
  const StudioQuestionImportService();

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
    final decoded = jsonDecode(input);
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

    final rawQuestions = _extractQuestionObjects(decoded);

    if (rawQuestions.isEmpty) {
      throw const FormatException(
        'No question objects were found in the JSON file.',
      );
    }

    final questions = rawQuestions.map((raw) {
      _validateDeclaredContext(
        raw,
        content: content,
        topic: topic,
        subtopic: subtopic,
        quizId: quizId,
      );

      return _questionFromMap(
        raw,
        id: nextId(),
        content: content,
        topic: topic,
        subtopic: subtopic,
        quizId: quizId,
      );
    }).toList();

    _validateUniqueQuestionStems(questions);
    return questions;
  }

  Question _questionFromMap(
    Map<String, dynamic> raw, {
    required int id,
    required StudyContent content,
    required StudyTopic topic,
    required StudySubtopic subtopic,
    required String quizId,
  }) {
    final options = _stringList(raw['options']);
    final correctAnswer = _correctAnswerIndex(raw, options);

    return Question(
      id: id,
      domain: _domainNumber(content.domainId),
      competencyId: content.competencyId,
      subtopicId: subtopic.id,
      topicId: topic.id,
      quizId: quizId,
      contentPackageId: content.id,
      question: _string(raw['question'] ?? raw['stem']),
      options: options,
      correctAnswer: correctAnswer,
      explanation: _string(raw['explanation']),
      bestAnswerRationale: _string(raw['bestAnswerRationale']),
      reference: _string(raw['reference'] ?? raw['source']),
      difficulty: _string(raw['difficulty'], fallback: 'Hard'),
      cognitiveLevel: _string(
        raw['cognitiveLevel'] ?? raw['cognitive_level'],
        fallback: 'analysis',
      ),
      questionType: _string(
        raw['questionType'] ?? raw['question_type'],
        fallback: 'scenario_mcq',
      ),
      status: 'draft',
      version: _int(raw['version'], fallback: 1),
      tags: _stringList(raw['tags']),
    );
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

      return [map];
    }

    throw const FormatException(
      'JSON must contain a question object or an array of question objects.',
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

  void _validateUniqueQuestionStems(List<Question> questions) {
    final seen = <String>{};

    for (final question in questions) {
      final normalized = _normalizedQuestionStem(question.question);

      if (normalized.isEmpty) {
        continue;
      }

      if (!seen.add(normalized)) {
        throw const FormatException(
          'The JSON file contains the same question stem more than once. '
          'Each imported question must be unique.',
        );
      }
    }
  }

  String _normalizedQuestionStem(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9 ]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  int _correctAnswerIndex(Map<String, dynamic> raw, List<String> options) {
    final value =
        raw['correctAnswer'] ?? raw['correct_answer'] ?? raw['bestAnswer'];

    if (value is int) {
      if (value >= 0 && value < options.length) return value;
      if (value >= 1 && value <= options.length) return value - 1;
    }

    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) return -1;

    final upper = text.toUpperCase();
    final letter = RegExp(r'^[ABCD]$').firstMatch(upper);
    if (letter != null) return 'ABCD'.indexOf(upper);

    final number = int.tryParse(text);
    if (number != null) {
      if (number >= 0 && number < options.length) return number;
      if (number >= 1 && number <= options.length) return number - 1;
    }

    final exact = options.indexWhere(
      (option) => option.trim().toLowerCase() == text.toLowerCase(),
    );
    return exact;
  }

  List<String> _stringList(dynamic value) {
    if (value is String) {
      return value
          .split(RegExp(r'[,;\n]'))
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }

    if (value is List) {
      return value
          .map((item) => item?.toString() ?? '')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }

    return <String>[];
  }

  String _string(dynamic value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  int _int(dynamic value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  int _domainNumber(String domainId) {
    final match = RegExp(r'\d+').firstMatch(domainId);
    return int.tryParse(match?.group(0) ?? '') ?? 0;
  }
}
