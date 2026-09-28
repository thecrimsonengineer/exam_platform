import 'package:exam_platform/data/csp11_blueprint.dart';
import 'package:exam_platform/features/exam_readiness/models/competency_readiness_profile.dart';
import 'package:exam_platform/features/exam_readiness/models/evidence_confidence.dart';
import 'package:exam_platform/features/exam_readiness/models/learning_evidence_event.dart';
import 'package:exam_platform/features/exam_readiness/models/study_plan_block.dart';
import 'package:exam_platform/features/exam_readiness/models/study_plan_block_outcome.dart';
import 'package:exam_platform/features/exam_readiness/repositories/learning_evidence_event_repository.dart';
import 'package:exam_platform/features/exam_readiness/services/daily_study_plan_service.dart';
import 'package:exam_platform/features/exam_readiness/services/learner_evidence_aggregation_service.dart';
import 'package:exam_platform/features/exam_readiness/services/learning_evidence_normalizer.dart';
import 'package:exam_platform/features/exam_readiness/services/readiness_profile_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../m7d/_support/m7d_fixture.dart';

StudyPlanBlock _block({
  required StudyPlanBlockType type,
  String blockId = 'erdp6-b01',
  String competencyId = 'd01_c01',
}) {
  return StudyPlanBlock(
    blockId: blockId,
    type: type,
    domainId: 'd01',
    competencyId: competencyId,
    subtopicId: 's01',
    topicId: 't01',
    plannedMinutes: 15,
    questionCount: switch (type) {
      StudyPlanBlockType.diagnostic ||
      StudyPlanBlockType.standardPractice ||
      StudyPlanBlockType.ultraHardPractice ||
      StudyPlanBlockType.mixedRetrieval ||
      StudyPlanBlockType.competencyRecheck ||
      StudyPlanBlockType.confidenceCalibration ||
      StudyPlanBlockType.examSimulation => 5,
      _ => 0,
    },
    priorityScore: 0.9,
    priorityBreakdown: m7dPriority(competencyId: competencyId),
    reasonCodes: const <String>['ERDP6_TEST'],
    reasonText: 'ERDP-6 evidence test.',
    status: StudyPlanBlockStatus.completed,
    createdAt: DateTime.utc(2026, 9, 28, 8),
    startedAt: DateTime.utc(2026, 9, 28, 9),
    completedAt: DateTime.utc(2026, 9, 28, 9, 15),
    manualChanges: const <StudyPlanManualChange>[],
  );
}

StudyPlanBlockOutcome _outcome({
  required StudyPlanBlock block,
  int attempted = 0,
  int correct = 0,
  double? applicationAccuracy,
}) {
  return StudyPlanBlockOutcome(
    outcomeId: 'outcome-${block.blockId}',
    planId: 'erdp6-plan',
    planVersion: 2,
    blockId: block.blockId,
    competencyId: block.competencyId,
    completedAt: block.completedAt!,
    minutesSpent: 15,
    questionsAttempted: attempted,
    questionsCorrect: correct,
    applicationAccuracy: applicationAccuracy,
    confidenceSamples: 0,
    contentCompleted: true,
    abandoned: false,
  );
}

