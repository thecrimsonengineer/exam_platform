import '../models/question.dart';

class CompleteQuestionPasteResult {
  final String question;
  final List<String> options;
  final int correctAnswer;
  final String explanation;
  final String reference;
  final List<String> tags;

  const CompleteQuestionPasteResult({
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    required this.reference,
    required this.tags,
  });

  Question toQuestion({
    required int id,
    required int domain,
    required String competencyId,
    required String subtopicId,
    required String topicId,
    required String quizId,
    required String contentPackageId,
    String difficulty = 'Hard',
    String cognitiveLevel = 'analysis',
  }) {
    return Question(
      id: id,
      domain: domain,
      competencyId: competencyId,
      subtopicId: subtopicId,
      topicId: topicId,
      quizId: quizId,
      contentPackageId: contentPackageId,
      question: question,
      options: List<String>.from(options),
      correctAnswer: correctAnswer,
      explanation: explanation,
      bestAnswerRationale: '',
      reference: reference,
      difficulty: difficulty,
      cognitiveLevel: cognitiveLevel,
      questionType: 'scenario_mcq',
      status: 'draft',
      version: 1,
      tags: List<String>.from(tags),
    );
  }
}

class CompleteQuestionPasteParser {
  const CompleteQuestionPasteParser();

  CompleteQuestionPasteResult parse(String input) {
    final normalized = input
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .trim();

    if (normalized.isEmpty) {
      throw const FormatException(
        'Nothing was pasted. Enter a complete question first.',
      );
    }

    final question = _extractSection(normalized, 'QUESTION', ['OPTION A']);

    final optionA = _extractSection(normalized, 'OPTION A', ['OPTION B']);

    final optionB = _extractSection(normalized, 'OPTION B', ['OPTION C']);

    final optionC = _extractSection(normalized, 'OPTION C', ['OPTION D']);

    final optionD = _extractSection(normalized, 'OPTION D', ['BEST ANSWER']);

    final bestAnswerText = _extractSection(normalized, 'BEST ANSWER', [
      'EXPLANATION',
    ]);

    final explanation = _extractSection(normalized, 'EXPLANATION', [
      'REFERENCE',
    ]);

    final reference = _extractSection(normalized, 'REFERENCE', ['TAGS']);

    // TAGS is the final section, so everything after "TAGS:" belongs
    // to the tag field. This is intentionally handled without an
    // end-of-line regex lookahead.
    final tags = _extractSection(
      normalized,
      'TAGS',
      const <String>[],
      required: false,
    );

    final options = <String>[
      optionA.trim(),
      optionB.trim(),
      optionC.trim(),
      optionD.trim(),
    ];

    if (options.any((option) => option.isEmpty)) {
      throw const FormatException('All four answer options are required.');
    }

    final correctAnswer = _parseAnswer(bestAnswerText);

    final parsedTags = _parseTags(tags);

    return CompleteQuestionPasteResult(
      question: question.trim(),
      options: options,
      correctAnswer: correctAnswer,
      explanation: explanation.trim(),
      reference: reference.trim(),
      tags: parsedTags,
    );
  }

  String _extractSection(
    String input,
    String label,
    List<String> nextLabels, {
    bool required = true,
  }) {
    final startPattern = RegExp(
      '^\\s*${RegExp.escape(label)}\\s*:\\s*',
      multiLine: true,
      caseSensitive: false,
    );

    final startMatch = startPattern.firstMatch(input);

    if (startMatch == null) {
      if (required) {
        throw FormatException('Missing required section: $label:');
      }

      return '';
    }

    final contentStart = startMatch.end;

    // The final section has no following section label.
    // Return everything remaining in the paste.
    if (nextLabels.isEmpty) {
      final value = input.substring(contentStart).trim();

      if (required && value.isEmpty) {
        throw FormatException('$label cannot be empty.');
      }

      return value;
    }

    final nextPattern = RegExp(
      '^\\s*(?:${nextLabels.map(RegExp.escape).join('|')})\\s*:',
      multiLine: true,
      caseSensitive: false,
    );

    final remaining = input.substring(contentStart);
    final nextMatch = nextPattern.firstMatch(remaining);

    final value = nextMatch == null
        ? remaining.trim()
        : remaining.substring(0, nextMatch.start).trim();

    if (required && value.isEmpty) {
      throw FormatException('$label cannot be empty.');
    }

    return value;
  }

  int _parseAnswer(String value) {
    final normalized = value.trim().toUpperCase();

    final letterMatch = RegExp(r'\b([ABCD])\b').firstMatch(normalized);

    if (letterMatch != null) {
      return 'ABCD'.indexOf(letterMatch.group(1)!);
    }

    final numberMatch = RegExp(r'\b([1-4])\b').firstMatch(normalized);

    if (numberMatch != null) {
      return int.parse(numberMatch.group(1)!) - 1;
    }

    throw const FormatException(
      'BEST ANSWER must be A, B, C, or D. '
      'You may also use 1, 2, 3, or 4.',
    );
  }

  List<String> _parseTags(String value) {
    if (value.trim().isEmpty) {
      return <String>[];
    }

    return value
        .split(RegExp(r'[,;\n]'))
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toSet()
        .toList();
  }
}
