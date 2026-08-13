/// Represents the learner's current study-session position.
///
/// This model is deliberately separate from persistent learning progress.
/// Persistent progress answers what the learner has completed.
/// This model answers where the learner currently is in the study sequence.
class StudySessionProgress {
  final int currentIndex;
  final int totalCount;

  const StudySessionProgress({
    required this.currentIndex,
    required this.totalCount,
  });

  int get currentNumber => currentIndex + 1;

  double get fraction {
    if (totalCount <= 0 || currentIndex < 0) {
      return 0;
    }

    final value = currentNumber / totalCount;

    if (value < 0) {
      return 0;
    }

    if (value > 1) {
      return 1;
    }

    return value;
  }

  String get label {
    if (totalCount <= 0 || currentIndex < 0) {
      return 'SUBTOPIC';
    }

    return 'SUBTOPIC ${currentNumber.toString().padLeft(2, '0')} '
        'OF ${totalCount.toString().padLeft(2, '0')}';
  }
}
