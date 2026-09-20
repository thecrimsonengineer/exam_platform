import '../models/flashcard_content_package.dart';
import '../registry/flashcard_concept_catalog.dart';
import 'flashcard_duplicate_detector.dart';

class FlashcardDeckValidationResult {
  const FlashcardDeckValidationResult(this.issues);

  final List<String> issues;

  bool get passed => issues.isEmpty;
}

class FlashcardDeckValidator {
  const FlashcardDeckValidator();

  FlashcardDeckValidationResult validate(FlashcardContentPackage package) {
    final issues = <String>[];

    try {
      FlashcardConceptCatalog.build(
        concepts: package.concepts,
        cards: package.cards,
        questionMappings: package.questionMappings,
        decks: <dynamic>[package.deck],
      );
    } on FormatException catch (error) {
      issues.add(error.message.toString());
    }

    final packagedCardIds = package.cards.map((card) => card.id).toSet();
    final deckCardIds = package.deck.cardIds.toSet();

    if (packagedCardIds.length != package.cards.length) {
      issues.add('Package contains duplicate Flashcard IDs.');
    }

    if (deckCardIds.length != package.deck.cardIds.length) {
      issues.add('Deck repeats one or more Flashcard IDs.');
    }

    if (packagedCardIds.difference(deckCardIds).isNotEmpty ||
        deckCardIds.difference(packagedCardIds).isNotEmpty) {
      issues.add(
        'Deck cardIds must match the packaged Flashcard set exactly.',
      );
    }

    final conceptsById = {
      for (final concept in package.concepts) concept.id: concept,
    };
    for (final card in package.cards) {
      final concept = conceptsById[card.conceptId];
      if (concept == null) {
        continue;
      }
      if (concept.primaryPlacement.toJson().toString() !=
          card.primaryPlacement.toJson().toString()) {
        issues.add(
          'Concept ${concept.id} and card ${card.id} must share '
          'the same canonical placement.',
        );
      }
    }

    final duplicates = const FlashcardDuplicateDetector().inspect(package);
    if (duplicates.hasBlockingDuplicates) {
      issues.add(
        'Package contains ${duplicates.findings.length} semantic duplicate '
        'finding(s).',
      );
    }

    return FlashcardDeckValidationResult(List.unmodifiable(issues));
  }
}
