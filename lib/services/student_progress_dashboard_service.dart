import '../data/csp11_blueprint.dart';
import '../models/student_learning_progress.dart';
import '../models/student_progress_dashboard.dart';
import '../models/student_topic_progress.dart';
import 'student_learning_progress_service.dart';
import 'student_topic_progress_service.dart';
import 'study_content_loader.dart';

/// Builds learner progress strictly from published content and persisted
/// learner activity.
class StudentProgressDashboardService {
  const StudentProgressDashboardService();

  Future<StudentProgressDashboard> loadDashboard() async {
    final loader = const StudyContentLoader();

    final contents = await loader.loadPublishedContent();

    final subtopicService = const StudentLearningProgressService();
    final topicService = const StudentTopicProgressService();

    final subtopicProgress = await subtopicService.loadAllProgress();
    final topicProgress = await topicService.loadAllProgress();

    final domains = <StudentDomainProgress>[];

    for (final domain in csp11Domains) {
      final domainContents = contents.where(
        (content) => content.domainId == domain.id,
      );

      final competencyIds = <String>{};
      var subtopicCount = 0;
      var completedSubtopics = 0;
      var topicCount = 0;
      var completedTopics = 0;

      for (final content in domainContents) {
        competencyIds.add(content.competencyId);

        for (final subtopic in content.subtopics) {
          subtopicCount++;

          final subtopicRecord = subtopicProgress[subtopic.id];

          if (subtopicRecord?.state == StudentLearningState.completed) {
            completedSubtopics++;
          }

          for (final topic in subtopic.mainContent) {
            topicCount++;

            final key = '${content.id}::${subtopic.id}::${topic.id}';

            final topicRecord = topicProgress[key];

            if (topicRecord?.state == StudentTopicLearningState.completed) {
              completedTopics++;
            }
          }
        }
      }

      domains.add(
        StudentDomainProgress(
          domainId: domain.id,
          domainNumber: domain.number,
          title: domain.title,
          competencyCount: competencyIds.length,
          subtopicCount: subtopicCount,
          completedSubtopics: completedSubtopics,
          topicCount: topicCount,
          completedTopics: completedTopics,
        ),
      );
    }

    DateTime? latestActivity;

    for (final record in subtopicProgress.values) {
      final value = record.lastOpenedAt;

      if (latestActivity == null || value.isAfter(latestActivity)) {
        latestActivity = value;
      }
    }

    for (final record in topicProgress.values) {
      final value = record.completedAt;

      if (value != null &&
          (latestActivity == null || value.isAfter(latestActivity))) {
        latestActivity = value;
      }
    }

    return StudentProgressDashboard(
      domains: domains,
      latestActivity: latestActivity,
    );
  }
}
