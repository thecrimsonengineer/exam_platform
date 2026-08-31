class Question {
  final int id;

  /// CSP domain number.
  final int domain;

  /// Official competency identifier.
  final String competencyId;

  /// Subtopic identifier.
  final String subtopicId;

  /// Main content topic identifier.
  /// Empty when the question covers the subtopic rather than one specific topic.
  final String topicId;

  /// Quiz to which this question belongs.
  final String quizId;

  /// Content package/version that produced the question.
  final String contentPackageId;

  /// Question stem.
  final String question;

  /// Exactly four answer options.
  final List<String> options;

  /// Zero-based index of the BEST/correct answer.
  final int correctAnswer;

  /// Explanation of the correct answer.
  final String explanation;

  /// Optional internal rationale for why the BEST answer is superior.
  ///
  /// This is retained for compatibility with the current application.
  /// It is not required during Complete Question Paste.
  final String bestAnswerRationale;

  /// Authoritative reference/source for the question.
  final String reference;

  /// Question difficulty.
  final String difficulty;

  /// Cognitive level.
  final String cognitiveLevel;

  /// Question type.
  final String questionType;

  /// Repository lifecycle status.
  final String status;

  /// Question version.
  final int version;

  /// Search and classification tags.
  final List<String> tags;

  const Question({
    required this.id,
    required this.domain,
    required this.competencyId,
    required this.subtopicId,
    required this.topicId,
    this.quizId = '',
    this.contentPackageId = '',
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    this.bestAnswerRationale = '',
    required this.reference,
    required this.difficulty,
    this.cognitiveLevel = 'application',
    this.questionType = 'scenario_mcq',
    this.status = 'draft',
    this.version = 1,
    required this.tags,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: _toInt(json['id']),
      domain: _toInt(json['domain']),
      competencyId: json['competencyId']?.toString() ?? '',
      subtopicId: json['subtopicId']?.toString() ?? '',
      topicId: json['topicId']?.toString() ?? '',
      quizId: json['quizId']?.toString() ?? '',
      contentPackageId: json['contentPackageId']?.toString() ?? '',
      question: json['question']?.toString() ?? '',
      options: _stringList(json['options']),
      correctAnswer: _toInt(json['correctAnswer']),
      explanation: json['explanation']?.toString() ?? '',
      bestAnswerRationale: json['bestAnswerRationale']?.toString() ?? '',
      reference: json['reference']?.toString() ?? '',
      difficulty: json['difficulty']?.toString() ?? 'Hard',
      cognitiveLevel: json['cognitiveLevel']?.toString() ?? 'application',
      questionType: json['questionType']?.toString() ?? 'scenario_mcq',
      status: json['status']?.toString() ?? 'draft',
      version: _toInt(json['version'], defaultValue: 1),
      tags: _stringList(json['tags']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'domain': domain,
      'competencyId': competencyId,
      'subtopicId': subtopicId,
      'topicId': topicId,
      'quizId': quizId,
      'contentPackageId': contentPackageId,
      'question': question,
      'options': options,
      'correctAnswer': correctAnswer,
      'explanation': explanation,
      'bestAnswerRationale': bestAnswerRationale,
      'reference': reference,
      'difficulty': difficulty,
      'cognitiveLevel': cognitiveLevel,
      'questionType': questionType,
      'status': status,
      'version': version,
      'tags': tags,
    };
  }

  static int _toInt(dynamic value, {int defaultValue = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value?.toString() ?? '') ?? defaultValue;
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) {
      return <String>[];
    }

    return value
        .map((item) => item?.toString() ?? '')
        .where((item) => item.trim().isNotEmpty)
        .toList();
  }
}
