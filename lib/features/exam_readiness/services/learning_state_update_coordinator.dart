import '../models/competency_readiness_profile.dart';
import '../models/learning_state_update_event.dart';
import '../models/misconception_signal.dart';
import '../models/plan_regeneration_reason.dart';
import '../models/study_plan_block_outcome.dart';
import '../repositories/daily_study_plan_repository.dart';
import '../repositories/evidence_snapshot_repository.dart';
import '../repositories/learner_assessment_attempt_repository.dart';
import '../repositories/learning_state_audit_repository.dart';
import '../repositories/readiness_snapshot_repository.dart';
import '../repositories/study_plan_block_outcome_repository.dart';
import 'competency_evidence_scope_service.dart';
import 'learner_evidence_aggregation_service.dart';
import 'misconception_signal_service.dart';
import 'plan_staleness_service.dart';
import 'readiness_profile_service.dart';

class LearningStateUpdateResult {
  const LearningStateUpdateResult({
    required this.outcomeRecorded,
    required this.competencyId,
    required this.profile,
    required this.regenerationReason,
    required this.misconceptionSignals,
    required this.stalePlanVersionsCreated,
    required this.auditEvent,
  });

  final bool outcomeRecorded;
  final String competencyId;
  final CompetencyReadinessProfile profile;
  final PlanRegenerationReason regenerationReason;
  final List<MisconceptionSignal> misconceptionSignals;
  final int stalePlanVersionsCreated;
  final LearningStateUpdateEvent auditEvent;
}

class LearningStateUpdateCoordinator {
  const LearningStateUpdateCoordinator({
    this.aggregationService = const LearnerEvidenceAggregationService(),
    this.readinessService = const ReadinessProfileService(),
    this.scopeService = const CompetencyEvidenceScopeService(),
    this.misconceptionService = const MisconceptionSignalService(),
    this.stalenessService = const PlanStalenessService(),
  });

  final LearnerEvidenceAggregationService aggregationService;
  final ReadinessProfileService readinessService;
  final CompetencyEvidenceScopeService scopeService;
  final MisconceptionSignalService misconceptionService;
  final PlanStalenessService stalenessService;

  Future<LearningStateUpdateResult> processOutcome({
    required StudyPlanBlockOutcome outcome,
    DateTime? now,
    PlanRegenerationReason? explicitReason,
    bool markFuturePlansStale = true,
    StudyPlanBlockOutcomeRepository? outcomeRepository,
    LearnerAssessmentAttemptRepository? attemptRepository,
    EvidenceSnapshotRepository? evidenceRepository,
    ReadinessSnapshotRepository? readinessRepository,
    DailyStudyPlanRepository? planRepository,
    LearningStateAuditRepository? auditRepository,
  }) async {
    outcome.validate();
    final at = now ?? outcome.completedAt;
    final outcomes =
        outcomeRepository ?? const StudyPlanBlockOutcomeRepository();
    final attemptsRepo =
        attemptRepository ?? const LearnerAssessmentAttemptRepository();
    final evidenceRepo = evidenceRepository ?? EvidenceSnapshotRepository();
    final readinessRepo = readinessRepository ?? ReadinessSnapshotRepository();
    final plansRepo = planRepository ?? DailyStudyPlanRepository();
    final audit = auditRepository ?? const LearningStateAuditRepository();

    final recorded = await outcomes.append(outcome);
    final previous = await readinessRepo.load(outcome.competencyId);
    final attempts = await attemptsRepo.loadAll();
    final scope = await scopeService.resolve(
      competencyId: outcome.competencyId,
      attempts: attempts,
    );

    final evidence = aggregationService.updateCompetencySnapshot(
      competencyId: outcome.competencyId,
      attemptsForCompetency: attempts,
      scope: scope,
      now: at,
    );
    await evidenceRepo.save(evidence, syncRemote: false);

    final profile = readinessService.buildCompetencyProfile(
      evidence: evidence,
      attempts: attempts,
      now: at,
    );
    await readinessRepo.save(profile, syncRemote: false);

    final signals = misconceptionService.detect(
      competencyId: outcome.competencyId,
      attempts: attempts,
      now: at,
    );
    final reason =
        explicitReason ??
        _reason(previous: previous, next: profile, signals: signals);

    final staleCount = markFuturePlansStale
        ? await stalenessService.markFuturePlansStale(
            afterDate: outcome.completedAt,
            reason: reason,
            at: at,
            repository: plansRepo,
          )
        : 0;

    final event = LearningStateUpdateEvent(
      eventId: 'm7e-${outcome.outcomeId}-${at.microsecondsSinceEpoch}',
      outcomeId: outcome.outcomeId,
      competencyId: profile.competencyId,
      occurredAt: at,
      regenerationReason: reason,
      previousReadinessState: previous?.readinessState.name,
      nextReadinessState: profile.readinessState.name,
      previousKnowledge: previous?.knowledgeMastery.value,
      nextKnowledge: profile.knowledgeMastery.value,
      previousApplication: previous?.applicationAbility.value,
      nextApplication: profile.applicationAbility.value,
      previousRetention: previous?.retention.value,
      nextRetention: profile.retention.value,
      stalePlanVersionsCreated: staleCount,
      misconceptionCodes: signals
          .expand((signal) => signal.reasonCodes)
          .toSet()
          .toList(growable: false),
      reasonCodes: <String>{
        ...profile.explanationCodes,
        reason.name,
      }.toList(growable: false),
    );
    await audit.append(event);

    return LearningStateUpdateResult(
      outcomeRecorded: recorded,
      competencyId: profile.competencyId,
      profile: profile,
      regenerationReason: reason,
      misconceptionSignals: signals,
      stalePlanVersionsCreated: staleCount,
      auditEvent: event,
    );
  }

  PlanRegenerationReason _reason({
    required CompetencyReadinessProfile? previous,
    required CompetencyReadinessProfile next,
    required List<MisconceptionSignal> signals,
  }) {
    if (next.hasCriticalGap) {
      return PlanRegenerationReason.criticalGapDetected;
    }
    if (signals.isNotEmpty) {
      return PlanRegenerationReason.majorPerformanceShift;
    }
    if (previous != null && _majorShift(previous, next)) {
      return PlanRegenerationReason.majorPerformanceShift;
    }
    return PlanRegenerationReason.assessmentCompleted;
  }

  bool _majorShift(
    CompetencyReadinessProfile previous,
    CompetencyReadinessProfile next,
  ) {
    if (previous.readinessState != next.readinessState) return true;
    for (final pair in [
      (previous.knowledgeMastery.value, next.knowledgeMastery.value),
      (previous.applicationAbility.value, next.applicationAbility.value),
      (previous.retention.value, next.retention.value),
    ]) {
      final before = pair.$1;
      final after = pair.$2;
      if (before != null && after != null && (after - before).abs() >= 0.15) {
        return true;
      }
    }
    return false;
  }
}
