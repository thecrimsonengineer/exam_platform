import 'package:exam_platform/features/flashcards/flashcards.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const placement = FlashcardPlacement(
    domainId: 'd03',
    competencyId: 'd03_c02',
    topicId: 'd03_c02_t01',
    subtopicId: 'd03_c02_t01_s01',
  );

  test('Flashcard JSON preserves the Run 1 contract', () {
    const card = Flashcard(
      id: 'csp11.flashcard.hierarchy_of_controls',
      conceptId: 'csp11.concept.hierarchy_of_controls',
      version: 2,
      type: FlashcardType.concept,
      frontLabel: 'Hierarchy of Controls',
      backDefinition: 'A framework for prioritizing hazard controls.',
      whyItMatters: 'More effective controls act closer to the hazard.',
      keyPoint: 'Prefer higher-order controls where feasible.',
      primaryPlacement: placement,
      sourceRefs: <FlashcardSourceRef>[
        FlashcardSourceRef(
          sourceId: 'SRC-FC-RUN2-PENDING',
          locator: 'placeholder',
          primary: true,
        ),
      ],
      lifecycle: FlashcardLifecycle.review,
      tags: <String>['risk-management', 'controls'],
    );

    final decoded = Flashcard.fromJson(card.toJson());

    expect(decoded.id, card.id);
    expect(decoded.conceptId, card.conceptId);
    expect(decoded.version, 2);
    expect(decoded.type, FlashcardType.concept);
    expect(decoded.frontLabel, 'Hierarchy of Controls');
    expect(decoded.primaryPlacement.subtopicId, 'd03_c02_t01_s01');
    expect(decoded.sourceRefs.single.primary, isTrue);
    expect(decoded.lifecycle, FlashcardLifecycle.review);
    expect(decoded.tags, <String>['risk-management', 'controls']);
  });

  test('Concept, deck and question mapping JSON preserve identity', () {
    const concept = FlashcardConcept(
      id: 'csp11.concept.hierarchy_of_controls',
      canonicalLabel: 'Hierarchy of Controls',
      flashcardId: 'csp11.flashcard.hierarchy_of_controls',
      primaryPlacement: placement,
      aliases: <String>['control hierarchy'],
    );

    const deck = FlashcardDeck(
      id: 'd03_c02_flashcards_v1',
      domainId: 'd03',
      competencyId: 'd03_c02',
      title: 'Risk Management Concept Cards',
      version: 1,
      cardIds: <String>['csp11.flashcard.hierarchy_of_controls'],
    );

    const mapping = QuestionConceptMapping(
      questionId: 900001,
      conceptId: 'csp11.concept.hierarchy_of_controls',
    );

    expect(
      FlashcardConcept.fromJson(concept.toJson()).flashcardId,
      concept.flashcardId,
    );
    expect(FlashcardDeck.fromJson(deck.toJson()).cardIds, deck.cardIds);
    expect(
      QuestionConceptMapping.fromJson(mapping.toJson()).conceptId,
      mapping.conceptId,
    );
  });
}
