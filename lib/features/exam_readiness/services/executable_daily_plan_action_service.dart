import '../models/daily_study_plan.dart';
import '../models/study_plan_block.dart';
import '../models/study_plan_carry_forward.dart';
import '../models/study_plan_execution_target.dart';
import '../repositories/daily_study_plan_repository.dart';
import 'daily_study_plan_service.dart';

typedef ExecutablePlanTargetResolver =
    StudyPlanExecutionTarget Function(StudyPlanBlock block);

class ExecutableDailyPlanActionResult {
  const ExecutableDailyPlanActionResult({
    required this.plan,
    this.carryForward,
    this.replacementBlock,
  });

  final DailyStudyPlan plan;
  final StudyPlanCarryForward? carryForward;
  final StudyPlanBlock? replacementBlock;
}

class ExecutableDailyPlanActionService {
  const ExecutableDailyPlanActionService({
    required this.repository,
    required this.resolveTarget,
    this.planService = const DailyStudyPlanService(),
  });

  final DailyStudyPlanRepository repository;
  final ExecutablePlanTargetResolver resolveTarget;
  final DailyStudyPlanService planService;

  Future<ExecutableDailyPlanActionResult> skip({
    required DailyStudyPlan sourcePlan,
    required String blockId,
    required DateTime at,
  }) async {
    final current = await _currentPlan(sourcePlan);
    final block = _findBlock(current, blockId);
    if (block.status == StudyPlanBlockStatus.skipped) {
      return ExecutableDailyPlanActionResult(plan: current);
    }
    _requireEditable(block, 'skip');

    final changed = planService.skipBlock(current, blockId, at: at);
    await repository.commitPlanMutation(plan: changed);
    return ExecutableDailyPlanActionResult(plan: changed);
  }

  Future<ExecutableDailyPlanActionResult> moveToTomorrow({
    required DailyStudyPlan sourcePlan,
    required String blockId,
    required DateTime at,
  }) async {
    final current = await _currentPlan(sourcePlan);
    final block = _findBlock(current, blockId);
    if (block.status == StudyPlanBlockStatus.movedToTomorrow) {
      final existing = await repository.loadCarryForwards();
      final carryForward = existing.where(
        (item) =>
            item.originalPlanId == current.planId &&
            item.originalBlockId == block.blockId,
      );
      return ExecutableDailyPlanActionResult(
        plan: current,
        carryForward: carryForward.isEmpty ? null : carryForward.first,
      );
    }
    _requireEditable(block, 'move to tomorrow');

    final target = resolveTarget(block);
    final dueDate = DateTime(
      at.year,
      at.month,
      at.day,
    ).add(const Duration(days: 1));
    final carryForward = StudyPlanCarryForward(
      id: StudyPlanCarryForward.deterministicId(
        planId: current.planId,
        blockId: block.blockId,
        dueDate: dueDate,
      ),
      learnerId: current.userId,
      originalPlanId: current.planId,
      originalBlockId: block.blockId,
      sourceBlock: block,
      executionTarget: target,
      reason: 'Learner moved this task to tomorrow.',
      createdAt: at,
      dueDate: dueDate,
      status: StudyPlanCarryForwardStatus.pending,
    );

    final changed = planService.moveToTomorrow(current, blockId, at: at);
    await repository.commitPlanMutation(
      plan: changed,
      upsertCarryForwards: <StudyPlanCarryForward>[carryForward],
    );
    return ExecutableDailyPlanActionResult(
      plan: changed,
      carryForward: carryForward,
    );
  }

  Future<ExecutableDailyPlanActionResult> replace({
    required DailyStudyPlan sourcePlan,
    required String blockId,
    required DateTime at,
  }) async {
    final current = await _currentPlan(sourcePlan);
    final block = _findBlock(current, blockId);
    if (block.status == StudyPlanBlockStatus.replaced) {
      final replacementId = block.replacedByBlockId;
      return ExecutableDailyPlanActionResult(
        plan: current,
        replacementBlock: replacementId == null
            ? null
            : _findBlock(current, replacementId),
      );
    }
    _requireEditable(block, 'replace');

    final alternativeType = _alternativeFor(block.type);
    final nextVersion = current.planVersion + 1;
    final replacementId = '${block.blockId}-replacement-v$nextVersion';
    final replacementMinutes = _replacementMinutes(
      alternativeType,
      block.plannedMinutes,
    );

    final change = StudyPlanManualChange(
      action: StudyPlanManualAction.replace,
      changedAt: at,
      note: 'Learner replaced task with ${alternativeType.name}.',
      previousMinutes: block.plannedMinutes,
      newMinutes: replacementMinutes,
    );
    final replacedOriginal = block.copyWith(
      status: StudyPlanBlockStatus.replaced,
      replacedByBlockId: replacementId,
      manualChanges: <StudyPlanManualChange>[...block.manualChanges, change],
    );
    final replacement = block.copyWith(
      blockId: replacementId,
      type: alternativeType,
      plannedMinutes: replacementMinutes,
      questionCount: _questionCount(alternativeType, replacementMinutes),
      status: StudyPlanBlockStatus.planned,
      createdAt: at,
      clearStartedAt: true,
      clearCompletedAt: true,
      replacesBlockId: block.blockId,
      clearReplacedByBlockId: true,
      reasonCodes: <String>{
        ...block.reasonCodes,
        'LEARNER_REPLACED',
        'SAME_COMPETENCY_ALTERNATIVE',
      }.toList(growable: false),
      reasonText:
          '${block.reasonText} Alternative method selected for the same competency.',
      manualChanges: <StudyPlanManualChange>[...block.manualChanges, change],
    );

    // A replacement must be executable before it is committed to the plan.
    resolveTarget(replacement);

    final blocks = <StudyPlanBlock>[
      for (final item in current.blocks)
        if (item.blockId == block.blockId) replacedOriginal else item,
      replacement,
    ];
    final changed = current.nextVersion(
      generatedAt: at,
      blocks: blocks,
      availableMinutes: current.availableMinutes,
      generationReason: DailyStudyPlanGenerationReason.manualRequest,
      sourceEvidenceVersion: current.sourceEvidenceVersion,
      sourceReadinessVersion: current.sourceReadinessVersion,
    );
    changed.validate();
    await repository.commitPlanMutation(plan: changed);

    return ExecutableDailyPlanActionResult(
      plan: changed,
      replacementBlock: replacement,
    );
  }

