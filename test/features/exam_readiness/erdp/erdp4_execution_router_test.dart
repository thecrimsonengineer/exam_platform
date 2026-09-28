import 'package:exam_platform/features/exam_readiness/models/daily_study_plan.dart';
import 'package:exam_platform/features/exam_readiness/models/study_plan_block.dart';
import 'package:exam_platform/features/exam_readiness/models/study_plan_execution_attempt.dart';
import 'package:exam_platform/features/exam_readiness/models/study_plan_execution_target.dart';
import 'package:exam_platform/features/exam_readiness/services/study_plan_execution_router.dart';
import 'package:flutter_test/flutter_test.dart';

import '../m7d/_support/m7d_fixture.dart';

StudyPlanBlock _block({
  StudyPlanBlockStatus status = StudyPlanBlockStatus.planned,
  StudyPlanBlockType type = StudyPlanBlockType.learn,
}) {
  return StudyPlanBlock(
    blockId: 'plan-v1-b01-d01_c01-${type.name}',
    type: type,
    domainId: 'd01',
    competencyId: 'd01_c01',
    subtopicId: '',
    topicId: '',
    plannedMinutes: 15,
    questionCount: type == StudyPlanBlockType.learn ? 0 : 5,
    priorityScore: 0.8,
    priorityBreakdown: m7dPriority(competencyId: 'd01_c01'),
    reasonCodes: const <String>['TEST'],
    reasonText: 'Test execution block.',
    status: status,
    createdAt: DateTime.utc(2026, 9, 28, 8),
    startedAt: status == StudyPlanBlockStatus.started
        ? DateTime.utc(2026, 9, 28, 9)
        : null,
    manualChanges: const <StudyPlanManualChange>[],
  );
}

DailyStudyPlan _plan(StudyPlanBlock block) {
  return DailyStudyPlan(
    planId: 'plan-20260928',
    userId: 'learner-1',
    date: DateTime.utc(2026, 9, 28),
    generatedAt: DateTime.utc(2026, 9, 28, 8),
    planVersion: 1,
    plannerAlgorithmVersion: DailyStudyPlan.currentAlgorithmVersion,
    availableMinutes: 60,
    allocatedMinutes: block.plannedMinutes,
    generationReason: DailyStudyPlanGenerationReason.initial,
    sourceEvidenceVersion: 'e1',
    sourceReadinessVersion: 'r1',
    blocks: <StudyPlanBlock>[block],
    status: DailyStudyPlanStatus.active,
    schemaVersion: DailyStudyPlan.currentSchemaVersion,
  );
}

StudyPlanExecutionTarget _target(
  StudyPlanBlock block, {
  StudyPlanExecutionTargetKind kind = StudyPlanExecutionTargetKind.studyContent,
}) {
  return StudyPlanExecutionTarget(
    kind: kind,
    blockId: block.blockId,
    blockType: block.type,
    domainId: block.domainId,
    domainNumber: 1,
    domainTitle: 'Advanced Sciences and Math',
    competencyId: block.competencyId,
    competencyTitle: 'Test competency',
    plannedMinutes: block.plannedMinutes,
    questionCount: block.questionCount,
  );
}

class _FakeStore implements StudyPlanExecutionStore {
  _FakeStore({
    this.failCommit = false,
    this.failNavigationMarker = false,
    this.corruptAttempt = false,
    this.events,
  });

  final bool failCommit;
  final bool failNavigationMarker;
  final bool corruptAttempt;
  final List<String>? events;

  int commitCalls = 0;
  int navigationFailureCalls = 0;
  StudyPlanExecutionAttempt? lastNavigationFailure;

