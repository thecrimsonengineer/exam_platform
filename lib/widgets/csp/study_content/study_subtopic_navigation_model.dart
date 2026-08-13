/// Describes the learner's position within a competency's subtopic sequence.
///
/// This is intentionally UI-agnostic. It allows StudySubtopicScreen to make
/// Previous / Next decisions without duplicating index calculations.
class StudySubtopicNavigationModel {
  final int currentIndex;
  final int totalCount;

  const StudySubtopicNavigationModel({
    required this.currentIndex,
    required this.totalCount,
  });

  bool get hasPrevious => currentIndex > 0;

  bool get hasNext => currentIndex >= 0 && currentIndex < totalCount - 1;

  int get currentNumber => currentIndex + 1;

  double get progress {
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

  String get positionLabel {
    if (totalCount <= 0 || currentIndex < 0) {
      return 'SUBTOPIC';
    }

    return 'SUBTOPIC ${currentNumber.toString().padLeft(2, '0')} '
        'OF ${totalCount.toString().padLeft(2, '0')}';
  }
}