  Future<DailyStudyPlan> _currentPlan(DailyStudyPlan sourcePlan) async {
    final current = await repository.loadLatestForDate(sourcePlan.date);
    if (current == null) return sourcePlan;
    if (current.planId != sourcePlan.planId ||
        current.userId != sourcePlan.userId) {
      throw StateError('Daily Plan identity changed during action execution.');
    }
    return current;
  }

  StudyPlanBlock _findBlock(DailyStudyPlan plan, String blockId) {
    for (final block in plan.blocks) {
      if (block.blockId == blockId) return block;
    }
    throw StateError('Study-plan block not found.');
  }

  void _requireEditable(StudyPlanBlock block, String action) {
    if (block.status != StudyPlanBlockStatus.planned &&
        block.status != StudyPlanBlockStatus.shortened) {
      throw StateError('Only planned or shortened tasks can be $action.');
    }
  }

  StudyPlanBlockType _alternativeFor(StudyPlanBlockType type) {
    switch (type) {
      case StudyPlanBlockType.learn:
      case StudyPlanBlockType.continueLearning:
        return StudyPlanBlockType.standardPractice;
      case StudyPlanBlockType.repair:
      case StudyPlanBlockType.diagnostic:
      case StudyPlanBlockType.confidenceCalibration:
        return StudyPlanBlockType.standardPractice;
      case StudyPlanBlockType.spacedReview:
      case StudyPlanBlockType.competencyRecheck:
        return StudyPlanBlockType.standardPractice;
      case StudyPlanBlockType.standardPractice:
        return StudyPlanBlockType.spacedReview;
      case StudyPlanBlockType.ultraHardPractice:
        return StudyPlanBlockType.mixedRetrieval;
      case StudyPlanBlockType.mixedRetrieval:
        return StudyPlanBlockType.spacedReview;
      case StudyPlanBlockType.examSimulation:
        return StudyPlanBlockType.mixedRetrieval;
      case StudyPlanBlockType.recovery:
        return StudyPlanBlockType.continueLearning;
    }
  }

  int _replacementMinutes(StudyPlanBlockType type, int originalMinutes) {
    switch (type) {
      case StudyPlanBlockType.spacedReview:
      case StudyPlanBlockType.recovery:
        return originalMinutes.clamp(5, 10).toInt();
      case StudyPlanBlockType.standardPractice:
      case StudyPlanBlockType.ultraHardPractice:
      case StudyPlanBlockType.mixedRetrieval:
      case StudyPlanBlockType.competencyRecheck:
      case StudyPlanBlockType.confidenceCalibration:
      case StudyPlanBlockType.examSimulation:
      case StudyPlanBlockType.diagnostic:
        return originalMinutes.clamp(5, 15).toInt();
      case StudyPlanBlockType.learn:
      case StudyPlanBlockType.continueLearning:
      case StudyPlanBlockType.repair:
        return originalMinutes.clamp(5, 10).toInt();
    }
  }

  int _questionCount(StudyPlanBlockType type, int minutes) {
    switch (type) {
      case StudyPlanBlockType.diagnostic:
      case StudyPlanBlockType.standardPractice:
      case StudyPlanBlockType.ultraHardPractice:
      case StudyPlanBlockType.mixedRetrieval:
      case StudyPlanBlockType.competencyRecheck:
      case StudyPlanBlockType.confidenceCalibration:
      case StudyPlanBlockType.examSimulation:
        return (minutes ~/ 2).clamp(3, 10).toInt();
      case StudyPlanBlockType.learn:
      case StudyPlanBlockType.continueLearning:
      case StudyPlanBlockType.repair:
      case StudyPlanBlockType.spacedReview:
      case StudyPlanBlockType.recovery:
        return 0;
    }
  }
}
