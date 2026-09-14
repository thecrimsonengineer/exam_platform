import 'package:exam_platform/models/student_learning_progress.dart';
import 'package:exam_platform/services/auth/learner_local_identity.dart';
import 'package:exam_platform/services/student_learning_position_service.dart';
import 'package:exam_platform/services/student_learning_progress_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LearnerLocalIdentity.clear();
  });

  tearDown(LearnerLocalIdentity.clear);

  test(
    'Account A completion is not visible to Account B on the same device',
    () async {
      const service = StudentLearningProgressService();

      LearnerLocalIdentity.activate('uid-A');

      await _complete(
        service,
        subtopicId: 'd07_c01_t01_s01',
        subtopicTitle: 'A completed subtopic',
      );

      final aCompleted = await service.loadSubtopicProgress(
        subtopicId: 'd07_c01_t01_s01',
        expectedContentVersion: 1,
      );

      expect(aCompleted?.state, StudentLearningState.completed);

      LearnerLocalIdentity.activate('uid-B');

      final bInherited = await service.loadSubtopicProgress(
        subtopicId: 'd07_c01_t01_s01',
        expectedContentVersion: 1,
      );

      expect(bInherited, isNull);

      await _complete(
        service,
        subtopicId: 'd07_c01_t01_s02',
        subtopicTitle: 'B completed subtopic',
      );

      LearnerLocalIdentity.activate('uid-A');

      expect(
        await service.loadSubtopicProgress(
          subtopicId: 'd07_c01_t01_s01',
          expectedContentVersion: 1,
        ),
        isNotNull,
      );
      expect(
        await service.loadSubtopicProgress(
          subtopicId: 'd07_c01_t01_s02',
          expectedContentVersion: 1,
        ),
        isNull,
      );

      LearnerLocalIdentity.activate('uid-B');

      expect(
        await service.loadSubtopicProgress(
          subtopicId: 'd07_c01_t01_s02',
          expectedContentVersion: 1,
        ),
        isNotNull,
      );
      expect(
        await service.loadSubtopicProgress(
          subtopicId: 'd07_c01_t01_s01',
          expectedContentVersion: 1,
        ),
        isNull,
      );

      final prefs = await SharedPreferences.getInstance();

      expect(
        prefs.containsKey(
          StudentLearningProgressService.storageKeyForUser('uid-A'),
        ),
        isTrue,
      );
      expect(
        prefs.containsKey(
          StudentLearningProgressService.storageKeyForUser('uid-B'),
        ),
        isTrue,
      );
    },
  );

  test('clearAllProgress clears only the active learner', () async {
    const service = StudentLearningProgressService();

    LearnerLocalIdentity.activate('uid-A');
    await _complete(service, subtopicId: 'd01_c01_t01_s01', subtopicTitle: 'A');

    LearnerLocalIdentity.activate('uid-B');
    await _complete(service, subtopicId: 'd01_c01_t01_s01', subtopicTitle: 'B');

    await service.clearAllProgress();

    expect(await service.loadAllProgress(), isEmpty);

    LearnerLocalIdentity.activate('uid-A');

    final aProgress = await service.loadAllProgress();
    expect(aProgress['d01_c01_t01_s01']?.state, StudentLearningState.completed);
  });

  test('Continue Learning position is isolated by Firebase UID', () async {
    const service = StudentLearningPositionService();

    LearnerLocalIdentity.activate('uid-A');

    await service.savePosition(
      domainId: 'd07',
      domainNumber: 7,
      domainTitle: 'Training',
      competencyId: 'd07_c01',
      competencyTitle: 'Account A competency',
      subtopicId: 'd07_c01_t01_s01',
      subtopicTitle: 'Account A subtopic',
    );

    LearnerLocalIdentity.activate('uid-B');

    expect(await service.loadPosition(), isNull);

    await service.savePosition(
      domainId: 'd04',
      domainNumber: 4,
      domainTitle: 'Emergency Management',
      competencyId: 'd04_c01',
      competencyTitle: 'Account B competency',
      subtopicId: 'd04_c01_t01_s01',
      subtopicTitle: 'Account B subtopic',
    );

    final bPosition = await service.loadPosition();
    expect(bPosition?.competencyId, 'd04_c01');

    LearnerLocalIdentity.activate('uid-A');

    final aPosition = await service.loadPosition();
    expect(aPosition?.competencyId, 'd07_c01');
    expect(aPosition?.subtopicId, 'd07_c01_t01_s01');
  });

  test('clearPosition clears only the active learner', () async {
    const service = StudentLearningPositionService();

    LearnerLocalIdentity.activate('uid-A');
    await _savePosition(service, competencyId: 'd01_c01');

    LearnerLocalIdentity.activate('uid-B');
    await _savePosition(service, competencyId: 'd02_c01');

    await service.clearPosition();
    expect(await service.loadPosition(), isNull);

    LearnerLocalIdentity.activate('uid-A');
    expect((await service.loadPosition())?.competencyId, 'd01_c01');
  });

  test(
    'legacy device-global learner data is ignored, not reassigned',
    () async {
      final legacyRecord = _record(
        subtopicId: 'd01_c01_t01_s01',
        subtopicTitle: 'Legacy subtopic',
      );

      SharedPreferences.setMockInitialValues({
        StudentLearningProgressService.legacyStorageKey:
            encodeStudentProgressMap({legacyRecord.subtopicId: legacyRecord}),
        'csp11.student.learning_position.domain_id': 'd01',
        'csp11.student.learning_position.domain_number': 1,
        'csp11.student.learning_position.domain_title': 'Legacy Domain',
        'csp11.student.learning_position.competency_id': 'd01_c01',
        'csp11.student.learning_position.competency_title': 'Legacy Competency',
        'csp11.student.learning_position.subtopic_id': 'd01_c01_t01_s01',
        'csp11.student.learning_position.subtopic_title': 'Legacy Subtopic',
        'csp11.student.learning_position.last_opened_at':
            '2026-09-10T10:00:00.000Z',
      });

      LearnerLocalIdentity.activate('uid-new-user');

      const progressService = StudentLearningProgressService();
      const positionService = StudentLearningPositionService();

      expect(await progressService.loadAllProgress(), isEmpty);
      expect(await positionService.loadPosition(), isNull);

      final prefs = await SharedPreferences.getInstance();

      expect(
        prefs.containsKey(StudentLearningProgressService.legacyStorageKey),
        isTrue,
      );
      expect(
        prefs.containsKey('csp11.student.learning_position.domain_id'),
        isTrue,
      );
    },
  );

  test('storage operations require an authenticated learner UID', () async {
    const progressService = StudentLearningProgressService();
    const positionService = StudentLearningPositionService();

    expect(progressService.loadAllProgress, throwsA(isA<StateError>()));
    expect(positionService.loadPosition, throwsA(isA<StateError>()));
  });

  test('explicit UID override supports deterministic service tests', () async {
    const service = StudentLearningProgressService(userIdOverride: 'test-user');

    await _complete(
      service,
      subtopicId: 'd03_c01_t01_s01',
      subtopicTitle: 'Test subtopic',
    );

    expect(
      (await service.loadAllProgress())['d03_c01_t01_s01']?.state,
      StudentLearningState.completed,
    );
  });
}

