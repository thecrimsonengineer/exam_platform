import 'package:exam_platform/features/flashcards/flashcards.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('1000-card due deck remains deterministic unique and bounded', () {
    const count = 1000;
    final now = DateTime.utc(2026, 9, 21, 12);
    final activated = now.subtract(const Duration(days: 7));

    final cards = <String, Flashcard>{};
    final ownership = <String, FlashcardOwnership>{};
    final reviews = <FlashcardReviewState>[];

    for (var index = 0; index < count; index++) {
      final suffix = index.toString().padLeft(4, '0');
      final cardId = 'csp11.flashcard.fc8_large_$suffix';
      final conceptId = 'csp11.concept.fc8_large_$suffix';
      final domain = (index % 7) + 1;
      final competency = (index % 6) + 1;

      final card = Flashcard(
        id: cardId,
        conceptId: conceptId,
        version: 1,
        type: FlashcardType.concept,
        frontLabel: 'FC8 large deck $suffix',
        backDefinition: 'Synthetic deterministic large-deck evidence.',
        primaryPlacement: FlashcardPlacement(
          domainId: 'd${domain.toString().padLeft(2, '0')}',
          competencyId:
              'd${domain.toString().padLeft(2, '0')}_c${competency.toString().padLeft(2, '0')}',
          topicId: 'topic_${index % 20}',
          subtopicId: 'subtopic_${index % 100}',
        ),
      );
      cards[cardId] = card;

      ownership[cardId] = FlashcardOwnership(
        cardId: cardId,
        conceptId: conceptId,
        acquiredAt: activated.subtract(const Duration(hours: 1)),
        acquisitionSource: FlashcardAcquisitionSource.dailyDiscovery,
        firstQuestionOutcome: FlashcardQuestionOutcome.notApplicable,
        firstViewedAt: activated,
        appliedEventIds: <String>['fc8-large-$suffix'],
      );

      reviews.add(
        FlashcardReviewState(
          cardId: cardId,
          conceptId: conceptId,
          activatedAt: activated,
          stage: FlashcardReviewStage.review,
          dueAt: now.subtract(Duration(minutes: count - index)),
          intervalMinutes: 24 * 60,
        ),
      );
    }

    const builder = FlashcardReviewSessionBuilder();
    final first = builder.build(
      reviewStates: reviews,
      cardsById: cards,
      ownershipByCardId: ownership,
      now: now,
      maxCards: count,
    );
    final second = builder.build(
      reviewStates: reviews.reversed,
      cardsById: cards,
      ownershipByCardId: ownership,
      now: now,
      maxCards: count,
    );
    final bounded = builder.build(
      reviewStates: reviews,
      cardsById: cards,
      ownershipByCardId: ownership,
      now: now,
      maxCards: 20,
    );

    expect(first.length, count);
    expect(first.cardIds.toSet().length, count);
    expect(second.cardIds, first.cardIds);
    expect(bounded.length, 20);
    expect(bounded.cardIds, first.cardIds.take(20).toList());
  });
}
