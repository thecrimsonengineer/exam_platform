import 'dart:convert';

import 'package:exam_platform/features/exam_readiness/models/daily_study_plan.dart';
import 'package:exam_platform/features/exam_readiness/models/study_plan_block.dart';
import 'package:exam_platform/features/exam_readiness/repositories/daily_study_plan_repository.dart';
import 'package:exam_platform/features/exam_readiness/services/daily_study_plan_service.dart';
import 'package:exam_platform/features/exam_readiness/services/ultra_hard_availability_service.dart';
import 'package:exam_platform/models/question.dart';
import 'package:exam_platform/services/auth/learner_local_identity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '_support/m7d_fixture.dart';

class _FakeRemote implements DailyStudyPlanRemoteStore {
  final List<DailyStudyPlan> plans = [];
  int saveCalls = 0;
  int loadCalls = 0;

  @override
  Future<List<DailyStudyPlan>> loadPlans(String userId) async {
    loadCalls++;
    return plans.where((plan) => plan.userId == userId).toList();
  }

  @override
  Future<void> savePlan(DailyStudyPlan plan) async {
    saveCalls++;
    plans.add(plan);
  }
}

DailyStudyPlan generated({
  int minutes = 60,
  DailyStudyPlan? existing,
}) {
  const service = DailyStudyPlanService();
  return service.generate(
    userId: 'u1',
    date: DateTime(2026, 9, 18),
    generatedAt: DateTime(2026, 9, 18, 8 + (existing?.planVersion ?? 0)),
    examDate: DateTime(2026, 12, 15),
    availableMinutes: minutes,
    readinessProfiles: const {},
    existingPlan: existing,
    generationReason: existing == null
        ? DailyStudyPlanGenerationReason.initial
        : DailyStudyPlanGenerationReason.manualRequest,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LearnerLocalIdentity.activate('u1');
  });

  tearDown(LearnerLocalIdentity.clear);

  group('M7D Ultra Hard availability', () {
    test('four published Ultra Hard questions are insufficient', () {
      final questions = [
        for (var i = 0; i < 4; i++) m7dQuestion(id: i + 1),
      ];
      expect(
        UltraHardAvailabilityService.fromQuestions(questions),
        isEmpty,
      );
    });

    test('five published Ultra Hard questions unlock competency', () {
      final questions = [
        for (var i = 0; i < 5; i++) m7dQuestion(id: i + 1),
      ];
      expect(
        UltraHardAvailabilityService.fromQuestions(questions),
        contains('d03_c02'),
      );
    });

    test('unpublished Ultra Hard questions do not count', () {
      final questions = [
        for (var i = 0; i < 5; i++)
          m7dQuestion(id: i + 1, status: 'draft'),
      ];
      expect(
        UltraHardAvailabilityService.fromQuestions(questions),
        isEmpty,
      );
    });

    test('ordinary Hard questions do not count as Ultra Hard', () {
      final questions = [
        for (var i = 0; i < 5; i++)
          m7dQuestion(id: i + 1, ultraHard: false),
      ];
      expect(
        UltraHardAvailabilityService.fromQuestions(questions),
        isEmpty,
      );
    });

    test('four Ultra Hard plus one ordinary Hard remains insufficient', () {
      final questions = [
        for (var i = 0; i < 4; i++) m7dQuestion(id: i + 1),
        m7dQuestion(id: 99, ultraHard: false),
      ];
      expect(
        UltraHardAvailabilityService.fromQuestions(questions),
        isEmpty,
      );
    });

    test('availability is counted independently by competency', () {
      final questions = [
        for (var i = 0; i < 5; i++)
          m7dQuestion(id: i + 1, competencyId: 'd03_c02'),
        for (var i = 0; i < 4; i++)
          m7dQuestion(id: 20 + i, competencyId: 'd06_c06'),
      ];
      final available =
          UltraHardAvailabilityService.fromQuestions(questions);
      expect(available, contains('d03_c02'));
      expect(available, isNot(contains('d06_c06')));
    });

    test('two competencies can both be Ultra Hard available', () {
      final questions = [
        for (var i = 0; i < 5; i++)
          m7dQuestion(id: i + 1, competencyId: 'd03_c02'),
        for (var i = 0; i < 5; i++)
          m7dQuestion(id: 20 + i, competencyId: 'd06_c06'),
      ];
      final available =
          UltraHardAvailabilityService.fromQuestions(questions);
      expect(available, containsAll(['d03_c02', 'd06_c06']));
    });

    test('malformed competency ID cannot become available', () {
      final questions = [
        for (var i = 0; i < 5; i++)
          m7dQuestion(id: i + 1, competencyId: 'bad'),
      ];
      expect(
        UltraHardAvailabilityService.fromQuestions(questions),
        isEmpty,
      );
    });

    test('classification tag comparison is case-insensitive', () {
      final questions = [
        for (var i = 0; i < 5; i++)
          Question.fromJson({
            ...m7dQuestion(id: i + 1).toJson(),
            'tags': const ['ULTRA-HARD-DQG300'],
          }),
      ];
      expect(
        UltraHardAvailabilityService.fromQuestions(questions),
        contains('d03_c02'),
      );
    });
  });

  group('M7D DailyStudyPlanRepository', () {
    test('empty repository returns empty history', () async {
      final repository = DailyStudyPlanRepository(userIdOverride: 'u1');
      expect(await repository.loadHistory(), isEmpty);
    });

    test('save stores first version locally', () async {
      final repository = DailyStudyPlanRepository(userIdOverride: 'u1');
      await repository.savePlan(generated(), syncRemote: false);
      expect(await repository.loadHistory(), hasLength(1));
    });

    test('identical same version save is idempotent', () async {
      final repository = DailyStudyPlanRepository(userIdOverride: 'u1');
      final plan = generated();
      await repository.savePlan(plan, syncRemote: false);
      await repository.savePlan(plan, syncRemote: false);
      expect(await repository.loadHistory(), hasLength(1));
    });

    test('changed same version is rejected as immutable', () async {
      final repository = DailyStudyPlanRepository(userIdOverride: 'u1');
      final plan = generated();
      await repository.savePlan(plan, syncRemote: false);
      final altered = plan.copyWith(
        availableMinutes: plan.availableMinutes + 5,
      );
      expect(
        () => repository.savePlan(altered, syncRemote: false),
        throwsStateError,
      );
    });

    test('new version is appended rather than overwritten', () async {
      final repository = DailyStudyPlanRepository(userIdOverride: 'u1');
      final first = generated();
      final second = generated(existing: first);
      await repository.savePlan(first, syncRemote: false);
      await repository.savePlan(second, syncRemote: false);
      expect(await repository.loadHistory(), hasLength(2));
    });

    test('latest for date returns highest version', () async {
      final repository = DailyStudyPlanRepository(userIdOverride: 'u1');
      final first = generated();
      final second = generated(existing: first);
      await repository.savePlan(first, syncRemote: false);
      await repository.savePlan(second, syncRemote: false);
      final latest = await repository.loadLatestForDate(
        DateTime(2026, 9, 18),
      );
      expect(latest?.planVersion, second.planVersion);
    });

    test('latest for another date returns null', () async {
      final repository = DailyStudyPlanRepository(userIdOverride: 'u1');
      await repository.savePlan(generated(), syncRemote: false);
      expect(
        await repository.loadLatestForDate(DateTime(2026, 9, 19)),
        isNull,
      );
    });

    test('ownership mismatch is rejected', () async {
      final repository = DailyStudyPlanRepository(userIdOverride: 'other');
      expect(
        () => repository.savePlan(generated(), syncRemote: false),
        throwsStateError,
      );
    });

    test('local storage key is learner scoped', () {
      expect(
        DailyStudyPlanRepository.storageKeyForUser('u1'),
        isNot(DailyStudyPlanRepository.storageKeyForUser('u2')),
      );
    });

    test('clearLocal removes history', () async {
      final repository = DailyStudyPlanRepository(userIdOverride: 'u1');
      await repository.savePlan(generated(), syncRemote: false);
      await repository.clearLocal();
      expect(await repository.loadHistory(), isEmpty);
    });

    test('malformed local JSON fails soft', () async {
      SharedPreferences.setMockInitialValues({
        DailyStudyPlanRepository.storageKeyForUser('u1'): '{bad',
      });
      final repository = DailyStudyPlanRepository(userIdOverride: 'u1');
      expect(await repository.loadHistory(), isEmpty);
    });

    test('malformed item does not discard valid plan', () async {
      final valid = generated();
      SharedPreferences.setMockInitialValues({
        DailyStudyPlanRepository.storageKeyForUser('u1'): jsonEncode([
          {'bad': true},
          valid.toJson(),
        ]),
      });
      final repository = DailyStudyPlanRepository(userIdOverride: 'u1');
      final history = await repository.loadHistory();
      expect(history, hasLength(1));
      expect(history.single.planId, valid.planId);
    });

    test('save can sync one new version to remote', () async {
      final remote = _FakeRemote();
      final repository = DailyStudyPlanRepository(
        userIdOverride: 'u1',
        remoteStore: remote,
      );
      await repository.savePlan(generated());
      expect(remote.saveCalls, 1);
    });

    test('idempotent local save avoids duplicate remote write', () async {
      final remote = _FakeRemote();
      final repository = DailyStudyPlanRepository(
        userIdOverride: 'u1',
        remoteStore: remote,
      );
      final plan = generated();
      await repository.savePlan(plan);
      await repository.savePlan(plan);
      expect(remote.saveCalls, 1);
    });

    test('refresh from remote replaces local snapshot history', () async {
      final remote = _FakeRemote()..plans.add(generated());
      final repository = DailyStudyPlanRepository(
        userIdOverride: 'u1',
        remoteStore: remote,
      );
      final refreshed = await repository.refreshFromRemote();
      expect(refreshed, hasLength(1));
      expect(remote.loadCalls, 1);
      expect(await repository.loadHistory(), hasLength(1));
    });

    test('history sorts newer version first', () async {
      final repository = DailyStudyPlanRepository(userIdOverride: 'u1');
      final first = generated();
      final second = generated(existing: first);
      await repository.savePlan(first, syncRemote: false);
      await repository.savePlan(second, syncRemote: false);
      final history = await repository.loadHistory();
      expect(history.first.planVersion, second.planVersion);
    });

    test('history returned to caller is unmodifiable', () async {
      final repository = DailyStudyPlanRepository(userIdOverride: 'u1');
      await repository.savePlan(generated(), syncRemote: false);
      final history = await repository.loadHistory();
      expect(
        () => history.add(generated()),
        throwsUnsupportedError,
      );
    });
  });
}
