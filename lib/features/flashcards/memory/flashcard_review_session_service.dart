import '../../../services/auth/learner_local_identity.dart';
import '../collection/flashcard_ownership.dart';
import '../models/flashcard.dart';
import 'flashcard_memory_service.dart';
import 'flashcard_review_event.dart';
import 'flashcard_review_session_builder.dart';
import 'flashcard_review_session_repository.dart';
import 'flashcard_review_session_state.dart';
import 'flashcard_review_state.dart';

class FlashcardReviewSessionStepResult {
  const FlashcardReviewSessionStepResult({
    required this.session,
    required this.reviewEvent,
  });

  final FlashcardReviewSessionState session;
  final FlashcardReviewEventResult reviewEvent;
}

class FlashcardReviewSessionService {
  FlashcardReviewSessionService({
    required FlashcardReviewSessionRepository sessionRepository,
    required FlashcardMemoryService memoryService,
    FlashcardReviewSessionBuilder sessionBuilder =
        const FlashcardReviewSessionBuilder(),
    this.userIdOverride,
  }) : _sessionRepository = sessionRepository,
       _memoryService = memoryService,
       _sessionBuilder = sessionBuilder;

  final FlashcardReviewSessionRepository _sessionRepository;
  final FlashcardMemoryService _memoryService;
  final FlashcardReviewSessionBuilder _sessionBuilder;
  final String? userIdOverride;

  Future<FlashcardReviewSessionState> startOrResume({
    required String sessionId,
    required DateTime now,
    required Map<String, Flashcard> cardsById,
    required Map<String, FlashcardOwnership> ownershipByCardId,
    int maxCards = 20,
  }) async {
    final learnerId = _requireAlignedLearnerId();
    final normalizedSessionId = sessionId.trim();
    if (normalizedSessionId.isEmpty) {
      throw const FormatException(
        'Flashcard review session ID is required.',
      );
    }

    final existing = await _sessionRepository.load(
      learnerId: learnerId,
      sessionId: normalizedSessionId,
    );
    if (existing != null) {
      return existing;
    }

    final reviews = await _memoryService.loadAll();
    final plan = _sessionBuilder.build(
      reviewStates: reviews,
      cardsById: cardsById,
      ownershipByCardId: ownershipByCardId,
      now: now,
      maxCards: maxCards,
    );

    final state = FlashcardReviewSessionState(
      sessionId: normalizedSessionId,
      createdAt: now,
      updatedAt: now,
      cardIds: plan.cardIds,
      nextIndex: 0,
      status: plan.isEmpty
          ? FlashcardReviewSessionStatus.completed
          : FlashcardReviewSessionStatus.active,
    );
    state.validate();

    await _sessionRepository.save(
      learnerId: learnerId,
      state: state,
    );
    return state;
  }

  Future<FlashcardReviewSessionState?> load(String sessionId) {
    final learnerId = _requireAlignedLearnerId();
    return _sessionRepository.load(
      learnerId: learnerId,
      sessionId: sessionId,
    );
  }

  Future<FlashcardReviewSessionStepResult> rateCurrent({
    required String sessionId,
    required FlashcardReviewRating rating,
    DateTime? reviewedAt,
  }) async {
    final learnerId = _requireAlignedLearnerId();
    final session = await _sessionRepository.load(
      learnerId: learnerId,
      sessionId: sessionId,
    );
    if (session == null) {
      throw StateError(
        'Flashcard review session does not exist: $sessionId',
      );
    }
    if (session.isCompleted || session.currentCardId == null) {
      throw StateError(
        'Flashcard review session is already complete: $sessionId',
      );
    }

    final cardId = session.currentCardId!;
    final review = await _memoryService.load(cardId);
    if (review == null) {
      throw StateError(
        'Flashcard memory state is missing for session card: $cardId',
      );
    }

    final at = reviewedAt ?? DateTime.now();
    final eventId =
        'review:$sessionId:${session.nextIndex}:$cardId';
    final reviewEvent = await _memoryService.rate(
      eventId: eventId,
      cardId: cardId,
      conceptId: review.conceptId,
      rating: rating,
      reviewedAt: at,
    );

    final advanced = session.advance(at);
    advanced.validate();

    await _sessionRepository.save(
      learnerId: learnerId,
      state: advanced,
    );

    return FlashcardReviewSessionStepResult(
      session: advanced,
      reviewEvent: reviewEvent,
    );
  }

  Future<List<String>> listSessionIds() {
    final learnerId = _requireAlignedLearnerId();
    return _sessionRepository.listSessionIds(
      learnerId: learnerId,
    );
  }

  String _requireAlignedLearnerId() {
    final learnerId = LearnerLocalIdentity.requireCurrentUserId(
      userIdOverride: userIdOverride,
    );
    final memoryLearnerId = _memoryService.requireLearnerId();
    if (learnerId != memoryLearnerId) {
      throw StateError(
        'Flashcard review session and memory learner identities differ.',
      );
    }
    return learnerId;
  }
}
