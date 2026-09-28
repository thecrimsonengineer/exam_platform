import 'package:exam_platform/features/exam_readiness/models/daily_study_plan.dart';
import 'package:exam_platform/features/exam_readiness/models/study_plan_block.dart';
import 'package:exam_platform/features/exam_readiness/models/study_plan_carry_forward.dart';
import 'package:exam_platform/features/exam_readiness/models/study_plan_execution_attempt.dart';
import 'package:exam_platform/features/exam_readiness/models/study_plan_execution_target.dart';
import 'package:exam_platform/features/exam_readiness/repositories/daily_study_plan_repository.dart';
import 'package:exam_platform/features/exam_readiness/services/daily_study_plan_service.dart';
import 'package:exam_platform/features/exam_readiness/services/executable_daily_plan_action_service.dart';
import 'package:exam_platform/features/exam_readiness/services/local_study_plan_execution_store.dart';
import 'package:exam_platform/features/exam_readiness/services/study_plan_carry_forward_planner.dart';
import 'package:exam_platform/features/exam_readiness/services/study_plan_execution_attempt_lifecycle_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../m7d/_support/m7d_fixture.dart';

StudyPlanBlock _block({
  required String id,
  required StudyPlanBlockType type,
  int minutes = 10,
  String competencyId = 'd01_c01',
}) {
  final questionCount = switch (type) {
    StudyPlanBlockType.diagnostic ||
    StudyPlanBlockType.standardPractice ||
    StudyPlanBlockType.ultraHardPractice ||
    StudyPlanBlockType.mixedRetrieval ||
    StudyPlanBlockType.competencyRecheck ||
    StudyPlanBlockType.confidenceCalibration ||
    StudyPlanBlockType.examSimulation => 5,
    _ => 0,
  };

  return StudyPlanBlock(
    blockId: id,
    type: type,
    domainId: 'd01',
    competencyId: competencyId,
    subtopicId: '',
    topicId: '',
    plannedMinutes: minutes,
    questionCount: questionCount,
    priorityScore: 0.8,
    priorityBreakdown: m7dPriority(competencyId: competencyId),
    reasonCodes: const <String>['ERDP10_ACCEPTANCE'],
    reasonText: 'ERDP-10 acceptance task.',
    status: StudyPlanBlockStatus.planned,
    createdAt: DateTime.utc(2026, 9, 28, 8),
    manualChanges: const <StudyPlanManualChange>[],
  );
}

DailyStudyPlan _plan({
  required DateTime date,
  required List<StudyPlanBlock> blocks,
  int version = 1,
  int availableMinutes = 60,
}) {
  return DailyStudyPlan(
    planId:
        'erdp10-${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}',
    userId: 'learner-1',
    date: date,
    generatedAt: DateTime.utc(date.year, date.month, date.day, 8),
    planVersion: version,
    plannerAlgorithmVersion: DailyStudyPlan.currentAlgorithmVersion,
    availableMinutes: availableMinutes,
    allocatedMinutes: blocks.fold<int>(
      0,
      (sum, block) =>
          sum + (block.consumesAllocation ? block.plannedMinutes : 0),
    ),
    generationReason: DailyStudyPlanGenerationReason.initial,
    sourceEvidenceVersion: 'erdp10-e1',
    sourceReadinessVersion: 'erdp10-r1',
    blocks: blocks,
    status: DailyStudyPlanStatus.active,
    schemaVersion: DailyStudyPlan.currentSchemaVersion,
  );
}

