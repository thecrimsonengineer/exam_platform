import '../models/student_learning_progress.dart';
import '../models/student_resume_decision.dart';
import 'student_learning_position_service.dart';
import 'student_learning_progress_service.dart';

/// Produces the learner-facing continuation decision from existing
/// position and progress data.
class StudentResumeIntelligenceService {
  const StudentResumeIntelligenceService();

  Future<StudentResumeDecision> decide() async {
    const positionService = StudentLearningPositionService();
    const progressService = StudentLearningProgressService();

    final position = await positionService.loadPosition();

    if (position == null ||
        position.domainId.trim().isEmpty ||
        position.competencyId.trim().isEmpty ||
        position.subtopicId == null ||
        position.subtopicId!.trim().isEmpty) {
      return const StudentResumeDecision(
        type: StudentResumeDecisionType.noPosition,
      );
    }

    final subtopicId = position.subtopicId!;

    final progress = await progressService.loadSubtopicProgress(
      subtopicId: subtopicId,
    );

    if (progress?.state == StudentLearningState.completed) {
      return StudentResumeDecision(
        type: StudentResumeDecisionType.reviewCompleted,
        domainId: position.domainId,
        domainNumber: position.domainNumber,
        domainTitle: position.domainTitle,
        competencyId: position.competencyId,
        competencyTitle: position.competencyTitle,
        subtopicId: subtopicId,
        subtopicTitle: position.subtopicTitle,
      );
    }

    return StudentResumeDecision(
      type: StudentResumeDecisionType.continueInProgress,
      domainId: position.domainId,
      domainNumber: position.domainNumber,
      domainTitle: position.domainTitle,
      competencyId: position.competencyId,
      competencyTitle: position.competencyTitle,
      subtopicId: subtopicId,
      subtopicTitle: position.subtopicTitle,
    );
  }
}
