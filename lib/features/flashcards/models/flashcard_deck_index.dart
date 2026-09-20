import 'flashcard_content_package.dart';
import 'flashcard_lifecycle.dart';

class FlashcardDeckIndexEntry {
  const FlashcardDeckIndexEntry({
    required this.deckId,
    required this.domainId,
    required this.competencyId,
    required this.title,
    required this.version,
    required this.lifecycle,
    required this.cardCount,
    required this.conceptCount,
    required this.mappingCount,
  });

  final String deckId;
  final String domainId;
  final String competencyId;
  final String title;
  final int version;
  final FlashcardLifecycle lifecycle;
  final int cardCount;
  final int conceptCount;
  final int mappingCount;

  factory FlashcardDeckIndexEntry.fromPackage(
    FlashcardContentPackage contentPackage,
  ) {
    return FlashcardDeckIndexEntry(
      deckId: contentPackage.deck.id,
      domainId: contentPackage.deck.domainId,
      competencyId: contentPackage.deck.competencyId,
      title: contentPackage.deck.title,
      version: contentPackage.deck.version,
      lifecycle: contentPackage.deck.lifecycle,
      cardCount: contentPackage.cards.length,
      conceptCount: contentPackage.concepts.length,
      mappingCount: contentPackage.questionMappings.length,
    );
  }
}

class FlashcardDeckIndex {
  const FlashcardDeckIndex(this.entries);

  final List<FlashcardDeckIndexEntry> entries;

  int get deckCount => entries.length;

  int get cardCount =>
      entries.fold<int>(0, (sum, entry) => sum + entry.cardCount);

  int get conceptCount =>
      entries.fold<int>(0, (sum, entry) => sum + entry.conceptCount);

  int get mappingCount =>
      entries.fold<int>(0, (sum, entry) => sum + entry.mappingCount);
}
