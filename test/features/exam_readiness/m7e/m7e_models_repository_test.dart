import 'package:exam_platform/features/exam_readiness/models/learning_state_update_event.dart';
import 'package:exam_platform/features/exam_readiness/models/misconception_signal.dart';
import 'package:exam_platform/features/exam_readiness/models/plan_regeneration_reason.dart';
import 'package:exam_platform/features/exam_readiness/models/study_plan_block_outcome.dart';
import 'package:exam_platform/features/exam_readiness/repositories/learning_state_audit_repository.dart';
import 'package:exam_platform/features/exam_readiness/repositories/study_plan_block_outcome_repository.dart';
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

  group('M7E StudyPlanBlockOutcome', () {
    test('valid outcome validates', () {
      expect(() => m7eOutcome().validate(), returnsNormally);
    });

    test('overall accuracy is derived from attempted questions', () {
      expect(
        m7eOutcome(questionsAttempted: 5, questionsCorrect: 3).overallAccuracy,
        0.6,
      );
    });

    test('zero attempted questions leaves overall accuracy unavailable', () {
      expect(
        m7eOutcome(
          questionsAttempted: 0,
          questionsCorrect: 0,
          applicationAccuracy: null,
        ).overallAccuracy,
        isNull,
      );
    });

    test('outcome round trips through JSON', () {
      final original = m7eOutcome(
        ultraHardAccuracy: 0.5,
        learnerRating: 4,
        confidenceSamples: 3,
      );
      final decoded = StudyPlanBlockOutcome.fromJson(original.toJson());

      expect(decoded.outcomeId, original.outcomeId);
      expect(decoded.ultraHardAccuracy, 0.5);
      expect(decoded.learnerRating, 4);
      expect(decoded.confidenceSamples, 3);
    });

    test('noncanonical competency is rejected', () {
      expect(
        () => m7eOutcome(competencyId: 'bad').validate(),
        throwsStateError,
      );
    });

    test('correct count cannot exceed attempts', () {
      expect(
        () => m7eOutcome(questionsAttempted: 2, questionsCorrect: 3).validate(),
        throwsStateError,
      );
    });

    test('accuracy outside unit interval is rejected', () {
      expect(
        () => m7eOutcome(applicationAccuracy: 1.2).validate(),
        throwsStateError,
      );
    });

    test('learner rating outside one to five is rejected', () {
      expect(() => m7eOutcome(learnerRating: 6).validate(), throwsStateError);
    });
  });

  group('M7E plan regeneration vocabulary', () {
    test('all frozen reasons map into daily plan generation reasons', () {
      for (final reason in PlanRegenerationReason.values) {
        expect(reason.dailyPlanReason.name, isNotEmpty);
      }
    });

    test('assessment completion remains distinct', () {
      expect(
        PlanRegenerationReason.assessmentCompleted.dailyPlanReason.name,
        'assessmentCompleted',
      );
    });

    test('missed study day remains distinct', () {
      expect(
        PlanRegenerationReason.missedStudyDay.dailyPlanReason.name,
        'missedStudyDay',
      );
    });
  });

  group('M7E local outcome repository', () {
    test('storage key is UID scoped', () {
      expect(
        StudyPlanBlockOutcomeRepository.storageKeyForUser('u1'),
        'csp11.student.u1.exam_readiness.block_outcomes.v1',
      );
    });

    test('append persists one immutable outcome', () async {
      const repo = StudyPlanBlockOutcomeRepository(userIdOverride: 'u1');

      expect(await repo.append(m7eOutcome()), isTrue);
      expect(await repo.loadAll(), hasLength(1));
    });

    test('duplicate outcome ID is idempotent', () async {
      const repo = StudyPlanBlockOutcomeRepository(userIdOverride: 'u1');

      expect(await repo.append(m7eOutcome()), isTrue);
      expect(await repo.append(m7eOutcome()), isFalse);
      expect(await repo.loadAll(), hasLength(1));
    });

    test('clear removes learner outcome history', () async {
      const repo = StudyPlanBlockOutcomeRepository(userIdOverride: 'u1');
      await repo.append(m7eOutcome());

      await repo.clear();

      expect(await repo.loadAll(), isEmpty);
    });
  });

  group('M7E local learning-state audit', () {
    LearningStateUpdateEvent event() => LearningStateUpdateEvent(
      eventId: 'event-1',
      outcomeId: 'outcome-1',
      competencyId: 'd03_c02',
      occurredAt: DateTime(2026, 9, 18, 12),
      regenerationReason: PlanRegenerationReason.assessmentCompleted,
      previousReadinessState: 'developing',
      nextReadinessState: 'strong',
      previousKnowledge: 0.6,
      nextKnowledge: 0.8,
      previousApplication: 0.5,
      nextApplication: 0.7,
      previousRetention: 0.7,
      nextRetention: 0.75,
      stalePlanVersionsCreated: 1,
      misconceptionCodes: const [],
      reasonCodes: const ['ASSESSMENT_UPDATED'],
    );

    test('audit storage key is UID scoped', () {
      expect(
        LearningStateAuditRepository.storageKeyForUser('u1'),
        'csp11.student.u1.exam_readiness.learning_state_audit.v1',
      );
    });

    test('audit event round trips through JSON', () {
      final decoded = LearningStateUpdateEvent.fromJson(event().toJson());

      expect(decoded.eventId, 'event-1');
      expect(decoded.nextKnowledge, 0.8);
      expect(decoded.stalePlanVersionsCreated, 1);
    });

    test('audit append is idempotent by event ID', () async {
      const repo = LearningStateAuditRepository(userIdOverride: 'u1');

      expect(await repo.append(event()), isTrue);
      expect(await repo.append(event()), isFalse);
      expect(await repo.loadAll(), hasLength(1));
    });
  });

  test('misconception signal round trips through JSON', () {
    final signal = MisconceptionSignal(
      competencyId: 'd03_c02',
      type: MisconceptionSignalType.highConfidenceIncorrect,
      strength: 0.8,
      sampleCount: 3,
      reasonCodes: const ['HIGH_CONFIDENCE_INCORRECT_PATTERN'],
      generatedAt: DateTime(2026, 9, 18),
    );

    final decoded = MisconceptionSignal.fromJson(signal.toJson());

    expect(decoded.type, MisconceptionSignalType.highConfidenceIncorrect);
    expect(decoded.strength, 0.8);
    expect(decoded.sampleCount, 3);
  });
}
