import 'package:exam_platform/features/flashcards/flashcards.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const policy = FlashcardIntervalPolicy();
  final activated = DateTime.utc(2026, 9, 20, 8);

  FlashcardReviewState state({
    FlashcardReviewStage stage = FlashcardReviewStage.learning,
    int intervalMinutes = FlashcardIntervalPolicy.initialIntervalMinutes,
    int gotItStreak = 0,
  }) {
    return FlashcardReviewState(
      cardId: 'csp11.flashcard.test',
      conceptId: 'csp11.concept.test',
      activatedAt: activated,
      stage: stage,
      dueAt: activated.add(Duration(minutes: intervalMinutes)),
      intervalMinutes: intervalMinutes,
      gotItStreak: gotItStreak,
    );
  }

  test('Again always enters 10-minute relearning', () {
    final decision = policy.next(
      current: state(stage: FlashcardReviewStage.review),
      rating: FlashcardReviewRating.again,
    );

    expect(decision.stage, FlashcardReviewStage.relearning);
    expect(
      decision.intervalMinutes,
      FlashcardIntervalPolicy.relearningIntervalMinutes,
    );
    expect(decision.lapseDelta, 1);
    expect(decision.nextGotItStreak, 0);
  });

  test('Hard starts at one day and later scales by 1.5', () {
    final initial = policy.next(
      current: state(),
      rating: FlashcardReviewRating.hard,
    );
    expect(
      initial.intervalMinutes,
      FlashcardIntervalPolicy.hardInitialIntervalMinutes,
    );

    final later = policy.next(
      current: state(
        stage: FlashcardReviewStage.review,
        intervalMinutes: 4 * 24 * 60,
      ),
      rating: FlashcardReviewRating.hard,
    );
    expect(later.intervalMinutes, 6 * 24 * 60);
  });

  test('Got It starts at three days and later scales by 2.5', () {
    final initial = policy.next(
      current: state(),
      rating: FlashcardReviewRating.gotIt,
    );
    expect(
      initial.intervalMinutes,
      FlashcardIntervalPolicy.gotItInitialIntervalMinutes,
    );

    final later = policy.next(
      current: state(
        stage: FlashcardReviewStage.review,
        intervalMinutes: 4 * 24 * 60,
        gotItStreak: 1,
      ),
      rating: FlashcardReviewRating.gotIt,
    );
    expect(later.intervalMinutes, 10 * 24 * 60);
    expect(later.nextGotItStreak, 2);
  });

  test('interval growth is capped at 365 days', () {
    final decision = policy.next(
      current: state(
        stage: FlashcardReviewStage.review,
        intervalMinutes: FlashcardIntervalPolicy.maximumIntervalMinutes,
      ),
      rating: FlashcardReviewRating.gotIt,
    );

    expect(
      decision.intervalMinutes,
      FlashcardIntervalPolicy.maximumIntervalMinutes,
    );
  });
}
