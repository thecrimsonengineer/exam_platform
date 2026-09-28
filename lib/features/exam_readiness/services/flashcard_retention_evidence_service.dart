import '../../flashcards/cloud/published_flashcard_package.dart';
import '../../flashcards/learning/flashcard_recall_event.dart';
import '../../flashcards/learning/flashcard_recall_event_repository.dart';
import '../models/learning_evidence_event.dart';
import '../repositories/learning_evidence_event_repository.dart';
import 'learning_state_update_coordinator.dart';

class FlashcardRecallRecordResult {
  const FlashcardRecallRecordResult({
    required this.recallEvent,
    required this.evidenceEvent,
    required this.recallRecorded,
    required this.evidenceRecorded,
    required this.stateUpdate,
  });

  final FlashcardRecallEvent recallEvent;
  final LearningEvidenceEvent evidenceEvent;
  final bool recallRecorded;
  final bool evidenceRecorded;
  final LearningStateUpdateResult? stateUpdate;
}

abstract interface class FlashcardRecallRuntime {
  Future<List<FlashcardRecallEvent>> loadHistory(String competencyId);

  Future<FlashcardRecallRecordResult> record({
    required String sessionId,
    required String competencyId,
    required FlashcardCard card,
    required FlashcardRecallRating rating,
    required DateTime occurredAt,
    required FlashcardReviewSource source,
    String? blockId,
  });
}

class FlashcardRetentionEvidenceService implements FlashcardRecallRuntime {
  const FlashcardRetentionEvidenceService({
    this.recallRepository,
    this.evidenceRepository,
    this.stateCoordinator,
  });

  final FlashcardRecallEventRepository? recallRepository;
  final LearningEvidenceEventRepository? evidenceRepository;
  final LearningStateUpdateCoordinator? stateCoordinator;

  FlashcardRecallEventRepository get _recallRepository =>
      recallRepository ?? const FlashcardRecallEventRepository();

  LearningEvidenceEventRepository get _evidenceRepository =>
      evidenceRepository ?? const LearningEvidenceEventRepository();

  LearningStateUpdateCoordinator get _stateCoordinator =>
      stateCoordinator ?? const LearningStateUpdateCoordinator();

  @override
  Future<List<FlashcardRecallEvent>> loadHistory(String competencyId) =>
      _recallRepository.loadAll(competencyId: competencyId);

  @override
  Future<FlashcardRecallRecordResult> record({
    required String sessionId,
    required String competencyId,
    required FlashcardCard card,
    required FlashcardRecallRating rating,
    required DateTime occurredAt,
    required FlashcardReviewSource source,
    String? blockId,
  }) async {
    final normalizedCompetency = competencyId.trim().toLowerCase();
    final history = await _recallRepository.loadAll(
      competencyId: normalizedCompetency,
      cardId: card.id,
    );
    final sessionAttempts = history
        .where((event) => event.sessionId == sessionId)
        .toList(growable: false);
    final previous = history.isEmpty ? null : history.last;
    final sameSessionRepeat = previous?.sessionId == sessionId;
    final spacingDays = previous == null || sameSessionRepeat
        ? null
        : _calendarDayDifference(previous.occurredAt, occurredAt);
    final attemptSequence = sessionAttempts.length + 1;

    final recall = FlashcardRecallEvent(
      eventId: _eventId(
        sessionId: sessionId,
        cardId: card.id,
        attemptSequence: attemptSequence,
      ),
      sessionId: sessionId,
      cardId: card.id,
      competencyId: normalizedCompetency,
      conceptLabel: card.frontLabel,
      rating: rating,
      occurredAt: occurredAt,
      attemptSequence: attemptSequence,
      previousRating: previous?.rating,
      previousOccurredAt: previous?.occurredAt,
      spacingIntervalDays: spacingDays,
      sameSessionRepeat: sameSessionRepeat,
      source: source,
      blockId: blockId,
      nextReviewAt: _nextReviewAt(
        rating: rating,
        occurredAt: occurredAt,
        previous: previous,
        spacingDays: spacingDays,
      ),
    );
    recall.validate();

    final recallRecorded = await _recallRepository.append(recall);
    final evidence = toLearningEvidence(recall);

    LearningStateUpdateResult? stateUpdate;
    late final bool evidenceRecorded;
    if (evidence.retentionScore != null) {
      stateUpdate = await _stateCoordinator.processEvidenceEvent(
        event: evidence,
        markFuturePlansStale: false,
        evidenceEventRepository: _evidenceRepository,
      );
      evidenceRecorded = stateUpdate.outcomeRecorded;
    } else {
      evidenceRecorded = await _evidenceRepository.append(evidence);
    }

    return FlashcardRecallRecordResult(
      recallEvent: recall,
      evidenceEvent: evidence,
      recallRecorded: recallRecorded,
      evidenceRecorded: evidenceRecorded,
      stateUpdate: stateUpdate,
    );
  }

