enum FlashcardLifecycle { candidate, review, validated, bundled }

FlashcardLifecycle flashcardLifecycleFromJson(dynamic value) {
  final normalized = value?.toString().trim();
  for (final lifecycle in FlashcardLifecycle.values) {
    if (lifecycle.name == normalized) {
      return lifecycle;
    }
  }

  throw FormatException('Unsupported flashcard lifecycle: $value');
}
