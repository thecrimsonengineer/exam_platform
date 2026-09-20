import 'flashcard_ownership.dart';

enum FlashcardUnlockEventKind {
  newlyCollected,
  reinforced,
  duplicateIgnored,
}

class FlashcardUnlockRequest {
  const FlashcardUnlockRequest({
    required this.eventId,
    required this.cardId,
    required this.conceptId,
    required this.source,
    required this.questionOutcome,
    this.questionId,
    this.occurredAt,
  });

  final String eventId;
  final String cardId;
  final String conceptId;
  final FlashcardAcquisitionSource source;
  final FlashcardQuestionOutcome questionOutcome;
  final int? questionId;
  final DateTime? occurredAt;
}

class FlashcardUnlockEvent {
  const FlashcardUnlockEvent({
    required this.eventId,
    required this.cardId,
    required this.conceptId,
    required this.kind,
    required this.source,
    required this.questionOutcome,
    required this.occurredAt,
    required this.ownership,
    this.questionId,
  });

  final String eventId;
  final String cardId;
  final String conceptId;
  final FlashcardUnlockEventKind kind;
  final FlashcardAcquisitionSource source;
  final FlashcardQuestionOutcome questionOutcome;
  final DateTime occurredAt;
  final FlashcardOwnership ownership;
  final int? questionId;

  bool get isNewCollection =>
      kind == FlashcardUnlockEventKind.newlyCollected;

  bool get isReinforcement =>
      kind == FlashcardUnlockEventKind.reinforced;

  bool get wasDuplicate =>
      kind == FlashcardUnlockEventKind.duplicateIgnored;
}
