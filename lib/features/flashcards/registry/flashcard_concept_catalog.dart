import '../../../data/csp11_blueprint.dart';
import '../models/flashcard.dart';
import '../models/flashcard_concept.dart';
import '../models/flashcard_deck.dart';
import '../models/flashcard_placement.dart';
import '../models/question_concept_mapping.dart';
import 'flashcard_ids.dart';

class FlashcardConceptCatalog {
  FlashcardConceptCatalog._({
    required Map<String, FlashcardConcept> conceptsById,
    required Map<String, Flashcard> cardsById,
    required Map<int, String> conceptIdByQuestion,
  }) : _conceptsById = Map<String, FlashcardConcept>.unmodifiable(conceptsById),
       _cardsById = Map<String, Flashcard>.unmodifiable(cardsById),
       _conceptIdByQuestion = Map<int, String>.unmodifiable(
         conceptIdByQuestion,
       );

  final Map<String, FlashcardConcept> _conceptsById;
  final Map<String, Flashcard> _cardsById;
  final Map<int, String> _conceptIdByQuestion;

  factory FlashcardConceptCatalog.build({
    required Iterable<FlashcardConcept> concepts,
    required Iterable<Flashcard> cards,
    required Iterable<QuestionConceptMapping> questionMappings,
    Iterable<FlashcardDeck> decks = const <FlashcardDeck>[],
  }) {
    final conceptsById = <String, FlashcardConcept>{};
    final cardsById = <String, Flashcard>{};
    final conceptIdByQuestion = <int, String>{};

    for (final concept in concepts) {
      _validateConcept(concept);
      if (conceptsById.containsKey(concept.id)) {
        throw FormatException('Duplicate Concept ID: ${concept.id}');
      }
      conceptsById[concept.id] = concept;
    }

    for (final card in cards) {
      _validateCard(card);
      if (cardsById.containsKey(card.id)) {
        throw FormatException('Duplicate Flashcard ID: ${card.id}');
      }
      cardsById[card.id] = card;
    }

    for (final concept in conceptsById.values) {
      final expectedCardId = FlashcardIds.expectedFlashcardIdForConcept(
        concept.id,
      );
      if (concept.flashcardId != expectedCardId) {
        throw FormatException(
          'Concept ${concept.id} must map to canonical card $expectedCardId.',
        );
      }

      final card = cardsById[concept.flashcardId];
      if (card == null) {
        throw FormatException(
          'Concept ${concept.id} references missing card '
          '${concept.flashcardId}.',
        );
      }

      if (card.conceptId != concept.id) {
        throw FormatException(
          'Card ${card.id} must point back to Concept ${concept.id}.',
        );
      }
    }

    for (final card in cardsById.values) {
      if (!conceptsById.containsKey(card.conceptId)) {
        throw FormatException(
          'Card ${card.id} references missing Concept ${card.conceptId}.',
        );
      }
    }

    for (final mapping in questionMappings) {
      if (mapping.questionId <= 0) {
        throw FormatException(
          'Question mapping IDs must be positive: ${mapping.questionId}.',
        );
      }

      if (!conceptsById.containsKey(mapping.conceptId)) {
        throw FormatException(
          'Question ${mapping.questionId} references missing Concept '
          '${mapping.conceptId}.',
        );
      }

      if (conceptIdByQuestion.containsKey(mapping.questionId)) {
        throw FormatException(
          'Duplicate Question mapping: ${mapping.questionId}.',
        );
      }

      conceptIdByQuestion[mapping.questionId] = mapping.conceptId;
    }

    for (final deck in decks) {
      _validateDeck(deck, cardsById);
    }

    return FlashcardConceptCatalog._(
      conceptsById: conceptsById,
      cardsById: cardsById,
      conceptIdByQuestion: conceptIdByQuestion,
    );
  }

  FlashcardConcept? conceptForId(String conceptId) {
    return _conceptsById[conceptId];
  }

  Flashcard? cardForId(String cardId) {
    return _cardsById[cardId];
  }

  FlashcardConcept? conceptForQuestion(int questionId) {
    final conceptId = _conceptIdByQuestion[questionId];
    if (conceptId == null) return null;
    return _conceptsById[conceptId];
  }

  Flashcard? cardForQuestion(int questionId) {
    final concept = conceptForQuestion(questionId);
    if (concept == null) return null;
    return _cardsById[concept.flashcardId];
  }

  Flashcard? cardForConcept(String conceptId) {
    final concept = _conceptsById[conceptId];
    if (concept == null) return null;
    return _cardsById[concept.flashcardId];
  }