  @override
  Future<StudyPlanExecutionStartCommit> commitStart({
    required DailyStudyPlan sourcePlan,
    required StudyPlanBlock block,
    required StudyPlanExecutionTarget target,
    required DateTime at,
  }) async {
    commitCalls += 1;
    events?.add('commit');
    if (failCommit) throw StateError('persistence failed');

    final startedBlock = block.copyWith(
      status: StudyPlanBlockStatus.started,
      startedAt: at,
    );
    final startedPlan = sourcePlan.copyWith(
      generatedAt: at,
      planVersion: sourcePlan.planVersion + 1,
      blocks: <StudyPlanBlock>[startedBlock],
    );
    final attempt = StudyPlanExecutionAttempt(
      executionAttemptId: StudyPlanExecutionAttempt.deterministicId(
        planId: sourcePlan.planId,
        sourcePlanVersion: sourcePlan.planVersion,
        blockId: block.blockId,
      ),
      planId: sourcePlan.planId,
      sourcePlanVersion: sourcePlan.planVersion,
      committedPlanVersion: startedPlan.planVersion,
      blockId: corruptAttempt ? 'wrong-block' : block.blockId,
      targetKind: target.kind,
      startedAt: at,
      status: StudyPlanExecutionAttemptStatus.started,
    );

    return StudyPlanExecutionStartCommit(
      startedPlan: startedPlan,
      attempt: attempt,
    );
  }

  @override
  Future<void> persistNavigationFailure(
    StudyPlanExecutionAttempt attempt,
  ) async {
    navigationFailureCalls += 1;
    lastNavigationFailure = attempt;
    events?.add('mark-navigation-failed');
    if (failNavigationMarker) {
      throw StateError('marker persistence failed');
    }
  }
}

class _FakeNavigator implements StudyPlanExecutionNavigator {
  _FakeNavigator({this.fail = false, this.events});

  final bool fail;
  final List<String>? events;
  int openCalls = 0;

  @override
  Future<void> open(StudyPlanExecutionTarget target) async {
    openCalls += 1;
    events?.add('navigate');
    if (fail) throw StateError('navigation failed');
  }
}

