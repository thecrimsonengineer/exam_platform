enum FlashcardRecallRating { again, hard, gotIt }

enum FlashcardReviewSource { dailyPlan, catalog }

class FlashcardRecallEvent {
  const FlashcardRecallEvent({
    required this.eventId,
    required this.sessionId,
    required this.cardId,
    required this.competencyId,
    required this.conceptLabel,
    required this.rating,
    required this.occurredAt,
    required this.attemptSequence,
    required this.sameSessionRepeat,
    required this.source,
    required this.nextReviewAt,
    this.previousRating,
    this.previousOccurredAt,
    this.spacingIntervalDays,
    this.blockId,
    this.schemaVersion = currentSchemaVersion,
  });

  static const int currentSchemaVersion = 1;

  final String eventId;
  final String sessionId;
  final String cardId;
  final String competencyId;
  final String conceptLabel;
  final FlashcardRecallRating rating;
  final DateTime occurredAt;
  final int attemptSequence;
  final FlashcardRecallRating? previousRating;
  final DateTime? previousOccurredAt;
  final int? spacingIntervalDays;
  final bool sameSessionRepeat;
  final FlashcardReviewSource source;
  final String? blockId;
  final DateTime nextReviewAt;
  final int schemaVersion;

  bool get isFirstAttemptInSession => !sameSessionRepeat && attemptSequence == 1;

  bool get isSpaced => !sameSessionRepeat && (spacingIntervalDays ?? 0) >= 1;

  bool get isSuccessfulRecall => rating == FlashcardRecallRating.gotIt;

  void validate() {
    if (eventId.trim().isEmpty ||
        sessionId.trim().isEmpty ||
        cardId.trim().isEmpty ||
        conceptLabel.trim().isEmpty) {
      throw StateError(
        'Flashcard recall identifiers and concept cannot be blank.',
      );
    }
    if (!RegExp(r'^d\d{2}_c\d{2}$').hasMatch(competencyId)) {
      throw StateError('Flashcard recall competency ID is not canonical.');
    }
    if (attemptSequence < 1) {
      throw StateError('Flashcard recall attempt sequence must start at one.');
    }
    if (sameSessionRepeat && attemptSequence < 2) {
      throw StateError('A same-session repeat must follow an earlier attempt.');
    }
    if (spacingIntervalDays != null && spacingIntervalDays! < 0) {
      throw StateError('Flashcard spacing interval cannot be negative.');
    }
    if (sameSessionRepeat && spacingIntervalDays != null) {
      throw StateError('Same-session repeats cannot claim spaced-recall credit.');
    }
    if (nextReviewAt.isBefore(occurredAt)) {
      throw StateError('Next Flashcard review cannot precede the recall event.');
    }
    if (source == FlashcardReviewSource.dailyPlan &&
        (blockId == null || blockId!.trim().isEmpty)) {
      throw StateError('A planned Flashcard review must retain its block ID.');
    }
  }

  Map<String, dynamic> toJson() {
    validate();
    return <String, dynamic>{
      'eventId': eventId,
      'sessionId': sessionId,
      'cardId': cardId,
      'competencyId': competencyId,
      'conceptLabel': conceptLabel,
      'rating': rating.name,
      'occurredAt': occurredAt.toIso8601String(),
      'attemptSequence': attemptSequence,
      'previousRating': previousRating?.name,
      'previousOccurredAt': previousOccurredAt?.toIso8601String(),
      'spacingIntervalDays': spacingIntervalDays,
      'sameSessionRepeat': sameSessionRepeat,
      'source': source.name,
      'blockId': blockId,
      'nextReviewAt': nextReviewAt.toIso8601String(),
      'schemaVersion': schemaVersion,
    };
  }

  factory FlashcardRecallEvent.fromJson(Map<String, dynamic> json) {
    final occurredAt = DateTime.tryParse(json['occurredAt']?.toString() ?? '');
    final nextReviewAt = DateTime.tryParse(
      json['nextReviewAt']?.toString() ?? '',
    );
    if (occurredAt == null || nextReviewAt == null) {
      throw const FormatException('Invalid Flashcard recall timestamp.');
    }

    final previousOccurredAt = DateTime.tryParse(
      json['previousOccurredAt']?.toString() ?? '',
    );
    final event = FlashcardRecallEvent(
      eventId: json['eventId']?.toString() ?? '',
      sessionId: json['sessionId']?.toString() ?? '',
      cardId: json['cardId']?.toString() ?? '',
      competencyId: json['competencyId']?.toString() ?? '',
      conceptLabel: json['conceptLabel']?.toString() ?? '',
      rating: FlashcardRecallRating.values.firstWhere(
        (item) => item.name == json['rating']?.toString(),
        orElse: () => FlashcardRecallRating.again,
      ),
      occurredAt: occurredAt,
      attemptSequence: _int(json['attemptSequence'], 1),
      previousRating: _nullableRating(json['previousRating']),
      previousOccurredAt: previousOccurredAt,
      spacingIntervalDays: json['spacingIntervalDays'] == null
          ? null
          : _int(json['spacingIntervalDays']),
      sameSessionRepeat: json['sameSessionRepeat'] == true,
      source: FlashcardReviewSource.values.firstWhere(
        (item) => item.name == json['source']?.toString(),
        orElse: () => FlashcardReviewSource.catalog,
      ),
      blockId: _nullableString(json['blockId']),
      nextReviewAt: nextReviewAt,
      schemaVersion: _int(json['schemaVersion'], currentSchemaVersion),
    );
    event.validate();
    return event;
  }
}

FlashcardRecallRating? _nullableRating(dynamic value) {
  final text = value?.toString().trim() ?? '';
  if (text.isEmpty) return null;
  for (final rating in FlashcardRecallRating.values) {
    if (rating.name == text) return rating;
  }
  return null;
}

String? _nullableString(dynamic value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

int _int(dynamic value, [int fallback = 0]) => value is num
    ? value.toInt()
    : int.tryParse(value?.toString() ?? '') ?? fallback;
