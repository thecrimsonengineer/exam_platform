import 'dart:async';

import '../../../services/auth/learner_local_identity.dart';
import '../collection/flashcard_ownership.dart';
import 'flashcard_interval_policy.dart';
import 'flashcard_review_event.dart';
import 'flashcard_review_repository.dart';
import 'flashcard_review_state.dart';

class FlashcardMemoryService {
  FlashcardMemoryService({
    required FlashcardReviewRepository repository,
    FlashcardIntervalPolicy intervalPolicy = const FlashcardIntervalPolicy(),
    this.userIdOverride,
  }) : _repository = repository,
       _intervalPolicy = intervalPolicy;

  final FlashcardReviewRepository _repository;
  final FlashcardIntervalPolicy _intervalPolicy;
  final String? userIdOverride;

  static final Map<String, Future<void>> _mutationTails =
      <String, Future<void>>{};

  String requireLearnerId() {
    return LearnerLocalIdentity.requireCurrentUserId(
      userIdOverride: userIdOverride,
    );
  }

  Future<FlashcardReviewState?> activateFromOwnership(
    FlashcardOwnership ownership,
  ) {
    final learnerId = requireLearnerId();
    final lockKey = '$learnerId|${ownership.cardId}';

    return _serialize(lockKey, () async {
      ownership.validate();

      final firstViewedAt = ownership.firstViewedAt;
      if (firstViewedAt == null) {
        return null;
      }

      final existing = await _repository.load(
        learnerId: learnerId,
        cardId: ownership.cardId,
      );

      if (existing != null) {
        if (existing.conceptId != ownership.conceptId) {
          throw FormatException(
            'Flashcard memory concept identity changed for '
            '${ownership.cardId}.',
          );
        }
        if (existing.activatedAt != firstViewedAt) {
          throw FormatException(
            'Flashcard memory activation does not match first reveal for '
            '${ownership.cardId}.',
          );
        }
        return existing;
      }

      final state = FlashcardReviewState(
        cardId: ownership.cardId,
        conceptId: ownership.conceptId,
        activatedAt: firstViewedAt,
        stage: FlashcardReviewStage.learning,
        dueAt: firstViewedAt.add(
          const Duration(
            minutes: FlashcardIntervalPolicy.initialIntervalMinutes,
          ),
        ),
        intervalMinutes: FlashcardIntervalPolicy.initialIntervalMinutes,
      );
      state.validate();

      await _repository.save(learnerId: learnerId, state: state);
      return state;
    });
  }

  Future<FlashcardReviewState?> load(String cardId) {
    return _repository.load(learnerId: requireLearnerId(), cardId: cardId);
  }

  Future<List<FlashcardReviewState>> loadAll() {
    return _repository.loadAll(learnerId: requireLearnerId());
  }

  Future<FlashcardReviewEventResult> rate({
    required String eventId,
    required String cardId,
    required String conceptId,
    required FlashcardReviewRating rating,
    DateTime? reviewedAt,
  }) {
    final learnerId = requireLearnerId();
    final lockKey = '$learnerId|$cardId';

    return _serialize(lockKey, () async {
      final normalizedEventId = eventId.trim();
      if (normalizedEventId.isEmpty) {
        throw const FormatException('Flashcard review event ID is required.');
      }

      final existing = await _repository.load(
        learnerId: learnerId,
        cardId: cardId,
      );
      if (existing == null) {
        throw StateError('Flashcard memory is not active for $cardId.');
      }
      if (existing.conceptId != conceptId) {
        throw const FormatException(
          'Flashcard review Concept identity does not match memory state.',
        );
      }

      final at = reviewedAt ?? DateTime.now();
      if (at.isBefore(existing.activatedAt)) {
        throw const FormatException(
          'Flashcard review cannot precede memory activation.',
        );
      }

      if (existing.hasAppliedEvent(normalizedEventId)) {
        return FlashcardReviewEventResult(
          eventId: normalizedEventId,
          kind: FlashcardReviewEventKind.duplicateIgnored,
          rating: rating,
          reviewedAt: at,
          state: existing,
        );
      }

      final decision = _intervalPolicy.next(current: existing, rating: rating);
      final next = existing.copyWith(
        stage: decision.stage,
        dueAt: at.add(Duration(minutes: decision.intervalMinutes)),
        intervalMinutes: decision.intervalMinutes,
        reviewCount: existing.reviewCount + 1,
        lapseCount: existing.lapseCount + decision.lapseDelta,
        againCount:
            existing.againCount +
            (rating == FlashcardReviewRating.again ? 1 : 0),
        hardCount:
            existing.hardCount + (rating == FlashcardReviewRating.hard ? 1 : 0),
        gotItCount:
            existing.gotItCount +
            (rating == FlashcardReviewRating.gotIt ? 1 : 0),
        gotItStreak: decision.nextGotItStreak,
        lastReviewedAt: at,
        lastRating: rating,
        appliedReviewEventIds: <String>[
          ...existing.appliedReviewEventIds,
          normalizedEventId,
        ],
      );
      next.validate();

      await _repository.save(learnerId: learnerId, state: next);

      return FlashcardReviewEventResult(
        eventId: normalizedEventId,
        kind: FlashcardReviewEventKind.applied,
        rating: rating,
        reviewedAt: at,
        state: next,
      );
    });
  }

  static Future<T> _serialize<T>(
    String key,
    Future<T> Function() action,
  ) async {
    final previous = _mutationTails[key] ?? Future<void>.value();
    final gate = Completer<void>();
    final tail = previous.then((_) => gate.future);
    _mutationTails[key] = tail;

    await previous;
    try {
      return await action();
    } finally {
      gate.complete();
      if (identical(_mutationTails[key], tail)) {
        _mutationTails.remove(key);
      }
    }
  }
}
