import '../models/competency_readiness_profile.dart';
import '../models/daily_study_plan.dart';
import '../models/learning_state_update_event.dart';
import '../models/study_plan_block_outcome.dart';
import '../models/weekly_readiness_review.dart';

class WeeklyReadinessReviewService {
  const WeeklyReadinessReviewService();

  WeeklyReadinessReview build({
    required DateTime weekStart,
    required Iterable<DailyStudyPlan> plans,
    required Iterable<StudyPlanBlockOutcome> outcomes,
    required Iterable<LearningStateUpdateEvent> auditEvents,
    required Map<String, CompetencyReadinessProfile> readinessProfiles,
  }) {
    final start = DateTime(weekStart.year, weekStart.month, weekStart.day);
    final end = start.add(const Duration(days: 7));

    final latestPlans = <String, DailyStudyPlan>{};
    for (final plan in plans.where((plan) => _inWindow(plan.date, start, end))) {
      final key =
          '${plan.date.year}-${plan.date.month}-${plan.date.day}:${plan.planId}';
      final existing = latestPlans[key];
      if (existing == null || plan.planVersion > existing.planVersion) {
        latestPlans[key] = plan;
      }
    }

    final weekOutcomes = outcomes
        .where((item) => _inWindow(item.completedAt, start, end))
        .toList(growable: false);
    final weekEvents = auditEvents
        .where((item) => _inWindow(item.occurredAt, start, end))
        .toList(growable: false);

    final deltas = _dimensionDeltas(weekEvents);
    final improved = weekEvents
        .where((event) => _eventImproved(event))
        .map((event) => event.competencyId)
        .toSet();

    final evidenceGaps = readinessProfiles.values
        .where((profile) => profile.hasEvidenceGap)
        .length;
    final critical = readinessProfiles.values
        .where((profile) => profile.hasCriticalGap)
        .length;

    final focus = readinessProfiles.values.toList(growable: false)
      ..sort((left, right) {
        final criticalOrder =
            (right.hasCriticalGap ? 1 : 0).compareTo(left.hasCriticalGap ? 1 : 0);
        if (criticalOrder != 0) return criticalOrder;
        final evidenceOrder =
            (right.hasEvidenceGap ? 1 : 0).compareTo(left.hasEvidenceGap ? 1 : 0);
        if (evidenceOrder != 0) return evidenceOrder;
        return left.competencyId.compareTo(right.competencyId);
      });

    return WeeklyReadinessReview(
      weekStart: start,
      weekEnd: end.subtract(const Duration(microseconds: 1)),
      plannedMinutes: latestPlans.values.fold<int>(
        0,
        (sum, plan) => sum + plan.allocatedMinutes,
      ),
      completedMinutes: weekOutcomes
          .where((item) => !item.abandoned)
          .fold<int>(0, (sum, item) => sum + item.minutesSpent),
      completedBlocks: weekOutcomes.where((item) => !item.abandoned).length,
      abandonedBlocks: weekOutcomes.where((item) => item.abandoned).length,
      knowledgeDelta: deltas.$1,
      applicationDelta: deltas.$2,
      retentionDelta: deltas.$3,
      competenciesImproved: improved.length,
      newEvidenceGaps: evidenceGaps,
      criticalGapsRemaining: critical,
      focusCompetencyIds: focus
          .where((profile) => profile.hasCriticalGap || profile.hasEvidenceGap)
          .take(5)
          .map((profile) => profile.competencyId)
          .toList(growable: false),
      reasonCodes: <String>[
        if (critical > 0) 'CRITICAL_GAPS_REMAIN',
        if (evidenceGaps > 0) 'EVIDENCE_GAPS_REMAIN',
        if (weekOutcomes.any((item) => item.abandoned)) 'MISSED_OR_ABANDONED_WORK',
        if (improved.isNotEmpty) 'COMPETENCIES_IMPROVED',
      ],
    );
  }

  (double?, double?, double?) _dimensionDeltas(
    List<LearningStateUpdateEvent> events,
  ) {
    double knowledge = 0;
    double application = 0;
    double retention = 0;
    var knowledgeSamples = 0;
    var applicationSamples = 0;
    var retentionSamples = 0;

    for (final event in events) {
      if (event.previousKnowledge != null && event.nextKnowledge != null) {
        knowledge += event.nextKnowledge! - event.previousKnowledge!;
        knowledgeSamples++;
      }
      if (event.previousApplication != null &&
          event.nextApplication != null) {
        application += event.nextApplication! - event.previousApplication!;
        applicationSamples++;
      }
      if (event.previousRetention != null && event.nextRetention != null) {
        retention += event.nextRetention! - event.previousRetention!;
        retentionSamples++;
      }
    }

    return (
      knowledgeSamples == 0 ? null : knowledge / knowledgeSamples,
      applicationSamples == 0 ? null : application / applicationSamples,
      retentionSamples == 0 ? null : retention / retentionSamples,
    );
  }

  bool _eventImproved(LearningStateUpdateEvent event) {
    final deltas = <double>[];
    if (event.previousKnowledge != null && event.nextKnowledge != null) {
      deltas.add(event.nextKnowledge! - event.previousKnowledge!);
    }
    if (event.previousApplication != null &&
        event.nextApplication != null) {
      deltas.add(event.nextApplication! - event.previousApplication!);
    }
    if (event.previousRetention != null && event.nextRetention != null) {
      deltas.add(event.nextRetention! - event.previousRetention!);
    }
    return deltas.any((value) => value >= 0.05);
  }

  bool _inWindow(DateTime value, DateTime start, DateTime end) =>
      !value.isBefore(start) && value.isBefore(end);
}
