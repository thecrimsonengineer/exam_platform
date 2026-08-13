enum SubtopicQuizStatusType {
  notAttempted,
  inProgress,
  completed,
}

class SubtopicQuizStatus {
  final SubtopicQuizStatusType status;
  final int questionCount;
  final int? correctAnswers;

  const SubtopicQuizStatus({
    required this.status,
    required this.questionCount,
    this.correctAnswers,
  });

  bool get hasScore =>
      correctAnswers != null && questionCount > 0;

  double? get score {
    if (!hasScore) {
      return null;
    }

    return correctAnswers! / questionCount;
  }

  String get statusLabel {
    switch (status) {
      case SubtopicQuizStatusType.notAttempted:
        return 'NOT ATTEMPTED';
      case SubtopicQuizStatusType.inProgress:
        return 'IN PROGRESS';
      case SubtopicQuizStatusType.completed:
        return 'COMPLETED';
    }
  }
}
