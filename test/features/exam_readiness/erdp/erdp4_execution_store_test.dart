import 'dart:convert';

import 'package:exam_platform/features/exam_readiness/models/daily_study_plan.dart';
import 'package:exam_platform/features/exam_readiness/models/study_plan_block.dart';
import 'package:exam_platform/features/exam_readiness/models/study_plan_execution_attempt.dart';
import 'package:exam_platform/features/exam_readiness/models/study_plan_execution_target.dart';
import 'package:exam_platform/features/exam_readiness/repositories/daily_study_plan_repository.dart';
import 'package:exam_platform/features/exam_readiness/services/daily_study_plan_service.dart';
import 'package:exam_platform/features/exam_readiness/services/local_study_plan_execution_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../m7d/_support/m7d_fixture.dart';

StudyPlanBlock _block() {
  return StudyPlanBlock(
    blockId: 'plan-20260928-v1-b01-d01_c01-learn',
    type: StudyPlanBlockType.learn,
    domainId: 'd01',
    competencyId: 'd01_c01',
    subtopicId: '',
    topicId: '',
    plannedMinutes: 15,
    questionCount: 0,
    priorityScore: 0.8,
    priorityBreakdown: m7dPriority(competencyId: 'd01_c01'),
    reasonCodes: const <String>['TEST'],
    reasonText: 'Test execution block.',
    status: StudyPlanBlockStatus.planned,
    createdAt: DateTime.utc(2026, 9, 28, 8),
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

StudyPlanExecutionTarget _target(StudyPlanBlock block) {
  return StudyPlanExecutionTarget(
    kind: StudyPlanExecutionTargetKind.studyContent,
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('legacy plan-list storage remains readable', () async {
    final block = _block();
    final plan = _plan(block);
    final key = DailyStudyPlanRepository.storageKeyForUser('learner-1');
    SharedPreferences.setMockInitialValues(<String, Object>{
      key: jsonEncode(<Map<String, dynamic>>[plan.toJson()]),
    });
    final repository = DailyStudyPlanRepository(
      userIdOverride: 'learner-1',
    );

    final history = await repository.loadHistory();

    expect(history, hasLength(1));
    expect(history.single.toJson(), plan.toJson());
    expect(await repository.loadExecutionAttempts(), isEmpty);
  });

  test('start commit stores plan version and execution attempt together', () async {
    final block = _block();
    final sourcePlan = _plan(block);
    final repository = DailyStudyPlanRepository(
      userIdOverride: 'learner-1',
    );
    await repository.savePlan(sourcePlan, syncRemote: false);
    final store = LocalStudyPlanExecutionStore(
      planRepository: repository,
      planService: const DailyStudyPlanService(),
    );
    final at = DateTime.utc(2026, 9, 28, 9);

    final commit = await store.commitStart(
      sourcePlan: sourcePlan,
      block: block,
      target: _target(block),
      at: at,
    );

    expect(commit.startedPlan.planVersion, 2);
    expect(
      commit.startedPlan.blocks.single.status,
      StudyPlanBlockStatus.started,
    );
    expect(commit.startedPlan.blocks.single.startedAt, at);

    final history = await repository.loadHistory();
    expect(history.map((plan) => plan.planVersion), containsAll(<int>[1, 2]));

    final attempts = await repository.loadExecutionAttempts();
    expect(attempts, hasLength(1));
    expect(attempts.single.executionAttemptId, commit.attempt.executionAttemptId);
    expect(
      attempts.single.status,
      StudyPlanExecutionAttemptStatus.started,
    );
  });

  test('repeating a deterministic start reuses the committed attempt', () async {
    final block = _block();
    final sourcePlan = _plan(block);
    final repository = DailyStudyPlanRepository(
      userIdOverride: 'learner-1',
    );
    await repository.savePlan(sourcePlan, syncRemote: false);
    final store = LocalStudyPlanExecutionStore(
      planRepository: repository,
      planService: const DailyStudyPlanService(),
    );

    final first = await store.commitStart(
      sourcePlan: sourcePlan,
      block: block,
      target: _target(block),
      at: DateTime.utc(2026, 9, 28, 9),
    );
    final second = await store.commitStart(
      sourcePlan: sourcePlan,
      block: block,
      target: _target(block),
      at: DateTime.utc(2026, 9, 28, 9, 1),
    );

    expect(second.attempt.executionAttemptId, first.attempt.executionAttemptId);
    expect(second.attempt.startedAt, first.attempt.startedAt);
    expect(second.startedPlan.planVersion, first.startedPlan.planVersion);
    expect(await repository.loadExecutionAttempts(), hasLength(1));
    expect(await repository.loadHistory(), hasLength(2));
  });

  test('navigation failure marker updates the existing attempt in place', () async {
    final block = _block();
    final sourcePlan = _plan(block);
    final repository = DailyStudyPlanRepository(
      userIdOverride: 'learner-1',
    );
    await repository.savePlan(sourcePlan, syncRemote: false);
    final store = LocalStudyPlanExecutionStore(
      planRepository: repository,
      planService: const DailyStudyPlanService(),
    );
    final commit = await store.commitStart(
      sourcePlan: sourcePlan,
      block: block,
      target: _target(block),
      at: DateTime.utc(2026, 9, 28, 9),
    );
    final failed = commit.attempt.markNavigationFailed(
      at: DateTime.utc(2026, 9, 28, 9, 0, 5),
      failureCode: 'NAVIGATION_StateError',
    );

    await store.persistNavigationFailure(failed);

    final attempts = await repository.loadExecutionAttempts();
    expect(attempts, hasLength(1));
    expect(
      attempts.single.status,
      StudyPlanExecutionAttemptStatus.navigationFailed,
    );
    expect(attempts.single.failureCode, 'NAVIGATION_StateError');
    expect(await repository.loadHistory(), hasLength(2));
  });
}