Future<void> _complete(
  StudentLearningProgressService service, {
  required String subtopicId,
  required String subtopicTitle,
}) {
  return service.completeSubtopic(
    domainId: 'd07',
    domainNumber: 7,
    domainTitle: 'Training',
    competencyId: 'd07_c01',
    competencyTitle: 'Training competency',
    subtopicId: subtopicId,
    subtopicTitle: subtopicTitle,
    studyContentId: 'content_d07_c01',
    studyContentVersion: 1,
  );
}

Future<void> _savePosition(
  StudentLearningPositionService service, {
  required String competencyId,
}) {
  return service.savePosition(
    domainId: 'd01',
    domainNumber: 1,
    domainTitle: 'Domain 1',
    competencyId: competencyId,
    competencyTitle: competencyId,
  );
}

StudentSubtopicProgress _record({
  required String subtopicId,
  required String subtopicTitle,
}) {
  final now = DateTime.utc(2026, 9, 10, 10);

  return StudentSubtopicProgress(
    domainId: 'd01',
    domainNumber: 1,
    domainTitle: 'Domain 1',
    competencyId: 'd01_c01',
    competencyTitle: 'Competency 1',
    subtopicId: subtopicId,
    subtopicTitle: subtopicTitle,
    studyContentId: 'content_d01_c01',
    studyContentVersion: 1,
    state: StudentLearningState.completed,
    lastOpenedAt: now,
    completedAt: now,
  );
}
