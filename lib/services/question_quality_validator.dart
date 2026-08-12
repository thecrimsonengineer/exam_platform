import '../models/question.dart';

class QuestionQualityIssue {
  final String message;
  final bool isError;

  const QuestionQualityIssue(this.message, {this.isError = true});
}

/// Quality gate for CSP11 best-answer questions.
///
/// Rules:
/// - Scenario MCQ
/// - Application or Analysis
/// - Hard difficulty
/// - Meaningful question stem
/// - Exactly 4 answer options
/// - Exactly 1 valid BEST answer
/// - Explanation required
/// - Reference required
/// - At least 2 useful tags
/// - Optional configurable answer-length check
///
/// Plausible Alternative and distractor classification are NOT used.
class QuestionQualityValidator {
  const QuestionQualityValidator({this.answerLengthCheckEnabled = true});

  final bool answerLengthCheckEnabled;

  List<QuestionQualityIssue> validate(Question question) {
    final issues = <QuestionQualityIssue>[];

    final stem = question.question.trim();

    final options = question.options.map((item) => item.trim()).toList();

    // ---------------------------------------------------------------
    // QUESTION TYPE
    // ---------------------------------------------------------------

    if (question.questionType != 'scenario_mcq') {
      issues.add(
        const QuestionQualityIssue('Question type must be Scenario MCQ.'),
      );
    }

    // ---------------------------------------------------------------
    // COGNITIVE LEVEL
    // ---------------------------------------------------------------

    if (!{
      'application',
      'analysis',
    }.contains(question.cognitiveLevel.toLowerCase())) {
      issues.add(
        const QuestionQualityIssue(
          'Cognitive level must be Application or Analysis.',
        ),
      );
    }

    // ---------------------------------------------------------------
    // DIFFICULTY
    // ---------------------------------------------------------------

    if (question.difficulty.toLowerCase() != 'hard') {
      issues.add(
        const QuestionQualityIssue(
          'CSP practice questions must be Hard difficulty.',
        ),
      );
    }

    // ---------------------------------------------------------------
    // QUESTION STEM
    // ---------------------------------------------------------------

    if (stem.isEmpty) {
      issues.add(const QuestionQualityIssue('Question stem is required.'));
    } else if (stem.length < 80) {
      issues.add(
        const QuestionQualityIssue(
          'Use a meaningful workplace scenario with enough context for a high-level decision.',
        ),
      );
    }

    // ---------------------------------------------------------------
    // ANSWER OPTIONS
    // ---------------------------------------------------------------

    if (options.length != 4) {
      issues.add(
        const QuestionQualityIssue('Exactly four answer options are required.'),
      );
    }

    if (options.length == 4) {
      final nonEmpty = options.where((item) => item.isNotEmpty).length;

      if (nonEmpty != 4) {
        issues.add(
          const QuestionQualityIssue(
            'All four answer options must contain meaningful text.',
          ),
        );
      }

      if (options.toSet().length != options.length) {
        issues.add(
          const QuestionQualityIssue('Answer options must be distinct.'),
        );
      }

      // -------------------------------------------------------------
      // BEST ANSWER
      // -------------------------------------------------------------

      if (question.correctAnswer < 0 ||
          question.correctAnswer >= options.length) {
        issues.add(
          const QuestionQualityIssue(
            'Exactly one valid BEST answer must be selected.',
          ),
        );
      }

      // -------------------------------------------------------------
      // ANSWER LENGTH CHECK
      // -------------------------------------------------------------

      if (answerLengthCheckEnabled &&
          question.correctAnswer >= 0 &&
          question.correctAnswer < options.length &&
          options.every((item) => item.isNotEmpty)) {
        _validateAnswerLengths(options, question.correctAnswer, issues);
      }
    }

    // ---------------------------------------------------------------
    // EXPLANATION
    // ---------------------------------------------------------------

    if (question.explanation.trim().isEmpty) {
      issues.add(const QuestionQualityIssue('An explanation is required.'));
    } else if (question.explanation.trim().length < 80) {
      issues.add(
        const QuestionQualityIssue(
          'Explanation should clearly explain why the BEST answer is correct.',
        ),
      );
    }

    // ---------------------------------------------------------------
    // REFERENCE
    // ---------------------------------------------------------------

    if (question.reference.trim().isEmpty) {
      issues.add(const QuestionQualityIssue('A source/reference is required.'));
    }

    // ---------------------------------------------------------------
    // TAGS
    // ---------------------------------------------------------------

    if (question.tags.length < 2) {
      issues.add(
        const QuestionQualityIssue('Add at least two useful question tags.'),
      );
    }

    return issues;
  }

  // -----------------------------------------------------------------
  // ANSWER LENGTH VALIDATION
  // -----------------------------------------------------------------

  void _validateAnswerLengths(
    List<String> options,
    int correctAnswer,
    List<QuestionQualityIssue> issues,
  ) {
    final lengths = options.map(_wordCount).toList();

    final correctLength = lengths[correctAnswer];

    final longest = lengths.reduce((a, b) => a > b ? a : b);

    final shortest = lengths.reduce((a, b) => a < b ? a : b);

    // Count how many options share the maximum length.
    final longestCount = lengths.where((length) => length == longest).length;

    // ---------------------------------------------------------------
    // BEST ANSWER MAY BE TIED FOR LONGEST
    //
    // PASS:
    // A = 8
    // B = 7
    // C = 8  <-- BEST
    // D = 7
    //
    // FAIL:
    // A = 7
    // B = 7
    // C = 8  <-- BEST
    // D = 7
    //
    // Therefore, the BEST answer is rejected only when it is
    // uniquely the longest option.
    // ---------------------------------------------------------------

    if (correctLength == longest && longestCount == 1) {
      issues.add(
        QuestionQualityIssue(
          'The BEST answer is uniquely the longest option '
          '($correctLength words). Keep the BEST answer comparable '
          'in length to the other options.',
        ),
      );
    }

    // ---------------------------------------------------------------
    // OVERALL OPTION BALANCE
    // ---------------------------------------------------------------

    if (shortest > 0 && longest > shortest * 2) {
      issues.add(
        QuestionQualityIssue(
          'Option lengths are too uneven '
          '($shortest to $longest words). '
          'Keep all options comparable in wording and detail.',
        ),
      );
    }
  }

  // -----------------------------------------------------------------
  // WORD COUNT
  // -----------------------------------------------------------------

  int _wordCount(String value) {
    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      return 0;
    }

    return trimmed
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .length;
  }
}
