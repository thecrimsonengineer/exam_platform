import 'package:exam_platform/models/student_learning_progress.dart';
import 'package:exam_platform/models/student_question_progress.dart';
import 'package:exam_platform/models/study_content.dart';
import 'package:exam_platform/services/student_progress_dashboard_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'dashboard exposes Topic, Subtopic and question completion together',
    () {
      final now = DateTime.utc(2026, 9, 10, 12);

      final content = StudyContent(
        id: 'content_d01_c01',
        domainId: 'd01',
        competencyId: 'd01_c01',
        competencyNumber: 1,
        title: 'Competency One',
        status: 'Published',
        version: 1,
        topics: const [
          StudyTopic(
            id: 'd01_c01_t01',
            title: 'Topic One',
            subtopics: [
              StudySubtopic(id: 'd01_c01_t01_s01', title: 'Subtopic One'),
              StudySubtopic(id: 'd01_c01_t01_s02', title: 'Subtopic Two'),
            ],
          ),
        ],
      );

      final dashboard = StudentProgressDashboardService.buildDashboard(
        contents: [content],
        subtopicProgress: {
          'd01_c01_t01_s01': StudentSubtopicProgress(
            domainId: 'd01',
            domainNumber: 1,
            domainTitle: 'Domain 1',
            competencyId: 'd01_c01',
            competencyTitle: 'Competency One',
            subtopicId: 'd01_c01_t01_s01',
            subtopicTitle: 'Subtopic One',
            studyContentId: 'content_d01_c01',
            studyContentVersion: 1,
            state: StudentLearningState.completed,
            lastOpenedAt: now,
            completedAt: now,
          ),
        },
        questionProgress: {
          101: StudentQuestionProgress(
            questionId: 101,
            domainNumber: 1,
            competencyId: 'd01_c01',
            topicId: 'd01_c01_t01',
            subtopicId: 'd01_c01_t01_s01',
            attemptCount: 1,
            lastCorrect: true,
            everCorrect: true,
            firstAnsweredAt: now,
            lastAnsweredAt: now,
          ),
          102: StudentQuestionProgress(
            questionId: 102,
            domainNumber: 1,
            competencyId: 'd01_c01',
            topicId: '',
            subtopicId: 'd01_c01_t01_s02',
            attemptCount: 1,
            lastCorrect: false,
            everCorrect: false,
            firstAnsweredAt: now,
            lastAnsweredAt: now,
          ),
        },
      );

      final domain = dashboard.domains.firstWhere(
        (item) => item.domainId == 'd01',
      );

      expect(domain.completedSubtopics, 1);
      expect(domain.subtopicCount, 2);
      expect(domain.completedTopics, 0);
      expect(domain.answeredQuestions, 2);
      expect(domain.correctQuestions, 1);

      final topic = domain.competencies.single.topics.single;

      expect(topic.completedSubtopics, 1);
      expect(topic.subtopicCount, 2);
      expect(topic.answeredQuestions, 2);
      expect(topic.correctQuestions, 1);
      expect(topic.completed, isFalse);
    },
  );
}
