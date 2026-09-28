import '../models/daily_study_plan.dart';
import '../models/study_plan_block.dart';
import '../models/study_plan_execution_attempt.dart';
import '../models/study_plan_execution_target.dart';
import '../repositories/daily_study_plan_repository.dart';
import 'daily_study_plan_service.dart';
import 'study_plan_execution_router.dart';

class LocalStudyPlanExecutionStore implements StudyPlanExecutionStore {
  const LocalStudyPlanExecutionStore({
    required this.planRepository,
    required this.planService,
  });

  final DailyStudyPlanRepository planRepository;
  final DailyStudyPlanService planService;

  @override
  Future<StudyPlanExecutionStartCommit> commitStart({
    required DailyStudyPlan sourcePlan,
    required StudyPlanBlock block,
    required StudyPlanExecutionTarget target,
    required DateTime at,
  }) async {
    final executionAttemptId = StudyPlanExecutionAttempt.deterministicId(
      planId: sourcePlan.planId,
      sourcePlanVersion: sourcePlan.planVersion,
      blockId: block.blockId,
    );

    final existing = await planRepository.loadExecutionAttempt(
      executionAttemptId,
    );
    if (existing != null) {
      final history = await planRepository.loadHistory();
      DailyStudyPlan? committedPlan;
      for (final plan in history) {
        if (plan.planId == existing.planId &&
            plan.planVersion == existing.committedPlanVersion) {
          committedPlan = plan;
          break;
        }
      }
      if (committedPlan == null) {
        throw StateError(
          'Execution attempt exists without its committed daily-plan version.',
        );
      }
      return StudyPlanExecutionStartCommit(
        startedPlan: committedPlan,
        attempt: existing,
      );
    }

    final startedPlan = planService.startBlock(
      sourcePlan,
      block.blockId,
      at: at,
    );
    final attempt = StudyPlanExecutionAttempt(
      executionAttemptId: executionAttemptId,
      planId: sourcePlan.planId,
      sourcePlanVersion: sourcePlan.planVersion,
      committedPlanVersion: startedPlan.planVersion,
      blockId: block.blockId,
      targetKind: target.kind,
      startedAt: at,
      status: StudyPlanExecutionAttemptStatus.started,
    );

    final committed = await planRepository.commitExecutionStart(
      startedPlan: startedPlan,
      attempt: attempt,
    );
    return StudyPlanExecutionStartCommit(
      startedPlan: committed.startedPlan,
      attempt: committed.attempt,
    );
  }

  @override
  Future<void> persistNavigationFailure(
    StudyPlanExecutionAttempt attempt,
  ) => planRepository.saveExecutionAttempt(attempt);
}
