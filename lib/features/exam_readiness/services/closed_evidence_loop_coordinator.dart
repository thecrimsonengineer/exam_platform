import '../models/daily_study_plan.dart';
import '../models/learning_evidence_event.dart';
import '../models/study_plan_block.dart';
import '../models/study_plan_block_outcome.dart';
import '../repositories/daily_study_plan_repository.dart';
import '../repositories/evidence_snapshot_repository.dart';
import '../repositories/exam_study_plan_repository.dart';
import '../repositories/learner_assessment_attempt_repository.dart';
import '../repositories/learning_evidence_event_repository.dart';
import '../repositories/learning_state_audit_repository.dart';
import '../repositories/readiness_snapshot_repository.dart';
import '../repositories/study_plan_block_outcome_repository.dart';
import 'learning_evidence_normalizer.dart';
import 'learning_state_update_coordinator.dart';
import 'plan_replanning_service.dart';

class ClosedEvidenceLoopResult {
  const ClosedEvidenceLoopResult({
    required this.evidenceEvent,
    required this.evidenceRecorded,
    required this.learningStateUpdate,
    required this.adaptedPlan,
  });

  final LearningEvidenceEvent evidenceEvent;
  final bool evidenceRecorded;
  final LearningStateUpdateResult learningStateUpdate;
  final DailyStudyPlan? adaptedPlan;

  bool get replanned => adaptedPlan != null;
}

class ClosedEvidenceLoopCoordinator {
  ClosedEvidenceLoopCoordinator({
    this.normalizer = const LearningEvidenceNormalizer(),
    this.stateCoordinator = const LearningStateUpdateCoordinator(),
    PlanReplanningService? replanningService,
  }) : replanningService = replanningService ?? PlanReplanningService();

  final LearningEvidenceNormalizer normalizer;
  final LearningStateUpdateCoordinator stateCoordinator;
  final PlanReplanningService replanningService;

  Future<ClosedEvidenceLoopResult> processCompletion({
    required DailyStudyPlan completedPlan,
    required StudyPlanBlock completedBlock,
    required StudyPlanBlockOutcome outcome,
    LearningEvidenceEventRepository? evidenceEventRepository,
    StudyPlanBlockOutcomeRepository? outcomeRepository,
    LearnerAssessmentAttemptRepository? attemptRepository,
    EvidenceSnapshotRepository? evidenceRepository,
    ReadinessSnapshotRepository? readinessRepository,
    DailyStudyPlanRepository? dailyPlanRepository,
    ExamStudyPlanRepository? examPlanRepository,
    LearningStateAuditRepository? auditRepository,
  }) async {
    if (completedBlock.status != StudyPlanBlockStatus.completed ||
        completedBlock.completedAt == null) {
      throw StateError(
        'Closed evidence processing requires a completed study-plan block.',
      );
    }
    if (completedPlan.blocks.every(
      (block) => block.blockId != completedBlock.blockId,
    )) {
      throw StateError('Completed block is not part of the supplied plan.');
    }

    final event = normalizer.fromStudyPlanOutcome(
      block: completedBlock,
      outcome: outcome,
    );
    final eventRepository =
        evidenceEventRepository ?? const LearningEvidenceEventRepository();
    final evidenceRecorded = await eventRepository.append(event);

    final update = await stateCoordinator.processOutcome(
      outcome: outcome,
      now: event.occurredAt,
      markFuturePlansStale: false,
      outcomeRepository: outcomeRepository,
      attemptRepository: attemptRepository,
      evidenceRepository: evidenceRepository,
      readinessRepository: readinessRepository,
      planRepository: dailyPlanRepository,
      auditRepository: auditRepository,
      evidenceEventRepository: eventRepository,
    );

    final adaptedPlan = await replanningService.regenerateForDate(
      date: completedPlan.date,
      reason: update.regenerationReason,
      now: event.occurredAt,
      triggerEvidenceEventId: event.evidenceEventId,
      examPlanRepository: examPlanRepository,
      readinessRepository: readinessRepository,
      dailyPlanRepository: dailyPlanRepository,
    );

    return ClosedEvidenceLoopResult(
      evidenceEvent: event,
      evidenceRecorded: evidenceRecorded,
      learningStateUpdate: update,
      adaptedPlan: adaptedPlan,
    );
  }
}
