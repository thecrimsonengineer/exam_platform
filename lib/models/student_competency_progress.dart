import 'student_learning_progress.dart';

class StudentCompetencyProgress {
  final String competencyId;
  final String competencyTitle;
  final int totalSubtopics;
  final int completedSubtopics;

  const StudentCompetencyProgress({
    required this.competencyId,
    required this.competencyTitle,
    required this.totalSubtopics,
    required this.completedSubtopics,
  });

  double get progress =>
      totalSubtopics == 0
          ? 0
          : completedSubtopics / totalSubtopics;

  StudentLearningState get state {
    if (totalSubtopics == 0 || completedSubtopics == 0) {
      return StudentLearningState.notStarted;
    }

    if (completedSubtopics >= totalSubtopics) {
      return StudentLearningState.completed;
    }

    return StudentLearningState.inProgress;
  }

  String get statusLabel {
    switch (state) {
      case StudentLearningState.notStarted:
        return 'NOT STARTED';
      case StudentLearningState.inProgress:
        return 'IN PROGRESS';
      case StudentLearningState.completed:
        return 'COMPLETED';
    }
  }
}
