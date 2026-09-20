class FlashcardIds {
  FlashcardIds._();

  static final RegExp _semanticSlug = RegExp(r'^[a-z0-9]+(?:_[a-z0-9]+)*$');

  static final RegExp _conceptId = RegExp(
    r'^csp11\.concept\.([a-z0-9]+(?:_[a-z0-9]+)*)$',
  );

  static final RegExp _flashcardId = RegExp(
    r'^csp11\.flashcard\.([a-z0-9]+(?:_[a-z0-9]+)*)$',
  );

  static final RegExp _deckId = RegExp(
    r'^(d\d{2}_c\d{2})_flashcards_v([1-9]\d*)$',
  );

  static bool isValidSemanticSlug(String value) {
    return _semanticSlug.hasMatch(value.trim());
  }

  static bool isValidConceptId(String value) {
    return _conceptId.hasMatch(value.trim());
  }

  static bool isValidFlashcardId(String value) {
    return _flashcardId.hasMatch(value.trim());
  }

  static bool isValidDeckId(String value) {
    return _deckId.hasMatch(value.trim());
  }

  static String conceptSlug(String conceptId) {
    final match = _conceptId.firstMatch(conceptId.trim());
    if (match == null) {
      throw FormatException('Invalid Concept ID: $conceptId');
    }
    return match.group(1)!;
  }

  static String flashcardSlug(String flashcardId) {
    final match = _flashcardId.firstMatch(flashcardId.trim());
    if (match == null) {
      throw FormatException('Invalid Flashcard ID: $flashcardId');
    }
    return match.group(1)!;
  }

  static String expectedFlashcardIdForConcept(String conceptId) {
    return 'csp11.flashcard.${conceptSlug(conceptId)}';
  }

  static String deckCompetencyId(String deckId) {
    final match = _deckId.firstMatch(deckId.trim());
    if (match == null) {
      throw FormatException('Invalid Flashcard deck ID: $deckId');
    }
    return match.group(1)!;
  }

  static int deckVersion(String deckId) {
    final match = _deckId.firstMatch(deckId.trim());
    if (match == null) {
      throw FormatException('Invalid Flashcard deck ID: $deckId');
    }
    return int.parse(match.group(2)!);
  }
}
