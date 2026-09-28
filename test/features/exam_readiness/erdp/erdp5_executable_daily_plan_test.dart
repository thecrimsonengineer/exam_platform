import 'package:exam_platform/features/exam_readiness/models/daily_study_plan.dart';
import 'package:exam_platform/features/exam_readiness/models/study_plan_block.dart';
import 'package:exam_platform/features/exam_readiness/models/study_plan_carry_forward.dart';
import 'package:exam_platform/features/exam_readiness/models/study_plan_execution_target.dart';
import 'package:exam_platform/features/exam_readiness/repositories/daily_study_plan_repository.dart';
import 'package:exam_platform/features/exam_readiness/services/executable_daily_plan_action_service.dart';
import 'package:exam_platform/features/exam_readiness/services/study_plan_carry_forward_planner.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../m7d/_support/m7d_fixture.dart';

StudyPlanBlock _block({
  String id = 'plan-20260928-v1-b01-d01_c01-standardPractice',
  StudyPlanBlockType type = StudyPlanBlockType.standardPractice,
  int minutes = 15,
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
    reasonCodes: const <String>['TEST'],
    reasonText: 'Test Daily Plan task.',
    status: StudyPlanBlockStatus.planned,
    createdAt: DateTime.utc(2026, 9, 28, 8),
    manualChanges: const <StudyPlanManualChange>[],
  );
}

DailyStudyPlan _plan({
  required DateTime date,
  required List<StudyPlanBlock> blocks,
  int availableMinutes = 60,
  int version = 1,
}) {
  return DailyStudyPlan(
    planId:
        'plan-${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}',
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
    sourceEvidenceVersion: 'e1',
    sourceReadinessVersion: 'r1',
    blocks: blocks,
    status: DailyStudyPlanStatus.active,
    schemaVersion: DailyStudyPlan.currentSchemaVersion,
  );
}

