import 'package:exam_platform/features/flashcards/flashcards.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const placement = FlashcardPlacement(
    domainId: 'd03',
    competencyId: 'd03_c02',
  );

  const concept = FlashcardConcept(
    id: 'csp11.concept.hierarchy_of_controls',
    canonicalLabel: 'Hierarchy of Controls',
    flashcardId: 'csp11.flashcard.hierarchy_of_controls',
    primaryPlacement: placement,
  );

  const card = Flashcard(
    id: 'csp11.flashcard.hierarchy_of_controls',
    conceptId: 'csp11.concept.hierarchy_of_controls',
    version: 1,
    type: FlashcardType.concept,
    frontLabel: 'Hierarchy of Controls',
    backDefinition: 'A framework for prioritizing hazard controls.',
    primaryPlacement: placement,
  );

  const deck = FlashcardDeck(
    id: 'd03_c02_flashcards_v1',
    domainId: 'd03',
    competencyId: 'd03_c02',
    title: 'Risk Management Concept Cards',
    version: 1,
    cardIds: <String>['csp11.flashcard.hierarchy_of_controls'],
  );

  test('many questions can resolve to one Concept and one canonical card', () {
    final catalog = FlashcardConceptCatalog.build(
      concepts: const <FlashcardConcept>[concept],
      cards: const <Flashcard>[card],
      decks: const <FlashcardDeck>[deck],
      questionMappings: const <QuestionConceptMapping>[
        QuestionConceptMapping(
          questionId: 900001,
          conceptId: 'csp11.concept.hierarchy_of_controls',
        ),
        QuestionConceptMapping(
          questionId: 900002,
          conceptId: 'csp11.concept.hierarchy_of_controls',
        ),
      ],
    );

    expect(catalog.conceptCount, 1);
    expect(catalog.cardCount, 1);
    expect(catalog.questionMappingCount, 2);
    expect(
      catalog.cardForQuestion(900001)?.id,
      'csp11.flashcard.hierarchy_of_controls',
    );
    expect(
      catalog.cardForQuestion(900002)?.id,
      'csp11.flashcard.hierarchy_of_controls',
    );
  });

  test('question-like learner fronts fail closed', () {
    const questionCard = Flashcard(
      id: 'csp11.flashcard.hierarchy_of_controls',
      conceptId: 'csp11.concept.hierarchy_of_controls',
      version: 1,
      type: FlashcardType.concept,
      frontLabel: 'What is the Hierarchy of Controls?',
      backDefinition: 'A framework for prioritizing hazard controls.',
      primaryPlacement: placement,
    );

    expect(
      () => FlashcardConceptCatalog.build(
        concepts: const <FlashcardConcept>[concept],
        cards: const <Flashcard>[questionCard],
        questionMappings: const <QuestionConceptMapping>[],
      ),
      throwsFormatException,
    );
  });

  test('duplicate Concept IDs fail closed', () {
    expect(
      () => FlashcardConceptCatalog.build(
        concepts: const <FlashcardConcept>[concept, concept],
        cards: const <Flashcard>[card],
        questionMappings: const <QuestionConceptMapping>[],
      ),
      throwsFormatException,
    );
  });

  test('duplicate Flashcard IDs fail closed', () {
    expect(
      () => FlashcardConceptCatalog.build(
        concepts: const <FlashcardConcept>[concept],
        cards: const <Flashcard>[card, card],
        questionMappings: const <QuestionConceptMapping>[],
      ),
      throwsFormatException,
    );
  });

  test('duplicate Question mappings fail closed', () {
    expect(
      () => FlashcardConceptCatalog.build(
        concepts: const <FlashcardConcept>[concept],
        cards: const <Flashcard>[card],
        questionMappings: const <QuestionConceptMapping>[
          QuestionConceptMapping(
            questionId: 900001,
            conceptId: 'csp11.concept.hierarchy_of_controls',
          ),
          QuestionConceptMapping(
            questionId: 900001,
            conceptId: 'csp11.concept.hierarchy_of_controls',
          ),
        ],
      ),
      throwsFormatException,
    );
  });

  test('dangling Concept to Flashcard references fail closed', () {
    expect(
      () => FlashcardConceptCatalog.build(
        concepts: const <FlashcardConcept>[concept],
        cards: const <Flashcard>[],
        questionMappings: const <QuestionConceptMapping>[],
      ),
      throwsFormatException,
    );
  });

  test('dangling Question to Concept references fail closed', () {
    expect(
      () => FlashcardConceptCatalog.build(
        concepts: const <FlashcardConcept>[concept],
        cards: const <Flashcard>[card],
        questionMappings: const <QuestionConceptMapping>[
          QuestionConceptMapping(
            questionId: 900003,
            conceptId: 'csp11.concept.missing',
          ),
        ],
      ),
      throwsFormatException,
    );
  });

  test('unknown canonical competency fails closed', () {
    const badPlacement = FlashcardPlacement(
      domainId: 'd03',
      competencyId: 'd03_c99',
    );

    const badConcept = FlashcardConcept(
      id: 'csp11.concept.hierarchy_of_controls',
      canonicalLabel: 'Hierarchy of Controls',
      flashcardId: 'csp11.flashcard.hierarchy_of_controls',
      primaryPlacement: badPlacement,
    );

    expect(
      () => FlashcardConceptCatalog.build(
        concepts: const <FlashcardConcept>[badConcept],
        cards: const <Flashcard>[card],
        questionMappings: const <QuestionConceptMapping>[],
      ),
      throwsFormatException,
    );
  });

  test('card and Concept semantic slugs must match', () {
    const wrongConcept = FlashcardConcept(
      id: 'csp11.concept.hierarchy_of_controls',
      canonicalLabel: 'Hierarchy of Controls',
      flashcardId: 'csp11.flashcard.risk_matrix',
      primaryPlacement: placement,
    );

    expect(
      () => FlashcardConceptCatalog.build(
        concepts: const <FlashcardConcept>[wrongConcept],
        cards: const <Flashcard>[card],
        questionMappings: const <QuestionConceptMapping>[],
      ),
      throwsFormatException,
    );
  });
}
