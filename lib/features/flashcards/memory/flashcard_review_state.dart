enum FlashcardReviewStage { learning, review, relearning }

enum FlashcardReviewRating { again, hard, gotIt }

FlashcardReviewStage flashcardReviewStageFromJson(dynamic value) {
  final raw = value?.toString().trim() ?? '';
  return FlashcardReviewStage.values.firstWhere(
    (item) => item.name == raw,
    orElse: () => throw FormatException(
      'Unsupported Flashcard review stage: $value',
    ),
  );
}

FlashcardReviewRating flashcardReviewRatingFromJson(dynamic value) {
  final raw = value?.toString().trim() ?? '';
  return FlashcardReviewRating.values.firstWhere(
    (item) => item.name == raw,
    orElse: () => throw FormatException(
      'Unsupported Flashcard review rating: $value',
    ),
  );
}

class FlashcardReviewState {
  const FlashcardReviewState({
    required this.cardId,
    required this.conceptId,
    required this.activatedAt,
    required this.stage,
    required this.dueAt,
    required this.intervalMinutes,
    this.reviewCount = 0,
    this.lapseCount = 0,
    this.againCount = 0,
    this.hardCount = 0,
    this.gotItCount = 0,
    this.gotItStreak = 0,
    this.lastReviewedAt,
    this.lastRating,
    this.appliedReviewEventIds = const <String>[],
  });

  final String cardId;
  final String conceptId;
  final DateTime activatedAt;
  final FlashcardReviewStage stage;
  final DateTime dueAt;
  final int intervalMinutes;
  final int reviewCount;
  final int lapseCount;
  final int againCount;
  final int hardCount;
  final int gotItCount;
  final int gotItStreak;
  final DateTime? lastReviewedAt;
  final FlashcardReviewRating? lastRating;
  final List<String> appliedReviewEventIds;

  bool isDue(DateTime now) => !dueAt.isAfter(now);

  bool hasAppliedEvent(String eventId) {
    return appliedReviewEventIds.contains(eventId.trim());
  }

  FlashcardReviewState copyWith({
    FlashcardReviewStage? stage,
    DateTime? dueAt,
    int? intervalMinutes,
    int? reviewCount,
    int? lapseCount,
    int? againCount,
    int? hardCount,
    int? gotItCount,
    int? gotItStreak,
    DateTime? lastReviewedAt,
    FlashcardReviewRating? lastRating,
    List<String>? appliedReviewEventIds,
  }) {
    return FlashcardReviewState(
      cardId: cardId,
      conceptId: conceptId,
      activatedAt: activatedAt,
      stage: stage ?? this.stage,
      dueAt: dueAt ?? this.dueAt,
      intervalMinutes: intervalMinutes ?? this.intervalMinutes,
      reviewCount: reviewCount ?? this.reviewCount,
      lapseCount: lapseCount ?? this.lapseCount,
      againCount: againCount ?? this.againCount,
      hardCount: hardCount ?? this.hardCount,
      gotItCount: gotItCount ?? this.gotItCount,
      gotItStreak: gotItStreak ?? this.gotItStreak,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      lastRating: lastRating ?? this.lastRating,
      appliedReviewEventIds:
          appliedReviewEventIds ?? this.appliedReviewEventIds,
    );
  }

