import 'package:exam_platform/features/flashcards/registry/flashcard_ids.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('semantic Concept and Flashcard IDs use the frozen formats', () {
    expect(
      FlashcardIds.isValidConceptId('csp11.concept.hierarchy_of_controls'),
      isTrue,
    );
    expect(
      FlashcardIds.isValidFlashcardId(
        'csp11.flashcard.hierarchy_of_controls',
      ),
      isTrue,
    );
    expect(
      FlashcardIds.expectedFlashcardIdForConcept(
        'csp11.concept.hierarchy_of_controls',
      ),
      'csp11.flashcard.hierarchy_of_controls',
    );

    expect(
      FlashcardIds.isValidConceptId('csp11.concept.Hierarchy-Of-Controls'),
      isFalse,
    );
    expect(
      FlashcardIds.isValidFlashcardId('d03_c02_fc001'),
      isFalse,
    );
  });

  test('deck identity carries competency and version', () {
    const id = 'd03_c02_flashcards_v7';

    expect(FlashcardIds.isValidDeckId(id), isTrue);
    expect(FlashcardIds.deckCompetencyId(id), 'd03_c02');
    expect(FlashcardIds.deckVersion(id), 7);
  });
}
