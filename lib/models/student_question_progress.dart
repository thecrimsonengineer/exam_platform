class StudentQuestionProgress {
  final int questionId;
  final int domainNumber;
  final String competencyId;
  final String topicId;
  final String subtopicId;
  final int attemptCount;
  final bool lastCorrect;
  final bool everCorrect;
  final DateTime firstAnsweredAt;
  final DateTime lastAnsweredAt;

  const StudentQuestionProgress({
    required this.questionId,
    required this.domainNumber,
    required this.competencyId,
    required this.topicId,
    required this.subtopicId,
    required this.attemptCount,
    required this.lastCorrect,
    required this.everCorrect,
    required this.firstAnsweredAt,
    required this.lastAnsweredAt,
  });

  factory StudentQuestionProgress.fromJson(Map<String, dynamic> json) {
    final firstAnsweredAt = DateTime.tryParse(
      json['firstAnsweredAt']?.toString() ?? '',
    );
    final lastAnsweredAt = DateTime.tryParse(
      json['lastAnsweredAt']?.toString() ?? '',
    );

    if (firstAnsweredAt == null || lastAnsweredAt == null) {
      throw const FormatException('Invalid question progress timestamp.');
    }

    return StudentQuestionProgress(
      questionId: _toInt(json['questionId']),
      domainNumber: _toInt(json['domainNumber']),
      competencyId: json['competencyId']?.toString() ?? '',
      topicId: json['topicId']?.toString() ?? '',
      subtopicId: json['subtopicId']?.toString() ?? '',
      attemptCount: _toInt(json['attemptCount'], fallback: 1),
      lastCorrect: json['lastCorrect'] == true,
      everCorrect: json['everCorrect'] == true,
      firstAnsweredAt: firstAnsweredAt,
      lastAnsweredAt: lastAnsweredAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'domainNumber': domainNumber,
      'competencyId': competencyId,
      'topicId': topicId,
      'subtopicId': subtopicId,
      'attemptCount': attemptCount,
      'lastCorrect': lastCorrect,
      'everCorrect': everCorrect,
      'firstAnsweredAt': firstAnsweredAt.toIso8601String(),
      'lastAnsweredAt': lastAnsweredAt.toIso8601String(),
    };
  }

  StudentQuestionProgress recordAttempt({
    required bool correct,
    required DateTime answeredAt,
    required int domainNumber,
    required String competencyId,
    required String topicId,
    required String subtopicId,
  }) {
    return StudentQuestionProgress(
      questionId: questionId,
      domainNumber: domainNumber,
      competencyId: competencyId,
      topicId: topicId,
      subtopicId: subtopicId,
      attemptCount: attemptCount + 1,
      lastCorrect: correct,
      everCorrect: everCorrect || correct,
      firstAnsweredAt: firstAnsweredAt,
      lastAnsweredAt: answeredAt,
    );
  }
}

int _toInt(dynamic value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ?? fallback;
}