  factory FlashcardReviewState.fromJson(Map<String, dynamic> json) {
    final activatedAt = DateTime.tryParse(
      json['activatedAt']?.toString() ?? '',
    );
    final dueAt = DateTime.tryParse(json['dueAt']?.toString() ?? '');
    if (activatedAt == null || dueAt == null) {
      throw const FormatException(
        'Flashcard review activation/due timestamp is invalid.',
      );
    }

    final lastReviewedRaw = json['lastReviewedAt']?.toString() ?? '';
    final lastReviewedAt = lastReviewedRaw.isEmpty
        ? null
        : DateTime.tryParse(lastReviewedRaw);
    if (lastReviewedRaw.isNotEmpty && lastReviewedAt == null) {
      throw const FormatException(
        'Flashcard review lastReviewedAt is invalid.',
      );
    }

    final rawEventIds = json['appliedReviewEventIds'];
    final eventIds = rawEventIds is List
        ? rawEventIds
              .map((item) => item?.toString().trim() ?? '')
              .where((item) => item.isNotEmpty)
              .toList()
        : <String>[];

    final rawLastRating = json['lastRating'];
    final state = FlashcardReviewState(
      cardId: json['cardId']?.toString() ?? '',
      conceptId: json['conceptId']?.toString() ?? '',
      activatedAt: activatedAt,
      stage: flashcardReviewStageFromJson(json['stage']),
      dueAt: dueAt,
      intervalMinutes: _nonNegativeInt(json['intervalMinutes']),
      reviewCount: _nonNegativeInt(json['reviewCount']),
      lapseCount: _nonNegativeInt(json['lapseCount']),
      againCount: _nonNegativeInt(json['againCount']),
      hardCount: _nonNegativeInt(json['hardCount']),
      gotItCount: _nonNegativeInt(json['gotItCount']),
      gotItStreak: _nonNegativeInt(json['gotItStreak']),
      lastReviewedAt: lastReviewedAt,
      lastRating: rawLastRating == null
          ? null
          : flashcardReviewRatingFromJson(rawLastRating),
      appliedReviewEventIds: eventIds,
    );
    state.validate();
    return state;
  }

  Map<String, dynamic> toJson() {
    return {
      'cardId': cardId,
      'conceptId': conceptId,
      'activatedAt': activatedAt.toIso8601String(),
      'stage': stage.name,
      'dueAt': dueAt.toIso8601String(),
      'intervalMinutes': intervalMinutes,
      'reviewCount': reviewCount,
      'lapseCount': lapseCount,
      'againCount': againCount,
      'hardCount': hardCount,
      'gotItCount': gotItCount,
      'gotItStreak': gotItStreak,
      if (lastReviewedAt != null)
        'lastReviewedAt': lastReviewedAt!.toIso8601String(),
      if (lastRating != null) 'lastRating': lastRating!.name,
      'appliedReviewEventIds': appliedReviewEventIds,
    };
  }

  void validate() {
    if (cardId.trim().isEmpty || conceptId.trim().isEmpty) {
      throw const FormatException(
        'Flashcard review state requires card and concept IDs.',
      );
    }
    if (intervalMinutes <= 0) {
      throw const FormatException(
        'Flashcard review interval must be positive.',
      );
    }
    if (dueAt.isBefore(activatedAt)) {
      throw const FormatException(
        'Flashcard review due time cannot precede activation.',
      );
    }
    if (appliedReviewEventIds.toSet().length !=
        appliedReviewEventIds.length) {
      throw const FormatException(
        'Flashcard review event IDs must be unique.',
      );
    }
    if (reviewCount != appliedReviewEventIds.length) {
      throw const FormatException(
        'Flashcard review count must match unique applied events.',
      );
    }
    if (againCount + hardCount + gotItCount != reviewCount) {
      throw const FormatException(
        'Flashcard review rating counts must equal review count.',
      );
    }
    if (lapseCount > againCount) {
      throw const FormatException(
        'Flashcard lapse count cannot exceed Again count.',
      );
    }
    if (reviewCount == 0) {
      if (lastReviewedAt != null || lastRating != null) {
        throw const FormatException(
          'Unreviewed Flashcard cannot have last-review metadata.',
        );
      }
    } else {
      if (lastReviewedAt == null || lastRating == null) {
        throw const FormatException(
          'Reviewed Flashcard requires last-review metadata.',
        );
      }
      if (lastReviewedAt!.isBefore(activatedAt)) {
        throw const FormatException(
          'Flashcard last review cannot precede activation.',
        );
      }
      if (dueAt.isBefore(lastReviewedAt!)) {
        throw const FormatException(
          'Flashcard next due time cannot precede last review.',
        );
      }
    }
    if (gotItStreak > gotItCount) {
      throw const FormatException(
        'Flashcard Got It streak cannot exceed Got It count.',
      );
    }
  }
}

int _nonNegativeInt(dynamic value) {
  final parsed = value is int
      ? value
      : value is num
      ? value.toInt()
      : int.tryParse(value?.toString() ?? '') ?? 0;
  if (parsed < 0) {
    throw FormatException(
      'Flashcard review count cannot be negative: $value',
    );
  }
  return parsed;
}
