import '../models/today_plan_task_category.dart';
import 'planner_constraints.dart';

class BalancedPlanPortfolioReservation {
  const BalancedPlanPortfolioReservation({
    required this.learnMinutes,
    required this.practiceMinutes,
    required this.rememberMinutes,
  });

  const BalancedPlanPortfolioReservation.none()
    : learnMinutes = 0,
      practiceMinutes = 0,
      rememberMinutes = 0;

  final int learnMinutes;
  final int practiceMinutes;
  final int rememberMinutes;

  int get totalMinutes => learnMinutes + practiceMinutes + rememberMinutes;

  bool get isActive => totalMinutes > 0;

  int minutesFor(TodayPlanTaskCategory category) {
    return switch (category) {
      TodayPlanTaskCategory.learn => learnMinutes,
      TodayPlanTaskCategory.practice => practiceMinutes,
      TodayPlanTaskCategory.remember => rememberMinutes,
    };
  }
}

/// ERDP-3 portfolio floor used by the authoritative DailyStudyPlan planner.
///
/// The policy does not create a second plan or score learner readiness. It only
/// reserves enough open capacity for missing Learn, Practice and Remember
/// families when the day is large enough to support all missing families.
class BalancedPlanPortfolioPolicy {
  const BalancedPlanPortfolioPolicy({
    this.constraints = const DailyPlannerConstraints(),
  });

  final DailyPlannerConstraints constraints;

  BalancedPlanPortfolioReservation reservationFor({
    required int availableMinutes,
    int committedMinutes = 0,
    Set<TodayPlanTaskCategory> representedCategories =
        const <TodayPlanTaskCategory>{},
  }) {
    constraints.validate();

    final normalizedAvailable = availableMinutes.clamp(0, 1440).toInt();
    final normalizedCommitted = committedMinutes.clamp(
      0,
      normalizedAvailable,
    );
    final openMinutes = normalizedAvailable - normalizedCommitted;

    final learn = representedCategories.contains(TodayPlanTaskCategory.learn)
        ? 0
        : constraints.learnMinMinutes;
    final practice =
        representedCategories.contains(TodayPlanTaskCategory.practice)
        ? 0
        : constraints.practiceMinMinutes;
    final remember =
        representedCategories.contains(TodayPlanTaskCategory.remember)
        ? 0
        : constraints.reviewMinMinutes;

    final required = learn + practice + remember;
    if (required == 0 || openMinutes < required) {
      return const BalancedPlanPortfolioReservation.none();
    }

    return BalancedPlanPortfolioReservation(
      learnMinutes: learn,
      practiceMinutes: practice,
      rememberMinutes: remember,
    );
  }
}
