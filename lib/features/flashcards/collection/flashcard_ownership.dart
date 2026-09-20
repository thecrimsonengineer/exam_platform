enum FlashcardAcquisitionSource { questionCompletion, dailyDiscovery }

enum FlashcardQuestionOutcome { correct, incorrect, notApplicable }

FlashcardAcquisitionSource flashcardAcquisitionSourceFromJson(dynamic value) {
  final raw = value?.toString().trim() ?? '';
  return FlashcardAcquisitionSource.values.firstWhere(
    (item) => item.name == raw,
    orElse: () => throw FormatException(
      'Unsupported Flashcard acquisition source: $value',
    ),
  );
}

FlashcardQuestionOutcome flashcardQuestionOutcomeFromJson(dynamic value) {
  final raw = value?.toString().trim() ?? '';
  return FlashcardQuestionOutcome.values.firstWhere(
    (item) => item.name == raw,
    orElse: () =>
        throw FormatException('Unsupported Flashcard question outcome: $value'),
  );
}

class FlashcardOwnership {
  const FlashcardOwnership({
    required this.cardId,
    required this.conceptId,
    required this.acquiredAt,
    required this.acquisitionSource,
    required this.firstQuestionOutcome,
    this.firstViewedAt,
    this.reinforcementCount = 0,
    this.lastReinforcedAt,
    this.correctSignalCount = 0,
    this.incorrectSignalCount = 0,
    this.appliedEventIds = const <String>[],
  });

  final String cardId;
  final String conceptId;
  final DateTime acquiredAt;
  final FlashcardAcquisitionSource acquisitionSource;
  final FlashcardQuestionOutcome firstQuestionOutcome;
  final DateTime? firstViewedAt;
  final int reinforcementCount;
  final DateTime? lastReinforcedAt;
  final int correctSignalCount;
  final int incorrectSignalCount;
  final List<String> appliedEventIds;

  bool get isUnseen => firstViewedAt == null;
  bool get isFirstViewed => firstViewedAt != null;

  bool hasAppliedEvent(String eventId) {
    return appliedEventIds.contains(eventId.trim());
  }

  FlashcardOwnership copyWith({
    DateTime? firstViewedAt,
    bool preserveFirstViewedAt = true,
    int? reinforcementCount,
    DateTime? lastReinforcedAt,
    int? correctSignalCount,
    int? incorrectSignalCount,
    List<String>? appliedEventIds,
  }) {
    return FlashcardOwnership(
      cardId: cardId,
      conceptId: conceptId,
      acquiredAt: acquiredAt,
      acquisitionSource: acquisitionSource,
      firstQuestionOutcome: firstQuestionOutcome,
      firstViewedAt: preserveFirstViewedAt
          ? (firstViewedAt ?? this.firstViewedAt)
          : firstViewedAt,
      reinforcementCount: reinforcementCount ?? this.reinforcementCount,
      lastReinforcedAt: lastReinforcedAt ?? this.lastReinforcedAt,
      correctSignalCount: correctSignalCount ?? this.correctSignalCount,
      incorrectSignalCount: incorrectSignalCount ?? this.incorrectSignalCount,
      appliedEventIds: appliedEventIds ?? this.appliedEventIds,
    );
  }

  factory FlashcardOwnership.fromJson(Map<String, dynamic> json) {
    final rawEventIds = json['appliedEventIds'];
    final acquiredAt = DateTime.tryParse(json['acquiredAt']?.toString() ?? '');
    if (acquiredAt == null) {
      throw const FormatException('Flashcard ownership acquiredAt is invalid.');
    }

    final firstViewedRaw = json['firstViewedAt']?.toString() ?? '';
    final lastReinforcedRaw = json['lastReinforcedAt']?.toString() ?? '';

    final firstViewedAt = firstViewedRaw.isEmpty
        ? null
        : DateTime.tryParse(firstViewedRaw);
    if (firstViewedRaw.isNotEmpty && firstViewedAt == null) {
      throw const FormatException(
        'Flashcard ownership firstViewedAt is invalid.',
      );
    }

    final lastReinforcedAt = lastReinforcedRaw.isEmpty
        ? null
        : DateTime.tryParse(lastReinforcedRaw);
    if (lastReinforcedRaw.isNotEmpty && lastReinforcedAt == null) {
      throw const FormatException(
        'Flashcard ownership lastReinforcedAt is invalid.',
      );
    }

    final eventIds = rawEventIds is List
        ? rawEventIds
              .map((item) => item?.toString().trim() ?? '')
              .where((item) => item.isNotEmpty)
              .toList()
        : <String>[];
    if (eventIds.toSet().length != eventIds.length) {
      throw const FormatException(
        'Flashcard ownership applied event IDs must be unique.',
      );
    }

    final ownership = FlashcardOwnership(
      cardId: json['cardId']?.toString() ?? '',
      conceptId: json['conceptId']?.toString() ?? '',
      acquiredAt: acquiredAt,
      acquisitionSource: flashcardAcquisitionSourceFromJson(
        json['acquisitionSource'],
      ),
      firstQuestionOutcome: flashcardQuestionOutcomeFromJson(
        json['firstQuestionOutcome'] ??
            FlashcardQuestionOutcome.notApplicable.name,
      ),
      firstViewedAt: firstViewedAt,
      reinforcementCount: _toNonNegativeInt(json['reinforcementCount']),
      lastReinforcedAt: lastReinforcedAt,
      correctSignalCount: _toNonNegativeInt(json['correctSignalCount']),
      incorrectSignalCount: _toNonNegativeInt(json['incorrectSignalCount']),
      appliedEventIds: eventIds,
    );
    ownership.validate();
    return ownership;
  }

  Map<String, dynamic> toJson() {
    return {
      'cardId': cardId,
      'conceptId': conceptId,
      'acquiredAt': acquiredAt.toIso8601String(),
      'acquisitionSource': acquisitionSource.name,
      'firstQuestionOutcome': firstQuestionOutcome.name,
      if (firstViewedAt != null)
        'firstViewedAt': firstViewedAt!.toIso8601String(),
      'reinforcementCount': reinforcementCount,
      if (lastReinforcedAt != null)
        'lastReinforcedAt': lastReinforcedAt!.toIso8601String(),
      'correctSignalCount': correctSignalCount,
      'incorrectSignalCount': incorrectSignalCount,
      'appliedEventIds': appliedEventIds,
    };
  }

  void validate() {
    if (cardId.trim().isEmpty || conceptId.trim().isEmpty) {
      throw const FormatException(
        'Flashcard ownership requires card and concept IDs.',
      );
    }
    if (appliedEventIds.isEmpty) {
      throw const FormatException(
        'Flashcard ownership requires at least one acquisition event.',
      );
    }
    if (firstViewedAt != null && firstViewedAt!.isBefore(acquiredAt)) {
      throw const FormatException(
        'Flashcard first-view time cannot precede acquisition.',
      );
    }
    if (lastReinforcedAt != null && lastReinforcedAt!.isBefore(acquiredAt)) {
      throw const FormatException(
        'Flashcard reinforcement time cannot precede acquisition.',
      );
    }
  }
}

int _toNonNegativeInt(dynamic value) {
  final parsed = value is int
      ? value
      : value is num
      ? value.toInt()
      : int.tryParse(value?.toString() ?? '') ?? 0;
  if (parsed < 0) {
    throw FormatException(
      'Flashcard ownership count cannot be negative: $value',
    );
  }
  return parsed;
}
