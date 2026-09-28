import 'package:exam_platform/features/exam_readiness/models/learner_assessment_attempt.dart';
import 'package:exam_platform/features/exam_readiness/models/learning_evidence_event.dart';
import 'package:exam_platform/features/exam_readiness/models/study_plan_block.dart';
import 'package:exam_platform/features/exam_readiness/services/flashcard_retention_evidence_service.dart';
import 'package:exam_platform/features/exam_readiness/services/learner_evidence_aggregation_service.dart';
import 'package:exam_platform/features/exam_readiness/services/readiness_profile_service.dart';
import 'package:exam_platform/features/exam_readiness/services/study_plan_completion_evidence_service.dart';
import 'package:exam_platform/features/flashcards/cloud/published_flashcard_package.dart';
import 'package:exam_platform/features/flashcards/learning/flashcard_recall_event.dart';
import 'package:exam_platform/features/flashcards/learning/flashcard_review_queue_service.dart';
import 'package:exam_platform/models/student_learning_progress.dart';
import 'package:exam_platform/screens/flashcards/flashcards_catalog_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../m7d/_support/m7d_fixture.dart';

FlashcardCard _card(String id) => FlashcardCard(
  id: id,
  frontLabel: 'Concept $id',
  backDefinition: 'Definition $id',
  whyItMatters: 'Why $id matters',
  keyPoint: 'Key point $id',
  tags: const <String>['erdp9'],
);

FlashcardRecallEvent _recall({
  required String id,
  required String cardId,
  required FlashcardRecallRating rating,
  required DateTime at,
  String sessionId = 'session-1',
  int attemptSequence = 1,
  int? spacingDays,
  bool sameSessionRepeat = false,
  FlashcardReviewSource source = FlashcardReviewSource.catalog,
  String? blockId,
}) => FlashcardRecallEvent(
  eventId: id,
  sessionId: sessionId,
  cardId: cardId,
  competencyId: 'd01_c01',
  conceptLabel: 'Concept $cardId',
  rating: rating,
  occurredAt: at,
  attemptSequence: attemptSequence,
  previousRating: spacingDays == null ? null : FlashcardRecallRating.gotIt,
  previousOccurredAt: spacingDays == null
      ? null
      : at.subtract(Duration(days: spacingDays)),
  spacingIntervalDays: spacingDays,
  sameSessionRepeat: sameSessionRepeat,
  source: source,
  blockId: blockId,
  nextReviewAt: at.add(const Duration(days: 1)),
);

LearnerAssessmentAttempt _attempt({
  required String id,
  required int questionId,
  required bool correct,
  required DateTime at,
}) => LearnerAssessmentAttempt(
  attemptId: id,
  questionId: questionId,
  domainNumber: 1,
  competencyId: 'd01_c01',
  topicId: 'd01_c01_t01',
  subtopicId: 'd01_c01_t01_s01',
  correct: correct,
  answeredAt: at,
  cognitiveLevel: 'application',
  questionType: 'scenario_mcq',
  difficultyLane: AttemptDifficultyLane.hard,
  publishedAtAttempt: true,
  questionVersion: 1,
  sessionKind: 'practice',
);

StudyPlanBlock _rememberBlock(DateTime startedAt) => StudyPlanBlock(
  blockId: 'plan-v1-b00-d01_c01-spacedReview',
  type: StudyPlanBlockType.spacedReview,
  domainId: 'd01',
  competencyId: 'd01_c01',
  subtopicId: '',
  topicId: '',
  plannedMinutes: 10,
  questionCount: 0,
  priorityScore: 0.9,
  priorityBreakdown: m7dPriority(competencyId: 'd01_c01'),
  reasonCodes: const <String>['RETENTION_DUE'],
  reasonText: 'Retention review is due.',
  status: StudyPlanBlockStatus.started,
  createdAt: startedAt.subtract(const Duration(minutes: 1)),
  startedAt: startedAt,
  manualChanges: const <StudyPlanManualChange>[],
);

class _FakeRecallRuntime implements FlashcardRecallRuntime {
  final List<FlashcardRecallEvent> events = <FlashcardRecallEvent>[];

  @override
  Future<List<FlashcardRecallEvent>> loadHistory(String competencyId) async =>
      List<FlashcardRecallEvent>.unmodifiable(events);

