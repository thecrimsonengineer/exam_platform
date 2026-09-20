import 'package:exam_platform/features/flashcards/flashcards.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  FlashcardReviewState reviewState(String cardId, String conceptId) {
    final activated = DateTime.utc(2026, 9, 20, 8);
    return FlashcardReviewState(
      cardId: cardId,
      conceptId: conceptId,
      activatedAt: activated,
      stage: FlashcardReviewStage.learning,
      dueAt: activated.add(const Duration(days: 1)),
      intervalMinutes: FlashcardIntervalPolicy.initialIntervalMinutes,
    );
  }

  test('review repository is learner-scoped and card-sharded', () async {
    final repository = SharedPreferencesFlashcardReviewRepository();
    final state = reviewState(
      'csp11.flashcard.hierarchy_of_controls',
      'csp11.concept.hierarchy_of_controls',
    );

    await repository.save(learnerId: 'learner-a', state: state);
    await repository.save(learnerId: 'learner-b', state: state);

    expect(await repository.loadAll(learnerId: 'learner-a'), hasLength(1));
    expect(await repository.loadAll(learnerId: 'learner-b'), hasLength(1));

    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString(
        SharedPreferencesFlashcardReviewRepository.stateKeyForLearner(
          learnerId: 'learner-a',
          cardId: state.cardId,
        ),
      ),
      isNotNull,
    );

    await repository.delete(learnerId: 'learner-a', cardId: state.cardId);
    expect(await repository.loadAll(learnerId: 'learner-a'), isEmpty);
    expect(await repository.loadAll(learnerId: 'learner-b'), hasLength(1));
  });

  test('review state rejects rating/event count drift', () {
    final state = reviewState('csp11.flashcard.test', 'csp11.concept.test');
    final json = state.toJson();
    json['reviewCount'] = 1;

    expect(() => FlashcardReviewState.fromJson(json), throwsFormatException);
  });

  test('session repository persists resumable learner state', () async {
    final repository = SharedPreferencesFlashcardReviewSessionRepository();
    final now = DateTime.utc(2026, 9, 20, 9);
    final state = FlashcardReviewSessionState(
      sessionId: 'session-1',
      createdAt: now,
      updatedAt: now,
      cardIds: const <String>['csp11.flashcard.one', 'csp11.flashcard.two'],
      nextIndex: 1,
      status: FlashcardReviewSessionStatus.active,
    );

    await repository.save(learnerId: 'learner-a', state: state);

    final loaded = await repository.load(
      learnerId: 'learner-a',
      sessionId: 'session-1',
    );
    expect(loaded?.nextIndex, 1);
    expect(loaded?.currentCardId, 'csp11.flashcard.two');
    expect(await repository.listSessionIds(learnerId: 'learner-a'), <String>[
      'session-1',
    ]);
    expect(
      await repository.load(learnerId: 'learner-b', sessionId: 'session-1'),
      isNull,
    );
  });
}
