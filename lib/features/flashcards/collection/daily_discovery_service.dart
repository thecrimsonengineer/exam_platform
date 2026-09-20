import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../../services/auth/learner_local_identity.dart';
import '../models/flashcard.dart';
import '../models/flashcard_content_package.dart';
import '../validation/fcq100_validator.dart';
import 'daily_discovery_repository.dart';
import 'daily_discovery_state.dart';
import 'flashcard_ownership.dart';
import 'flashcard_unlock_event.dart';
import 'flashcard_unlock_service.dart';

class DailyDiscoveryClaimResult {
  const DailyDiscoveryClaimResult({
    required this.state,
    required this.unlockEvent,
  });

  final DailyDiscoveryState state;
  final FlashcardUnlockEvent? unlockEvent;
}

class DailyDiscoveryService {
  DailyDiscoveryService({
    required DailyDiscoveryRepository discoveryRepository,
    required FlashcardUnlockService unlockService,
    Fcq100Validator fcq100 = const Fcq100Validator(),
    this.userIdOverride,
  }) : _discoveryRepository = discoveryRepository,
       _unlockService = unlockService,
       _fcq100 = fcq100;

  final DailyDiscoveryRepository _discoveryRepository;
  final FlashcardUnlockService _unlockService;
  final Fcq100Validator _fcq100;
  final String? userIdOverride;

  Future<DailyDiscoveryState> offerForDate({
    required DateTime localDate,
    required Iterable<FlashcardContentPackage> packages,
    DateTime? offeredAt,
  }) async {
    final learnerId = _requireAlignedLearnerId();
    final dateKey = localDateKey(localDate);

    final existing = await _discoveryRepository.loadState(
      learnerId: learnerId,
      dateKey: dateKey,
    );
    if (existing != null) {
      return existing;
    }

    final owned = await _unlockService.loadCollection();
    final ownedIds = owned.map((item) => item.cardId).toSet();
    final eligibleById = <String, Flashcard>{};

    for (final contentPackage in packages) {
      if (!_fcq100.validate(contentPackage).passed) {
        continue;
      }

      for (final card in contentPackage.cards) {
        if (ownedIds.contains(card.id)) {
          continue;
        }

        final previous = eligibleById[card.id];
        if (previous != null && previous.conceptId != card.conceptId) {
          throw FormatException(
            'Daily Discovery found conflicting canonical card: ${card.id}.',
          );
        }
        eligibleById[card.id] = card;
      }
    }

    final candidates = eligibleById.values.toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    final now = offeredAt ?? DateTime.now();

    if (candidates.isEmpty) {
      final state = DailyDiscoveryState(
        dateKey: dateKey,
        status: DailyDiscoveryStatus.empty,
        offeredAt: now,
      );
      state.validate();
      await _discoveryRepository.saveState(learnerId: learnerId, state: state);
      return state;
    }

    final selected =
        candidates[_deterministicIndex(
          learnerId: learnerId,
          dateKey: dateKey,
          length: candidates.length,
        )];
    final eventId = 'daily:$dateKey:${selected.id}';

    final state = DailyDiscoveryState(
      dateKey: dateKey,
      status: DailyDiscoveryStatus.offered,
      offeredAt: now,
      cardId: selected.id,
      conceptId: selected.conceptId,
      unlockEventId: eventId,
    );
    state.validate();
    await _discoveryRepository.saveState(learnerId: learnerId, state: state);
    return state;
  }

  Future<DailyDiscoveryClaimResult> claimForDate({
    required DateTime localDate,
    required Iterable<FlashcardContentPackage> packages,
    DateTime? claimedAt,
  }) async {
    _requireAlignedLearnerId();

    final packageList = packages.toList(growable: false);
    final state = await offerForDate(
      localDate: localDate,
      packages: packageList,
      offeredAt: claimedAt,
    );

    if (!state.hasOffer) {
      return DailyDiscoveryClaimResult(state: state, unlockEvent: null);
    }

    final card = _findOfferedCard(
      cardId: state.cardId,
      conceptId: state.conceptId,
      packages: packageList,
    );
    final at = claimedAt ?? DateTime.now();

    final event = await _unlockService.apply(
      card: card,
      request: FlashcardUnlockRequest(
        eventId: state.unlockEventId,
        cardId: card.id,
        conceptId: card.conceptId,
        source: FlashcardAcquisitionSource.dailyDiscovery,
        questionOutcome: FlashcardQuestionOutcome.notApplicable,
        occurredAt: at,
      ),
    );

    if (state.isClaimed) {
      return DailyDiscoveryClaimResult(state: state, unlockEvent: event);
    }

    final learnerId = _requireAlignedLearnerId();
    final claimed = state.markClaimed(at);
    await _discoveryRepository.saveState(learnerId: learnerId, state: claimed);

    return DailyDiscoveryClaimResult(state: claimed, unlockEvent: event);
  }

  static String localDateKey(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _requireAlignedLearnerId() {
    final learnerId = LearnerLocalIdentity.requireCurrentUserId(
      userIdOverride: userIdOverride,
    );
    final unlockLearnerId = _unlockService.requireLearnerId();
    if (learnerId != unlockLearnerId) {
      throw StateError(
        'Daily Discovery and Flashcard unlock learner identities differ.',
      );
    }
    return learnerId;
  }

  static int _deterministicIndex({
    required String learnerId,
    required String dateKey,
    required int length,
  }) {
    if (length <= 0) {
      throw ArgumentError.value(length, 'length', 'Must be positive.');
    }

    final digest = sha256.convert(
      utf8.encode('csp11.daily.v1|$learnerId|$dateKey'),
    );
    final prefix = digest.toString().substring(0, 12);
    final value = int.parse(prefix, radix: 16);
    return value % length;
  }

  static Flashcard _findOfferedCard({
    required String cardId,
    required String conceptId,
    required Iterable<FlashcardContentPackage> packages,
  }) {
    for (final contentPackage in packages) {
      for (final card in contentPackage.cards) {
        if (card.id == cardId && card.conceptId == conceptId) {
          return card;
        }
      }
    }

    throw StateError(
      'Daily Discovery offered card is no longer available: $cardId',
    );
  }
}
