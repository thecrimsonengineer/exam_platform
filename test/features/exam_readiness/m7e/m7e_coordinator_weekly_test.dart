import 'package:exam_platform/features/exam_readiness/models/evidence_confidence.dart';
import 'package:exam_platform/features/exam_readiness/models/learning_state_update_event.dart';
import 'package:exam_platform/features/exam_readiness/models/learner_assessment_attempt.dart';
import 'package:exam_platform/features/exam_readiness/models/readiness_gap.dart';
import 'package:exam_platform/features/exam_readiness/models/plan_regeneration_reason.dart';
import 'package:exam_platform/features/exam_readiness/repositories/daily_study_plan_repository.dart';
import 'package:exam_platform/features/exam_readiness/repositories/evidence_snapshot_repository.dart';
import 'package:exam_platform/features/exam_readiness/repositories/learner_assessment_attempt_repository.dart';
import 'package:exam_platform/features/exam_readiness/repositories/learning_state_audit_repository.dart';
import 'package:exam_platform/features/exam_readiness/repositories/readiness_snapshot_repository.dart';
import 'package:exam_platform/features/exam_readiness/repositories/study_plan_block_outcome_repository.dart';
import 'package:exam_platform/features/exam_readiness/services/learning_state_update_coordinator.dart';
import 'package:exam_platform/features/exam_readiness/services/weekly_readiness_review_service.dart';
import 'package:exam_platform/services/auth/learner_local_identity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../m7d/_support/m7d_fixture.dart';
import '_support/m7e_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LearnerLocalIdentity.activate('u1');
  });

  tearDown(LearnerLocalIdentity.clear);

  group('M7E LearningStateUpdateCoordinator', () {
    test('records block outcome locally', () async {
      const attempts = LearnerAssessmentAttemptRepository(userIdOverride: 'u1');
      await attempts.append(m7eAttempt());

      final result = await const LearningStateUpdateCoordinator().processOutcome(
        outcome: m7eOutcome(),
        markFuturePlansStale: false,
        attemptRepository: attempts,
        outcomeRepository:
            const StudyPlanBlockOutcomeRepository(userIdOverride: 'u1'),
        evidenceRepository: EvidenceSnapshotRepository(userIdOverride: 'u1'),
        readinessRepository: ReadinessSnapshotRepository(userIdOverride: 'u1'),
        planRepository: DailyStudyPlanRepository(userIdOverride: 'u1'),
        auditRepository: const LearningStateAuditRepository(userIdOverride: 'u1'),
      );

      expect(result.outcomeRecorded, isTrue);
    });

    test('updates evidence only for affected competency', () async {
      const attempts = LearnerAssessmentAttemptRepository(userIdOverride: 'u1');
      await attempts.append(m7eAttempt());
      final evidenceRepo = EvidenceSnapshotRepository(userIdOverride: 'u1');

      await const LearningStateUpdateCoordinator().processOutcome(
        outcome: m7eOutcome(),
        markFuturePlansStale: false,
        attemptRepository: attempts,
        evidenceRepository: evidenceRepo,
        readinessRepository: ReadinessSnapshotRepository(userIdOverride: 'u1'),
        planRepository: DailyStudyPlanRepository(userIdOverride: 'u1'),
      );

      final evidence = await evidenceRepo.loadLocal();
      expect(evidence.keys, ['d03_c02']);
    });

    test('writes affected readiness profile locally', () async {
      const attempts = LearnerAssessmentAttemptRepository(userIdOverride: 'u1');
      for (var i = 0; i < 4; i++) {
        await attempts.append(
          m7eAttempt(
            attemptId: 'a$i',
            questionId: i + 1,
            correct: i > 0,
          ),
        );
      }
      final readinessRepo = ReadinessSnapshotRepository(userIdOverride: 'u1');

      await const LearningStateUpdateCoordinator().processOutcome(
        outcome: m7eOutcome(),
        markFuturePlansStale: false,
        attemptRepository: attempts,
        evidenceRepository: EvidenceSnapshotRepository(userIdOverride: 'u1'),
        readinessRepository: readinessRepo,
        planRepository: DailyStudyPlanRepository(userIdOverride: 'u1'),
      );

      expect(await readinessRepo.load('d03_c02'), isNotNull);
    });

    test('does not remove unrelated readiness profile', () async {
      final readinessRepo = ReadinessSnapshotRepository(userIdOverride: 'u1');
      await readinessRepo.save(
        m7dProfile(competencyId: 'd01_c01'),
        syncRemote: false,
      );
      const attempts = LearnerAssessmentAttemptRepository(userIdOverride: 'u1');
      await attempts.append(m7eAttempt());

      await const LearningStateUpdateCoordinator().processOutcome(
        outcome: m7eOutcome(),
        markFuturePlansStale: false,
        attemptRepository: attempts,
        evidenceRepository: EvidenceSnapshotRepository(userIdOverride: 'u1'),
        readinessRepository: readinessRepo,
        planRepository: DailyStudyPlanRepository(userIdOverride: 'u1'),
      );

      expect(await readinessRepo.load('d01_c01'), isNotNull);
      expect(await readinessRepo.load('d03_c02'), isNotNull);
    });

    test('explicit regeneration reason is preserved', () async {
      const attempts = LearnerAssessmentAttemptRepository(userIdOverride: 'u1');
      await attempts.append(m7eAttempt());

      final result = await const LearningStateUpdateCoordinator().processOutcome(
        outcome: m7eOutcome(),
        explicitReason: PlanRegenerationReason.manualRequest,
        markFuturePlansStale: false,
        attemptRepository: attempts,
        evidenceRepository: EvidenceSnapshotRepository(userIdOverride: 'u1'),
        readinessRepository: ReadinessSnapshotRepository(userIdOverride: 'u1'),
        planRepository: DailyStudyPlanRepository(userIdOverride: 'u1'),
      );

      expect(result.regenerationReason, PlanRegenerationReason.manualRequest);
    });

    test('high-confidence incorrect pattern is surfaced', () async {
      const attempts = LearnerAssessmentAttemptRepository(userIdOverride: 'u1');
      for (var i = 0; i < 3; i++) {
        await attempts.append(
          m7eAttempt(
            attemptId: 'h$i',
            questionId: i + 1,
            correct: i == 2,
            confidence: LearnerConfidenceLevel.high,
          ),
        );
      }

      final result = await const LearningStateUpdateCoordinator().processOutcome(
        outcome: m7eOutcome(),
        markFuturePlansStale: false,
        attemptRepository: attempts,
        evidenceRepository: EvidenceSnapshotRepository(userIdOverride: 'u1'),
        readinessRepository: ReadinessSnapshotRepository(userIdOverride: 'u1'),
        planRepository: DailyStudyPlanRepository(userIdOverride: 'u1'),
      );

      expect(result.misconceptionSignals, isNotEmpty);
    });

    test('audit event is appended for update', () async {
      const attempts = LearnerAssessmentAttemptRepository(userIdOverride: 'u1');
      await attempts.append(m7eAttempt());
      const audit = LearningStateAuditRepository(userIdOverride: 'u1');

      await const LearningStateUpdateCoordinator().processOutcome(
        outcome: m7eOutcome(),
        markFuturePlansStale: false,
        attemptRepository: attempts,
        evidenceRepository: EvidenceSnapshotRepository(userIdOverride: 'u1'),
        readinessRepository: ReadinessSnapshotRepository(userIdOverride: 'u1'),
        planRepository: DailyStudyPlanRepository(userIdOverride: 'u1'),
        auditRepository: audit,
      );

      expect(await audit.loadAll(), hasLength(1));
    });

    test('future plan is made stale at controlled outcome checkpoint', () async {
      const attempts = LearnerAssessmentAttemptRepository(userIdOverride: 'u1');
      await attempts.append(m7eAttempt());
      final plans = DailyStudyPlanRepository(userIdOverride: 'u1');
      await plans.savePlan(
        m7ePlan(date: DateTime(2026, 9, 19)),
        syncRemote: false,
      );

      final result = await const LearningStateUpdateCoordinator().processOutcome(
        outcome: m7eOutcome(completedAt: DateTime(2026, 9, 18, 11)),
        now: DateTime(2026, 9, 18, 11),
        attemptRepository: attempts,
        evidenceRepository: EvidenceSnapshotRepository(userIdOverride: 'u1'),
        readinessRepository: ReadinessSnapshotRepository(userIdOverride: 'u1'),
        planRepository: plans,
      );

      expect(result.stalePlanVersionsCreated, 1);
    });

    test('staleness can be deferred instead of recalculating every event', () async {
      const attempts = LearnerAssessmentAttemptRepository(userIdOverride: 'u1');
      await attempts.append(m7eAttempt());
      final plans = DailyStudyPlanRepository(userIdOverride: 'u1');
      await plans.savePlan(
        m7ePlan(date: DateTime(2026, 9, 19)),
        syncRemote: false,
      );

      final result = await const LearningStateUpdateCoordinator().processOutcome(
        outcome: m7eOutcome(),
        markFuturePlansStale: false,
        attemptRepository: attempts,
        evidenceRepository: EvidenceSnapshotRepository(userIdOverride: 'u1'),
        readinessRepository: ReadinessSnapshotRepository(userIdOverride: 'u1'),
        planRepository: plans,
      );

      expect(result.stalePlanVersionsCreated, 0);
      expect(
        (await plans.loadLatestForDate(DateTime(2026, 9, 19)))?.status.name,
        'active',
      );
    });
  });

  group('M7E weekly review', () {
    const service = WeeklyReadinessReviewService();

    LearningStateUpdateEvent event({
      double before = 0.5,
      double after = 0.7,
    }) => LearningStateUpdateEvent(
      eventId: 'e1',
      outcomeId: 'o1',
      competencyId: 'd03_c02',
      occurredAt: DateTime(2026, 9, 18, 12),
      regenerationReason: PlanRegenerationReason.assessmentCompleted,
      previousReadinessState: 'developing',
      nextReadinessState: 'strong',
      previousKnowledge: before,
      nextKnowledge: after,
      previousApplication: before,
      nextApplication: after,
      previousRetention: before,
      nextRetention: after,
      stalePlanVersionsCreated: 0,
      misconceptionCodes: const [],
      reasonCodes: const ['IMPROVED'],
    );

    test('uses only latest immutable plan version for planned minutes', () {
      final review = service.build(
        weekStart: DateTime(2026, 9, 14),
        plans: [
          m7ePlan(date: DateTime(2026, 9, 18), version: 1),
          m7ePlan(
            date: DateTime(2026, 9, 18),
            version: 2,
            blocks: [m7eBlock(minutes: 30)],
          ),
        ],
        outcomes: const [],
        auditEvents: const [],
        readinessProfiles: const {},
      );

      expect(review.plannedMinutes, 30);
    });

    test('completed minutes exclude abandoned outcomes', () {
      final review = service.build(
        weekStart: DateTime(2026, 9, 14),
        plans: const [],
        outcomes: [
          m7eOutcome(minutesSpent: 20),
          m7eOutcome(
            outcomeId: 'o2',
            minutesSpent: 10,
            abandoned: true,
          ),
        ],
        auditEvents: const [],
        readinessProfiles: const {},
      );

      expect(review.completedMinutes, 20);
      expect(review.abandonedBlocks, 1);
    });

    test('dimension deltas come from audit history', () {
      final review = service.build(
        weekStart: DateTime(2026, 9, 14),
        plans: const [],
        outcomes: const [],
        auditEvents: [event()],
        readinessProfiles: const {},
      );

      expect(review.knowledgeDelta, closeTo(0.2, 0.0001));
      expect(review.applicationDelta, closeTo(0.2, 0.0001));
      expect(review.retentionDelta, closeTo(0.2, 0.0001));
    });

    test('improved competency is counted once', () {
      final review = service.build(
        weekStart: DateTime(2026, 9, 14),
        plans: const [],
        outcomes: const [],
        auditEvents: [event()],
        readinessProfiles: const {},
      );

      expect(review.competenciesImproved, 1);
    });

    test('critical and evidence gaps become next-week focus', () {
      final profile = m7dProfile(
        gaps: [
          m7dGap(
            severity: ReadinessGapSeverity.critical,
            type: ReadinessGapType.evidenceGap,
            reasonCode: 'EVIDENCE_CRITICAL',
            evidenceLimited: true,
          ),
        ],
        evidenceConfidence: EvidenceConfidence.low,
      );

      final review = service.build(
        weekStart: DateTime(2026, 9, 14),
        plans: const [],
        outcomes: const [],
        auditEvents: const [],
        readinessProfiles: {'d03_c02': profile},
      );

      expect(review.criticalGapsRemaining, 1);
      expect(review.newEvidenceGaps, 1);
      expect(review.focusCompetencyIds, contains('d03_c02'));
    });

    test('empty week does not fabricate readiness deltas', () {
      final review = service.build(
        weekStart: DateTime(2026, 9, 14),
        plans: const [],
        outcomes: const [],
        auditEvents: const [],
        readinessProfiles: const {},
      );

      expect(review.knowledgeDelta, isNull);
      expect(review.applicationDelta, isNull);
      expect(review.retentionDelta, isNull);
    });
  });
}