  @override
  Future<FlashcardRecallRecordResult> record({
    required String sessionId,
    required String competencyId,
    required FlashcardCard card,
    required FlashcardRecallRating rating,
    required DateTime occurredAt,
    required FlashcardReviewSource source,
    String? blockId,
  }) async {
    final priorInSession = events
        .where((event) => event.sessionId == sessionId && event.cardId == card.id)
        .length;
    final recall = FlashcardRecallEvent(
      eventId: '$sessionId-${card.id}-${priorInSession + 1}',
      sessionId: sessionId,
      cardId: card.id,
      competencyId: competencyId,
      conceptLabel: card.frontLabel,
      rating: rating,
      occurredAt: occurredAt,
      attemptSequence: priorInSession + 1,
      sameSessionRepeat: priorInSession > 0,
      source: source,
      blockId: blockId,
      nextReviewAt: occurredAt.add(const Duration(days: 1)),
    );
    events.add(recall);
    final evidence = const FlashcardRetentionEvidenceService().toLearningEvidence(
      recall,
    );
    return FlashcardRecallRecordResult(
      recallEvent: recall,
      evidenceEvent: evidence,
      recallRecorded: true,
      evidenceRecorded: true,
      stateUpdate: null,
    );
  }
}

void main() {
  const retentionService = FlashcardRetentionEvidenceService();
  const aggregationService = LearnerEvidenceAggregationService();
  const readinessService = ReadinessProfileService();

  group('ERDP-9 Flashcard recall evidence', () {
    test('Again is a strong negative retention signal', () {
      final event = _recall(
        id: 'again-1',
        cardId: 'card-1',
        rating: FlashcardRecallRating.again,
        at: DateTime.utc(2026, 9, 28),
      );
      final evidence = retentionService.toLearningEvidence(event);

      expect(evidence.retentionScore, 0.0);
      expect(evidence.signalCodes, contains('FLASHCARD_RETENTION_GAP_STRONG'));
      expect(evidence.strength, LearningEvidenceStrength.supporting);
    });

    test('Hard is moderate and Got It gains value when genuinely spaced', () {
      final hard = retentionService.toLearningEvidence(
        _recall(
          id: 'hard-1',
          cardId: 'card-1',
          rating: FlashcardRecallRating.hard,
          at: DateTime.utc(2026, 9, 28),
          spacingDays: 3,
        ),
      );
      final gotIt = retentionService.toLearningEvidence(
        _recall(
          id: 'got-1',
          cardId: 'card-2',
          rating: FlashcardRecallRating.gotIt,
          at: DateTime.utc(2026, 9, 28),
          spacingDays: 3,
        ),
      );

      expect(hard.retentionScore, 0.40);
      expect(hard.signalCodes, contains('FLASHCARD_RETENTION_GAP_MODERATE'));
      expect(gotIt.retentionScore, 0.90);
      expect(gotIt.signalCodes, contains('FLASHCARD_SPACED_SUCCESS'));
    });

    test('same-sitting repeats carry no extra readiness credit', () {
      final repeat = retentionService.toLearningEvidence(
        _recall(
          id: 'repeat-1',
          cardId: 'card-1',
          rating: FlashcardRecallRating.gotIt,
          at: DateTime.utc(2026, 9, 28, 10),
          attemptSequence: 2,
          sameSessionRepeat: true,
        ),
      );

      expect(repeat.retentionScore, isNull);
      expect(
        repeat.signalCodes,
        contains('FLASHCARD_SAME_SESSION_REPEAT_NO_EXTRA_CREDIT'),
      );
    });

    test('one successful card cannot create a retention readiness value', () {
      final now = DateTime.utc(2026, 9, 28, 12);
      final event = retentionService.toLearningEvidence(
        _recall(
          id: 'single-success',
          cardId: 'card-1',
          rating: FlashcardRecallRating.gotIt,
          at: now.subtract(const Duration(days: 3)),
          spacingDays: 3,
        ),
      );
      final evidence = aggregationService.buildSnapshot(
        competencyId: 'd01_c01',
        attempts: const <LearnerAssessmentAttempt>[],
        scope: const CompetencyEvidenceScope(competencyId: 'd01_c01'),
        now: now,
        activityEvents: <LearningEvidenceEvent>[event],
      );
      final profile = readinessService.buildCompetencyProfile(
        evidence: evidence,
        now: now,
      );

      expect(evidence.activity.supportingRetentionSamples, 1);
      expect(profile.retention.value, isNull);
      expect(
        profile.retention.reasonCodes,
        contains('FLASHCARD_RETENTION_EVIDENCE_BUILDING'),
      );
    });

    test('repeated spaced success across cards creates supporting retention', () {
      final now = DateTime.utc(2026, 9, 28, 12);
      final events = <LearningEvidenceEvent>[
        for (var i = 0; i < 3; i++)
          retentionService.toLearningEvidence(
            _recall(
              id: 'spaced-$i',
              cardId: 'card-${i + 1}',
              rating: FlashcardRecallRating.gotIt,
              at: now.subtract(Duration(days: 3 + i)),
              spacingDays: 3 + i,
            ),
          ),
      ];
      final evidence = aggregationService.buildSnapshot(
        competencyId: 'd01_c01',
        attempts: const <LearnerAssessmentAttempt>[],
        scope: const CompetencyEvidenceScope(competencyId: 'd01_c01'),
        now: now,
        activityEvents: events,
      );
      final profile = readinessService.buildCompetencyProfile(
        evidence: evidence,
        now: now,
      );

      expect(evidence.activity.supportingRetentionDistinctUnits, 3);
      expect(evidence.activity.supportingRetentionSpacedSamples, 3);
      expect(profile.retention.value, isNotNull);
      expect(profile.retention.value!, greaterThan(0.70));
      expect(
        profile.retention.reasonCodes,
        contains('FLASHCARD_SUPPORTING_ONLY'),
      );
    });

    test('delayed question evidence remains authoritative over Flashcards', () {
      final now = DateTime.utc(2026, 9, 28, 12);
      final attempts = <LearnerAssessmentAttempt>[
        _attempt(
          id: 'q1-initial',
          questionId: 1,
          correct: false,
          at: now.subtract(const Duration(days: 6)),
        ),
        _attempt(
          id: 'q1-delayed',
          questionId: 1,
          correct: false,
          at: now.subtract(const Duration(days: 2)),
        ),
        _attempt(
          id: 'q2-initial',
          questionId: 2,
          correct: true,
          at: now.subtract(const Duration(days: 6)),
        ),
        _attempt(
          id: 'q2-delayed',
          questionId: 2,
          correct: false,
          at: now.subtract(const Duration(days: 2)),
        ),
      ];
      final flashcards = <LearningEvidenceEvent>[
        for (var i = 0; i < 4; i++)
          retentionService.toLearningEvidence(
            _recall(
              id: 'positive-$i',
              cardId: 'card-$i',
              rating: FlashcardRecallRating.gotIt,
              at: now.subtract(Duration(days: 3 + i)),
              spacingDays: 4,
            ),
          ),
      ];
      final evidence = aggregationService.buildSnapshot(
        competencyId: 'd01_c01',
        attempts: attempts,
        scope: const CompetencyEvidenceScope(competencyId: 'd01_c01'),
        now: now,
        activityEvents: flashcards,
      );
      final profile = readinessService.buildCompetencyProfile(
        evidence: evidence,
        attempts: attempts,
        now: now,
      );

      expect(evidence.retention.delayedAttempts, 2);
      expect(profile.retention.value, lessThan(0.30));
      expect(
        profile.retention.reasonCodes,
        contains('DELAYED_RETENTION_EVIDENCE_AVAILABLE'),
      );
    });

    test('micro-learning remains zero-credit beside Flashcard evidence', () {
      final micro = LearningEvidenceEvent(
        evidenceEventId: 'micro-1',
        sourceOutcomeId: 'micro-1',
        planId: 'plan-1',
        planVersion: 1,
        blockId: 'block-1',
        domainId: 'd01',
        competencyId: 'd01_c01',
        topicId: '',
        subtopicId: '',
        sourceKind: LearningEvidenceSourceKind.microLearning,
        strength: LearningEvidenceStrength.none,
        occurredAt: DateTime.utc(2026, 9, 28),
        questionsAttempted: 0,
        questionsCorrect: 0,
        confidenceSamples: 0,
        contentCompleted: false,
        abandoned: false,
        signalCodes: const <String>['MICRO_EXPOSURE'],
      );
      final stats = ActivityEvidenceStats.aggregate(<LearningEvidenceEvent>[
        micro,
      ]);

      expect(stats.zeroCreditEvents, 1);
      expect(stats.supportingRetentionSamples, 0);
    });
  });

  group('ERDP-9 review queue and Daily Plan completion', () {
    test('queue prioritizes due weak cards and respects target size', () {
      final now = DateTime.utc(2026, 9, 28, 12);
      final cards = <FlashcardCard>[_card('a'), _card('b'), _card('c')];
      final history = <FlashcardRecallEvent>[
        _recall(
          id: 'a-old',
          cardId: 'a',
          rating: FlashcardRecallRating.again,
          at: now.subtract(const Duration(days: 2)),
        ),
        FlashcardRecallEvent(
          eventId: 'b-future',
          sessionId: 'prior',
          cardId: 'b',
          competencyId: 'd01_c01',
          conceptLabel: 'Concept b',
          rating: FlashcardRecallRating.gotIt,
          occurredAt: now.subtract(const Duration(days: 1)),
          attemptSequence: 1,
          sameSessionRepeat: false,
          source: FlashcardReviewSource.catalog,
          nextReviewAt: now.add(const Duration(days: 5)),
        ),
      ];

      final queue = const FlashcardReviewQueueService().build(
        cards: cards,
        history: history,
        now: now,
        targetCardCount: 2,
        dueOnly: true,
      );

      expect(queue.map((card) => card.id), containsAll(<String>['a', 'c']));
      expect(queue.map((card) => card.id), isNot(contains('b')));
      expect(queue, hasLength(2));
    });

    test('planned Remember completion requires distinct first-session ratings', () {
      final started = DateTime.utc(2026, 9, 28, 9);
      final block = _rememberBlock(started);
      final events = <FlashcardRecallEvent>[
        for (var i = 0; i < 5; i++)
          _recall(
            id: 'planned-$i',
            cardId: 'card-$i',
            rating: i == 0
                ? FlashcardRecallRating.again
                : FlashcardRecallRating.gotIt,
            at: started.add(Duration(minutes: i + 1)),
            source: FlashcardReviewSource.dailyPlan,
            blockId: block.blockId,
          ),
        _recall(
          id: 'repeat-extra',
          cardId: 'card-0',
          rating: FlashcardRecallRating.gotIt,
          at: started.add(const Duration(minutes: 8)),
          attemptSequence: 2,
          sameSessionRepeat: true,
          source: FlashcardReviewSource.dailyPlan,
          blockId: block.blockId,
        ),
      ];

      final decision = const StudyPlanCompletionEvidenceService().evaluate(
        block: block,
        source: StudyPlanCompletionEvidenceSource.flashcardReviewSession,
        attempts: const <LearnerAssessmentAttempt>[],
        studyProgress: const <StudentSubtopicProgress>[],
        flashcardRecallEvents: events,
        completedAt: started.add(const Duration(minutes: 10)),
      );

      expect(decision.eligible, isTrue);
    });
  });

  testWidgets('deck exposes Again, Hard and Got It only after reveal', (
    tester,
  ) async {
    final runtime = _FakeRecallRuntime();
    var completed = 0;
    final deck = FlashcardDeckPackage(
      competencyId: 'd01_c01',
      domainId: 'd01',
      deckId: 'deck-1',
      title: 'ERDP-9 Deck',
      cards: <FlashcardCard>[_card('a'), _card('b'), _card('c')],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: FlashcardDeckScreen(
          deck: deck,
          isDarkMode: false,
          plannedBlockId: 'block-1',
          targetCardCount: 2,
          dueOnly: false,
          recallRuntime: runtime,
          now: () => DateTime.utc(2026, 9, 28, 10),
          onReviewSessionCompleted: () async => completed++,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Again'), findsNothing);
    expect(find.text('Hard'), findsNothing);
    expect(find.text('Got It'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('flashcard-study-card')));
    await tester.pump();
    expect(find.text('Again'), findsOneWidget);
    expect(find.text('Hard'), findsOneWidget);
    expect(find.text('Got It'), findsOneWidget);

    await tester.tap(find.text('Again'));
    await tester.pumpAndSettle();
    expect(runtime.events, hasLength(1));
    expect(runtime.events.single.rating, FlashcardRecallRating.again);

    await tester.tap(find.byKey(const ValueKey('flashcard-study-card')));
    await tester.pump();
    await tester.tap(find.text('Got It'));
    await tester.pumpAndSettle();

    expect(completed, 1);
    expect(
      runtime.events.where((event) => event.isFirstAttemptInSession),
      hasLength(2),
    );
  });
}
