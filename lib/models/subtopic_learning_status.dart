enum SubtopicOverallStatus {
  notStarted,
  studying,
  readyForQuiz,
  quizCompleted,
}

class SubtopicLearningStatus {
  final bool studyCompleted;
  final int completedTopics;
  final int totalTopics;
  final bool quizCompleted;
  final int? quizCorrectAnswers;
  final int? quizQuestionCount;

  const SubtopicLearningStatus({
    required this.studyCompleted,
    required this.completedTopics,
    required this.totalTopics,
    required this.quizCompleted,
    this.quizCorrectAnswers,
    this.quizQuestionCount,
  });

  double get topicProgress =>
      totalTopics == 0 ? 0 : completedTopics / totalTopics;

  double? get quizScore {
    if (!quizCompleted ||
        quizCorrectAnswers == null ||
        quizQuestionCount == null ||
        quizQuestionCount == 0) {
      return null;
    }

    return quizCorrectAnswers! / quizQuestionCount!;
  }

  SubtopicOverallStatus get overallStatus {
    if (!studyCompleted && completedTopics == 0) {
      return SubtopicOverallStatus.notStarted;
    }

    if (quizCompleted) {
      return SubtopicOverallStatus.quizCompleted;
    }

    if (studyCompleted && completedTopics >= totalTopics) {
      return SubtopicOverallStatus.readyForQuiz;
    }

    return SubtopicOverallStatus.studying;
  }

  String get statusLabel {
    switch (overallStatus) {
      case SubtopicOverallStatus.notStarted:
        return 'NOT STARTED';
      case SubtopicOverallStatus.studying:
        return 'IN PROGRESS';
      case SubtopicOverallStatus.readyForQuiz:
        return 'READY FOR QUIZ';
      case SubtopicOverallStatus.quizCompleted:
        return 'QUIZ COMPLETED';
    }
  }
}
