import '../models/daily_study_plan.dart';
import '../models/plan_regeneration_reason.dart';
import '../repositories/daily_study_plan_repository.dart';
import '../repositories/exam_study_plan_repository.dart';
import '../repositories/readiness_snapshot_repository.dart';
import 'daily_study_plan_service.dart';
import 'exam_study_capacity_service.dart';
import 'ultra_hard_availability_service.dart';

class PlanReplanningService {
  PlanReplanningService({
    this.planService = const DailyStudyPlanService(),
    this.capacityService = const ExamStudyCapacityService(),
    UltraHardAvailabilityService? ultraHardAvailabilityService,
  }) : ultraHardAvailabilityService =
           ultraHardAvailabilityService ?? UltraHardAvailabilityService();

  final DailyStudyPlanService planService;
  final ExamStudyCapacityService capacityService;
  final UltraHardAvailabilityService ultraHardAvailabilityService;

  Future<DailyStudyPlan?> regenerateForDate({
    required DateTime date,
    required PlanRegenerationReason reason,
    DateTime? now,
    Set<String>? ultraHardAvailableCompetencyIds,
    Set<String> recentlyStudiedCompetencyIds = const <String>{},
    ExamStudyPlanRepository? examPlanRepository,
    ReadinessSnapshotRepository? readinessRepository,
    DailyStudyPlanRepository? dailyPlanRepository,
  }) async {
    final examRepo = examPlanRepository ?? ExamStudyPlanRepository();
    final readinessRepo = readinessRepository ?? ReadinessSnapshotRepository();
    final dailyRepo = dailyPlanRepository ?? DailyStudyPlanRepository();

    final examPlan = await examRepo.loadActivePlan();
    if (examPlan == null) return null;

    final availableMinutes = capacityService.minutesForDate(
      plan: examPlan,
      date: date,
    );
    final readiness = await readinessRepo.loadLocal();
    final existing = await dailyRepo.loadLatestForDate(date);

    var ultraAvailable = ultraHardAvailableCompetencyIds;
    if (ultraAvailable == null) {
      try {
        ultraAvailable =
            await ultraHardAvailabilityService.loadAvailableCompetencyIds();
      } catch (_) {
        ultraAvailable = const <String>{};
      }
    }

    final generated = planService.generate(
      userId: examPlan.userId,
      date: date,
      generatedAt: now ?? DateTime.now(),
      examDate: examPlan.examDate,
      availableMinutes: availableMinutes,
      readinessProfiles: readiness,
      ultraHardAvailableCompetencyIds: ultraAvailable,
      recentlyStudiedCompetencyIds: recentlyStudiedCompetencyIds,
      existingPlan: existing,
      generationReason: reason.dailyPlanReason,
    );

    await dailyRepo.savePlan(generated, syncRemote: false);
    return generated;
  }
}