LearningEvidenceEvent _event({
  required String id,
  required LearningEvidenceSourceKind source,
  required LearningEvidenceStrength strength,
  String competencyId = 'd01_c01',
  double? applicationScore,
  double? retentionScore,
}) {
  return LearningEvidenceEvent(
    evidenceEventId: id,
    sourceOutcomeId: 'source-$id',
    planId: 'erdp6-plan',
    planVersion: 2,
    blockId: 'erdp6-b01',
    domainId: 'd01',
    competencyId: competencyId,
    topicId: 't01',
    subtopicId: 's01',
    sourceKind: source,
    strength: strength,
    occurredAt: DateTime.utc(2026, 9, 28, 9, 15),
    questionsAttempted: 0,
    questionsCorrect: 0,
    confidenceSamples: 0,
    contentCompleted: true,
    abandoned: false,
    applicationScore: applicationScore,
    retentionScore: retentionScore,
    signalCodes: const <String>['ERDP6_TEST'],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('ERDP-6 normalized evidence hierarchy', () {
    test('practice outcome becomes strong question evidence', () {
      final block = _block(type: StudyPlanBlockType.standardPractice);
      final event = const LearningEvidenceNormalizer().fromStudyPlanOutcome(
        block: block,
        outcome: _outcome(block: block, attempted: 5, correct: 2),
      );

      expect(event.sourceKind, LearningEvidenceSourceKind.question);
      expect(event.strength, LearningEvidenceStrength.strong);
      expect(event.performanceScore, closeTo(0.4, 0.0001));
      expect(event.signalCodes, contains('LOW_PERFORMANCE_SIGNAL'));
    });

    test('Remember completion is supporting evidence, not automatic retention', () {
      final block = _block(type: StudyPlanBlockType.spacedReview);
      final event = const LearningEvidenceNormalizer().fromStudyPlanOutcome(
        block: block,
        outcome: _outcome(block: block),
      );

      expect(event.sourceKind, LearningEvidenceSourceKind.flashcard);
      expect(event.strength, LearningEvidenceStrength.supporting);
      expect(event.retentionScore, isNull);
      expect(
        event.signalCodes,
        contains('FLASHCARD_SUPPORT_REQUIRES_RECALL_QUALITY'),
      );
    });

    test('micro-learning cannot carry readiness scores', () {
      final invalid = _event(
        id: 'micro-1',
        source: LearningEvidenceSourceKind.microLearning,
        strength: LearningEvidenceStrength.none,
        applicationScore: 0.9,
      );

      expect(invalid.validate, throwsStateError);
    });
  });

  group('ERDP-6 immutable evidence ledger', () {
    test('same event replay is idempotent', () async {
      final repository = LearningEvidenceEventRepository(
        userIdOverride: 'learner-1',
      );
      final event = _event(
        id: 'study-1',
        source: LearningEvidenceSourceKind.study,
        strength: LearningEvidenceStrength.context,
      );

      expect(await repository.append(event), isTrue);
      expect(await repository.append(event), isFalse);
      expect(await repository.loadAll(), hasLength(1));
    });

    test('same event ID with changed payload is rejected', () async {
      final repository = LearningEvidenceEventRepository(
        userIdOverride: 'learner-1',
      );
      final event = _event(
        id: 'study-immutable',
        source: LearningEvidenceSourceKind.study,
        strength: LearningEvidenceStrength.context,
      );
      await repository.append(event);

      final changed = LearningEvidenceEvent(
        evidenceEventId: event.evidenceEventId,
        sourceOutcomeId: event.sourceOutcomeId,
        planId: event.planId,
        planVersion: event.planVersion,
        blockId: event.blockId,
        domainId: event.domainId,
        competencyId: event.competencyId,
        topicId: event.topicId,
        subtopicId: event.subtopicId,
        sourceKind: event.sourceKind,
        strength: event.strength,
        occurredAt: event.occurredAt,
        questionsAttempted: event.questionsAttempted,
        questionsCorrect: event.questionsCorrect,
        confidenceSamples: event.confidenceSamples,
        contentCompleted: false,
        abandoned: event.abandoned,
        signalCodes: event.signalCodes,
      );

      expect(() => repository.append(changed), throwsA(isA<StateError>()));
    });
  });

  group('ERDP-6 readiness semantics', () {
    test('study context means insufficient evidence, not weak mastery', () {
      final event = _event(
        id: 'study-context',
        source: LearningEvidenceSourceKind.study,
        strength: LearningEvidenceStrength.context,
      );
      final evidence = const LearnerEvidenceAggregationService().buildSnapshot(
        competencyId: 'd01_c01',
        attempts: const [],
        scope: const CompetencyEvidenceScope(
          competencyId: 'd01_c01',
          topicIds: <String>{'t01'},
          subtopicIds: <String>{'s01'},
        ),
        now: DateTime.utc(2026, 9, 28, 10),
        activityEvents: <LearningEvidenceEvent>[event],
      );
      final profile = const ReadinessProfileService().buildCompetencyProfile(
        evidence: evidence,
        now: DateTime.utc(2026, 9, 28, 10),
      );

      expect(evidence.activity.contextEvents, 1);
      expect(profile.readinessState, ReadinessState.insufficientEvidence);
      expect(profile.knowledgeMastery.value, isNull);
    });

    test('micro-learning exposure leaves readiness unknown', () {
      final event = _event(
        id: 'micro-zero',
        source: LearningEvidenceSourceKind.microLearning,
        strength: LearningEvidenceStrength.none,
      );
      final evidence = const LearnerEvidenceAggregationService().buildSnapshot(
        competencyId: 'd01_c01',
        attempts: const [],
        scope: const CompetencyEvidenceScope(competencyId: 'd01_c01'),
        now: DateTime.utc(2026, 9, 28, 10),
        activityEvents: <LearningEvidenceEvent>[event],
      );
      final profile = const ReadinessProfileService().buildCompetencyProfile(
        evidence: evidence,
        now: DateTime.utc(2026, 9, 28, 10),
      );

      expect(evidence.activity.zeroCreditEvents, 1);
      expect(evidence.activity.creditableEvents, 0);
      expect(profile.readinessState, ReadinessState.unknown);
    });

    test('strong LAB evidence contributes to application only', () {
      final event = _event(
        id: 'lab-1',
        source: LearningEvidenceSourceKind.lab,
        strength: LearningEvidenceStrength.strong,
        applicationScore: 0.82,
      );
      final evidence = const LearnerEvidenceAggregationService().buildSnapshot(
        competencyId: 'd01_c01',
        attempts: const [],
        scope: const CompetencyEvidenceScope(competencyId: 'd01_c01'),
        now: DateTime.utc(2026, 9, 28, 10),
        activityEvents: <LearningEvidenceEvent>[event],
      );
      final profile = const ReadinessProfileService().buildCompetencyProfile(
        evidence: evidence,
        now: DateTime.utc(2026, 9, 28, 10),
      );

      expect(evidence.activity.strongApplicationSamples, 1);
      expect(profile.applicationAbility.value, isNotNull);
      expect(profile.knowledgeMastery.value, isNull);
      expect(profile.readinessState, ReadinessState.insufficientEvidence);
    });

    test('insufficient evidence is converted into a Diagnostic plan action', () {
      final context = _event(
        id: 'context-diagnostic',
        source: LearningEvidenceSourceKind.study,
        strength: LearningEvidenceStrength.context,
      );
      final evidence = const LearnerEvidenceAggregationService().buildSnapshot(
        competencyId: 'd01_c01',
        attempts: const [],
        scope: const CompetencyEvidenceScope(competencyId: 'd01_c01'),
        now: DateTime.utc(2026, 9, 28, 10),
        activityEvents: <LearningEvidenceEvent>[context],
      );
      final targetProfile = const ReadinessProfileService()
          .buildCompetencyProfile(
            evidence: evidence,
            now: DateTime.utc(2026, 9, 28, 10),
          );

      final profiles = <String, CompetencyReadinessProfile>{};
      for (final domain in csp11Domains) {
        for (final competency in domain.competencies) {
          profiles[competency.id] = m7dProfile(
            competencyId: competency.id,
            evidenceConfidence: EvidenceConfidence.veryHigh,
            readinessState: ReadinessState.stable,
            knowledge: 0.92,
            application: 0.90,
            retention: 0.90,
            coverage: 0.95,
            difficulty: 0.88,
            calibration: 0.92,
          );
        }
      }
      profiles['d01_c01'] = targetProfile;

      final plan = const DailyStudyPlanService().generate(
        userId: 'learner-1',
        date: DateTime(2026, 9, 28),
        generatedAt: DateTime(2026, 9, 28, 10),
        examDate: DateTime(2026, 11, 1),
        availableMinutes: 60,
        readinessProfiles: profiles,
      );

      expect(
        plan.blocks.any(
          (block) =>
              block.competencyId == 'd01_c01' &&
              block.type == StudyPlanBlockType.diagnostic,
        ),
        isTrue,
      );
    });
  });
}
