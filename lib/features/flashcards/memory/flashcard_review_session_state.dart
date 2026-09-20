enum FlashcardReviewSessionStatus { active, completed }

FlashcardReviewSessionStatus flashcardReviewSessionStatusFromJson(
  dynamic value,
) {
  final raw = value?.toString().trim() ?? '';
  return FlashcardReviewSessionStatus.values.firstWhere(
    (item) => item.name == raw,
    orElse: () => throw FormatException(
      'Unsupported Flashcard review session status: $value',
    ),
  );
}

class FlashcardReviewSessionState {
  const FlashcardReviewSessionState({
    required this.sessionId,
    required this.createdAt,
    required this.updatedAt,
    required this.cardIds,
    required this.nextIndex,
    required this.status,
  });

  final String sessionId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> cardIds;
  final int nextIndex;
  final FlashcardReviewSessionStatus status;

  bool get isCompleted => status == FlashcardReviewSessionStatus.completed;
  int get completedCount => nextIndex;
  int get remainingCount => cardIds.length - nextIndex;

  String? get currentCardId {
    if (isCompleted || nextIndex >= cardIds.length) {
      return null;
    }
    return cardIds[nextIndex];
  }

  FlashcardReviewSessionState advance(DateTime at) {
    if (isCompleted) {
      return this;
    }

    final next = nextIndex + 1;
    return FlashcardReviewSessionState(
      sessionId: sessionId,
      createdAt: createdAt,
      updatedAt: at,
      cardIds: cardIds,
      nextIndex: next,
      status: next >= cardIds.length
          ? FlashcardReviewSessionStatus.completed
          : FlashcardReviewSessionStatus.active,
    );
  }

  factory FlashcardReviewSessionState.fromJson(Map<String, dynamic> json) {
    final createdAt = DateTime.tryParse(json['createdAt']?.toString() ?? '');
    final updatedAt = DateTime.tryParse(json['updatedAt']?.toString() ?? '');
    if (createdAt == null || updatedAt == null) {
      throw const FormatException(
        'Flashcard review session timestamps are invalid.',
      );
    }

    final rawIds = json['cardIds'];
    final cardIds = rawIds is List
        ? rawIds
              .map((item) => item?.toString().trim() ?? '')
              .where((item) => item.isNotEmpty)
              .toList()
        : <String>[];

    final nextIndex = json['nextIndex'] is int
        ? json['nextIndex'] as int
        : int.tryParse(json['nextIndex']?.toString() ?? '') ?? 0;

    final state = FlashcardReviewSessionState(
      sessionId: json['sessionId']?.toString() ?? '',
      createdAt: createdAt,
      updatedAt: updatedAt,
      cardIds: cardIds,
      nextIndex: nextIndex,
      status: flashcardReviewSessionStatusFromJson(json['status']),
    );
    state.validate();
    return state;
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'cardIds': cardIds,
      'nextIndex': nextIndex,
      'status': status.name,
    };
  }

  void validate() {
    if (sessionId.trim().isEmpty) {
      throw const FormatException('Flashcard review session ID is required.');
    }
    if (updatedAt.isBefore(createdAt)) {
      throw const FormatException(
        'Flashcard review session update cannot precede creation.',
      );
    }
    if (cardIds.toSet().length != cardIds.length) {
      throw const FormatException(
        'Flashcard review session card IDs must be unique.',
      );
    }
    if (nextIndex < 0 || nextIndex > cardIds.length) {
      throw const FormatException('Flashcard review session index is invalid.');
    }
    if (status == FlashcardReviewSessionStatus.completed &&
        nextIndex != cardIds.length) {
      throw const FormatException(
        'Completed Flashcard review session must consume all cards.',
      );
    }
    if (status == FlashcardReviewSessionStatus.active &&
        cardIds.isNotEmpty &&
        nextIndex >= cardIds.length) {
      throw const FormatException(
        'Active Flashcard review session requires a remaining card.',
      );
    }
    if (cardIds.isEmpty && status != FlashcardReviewSessionStatus.completed) {
      throw const FormatException(
        'Empty Flashcard review session must be completed.',
      );
    }
  }
}
