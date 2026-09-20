import '../../../models/study_content.dart';
import '../../../services/auth/learner_local_identity.dart';
import '../collection/flashcard_collection_repository.dart';
import '../collection/flashcard_ownership.dart';
import '../collection/flashcard_unlock_event.dart';
import '../collection/flashcard_unlock_service.dart';
import '../memory/flashcard_memory_statistics.dart';
import '../memory/flashcard_review_repository.dart';
import '../memory/flashcard_review_session_builder.dart';
import '../memory/flashcard_review_session_repository.dart';
import '../memory/flashcard_review_session_state.dart';
import '../models/flashcard.dart';
import '../models/flashcard_source_provenance.dart';
import '../repository/flashcard_package_repository.dart';
import 'flashcard_integration_catalog.dart';
import 'flashcard_integration_models.dart';

class FlashcardIntegrationService {
  FlashcardIntegrationService({
    required FlashcardPackageRepository packageRepository,
    required FlashcardCollectionRepository collectionRepository,
    required FlashcardReviewRepository reviewRepository,
    required FlashcardReviewSessionRepository sessionRepository,
    this.userIdOverride,
  }) : _packageRepository = packageRepository,
       _collectionRepository = collectionRepository,
       _reviewRepository = reviewRepository,
       _sessionRepository = sessionRepository {
    _unlockService = FlashcardUnlockService(
      repository: collectionRepository,
      userIdOverride: userIdOverride,
    );
  }

  factory FlashcardIntegrationService.local({String? userIdOverride}) {
    return FlashcardIntegrationService(
      packageRepository: SharedPreferencesFlashcardPackageRepository(),
      collectionRepository: SharedPreferencesFlashcardCollectionRepository(),
      reviewRepository: SharedPreferencesFlashcardReviewRepository(),
      sessionRepository: SharedPreferencesFlashcardReviewSessionRepository(),
      userIdOverride: userIdOverride,
    );
  }

  final FlashcardPackageRepository _packageRepository;
  final FlashcardCollectionRepository _collectionRepository;
  final FlashcardReviewRepository _reviewRepository;
  final FlashcardReviewSessionRepository _sessionRepository;
  final String? userIdOverride;

  late final FlashcardUnlockService _unlockService;

  String requireLearnerId() {
    return LearnerLocalIdentity.requireCurrentUserId(
      userIdOverride: userIdOverride,
    );
  }

  Future<FlashcardQuestionCompletionResult> recordQuestionCompletion({
    required int questionId,
    required bool correct,
    required String eventId,
    DateTime? occurredAt,
  }) async {
    if (questionId <= 0) {
      throw const FormatException(
        'Flashcard Question completion requires a positive Question ID.',
      );
    }
    if (eventId.trim().isEmpty) {
      throw const FormatException(
        'Flashcard Question completion event ID is required.',
      );
    }

    final catalog = await FlashcardIntegrationCatalog.load(
      repository: _packageRepository,
    );
    final conceptId = catalog.singleConceptForQuestion(questionId);

    if (conceptId == null) {
      return FlashcardQuestionCompletionResult(
        questionId: questionId,
        status: FlashcardQuestionCompletionStatus.noMapping,
      );
    }

    final card = catalog.requireCardForConcept(conceptId);
    final request = FlashcardUnlockRequest(
      eventId: eventId.trim(),
      cardId: card.id,
      conceptId: conceptId,
      source: FlashcardAcquisitionSource.questionCompletion,
      questionOutcome: correct
          ? FlashcardQuestionOutcome.correct
          : FlashcardQuestionOutcome.incorrect,
      questionId: questionId,
      occurredAt: occurredAt,
    );

    final event = await _unlockService.apply(card: card, request: request);
    final status = switch (event.kind) {
      FlashcardUnlockEventKind.newlyCollected =>
        FlashcardQuestionCompletionStatus.newlyCollected,
      FlashcardUnlockEventKind.reinforced =>
        FlashcardQuestionCompletionStatus.reinforced,
      FlashcardUnlockEventKind.duplicateIgnored =>
        FlashcardQuestionCompletionStatus.duplicateIgnored,
    };

    return FlashcardQuestionCompletionResult(
      questionId: questionId,
      status: status,
      conceptId: conceptId,
      cardId: card.id,
      frontLabel: card.frontLabel,
      unlockEvent: event,
    );
  }

