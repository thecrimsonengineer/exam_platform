import 'dart:async';

import '../../../services/auth/learner_local_identity.dart';
import '../models/flashcard.dart';
import '../models/flashcard_lifecycle.dart';
import 'flashcard_collection_repository.dart';
import 'flashcard_collection_statistics.dart';
import 'flashcard_ownership.dart';
import 'flashcard_unlock_event.dart';

class FlashcardUnlockService {
  FlashcardUnlockService({
    required FlashcardCollectionRepository repository,
    this.userIdOverride,
  }) : _repository = repository;

  final FlashcardCollectionRepository _repository;
  final String? userIdOverride;

  static final Map<String, Future<void>> _mutationTails =
      <String, Future<void>>{};

  String requireLearnerId() {
    return LearnerLocalIdentity.requireCurrentUserId(
      userIdOverride: userIdOverride,
    );
  }

  Future<bool> isOwned(String cardId) async {
    final learnerId = requireLearnerId();
    return _repository.loadOwnership(
          learnerId: learnerId,
          cardId: cardId,
        ) !=
        null;
  }

  Future<FlashcardUnlockEvent> apply({
    required Flashcard card,
    required FlashcardUnlockRequest request,
  }) {
    final learnerId = requireLearnerId();
    final lockKey = '$learnerId|${card.id}';

    return _serialize(
      lockKey,
      () => _applyLocked(
        learnerId: learnerId,
        card: card,
        request: request,
      ),
    );
  }

  Future<FlashcardOwnership> markFirstViewed({
    required String cardId,
    DateTime? viewedAt,
  }) {
    final learnerId = requireLearnerId();
    final lockKey = '$learnerId|$cardId';

    return _serialize(lockKey, () async {
      final existing = await _repository.loadOwnership(
        learnerId: learnerId,
        cardId: cardId,
      );
      if (existing == null) {
        throw StateError(
          'Cannot mark an unowned Flashcard as first-viewed: $cardId',
        );
      }

      if (existing.firstViewedAt != null) {
        return existing;
      }

      final updated = existing.copyWith(
        firstViewedAt: viewedAt ?? DateTime.now(),
      );
      await _repository.saveOwnership(
        learnerId: learnerId,
        ownership: updated,
      );
      return updated;
    });
  }

  Future<List<FlashcardOwnership>> loadCollection() {
    return _repository.loadAllOwnership(learnerId: requireLearnerId());
  }

  Future<FlashcardCollectionStatistics> statistics() async {
    final records = await loadCollection();
    return FlashcardCollectionStatistics.fromOwnership(records);
  }

  Future<FlashcardUnlockEvent> _applyLocked({
    required String learnerId,
    required Flashcard card,
    required FlashcardUnlockRequest request,
  }) async {
    _validate(card: card, request: request);

    final eventId = request.eventId.trim();
    final occurredAt = request.occurredAt ?? DateTime.now();
    final existing = await _repository.loadOwnership(
      learnerId: learnerId,
      cardId: card.id,
    );

    if (existing != null && existing.hasAppliedEvent(eventId)) {
      return FlashcardUnlockEvent(
        eventId: eventId,
        cardId: card.id,
        conceptId: card.conceptId,
        kind: FlashcardUnlockEventKind.duplicateIgnored,
        source: request.source,
        questionOutcome: request.questionOutcome,
        occurredAt: occurredAt,
        ownership: existing,
        questionId: request.questionId,
      );
    }

    if (existing == null) {
      final counts = _questionSignalDelta(request.questionOutcome);
      final ownership = FlashcardOwnership(
        cardId: card.id,
        conceptId: card.conceptId,
        acquiredAt: occurredAt,
        acquisitionSource: request.source,
        firstQuestionOutcome: request.questionOutcome,
        correctSignalCount: counts.correct,
        incorrectSignalCount: counts.incorrect,
        appliedEventIds: <String>[eventId],
      );

      await _repository.saveOwnership(
        learnerId: learnerId,
        ownership: ownership,
      );

      return FlashcardUnlockEvent(
        eventId: eventId,
        cardId: card.id,
        conceptId: card.conceptId,
        kind: FlashcardUnlockEventKind.newlyCollected,
        source: request.source,
        questionOutcome: request.questionOutcome,
        occurredAt: occurredAt,
        ownership: ownership,
        questionId: request.questionId,
      );
    }

    if (existing.conceptId != card.conceptId) {
      throw FormatException(
        'Owned Flashcard concept identity changed for ${card.id}.',
      );
    }

    final counts = _questionSignalDelta(request.questionOutcome);
    final updated = existing.copyWith(
      reinforcementCount: existing.reinforcementCount + 1,
      lastReinforcedAt: occurredAt,
      correctSignalCount: existing.correctSignalCount + counts.correct,
      incorrectSignalCount: existing.incorrectSignalCount + counts.incorrect,
      appliedEventIds: <String>[...existing.appliedEventIds, eventId],
    );

    await _repository.saveOwnership(
      learnerId: learnerId,
      ownership: updated,
    );

    return FlashcardUnlockEvent(
      eventId: eventId,
      cardId: card.id,
      conceptId: card.conceptId,
      kind: FlashcardUnlockEventKind.reinforced,
      source: request.source,
      questionOutcome: request.questionOutcome,
      occurredAt: occurredAt,
      ownership: updated,
      questionId: request.questionId,
    );
  }

  static void _validate({
    required Flashcard card,
    required FlashcardUnlockRequest request,
  }) {
    if (request.eventId.trim().isEmpty) {
      throw const FormatException('Flashcard unlock event ID is required.');
    }
    if (request.cardId != card.id || request.conceptId != card.conceptId) {
      throw const FormatException(
        'Flashcard unlock request identity does not match the card.',
      );
    }
    if (card.lifecycle != FlashcardLifecycle.validated &&
        card.lifecycle != FlashcardLifecycle.bundled) {
      throw FormatException(
        'Flashcard ${card.id} is not learner-ready for collection.',
      );
    }

    switch (request.source) {
      case FlashcardAcquisitionSource.questionCompletion:
        if (request.questionId == null || request.questionId! <= 0) {
          throw const FormatException(
            'Question completion unlock requires a positive Question ID.',
          );
        }
        if (request.questionOutcome == FlashcardQuestionOutcome.notApplicable) {
          throw const FormatException(
            'Question completion unlock requires correct/incorrect outcome.',
          );
        }
      case FlashcardAcquisitionSource.dailyDiscovery:
        if (request.questionId != null) {
          throw const FormatException(
            'Daily Discovery unlock cannot carry a Question ID.',
          );
        }
        if (request.questionOutcome !=
            FlashcardQuestionOutcome.notApplicable) {
          throw const FormatException(
            'Daily Discovery unlock cannot carry a Question outcome.',
          );
        }
    }
  }

  static ({int correct, int incorrect}) _questionSignalDelta(
    FlashcardQuestionOutcome outcome,
  ) {
    return switch (outcome) {
      FlashcardQuestionOutcome.correct => (correct: 1, incorrect: 0),
      FlashcardQuestionOutcome.incorrect => (correct: 0, incorrect: 1),
      FlashcardQuestionOutcome.notApplicable => (correct: 0, incorrect: 0),
    };
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
