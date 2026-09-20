import 'package:exam_platform/features/flashcards/flashcards.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  FlashcardOwnership ownership({
    required DateTime acquiredAt,
    DateTime? firstViewedAt,
    String cardId = 'csp11.flashcard.hierarchy_of_controls',
    String conceptId = 'csp11.concept.hierarchy_of_controls',
  }) {
    final value = FlashcardOwnership(
      cardId: cardId,
      conceptId: conceptId,
      acquiredAt: acquiredAt,
      acquisitionSource: FlashcardAcquisitionSource.dailyDiscovery,
      firstQuestionOutcome: FlashcardQuestionOutcome.notApplicable,
      firstViewedAt: firstViewedAt,
      appliedEventIds: const <String>['daily:seed'],
    );
    value.validate();
    return value;
  }

  test('memory does not activate before first reveal', () async {
    final repository = MemoryFlashcardReviewRepository();
    final service = FlashcardMemoryService(
      repository: repository,
      userIdOverride: 'learner-unseen',
    );
    final acquired = DateTime.utc(2026, 9, 20, 8);

    final result = await service.activateFromOwnership(
      ownership(acquiredAt: acquired),
    );

    expect(result, isNull);
    expect(await service.loadAll(), isEmpty);
  });

  test('first reveal activates a one-day learning interval', () async {
    final repository = MemoryFlashcardReviewRepository();
    final service = FlashcardMemoryService(
      repository: repository,
      userIdOverride: 'learner-activate',
    );
    final acquired = DateTime.utc(2026, 9, 20, 8);
    final viewed = DateTime.utc(2026, 9, 20, 9);
    final owned = ownership(
      acquiredAt: acquired,
      firstViewedAt: viewed,
    );

    final first = await service.activateFromOwnership(owned);
    final second = await service.activateFromOwnership(owned);

    expect(first, isNotNull);
    expect(first?.stage, FlashcardReviewStage.learning);
    expect(
      first?.dueAt,
      viewed.add(const Duration(days: 1)),
    );
    expect(second?.toJson(), first?.toJson());
  });

  test('ratings produce deterministic due dates and relearning', () async {
    final repository = MemoryFlashcardReviewRepository();
    final service = FlashcardMemoryService(
      repository: repository,
      userIdOverride: 'learner-ratings',
    );
    final acquired = DateTime.utc(2026, 9, 20, 8);
    final viewed = DateTime.utc(2026, 9, 20, 9);
    final owned = ownership(
      acquiredAt: acquired,
      firstViewedAt: viewed,
    );
    await service.activateFromOwnership(owned);

    final firstReview = viewed.add(const Duration(days: 1));
    final gotIt = await service.rate(
      eventId: 'review:one',
      cardId: owned.cardId,
      conceptId: owned.conceptId,
      rating: FlashcardReviewRating.gotIt,
      reviewedAt: firstReview,
    );

    expect(gotIt.kind, FlashcardReviewEventKind.applied);
    expect(gotIt.state.stage, FlashcardReviewStage.review);
    expect(
      gotIt.state.dueAt,
      firstReview.add(const Duration(days: 3)),
    );

    final duplicate = await service.rate(
      eventId: 'review:one',
      cardId: owned.cardId,
      conceptId: owned.conceptId,
      rating: FlashcardReviewRating.gotIt,
      reviewedAt: firstReview,
    );
    expect(
      duplicate.kind,
      FlashcardReviewEventKind.duplicateIgnored,
    );
    expect(duplicate.state.reviewCount, 1);

    final againAt = firstReview.add(const Duration(days: 3));
    final again = await service.rate(
      eventId: 'review:two',
      cardId: owned.cardId,
      conceptId: owned.conceptId,
      rating: FlashcardReviewRating.again,
      reviewedAt: againAt,
    );

    expect(again.state.stage, FlashcardReviewStage.relearning);
    expect(again.state.lapseCount, 1);
    expect(
      again.state.dueAt,
      againAt.add(const Duration(minutes: 10)),
    );

    final hardAt = againAt.add(const Duration(minutes: 10));
    final hard = await service.rate(
      eventId: 'review:three',
      cardId: owned.cardId,
      conceptId: owned.conceptId,
      rating: FlashcardReviewRating.hard,
      reviewedAt: hardAt,
    );

    expect(hard.state.stage, FlashcardReviewStage.review);
    expect(
      hard.state.dueAt,
      hardAt.add(const Duration(days: 1)),
    );
  });

  test('weak-card assessment can use incorrect MCQ evidence for priority', () {
    final activated = DateTime.utc(2026, 9, 20, 8);
    final review = FlashcardReviewState(
      cardId: 'csp11.flashcard.test',
      conceptId: 'csp11.concept.test',
      activatedAt: activated,
      stage: FlashcardReviewStage.learning,
      dueAt: activated.add(const Duration(days: 1)),
      intervalMinutes: FlashcardIntervalPolicy.initialIntervalMinutes,
    );
    final owned = FlashcardOwnership(
      cardId: review.cardId,
      conceptId: review.conceptId,
      acquiredAt: activated.subtract(const Duration(hours: 1)),
      acquisitionSource: FlashcardAcquisitionSource.questionCompletion,
      firstQuestionOutcome: FlashcardQuestionOutcome.incorrect,
      firstViewedAt: activated,
      correctSignalCount: 0,
      incorrectSignalCount: 3,
      reinforcementCount: 2,
      lastReinforcedAt: activated,
      appliedEventIds: const <String>['q1', 'q2', 'q3'],
    );
    owned.validate();

    final assessment = const FlashcardWeakCardPolicy().assess(
      review: review,
      ownership: owned,
    );

    expect(assessment.score, 3);
    expect(assessment.isWeak, isFalse);
  });

  test('memory statistics separate due, stage and weakness counts', () {
    final now = DateTime.utc(2026, 9, 25, 8);
    final activated = DateTime.utc(2026, 9, 20, 8);
    final learning = FlashcardReviewState(
      cardId: 'csp11.flashcard.learning',
      conceptId: 'csp11.concept.learning',
      activatedAt: activated,
      stage: FlashcardReviewStage.learning,
      dueAt: now.subtract(const Duration(minutes: 1)),
      intervalMinutes: FlashcardIntervalPolicy.initialIntervalMinutes,
    );
    final relearning = FlashcardReviewState(
      cardId: 'csp11.flashcard.relearning',
      conceptId: 'csp11.concept.relearning',
      activatedAt: activated,
      stage: FlashcardReviewStage.relearning,
      dueAt: now.add(const Duration(minutes: 10)),
      intervalMinutes: FlashcardIntervalPolicy.relearningIntervalMinutes,
      reviewCount: 1,
      lapseCount: 1,
      againCount: 1,
      lastReviewedAt: now,
      lastRating: FlashcardReviewRating.again,
      appliedReviewEventIds: const <String>['review:again'],
    );

    final stats = FlashcardMemoryStatistics.build(
      reviews: <FlashcardReviewState>[learning, relearning],
      now: now,
    );

    expect(stats.activeCount, 2);
    expect(stats.dueCount, 1);
    expect(stats.learningCount, 1);
    expect(stats.relearningCount, 1);
    expect(stats.weakCount, 1);
    expect(stats.totalReviewEvents, 1);
    expect(stats.totalLapses, 1);
  });
}