  LearningEvidenceEvent toLearningEvidence(FlashcardRecallEvent recall) {
    recall.validate();
    final score = retentionScoreFor(recall);
    final signals = <String>{
      'FLASHCARD_RATING_${recall.rating.name.toUpperCase()}',
      'FLASHCARD_SOURCE_${recall.source.name.toUpperCase()}',
      if (recall.rating == FlashcardRecallRating.again)
        'FLASHCARD_RETENTION_GAP_STRONG',
      if (recall.rating == FlashcardRecallRating.hard)
        'FLASHCARD_RETENTION_GAP_MODERATE',
      if (recall.rating == FlashcardRecallRating.gotIt)
        'FLASHCARD_RECALL_SUCCESS',
      if (recall.isSpaced && recall.isSuccessfulRecall)
        'FLASHCARD_SPACED_SUCCESS',
      if (recall.sameSessionRepeat)
        'FLASHCARD_SAME_SESSION_REPEAT_NO_EXTRA_CREDIT',
      if (score != null) 'FLASHCARD_RETENTION_SAMPLE',
    }.toList(growable: false)..sort();

    final event = LearningEvidenceEvent(
      evidenceEventId: 'erdp9-fc-${recall.eventId}',
      sourceOutcomeId: recall.eventId,
      planId: '',
      planVersion: 0,
      blockId: recall.blockId ?? recall.sessionId,
      domainId: recall.competencyId.substring(0, 3),
      competencyId: recall.competencyId,
      topicId: '',
      subtopicId: '',
      sourceKind: LearningEvidenceSourceKind.flashcard,
      strength: LearningEvidenceStrength.supporting,
      occurredAt: recall.occurredAt,
      questionsAttempted: 0,
      questionsCorrect: 0,
      confidenceSamples: 0,
      contentCompleted: false,
      abandoned: false,
      retentionScore: score,
      signalCodes: signals,
      evidenceUnitId: recall.cardId,
      sourceSessionId: recall.sessionId,
      attemptSequence: recall.attemptSequence,
      spacingIntervalDays: recall.spacingIntervalDays,
      sameSessionRepeat: recall.sameSessionRepeat,
    );
    event.validate();
    return event;
  }

  double? retentionScoreFor(FlashcardRecallEvent recall) {
    if (recall.sameSessionRepeat) return null;
    final spacing = recall.spacingIntervalDays ?? 0;
    switch (recall.rating) {
      case FlashcardRecallRating.again:
        return 0.0;
      case FlashcardRecallRating.hard:
        return spacing >= 1 ? 0.40 : 0.30;
      case FlashcardRecallRating.gotIt:
        if (spacing >= 7) return 0.95;
        if (spacing >= 3) return 0.90;
        if (spacing >= 1) return 0.85;
        return 0.70;
    }
  }

  DateTime _nextReviewAt({
    required FlashcardRecallRating rating,
    required DateTime occurredAt,
    required FlashcardRecallEvent? previous,
    required int? spacingDays,
  }) {
    switch (rating) {
      case FlashcardRecallRating.again:
        return occurredAt.add(const Duration(minutes: 10));
      case FlashcardRecallRating.hard:
        return occurredAt.add(const Duration(days: 1));
      case FlashcardRecallRating.gotIt:
        var intervalDays = 2;
        if (previous?.rating == FlashcardRecallRating.gotIt &&
            (spacingDays ?? 0) >= 1) {
          intervalDays = ((spacingDays ?? 1) * 2).clamp(3, 30).toInt();
        }
        return occurredAt.add(Duration(days: intervalDays));
    }
  }

  int _calendarDayDifference(DateTime previous, DateTime current) {
    final previousDay = DateTime.utc(
      previous.toUtc().year,
      previous.toUtc().month,
      previous.toUtc().day,
    );
    final currentDay = DateTime.utc(
      current.toUtc().year,
      current.toUtc().month,
      current.toUtc().day,
    );
    return currentDay.difference(previousDay).inDays.clamp(0, 36500).toInt();
  }

  String _eventId({
    required String sessionId,
    required String cardId,
    required int attemptSequence,
  }) {
    String safe(String value) =>
        value.trim().replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_');
    return 'fc-${safe(sessionId)}-${safe(cardId)}-a$attemptSequence';
  }
}