  int get conceptCount => _conceptsById.length;
  int get cardCount => _cardsById.length;
  int get questionMappingCount => _conceptIdByQuestion.length;

  static void _validateConcept(FlashcardConcept concept) {
    if (!FlashcardIds.isValidConceptId(concept.id)) {
      throw FormatException('Invalid Concept ID: ${concept.id}');
    }
    if (concept.canonicalLabel.trim().isEmpty) {
      throw FormatException('Concept ${concept.id} has an empty label.');
    }
    if (!FlashcardIds.isValidFlashcardId(concept.flashcardId)) {
      throw FormatException(
        'Concept ${concept.id} has an invalid Flashcard ID.',
      );
    }
    _validatePlacement(concept.primaryPlacement);
  }

  static void _validateCard(Flashcard card) {
    if (!FlashcardIds.isValidFlashcardId(card.id)) {
      throw FormatException('Invalid Flashcard ID: ${card.id}');
    }
    if (!FlashcardIds.isValidConceptId(card.conceptId)) {
      throw FormatException(
        'Card ${card.id} has an invalid Concept ID: ${card.conceptId}.',
      );
    }
    if (card.id != FlashcardIds.expectedFlashcardIdForConcept(card.conceptId)) {
      throw FormatException(
        'Card ${card.id} does not match Concept ${card.conceptId}.',
      );
    }
    if (card.version < 1) {
      throw FormatException('Card ${card.id} version must be >= 1.');
    }
    if (card.frontLabel.trim().isEmpty) {
      throw FormatException('Card ${card.id} has an empty front label.');
    }
    if (card.frontLabel.contains('?')) {
      throw FormatException(
        'Card ${card.id} front must be a concept/phrase, not a question.',
      );
    }
    if (card.backDefinition.trim().isEmpty) {
      throw FormatException('Card ${card.id} has an empty back definition.');
    }
    _validatePlacement(card.primaryPlacement);
  }

  static void _validateDeck(
    FlashcardDeck deck,
    Map<String, Flashcard> cardsById,
  ) {
    if (!FlashcardIds.isValidDeckId(deck.id)) {
      throw FormatException('Invalid Flashcard deck ID: ${deck.id}');
    }
    if (deck.version < 1 || FlashcardIds.deckVersion(deck.id) != deck.version) {
      throw FormatException('Deck ${deck.id} version does not match its ID.');
    }

    _validatePlacement(
      FlashcardPlacement(
        domainId: deck.domainId,
        competencyId: deck.competencyId,
      ),
    );

    if (FlashcardIds.deckCompetencyId(deck.id) != deck.competencyId) {
      throw FormatException(
        'Deck ${deck.id} does not match competency ${deck.competencyId}.',
      );
    }

    final seen = <String>{};
    for (final cardId in deck.cardIds) {
      if (!seen.add(cardId)) {
        throw FormatException('Deck ${deck.id} repeats card $cardId.');
      }
      final card = cardsById[cardId];
      if (card == null) {
        throw FormatException(
          'Deck ${deck.id} references missing card $cardId.',
        );
      }
      if (card.primaryPlacement.competencyId != deck.competencyId) {
        throw FormatException(
          'Deck ${deck.id} contains a card from another competency: $cardId.',
        );
      }
    }
  }

  static void _validatePlacement(FlashcardPlacement placement) {
    final domain = domainForContentId(placement.domainId);
    if (domain == null) {
      throw FormatException('Unknown CSP11 Domain ID: ${placement.domainId}.');
    }

    final competency = competencyForId(placement.competencyId);
    if (competency == null || !competency.id.startsWith('${domain.id}_')) {
      throw FormatException(
        'Competency ${placement.competencyId} does not belong to '
        'Domain ${domain.id}.',
      );
    }

    if (placement.topicId.isNotEmpty) {
      final topicPattern = RegExp(r'^d\d{2}_c\d{2}_t\d{2}$');
      if (!topicPattern.hasMatch(placement.topicId) ||
          !placement.topicId.startsWith('${placement.competencyId}_')) {
        throw FormatException('Non-canonical Topic ID: ${placement.topicId}.');
      }
    }

    if (placement.subtopicId.isNotEmpty) {
      final subtopicPattern = RegExp(r'^d\d{2}_c\d{2}_t\d{2}_s\d{2}$');
      if (!subtopicPattern.hasMatch(placement.subtopicId) ||
          !placement.subtopicId.startsWith('${placement.competencyId}_')) {
        throw FormatException(
          'Non-canonical Subtopic ID: ${placement.subtopicId}.',
        );
      }
    }
  }
}