StudyPlanExecutionTarget _target(StudyPlanBlock block) {
  final kind = switch (block.type) {
    StudyPlanBlockType.spacedReview || StudyPlanBlockType.recovery =>
      StudyPlanExecutionTargetKind.flashcardReview,
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
    competencyTitle: 'Test competency',
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

  test('Skip persists once, frees time, and creates no readiness evidence', () async {
    final block = _block();
    final source = _plan(
      date: DateTime.utc(2026, 9, 28),
      blocks: <StudyPlanBlock>[block],
    );
    final repository = DailyStudyPlanRepository(userIdOverride: 'learner-1');
    await repository.savePlan(source, syncRemote: false);
    final service = ExecutableDailyPlanActionService(
      repository: repository,
      resolveTarget: _target,
    );

    final first = await service.skip(
      sourcePlan: source,
      blockId: block.blockId,
      at: DateTime.utc(2026, 9, 28, 9),
    );
    final second = await service.skip(
      sourcePlan: source,
      blockId: block.blockId,
      at: DateTime.utc(2026, 9, 28, 9, 1),
    );

    expect(first.plan.blocks.single.status, StudyPlanBlockStatus.skipped);
    expect(first.plan.allocatedMinutes, 0);
    expect(second.plan.planVersion, first.plan.planVersion);
    expect(await repository.loadHistory(), hasLength(2));
    expect(await repository.loadExecutionAttempts(), isEmpty);
  });

  test('Tomorrow creates exactly one persistent deterministic carry-forward', () async {
    final block = _block();
    final source = _plan(
      date: DateTime.utc(2026, 9, 28),
      blocks: <StudyPlanBlock>[block],
    );
    final repository = DailyStudyPlanRepository(userIdOverride: 'learner-1');
    await repository.savePlan(source, syncRemote: false);
    final service = ExecutableDailyPlanActionService(
      repository: repository,
      resolveTarget: _target,
    );

    final first = await service.moveToTomorrow(
      sourcePlan: source,
      blockId: block.blockId,
      at: DateTime.utc(2026, 9, 28, 9),
    );
    final second = await service.moveToTomorrow(
      sourcePlan: source,
      blockId: block.blockId,
      at: DateTime.utc(2026, 9, 28, 9, 1),
    );

    expect(
      first.plan.blocks.single.status,
      StudyPlanBlockStatus.movedToTomorrow,
    );
    expect(first.plan.allocatedMinutes, 0);
    expect(second.plan.planVersion, first.plan.planVersion);

    final queue = await repository.loadCarryForwards();
    expect(queue, hasLength(1));
    expect(queue.single.id, first.carryForward!.id);
    expect(queue.single.status, StudyPlanCarryForwardStatus.pending);
    expect(queue.single.dueDate, DateTime(2026, 9, 29));
    expect(queue.single.executionTarget.blockId, block.blockId);
  });

  test('Replace preserves history and links an executable same-competency alternative', () async {
    final block = _block();
    final source = _plan(
      date: DateTime.utc(2026, 9, 28),
      blocks: <StudyPlanBlock>[block],
    );
    final repository = DailyStudyPlanRepository(userIdOverride: 'learner-1');
    await repository.savePlan(source, syncRemote: false);
    final service = ExecutableDailyPlanActionService(
      repository: repository,
      resolveTarget: _target,
    );

    final first = await service.replace(
      sourcePlan: source,
      blockId: block.blockId,
      at: DateTime.utc(2026, 9, 28, 9),
    );
    final second = await service.replace(
      sourcePlan: source,
      blockId: block.blockId,
      at: DateTime.utc(2026, 9, 28, 9, 1),
    );

    expect(first.plan.blocks, hasLength(2));
    final original = first.plan.blocks.firstWhere(
      (item) => item.blockId == block.blockId,
    );
    final replacement = first.replacementBlock!;
    expect(original.status, StudyPlanBlockStatus.replaced);
    expect(original.replacedByBlockId, replacement.blockId);
    expect(replacement.replacesBlockId, original.blockId);
    expect(replacement.competencyId, original.competencyId);
    expect(replacement.type, isNot(original.type));
    expect(replacement.status, StudyPlanBlockStatus.planned);
    expect(_target(replacement).blockId, replacement.blockId);
    expect(
      first.plan.allocatedMinutes,
      replacement.plannedMinutes,
      reason: 'The historical replaced task must not consume capacity.',
    );
    expect(second.plan.planVersion, first.plan.planVersion);
    expect(await repository.loadHistory(), hasLength(2));
  });

  test('carry-forward planner schedules due work before ordinary recommendations', () {
    final original = _block(minutes: 15);
    final carry = StudyPlanCarryForward(
      id: StudyPlanCarryForward.deterministicId(
        planId: 'plan-20260928',
        blockId: original.blockId,
        dueDate: DateTime.utc(2026, 9, 29),
      ),
      learnerId: 'learner-1',
      originalPlanId: 'plan-20260928',
      originalBlockId: original.blockId,
      sourceBlock: original,
      executionTarget: _target(original),
      reason: 'Moved by learner.',
      createdAt: DateTime.utc(2026, 9, 28, 9),
      dueDate: DateTime.utc(2026, 9, 29),
      status: StudyPlanCarryForwardStatus.pending,
    );
    final ordinaryA = _block(
      id: 'ordinary-a',
      minutes: 30,
      competencyId: 'd01_c02',
    );
    final ordinaryB = _block(
      id: 'ordinary-b',
      minutes: 30,
      competencyId: 'd01_c03',
    );
    final base = _plan(
      date: DateTime.utc(2026, 9, 29),
      blocks: <StudyPlanBlock>[ordinaryA, ordinaryB],
      availableMinutes: 60,
    );

    final result = const StudyPlanCarryForwardPlanner().apply(
      basePlan: base,
      pendingCarryForwards: <StudyPlanCarryForward>[carry],
      at: DateTime.utc(2026, 9, 29, 8),
    );

    expect(result.consumedIds, <String>{carry.id});
    expect(result.plan.blocks.first.reasonCodes, contains('CARRY_FORWARD'));
    expect(result.plan.blocks.first.competencyId, original.competencyId);
    expect(result.plan.allocatedMinutes, 45);
    expect(
      result.plan.blocks.where((item) => item.blockId.startsWith('ordinary-')),
      hasLength(1),
    );
  });

  test('carry-forward stays pending when today has insufficient capacity', () {
    final original = _block(minutes: 15);
    final carry = StudyPlanCarryForward(
      id: 'cf-capacity',
      learnerId: 'learner-1',
      originalPlanId: 'plan-20260928',
      originalBlockId: original.blockId,
      sourceBlock: original,
      executionTarget: _target(original),
      reason: 'Moved by learner.',
      createdAt: DateTime.utc(2026, 9, 28, 9),
      dueDate: DateTime.utc(2026, 9, 29),
      status: StudyPlanCarryForwardStatus.pending,
    );
    final base = _plan(
      date: DateTime.utc(2026, 9, 29),
      blocks: const <StudyPlanBlock>[],
      availableMinutes: 10,
    );

    final result = const StudyPlanCarryForwardPlanner().apply(
      basePlan: base,
      pendingCarryForwards: <StudyPlanCarryForward>[carry],
      at: DateTime.utc(2026, 9, 29, 8),
    );

    expect(result.consumedIds, isEmpty);
    expect(result.plan.blocks, isEmpty);
  });

  test('execution target serialization preserves Flashcard routing metadata', () {
    final block = _block(type: StudyPlanBlockType.spacedReview, minutes: 10);
    final target = _target(block).copyWith(
      cardIds: const <String>['card-1', 'card-2'],
      weakOnly: true,
      sourceEvidenceIds: const <String>['evidence-1'],
      targetCardCount: 8,
    );

    final restored = StudyPlanExecutionTarget.fromJson(target.toJson());

    expect(restored.kind, StudyPlanExecutionTargetKind.flashcardReview);
    expect(restored.cardIds, target.cardIds);
    expect(restored.dueOnly, isTrue);
    expect(restored.weakOnly, isTrue);
    expect(restored.sourceEvidenceIds, target.sourceEvidenceIds);
    expect(restored.targetCardCount, 8);
  });
}
