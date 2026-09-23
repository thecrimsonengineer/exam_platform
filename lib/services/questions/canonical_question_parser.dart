import 'dart:convert';

/// Context-free representation of an authored CSP11 question.
///
/// Placement such as domain, competency, topic, subtopic and quiz identity is
/// intentionally attached by the calling context after parsing.
class CanonicalQuestionDraft {
  const CanonicalQuestionDraft({
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    required this.bestAnswerRationale,
    required this.reference,
    required this.difficulty,
    required this.cognitiveLevel,
    required this.questionType,
    required this.version,
    required this.tags,
  });

  final String question;
  final List<String> options;
  final int correctAnswer;
  final String explanation;
  final String bestAnswerRationale;
  final String reference;
  final String difficulty;
  final String cognitiveLevel;
  final String questionType;
  final int version;
  final List<String> tags;
}

/// Canonical CSP11 JSON question parser.
///
/// This service owns raw JSON shape handling, field aliases, answer decoding,
/// defaults, tag normalization and duplicate-stem detection. It deliberately
/// has no dependency on StudyContent, LAB runtime state, persistence or UI.
class CanonicalQuestionParser {
  const CanonicalQuestionParser();

  dynamic decodeJson(String input) => jsonDecode(input);

  List<CanonicalQuestionDraft> fromJsonText(String input) {
    return fromDecoded(decodeJson(input));
  }

  List<CanonicalQuestionDraft> fromDecoded(dynamic decoded) {
    return parseQuestionObjects(questionObjectsFromDecoded(decoded));
  }

  List<Map<String, dynamic>> questionObjectsFromDecoded(dynamic decoded) {
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

      return <Map<String, dynamic>>[map];
    }

    throw const FormatException(
      'JSON must contain a question object or an array of question objects.',
    );
  }

  List<CanonicalQuestionDraft> parseQuestionObjects(
    Iterable<Map<String, dynamic>> rawQuestions,
  ) {
    final values = rawQuestions.toList(growable: false);

    if (values.isEmpty) {
      throw const FormatException(
        'No question objects were found in the JSON file.',
      );
    }

    final questions = values.map(parseQuestion).toList(growable: false);
    validateUniqueQuestionStems(questions);
    return questions;
  }

  CanonicalQuestionDraft parseQuestion(Map<String, dynamic> raw) {
    final options = _stringList(raw['options']);
    final correctAnswer = _correctAnswerIndex(raw, options);

    return CanonicalQuestionDraft(
      question: _string(raw['question'] ?? raw['stem']),
      options: List<String>.unmodifiable(options),
      correctAnswer: correctAnswer,
      explanation: _string(raw['explanation']),
      bestAnswerRationale: _string(
        raw['bestAnswerRationale'] ?? raw['best_answer_rationale'],
      ),
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
      version: _int(raw['version'], fallback: 1),
      tags: List<String>.unmodifiable(_stringList(raw['tags'])),
    );
  }

  void validateUniqueQuestionStems(
    Iterable<CanonicalQuestionDraft> questions,
  ) {
    final seen = <String>{};

    for (final question in questions) {
      final normalized = normalizedQuestionStem(question.question);

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

  String normalizedQuestionStem(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9 ]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  int _correctAnswerIndex(
    Map<String, dynamic> raw,
    List<String> options,
  ) {
    final value =
        raw['correctAnswer'] ?? raw['correct_answer'] ?? raw['bestAnswer'];

    // Preserve the established Studio import semantics exactly: integer values
    // that already fit the zero-based range are treated as zero-based first.
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
}
