import '../collection/flashcard_ownership.dart';
import 'flashcard_review_state.dart';
import 'flashcard_weak_card_policy.dart';

class FlashcardMemoryStatistics {
  const FlashcardMemoryStatistics({
    required this.activeCount,
    required this.dueCount,
    required this.learningCount,
    required this.reviewStageCount,
    required this.relearningCount,
    required this.weakCount,
    required this.totalReviewEvents,
    required this.totalLapses,
    required this.averageIntervalMinutes,
  });

  final int activeCount;
  final int dueCount;
  final int learningCount;
  final int reviewStageCount;
  final int relearningCount;
  final int weakCount;
  final int totalReviewEvents;
  final int totalLapses;
  final double averageIntervalMinutes;

  factory FlashcardMemoryStatistics.build({
    required Iterable<FlashcardReviewState> reviews,
    required DateTime now,
    Map<String, FlashcardOwnership> ownershipByCardId =
        const <String, FlashcardOwnership>{},
    FlashcardWeakCardPolicy weakCardPolicy = const FlashcardWeakCardPolicy(),
  }) {
    var activeCount = 0;
    var dueCount = 0;
    var learningCount = 0;
    var reviewStageCount = 0;
    var relearningCount = 0;
    var weakCount = 0;
    var totalReviewEvents = 0;
    var totalLapses = 0;
    var totalIntervalMinutes = 0;

    for (final review in reviews) {
      activeCount++;
      if (review.isDue(now)) {
        dueCount++;
      }

      if (review.stage == FlashcardReviewStage.learning) {
        learningCount++;
      } else if (review.stage == FlashcardReviewStage.review) {
        reviewStageCount++;
      } else if (review.stage == FlashcardReviewStage.relearning) {
        relearningCount++;
      }

      final weak = weakCardPolicy.assess(
        review: review,
        ownership: ownershipByCardId[review.cardId],
      );
      if (weak.isWeak) {
        weakCount++;
      }

      totalReviewEvents += review.reviewCount;
      totalLapses += review.lapseCount;
      totalIntervalMinutes += review.intervalMinutes;
    }

    return FlashcardMemoryStatistics(
      activeCount: activeCount,
      dueCount: dueCount,
      learningCount: learningCount,
      reviewStageCount: reviewStageCount,
      relearningCount: relearningCount,
      weakCount: weakCount,
      totalReviewEvents: totalReviewEvents,
      totalLapses: totalLapses,
      averageIntervalMinutes: activeCount == 0
          ? 0
          : totalIntervalMinutes / activeCount,
    );
  }
}
