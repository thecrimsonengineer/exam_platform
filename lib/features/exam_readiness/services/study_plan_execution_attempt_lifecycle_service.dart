import '../models/daily_study_plan.dart';
import '../models/study_plan_block.dart';
import '../models/study_plan_execution_attempt.dart';
import '../repositories/daily_study_plan_repository.dart';

class StudyPlanExecutionAttemptLifecycleService {
  const StudyPlanExecutionAttemptLifecycleService();

  Future<int> closeForCompletedBlock({
    required DailyStudyPlan plan,
    required StudyPlanBlock block,
    DailyStudyPlanRepository? repository,
  }) async {
    if (block.status != StudyPlanBlockStatus.completed ||
        block.completedAt == null) {
      throw StateError(
        'Execution attempt closure requires a completed study-plan block.',
      );
    }
    if (plan.planId.trim().isEmpty || block.blockId.trim().isEmpty) {
      throw StateError('Execution attempt closure requires stable identities.');
    }

    final repo = repository ?? DailyStudyPlanRepository();
    final attempts = await repo.loadExecutionAttempts();
    var changed = 0;

    for (final attempt in attempts) {
      if (attempt.planId != plan.planId || attempt.blockId != block.blockId) {
        continue;
      }
      if (attempt.status == StudyPlanExecutionAttemptStatus.completed) {
        continue;
      }

      await repo.saveExecutionAttempt(
        StudyPlanExecutionAttempt(
          executionAttemptId: attempt.executionAttemptId,
          planId: attempt.planId,
          sourcePlanVersion: attempt.sourcePlanVersion,
          committedPlanVersion: attempt.committedPlanVersion,
          blockId: attempt.blockId,
          targetKind: attempt.targetKind,
          startedAt: attempt.startedAt,
          status: StudyPlanExecutionAttemptStatus.completed,
          navigationFailedAt: attempt.navigationFailedAt,
          failureCode: attempt.failureCode,
        ),
      );
      changed++;
    }

    return changed;
  }
}
