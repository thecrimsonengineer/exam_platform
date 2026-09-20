import 'package:exam_platform/features/flashcards/flashcards.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('SharedPreferences collection is learner-scoped and sharded', () async {
    final repository = SharedPreferencesFlashcardCollectionRepository();
    final acquiredAt = DateTime.utc(2026, 9, 20, 8);

    final ownership = FlashcardOwnership(
      cardId: 'csp11.flashcard.hierarchy_of_controls',
      conceptId: 'csp11.concept.hierarchy_of_controls',
      acquiredAt: acquiredAt,
      acquisitionSource: FlashcardAcquisitionSource.questionCompletion,
      firstQuestionOutcome: FlashcardQuestionOutcome.correct,
      correctSignalCount: 1,
      appliedEventIds: const <String>['quiz:a:930001'],
    );

    await repository.saveOwnership(
      learnerId: 'learner-a',
      ownership: ownership,
    );
    await repository.saveOwnership(
      learnerId: 'learner-b',
      ownership: ownership,
    );

    expect(
      await repository.loadAllOwnership(learnerId: 'learner-a'),
      hasLength(1),
    );
    expect(
      await repository.loadAllOwnership(learnerId: 'learner-b'),
      hasLength(1),
    );

    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getString(
        SharedPreferencesFlashcardCollectionRepository.ownershipKeyForLearner(
          learnerId: 'learner-a',
          cardId: ownership.cardId,
        ),
      ),
      isNotNull,
    );
    expect(
      preferences.getString(
        SharedPreferencesFlashcardCollectionRepository.ownershipKeyForLearner(
          learnerId: 'learner-b',
          cardId: ownership.cardId,
        ),
      ),
      isNotNull,
    );

    await repository.clearLearnerCollection(learnerId: 'learner-a');

    expect(await repository.loadAllOwnership(learnerId: 'learner-a'), isEmpty);
    expect(
      await repository.loadAllOwnership(learnerId: 'learner-b'),
      hasLength(1),
    );
  });

  test('ownership JSON round trip preserves unseen and event state', () {
    final ownership = FlashcardOwnership(
      cardId: 'csp11.flashcard.elimination_control',
      conceptId: 'csp11.concept.elimination_control',
      acquiredAt: DateTime.utc(2026, 9, 20, 9),
      acquisitionSource: FlashcardAcquisitionSource.dailyDiscovery,
      firstQuestionOutcome: FlashcardQuestionOutcome.notApplicable,
      reinforcementCount: 2,
      lastReinforcedAt: DateTime.utc(2026, 9, 21, 9),
      correctSignalCount: 1,
      incorrectSignalCount: 1,
      appliedEventIds: const <String>['daily:one', 'quiz:two'],
    );

    final decoded = FlashcardOwnership.fromJson(ownership.toJson());

    expect(decoded.cardId, ownership.cardId);
    expect(decoded.isUnseen, isTrue);
    expect(decoded.reinforcementCount, 2);
    expect(decoded.appliedEventIds, ownership.appliedEventIds);
  });

  test('duplicate applied event IDs fail closed on persisted ownership', () {
    final ownership = FlashcardOwnership(
      cardId: 'csp11.flashcard.elimination_control',
      conceptId: 'csp11.concept.elimination_control',
      acquiredAt: DateTime.utc(2026, 9, 20, 9),
      acquisitionSource: FlashcardAcquisitionSource.dailyDiscovery,
      firstQuestionOutcome: FlashcardQuestionOutcome.notApplicable,
      appliedEventIds: const <String>['daily:one'],
    );
    final json = ownership.toJson();
    json['appliedEventIds'] = <String>['daily:one', 'daily:one'];

    expect(() => FlashcardOwnership.fromJson(json), throwsFormatException);
  });
}
