import '../collection/flashcard_ownership.dart';
import 'flashcard_review_state.dart';

class FlashcardWeakCardAssessment {
  const FlashcardWeakCardAssessment({
    required this.score,
    required this.isWeak,
  });

  final int score;
  final bool isWeak;
}

class FlashcardWeakCardPolicy {
  const FlashcardWeakCardPolicy();

  static const int weakThreshold = 4;

  FlashcardWeakCardAssessment assess({
    required FlashcardReviewState review,
    FlashcardOwnership? ownership,
  }) {
    var score = 0;

    if (review.stage == FlashcardReviewStage.relearning) {
      score += 4;
    }

    final lapseScore = review.lapseCount * 2;
    score += lapseScore > 6 ? 6 : lapseScore;

    if (review.lastRating == FlashcardReviewRating.again) {
      score += 3;
    }

    if (ownership != null) {
      final incorrectLead =
          ownership.incorrectSignalCount - ownership.correctSignalCount;
      if (incorrectLead > 0) {
        score += incorrectLead > 3 ? 3 : incorrectLead;
      }
    }

    return FlashcardWeakCardAssessment(
      score: score,
      isWeak: score >= weakThreshold,
    );
  }
}