  Future<FlashcardQuestionMappingCoverage> questionMappingCoverage(
    Iterable<int> eligibleQuestionIds,
  ) async {
    final catalog = await FlashcardIntegrationCatalog.load(
      repository: _packageRepository,
    );
    final eligible = eligibleQuestionIds.where((id) => id > 0).toSet();
    final mapped = <int>[];
    final unmapped = <int>[];
    final conflicts = <int>[];

    for (final questionId in eligible) {
      final candidates = catalog.questionConceptCandidates[questionId];
      if (candidates == null || candidates.isEmpty) {
        unmapped.add(questionId);
      } else if (candidates.length > 1) {
        conflicts.add(questionId);
      } else {
        mapped.add(questionId);
      }
    }

    final eligibleSorted = eligible.toList()..sort();
    mapped.sort();
    unmapped.sort();
    conflicts.sort();

    return FlashcardQuestionMappingCoverage(
      eligibleQuestionIds: List.unmodifiable(eligibleSorted),
      mappedQuestionIds: List.unmodifiable(mapped),
      unmappedQuestionIds: List.unmodifiable(unmapped),
      conflictingQuestionIds: List.unmodifiable(conflicts),
    );
  }

  Future<FlashcardScopedReviewSummary> scopedReviewSummary({
    required FlashcardReviewScope scope,
    DateTime? now,
  }) async {
    final learnerId = requireLearnerId();
    final at = now ?? DateTime.now();
    final catalog = await FlashcardIntegrationCatalog.load(
      repository: _packageRepository,
    );
    final ownership = await _collectionRepository.loadAllOwnership(
      learnerId: learnerId,
    );
    final reviews = await _reviewRepository.loadAll(learnerId: learnerId);
    final scopedCards = catalog.cardsById.values.where(
      (card) => _matchesScope(card, scope),
    );
    final scopedCardIds = scopedCards.map((card) => card.id).toSet();
    final ownedById = <String, FlashcardOwnership>{
      for (final item in ownership) item.cardId: item,
    };

    final activeSession = await _latestScopedActiveSession(
      learnerId: learnerId,
      scope: scope,
    );

    return FlashcardScopedReviewSummary(
      scope: scope,
      totalCards: scopedCardIds.length,
      ownedCards: scopedCardIds.where(ownedById.containsKey).length,
      dueCards: reviews
          .where(
            (review) =>
                scopedCardIds.contains(review.cardId) && review.isDue(at),
          )
          .length,
      unseenCards: scopedCardIds
          .where((cardId) => ownedById[cardId]?.isUnseen == true)
          .length,
      activeSession: activeSession,
    );
  }

  Future<FlashcardReviewSessionState> startOrResumeScopedReview({
    required FlashcardReviewScope scope,
    DateTime? now,
    int maxCards = 20,
  }) async {
    final learnerId = requireLearnerId();
    final at = now ?? DateTime.now();
    final active = await _latestScopedActiveSession(
      learnerId: learnerId,
      scope: scope,
    );
    if (active != null) {
      return active;
    }

    final catalog = await FlashcardIntegrationCatalog.load(
      repository: _packageRepository,
    );
    final ownership = await _collectionRepository.loadAllOwnership(
      learnerId: learnerId,
    );
    final reviews = await _reviewRepository.loadAll(learnerId: learnerId);

    final scopedCards = <String, Flashcard>{
      for (final card in catalog.cardsById.values)
        if (_matchesScope(card, scope)) card.id: card,
    };
    final scopedIds = scopedCards.keys.toSet();
    final scopedOwnership = <String, FlashcardOwnership>{
      for (final item in ownership)
        if (scopedIds.contains(item.cardId)) item.cardId: item,
    };
    final scopedReviews = reviews
        .where((review) => scopedIds.contains(review.cardId))
        .toList();

    final plan = const FlashcardReviewSessionBuilder().build(
      reviewStates: scopedReviews,
      cardsById: scopedCards,
      ownershipByCardId: scopedOwnership,
      now: at,
      maxCards: maxCards,
    );

    final session = FlashcardReviewSessionState(
      sessionId:
          'fc7-review-${scope.storageKey}-${at.toUtc().microsecondsSinceEpoch}',
      createdAt: at,
      updatedAt: at,
      cardIds: plan.cardIds,
      nextIndex: 0,
      status: plan.isEmpty
          ? FlashcardReviewSessionStatus.completed
          : FlashcardReviewSessionStatus.active,
    );
    session.validate();

    await _sessionRepository.save(
      learnerId: learnerId,
      state: session,
    );
    return session;
  }

