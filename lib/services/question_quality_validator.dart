import '../models/question.dart';
import '../models/question_validation_report.dart';

enum QuestionIssueSeverity {
  error,
  warning,
}

class QuestionQualityIssue {
  final String code;
  final String field;
  final QuestionIssueSeverity severity;
  final String message;

  const QuestionQualityIssue({
    required this.code,
    required this.field,
    required this.severity,
    required this.message,
  });

  bool get isError => severity == QuestionIssueSeverity.error;

  bool get isWarning => severity == QuestionIssueSeverity.warning;
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

  /// Validates a question and returns one structured validation report.
  QuestionValidationReport validateReport(Question question) {
    return QuestionValidationReport(
      issues: _validateIssues(question),
    );
  }

  /// Backward-compatible validation API.
  ///
  /// New callers should prefer [validateReport].
  List<QuestionQualityIssue> validate(Question question) {
    return validateReport(question).issues;
  }

  List<QuestionQualityIssue> _validateIssues(Question question) {
    final issues = <QuestionQualityIssue>[];

    final stem = question.question.trim();

    final options = question.options.map((item) => item.trim()).toList();

    // ---------------------------------------------------------------
    // QUESTION TYPE
    // ---------------------------------------------------------------

    if (question.questionType != 'scenario_mcq') {
      issues.add(
        const QuestionQualityIssue(
          code: 'invalid_question_type',
          field: 'questionType',
          severity: QuestionIssueSeverity.error,
          message: 'Question type must be Scenario MCQ.',
        ),
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
          code: 'invalid_cognitive_level',
          field: 'cognitiveLevel',
          severity: QuestionIssueSeverity.error,
          message: 'Cognitive level must be Application or Analysis.',
        ),
      );
    }

    // ---------------------------------------------------------------
    // DIFFICULTY
    // ---------------------------------------------------------------

    if (question.difficulty.toLowerCase() != 'hard') {
      issues.add(
        const QuestionQualityIssue(
          code: 'invalid_difficulty',
          field: 'difficulty',
          severity: QuestionIssueSeverity.error,
          message: 'CSP practice questions must be Hard difficulty.',
        ),
      );
    }

    // ---------------------------------------------------------------
    // QUESTION STEM
    // ---------------------------------------------------------------

    if (stem.isEmpty) {
      issues.add(const QuestionQualityIssue(
          code: 'missing_question_stem',
          field: 'question',
          severity: QuestionIssueSeverity.error,
          message: 'Question stem is required.',
        ));
    } else if (stem.length < 80) {
      issues.add(
        const QuestionQualityIssue(
          code: 'weak_question_stem',
          field: 'question',
          severity: QuestionIssueSeverity.warning,
          message:
              'Use a meaningful workplace scenario with enough context for a high-level decision.',
        ),
      );
    }

    // ---------------------------------------------------------------
    // ANSWER OPTIONS
    // ---------------------------------------------------------------

    if (options.length != 4) {
      issues.add(
        const QuestionQualityIssue(
          code: 'invalid_option_count',
          field: 'options',
          severity: QuestionIssueSeverity.error,
          message: 'Exactly four answer options are required.',
        ),
      );
    }

    if (options.length == 4) {
      final nonEmpty = options.where((item) => item.isNotEmpty).length;

      if (nonEmpty != 4) {
        issues.add(
          const QuestionQualityIssue(
            code: 'empty_answer_option',
            field: 'options',
            severity: QuestionIssueSeverity.error,
            message:
                'All four answer options must contain meaningful text.',
          ),
        );
      }

      if (options.toSet().length != options.length) {
        issues.add(
          const QuestionQualityIssue(
          code: 'duplicate_answer_option',
          field: 'options',
          severity: QuestionIssueSeverity.error,
          message: 'Answer options must be distinct.',
        ),
        );
      }

      // -------------------------------------------------------------
      // BEST ANSWER
      // -------------------------------------------------------------

      if (question.correctAnswer < 0 ||
          question.correctAnswer >= options.length) {
        issues.add(
          const QuestionQualityIssue(
            code: 'invalid_correct_answer',
            field: 'correctAnswer',
            severity: QuestionIssueSeverity.error,
            message: 'Exactly one valid BEST answer must be selected.',
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
      issues.add(const QuestionQualityIssue(
          code: 'missing_explanation',
          field: 'explanation',
          severity: QuestionIssueSeverity.error,
          message: 'An explanation is required.',
        ));
    } else if (question.explanation.trim().length < 80) {
      issues.add(
        const QuestionQualityIssue(
          code: 'weak_explanation',
          field: 'explanation',
          severity: QuestionIssueSeverity.warning,
          message:
              'Explanation should clearly explain why the BEST answer is correct.',
        ),
      );
    }

    // ---------------------------------------------------------------
    // REFERENCE
    // ---------------------------------------------------------------

    if (question.reference.trim().isEmpty) {
      issues.add(const QuestionQualityIssue(
          code: 'missing_reference',
          field: 'reference',
          severity: QuestionIssueSeverity.error,
          message: 'A source/reference is required.',
        ));
    }

    // ---------------------------------------------------------------
    // TAGS
    // ---------------------------------------------------------------

    if (question.tags.length < 2) {
      issues.add(
        const QuestionQualityIssue(
          code: 'insufficient_tags',
          field: 'tags',
          severity: QuestionIssueSeverity.warning,
          message: 'Add at least two useful question tags.',
        ),
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

    final longestCount = lengths.where((length) => length == longest).length;

    // BEST answer may be tied for longest.
    // It fails only when it is uniquely the longest option.
    if (correctLength == longest && longestCount == 1) {
      issues.add(
        QuestionQualityIssue(
          code: 'best_answer_length_bias',
          field: 'options',
          severity: QuestionIssueSeverity.warning,
          message:
              'The BEST answer is uniquely the longest option '
              '($correctLength words). Keep the BEST answer comparable '
              'in length to the other options.',
        ),
      );
    }

    // Overall option balance.
    if (shortest > 0 && longest > shortest * 2) {
      issues.add(
        QuestionQualityIssue(
          code: 'option_length_imbalance',
          field: 'options',
          severity: QuestionIssueSeverity.warning,
          message:
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
