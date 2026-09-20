import 'dart:convert';
import 'dart:io';

import 'package:exam_platform/features/flashcards/flashcards.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Run 1 reference fixture satisfies Question -> Concept -> Card contract', () {
    final raw = File(
      'assets/flashcards/run1/fc_reference_registry.v1.json',
    ).readAsStringSync();
    final decoded = jsonDecode(raw);

    expect(decoded, isA<Map>());

    final json = Map<String, dynamic>.from(decoded as Map);
    expect(json['schemaVersion'], 'csp11.flashcards.v1');

    final deck = FlashcardDeck.fromJson(
      Map<String, dynamic>.from(json['deck'] as Map),
    );

    final concepts = (json['concepts'] as List)
        .whereType<Map>()
        .map(
          (item) => FlashcardConcept.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();

    final cards = (json['cards'] as List)
        .whereType<Map>()
        .map(
          (item) => Flashcard.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();

    final mappings = (json['questionMappings'] as List)
        .whereType<Map>()
        .map(
          (item) => QuestionConceptMapping.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();

    final catalog = FlashcardConceptCatalog.build(
      concepts: concepts,
      cards: cards,
      questionMappings: mappings,
      decks: <FlashcardDeck>[deck],
    );

    expect(catalog.conceptCount, 1);
    expect(catalog.cardCount, 1);
    expect(catalog.questionMappingCount, 2);
    expect(
      catalog.cardForQuestion(900001)?.frontLabel,
      'Hierarchy of Controls',
    );
    expect(
      catalog.cardForQuestion(900002)?.frontLabel,
      'Hierarchy of Controls',
    );
  });
}
