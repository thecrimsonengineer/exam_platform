import 'dart:io';

import 'package:exam_platform/features/flashcards/flashcards.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FlashcardContentPackage referencePackage;
  late Flashcard hierarchy;
  late Flashcard elimination;

  setUpAll(() {
    referencePackage = const FlashcardPackageJsonCodec().decode(
      File(
        'assets/flashcards/run3/fc_reference_package.v1.json',
      ).readAsStringSync(),
    );
    hierarchy = referencePackage.cards.firstWhere(
      (card) => card.id == 'csp11.flashcard.hierarchy_of_controls',
    );
    elimination = referencePackage.cards.firstWhere(
      (card) => card.id == 'csp11.flashcard.elimination_control',
    );
  });

  test('correct completion collects an unseen card', () async {
    final repository = MemoryFlashcardCollectionRepository();
    final service = FlashcardUnlockService(
      repository: repository,
      userIdOverride: 'learner-correct',
    );

    final event = await service.apply(
      card: hierarchy,
      request: FlashcardUnlockRequest(
        eventId: 'quiz:session-a:930001',
        cardId: hierarchy.id,
        conceptId: hierarchy.conceptId,
        source: FlashcardAcquisitionSource.questionCompletion,
        questionOutcome: FlashcardQuestionOutcome.correct,
        questionId: 930001,
        occurredAt: DateTime.utc(2026, 9, 20, 10),
      ),
    );

    expect(event.kind, FlashcardUnlockEventKind.newlyCollected);
    expect(event.ownership.isUnseen, isTrue);
    expect(event.ownership.correctSignalCount, 1);
    expect(event.ownership.incorrectSignalCount, 0);
    expect(event.ownership.reinforcementCount, 0);
    expect(await service.isOwned(hierarchy.id), isTrue);
  });

  test('incorrect completion also collects the mapped concept card', () async {
    final repository = MemoryFlashcardCollectionRepository();
    final service = FlashcardUnlockService(
      repository: repository,
      userIdOverride: 'learner-incorrect',
    );

    final event = await service.apply(
      card: hierarchy,
      request: FlashcardUnlockRequest(
        eventId: 'quiz:session-b:930001',
        cardId: hierarchy.id,
        conceptId: hierarchy.conceptId,
        source: FlashcardAcquisitionSource.questionCompletion,
        questionOutcome: FlashcardQuestionOutcome.incorrect,
        questionId: 930001,
      ),
    );

    expect(event.kind, FlashcardUnlockEventKind.newlyCollected);
    expect(event.ownership.incorrectSignalCount, 1);
    expect(event.ownership.correctSignalCount, 0);
  });

  test('new event reinforces but repeated event ID is idempotent', () async {
    final repository = MemoryFlashcardCollectionRepository();
    final service = FlashcardUnlockService(
      repository: repository,
      userIdOverride: 'learner-reinforce',
    );

    await service.apply(
      card: hierarchy,
      request: FlashcardUnlockRequest(
        eventId: 'quiz:one',
        cardId: hierarchy.id,
        conceptId: hierarchy.conceptId,
        source: FlashcardAcquisitionSource.questionCompletion,
        questionOutcome: FlashcardQuestionOutcome.correct,
        questionId: 930001,
      ),
    );

    final reinforcement = await service.apply(
      card: hierarchy,
      request: FlashcardUnlockRequest(
        eventId: 'quiz:two',
        cardId: hierarchy.id,
        conceptId: hierarchy.conceptId,
        source: FlashcardAcquisitionSource.questionCompletion,
        questionOutcome: FlashcardQuestionOutcome.incorrect,
        questionId: 930001,
      ),
    );
    final duplicate = await service.apply(
      card: hierarchy,
      request: FlashcardUnlockRequest(
        eventId: 'quiz:two',
        cardId: hierarchy.id,
        conceptId: hierarchy.conceptId,
        source: FlashcardAcquisitionSource.questionCompletion,
        questionOutcome: FlashcardQuestionOutcome.incorrect,
        questionId: 930001,
      ),
    );

    expect(reinforcement.kind, FlashcardUnlockEventKind.reinforced);
    expect(reinforcement.ownership.reinforcementCount, 1);
    expect(reinforcement.ownership.correctSignalCount, 1);
    expect(reinforcement.ownership.incorrectSignalCount, 1);

    expect(duplicate.kind, FlashcardUnlockEventKind.duplicateIgnored);
    expect(duplicate.ownership.reinforcementCount, 1);
    expect(duplicate.ownership.appliedEventIds, hasLength(2));
  });

  test('concurrent duplicate callbacks create one ownership mutation', () async {
    final repository = MemoryFlashcardCollectionRepository();
    final service = FlashcardUnlockService(
      repository: repository,
      userIdOverride: 'learner-concurrent',
    );
    final request = FlashcardUnlockRequest(
      eventId: 'quiz:concurrent',
      cardId: hierarchy.id,
      conceptId: hierarchy.conceptId,
      source: FlashcardAcquisitionSource.questionCompletion,
      questionOutcome: FlashcardQuestionOutcome.correct,
      questionId: 930001,
    );

    final events = await Future.wait(<Future<FlashcardUnlockEvent>>[
      service.apply(card: hierarchy, request: request),
      service.apply(card: hierarchy, request: request),
    ]);

    expect(
      events.map((event) => event.kind).toSet(),
      <FlashcardUnlockEventKind>{
        FlashcardUnlockEventKind.newlyCollected,
        FlashcardUnlockEventKind.duplicateIgnored,
      },
    );

    final owned = await service.loadCollection();
    expect(owned, hasLength(1));
    expect(owned.single.reinforcementCount, 0);
    expect(owned.single.appliedEventIds, <String>['quiz:concurrent']);
  });

  test('first-view transition is one-way and idempotent', () async {
    final repository = MemoryFlashcardCollectionRepository();
    final service = FlashcardUnlockService(
      repository: repository,
      userIdOverride: 'learner-view',
    );

    await service.apply(
      card: hierarchy,
      request: FlashcardUnlockRequest(
        eventId: 'quiz:view',
        cardId: hierarchy.id,
        conceptId: hierarchy.conceptId,
        source: FlashcardAcquisitionSource.questionCompletion,
        questionOutcome: FlashcardQuestionOutcome.correct,
        questionId: 930001,
      ),
    );

    final firstAt = DateTime.utc(2026, 9, 20, 11);
    final secondAt = DateTime.utc(2026, 9, 21, 11);
    final first = await service.markFirstViewed(
      cardId: hierarchy.id,
      viewedAt: firstAt,
    );
    final second = await service.markFirstViewed(
      cardId: hierarchy.id,
      viewedAt: secondAt,
    );

    expect(first.isFirstViewed, isTrue);
    expect(first.firstViewedAt, firstAt);
    expect(second.firstViewedAt, firstAt);
  });

  test('collection statistics separate ownership, view and reinforcement', () async {
    final repository = MemoryFlashcardCollectionRepository();
    final service = FlashcardUnlockService(
      repository: repository,
      userIdOverride: 'learner-stats',
    );

    await service.apply(
      card: hierarchy,
      request: FlashcardUnlockRequest(
        eventId: 'quiz:stats:one',
        cardId: hierarchy.id,
        conceptId: hierarchy.conceptId,
        source: FlashcardAcquisitionSource.questionCompletion,
        questionOutcome: FlashcardQuestionOutcome.correct,
        questionId: 930001,
      ),
    );
    await service.apply(
      card: hierarchy,
      request: FlashcardUnlockRequest(
        eventId: 'quiz:stats:two',
        cardId: hierarchy.id,
        conceptId: hierarchy.conceptId,
        source: FlashcardAcquisitionSource.questionCompletion,
        questionOutcome: FlashcardQuestionOutcome.incorrect,
        questionId: 930001,
      ),
    );
    await service.apply(
      card: elimination,
      request: FlashcardUnlockRequest(
        eventId: 'daily:stats',
        cardId: elimination.id,
        conceptId: elimination.conceptId,
        source: FlashcardAcquisitionSource.dailyDiscovery,
        questionOutcome: FlashcardQuestionOutcome.notApplicable,
      ),
    );
    await service.markFirstViewed(cardId: hierarchy.id);

    final stats = await service.statistics();

    expect(stats.totalOwned, 2);
    expect(stats.unseenCount, 1);
    expect(stats.firstViewedCount, 1);
    expect(stats.totalReinforcements, 1);
    expect(stats.questionAcquiredCount, 1);
    expect(stats.dailyDiscoveryAcquiredCount, 1);
    expect(stats.correctSignalCount, 1);
    expect(stats.incorrectSignalCount, 1);
  });

  test('the same card is isolated between learner namespaces', () async {
    final repository = MemoryFlashcardCollectionRepository();
    final a = FlashcardUnlockService(
      repository: repository,
      userIdOverride: 'learner-a',
    );
    final b = FlashcardUnlockService(
      repository: repository,
      userIdOverride: 'learner-b',
    );

    for (final service in <FlashcardUnlockService>[a, b]) {
      await service.apply(
        card: hierarchy,
        request: FlashcardUnlockRequest(
          eventId: 'quiz:shared-id',
          cardId: hierarchy.id,
          conceptId: hierarchy.conceptId,
          source: FlashcardAcquisitionSource.questionCompletion,
          questionOutcome: FlashcardQuestionOutcome.correct,
          questionId: 930001,
        ),
      );
    }

    expect(await a.loadCollection(), hasLength(1));
    expect(await b.loadCollection(), hasLength(1));
  });
}
