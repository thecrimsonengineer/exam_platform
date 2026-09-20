import '../collection/flashcard_ownership.dart';
import '../models/flashcard.dart';
import 'flashcard_review_state.dart';
import 'flashcard_weak_card_policy.dart';

class FlashcardReviewSessionPlan {
  const FlashcardReviewSessionPlan(this.cardIds);

  final List<String> cardIds;

  bool get isEmpty => cardIds.isEmpty;
  int get length => cardIds.length;
}

class FlashcardReviewSessionBuilder {
  const FlashcardReviewSessionBuilder({
    FlashcardWeakCardPolicy weakCardPolicy = const FlashcardWeakCardPolicy(),
  }) : _weakCardPolicy = weakCardPolicy;

  final FlashcardWeakCardPolicy _weakCardPolicy;

  FlashcardReviewSessionPlan build({
    required Iterable<FlashcardReviewState> reviewStates,
    required Map<String, Flashcard> cardsById,
    required Map<String, FlashcardOwnership> ownershipByCardId,
    required DateTime now,
    int maxCards = 20,
  }) {
    if (maxCards <= 0) {
      throw ArgumentError.value(maxCards, 'maxCards', 'Must be positive.');
    }

    final candidates = <_ReviewCandidate>[];
    for (final review in reviewStates) {
      if (!review.isDue(now)) {
        continue;
      }

      final card = cardsById[review.cardId];
      if (card == null) {
        throw FormatException(
          'Review state references missing Flashcard: ${review.cardId}',
        );
      }
      if (card.conceptId != review.conceptId) {
        throw FormatException(
          'Review state Concept mismatch for ${review.cardId}.',
        );
      }

      final ownership = ownershipByCardId[review.cardId];
      if (ownership == null) {
        throw FormatException(
          'Review state references unowned Flashcard: ${review.cardId}',
        );
      }
      if (ownership.firstViewedAt == null) {
        throw FormatException(
          'Review state exists before first reveal: ${review.cardId}',
        );
      }

      final weakness = _weakCardPolicy.assess(
        review: review,
        ownership: ownership,
      );
      candidates.add(
        _ReviewCandidate(
          review: review,
          card: card,
          weakScore: weakness.score,
          siblingKey: _siblingKey(card),
        ),
      );
    }

    candidates.sort((a, b) {
      final weak = b.weakScore.compareTo(a.weakScore);
      if (weak != 0) {
        return weak;
      }
      final due = a.review.dueAt.compareTo(b.review.dueAt);
      if (due != 0) {
        return due;
      }
      return a.review.cardId.compareTo(b.review.cardId);
    });

    final remaining = candidates.toList();
    final ordered = <String>[];
    String? lastConceptId;
    String? lastSiblingKey;

    while (remaining.isNotEmpty && ordered.length < maxCards) {
      var index = remaining.indexWhere(
        (candidate) =>
            candidate.review.conceptId != lastConceptId &&
            candidate.siblingKey != lastSiblingKey,
      );

      if (index < 0) {
        index = remaining.indexWhere(
          (candidate) => candidate.review.conceptId != lastConceptId,
        );
      }
      if (index < 0) {
        index = 0;
      }

      final selected = remaining.removeAt(index);
      ordered.add(selected.review.cardId);
      lastConceptId = selected.review.conceptId;
      lastSiblingKey = selected.siblingKey;
    }

    return FlashcardReviewSessionPlan(List.unmodifiable(ordered));
  }

  static String _siblingKey(Flashcard card) {
    final placement = card.primaryPlacement;
    if (placement.subtopicId.isNotEmpty) {
      return 'subtopic:${placement.subtopicId}';
    }
    if (placement.topicId.isNotEmpty) {
      return 'topic:${placement.topicId}';
    }
    return 'competency:${placement.competencyId}';
  }
}

class _ReviewCandidate {
  const _ReviewCandidate({
    required this.review,
    required this.card,
    required this.weakScore,
    required this.siblingKey,
  });

  final FlashcardReviewState review;
  final Flashcard card;
  final int weakScore;
  final String siblingKey;
}
