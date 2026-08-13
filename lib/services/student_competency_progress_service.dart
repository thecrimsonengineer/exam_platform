import '../models/student_competency_progress.dart';
import '../models/student_learning_progress.dart';
import 'student_learning_progress_service.dart';
import 'study_content_loader.dart';

/// Calculates real competency progress from published content and
/// persisted learner completion.
class StudentCompetencyProgressService {
  const StudentCompetencyProgressService();

  Future<StudentCompetencyProgress> load({
    required String competencyId,
    required String competencyTitle,
  }) async {
    const loader = StudyContentLoader();
    const progressService = StudentLearningProgressService();

    final contents = await loader.loadPublishedContent();
    final progress = await progressService.loadAllProgress();

    var totalSubtopics = 0;
    var completedSubtopics = 0;

    for (final content in contents) {
      if (content.competencyId != competencyId) {
        continue;
      }

      for (final subtopic in content.subtopics) {
        totalSubtopics++;

        final record = progress[subtopic.id];

        if (record?.state == StudentLearningState.completed) {
          completedSubtopics++;
        }
      }
    }

    return StudentCompetencyProgress(
      competencyId: competencyId,
      competencyTitle: competencyTitle,
      totalSubtopics: totalSubtopics,
      completedSubtopics: completedSubtopics,
    );
  }
}