StudyPlanExecutionTarget _target(StudyPlanBlock block) {
  final kind = switch (block.type) {
    StudyPlanBlockType.spacedReview ||
    StudyPlanBlockType.recovery => StudyPlanExecutionTargetKind.flashcardReview,
    StudyPlanBlockType.diagnostic ||
    StudyPlanBlockType.standardPractice ||
    StudyPlanBlockType.ultraHardPractice ||
    StudyPlanBlockType.mixedRetrieval ||
    StudyPlanBlockType.competencyRecheck ||
    StudyPlanBlockType.confidenceCalibration =>
      StudyPlanExecutionTargetKind.practiceSession,
    StudyPlanBlockType.examSimulation =>
      StudyPlanExecutionTargetKind.examSimulation,
    _ => StudyPlanExecutionTargetKind.studyContent,
  };

  return StudyPlanExecutionTarget(
    kind: kind,
    blockId: block.blockId,
    blockType: block.type,
    domainId: block.domainId,
    domainNumber: 1,
    domainTitle: 'Advanced Sciences and Math',
    competencyId: block.competencyId,
    competencyTitle: 'ERDP-10 competency',
    plannedMinutes: block.plannedMinutes,
    questionCount: block.questionCount,
    dueOnly: kind == StudyPlanExecutionTargetKind.flashcardReview,
    reviewReason: kind == StudyPlanExecutionTargetKind.flashcardReview
        ? block.reasonText
        : null,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test(
    'started and completed task state survives repository reconstruction',
    () async {
      final block = _block(
        id: 'erdp10-20260928-learn',
        type: StudyPlanBlockType.learn,
        minutes: 15,
      );
      final source = _plan(
        date: DateTime.utc(2026, 9, 28),
        blocks: <StudyPlanBlock>[block],
      );
      final repository = DailyStudyPlanRepository(userIdOverride: 'learner-1');
      await repository.savePlan(source, syncRemote: false);

      final store = LocalStudyPlanExecutionStore(
        planRepository: repository,
        planService: const DailyStudyPlanService(),
      );
      final start = await store.commitStart(
        sourcePlan: source,
        block: block,
        target: _target(block),
        at: DateTime.utc(2026, 9, 28, 9),
      );

      final restartedRepository = DailyStudyPlanRepository(
        userIdOverride: 'learner-1',
      );
      final restarted = await restartedRepository.loadLatestForDate(
        source.date,
      );
      final attemptsAfterRestart = await restartedRepository
          .loadExecutionAttempts();

      expect(restarted, isNotNull);
      expect(restarted!.blocks.single.status, StudyPlanBlockStatus.started);
      expect(attemptsAfterRestart, hasLength(1));
      expect(
        attemptsAfterRestart.single.executionAttemptId,
        start.attempt.executionAttemptId,
      );

      final completed = const DailyStudyPlanService().completeBlock(
        restarted,
        block.blockId,
        at: DateTime.utc(2026, 9, 28, 9, 20),
      );
      await restartedRepository.savePlan(completed, syncRemote: false);
      final completedBlock = completed.blocks.single;

      final closed = await const StudyPlanExecutionAttemptLifecycleService()
          .closeForCompletedBlock(
            plan: completed,
            block: completedBlock,
            repository: restartedRepository,
          );
      final replay = await const StudyPlanExecutionAttemptLifecycleService()
          .closeForCompletedBlock(
            plan: completed,
            block: completedBlock,
            repository: restartedRepository,
          );

      expect(closed, 1);
      expect(replay, 0);

      final finalRepository = DailyStudyPlanRepository(
        userIdOverride: 'learner-1',
      );
      final finalPlan = await finalRepository.loadLatestForDate(source.date);
      final finalAttempts = await finalRepository.loadExecutionAttempts();

      expect(finalPlan!.blocks.single.status, StudyPlanBlockStatus.completed);
      expect(finalAttempts, hasLength(1));
      expect(
        finalAttempts.single.status,
        StudyPlanExecutionAttemptStatus.completed,
      );
    },
  );

  test(
    'navigation-failed attempt becomes completed after real task completion',
    () async {
      final block = _block(
        id: 'erdp10-20260928-navigation-recovery',
        type: StudyPlanBlockType.learn,
        minutes: 10,
      );
      final source = _plan(
        date: DateTime.utc(2026, 9, 28),
        blocks: <StudyPlanBlock>[block],
      );
      final repository = DailyStudyPlanRepository(userIdOverride: 'learner-1');
      await repository.savePlan(source, syncRemote: false);
      final store = LocalStudyPlanExecutionStore(
        planRepository: repository,
        planService: const DailyStudyPlanService(),
      );
      final start = await store.commitStart(
        sourcePlan: source,
        block: block,
        target: _target(block),
        at: DateTime.utc(2026, 9, 28, 9),
      );
      await store.persistNavigationFailure(
        start.attempt.markNavigationFailed(
          at: DateTime.utc(2026, 9, 28, 9, 0, 5),
          failureCode: 'NAVIGATION_StateError',
        ),
      );

      final completed = const DailyStudyPlanService().completeBlock(
        start.startedPlan,
        block.blockId,
        at: DateTime.utc(2026, 9, 28, 9, 15),
      );
      await repository.savePlan(completed, syncRemote: false);
      await const StudyPlanExecutionAttemptLifecycleService()
          .closeForCompletedBlock(
            plan: completed,
            block: completed.blocks.single,
            repository: repository,
          );

      final attempts = await repository.loadExecutionAttempts();
      expect(attempts, hasLength(1));
      expect(attempts.single.status, StudyPlanExecutionAttemptStatus.completed);
      expect(attempts.single.failureCode, 'NAVIGATION_StateError');
    },
  );

  test(
    'Skip Tomorrow Replace survive restart and Tomorrow stays deduplicated',
    () async {
      final skipBlock = _block(
        id: 'erdp10-skip',
        type: StudyPlanBlockType.standardPractice,
      );
      final tomorrowBlock = _block(
        id: 'erdp10-tomorrow',
        type: StudyPlanBlockType.standardPractice,
      );
      final replaceBlock = _block(
        id: 'erdp10-replace',
        type: StudyPlanBlockType.learn,
      );
      final source = _plan(
        date: DateTime.utc(2026, 9, 28),
        blocks: <StudyPlanBlock>[skipBlock, tomorrowBlock, replaceBlock],
      );
      final repository = DailyStudyPlanRepository(userIdOverride: 'learner-1');
      await repository.savePlan(source, syncRemote: false);
      final actions = ExecutableDailyPlanActionService(
        repository: repository,
        resolveTarget: _target,
      );

      final skipped = await actions.skip(
        sourcePlan: source,
        blockId: skipBlock.blockId,
        at: DateTime.utc(2026, 9, 28, 9),
      );
      final moved = await actions.moveToTomorrow(
        sourcePlan: skipped.plan,
        blockId: tomorrowBlock.blockId,
        at: DateTime.utc(2026, 9, 28, 9, 1),
      );
      final replaced = await actions.replace(
        sourcePlan: moved.plan,
        blockId: replaceBlock.blockId,
        at: DateTime.utc(2026, 9, 28, 9, 2),
      );

      final restartedRepository = DailyStudyPlanRepository(
        userIdOverride: 'learner-1',
      );
      final persisted = await restartedRepository.loadLatestForDate(
        source.date,
      );
      final persistedCarry = await restartedRepository.loadCarryForwards();

      expect(persisted, isNotNull);
      expect(
        persisted!.blocks
            .firstWhere((b) => b.blockId == skipBlock.blockId)
            .status,
        StudyPlanBlockStatus.skipped,
      );
      expect(
        persisted.blocks
            .firstWhere((b) => b.blockId == tomorrowBlock.blockId)
            .status,
        StudyPlanBlockStatus.movedToTomorrow,
      );
      final original = persisted.blocks.firstWhere(
        (b) => b.blockId == replaceBlock.blockId,
      );
      final replacement = persisted.blocks.firstWhere(
        (b) => b.replacesBlockId == replaceBlock.blockId,
      );
      expect(original.status, StudyPlanBlockStatus.replaced);
      expect(original.replacedByBlockId, replacement.blockId);
      expect(replacement.competencyId, original.competencyId);
      expect(replacement.type, isNot(original.type));
      expect(persistedCarry, hasLength(1));

      final restartedActions = ExecutableDailyPlanActionService(
        repository: restartedRepository,
        resolveTarget: _target,
      );
      final replay = await restartedActions.moveToTomorrow(
        sourcePlan: persisted,
        blockId: tomorrowBlock.blockId,
        at: DateTime.utc(2026, 9, 28, 9, 3),
      );

      expect(replay.plan.planVersion, replaced.plan.planVersion);
      expect(await restartedRepository.loadCarryForwards(), hasLength(1));
    },
  );

  test('carry-forward is consumed exactly once on the next day', () async {
    final block = _block(
      id: 'erdp10-carry-source',
      type: StudyPlanBlockType.standardPractice,
      minutes: 15,
    );
    final dayOne = _plan(
      date: DateTime.utc(2026, 9, 28),
      blocks: <StudyPlanBlock>[block],
    );
    final repository = DailyStudyPlanRepository(userIdOverride: 'learner-1');
    await repository.savePlan(dayOne, syncRemote: false);
    final actions = ExecutableDailyPlanActionService(
      repository: repository,
      resolveTarget: _target,
    );
    await actions.moveToTomorrow(
      sourcePlan: dayOne,
      blockId: block.blockId,
      at: DateTime.utc(2026, 9, 28, 10),
    );

    final queue = await repository.loadCarryForwards(
      dueOnOrBefore: DateTime.utc(2026, 9, 29),
      pendingOnly: true,
    );
    expect(queue, hasLength(1));

    final ordinary = _block(
      id: 'erdp10-day2-ordinary',
      type: StudyPlanBlockType.learn,
      minutes: 15,
      competencyId: 'd01_c02',
    );
    final dayTwoBase = _plan(
      date: DateTime.utc(2026, 9, 29),
      blocks: <StudyPlanBlock>[ordinary],
    );
    final applied = const StudyPlanCarryForwardPlanner().apply(
      basePlan: dayTwoBase,
      pendingCarryForwards: queue,
      at: DateTime.utc(2026, 9, 29, 8),
    );

    expect(applied.consumedIds, <String>{queue.single.id});
    expect(applied.plan.blocks.first.reasonCodes, contains('CARRY_FORWARD'));

    await repository.commitPlanMutation(
      plan: applied.plan,
      consumeCarryForwardIds: applied.consumedIds,
      consumedAt: DateTime.utc(2026, 9, 29, 8),
    );

    final restartedRepository = DailyStudyPlanRepository(
      userIdOverride: 'learner-1',
    );
    final pendingAfterRestart = await restartedRepository.loadCarryForwards(
      dueOnOrBefore: DateTime.utc(2026, 9, 29),
      pendingOnly: true,
    );
    final allAfterRestart = await restartedRepository.loadCarryForwards();

    expect(pendingAfterRestart, isEmpty);
    expect(allAfterRestart, hasLength(1));
    expect(allAfterRestart.single.status, StudyPlanCarryForwardStatus.consumed);

    final secondPass = const StudyPlanCarryForwardPlanner().apply(
      basePlan: applied.plan,
      pendingCarryForwards: pendingAfterRestart,
      at: DateTime.utc(2026, 9, 29, 8, 1),
    );
    expect(secondPass.consumedIds, isEmpty);
    expect(
      secondPass.plan.blocks.where(
        (item) => item.reasonCodes.contains('CARRY_FORWARD'),
      ),
      hasLength(1),
    );
  });
}
