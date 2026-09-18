import 'package:exam_platform/features/exam_readiness/models/daily_study_plan.dart';
import 'package:exam_platform/features/exam_readiness/models/competency_readiness_profile.dart';
import 'package:exam_platform/features/exam_readiness/models/evidence_confidence.dart';
import 'package:exam_platform/features/exam_readiness/models/learner_assessment_attempt.dart';
import 'package:exam_platform/features/exam_readiness/models/plan_regeneration_reason.dart';
import 'package:exam_platform/features/exam_readiness/models/readiness_gap.dart';
import 'package:exam_platform/features/exam_readiness/models/study_plan_block.dart';
import 'package:exam_platform/features/exam_readiness/repositories/daily_study_plan_repository.dart';
import 'package:exam_platform/features/exam_readiness/repositories/evidence_snapshot_repository.dart';
import 'package:exam_platform/features/exam_readiness/repositories/exam_study_plan_repository.dart';
import 'package:exam_platform/features/exam_readiness/repositories/learner_assessment_attempt_repository.dart';
import 'package:exam_platform/features/exam_readiness/repositories/readiness_snapshot_repository.dart';
import 'package:exam_platform/features/exam_readiness/services/daily_study_plan_service.dart';
import 'package:exam_platform/features/exam_readiness/services/learning_state_update_coordinator.dart';
import 'package:exam_platform/features/exam_readiness/services/plan_replanning_service.dart';
import 'package:exam_platform/features/exam_readiness/models/exam_study_plan.dart';
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

  test('Sequence A poor new evidence changes tomorrow toward repair', () async {
    final planner = const DailyStudyPlanService();
    final before = planner.generate(
      userId: 'u1',
      date: DateTime(2026, 9, 19),
      generatedAt: DateTime(2026, 9, 18),
      examDate: DateTime(2026, 10, 20),
      availableMinutes: 60,
      readinessProfiles: {
        'd03_c02': m7dProfile(
          readinessState: ReadinessState.strong,
          knowledge: 0.85,
          application: 0.85,
          retention: 0.8,
        ),
      },
    );

    final after = planner.generate(
      userId: 'u1',
      date: DateTime(2026, 9, 19),
      generatedAt: DateTime(2026, 9, 18, 12),
      examDate: DateTime(2026, 10, 20),
      availableMinutes: 60,
      readinessProfiles: {
        'd03_c02': m7dProfile(
          readinessState: ReadinessState.developing,
          knowledge: 0.82,
          application: 0.3,
          retention: 0.75,
          gaps: [
            m7dGap(
              type: ReadinessGapType.applicationGap,
              severity: ReadinessGapSeverity.high,
            ),
          ],
        ),
      },
      existingPlan: before,
      generationReason:
          PlanRegenerationReason.majorPerformanceShift.dailyPlanReason,
    );

    expect(after.planVersion, 2);
    expect(after.generationReason, DailyStudyPlanGenerationReason.majorPerformanceShift);
    expect(
      after.blocks.any((block) => block.type == StudyPlanBlockType.repair),
      isTrue,
    );
  });

  test('Sequence B excellent evidence reduces need for repair repetition', () {
    const planner = DailyStudyPlanService();
    final weak = planner.generate(
      userId: 'u1',
      date: DateTime(2026, 9, 19),
      generatedAt: DateTime(2026, 9, 18),
      examDate: DateTime(2026, 10, 20),
      availableMinutes: 60,
      readinessProfiles: {
        'd03_c02': m7dProfile(
          application: 0.3,
          gaps: [m7dGap()],
        ),
      },
    );
    final strong = planner.generate(
      userId: 'u1',
      date: DateTime(2026, 9, 19),
      generatedAt: DateTime(2026, 9, 18, 12),
      examDate: DateTime(2026, 10, 20),
      availableMinutes: 60,
      readinessProfiles: {
        'd03_c02': m7dProfile(
          readinessState: ReadinessState.strong,
          knowledge: 0.9,
          application: 0.9,
          retention: 0.85,
          coverage: 0.9,
          difficulty: 0.85,
        ),
      },
    );

    expect(weak.blocks.any((b) => b.type == StudyPlanBlockType.repair), isTrue);
    expect(strong.blocks.any((b) => b.type == StudyPlanBlockType.repair), isFalse);
  });

  test('Sequence C missed study day does not exceed next-day capacity', () {
    const planner = DailyStudyPlanService();
    final replanned = planner.generate(
      userId: 'u1',
      date: DateTime(2026, 9, 20),
      generatedAt: DateTime(2026, 9, 19, 20),
      examDate: DateTime(2026, 10, 20),
      availableMinutes: 30,
      readinessProfiles: {
        'd03_c02': m7dProfile(application: 0.35, gaps: [m7dGap()]),
        'd01_c01': m7dProfile(competencyId: 'd01_c01'),
      },
      generationReason: PlanRegenerationReason.missedStudyDay.dailyPlanReason,
    );

    expect(replanned.generationReason, DailyStudyPlanGenerationReason.missedStudyDay);
    expect(replanned.allocatedMinutes, lessThanOrEqualTo(30));
  });

  test('Sequence D poor Ultra Hard creates targeted recheck opportunity', () {
    const planner = DailyStudyPlanService();
    final plan = planner.generate(
      userId: 'u1',
      date: DateTime(2026, 9, 19),
      generatedAt: DateTime(2026, 9, 18),
      examDate: DateTime(2026, 10, 1),
      availableMinutes: 90,
      readinessProfiles: {
        'd03_c02': m7dProfile(
          difficulty: 0.35,
          ultraHardAccuracy: 0.2,
          gaps: [
            m7dGap(
              type: ReadinessGapType.difficultyGap,
              severity: ReadinessGapSeverity.high,
              reasonCode: 'ULTRA_HARD_GAP',
            ),
          ],
        ),
      },
      ultraHardAvailableCompetencyIds: {'d03_c02'},
      generationReason:
          PlanRegenerationReason.majorPerformanceShift.dailyPlanReason,
    );

    expect(
      plan.blocks.any((block) => block.type == StudyPlanBlockType.ultraHardPractice),
      isTrue,
    );
  });

  test('Sequence E high-confidence incorrect triggers calibration repair signal', () async {
    const attempts = LearnerAssessmentAttemptRepository(userIdOverride: 'u1');
    for (var i = 0; i < 3; i++) {
      await attempts.append(
        m7eAttempt(
          attemptId: 'hc$i',
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

    expect(
      result.misconceptionSignals
          .expand((signal) => signal.reasonCodes),
      contains('CALIBRATION_REPAIR_NEEDED'),
    );
  });

  test('same baseline plus new evidence can produce justified next-day plan', () async {
    final examRepo = ExamStudyPlanRepository(userIdOverride: 'u1');
    await examRepo.savePlan(
      ExamStudyPlan.create(
        id: 'exam-1',
        userId: 'u1',
        examDate: DateTime(2026, 10, 20),
        studyDaysOfWeek: {
          DateTime.friday,
          DateTime.saturday,
          DateTime.sunday,
        },
        defaultMinutesPerStudyDay: 60,
        now: DateTime(2026, 9, 18),
      ),
      syncRemote: false,
    );

    final readinessRepo = ReadinessSnapshotRepository(userIdOverride: 'u1');
    await readinessRepo.save(
      m7dProfile(
        readinessState: ReadinessState.strong,
        application: 0.85,
        knowledge: 0.85,
        retention: 0.8,
      ),
      syncRemote: false,
    );

    final dailyRepo = DailyStudyPlanRepository(userIdOverride: 'u1');
    final replanner = PlanReplanningService();
    final before = await replanner.regenerateForDate(
      date: DateTime(2026, 9, 19),
      reason: PlanRegenerationReason.dailyRollover,
      now: DateTime(2026, 9, 18, 8),
      ultraHardAvailableCompetencyIds: const <String>{},
      examPlanRepository: examRepo,
      readinessRepository: readinessRepo,
      dailyPlanRepository: dailyRepo,
    );

    await readinessRepo.save(
      m7dProfile(
        readinessState: ReadinessState.developing,
        knowledge: 0.8,
        application: 0.3,
        retention: 0.75,
        gaps: [m7dGap()],
        generatedAt: DateTime(2026, 9, 18, 12),
      ),
      syncRemote: false,
    );

    final after = await replanner.regenerateForDate(
      date: DateTime(2026, 9, 19),
      reason: PlanRegenerationReason.majorPerformanceShift,
      now: DateTime(2026, 9, 18, 12),
      ultraHardAvailableCompetencyIds: const <String>{},
      examPlanRepository: examRepo,
      readinessRepository: readinessRepo,
      dailyPlanRepository: dailyRepo,
    );

    expect(before, isNotNull);
    expect(after, isNotNull);
    expect(after!.planVersion, greaterThan(before!.planVersion));
    expect(after.previousPlanId, '${before.planId}:v${before.planVersion}');
    expect(
      after.blocks.map((block) => block.type).toList(),
      isNot(equals(before.blocks.map((block) => block.type).toList())),
    );
    expect(
      after.blocks.any((block) => block.reasonCodes.isNotEmpty),
      isTrue,
    );
  });
}
