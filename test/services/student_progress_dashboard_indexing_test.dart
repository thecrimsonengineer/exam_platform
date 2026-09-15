import 'package:exam_platform/models/student_question_progress.dart';
import 'package:exam_platform/models/study_content.dart';
import 'package:exam_platform/services/student_progress_dashboard_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'indexed question roll-up preserves domain competency topic and subtopic counts',
    () {
      final now = DateTime.utc(2026, 9, 15, 12);

      final content = StudyContent(
        id: 'content-d03-c01',
        domainId: 'd03',
        competencyId: 'd03_c01',
        competencyNumber: 1,
        title: 'Risk Management',
        status: 'published',
        version: 1,
        topics: const [
          StudyTopic(
            id: 'd03_c01_t01',
            title: 'Risk Evaluation',
            subtopics: [
              StudySubtopic(id: 'd03_c01_t01_s01', title: 'Identify Risk'),
              StudySubtopic(id: 'd03_c01_t01_s02', title: 'Evaluate Risk'),
            ],
          ),
        ],
      );

      final dashboard = StudentProgressDashboardService.buildDashboard(
        contents: [content],
        subtopicProgress: const {},
        questionProgress: {
          101: StudentQuestionProgress(
            questionId: 101,
            domainNumber: 3,
            competencyId: 'd03_c01',
            topicId: 'd03_c01_t01',
            subtopicId: 'd03_c01_t01_s01',
            attemptCount: 1,
            lastCorrect: true,
            everCorrect: true,
            firstAnsweredAt: now,
            lastAnsweredAt: now,
          ),
          102: StudentQuestionProgress(
            questionId: 102,
            domainNumber: 3,
            competencyId: 'd03_c01',
            topicId: '',
            subtopicId: 'd03_c01_t01_s02',
            attemptCount: 2,
            lastCorrect: false,
            everCorrect: false,
            firstAnsweredAt: now,
            lastAnsweredAt: now,
          ),
        },
      );

      final domain = dashboard.domains.singleWhere(
        (item) => item.domainId == 'd03',
      );
      final competency = domain.competencies.single;
      final topic = competency.topics.single;

      expect(domain.answeredQuestions, 2);
      expect(domain.correctQuestions, 1);
      expect(competency.answeredQuestions, 2);
      expect(competency.correctQuestions, 1);
      expect(topic.answeredQuestions, 2);
      expect(topic.correctQuestions, 1);
      expect(topic.subtopics[0].answeredQuestions, 1);
      expect(topic.subtopics[0].correctQuestions, 1);
      expect(topic.subtopics[1].answeredQuestions, 1);
      expect(topic.subtopics[1].correctQuestions, 0);
    },
  );
}
