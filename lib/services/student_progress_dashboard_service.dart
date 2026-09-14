import '../data/csp11_blueprint.dart';
import '../models/student_learning_progress.dart';
import '../models/student_progress_dashboard.dart';
import '../models/student_question_progress.dart';
import '../models/study_content.dart';
import 'student_learning_progress_service.dart';
import 'student_question_progress_service.dart';
import 'study_content_loader.dart';

/// Builds the CSP11 learner progress dashboard from published StudyContent and
/// UID-scoped local learner activity.
///
/// Subtopic progress is the authoritative persisted learning state.
/// Topic completion remains derived: a non-empty Topic is complete only when
/// every child Subtopic is complete for the current content version.
///
/// Question completion is independent from learning completion. A question is
/// counted as completed when the learner has submitted it at least once.
class StudentProgressDashboardService {
  const StudentProgressDashboardService();

  Future<StudentProgressDashboard> loadDashboard() async {
    final loader = const StudyContentLoader();
    final contents = await loader.loadPublishedContent();

    final subtopicService = const StudentLearningProgressService();
    final subtopicProgress = await subtopicService.loadAllProgress();

    final questionService = const StudentQuestionProgressService();
    final questionProgress = await questionService.loadAllProgress();

    return buildDashboard(
      contents: contents,
      subtopicProgress: subtopicProgress,
      questionProgress: questionProgress,
    );
  }

  static StudentProgressDashboard buildDashboard({
    required Iterable<StudyContent> contents,
    required Map<String, StudentSubtopicProgress> subtopicProgress,
    Map<int, StudentQuestionProgress> questionProgress = const {},
  }) {
    final contentList = contents.toList(growable: false);
    final domains = <StudentDomainProgress>[];

    final topicForSubtopic = <String, String>{};

    for (final content in contentList) {
      for (final topic in content.topics) {
        for (final subtopic in topic.subtopics) {
          topicForSubtopic[subtopic.id] = topic.id;
        }
      }
    }

    String resolvedQuestionTopic(StudentQuestionProgress record) {
      final direct = record.topicId.trim();

      if (direct.isNotEmpty) {
        return direct;
      }

      return topicForSubtopic[record.subtopicId] ?? '';
    }

    for (final domain in csp11Domains) {
      final domainContents = contentList
          .where((content) => content.domainId == domain.id)
          .toList(growable: false);

      final competencyDetails = <StudentCompetencyProgressDetail>[];

      var domainSubtopicCount = 0;
      var domainCompletedSubtopics = 0;
      var domainTopicCount = 0;
      var domainCompletedTopics = 0;

      for (final content in domainContents) {
        final topicDetails = <StudentTopicProgressDetail>[];

        var competencySubtopicCount = 0;
        var competencyCompletedSubtopics = 0;
        var competencyCompletedTopics = 0;

        for (final topic in content.topics) {
          final subtopicDetails = <StudentSubtopicProgressDetail>[];
          var completedInTopic = 0;

          for (final subtopic in topic.subtopics) {
            final record = subtopicProgress[subtopic.id];

            final belongsToCurrentContent =
                record?.studyContentId == content.id &&
                record?.studyContentVersion == content.version;

            final completed =
                belongsToCurrentContent &&
                record?.state == StudentLearningState.completed;

            final inProgress =
                belongsToCurrentContent &&
                record?.state == StudentLearningState.inProgress;

            if (completed) {
              completedInTopic++;
            }

            final subtopicQuestions = questionProgress.values.where(
              (question) => question.subtopicId == subtopic.id,
            );

            subtopicDetails.add(
              StudentSubtopicProgressDetail(
                subtopicId: subtopic.id,
                title: subtopic.title,
                completed: completed,
                inProgress: inProgress,
                answeredQuestions: subtopicQuestions.length,
                correctQuestions: subtopicQuestions
                    .where((item) => item.everCorrect)
                    .length,
              ),
            );
          }

          final topicQuestions = questionProgress.values.where(
            (question) => resolvedQuestionTopic(question) == topic.id,
          );

          final detail = StudentTopicProgressDetail(
            topicId: topic.id,
            title: topic.title,
            subtopicCount: topic.subtopics.length,
            completedSubtopics: completedInTopic,
            answeredQuestions: topicQuestions.length,
            correctQuestions: topicQuestions
                .where((item) => item.everCorrect)
                .length,
            subtopics: subtopicDetails,
          );

          topicDetails.add(detail);

          competencySubtopicCount += detail.subtopicCount;
          competencyCompletedSubtopics += detail.completedSubtopics;

          if (detail.completed) {
            competencyCompletedTopics++;
          }
        }

        final competencyQuestions = questionProgress.values.where(
          (question) => question.competencyId == content.competencyId,
        );

        competencyDetails.add(
          StudentCompetencyProgressDetail(
            competencyId: content.competencyId,
            competencyNumber: content.competencyNumber,
            title: content.title,
            topicCount: topicDetails.length,
            completedTopics: competencyCompletedTopics,
            subtopicCount: competencySubtopicCount,
            completedSubtopics: competencyCompletedSubtopics,
            answeredQuestions: competencyQuestions.length,
            correctQuestions: competencyQuestions
                .where((item) => item.everCorrect)
                .length,
            topics: topicDetails,
          ),
        );

        domainTopicCount += topicDetails.length;
        domainCompletedTopics += competencyCompletedTopics;
        domainSubtopicCount += competencySubtopicCount;
        domainCompletedSubtopics += competencyCompletedSubtopics;
      }

      final domainQuestions = questionProgress.values.where(
        (question) => question.domainNumber == domain.number,
      );

      domains.add(
        StudentDomainProgress(
          domainId: domain.id,
          domainNumber: domain.number,
          title: domain.title,
          competencyCount: competencyDetails.length,
          subtopicCount: domainSubtopicCount,
          completedSubtopics: domainCompletedSubtopics,
          topicCount: domainTopicCount,
          completedTopics: domainCompletedTopics,
          answeredQuestions: domainQuestions.length,
          correctQuestions: domainQuestions
              .where((item) => item.everCorrect)
              .length,
          competencies: competencyDetails,
        ),
      );
    }

    DateTime? latestActivity;

    void consider(DateTime value) {
      if (latestActivity == null || value.isAfter(latestActivity!)) {
        latestActivity = value;
      }
    }

    for (final record in subtopicProgress.values) {
      consider(record.lastOpenedAt);
    }

    for (final record in questionProgress.values) {
      consider(record.lastAnsweredAt);
    }

    return StudentProgressDashboard(
      domains: domains,
      latestActivity: latestActivity,
    );
  }
}
