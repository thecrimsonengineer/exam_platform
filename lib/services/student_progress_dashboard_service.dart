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
/// Inputs are loaded concurrently and question roll-ups are indexed once so
/// Domain / Competency / Topic / Subtopic analytics do not repeatedly rescan
/// the learner's entire question history.
class StudentProgressDashboardService {
  const StudentProgressDashboardService();

  Future<StudentProgressDashboard> loadDashboard() async {
    final results = await Future.wait<dynamic>([
      const StudyContentLoader().loadPublishedContent(),
      const StudentLearningProgressService().loadAllProgress(),
      const StudentQuestionProgressService().loadAllProgress(),
    ]);

    return buildDashboard(
      contents: results[0] as List<StudyContent>,
      subtopicProgress: results[1] as Map<String, StudentSubtopicProgress>,
      questionProgress: results[2] as Map<int, StudentQuestionProgress>,
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

    final answeredBySubtopic = <String, int>{};
    final correctBySubtopic = <String, int>{};
    final answeredByTopic = <String, int>{};
    final correctByTopic = <String, int>{};
    final answeredByCompetency = <String, int>{};
    final correctByCompetency = <String, int>{};
    final answeredByDomain = <int, int>{};
    final correctByDomain = <int, int>{};

    void countString(
      Map<String, int> answered,
      Map<String, int> correct,
      String key,
      StudentQuestionProgress record,
    ) {
      final normalized = key.trim();

      if (normalized.isEmpty) {
        return;
      }

      answered[normalized] = (answered[normalized] ?? 0) + 1;

      if (record.everCorrect) {
        correct[normalized] = (correct[normalized] ?? 0) + 1;
      }
    }

    for (final record in questionProgress.values) {
      countString(
        answeredBySubtopic,
        correctBySubtopic,
        record.subtopicId,
        record,
      );
      countString(
        answeredByTopic,
        correctByTopic,
        resolvedQuestionTopic(record),
        record,
      );
      countString(
        answeredByCompetency,
        correctByCompetency,
        record.competencyId,
        record,
      );

      if (record.domainNumber > 0) {
        answeredByDomain[record.domainNumber] =
            (answeredByDomain[record.domainNumber] ?? 0) + 1;

        if (record.everCorrect) {
          correctByDomain[record.domainNumber] =
              (correctByDomain[record.domainNumber] ?? 0) + 1;
        }
      }
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

            subtopicDetails.add(
              StudentSubtopicProgressDetail(
                subtopicId: subtopic.id,
                title: subtopic.title,
                completed: completed,
                inProgress: inProgress,
                answeredQuestions: answeredBySubtopic[subtopic.id] ?? 0,
                correctQuestions: correctBySubtopic[subtopic.id] ?? 0,
              ),
            );
          }

          final detail = StudentTopicProgressDetail(
            topicId: topic.id,
            title: topic.title,
            subtopicCount: topic.subtopics.length,
            completedSubtopics: completedInTopic,
            answeredQuestions: answeredByTopic[topic.id] ?? 0,
            correctQuestions: correctByTopic[topic.id] ?? 0,
            subtopics: subtopicDetails,
          );

          topicDetails.add(detail);

          competencySubtopicCount += detail.subtopicCount;
          competencyCompletedSubtopics += detail.completedSubtopics;

          if (detail.completed) {
            competencyCompletedTopics++;
          }
        }

        competencyDetails.add(
          StudentCompetencyProgressDetail(
            competencyId: content.competencyId,
            competencyNumber: content.competencyNumber,
            title: content.title,
            topicCount: topicDetails.length,
            completedTopics: competencyCompletedTopics,
            subtopicCount: competencySubtopicCount,
            completedSubtopics: competencyCompletedSubtopics,
            answeredQuestions: answeredByCompetency[content.competencyId] ?? 0,
            correctQuestions: correctByCompetency[content.competencyId] ?? 0,
            topics: topicDetails,
          ),
        );

        domainTopicCount += topicDetails.length;
        domainCompletedTopics += competencyCompletedTopics;
        domainSubtopicCount += competencySubtopicCount;
        domainCompletedSubtopics += competencyCompletedSubtopics;
      }

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
          answeredQuestions: answeredByDomain[domain.number] ?? 0,
          correctQuestions: correctByDomain[domain.number] ?? 0,
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
