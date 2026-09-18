import 'daily_study_plan.dart';

enum PlanRegenerationReason {
  dailyRollover,
  assessmentCompleted,
  majorPerformanceShift,
  examDateChanged,
  studyScheduleChanged,
  criticalGapDetected,
  manualRequest,
  missedStudyDay,
  capacityChanged,
}

extension PlanRegenerationReasonX on PlanRegenerationReason {
  DailyStudyPlanGenerationReason get dailyPlanReason {
    return switch (this) {
      PlanRegenerationReason.dailyRollover =>
        DailyStudyPlanGenerationReason.dailyRollover,
      PlanRegenerationReason.assessmentCompleted =>
        DailyStudyPlanGenerationReason.assessmentCompleted,
      PlanRegenerationReason.majorPerformanceShift =>
        DailyStudyPlanGenerationReason.majorPerformanceShift,
      PlanRegenerationReason.examDateChanged =>
        DailyStudyPlanGenerationReason.examDateChanged,
      PlanRegenerationReason.studyScheduleChanged =>
        DailyStudyPlanGenerationReason.studyScheduleChanged,
      PlanRegenerationReason.criticalGapDetected =>
        DailyStudyPlanGenerationReason.criticalGapDetected,
      PlanRegenerationReason.manualRequest =>
        DailyStudyPlanGenerationReason.manualRequest,
      PlanRegenerationReason.missedStudyDay =>
        DailyStudyPlanGenerationReason.missedStudyDay,
      PlanRegenerationReason.capacityChanged =>
        DailyStudyPlanGenerationReason.capacityChanged,
    };
  }
}
