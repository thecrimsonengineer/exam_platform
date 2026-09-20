enum FlashcardType {
  concept,
  term,
  phrase,
  acronym,
  principle,
  formulaName,
  thresholdName,
  processName,
  classification,
  control,
  hazard,
  model,
}

FlashcardType flashcardTypeFromJson(dynamic value) {
  final normalized = value?.toString().trim();
  for (final type in FlashcardType.values) {
    if (type.name == normalized) {
      return type;
    }
  }

  throw FormatException('Unsupported flashcard type: $value');
}
