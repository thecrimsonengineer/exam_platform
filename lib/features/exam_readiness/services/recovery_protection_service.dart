import '../models/daily_study_plan.dart';
import '../models/recovery_protection_snapshot.dart';
import '../models/study_plan_block.dart';

class RecoveryProtectionService {
  const RecoveryProtectionService({
    this.reducedIntensityAfterMisses = 2,
    this.recoveryDayAfterMisses = 3,
    this.algorithmVersion = currentAlgorithmVersion,
  });

  static const String currentAlgorithmVersion = 'm7f-recovery-v1';

  final int reducedIntensityAfterMisses;
  final int recoveryDayAfterMisses;
  final String algorithmVersion;

  RecoveryProtectionSnapshot evaluate({
    required Iterable<DailyStudyPlan> history,
    required DateTime today,
    required int declaredMinutes,
  }) {
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final latestByDay = <String, DailyStudyPlan>{};

    for (final plan in history) {
      final date = DateTime(plan.date.year, plan.date.month, plan.date.day);
      if (!date.isBefore(normalizedToday)) continue;
      final key = _dayKey(date);
      final existing = latestByDay[key];
      if (existing == null || plan.planVersion > existing.planVersion) {
        latestByDay[key] = plan;
      }
    }

    final ordered = latestByDay.values.toList(growable: false)
      ..sort((left, right) => right.date.compareTo(left.date));

    var consecutive = 0;
    for (final plan in ordered) {
      if (plan.availableMinutes <= 0 || plan.blocks.isEmpty) continue;
      final completed = plan.blocks.any(
        (block) => block.status == StudyPlanBlockStatus.completed,
      );
      if (completed) break;
      consecutive++;
    }

    final declared = declaredMinutes.clamp(0, 1440).toInt();
    if (consecutive >= recoveryDayAfterMisses) {
      return RecoveryProtectionSnapshot(
        state: RecoveryProtectionState.recoveryDay,
        consecutiveMissedStudyDays: consecutive,
        declaredMinutes: declared,
        suggestedMinutes: declared == 0
            ? 0
            : (declared * 0.50).round().clamp(5, declared).toInt(),
        reasonCodes: const [
          'REPEATED_MISSED_STUDY_DAYS',
          'RECOVERY_DAY_OPTION',
          'NO_BACKLOG_DUMPING',
        ],
        algorithmVersion: algorithmVersion,
      );
    }

    if (consecutive >= reducedIntensityAfterMisses) {
      return RecoveryProtectionSnapshot(
        state: RecoveryProtectionState.reducedIntensityDay,
        consecutiveMissedStudyDays: consecutive,
        declaredMinutes: declared,
        suggestedMinutes: declared == 0
            ? 0
            : (declared * 0.75).round().clamp(5, declared).toInt(),
        reasonCodes: const [
          'REPEATED_MISSED_STUDY_DAYS',
          'REDUCED_INTENSITY_OPTION',
          'NO_BACKLOG_DUMPING',
        ],
        algorithmVersion: algorithmVersion,
      );
    }

    return RecoveryProtectionSnapshot(
      state: RecoveryProtectionState.none,
      consecutiveMissedStudyDays: consecutive,
      declaredMinutes: declared,
      suggestedMinutes: declared,
      reasonCodes: const ['RECOVERY_PROTECTION_NOT_REQUIRED'],
      algorithmVersion: algorithmVersion,
    );
  }

  String _dayKey(DateTime value) => '${value.year}-${value.month}-${value.day}';
}