  Future<FlashcardStudyContentPlacementReport> validateStudyContentPlacements(
    Iterable<StudyContent> contents,
  ) async {
    final catalog = await FlashcardIntegrationCatalog.load(
      repository: _packageRepository,
    );
    final contentByCompetency = <String, StudyContent>{};

    for (final content in contents) {
      final key = '${content.domainId}|${content.competencyId}';
      final existing = contentByCompetency[key];
      if (existing == null || content.version > existing.version) {
        contentByCompetency[key] = content;
      }
    }

    final issues = <FlashcardStudyContentPlacementIssue>[];

    for (final card in catalog.cardsById.values) {
      final placement = card.primaryPlacement;
      final key = '${placement.domainId}|${placement.competencyId}';
      final content = contentByCompetency[key];

      if (content == null) {
        issues.add(
          FlashcardStudyContentPlacementIssue(
            cardId: card.id,
            level: 'competency',
            identifier: placement.competencyId,
            message:
                'No StudyContent matches ${placement.domainId}/'
                '${placement.competencyId}.',
          ),
        );
        continue;
      }

      if (placement.topicId.isEmpty && placement.subtopicId.isEmpty) {
        continue;
      }

      final topic = content.topics.where(
        (item) => item.id == placement.topicId,
      );
      if (placement.topicId.isNotEmpty && topic.length != 1) {
        issues.add(
          FlashcardStudyContentPlacementIssue(
            cardId: card.id,
            level: 'topic',
            identifier: placement.topicId,
            message: 'Flashcard topic does not resolve in StudyContent.',
          ),
        );
        continue;
      }

      if (placement.subtopicId.isNotEmpty) {
        if (placement.topicId.isEmpty) {
          issues.add(
            FlashcardStudyContentPlacementIssue(
              cardId: card.id,
              level: 'subtopic',
              identifier: placement.subtopicId,
              message: 'Subtopic placement requires a canonical topic.',
            ),
          );
          continue;
        }

        final subtopics = topic.single.subtopics.where(
          (item) => item.id == placement.subtopicId,
        );
        if (subtopics.length != 1) {
          issues.add(
            FlashcardStudyContentPlacementIssue(
              cardId: card.id,
              level: 'subtopic',
              identifier: placement.subtopicId,
              message: 'Flashcard subtopic does not resolve in StudyContent.',
            ),
          );
        }
      }
    }

    return FlashcardStudyContentPlacementReport(
      checkedCards: catalog.cardsById.length,
      issues: List.unmodifiable(issues),
    );
  }

  Future<FlashcardSourceQualityReport> sourceQuality() async {
    final catalog = await FlashcardIntegrationCatalog.load(
      repository: _packageRepository,
    );

    var cardsWithPrimary = 0;
    var cardsWithVerifiedPrimary = 0;

    for (final card in catalog.cardsById.values) {
      final primaryRefs = card.sourceRefs.where((ref) => ref.primary).toList();
      if (primaryRefs.length == 1) {
        cardsWithPrimary++;
        final source = catalog.sourcesById[primaryRefs.single.sourceId];
        if (source?.verificationStatus == SourceVerificationStatus.verified) {
          cardsWithVerifiedPrimary++;
        }
      }
    }

    var verified = 0;
    var needsReview = 0;
    var stale = 0;
    var blocked = 0;
    for (final source in catalog.sourcesById.values) {
      switch (source.verificationStatus) {
        case SourceVerificationStatus.verified:
          verified++;
        case SourceVerificationStatus.needsReview:
          needsReview++;
        case SourceVerificationStatus.stale:
          stale++;
        case SourceVerificationStatus.blocked:
          blocked++;
      }
    }

    return FlashcardSourceQualityReport(
      packageCount: catalog.packages.length,
      cardCount: catalog.cardsById.length,
      sourceCount: catalog.sourcesById.length,
      cardsWithPrimarySource: cardsWithPrimary,
      cardsWithVerifiedPrimarySource: cardsWithVerifiedPrimary,
      verifiedSourceCount: verified,
      needsReviewSourceCount: needsReview,
      staleSourceCount: stale,
      blockedSourceCount: blocked,
    );
  }

