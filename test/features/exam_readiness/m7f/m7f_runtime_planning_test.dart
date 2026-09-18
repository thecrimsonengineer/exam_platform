import 'package:exam_platform/data/csp11_blueprint.dart';
import 'package:exam_platform/features/exam_readiness/models/competency_readiness_profile.dart';
import 'package:exam_platform/features/exam_readiness/models/daily_study_plan.dart';
import 'package:exam_platform/features/exam_readiness/models/evidence_confidence.dart';
import 'package:exam_platform/features/exam_readiness/models/exam_preparation_phase.dart';
import 'package:exam_platform/features/exam_readiness/models/readiness_checkpoint.dart';
import 'package:exam_platform/features/exam_readiness/models/readiness_trajectory_point.dart';
import 'package:exam_platform/features/exam_readiness/models/recovery_protection_snapshot.dart';
import 'package:exam_platform/features/exam_readiness/models/study_plan_block.dart';
import 'package:exam_platform/features/exam_readiness/repositories/readiness_history_repository.dart';
import 'package:exam_platform/features/exam_readiness/services/coverage_projection_service.dart';
import 'package:exam_platform/features/exam_readiness/services/daily_study_plan_service.dart';
import 'package:exam_platform/features/exam_readiness/services/exam_simulation_suppression_policy.dart';
import 'package:exam_platform/features/exam_readiness/services/phase_aware_daily_plan_service.dart';
import 'package:exam_platform/features/exam_readiness/services/readiness_checkpoint_service.dart';
import 'package:exam_platform/features/exam_readiness/services/readiness_trajectory_service.dart';
import 'package:exam_platform/features/exam_readiness/services/recovery_protection_service.dart';
import 'package:exam_platform/services/auth/learner_local_identity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../m7d/_support/m7d_fixture.dart';
import '../m7e/_support/m7e_fixture.dart';

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

DailyStudyPlan _phasePlan({
  required int daysToExam,
  int minutes = 120,
  Set<String> ultra = const <String>{},
  Map<String, CompetencyReadinessProfile>? profiles,
  DailyStudyPlan? existing,
}) {
  final date = DateTime(2026, 9, 18);
  return const PhaseAwareDailyPlanService().generate(
    userId: 'u1',
    date: date,
    generatedAt: DateTime(2026, 9, 18, 8),
    examDate: date.add(Duration(days: daysToExam)),
    availableMinutes: minutes,
    readinessProfiles: profiles ?? _stableProfiles(),
    ultraHardAvailableCompetencyIds: ultra,
    existingPlan: existing,
    generationReason: existing == null
        ? DailyStudyPlanGenerationReason.initial
        : DailyStudyPlanGenerationReason.manualRequest,
  );
}