void main() {
  group('ERDP-4 execution attempt model', () {
    test('deterministic attempt ID is stable for the same source block', () {
      final first = StudyPlanExecutionAttempt.deterministicId(
        planId: 'p1',
        sourcePlanVersion: 3,
        blockId: 'b1',
      );
      final second = StudyPlanExecutionAttempt.deterministicId(
        planId: 'p1',
        sourcePlanVersion: 3,
        blockId: 'b1',
      );

      expect(first, second);
    });

    test('attempt round trips through JSON', () {
      final attempt = StudyPlanExecutionAttempt(
        executionAttemptId: 'a1',
        planId: 'p1',
        sourcePlanVersion: 1,
        committedPlanVersion: 2,
        blockId: 'b1',
        targetKind: StudyPlanExecutionTargetKind.flashcardReview,
        startedAt: DateTime.utc(2026, 9, 28, 9),
        status: StudyPlanExecutionAttemptStatus.started,
      );

      final restored = StudyPlanExecutionAttempt.fromJson(attempt.toJson());

      expect(restored.toJson(), attempt.toJson());
    });
  });

  group('ERDP-4 transaction-safe execution router', () {
    test('successful start resolves then commits then navigates', () async {
      final events = <String>[];
      final block = _block();
      final plan = _plan(block);
      final store = _FakeStore(events: events);
      final navigator = _FakeNavigator(events: events);
      final router = StudyPlanExecutionRouter(
        resolveTarget: (value) {
          events.add('resolve');
          return _target(value);
        },
        store: store,
        navigator: navigator,
      );
      final at = DateTime.utc(2026, 9, 28, 9);

      final result = await router.start(
        plan: plan,
        blockId: block.blockId,
        at: at,
      );

      expect(events, <String>['resolve', 'commit', 'navigate']);
      expect(result.navigationSucceeded, isTrue);
      expect(result.startedPlan.planVersion, 2);
      expect(
        result.startedPlan.blocks.single.status,
        StudyPlanBlockStatus.started,
      );
      expect(result.attempt.status, StudyPlanExecutionAttemptStatus.started);
    });

    test('persistence failure prevents navigation', () async {
      final block = _block();
      final store = _FakeStore(failCommit: true);
      final navigator = _FakeNavigator();
      final router = StudyPlanExecutionRouter(
        resolveTarget: _target,
        store: store,
        navigator: navigator,
      );

      await expectLater(
        router.start(
          plan: _plan(block),
          blockId: block.blockId,
          at: DateTime.utc(2026, 9, 28, 9),
        ),
        throwsStateError,
      );
      expect(navigator.openCalls, 0);
    });

    test(
      'target resolution failure performs no persistence or navigation',
      () async {
        final block = _block();
        final store = _FakeStore();
        final navigator = _FakeNavigator();
        final router = StudyPlanExecutionRouter(
          resolveTarget: (_) => throw StateError('bad target'),
          store: store,
          navigator: navigator,
        );

        await expectLater(
          router.start(
            plan: _plan(block),
            blockId: block.blockId,
            at: DateTime.utc(2026, 9, 28, 9),
          ),
          throwsStateError,
        );
        expect(store.commitCalls, 0);
        expect(navigator.openCalls, 0);
      },
    );

    test('terminal block cannot create a new execution attempt', () async {
      final block = _block(status: StudyPlanBlockStatus.completed);
      final store = _FakeStore();
      final navigator = _FakeNavigator();
      var resolveCalls = 0;
      final router = StudyPlanExecutionRouter(
        resolveTarget: (value) {
          resolveCalls += 1;
          return _target(value);
        },
        store: store,
        navigator: navigator,
      );

      await expectLater(
        router.start(
          plan: _plan(block),
          blockId: block.blockId,
          at: DateTime.utc(2026, 9, 28, 9),
        ),
        throwsStateError,
      );
      expect(resolveCalls, 0);
      expect(store.commitCalls, 0);
      expect(navigator.openCalls, 0);
    });

    test('invalid commit is rejected before navigation', () async {
      final block = _block();
      final store = _FakeStore(corruptAttempt: true);
      final navigator = _FakeNavigator();
      final router = StudyPlanExecutionRouter(
        resolveTarget: _target,
        store: store,
        navigator: navigator,
      );

      await expectLater(
        router.start(
          plan: _plan(block),
          blockId: block.blockId,
          at: DateTime.utc(2026, 9, 28, 9),
        ),
        throwsStateError,
      );
      expect(navigator.openCalls, 0);
    });

    test(
      'navigation failure retains started plan and recoverable attempt',
      () async {
        final block = _block();
        final store = _FakeStore();
        final navigator = _FakeNavigator(fail: true);
        final router = StudyPlanExecutionRouter(
          resolveTarget: _target,
          store: store,
          navigator: navigator,
        );

        final result = await router.start(
          plan: _plan(block),
          blockId: block.blockId,
          at: DateTime.utc(2026, 9, 28, 9),
        );

        expect(result.navigationSucceeded, isFalse);
        expect(result.isRecoverableNavigationFailure, isTrue);
        expect(
          result.startedPlan.blocks.single.status,
          StudyPlanBlockStatus.started,
        );
        expect(
          result.attempt.status,
          StudyPlanExecutionAttemptStatus.navigationFailed,
        );
        expect(result.navigationFailurePersisted, isTrue);
        expect(store.navigationFailureCalls, 1);
      },
    );

    test('failed navigation marker does not invent a rollback', () async {
      final block = _block();
      final store = _FakeStore(failNavigationMarker: true);
      final navigator = _FakeNavigator(fail: true);
      final router = StudyPlanExecutionRouter(
        resolveTarget: _target,
        store: store,
        navigator: navigator,
      );

      final result = await router.start(
        plan: _plan(block),
        blockId: block.blockId,
        at: DateTime.utc(2026, 9, 28, 9),
      );

      expect(result.navigationSucceeded, isFalse);
      expect(result.navigationFailurePersisted, isFalse);
      expect(result.startedPlan.planVersion, 2);
      expect(
        result.startedPlan.blocks.single.status,
        StudyPlanBlockStatus.started,
      );
    });

    test(
      'resolved Flashcard target remains first-class through transaction',
      () async {
        final block = _block(type: StudyPlanBlockType.spacedReview);
        final store = _FakeStore();
        final navigator = _FakeNavigator();
        final router = StudyPlanExecutionRouter(
          resolveTarget: (value) => _target(
            value,
            kind: StudyPlanExecutionTargetKind.flashcardReview,
          ),
          store: store,
          navigator: navigator,
        );

        final result = await router.start(
          plan: _plan(block),
          blockId: block.blockId,
          at: DateTime.utc(2026, 9, 28, 9),
        );

        expect(
          result.target.kind,
          StudyPlanExecutionTargetKind.flashcardReview,
        );
        expect(
          result.attempt.targetKind,
          StudyPlanExecutionTargetKind.flashcardReview,
        );
      },
    );
  });
}
