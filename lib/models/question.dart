class Question {
  final int id;

  /// CSP domain number.
  ///
  /// Example:
  /// 7 = Domain 7
  final int domain;

  /// Competency ID within the domain.
  ///
  /// Example:
  /// d07_c01
  final String competencyId;

  /// Subtopic ID within the competency.
  ///
  /// Example:
  /// d07_c01_s01
  final String subtopicId;

  /// Main content topic ID within the subtopic.
  ///
  /// Example:
  /// d07_c01_s01_t01
  final String topicId;

  final String question;

  final List<String> options;

  final int correctAnswer;

  final String explanation;

  final String reference;

  final String difficulty;

  final List<String> tags;

  const Question({
    required this.id,
    required this.domain,
    required this.competencyId,
    required this.subtopicId,
    required this.topicId,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    required this.reference,
    required this.difficulty,
    required this.tags,
  });
}