ReadinessTrajectoryPoint _point(DateTime date, double coverage) {
  return ReadinessTrajectoryPoint(
    date: date,
    knowledge: 0.7,
    application: 0.7,
    retention: 0.7,
    coverage: coverage,
    difficulty: 0.7,
    evidenceConfidence: EvidenceConfidence.high,
    algorithmVersion: ReadinessTrajectoryService.currentAlgorithmVersion,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LearnerLocalIdentity.activate('u1');
  });

  tearDown(LearnerLocalIdentity.clear);

  group('M7F phase-aware daily planning', () {
    test('phase-aware plan is explicitly versioned as M7F', () {
      expect(
        _phasePlan(daysToExam: 90).plannerAlgorithmVersion,
        PhaseAwareDailyPlanService.currentAlgorithmVersion,
      );
    });

    test('foundation plan carries foundation reason code', () {
      final plan = _phasePlan(daysToExam: 90);
      expect(
        plan.blocks.every(
          (block) => block.reasonCodes.contains('EXAM_PHASE_FOUNDATION'),
        ),
        isTrue,
      );
    });

    test('integration plan carries integration reason code', () {
      final plan = _phasePlan(daysToExam: 45);
      expect(
        plan.blocks.every(
          (block) => block.reasonCodes.contains('EXAM_PHASE_INTEGRATION'),
        ),
        isTrue,
      );
    });

    test('readiness plan carries readiness reason code', () {
      final plan = _phasePlan(daysToExam: 20);
      expect(
        plan.blocks.every(
          (block) => block.reasonCodes.contains('EXAM_PHASE_READINESS'),
        ),
        isTrue,
      );
    });

    test('consolidation plan carries consolidation reason code', () {
      final plan = _phasePlan(daysToExam: 7);
      expect(
        plan.blocks.every(
          (block) => block.reasonCodes.contains('EXAM_PHASE_CONSOLIDATION'),
        ),
        isTrue,
      );
    });

    test('phase allocation configuration is traceable on blocks', () {
      final plan = _phasePlan(daysToExam: 90);
      expect(
        plan.blocks.every(
          (block) => block.reasonCodes.any(
            (code) => code.startsWith('PHASE_ALLOCATION_'),
          ),
        ),
        isTrue,
      );
    });

    test('phase-aware planning never exceeds declared daily capacity', () {
      for (final days in [90, 45, 20, 7]) {
        final plan = _phasePlan(daysToExam: days, minutes: 60);
        expect(plan.allocatedMinutes, lessThanOrEqualTo(60));
      }
    });

    test('stable readiness phase reduces unnecessary forward learning', () {
      final plan = _phasePlan(daysToExam: 20);
      expect(
        plan.blocks.where(
          (block) =>
              block.type == StudyPlanBlockType.learn ||
              block.type == StudyPlanBlockType.continueLearning,
        ),
        isEmpty,
      );
    });

    test('stable consolidation phase emphasizes review over novelty', () {
      final plan = _phasePlan(daysToExam: 7);
      expect(
        plan.blocks.where(
          (block) =>
              block.type == StudyPlanBlockType.learn ||
              block.type == StudyPlanBlockType.continueLearning,
        ),
        isEmpty,
      );
      expect(
        plan.blocks.any(
          (block) =>
              block.type == StudyPlanBlockType.spacedReview ||
              block.type == StudyPlanBlockType.mixedRetrieval,
        ),
        isTrue,
      );
    });

    test('Ultra Hard cannot appear without published availability', () {
      final weak = m7dProfile(
        competencyId: 'd01_c01',
        evidenceConfidence: EvidenceConfidence.high,
        application: 0.55,
        ultraHardAccuracy: null,
      );
      final plan = _phasePlan(
        daysToExam: 20,
        profiles: _stableProfiles(overrideId: 'd01_c01', overrideProfile: weak),
      );
      expect(
        plan.blocks.any(
          (block) => block.type == StudyPlanBlockType.ultraHardPractice,
        ),
        isFalse,
      );
    });

    test(
      'readiness phase may use Ultra Hard only when justified and available',
      () {
        final weak = m7dProfile(
          competencyId: 'd01_c01',
          evidenceConfidence: EvidenceConfidence.high,
          application: 0.55,
          ultraHardAccuracy: null,
        );
        final plan = _phasePlan(
          daysToExam: 20,
          minutes: 120,
          ultra: const {'d01_c01'},
          profiles: _stableProfiles(
            overrideId: 'd01_c01',
            overrideProfile: weak,
          ),
        );
        expect(
          plan.blocks.any(
            (block) =>
                block.competencyId == 'd01_c01' &&
                block.type == StudyPlanBlockType.ultraHardPractice,
          ),
          isTrue,
        );
      },
    );

    test('started block remains byte-equivalent across phase regeneration', () {
      const base = DailyStudyPlanService();
      final date = DateTime(2026, 9, 18);
      final initial = base.generate(
        userId: 'u1',
        date: date,
        generatedAt: DateTime(2026, 9, 18, 8),
        examDate: DateTime(2026, 10, 8),
        availableMinutes: 120,
        readinessProfiles: _stableProfiles(),
      );
      final started = base.startBlock(
        initial,
        initial.blocks.first.blockId,
        at: DateTime(2026, 9, 18, 9),
      );
      final regenerated = const PhaseAwareDailyPlanService().generate(
        userId: 'u1',
        date: date,
        generatedAt: DateTime(2026, 9, 18, 10),
        examDate: DateTime(2026, 10, 8),
        availableMinutes: 120,
        readinessProfiles: _stableProfiles(),
        existingPlan: started,
        generationReason: DailyStudyPlanGenerationReason.manualRequest,
      );

      final retained = regenerated.blocks.firstWhere(
        (block) => block.blockId == started.blocks.first.blockId,
      );
      expect(retained.toJson(), started.blocks.first.toJson());
    });

    test('phase metadata is included in input snapshot lineage', () {
      final plan = _phasePlan(daysToExam: 20);
      expect(plan.inputSnapshotVersion, contains('phase:readiness'));
      expect(plan.inputSnapshotVersion, contains('phaseCfg:m7f-phase-v1'));
    });
  });

  group('M7F readiness checkpoints', () {
    const service = ReadinessCheckpointService();
    final exam = DateTime(2026, 12, 17);

    test('100 days remaining targets 90 day checkpoint', () {
      final checkpoint = service.nextCheckpoint(
        currentDate: exam.subtract(const Duration(days: 100)),
        examDate: exam,
        ultraHardAvailable: true,
      );
      expect(checkpoint?.milestoneDaysRemaining, 90);
      expect(checkpoint?.status, ReadinessCheckpointStatus.upcoming);
    });

    test('90 day milestone is due', () {
      final checkpoint = service.nextCheckpoint(
        currentDate: exam.subtract(const Duration(days: 90)),
        examDate: exam,
        ultraHardAvailable: true,
      );
      expect(checkpoint?.status, ReadinessCheckpointStatus.due);
    });

    test('61 days remaining targets 60 day checkpoint', () {
      final checkpoint = service.nextCheckpoint(
        currentDate: exam.subtract(const Duration(days: 61)),
        examDate: exam,
        ultraHardAvailable: true,
      );
      expect(checkpoint?.milestoneDaysRemaining, 60);
    });

    test('31 days remaining targets 30 day checkpoint', () {
      final checkpoint = service.nextCheckpoint(
        currentDate: exam.subtract(const Duration(days: 31)),
        examDate: exam,
        ultraHardAvailable: true,
      );
      expect(checkpoint?.milestoneDaysRemaining, 30);
    });

    test('15 days remaining targets 14 day checkpoint', () {
      final checkpoint = service.nextCheckpoint(
        currentDate: exam.subtract(const Duration(days: 15)),
        examDate: exam,
        ultraHardAvailable: true,
      );
      expect(checkpoint?.milestoneDaysRemaining, 14);
    });

    test('8 days remaining targets 7 day checkpoint', () {
      final checkpoint = service.nextCheckpoint(
        currentDate: exam.subtract(const Duration(days: 8)),
        examDate: exam,
        ultraHardAvailable: true,
      );
      expect(checkpoint?.milestoneDaysRemaining, 7);
    });

    test('inside final 7 days has no future configured checkpoint', () {
      expect(
        service.nextCheckpoint(
          currentDate: exam.subtract(const Duration(days: 6)),
          examDate: exam,
          ultraHardAvailable: true,
        ),
        isNull,
      );
    });

    test('readiness checkpoint includes Ultra Hard only when available', () {
      final withUltra = service.nextCheckpoint(
        currentDate: exam.subtract(const Duration(days: 30)),
        examDate: exam,
        ultraHardAvailable: true,
      );
      final withoutUltra = service.nextCheckpoint(
        currentDate: exam.subtract(const Duration(days: 30)),
        examDate: exam,
        ultraHardAvailable: false,
      );
      expect(withUltra?.includeUltraHard, isTrue);
      expect(withoutUltra?.includeUltraHard, isFalse);
    });

    test('foundation checkpoint does not force Ultra Hard', () {
      final checkpoint = service.nextCheckpoint(
        currentDate: exam.subtract(const Duration(days: 90)),
        examDate: exam,
        ultraHardAvailable: true,
      );
      expect(checkpoint?.phase, ExamPreparationPhase.foundation);
      expect(checkpoint?.includeUltraHard, isFalse);
    });

    test('checkpoint carries deterministic reason code', () {
      final checkpoint = service.nextCheckpoint(
        currentDate: exam.subtract(const Duration(days: 30)),
        examDate: exam,
        ultraHardAvailable: true,
      );
      expect(checkpoint?.reasonCodes, contains('READINESS_CHECKPOINT_30D'));
    });
  });

  group('M7F recovery protection', () {
    const service = RecoveryProtectionService();

    DailyStudyPlan missed(int day) => m7ePlan(
      planId: 'p$day',
      date: DateTime(2026, 9, day),
      blocks: [m7eBlock(blockId: 'b$day')],
    );

    test('no missed history requires no intervention', () {
      final result = service.evaluate(
        history: const [],
        today: DateTime(2026, 9, 18),
        declaredMinutes: 60,
      );
      expect(result.state, RecoveryProtectionState.none);
      expect(result.suggestedMinutes, 60);
    });

    test('one missed day does not trigger reduced intensity', () {
      final result = service.evaluate(
        history: [missed(17)],
        today: DateTime(2026, 9, 18),
        declaredMinutes: 60,
      );
      expect(result.state, RecoveryProtectionState.none);
    });

    test('two missed study days offer reduced intensity', () {
      final result = service.evaluate(
        history: [missed(16), missed(17)],
        today: DateTime(2026, 9, 18),
        declaredMinutes: 60,
      );
      expect(result.state, RecoveryProtectionState.reducedIntensityDay);
      expect(result.suggestedMinutes, 45);
    });

    test('three missed study days offer recovery day', () {
      final result = service.evaluate(
        history: [missed(15), missed(16), missed(17)],
        today: DateTime(2026, 9, 18),
        declaredMinutes: 60,
      );
      expect(result.state, RecoveryProtectionState.recoveryDay);
      expect(result.suggestedMinutes, 30);
    });

    test('recovery recommendation never increases declared minutes', () {
      final result = service.evaluate(
        history: [missed(15), missed(16), missed(17)],
        today: DateTime(2026, 9, 18),
        declaredMinutes: 40,
      );
      expect(result.suggestedMinutes, lessThanOrEqualTo(40));
    });

    test('completed prior day breaks missed-day streak', () {
      final completed = m7ePlan(
        planId: 'complete',
        date: DateTime(2026, 9, 17),
        blocks: [
          m7eBlock(blockId: 'done', status: StudyPlanBlockStatus.completed),
        ],
      );
      final result = service.evaluate(
        history: [missed(15), missed(16), completed],
        today: DateTime(2026, 9, 18),
        declaredMinutes: 60,
      );
      expect(result.state, RecoveryProtectionState.none);
      expect(result.consecutiveMissedStudyDays, 0);
    });

    test('recovery reasons explicitly prohibit backlog dumping', () {
      final result = service.evaluate(
        history: [missed(15), missed(16), missed(17)],
        today: DateTime(2026, 9, 18),
        declaredMinutes: 60,
      );
      expect(result.reasonCodes, contains('NO_BACKLOG_DUMPING'));
    });
  });

  group('M7F local trajectory history', () {
    test('storage key is UID scoped', () {
      expect(
        ReadinessHistoryRepository.storageKeyForUser('u1'),
        'csp11.student.u1.exam_readiness.readiness_history.v1',
      );
    });

    test('saveDaily persists one point', () async {
      const repo = ReadinessHistoryRepository(userIdOverride: 'u1');
      await repo.saveDaily(_point(DateTime(2026, 9, 18), 0.6));
      expect(await repo.loadAll(), hasLength(1));
    });

    test('same day replaces point rather than duplicating history', () async {
      const repo = ReadinessHistoryRepository(userIdOverride: 'u1');
      await repo.saveDaily(_point(DateTime(2026, 9, 18, 8), 0.6));
      await repo.saveDaily(_point(DateTime(2026, 9, 18, 20), 0.8));
      final values = await repo.loadAll();
      expect(values, hasLength(1));
      expect(values.single.coverage, 0.8);
    });

    test('history remains sorted oldest to newest', () async {
      const repo = ReadinessHistoryRepository(userIdOverride: 'u1');
      await repo.saveDaily(_point(DateTime(2026, 9, 18), 0.8));
      await repo.saveDaily(_point(DateTime(2026, 9, 4), 0.6));
      final values = await repo.loadAll();
      expect(values.first.date.day, 4);
      expect(values.last.date.day, 18);
    });

    test('clear removes local trajectory history', () async {
      const repo = ReadinessHistoryRepository(userIdOverride: 'u1');
      await repo.saveDaily(_point(DateTime(2026, 9, 18), 0.8));
      await repo.clear();
      expect(await repo.loadAll(), isEmpty);
    });
  });

  group('M7F safe coverage projection', () {
    const trajectoryService = ReadinessTrajectoryService();
    const projectionService = CoverageProjectionService();

    test('short trajectory window withholds projection', () {
      final trajectory = trajectoryService.summarize([
        _point(DateTime(2026, 9, 10), 0.5),
        _point(DateTime(2026, 9, 18), 0.6),
      ]);
      final projection = projectionService.project(
        trajectory: trajectory,
        daysToExam: 30,
      );
      expect(projection.isAvailable, isFalse);
    });

    test('meaningful trajectory window can project coverage', () {
      final trajectory = trajectoryService.summarize([
        _point(DateTime(2026, 9, 1), 0.50),
        _point(DateTime(2026, 9, 18), 0.65),
      ]);
      final projection = projectionService.project(
        trajectory: trajectory,
        daysToExam: 20,
      );
      expect(projection.isAvailable, isTrue);
      expect(projection.projectedCoverage, greaterThan(0.65));
    });

    test('coverage projection is clamped at one hundred percent', () {
      final trajectory = trajectoryService.summarize([
        _point(DateTime(2026, 9, 1), 0.50),
        _point(DateTime(2026, 9, 18), 0.95),
      ]);
      final projection = projectionService.project(
        trajectory: trajectory,
        daysToExam: 100,
      );
      expect(projection.projectedCoverage, 1);
    });

    test('coverage projection identifies itself as a process variable', () {
      final trajectory = trajectoryService.summarize([
        _point(DateTime(2026, 9, 1), 0.50),
        _point(DateTime(2026, 9, 18), 0.65),
      ]);
      final projection = projectionService.project(
        trajectory: trajectory,
        daysToExam: 20,
      );
      expect(
        projection.reasonCodes,
        contains('PROCESS_VARIABLE_NOT_EXAM_OUTCOME'),
      );
    });
  });

  group('M7F timed simulation suppression', () {
    const policy = ExamSimulationSuppressionPolicy();

    test('timed simulation suppresses Learning Twin', () {
      expect(
        policy.suppressLearningTwin(isTimedSimulationActive: true),
        isTrue,
      );
    });

    test('timed simulation suppresses hints', () {
      expect(policy.suppressHints(isTimedSimulationActive: true), isTrue);
    });

    test('timed simulation suppresses readiness prompts', () {
      expect(
        policy.suppressReadinessPrompts(isTimedSimulationActive: true),
        isTrue,
      );
    });

    test('timed simulation blocks evidence update before submission', () {
      expect(
        policy.allowPostSubmissionEvidenceUpdate(
          isTimedSimulationActive: true,
          submitted: false,
        ),
        isFalse,
      );
    });

    test('timed simulation allows evidence update after submission', () {
      expect(
        policy.allowPostSubmissionEvidenceUpdate(
          isTimedSimulationActive: true,
          submitted: true,
        ),
        isTrue,
      );
    });

    test('ordinary practice does not activate timed suppression', () {
      expect(
        policy.suppressLearningTwin(isTimedSimulationActive: false),
        isFalse,
      );
      expect(policy.suppressHints(isTimedSimulationActive: false), isFalse);
      expect(
        policy.suppressReadinessPrompts(isTimedSimulationActive: false),
        isFalse,
      );
    });
  });
}
