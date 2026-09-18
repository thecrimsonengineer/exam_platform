import 'package:exam_platform/features/exam_readiness/models/daily_study_plan.dart';
import 'package:exam_platform/features/exam_readiness/models/learner_assessment_attempt.dart';
import 'package:exam_platform/features/exam_readiness/models/misconception_signal.dart';
import 'package:exam_platform/features/exam_readiness/models/plan_regeneration_reason.dart';
import 'package:exam_platform/features/exam_readiness/repositories/daily_study_plan_repository.dart';
import 'package:exam_platform/features/exam_readiness/services/misconception_signal_service.dart';
import 'package:exam_platform/features/exam_readiness/services/plan_staleness_service.dart';
import 'package:exam_platform/services/auth/learner_local_identity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '_support/m7e_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LearnerLocalIdentity.activate('u1');
  });

  tearDown(LearnerLocalIdentity.clear);

  group('M7E misconception signals', () {
    const service = MisconceptionSignalService();

    test('two high-confidence incorrect answers create calibration signal', () {
      final attempts = [
        m7eAttempt(
          attemptId: 'a1',
          questionId: 1,
          correct: false,
          confidence: LearnerConfidenceLevel.high,
        ),
        m7eAttempt(
          attemptId: 'a2',
          questionId: 2,
          correct: false,
          confidence: LearnerConfidenceLevel.high,
        ),
        m7eAttempt(attemptId: 'a3', questionId: 3, correct: true),
      ];

      final signals = service.detect(
        competencyId: 'd03_c02',
        attempts: attempts,
        now: DateTime(2026, 9, 18),
      );

      expect(
        signals.any(
          (item) =>
              item.type == MisconceptionSignalType.highConfidenceIncorrect,
        ),
        isTrue,
      );
    });

    test('repeated incorrect pattern creates misconception signal', () {
      final attempts = [
        for (var i = 0; i < 4; i++)
          m7eAttempt(
            attemptId: 'a$i',
            questionId: i + 1,
            correct: i == 3,
          ),
      ];

      final signals = service.detect(
        competencyId: 'd03_c02',
        attempts: attempts,
        now: DateTime(2026, 9, 18),
      );

      expect(
        signals.any(
          (item) => item.type == MisconceptionSignalType.repeatedIncorrect,
        ),
        isTrue,
      );
    });

    test('weak application evidence creates application reasoning signal', () {
      final attempts = [
        for (var i = 0; i < 4; i++)
          m7eAttempt(
            attemptId: 'a$i',
            questionId: i + 1,
            correct: i == 3,
            cognitiveLevel: 'application',
          ),
      ];

      final signals = service.detect(
        competencyId: 'd03_c02',
        attempts: attempts,
        now: DateTime(2026, 9, 18),
      );

      expect(
        signals.any(
          (item) => item.type == MisconceptionSignalType.applicationReasoning,
        ),
        isTrue,
      );
    });

    test('poor Ultra Hard evidence creates targeted difficulty signal', () {
      final attempts = [
        for (var i = 0; i < 4; i++)
          m7eAttempt(
            attemptId: 'u$i',
            questionId: i + 1,
            correct: i == 3,
            difficultyLane: AttemptDifficultyLane.ultraHard,
          ),
      ];

      final signals = service.detect(
        competencyId: 'd03_c02',
        attempts: attempts,
        now: DateTime(2026, 9, 18),
      );

      expect(
        signals.any(
          (item) => item.type == MisconceptionSignalType.ultraHardDifficulty,
        ),
        isTrue,
      );
    });

    test('strong recent evidence creates no misconception signal', () {
      final attempts = [
        for (var i = 0; i < 5; i++)
          m7eAttempt(
            attemptId: 's$i',
            questionId: i + 1,
            correct: true,
            confidence: LearnerConfidenceLevel.high,
          ),
      ];

      expect(
        service.detect(
          competencyId: 'd03_c02',
          attempts: attempts,
          now: DateTime(2026, 9, 18),
        ),
        isEmpty,
      );
    });

    test('signals are isolated to affected competency', () {
      final attempts = [
        m7eAttempt(
          attemptId: 'x1',
          questionId: 1,
          competencyId: 'd01_c01',
          correct: false,
          confidence: LearnerConfidenceLevel.high,
        ),
        m7eAttempt(
          attemptId: 'x2',
          questionId: 2,
          competencyId: 'd01_c01',
          correct: false,
          confidence: LearnerConfidenceLevel.high,
        ),
      ];

      expect(
        service.detect(
          competencyId: 'd03_c02',
          attempts: attempts,
          now: DateTime(2026, 9, 18),
        ),
        isEmpty,
      );
    });
  });

  group('M7E future plan staleness', () {
    const service = PlanStalenessService();

    test('future active plan receives new stale version', () async {
      final repo = DailyStudyPlanRepository(userIdOverride: 'u1');
      await repo.savePlan(
        m7ePlan(date: DateTime(2026, 9, 19)),
        syncRemote: false,
      );

      expect(
        await service.markFuturePlansStale(
          afterDate: DateTime(2026, 9, 18),
          reason: PlanRegenerationReason.assessmentCompleted,
          at: DateTime(2026, 9, 18, 12),
          repository: repo,
        ),
        1,
      );

      final latest = await repo.loadLatestForDate(DateTime(2026, 9, 19));
      expect(latest?.status, DailyStudyPlanStatus.stale);
      expect(latest?.planVersion, 2);
    });

    test('current day plan is not made stale by outcome', () async {
      final repo = DailyStudyPlanRepository(userIdOverride: 'u1');
      await repo.savePlan(
        m7ePlan(date: DateTime(2026, 9, 18)),
        syncRemote: false,
      );

      expect(
        await service.markFuturePlansStale(
          afterDate: DateTime(2026, 9, 18),
          reason: PlanRegenerationReason.assessmentCompleted,
          at: DateTime(2026, 9, 18, 12),
          repository: repo,
        ),
        0,
      );
    });

    test('historical version remains preserved after staleness', () async {
      final repo = DailyStudyPlanRepository(userIdOverride: 'u1');
      await repo.savePlan(
        m7ePlan(date: DateTime(2026, 9, 19)),
        syncRemote: false,
      );

      await service.markFuturePlansStale(
        afterDate: DateTime(2026, 9, 18),
        reason: PlanRegenerationReason.majorPerformanceShift,
        at: DateTime(2026, 9, 18, 12),
        repository: repo,
      );

      final history = await repo.loadHistory();
      expect(history.where((item) => item.date.day == 19), hasLength(2));
      expect(history.any((item) => item.status == DailyStudyPlanStatus.active), isTrue);
      expect(history.any((item) => item.status == DailyStudyPlanStatus.stale), isTrue);
    });

    test('stale version points to previous plan version', () async {
      final repo = DailyStudyPlanRepository(userIdOverride: 'u1');
      await repo.savePlan(
        m7ePlan(date: DateTime(2026, 9, 19)),
        syncRemote: false,
      );

      await service.markFuturePlansStale(
        afterDate: DateTime(2026, 9, 18),
        reason: PlanRegenerationReason.criticalGapDetected,
        at: DateTime(2026, 9, 18, 12),
        repository: repo,
      );

      final latest = await repo.loadLatestForDate(DateTime(2026, 9, 19));
      expect(latest?.previousPlanId, 'plan-1:v1');
      expect(
        latest?.generationReason,
        DailyStudyPlanGenerationReason.criticalGapDetected,
      );
    });

    test('already stale latest plan is not duplicated', () async {
      final repo = DailyStudyPlanRepository(userIdOverride: 'u1');
      await repo.savePlan(
        m7ePlan(
          date: DateTime(2026, 9, 19),
          status: DailyStudyPlanStatus.stale,
        ),
        syncRemote: false,
      );

      expect(
        await service.markFuturePlansStale(
          afterDate: DateTime(2026, 9, 18),
          reason: PlanRegenerationReason.assessmentCompleted,
          at: DateTime(2026, 9, 18, 12),
          repository: repo,
        ),
        0,
      );
    });
  });
}
