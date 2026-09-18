import 'package:exam_platform/data/csp11_blueprint.dart';
import 'package:exam_platform/features/exam_readiness/models/competency_readiness_profile.dart';
import 'package:exam_platform/features/exam_readiness/models/evidence_confidence.dart';
import 'package:exam_platform/features/exam_readiness/models/learner_assessment_attempt.dart';
import 'package:exam_platform/features/exam_readiness/models/readiness_gap.dart';
import 'package:exam_platform/features/exam_readiness/models/study_plan_block.dart';
import 'package:exam_platform/features/exam_readiness/repositories/daily_study_plan_repository.dart';
import 'package:exam_platform/features/exam_readiness/repositories/evidence_snapshot_repository.dart';
import 'package:exam_platform/features/exam_readiness/repositories/learner_assessment_attempt_repository.dart';
import 'package:exam_platform/features/exam_readiness/repositories/learning_state_audit_repository.dart';
import 'package:exam_platform/features/exam_readiness/repositories/readiness_snapshot_repository.dart';
import 'package:exam_platform/features/exam_readiness/services/daily_study_plan_service.dart';
import 'package:exam_platform/features/exam_readiness/services/learning_state_update_coordinator.dart';
import 'package:exam_platform/features/exam_readiness/services/study_plan_outcome_service.dart';
import 'package:exam_platform/services/auth/learner_local_identity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../m7d/_support/m7d_fixture.dart';
import '_support/m7e_fixture.dart';

