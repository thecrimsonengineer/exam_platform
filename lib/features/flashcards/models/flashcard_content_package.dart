import 'flashcard.dart';
import 'flashcard_concept.dart';
import 'flashcard_deck.dart';
import 'flashcard_source_provenance.dart';
import 'question_concept_mapping.dart';

class FlashcardContentPackage {
  const FlashcardContentPackage({
    required this.schemaVersion,
    required this.deck,
    required this.concepts,
    required this.cards,
    required this.questionMappings,
    required this.sources,
  });

  static const String currentSchemaVersion = 'csp11.flashcards.package.v1';

  final String schemaVersion;
  final FlashcardDeck deck;
  final List<FlashcardConcept> concepts;
  final List<Flashcard> cards;
  final List<QuestionConceptMapping> questionMappings;
  final List<FlashcardSourceRegistryEntry> sources;

  String get packageId => deck.id;

  factory FlashcardContentPackage.fromJson(Map<String, dynamic> json) {
    final rawDeck = json['deck'];
    if (rawDeck is! Map) {
      throw const FormatException('Flashcard package deck is required.');
    }

    return FlashcardContentPackage(
      schemaVersion: json['schemaVersion']?.toString() ?? '',
      deck: FlashcardDeck.fromJson(Map<String, dynamic>.from(rawDeck)),
      concepts: _decodeList(
        json['concepts'],
        (item) => FlashcardConcept.fromJson(item),
      ),
      cards: _decodeList(json['cards'], (item) => Flashcard.fromJson(item)),
      questionMappings: _decodeList(
        json['questionMappings'],
        (item) => QuestionConceptMapping.fromJson(item),
      ),
      sources: _decodeList(
        json['sources'],
        (item) => FlashcardSourceRegistryEntry.fromJson(item),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': schemaVersion,
      'deck': deck.toJson(),
      'concepts': concepts.map((item) => item.toJson()).toList(),
      'cards': cards.map((item) => item.toJson()).toList(),
      'questionMappings': questionMappings
          .map((item) => item.toJson())
          .toList(),
      'sources': sources.map((item) => item.toJson()).toList(),
    };
  }

  static List<T> _decodeList<T>(
    dynamic raw,
    T Function(Map<String, dynamic>) decode,
  ) {
    if (raw is! List) {
      return <T>[];
    }

    return raw
        .whereType<Map>()
        .map((item) => decode(Map<String, dynamic>.from(item)))
        .toList();
  }
}
