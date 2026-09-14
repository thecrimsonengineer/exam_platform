import 'package:exam_platform/models/student_learning_progress.dart';
import 'package:exam_platform/models/study_content.dart';
import 'package:exam_platform/models/student_progress_dashboard.dart';
import 'package:exam_platform/services/student_learning_progress_service.dart';
import 'package:exam_platform/services/student_progress_dashboard_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StudentProgressDashboardService canonical Topic roll-up', () {
    test('0 of 3 completed does not complete the Topic', () {
      final dashboard = StudentProgressDashboardService.buildDashboard(
        contents: [
          _contentWithTopics([_topic('t01', 3)]),
        ],
        subtopicProgress: const {},
      );

      final domain = _domain01(dashboard);

      expect(domain.topicCount, 1);
      expect(domain.completedTopics, 0);
      expect(domain.subtopicCount, 3);
      expect(domain.completedSubtopics, 0);
    });

    test('2 of 3 completed does not complete the Topic', () {
      final dashboard = StudentProgressDashboardService.buildDashboard(
        contents: [
          _contentWithTopics([_topic('t01', 3)]),
        ],
        subtopicProgress: {
          't01_s01': _progress('t01_s01'),
          't01_s02': _progress('t01_s02'),
        },
      );

      final domain = _domain01(dashboard);

      expect(domain.topicCount, 1);
      expect(domain.completedTopics, 0);
      expect(domain.subtopicCount, 3);
      expect(domain.completedSubtopics, 2);
    });

    test('3 of 3 completed completes the Topic exactly once', () {
      final dashboard = StudentProgressDashboardService.buildDashboard(
        contents: [
          _contentWithTopics([_topic('t01', 3)]),
        ],
        subtopicProgress: {
          't01_s01': _progress('t01_s01'),
          't01_s02': _progress('t01_s02'),
          't01_s03': _progress('t01_s03'),
        },
      );

      final domain = _domain01(dashboard);

      expect(domain.topicCount, 1);
      expect(domain.completedTopics, 1);
      expect(domain.subtopicCount, 3);
      expect(domain.completedSubtopics, 3);
    });

    test('mixed Topics roll up independently', () {
      final dashboard = StudentProgressDashboardService.buildDashboard(
        contents: [
          _contentWithTopics([_topic('t01', 2), _topic('t02', 3)]),
        ],
        subtopicProgress: {
          't01_s01': _progress('t01_s01'),
          't01_s02': _progress('t01_s02'),
          't02_s01': _progress('t02_s01'),
        },
      );

      final domain = _domain01(dashboard);

      expect(domain.topicCount, 2);
      expect(domain.completedTopics, 1);
      expect(domain.subtopicCount, 5);
      expect(domain.completedSubtopics, 3);
    });

    test(
      'progress from an old content version does not complete current content',
      () {
        final dashboard = StudentProgressDashboardService.buildDashboard(
          contents: [
            _contentWithTopics([_topic('t01', 1)], version: 2),
          ],
          subtopicProgress: {
            't01_s01': _progress('t01_s01', contentVersion: 1),
          },
        );

        final domain = _domain01(dashboard);

        expect(domain.topicCount, 1);
        expect(domain.completedTopics, 0);
        expect(domain.completedSubtopics, 0);
      },
    );

    test('empty Topic is counted but never treated as completed', () {
      final dashboard = StudentProgressDashboardService.buildDashboard(
        contents: [
          _contentWithTopics([
            const StudyTopic(id: 't01', title: 'Empty Topic'),
          ]),
        ],
        subtopicProgress: const {},
      );

      final domain = _domain01(dashboard);

      expect(domain.topicCount, 1);
      expect(domain.completedTopics, 0);
      expect(domain.subtopicCount, 0);
    });
  });

  group('StudentLearningProgressService completion stability', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test(
      'reopening a completed Subtopic does not downgrade completion',
      () async {
        const service = StudentLearningProgressService(
          userIdOverride: 'test-student',
        );

        await service.completeSubtopic(
          domainId: 'd01',
          domainNumber: 1,
          domainTitle: 'Domain 1',
          competencyId: 'd01_c01',
          competencyTitle: 'Competency 1',
          subtopicId: 'd01_c01_t01_s01',
          subtopicTitle: 'Subtopic 1',
          studyContentId: 'content_d01_c01',
          studyContentVersion: 1,
        );

        await service.markInProgress(
          domainId: 'd01',
          domainNumber: 1,
          domainTitle: 'Domain 1',
          competencyId: 'd01_c01',
          competencyTitle: 'Competency 1',
          subtopicId: 'd01_c01_t01_s01',
          subtopicTitle: 'Subtopic 1',
          studyContentId: 'content_d01_c01',
          studyContentVersion: 1,
        );

        final record = await service.loadSubtopicProgress(
          subtopicId: 'd01_c01_t01_s01',
          expectedContentVersion: 1,
        );

        expect(record, isNotNull);
        expect(record!.state, StudentLearningState.completed);
        expect(record.completedAt, isNotNull);
      },
    );
  });
}

StudyContent _contentWithTopics(List<StudyTopic> topics, {int version = 1}) {
  return StudyContent(
    id: 'content_d01_c01',
    domainId: 'd01',
    competencyId: 'd01_c01',
    competencyNumber: 1,
    title: 'Competency 1',
    status: 'Published',
    version: version,
    topics: topics,
  );
}

StudyTopic _topic(String id, int subtopicCount) {
  return StudyTopic(
    id: id,
    title: 'Topic $id',
    subtopics: List.generate(
      subtopicCount,
      (index) => StudySubtopic(
        id: '${id}_s${(index + 1).toString().padLeft(2, '0')}',
        title: 'Subtopic ${index + 1}',
      ),
    ),
  );
}

StudentSubtopicProgress _progress(String subtopicId, {int contentVersion = 1}) {
  final now = DateTime.utc(2026, 9, 9, 12);

  return StudentSubtopicProgress(
    domainId: 'd01',
    domainNumber: 1,
    domainTitle: 'Domain 1',
    competencyId: 'd01_c01',
    competencyTitle: 'Competency 1',
    subtopicId: subtopicId,
    subtopicTitle: subtopicId,
    studyContentId: 'content_d01_c01',
    studyContentVersion: contentVersion,
    state: StudentLearningState.completed,
    lastOpenedAt: now,
    completedAt: now,
  );
}

StudentDomainProgress _domain01(StudentProgressDashboard dashboard) {
  return dashboard.domains.firstWhere((domain) => domain.domainId == 'd01');
}
