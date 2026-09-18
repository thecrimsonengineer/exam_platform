import '../models/daily_study_plan.dart';
import '../models/plan_regeneration_reason.dart';
import '../repositories/daily_study_plan_repository.dart';

class PlanStalenessService {
  const PlanStalenessService();

  Future<int> markFuturePlansStale({
    required DateTime afterDate,
    required PlanRegenerationReason reason,
    required DateTime at,
    DailyStudyPlanRepository? repository,
  }) async {
    final repo = repository ?? DailyStudyPlanRepository();
    final history = await repo.loadHistory();
    final cutoff = _dateOnly(afterDate);

    final latestByDate = <String, DailyStudyPlan>{};
    for (final plan in history) {
      final key = _dayKey(plan.date);
      final existing = latestByDate[key];
      if (existing == null || plan.planVersion > existing.planVersion) {
        latestByDate[key] = plan;
      }
    }

    var created = 0;
    for (final plan in latestByDate.values) {
      if (!_dateOnly(plan.date).isAfter(cutoff) ||
          plan.status == DailyStudyPlanStatus.stale) {
        continue;
      }

      final stale = plan.copyWith(
        generatedAt: at,
        planVersion: plan.planVersion + 1,
        generationReason: reason.dailyPlanReason,
        previousPlanId: '${plan.planId}:v${plan.planVersion}',
        status: DailyStudyPlanStatus.stale,
      );
      await repo.savePlan(stale, syncRemote: false);
      created++;
    }

    return created;
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  String _dayKey(DateTime value) {
    final date = _dateOnly(value);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
