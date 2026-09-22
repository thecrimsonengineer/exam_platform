import '../models/study_plan_block.dart';
import '../models/today_plan_task_category.dart';
import 'today_plan_task_category_policy.dart';

class TodayPlanPresentationFilter {
  const TodayPlanPresentationFilter({
    this.categoryPolicy = const TodayPlanTaskCategoryPolicy(),
  });

  final TodayPlanTaskCategoryPolicy categoryPolicy;

  List<StudyPlanBlock> apply({
    required Iterable<StudyPlanBlock> blocks,
    TodayPlanTaskCategory? category,
  }) {
    final source = List<StudyPlanBlock>.unmodifiable(blocks);

    if (category == null) {
      return source;
    }

    return List<StudyPlanBlock>.unmodifiable(
      source.where((block) => categoryPolicy.categoryFor(block) == category),
    );
  }
}