Map<String, CompetencyReadinessProfile> _stableProfiles({
  String? overrideId,
  CompetencyReadinessProfile? overrideProfile,
}) {
  final values = <String, CompetencyReadinessProfile>{};
  for (final domain in csp11Domains) {
    for (final competency in domain.competencies) {
      values[competency.id] = m7dProfile(
        competencyId: competency.id,
        evidenceConfidence: EvidenceConfidence.veryHigh,
        readinessState: ReadinessState.stable,
        knowledge: 0.92,
        application: 0.90,
        retention: 0.90,
        coverage: 0.95,
        difficulty: 0.88,
        calibration: 0.92,
        hardAccuracy: 0.88,
        ultraHardAccuracy: 0.82,
      );
    }
  }
  if (overrideId != null && overrideProfile != null) {
    values[overrideId] = overrideProfile;
  }
  return values;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LearnerLocalIdentity.activate('u1');
  });

  tearDown(LearnerLocalIdentity.clear);

  group('M7E study-plan outcome capture', () {
    const service = StudyPlanOutcomeService();

    test('uses only published attempts from the started block window', () {
      final block = m7eBlock(
        status: StudyPlanBlockStatus.started,
        createdAt: DateTime(2026, 9, 18, 8),
      ).copyWith(startedAt: DateTime(2026, 9, 18, 10));

      final outcome = service.build(
        plan: m7ePlan(blocks: [block]),
        block: block,
        completedAt: DateTime(2026, 9, 18, 10, 30),
        attempts: [
          m7eAttempt(
            attemptId: 'before',
            questionId: 1,
            answeredAt: DateTime(2026, 9, 18, 9, 59),
          ),
          m7eAttempt(
            attemptId: 'inside',
            questionId: 2,
            answeredAt: DateTime(2026, 9, 18, 10, 10),
          ),
          m7eAttempt(
            attemptId: 'other',
            questionId: 3,
            competencyId: 'd01_c01',
            answeredAt: DateTime(2026, 9, 18, 10, 15),
          ),
        ],
      );

      expect(outcome.questionsAttempted, 1);
      expect(outcome.questionsCorrect, 1);
      expect(outcome.minutesSpent, 30);
    });

    test('derives application, analysis and Ultra Hard accuracy', () {
      final block = m7eBlock(
        status: StudyPlanBlockStatus.started,
      ).copyWith(startedAt: DateTime(2026, 9, 18, 10));

      final outcome = service.build(
        plan: m7ePlan(blocks: [block]),
        block: block,
        completedAt: DateTime(2026, 9, 18, 10, 30),
        attempts: [
          m7eAttempt(
            attemptId: 'app1',
            questionId: 1,
            correct: true,
            answeredAt: DateTime(2026, 9, 18, 10, 5),
            cognitiveLevel: 'application',
          ),
          m7eAttempt(
            attemptId: 'app2',
            questionId: 2,
            correct: false,
            answeredAt: DateTime(2026, 9, 18, 10, 10),
            cognitiveLevel: 'application',
          ),
          m7eAttempt(
            attemptId: 'analysis',
            questionId: 3,
            correct: true,
            answeredAt: DateTime(2026, 9, 18, 10, 15),
            cognitiveLevel: 'analysis',
            difficultyLane: AttemptDifficultyLane.ultraHard,
          ),
        ],
      );

      expect(outcome.applicationAccuracy, 0.5);
      expect(outcome.analysisAccuracy, 1);
      expect(outcome.ultraHardAccuracy, 1);
    });

    test('does not fabricate question accuracy when no attempts occurred', () {
      final block = m7eBlock(
        status: StudyPlanBlockStatus.started,
      ).copyWith(startedAt: DateTime(2026, 9, 18, 10));

      final outcome = service.build(
        plan: m7ePlan(blocks: [block]),
        block: block,
        completedAt: DateTime(2026, 9, 18, 10, 20),
        attempts: const [],
      );

      expect(outcome.questionsAttempted, 0);
      expect(outcome.overallAccuracy, isNull);
      expect(outcome.applicationAccuracy, isNull);
      expect(outcome.ultraHardAccuracy, isNull);
    });

    test('requires a started block', () {
      final block = m7eBlock();

      expect(
        () => service.build(
          plan: m7ePlan(blocks: [block]),
          block: block,
          completedAt: DateTime(2026, 9, 18, 10, 20),
          attempts: const [],
        ),
        throwsStateError,
      );
    });
  });

  group('M7E completion lifecycle', () {
    const planner = DailyStudyPlanService();

    test('completion requires a started block', () {
      final plan = m7ePlan();

      expect(
        () => planner.completeBlock(
          plan,
          plan.blocks.first.blockId,
          at: DateTime(2026, 9, 18, 10),
        ),
        throwsStateError,
      );
    });

    test('started block becomes completed and remains locked', () {
      final plan = m7ePlan();
      final started = planner.startBlock(
        plan,
        plan.blocks.first.blockId,
        at: DateTime(2026, 9, 18, 9),
      );
      final completed = planner.completeBlock(
        started,
        started.blocks.first.blockId,
        at: DateTime(2026, 9, 18, 9, 30),
      );

      expect(completed.planVersion, started.planVersion + 1);
      expect(completed.blocks.first.status, StudyPlanBlockStatus.completed);
      expect(completed.blocks.first.completedAt, isNotNull);
      expect(completed.blocks.first.isLocked, isTrue);
      expect(
        completed.blocks.first.manualChanges.last.action,
        StudyPlanManualAction.complete,
      );
    });

    test('completed block is idempotent', () {
      final plan = m7ePlan();
      final started = planner.startBlock(
        plan,
        plan.blocks.first.blockId,
        at: DateTime(2026, 9, 18, 9),
      );
      final completed = planner.completeBlock(
        started,
        started.blocks.first.blockId,
        at: DateTime(2026, 9, 18, 9, 30),
      );

      expect(
        planner.completeBlock(
          completed,
          completed.blocks.first.blockId,
          at: DateTime(2026, 9, 18, 10),
        ),
        same(completed),
      );
    });
  });

  group('M7E confidence response', () {
    test('high-confidence misalignment can schedule calibration block', () {
      final profile = m7dProfile(
        competencyId: 'd01_c01',
        evidenceConfidence: EvidenceConfidence.high,
        calibration: 0.25,
        gaps: [
          m7dGap(
            competencyId: 'd01_c01',
            type: ReadinessGapType.confidenceGap,
            severity: ReadinessGapSeverity.high,
            reasonCode: 'CONFIDENCE_MISALIGNMENT',
          ),
        ],
      );

      final plan = const DailyStudyPlanService().generate(
        userId: 'u1',
        date: DateTime(2026, 9, 19),
        generatedAt: DateTime(2026, 9, 18),
        examDate: DateTime(2026, 10, 20),
        availableMinutes: 60,
        readinessProfiles: _stableProfiles(
          overrideId: 'd01_c01',
          overrideProfile: profile,
        ),
      );

      final calibrationBlock = plan.blocks.firstWhere(
        (block) =>
            block.competencyId == 'd01_c01' &&
            block.type == StudyPlanBlockType.confidenceCalibration,
      );
      expect(
        calibrationBlock.reasonCodes,
        contains('CONFIDENCE_MISALIGNMENT'),
      );
      expect(
        calibrationBlock.reasonCodes,
        contains('CONFIDENCE_CALIBRATION'),
      );
    });
  });

  group('M7E retry safety', () {
    test('processing the same outcome does not duplicate audit history', () async {
      const attempts = LearnerAssessmentAttemptRepository(userIdOverride: 'u1');
      await attempts.append(m7eAttempt());

      const audit = LearningStateAuditRepository(userIdOverride: 'u1');
      final coordinator = const LearningStateUpdateCoordinator();
      final outcome = m7eOutcome();

      for (var index = 0; index < 2; index++) {
        await coordinator.processOutcome(
          outcome: outcome,
          now: DateTime(2026, 9, 18, 12 + index),
          markFuturePlansStale: false,
          attemptRepository: attempts,
          evidenceRepository: EvidenceSnapshotRepository(userIdOverride: 'u1'),
          readinessRepository: ReadinessSnapshotRepository(
            userIdOverride: 'u1',
          ),
          planRepository: DailyStudyPlanRepository(userIdOverride: 'u1'),
          auditRepository: audit,
        );
      }

      expect(await audit.loadAll(), hasLength(1));
    });
  });
}
