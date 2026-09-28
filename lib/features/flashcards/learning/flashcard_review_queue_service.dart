import '../cloud/published_flashcard_package.dart';
import 'flashcard_recall_event.dart';

class FlashcardReviewQueueService {
  const FlashcardReviewQueueService();

  List<FlashcardCard> build({
    required Iterable<FlashcardCard> cards,
    required Iterable<FlashcardRecallEvent> history,
    required DateTime now,
    required int targetCardCount,
    bool dueOnly = false,
    bool weakOnly = false,
  }) {
    final source = cards.toList(growable: false);
    if (source.isEmpty) return const <FlashcardCard>[];

    final latest = <String, FlashcardRecallEvent>{};
    for (final event in history) {
      final current = latest[event.cardId];
      if (current == null || event.occurredAt.isAfter(current.occurredAt)) {
        latest[event.cardId] = event;
      }
    }

    bool due(FlashcardCard card) {
      final event = latest[card.id];
      return event == null || !event.nextReviewAt.isAfter(now);
    }

    bool weak(FlashcardCard card) {
      final event = latest[card.id];
      return event == null || event.rating != FlashcardRecallRating.gotIt;
    }

    final ranked = source.toList(growable: false)
      ..sort((left, right) {
        final leftEvent = latest[left.id];
        final rightEvent = latest[right.id];
        final leftDue = due(left);
        final rightDue = due(right);
        if (leftDue != rightDue) return leftDue ? -1 : 1;

        final leftWeak = weak(left);
        final rightWeak = weak(right);
        if (leftWeak != rightWeak) return leftWeak ? -1 : 1;

        if (leftEvent == null && rightEvent != null) return -1;
        if (leftEvent != null && rightEvent == null) return 1;
        if (leftEvent != null && rightEvent != null) {
          final reviewOrder = leftEvent.nextReviewAt.compareTo(
            rightEvent.nextReviewAt,
          );
          if (reviewOrder != 0) return reviewOrder;
        }
        return source.indexOf(left).compareTo(source.indexOf(right));
      });

    var eligible = ranked.where((card) {
      if (dueOnly && !due(card)) return false;
      if (weakOnly && !weak(card)) return false;
      return true;
    }).toList(growable: false);

    // Unseen cards are always considered due. If a strict filter returns no
    // cards because every learned card is still ahead of its interval, keep the
    // session safe and empty instead of inventing extra review credit.
    if (eligible.isEmpty && !dueOnly && !weakOnly) {
      eligible = ranked;
    }

    final requested = targetCardCount <= 0
        ? eligible.length
        : targetCardCount.clamp(1, eligible.length).toInt();
    return List<FlashcardCard>.unmodifiable(eligible.take(requested));
  }
}
