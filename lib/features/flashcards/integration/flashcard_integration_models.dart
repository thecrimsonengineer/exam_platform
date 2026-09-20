import '../collection/flashcard_unlock_event.dart';
import '../memory/flashcard_review_session_state.dart';

enum FlashcardQuestionCompletionStatus {
  noMapping,
  newlyCollected,
  reinforced,
  duplicateIgnored,
}

class FlashcardQuestionCompletionResult {
  const FlashcardQuestionCompletionResult({
    required this.questionId,
    required this.status,
    this.conceptId,
    this.cardId,
    this.frontLabel,
    this.unlockEvent,
  });

  final int questionId;
  final FlashcardQuestionCompletionStatus status;
  final String? conceptId;
  final String? cardId;
  final String? frontLabel;
  final FlashcardUnlockEvent? unlockEvent;

  bool get hasReward =>
      status == FlashcardQuestionCompletionStatus.newlyCollected ||
      status == FlashcardQuestionCompletionStatus.reinforced;

  bool get isNewCollection =>
      status == FlashcardQuestionCompletionStatus.newlyCollected;
}

class FlashcardReviewScope {
  const FlashcardReviewScope({
    this.domainId,
    this.competencyId,
    this.topicId,
    this.subtopicId,
  });

  final String? domainId;
  final String? competencyId;
  final String? topicId;
  final String? subtopicId;

  bool get isGlobal =>
      _clean(domainId).isEmpty &&
      _clean(competencyId).isEmpty &&
      _clean(topicId).isEmpty &&
      _clean(subtopicId).isEmpty;

  String get storageKey {
    final parts = <String>[
      if (_clean(domainId).isNotEmpty) 'd-${_clean(domainId)}',
      if (_clean(competencyId).isNotEmpty) 'c-${_clean(competencyId)}',
      if (_clean(topicId).isNotEmpty) 't-${_clean(topicId)}',
      if (_clean(subtopicId).isNotEmpty) 's-${_clean(subtopicId)}',
    ];
    return parts.isEmpty ? 'all' : parts.join('_');
  }

  static String _clean(String? value) => value?.trim() ?? '';
}

class FlashcardScopedReviewSummary {
  const FlashcardScopedReviewSummary({
    required this.scope,
    required this.totalCards,
    required this.ownedCards,
    required this.dueCards,
    required this.unseenCards,
    this.activeSession,
  });

  final FlashcardReviewScope scope;
  final int totalCards;
  final int ownedCards;
  final int dueCards;
  final int unseenCards;
  final FlashcardReviewSessionState? activeSession;

  bool get canReview =>
      (activeSession != null && !activeSession!.isCompleted) || dueCards > 0;
}

class FlashcardQuestionMappingCoverage {
  const FlashcardQuestionMappingCoverage({
    required this.eligibleQuestionIds,
    required this.mappedQuestionIds,
    required this.unmappedQuestionIds,
    required this.conflictingQuestionIds,
  });

  final List<int> eligibleQuestionIds;
  final List<int> mappedQuestionIds;
  final List<int> unmappedQuestionIds;
  final List<int> conflictingQuestionIds;

  int get eligibleCount => eligibleQuestionIds.length;
  int get mappedCount => mappedQuestionIds.length;

  double get coverageRatio {
    if (eligibleCount == 0) {
      return 1;
    }
    return mappedCount / eligibleCount;
  }

  bool get passed =>
      unmappedQuestionIds.isEmpty && conflictingQuestionIds.isEmpty;
}

class FlashcardStudyContentPlacementIssue {
  const FlashcardStudyContentPlacementIssue({
    required this.cardId,
    required this.level,
    required this.identifier,
    required this.message,
  });

  final String cardId;
  final String level;
  final String identifier;
  final String message;
}

class FlashcardStudyContentPlacementReport {
  const FlashcardStudyContentPlacementReport({
    required this.checkedCards,
    required this.issues,
  });

  final int checkedCards;
  final List<FlashcardStudyContentPlacementIssue> issues;

  bool get passed => issues.isEmpty;
}

class FlashcardSourceQualityReport {
  const FlashcardSourceQualityReport({
    required this.packageCount,
    required this.cardCount,
    required this.sourceCount,
    required this.cardsWithPrimarySource,
    required this.cardsWithVerifiedPrimarySource,
    required this.verifiedSourceCount,
    required this.needsReviewSourceCount,
    required this.staleSourceCount,
    required this.blockedSourceCount,
  });

  final int packageCount;
  final int cardCount;
  final int sourceCount;
  final int cardsWithPrimarySource;
  final int cardsWithVerifiedPrimarySource;
  final int verifiedSourceCount;
  final int needsReviewSourceCount;
  final int staleSourceCount;
  final int blockedSourceCount;

  double get verifiedPrimaryCoverage {
    if (cardCount == 0) {
      return 1;
    }
    return cardsWithVerifiedPrimarySource / cardCount;
  }

  bool get passed =>
      cardsWithPrimarySource == cardCount &&
      cardsWithVerifiedPrimarySource == cardCount &&
      blockedSourceCount == 0;
}

class FlashcardCollectionQualityReport {
  const FlashcardCollectionQualityReport({
    required this.ownedCount,
    required this.unseenCount,
    required this.reviewStateCount,
    required this.dueCount,
    required this.orphanOwnershipCardIds,
    required this.conceptMismatchCardIds,
    required this.orphanReviewCardIds,
    required this.reviewBeforeRevealCardIds,
  });

  final int ownedCount;
  final int unseenCount;
  final int reviewStateCount;
  final int dueCount;
  final List<String> orphanOwnershipCardIds;
  final List<String> conceptMismatchCardIds;
  final List<String> orphanReviewCardIds;
  final List<String> reviewBeforeRevealCardIds;

  bool get passed =>
      orphanOwnershipCardIds.isEmpty &&
      conceptMismatchCardIds.isEmpty &&
      orphanReviewCardIds.isEmpty &&
      reviewBeforeRevealCardIds.isEmpty;
}

class FlashcardLearningTwinSummary {
  const FlashcardLearningTwinSummary({
    required this.ownedCount,
    required this.unseenCount,
    required this.dueCount,
    required this.weakCount,
    required this.totalReviewEvents,
    required this.dueDomainIds,
  });

  final int ownedCount;
  final int unseenCount;
  final int dueCount;
  final int weakCount;
  final int totalReviewEvents;
  final List<String> dueDomainIds;

  bool get hasDueReview => dueCount > 0;

  Map<String, Object> toSanitizedJson() => <String, Object>{
    'ownedCount': ownedCount,
    'unseenCount': unseenCount,
    'dueCount': dueCount,
    'weakCount': weakCount,
    'totalReviewEvents': totalReviewEvents,
    'dueDomainIds': List<String>.unmodifiable(dueDomainIds),
  };
}

class FlashcardDiagnosticsReport {
  const FlashcardDiagnosticsReport({
    required this.questionCoverage,
    required this.placement,
    required this.sourceQuality,
    required this.collectionQuality,
  });

  final FlashcardQuestionMappingCoverage questionCoverage;
  final FlashcardStudyContentPlacementReport placement;
  final FlashcardSourceQualityReport sourceQuality;
  final FlashcardCollectionQualityReport collectionQuality;

  bool get passed =>
      questionCoverage.passed &&
      placement.passed &&
      sourceQuality.passed &&
      collectionQuality.passed;
}
