import '../models/daily_study_plan.dart';
import '../models/study_plan_block.dart';
import '../models/today_plan_summary.dart';
import 'today_plan_task_category_policy.dart';

class TodayPlanSummaryService {
  const TodayPlanSummaryService({
    this.categoryPolicy = const TodayPlanTaskCategoryPolicy(),
  });

  final TodayPlanTaskCategoryPolicy categoryPolicy;

  TodayPlanSummary summarize(DailyStudyPlan plan) {
    final accumulators = <TodayPlanTaskCategory, _CategoryAccumulator>{
      for (final category in TodayPlanTaskCategory.values)
        category: _CategoryAccumulator(category),
    };

    var completedMinutes = 0;
    var completedTaskCount = 0;
    var questionCount = 0;
    var completedQuestionCount = 0;

    for (final block in plan.blocks) {
      final category = categoryPolicy.categoryFor(block);
      final accumulator = accumulators[category]!;
      final completed = block.status == StudyPlanBlockStatus.completed;

      accumulator.add(block, completed: completed);
      questionCount += block.questionCount;

      if (completed) {
        completedTaskCount++;
        completedMinutes += block.plannedMinutes;
        completedQuestionCount += block.questionCount;
      }
    }

    final categories = <TodayPlanTaskCategory, TodayPlanCategorySummary>{
      for (final entry in accumulators.entries)
        entry.key: entry.value.build(),
    };

    return TodayPlanSummary(
      planId: plan.planId,
      planVersion: plan.planVersion,
      date: plan.date,
      planStatus: plan.status,
      availableMinutes: plan.availableMinutes,
      allocatedMinutes: plan.blocks.fold<int>(
        0,
        (sum, block) => sum + block.plannedMinutes,
      ),
      completedMinutes: completedMinutes,
      taskCount: plan.blocks.length,
      completedTaskCount: completedTaskCount,
      questionCount: questionCount,
      completedQuestionCount: completedQuestionCount,
      categories: categories,
    );
  }
}

class _CategoryAccumulator {
  _CategoryAccumulator(this.category);

  final TodayPlanTaskCategory category;

  int taskCount = 0;
  int completedTaskCount = 0;
  int plannedMinutes = 0;
  int completedMinutes = 0;
  int questionCount = 0;
  int completedQuestionCount = 0;
  String? nextBlockId;
  String? nextCompetencyId;

  void add(StudyPlanBlock block, {required bool completed}) {
    taskCount++;
    plannedMinutes += block.plannedMinutes;
    questionCount += block.questionCount;

    if (completed) {
      completedTaskCount++;
      completedMinutes += block.plannedMinutes;
      completedQuestionCount += block.questionCount;
      return;
    }

    nextBlockId ??= block.blockId;
    nextCompetencyId ??= block.competencyId;
  }

  TodayPlanCategorySummary build() {
    return TodayPlanCategorySummary(
      category: category,
      taskCount: taskCount,
      completedTaskCount: completedTaskCount,
      plannedMinutes: plannedMinutes,
      completedMinutes: completedMinutes,
      questionCount: questionCount,
      completedQuestionCount: completedQuestionCount,
      nextBlockId: nextBlockId,
      nextCompetencyId: nextCompetencyId,
    );
  }
}
