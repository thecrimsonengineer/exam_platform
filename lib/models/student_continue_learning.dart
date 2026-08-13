import 'student_learning_progress.dart';

/// Learner-facing continuation information.
///
/// This is an orchestration model. It does not replace the persistent
/// learner-position or learner-progress models.
class StudentContinueLearning {
  final String domainId;
  final int domainNumber;
  final String domainTitle;
  final String competencyId;
  final String competencyTitle;
  final String subtopicId;
  final String subtopicTitle;
  final StudentLearningState state;
  final DateTime? lastOpenedAt;

  const StudentContinueLearning({
    required this.domainId,
    required this.domainNumber,
    required this.domainTitle,
    required this.competencyId,
    required this.competencyTitle,
    required this.subtopicId,
    required this.subtopicTitle,
    required this.state,
    required this.lastOpenedAt,
  });

  bool get isCompleted =>
      state == StudentLearningState.completed;

  bool get isInProgress =>
      state == StudentLearningState.inProgress;

  bool get isNotStarted =>
      state == StudentLearningState.notStarted;

  String get statusLabel {
    if (isCompleted) {
      return 'COMPLETED';
    }

    if (isInProgress) {
      return 'IN PROGRESS';
    }

    return 'NOT STARTED';
  }
}
