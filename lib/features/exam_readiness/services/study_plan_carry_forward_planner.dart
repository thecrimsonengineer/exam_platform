import '../models/daily_study_plan.dart';
import '../models/study_plan_block.dart';
import '../models/study_plan_carry_forward.dart';

class StudyPlanCarryForwardPlanningResult {
  const StudyPlanCarryForwardPlanningResult({
    required this.plan,
    required this.consumedIds,
  });

  final DailyStudyPlan plan;
  final Set<String> consumedIds;
}

class StudyPlanCarryForwardPlanner {
  const StudyPlanCarryForwardPlanner();

  StudyPlanCarryForwardPlanningResult apply({
    required DailyStudyPlan basePlan,
    required Iterable<StudyPlanCarryForward> pendingCarryForwards,
    required DateTime at,
  }) {
    final due = pendingCarryForwards
        .where(
          (item) =>
              item.status == StudyPlanCarryForwardStatus.pending &&
              item.learnerId == basePlan.userId &&
              !_dateOnly(item.dueDate).isAfter(_dateOnly(basePlan.date)),
        )
        .toList(growable: false)
      ..sort((left, right) {
        final dueOrder = left.dueDate.compareTo(right.dueDate);
        if (dueOrder != 0) return dueOrder;
        return left.createdAt.compareTo(right.createdAt);
      });

    if (due.isEmpty) {
      return StudyPlanCarryForwardPlanningResult(
        plan: basePlan,
        consumedIds: const <String>{},
      );
    }

    final retainedLocked = basePlan.blocks
        .where((block) => block.isLocked)
        .toList(growable: false);
    var allocated = retainedLocked.fold<int>(
      0,
      (sum, block) => sum + block.plannedMinutes,
    );
    final blocks = <StudyPlanBlock>[...retainedLocked];
    final consumed = <String>{};
    final carriedCompetencies = <String>{};

    for (final item in due) {
      final minutes = item.sourceBlock.plannedMinutes;
      if (minutes <= 0 || allocated + minutes > basePlan.availableMinutes) {
        continue;
      }

      final blockId = '${basePlan.planId}-carry-${_safe(item.id)}';
      final carried = item.sourceBlock.copyWith(
        blockId: blockId,
        status: StudyPlanBlockStatus.planned,
        createdAt: at,
        clearStartedAt: true,
        clearCompletedAt: true,
        clearReplacesBlockId: true,
        clearReplacedByBlockId: true,
        reasonCodes: <String>{
          ...item.sourceBlock.reasonCodes,
          'CARRY_FORWARD',
          'CARRY_FORWARD_ID_${_safe(item.id)}',
        }.toList(growable: false),
        reasonText:
            '${item.sourceBlock.reasonText} Carried forward from a previous day.',
        manualChanges: const <StudyPlanManualChange>[],
      );

      blocks.add(carried);
      allocated += minutes;
      consumed.add(item.id);
      carriedCompetencies.add(item.competencyId);
    }

    final ordinary = basePlan.blocks
        .where((block) => !block.isLocked && !block.isTerminalChange)
        .toList(growable: false);
    final orderedOrdinary = <StudyPlanBlock>[
      ...ordinary.where(
        (block) => !carriedCompetencies.contains(block.competencyId),
      ),
      ...ordinary.where(
        (block) => carriedCompetencies.contains(block.competencyId),
      ),
    ];

    for (final block in orderedOrdinary) {
      if (blocks.any((item) => item.blockId == block.blockId)) continue;
      if (allocated + block.plannedMinutes > basePlan.availableMinutes) {
        continue;
      }
      blocks.add(block);
      allocated += block.plannedMinutes;
    }

    final plan = basePlan.copyWith(
      blocks: blocks,
      allocatedMinutes: allocated,
      inputSnapshotVersion:
          '${basePlan.inputSnapshotVersion}|carry:${consumed.toList()..sort()}',
    );
    plan.validate();

    return StudyPlanCarryForwardPlanningResult(
      plan: plan,
      consumedIds: Set<String>.unmodifiable(consumed),
    );
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  String _safe(String value) =>
      value.trim().replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_');
}