  Future<FlashcardCollectionQualityReport> collectionQuality({
    DateTime? now,
  }) async {
    final learnerId = requireLearnerId();
    final at = now ?? DateTime.now();
    final catalog = await FlashcardIntegrationCatalog.load(
      repository: _packageRepository,
    );
    final ownership = await _collectionRepository.loadAllOwnership(
      learnerId: learnerId,
    );
    final reviews = await _reviewRepository.loadAll(learnerId: learnerId);
    final ownershipByCard = <String, FlashcardOwnership>{
      for (final item in ownership) item.cardId: item,
    };

    final orphanOwnership = <String>[];
    final conceptMismatch = <String>[];
    for (final owned in ownership) {
      final card = catalog.cardsById[owned.cardId];
      if (card == null) {
        orphanOwnership.add(owned.cardId);
      } else if (card.conceptId != owned.conceptId) {
        conceptMismatch.add(owned.cardId);
      }
    }

    final orphanReview = <String>[];
    final reviewBeforeReveal = <String>[];
    for (final review in reviews) {
      final owned = ownershipByCard[review.cardId];
      if (owned == null || !catalog.cardsById.containsKey(review.cardId)) {
        orphanReview.add(review.cardId);
      } else if (owned.firstViewedAt == null) {
        reviewBeforeReveal.add(review.cardId);
      }
    }

    orphanOwnership.sort();
    conceptMismatch.sort();
    orphanReview.sort();
    reviewBeforeReveal.sort();

    return FlashcardCollectionQualityReport(
      ownedCount: ownership.length,
      unseenCount: ownership.where((item) => item.isUnseen).length,
      reviewStateCount: reviews.length,
      dueCount: reviews.where((item) => item.isDue(at)).length,
      orphanOwnershipCardIds: List.unmodifiable(orphanOwnership),
      conceptMismatchCardIds: List.unmodifiable(conceptMismatch),
      orphanReviewCardIds: List.unmodifiable(orphanReview),
      reviewBeforeRevealCardIds: List.unmodifiable(reviewBeforeReveal),
    );
  }

  Future<FlashcardLearningTwinSummary> learningTwinSummary({
    DateTime? now,
  }) async {
    final learnerId = requireLearnerId();
    final at = now ?? DateTime.now();
    final catalog = await FlashcardIntegrationCatalog.load(
      repository: _packageRepository,
    );
    final ownership = await _collectionRepository.loadAllOwnership(
      learnerId: learnerId,
    );
    final reviews = await _reviewRepository.loadAll(learnerId: learnerId);
    final ownershipByCard = <String, FlashcardOwnership>{
      for (final item in ownership) item.cardId: item,
    };
    final stats = FlashcardMemoryStatistics.build(
      reviews: reviews,
      now: at,
      ownershipByCardId: ownershipByCard,
    );
    final dueDomains = <String>{};

    for (final review in reviews) {
      if (!review.isDue(at)) {
        continue;
      }
      final card = catalog.cardsById[review.cardId];
      if (card != null) {
        dueDomains.add(card.primaryPlacement.domainId);
      }
    }

    final sortedDomains = dueDomains.toList()..sort();

    return FlashcardLearningTwinSummary(
      ownedCount: ownership.length,
      unseenCount: ownership.where((item) => item.isUnseen).length,
      dueCount: stats.dueCount,
      weakCount: stats.weakCount,
      totalReviewEvents: stats.totalReviewEvents,
      dueDomainIds: List.unmodifiable(sortedDomains),
    );
  }

  Future<FlashcardDiagnosticsReport> diagnostics({
    Iterable<int> eligibleQuestionIds = const <int>[],
    Iterable<StudyContent> studyContent = const <StudyContent>[],
    DateTime? now,
  }) async {
    return FlashcardDiagnosticsReport(
      questionCoverage: await questionMappingCoverage(eligibleQuestionIds),
      placement: await validateStudyContentPlacements(studyContent),
      sourceQuality: await sourceQuality(),
      collectionQuality: await collectionQuality(now: now),
    );
  }

  bool _matchesScope(Flashcard card, FlashcardReviewScope scope) {
    final placement = card.primaryPlacement;
    final domainId = scope.domainId?.trim() ?? '';
    final competencyId = scope.competencyId?.trim() ?? '';
    final topicId = scope.topicId?.trim() ?? '';
    final subtopicId = scope.subtopicId?.trim() ?? '';

    if (domainId.isNotEmpty && placement.domainId != domainId) {
      return false;
    }
    if (competencyId.isNotEmpty && placement.competencyId != competencyId) {
      return false;
    }
    if (topicId.isNotEmpty && placement.topicId != topicId) {
      return false;
    }
    if (subtopicId.isNotEmpty && placement.subtopicId != subtopicId) {
      return false;
    }
    return true;
  }

  Future<FlashcardReviewSessionState?> _latestScopedActiveSession({
    required String learnerId,
    required FlashcardReviewScope scope,
  }) async {
    final prefix = 'fc7-review-${scope.storageKey}-';
    final ids = await _sessionRepository.listSessionIds(learnerId: learnerId);
    FlashcardReviewSessionState? latest;

    for (final id in ids.where((item) => item.startsWith(prefix))) {
      final session = await _sessionRepository.load(
        learnerId: learnerId,
        sessionId: id,
      );
      if (session == null || session.isCompleted) {
        continue;
      }
      if (latest == null || session.updatedAt.isAfter(latest.updatedAt)) {
        latest = session;
      }
    }
    return latest;
  }
}
