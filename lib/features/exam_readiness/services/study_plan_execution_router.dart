import '../models/daily_study_plan.dart';
import '../models/study_plan_block.dart';
import '../models/study_plan_execution_attempt.dart';
import '../models/study_plan_execution_target.dart';

typedef StudyPlanExecutionTargetResolver = StudyPlanExecutionTarget Function(
  StudyPlanBlock block,
);

/// Persistence boundary for the ERDP-4 start transaction.
///
/// [commitStart] must persist the started DailyStudyPlan version and the
/// corresponding execution attempt as one logical commit. If it throws, the
/// router will not navigate and must not report the task as started.
abstract class StudyPlanExecutionStore {
  Future<StudyPlanExecutionStartCommit> commitStart({
    required DailyStudyPlan sourcePlan,
    required StudyPlanBlock block,
    required StudyPlanExecutionTarget target,
    required DateTime at,
  });

  /// Persists a recoverable navigation-failure marker for an already committed
  /// execution attempt. Failure to write this marker must never roll back the
  /// already committed started plan or delete the attempt.
  Future<void> persistNavigationFailure(StudyPlanExecutionAttempt attempt);
}

abstract class StudyPlanExecutionNavigator {
  Future<void> open(StudyPlanExecutionTarget target);
}

class StudyPlanExecutionStartCommit {
  const StudyPlanExecutionStartCommit({
    required this.startedPlan,
    required this.attempt,
  });

  final DailyStudyPlan startedPlan;
  final StudyPlanExecutionAttempt attempt;
}

class StudyPlanExecutionResult {
  const StudyPlanExecutionResult({
    required this.target,
    required this.startedPlan,
    required this.attempt,
    required this.navigationSucceeded,
    required this.navigationFailurePersisted,
    this.navigationFailureCode,
  });

  final StudyPlanExecutionTarget target;
  final DailyStudyPlan startedPlan;
  final StudyPlanExecutionAttempt attempt;
  final bool navigationSucceeded;
  final bool navigationFailurePersisted;
  final String? navigationFailureCode;

  bool get isRecoverableNavigationFailure =>
      !navigationSucceeded &&
      (attempt.status == StudyPlanExecutionAttemptStatus.navigationFailed ||
          attempt.status == StudyPlanExecutionAttemptStatus.started);
}

class StudyPlanExecutionRouter {
  const StudyPlanExecutionRouter({
    required this.resolveTarget,
    required this.store,
    required this.navigator,
  });

  final StudyPlanExecutionTargetResolver resolveTarget;
  final StudyPlanExecutionStore store;
  final StudyPlanExecutionNavigator navigator;

  Future<StudyPlanExecutionResult> start({
    required DailyStudyPlan plan,
    required String blockId,
    required DateTime at,
  }) async {
    final block = _findBlock(plan, blockId);
    _validateStartable(block);

    // Target resolution occurs before any persisted state mutation.
    final target = resolveTarget(block);
    _validateTarget(block, target);

    // This is the transaction boundary. If persistence fails, navigation is
    // never attempted and no success result is produced.
    final commit = await store.commitStart(
      sourcePlan: plan,
      block: block,
      target: target,
      at: at,
    );
    _validateCommit(
      sourcePlan: plan,
      block: block,
      target: target,
      commit: commit,
      at: at,
    );

    try {
      await navigator.open(target);
      return StudyPlanExecutionResult(
        target: target,
        startedPlan: commit.startedPlan,
        attempt: commit.attempt,
        navigationSucceeded: true,
        navigationFailurePersisted: false,
      );
    } catch (error) {
      final failureCode = 'NAVIGATION_${error.runtimeType}';
      final failedAttempt = commit.attempt.markNavigationFailed(
        at: DateTime.now().toUtc(),
        failureCode: failureCode,
      );

      var failurePersisted = false;
      try {
        await store.persistNavigationFailure(failedAttempt);
        failurePersisted = true;
      } catch (_) {
        // The original started attempt remains the recovery anchor. A failed
        // marker write must not invent a rollback or false completion.
      }

      return StudyPlanExecutionResult(
        target: target,
        startedPlan: commit.startedPlan,
        attempt: failedAttempt,
        navigationSucceeded: false,
        navigationFailurePersisted: failurePersisted,
        navigationFailureCode: failureCode,
      );
    }
  }

  StudyPlanBlock _findBlock(DailyStudyPlan plan, String blockId) {
    for (final block in plan.blocks) {
      if (block.blockId == blockId) return block;
    }
    throw StateError('Study-plan block is not part of the active plan.');
  }

  void _validateStartable(StudyPlanBlock block) {
    if (block.status != StudyPlanBlockStatus.planned &&
        block.status != StudyPlanBlockStatus.shortened) {
      throw StateError(
        'Only planned or shortened study-plan blocks may start a new execution attempt.',
      );
    }
    if (block.plannedMinutes <= 0) {
      throw StateError('Study-plan block has no executable duration.');
    }
  }

  void _validateTarget(
    StudyPlanBlock block,
    StudyPlanExecutionTarget target,
  ) {
    if (target.blockId != block.blockId ||
        target.blockType != block.type ||
        target.competencyId != block.competencyId ||
        target.domainId != block.domainId) {
      throw StateError('Execution target does not match the planned block.');
    }
  }

  void _validateCommit({
    required DailyStudyPlan sourcePlan,
    required StudyPlanBlock block,
    required StudyPlanExecutionTarget target,
    required StudyPlanExecutionStartCommit commit,
    required DateTime at,
  }) {
    final startedPlan = commit.startedPlan;
    final attempt = commit.attempt;

    if (startedPlan.planId != sourcePlan.planId ||
        startedPlan.userId != sourcePlan.userId ||
        startedPlan.planVersion <= sourcePlan.planVersion) {
      throw StateError('Execution start commit returned an invalid plan version.');
    }

    final startedBlock = _findBlock(startedPlan, block.blockId);
    if (startedBlock.status != StudyPlanBlockStatus.started ||
        startedBlock.startedAt == null) {
      throw StateError('Execution start commit did not persist started state.');
    }

    final expectedAttemptId = StudyPlanExecutionAttempt.deterministicId(
      planId: sourcePlan.planId,
      sourcePlanVersion: sourcePlan.planVersion,
      blockId: block.blockId,
    );

    if (attempt.executionAttemptId != expectedAttemptId ||
        attempt.planId != sourcePlan.planId ||
        attempt.sourcePlanVersion != sourcePlan.planVersion ||
        attempt.committedPlanVersion != startedPlan.planVersion ||
        attempt.blockId != block.blockId ||
        attempt.targetKind != target.kind ||
        attempt.status != StudyPlanExecutionAttemptStatus.started ||
        startedBlock.startedAt != attempt.startedAt ||
        attempt.startedAt.isAfter(at)) {
      throw StateError('Execution start commit returned an invalid attempt.');
    }
  }
}
