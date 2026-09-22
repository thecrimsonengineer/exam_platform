import 'daily_study_plan.dart';
import '../services/today_plan_task_category_policy.dart';

class TodayPlanCategorySummary {
  const TodayPlanCategorySummary({
    required this.category,
    required this.taskCount,
    required this.completedTaskCount,
    required this.plannedMinutes,
    required this.completedMinutes,
    required this.questionCount,
    required this.completedQuestionCount,
    required this.nextBlockId,
    required this.nextCompetencyId,
  });

  final TodayPlanTaskCategory category;
  final int taskCount;
  final int completedTaskCount;
  final int plannedMinutes;
  final int completedMinutes;
  final int questionCount;
  final int completedQuestionCount;
  final String? nextBlockId;
  final String? nextCompetencyId;

  int get remainingTaskCount => taskCount - completedTaskCount;

  int get remainingMinutes => plannedMinutes - completedMinutes;

  int get remainingQuestionCount => questionCount - completedQuestionCount;

  bool get isEmpty => taskCount == 0;

  bool get isComplete => taskCount > 0 && completedTaskCount == taskCount;
}

class TodayPlanSummary {
  TodayPlanSummary({
    required this.planId,
    required this.planVersion,
    required this.date,
    required this.planStatus,
    required this.availableMinutes,
    required this.allocatedMinutes,
    required this.completedMinutes,
    required this.taskCount,
    required this.completedTaskCount,
    required this.questionCount,
    required this.completedQuestionCount,
    required Map<TodayPlanTaskCategory, TodayPlanCategorySummary> categories,
  }) : categories = Map<TodayPlanTaskCategory, TodayPlanCategorySummary>.unmodifiable(
         categories,
       ) {
    for (final category in TodayPlanTaskCategory.values) {
      if (!this.categories.containsKey(category)) {
        throw StateError(
          'Today plan summary is missing the ${category.name} category.',
        );
      }
    }
  }

  final String planId;
  final int planVersion;
  final DateTime date;
  final DailyStudyPlanStatus planStatus;
  final int availableMinutes;
  final int allocatedMinutes;
  final int completedMinutes;
  final int taskCount;
  final int completedTaskCount;
  final int questionCount;
  final int completedQuestionCount;
  final Map<TodayPlanTaskCategory, TodayPlanCategorySummary> categories;

  TodayPlanCategorySummary category(TodayPlanTaskCategory category) =>
      categories[category]!;

  int get remainingTaskCount => taskCount - completedTaskCount;

  int get remainingMinutes => allocatedMinutes - completedMinutes;

  int get remainingQuestionCount => questionCount - completedQuestionCount;

  bool get isEmpty => taskCount == 0;

  bool get isComplete => taskCount > 0 && completedTaskCount == taskCount;
}
