import 'dart:convert';

import 'package:exam_platform/features/exam_readiness/models/exam_study_plan.dart';
import 'package:exam_platform/features/exam_readiness/repositories/exam_study_plan_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeRemote implements ExamStudyPlanRemoteStore {
  List<ExamStudyPlan> plans = [];
  int loadCalls = 0;
  int saveCalls = 0;
  int deactivateCalls = 0;
  String? lastActivePlanId;

  @override
  Future<List<ExamStudyPlan>> loadPlans(String userId) async {
    loadCalls++;
    return plans.where((plan) => plan.userId == userId).toList();
  }

  @override
  Future<void> savePlan(ExamStudyPlan plan) async {
    saveCalls++;
    plans.removeWhere((item) => item.id == plan.id);
    plans.add(plan);
  }

  @override
  Future<void> deactivateOtherPlans({
    required String userId,
    required String activePlanId,
  }) async {
    deactivateCalls++;
    lastActivePlanId = activePlanId;
    plans = plans
        .map(
          (plan) =>
              plan.userId == userId &&
                  plan.id != activePlanId &&
                  plan.active
              ? plan.copyWith(active: false)
              : plan,
        )
        .toList();
  }
}

ExamStudyPlan _plan({
  String id = 'plan-1',
  String userId = 'u1',
  bool active = true,
  DateTime? updatedAt,
}) {
  final plan = ExamStudyPlan.create(
    id: id,
    userId: userId,
    examDate: DateTime(2026, 12, 15),
    studyDaysOfWeek: const {1, 2, 3, 5, 6},
    defaultMinutesPerStudyDay: 60,
    now: updatedAt ?? DateTime(2026, 9, 18, 10),
  );
  return plan.copyWith(
    active: active,
    updatedAt: updatedAt ?? plan.updatedAt,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('M7A ExamStudyPlanRepository', () {
    test('storage key is UID scoped', () {
      expect(
        ExamStudyPlanRepository.storageKeyForUser('abc'),
        'csp11.student.abc.exam_readiness.exam_plans.v1',
      );
    });

    test('empty local store returns no plans', () async {
      final repository = ExamStudyPlanRepository(userIdOverride: 'u1');

      expect(await repository.loadLocalPlans(), isEmpty);
      expect(await repository.loadActivePlan(), isNull);
    });

    test('save persists and loads active plan locally', () async {
      final repository = ExamStudyPlanRepository(userIdOverride: 'u1');
      final plan = _plan();

      await repository.savePlan(plan, syncRemote: false);

      expect((await repository.loadActivePlan())?.id, 'plan-1');
    });

    test('save rejects plan owned by another UID', () async {
      final repository = ExamStudyPlanRepository(userIdOverride: 'u1');

      expect(
        () => repository.savePlan(_plan(userId: 'u2'), syncRemote: false),
        throwsA(isA<StateError>()),
      );
    });

    test('new active plan deactivates previous local active plan', () async {
      final repository = ExamStudyPlanRepository(userIdOverride: 'u1');
      await repository.savePlan(_plan(id: 'p1'), syncRemote: false);
      await repository.savePlan(
        _plan(id: 'p2', updatedAt: DateTime(2026, 9, 19)),
        syncRemote: false,
      );

      final plans = await repository.loadLocalPlans();
      final p1 = plans.singleWhere((item) => item.id == 'p1');
      final p2 = plans.singleWhere((item) => item.id == 'p2');

      expect(p1.active, isFalse);
      expect(p2.active, isTrue);
    });

    test('loadActivePlan returns newest active record', () async {
      final repository = ExamStudyPlanRepository(userIdOverride: 'u1');
      final prefs = await SharedPreferences.getInstance();
      final older = _plan(id: 'old', updatedAt: DateTime(2026, 9, 18));
      final newer = _plan(id: 'new', updatedAt: DateTime(2026, 9, 19));

      await prefs.setString(
        ExamStudyPlanRepository.storageKeyForUser('u1'),
        jsonEncode([older.toJson(), newer.toJson()]),
      );

      expect((await repository.loadActivePlan())?.id, 'new');
    });

    test('deactivatePlan marks active plan inactive', () async {
      final repository = ExamStudyPlanRepository(userIdOverride: 'u1');
      await repository.savePlan(_plan(), syncRemote: false);

      await repository.deactivatePlan(
        'plan-1',
        updatedAt: DateTime(2026, 9, 20),
        syncRemote: false,
      );

      expect(await repository.loadActivePlan(), isNull);
    });

    test('deactivatePlan ignores unknown plan ID', () async {
      final repository = ExamStudyPlanRepository(userIdOverride: 'u1');
      await repository.savePlan(_plan(), syncRemote: false);

      await repository.deactivatePlan('missing', syncRemote: false);

      expect((await repository.loadActivePlan())?.id, 'plan-1');
    });

    test('clearLocalPlans removes only active user cache', () async {
      final r1 = ExamStudyPlanRepository(userIdOverride: 'u1');
      final r2 = ExamStudyPlanRepository(userIdOverride: 'u2');
      await r1.savePlan(_plan(userId: 'u1'), syncRemote: false);
      await r2.savePlan(
        _plan(id: 'u2-plan', userId: 'u2'),
        syncRemote: false,
      );

      await r1.clearLocalPlans();

      expect(await r1.loadLocalPlans(), isEmpty);
      expect(await r2.loadLocalPlans(), hasLength(1));
    });

    test('refreshFromRemote writes remote plans into local cache', () async {
      final remote = _FakeRemote()
        ..plans = [
          _plan(
            id: 'remote',
            updatedAt: DateTime(2026, 9, 20),
          ),
        ];
      final repository = ExamStudyPlanRepository(
        userIdOverride: 'u1',
        remoteStore: remote,
      );

      final active = await repository.refreshFromRemote();

      expect(active?.id, 'remote');
      expect(remote.loadCalls, 1);
      expect((await repository.loadLocalPlans()).single.id, 'remote');
    });

    test('loadActivePlan does not hit remote unless refresh requested', () async {
      final remote = _FakeRemote()..plans = [_plan(id: 'remote')];
      final repository = ExamStudyPlanRepository(
        userIdOverride: 'u1',
        remoteStore: remote,
      );

      expect(await repository.loadActivePlan(), isNull);
      expect(remote.loadCalls, 0);
    });

    test('loadActivePlan refresh flag explicitly hits remote', () async {
      final remote = _FakeRemote()..plans = [_plan(id: 'remote')];
      final repository = ExamStudyPlanRepository(
        userIdOverride: 'u1',
        remoteStore: remote,
      );

      final plan = await repository.loadActivePlan(refreshRemote: true);

      expect(plan?.id, 'remote');
      expect(remote.loadCalls, 1);
    });

    test('active remote save deactivates other remote plans first', () async {
      final remote = _FakeRemote();
      final repository = ExamStudyPlanRepository(
        userIdOverride: 'u1',
        remoteStore: remote,
      );

      await repository.savePlan(_plan(id: 'new'));

      expect(remote.deactivateCalls, 1);
      expect(remote.lastActivePlanId, 'new');
      expect(remote.saveCalls, 1);
    });

    test('inactive remote save does not deactivate other plans', () async {
      final remote = _FakeRemote();
      final repository = ExamStudyPlanRepository(
        userIdOverride: 'u1',
        remoteStore: remote,
      );

      await repository.savePlan(_plan(active: false));

      expect(remote.deactivateCalls, 0);
      expect(remote.saveCalls, 1);
    });

    test('syncRemote false performs no remote writes', () async {
      final remote = _FakeRemote();
      final repository = ExamStudyPlanRepository(
        userIdOverride: 'u1',
        remoteStore: remote,
      );

      await repository.savePlan(_plan(), syncRemote: false);

      expect(remote.saveCalls, 0);
      expect(remote.deactivateCalls, 0);
    });

    test('malformed local JSON fails soft to an empty plan set', () async {
      SharedPreferences.setMockInitialValues({
        ExamStudyPlanRepository.storageKeyForUser('u1'): '{broken',
      });
      final repository = ExamStudyPlanRepository(userIdOverride: 'u1');

      expect(await repository.loadLocalPlans(), isEmpty);
    });

    test('one malformed local item does not discard valid plan', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        ExamStudyPlanRepository.storageKeyForUser('u1'),
        jsonEncode([
          {'bad': 'record'},
          _plan().toJson(),
        ]),
      );
      final repository = ExamStudyPlanRepository(userIdOverride: 'u1');

      final plans = await repository.loadLocalPlans();

      expect(plans, hasLength(1));
      expect(plans.single.id, 'plan-1');
    });

    test('refresh without remote store falls back to local plan', () async {
      final repository = ExamStudyPlanRepository(userIdOverride: 'u1');
      await repository.savePlan(_plan(), syncRemote: false);

      expect((await repository.refreshFromRemote())?.id, 'plan-1');
    });
  });
}
