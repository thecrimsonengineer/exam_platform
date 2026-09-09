import '../data/csp11_blueprint.dart';
import '../models/student_learning_progress.dart';
import '../models/student_progress_dashboard.dart';
import '../models/study_content.dart';
import 'student_learning_progress_service.dart';
import 'study_content_loader.dart';

/// Builds learner progress strictly from published content and persisted
/// learner activity.
///
/// Subtopic progress is authoritative persisted learner state.
/// Topic completion is derived from the completion state of every Subtopic
/// that belongs to that Topic. Topic completion is not persisted separately.
class StudentProgressDashboardService {
  const StudentProgressDashboardService();

  Future<StudentProgressDashboard> loadDashboard() async {
    final loader = const StudyContentLoader();
    final contents = await loader.loadPublishedContent();

    final subtopicService = const StudentLearningProgressService();
    final subtopicProgress = await subtopicService.loadAllProgress();

    return buildDashboard(
      contents: contents,
      subtopicProgress: subtopicProgress,
    );
  }

  /// Pure progress aggregation used by the real dashboard and regression tests.
  ///
  /// A Topic is complete only when it contains at least one Subtopic and every
  /// child Subtopic has a completed progress record for the same content ID
  /// and content version currently being aggregated.
  static StudentProgressDashboard buildDashboard({
    required Iterable<StudyContent> contents,
    required Map<String, StudentSubtopicProgress> subtopicProgress,
  }) {
    final contentList = contents.toList(growable: false);
    final domains = <StudentDomainProgress>[];

    for (final domain in csp11Domains) {
      final domainContents = contentList.where(
        (content) => content.domainId == domain.id,
      );

      final competencyIds = <String>{};
      var subtopicCount = 0;
      var completedSubtopics = 0;
      var topicCount = 0;
      var completedTopics = 0;

      for (final content in domainContents) {
        competencyIds.add(content.competencyId);

        for (final topic in content.topics) {
          topicCount++;

          var topicCompleted = topic.subtopics.isNotEmpty;

          for (final subtopic in topic.subtopics) {
            subtopicCount++;

            final record = subtopicProgress[subtopic.id];
            final belongsToCurrentContent =
                record?.studyContentId == content.id &&
                record?.studyContentVersion == content.version;
            final subtopicCompleted =
                belongsToCurrentContent &&
                record?.state == StudentLearningState.completed;

            if (subtopicCompleted) {
              completedSubtopics++;
            } else {
              topicCompleted = false;
            }
          }

          if (topicCompleted) {
            completedTopics++;
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

    return StudentProgressDashboard(
      domains: domains,
      latestActivity: latestActivity,
    );
  }
}
