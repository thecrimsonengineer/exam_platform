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

  FlashcardDeckValidationResult validate(
    FlashcardContentPackage contentPackage,
  ) {
    final issues = <String>[];

    try {
      FlashcardConceptCatalog.build(
        concepts: contentPackage.concepts,
        cards: contentPackage.cards,
        questionMappings: contentPackage.questionMappings,
        decks: [contentPackage.deck],
      );
    } on FormatException catch (error) {
      issues.add(error.message.toString());
    }

    final packagedCardIds = contentPackage.cards.map((card) => card.id).toSet();
    final deckCardIds = contentPackage.deck.cardIds.toSet();

    if (packagedCardIds.length != contentPackage.cards.length) {
      issues.add('Package contains duplicate Flashcard IDs.');
    }

    if (deckCardIds.length != contentPackage.deck.cardIds.length) {
      issues.add('Deck repeats one or more Flashcard IDs.');
    }

    if (packagedCardIds.difference(deckCardIds).isNotEmpty ||
        deckCardIds.difference(packagedCardIds).isNotEmpty) {
      issues.add('Deck cardIds must match the packaged Flashcard set exactly.');
    }

    final conceptsById = {
      for (final concept in contentPackage.concepts) concept.id: concept,
    };
    for (final card in contentPackage.cards) {
      final concept = conceptsById[card.conceptId];
      if (concept == null) {
        continue;
      }
      final left = concept.primaryPlacement;
      final right = card.primaryPlacement;
      if (left.domainId != right.domainId ||
          left.competencyId != right.competencyId ||
          left.topicId != right.topicId ||
          left.subtopicId != right.subtopicId) {
        issues.add(
          'Concept ${concept.id} and card ${card.id} must share '
          'the same canonical placement.',
        );
      }
    }

    final duplicates = const FlashcardDuplicateDetector().inspect(
      contentPackage,
    );
    if (duplicates.hasBlockingDuplicates) {
      issues.add(
        'Package contains ${duplicates.findings.length} semantic duplicate '
        'finding(s).',
      );
    }

    return FlashcardDeckValidationResult(List.unmodifiable(issues));
  }
}
