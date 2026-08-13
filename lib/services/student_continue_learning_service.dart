import '../models/student_continue_learning.dart';
import '../models/student_learning_progress.dart';
import 'student_learning_position_service.dart';
import 'student_learning_progress_service.dart';

/// Combines the existing learner-position and learner-progress services
/// into a single model for the Courses/Continue experience.
class StudentContinueLearningService {
  const StudentContinueLearningService();

  Future<StudentContinueLearning?> load() async {
    const positionService = StudentLearningPositionService();
    const progressService = StudentLearningProgressService();

    final position = await positionService.loadPosition();

    if (position == null) {
      return null;
    }

    final domainId = position.domainId;
    final competencyId = position.competencyId;
    final subtopicId = position.subtopicId;
    final subtopicTitle = position.subtopicTitle;

    if (domainId.trim().isEmpty ||
        competencyId.trim().isEmpty ||
        subtopicId == null ||
        subtopicTitle == null ||
        subtopicId.trim().isEmpty ||
        subtopicTitle.trim().isEmpty) {
      return null;
    }

    final progress = await progressService.loadSubtopicProgress(
      subtopicId: subtopicId,
    );

    final state = progress?.state ?? StudentLearningState.inProgress;

    return StudentContinueLearning(
      domainId: domainId,
      domainNumber: position.domainNumber,
      domainTitle: position.domainTitle,
      competencyId: competencyId,
      competencyTitle: position.competencyTitle,
      subtopicId: subtopicId,
      subtopicTitle: subtopicTitle,
      state: state,
      lastOpenedAt: progress?.lastOpenedAt ?? position.lastOpenedAt,
    );
  }
}
