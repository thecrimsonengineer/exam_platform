import 'flashcard_review_state.dart';

class FlashcardIntervalDecision {
  const FlashcardIntervalDecision({
    required this.stage,
    required this.intervalMinutes,
    required this.lapseDelta,
    required this.nextGotItStreak,
  });

  final FlashcardReviewStage stage;
  final int intervalMinutes;
  final int lapseDelta;
  final int nextGotItStreak;
}

class FlashcardIntervalPolicy {
  const FlashcardIntervalPolicy();

  static const int initialIntervalMinutes = 24 * 60;
  static const int relearningIntervalMinutes = 10;
  static const int hardInitialIntervalMinutes = 24 * 60;
  static const int gotItInitialIntervalMinutes = 3 * 24 * 60;
  static const int maximumIntervalMinutes = 365 * 24 * 60;

  FlashcardIntervalDecision next({
    required FlashcardReviewState current,
    required FlashcardReviewRating rating,
  }) {
    return switch (rating) {
      FlashcardReviewRating.again => const FlashcardIntervalDecision(
        stage: FlashcardReviewStage.relearning,
        intervalMinutes: relearningIntervalMinutes,
        lapseDelta: 1,
        nextGotItStreak: 0,
      ),
      FlashcardReviewRating.hard => FlashcardIntervalDecision(
        stage: FlashcardReviewStage.review,
        intervalMinutes: current.stage == FlashcardReviewStage.review
            ? _scale(
                current.intervalMinutes,
                numerator: 3,
                denominator: 2,
                minimum: hardInitialIntervalMinutes,
              )
            : hardInitialIntervalMinutes,
        lapseDelta: 0,
        nextGotItStreak: 0,
      ),
      FlashcardReviewRating.gotIt => FlashcardIntervalDecision(
        stage: FlashcardReviewStage.review,
        intervalMinutes: current.stage == FlashcardReviewStage.review
            ? _scale(
                current.intervalMinutes,
                numerator: 5,
                denominator: 2,
                minimum: gotItInitialIntervalMinutes,
              )
            : gotItInitialIntervalMinutes,
        lapseDelta: 0,
        nextGotItStreak: current.gotItStreak + 1,
      ),
    };
  }

  static int _scale(
    int current, {
    required int numerator,
    required int denominator,
    required int minimum,
  }) {
    final scaled = ((current * numerator) / denominator).round();
    final bounded = scaled < minimum ? minimum : scaled;
    return bounded > maximumIntervalMinutes ? maximumIntervalMinutes : bounded;
  }
}
