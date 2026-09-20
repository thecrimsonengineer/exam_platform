import 'flashcard_review_state.dart';

enum FlashcardReviewEventKind { applied, duplicateIgnored }

class FlashcardReviewEventResult {
  const FlashcardReviewEventResult({
    required this.eventId,
    required this.kind,
    required this.rating,
    required this.reviewedAt,
    required this.state,
  });

  final String eventId;
  final FlashcardReviewEventKind kind;
  final FlashcardReviewRating rating;
  final DateTime reviewedAt;
  final FlashcardReviewState state;

  bool get wasApplied => kind == FlashcardReviewEventKind.applied;
  bool get wasDuplicate => kind == FlashcardReviewEventKind.duplicateIgnored;
}
