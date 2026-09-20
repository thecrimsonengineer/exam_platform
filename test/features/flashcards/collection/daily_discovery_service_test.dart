import 'dart:io';

import 'package:exam_platform/features/flashcards/flashcards.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late FlashcardContentPackage referencePackage;
  late Flashcard hierarchy;
  late Flashcard elimination;

  setUpAll(() {
    referencePackage = const FlashcardPackageJsonCodec().decode(
      File(
        'assets/flashcards/run3/fc_reference_package.v1.json',
      ).readAsStringSync(),
    );
    hierarchy = referencePackage.cards.firstWhere(
      (card) => card.id == 'csp11.flashcard.hierarchy_of_controls',
    );
    elimination = referencePackage.cards.firstWhere(
      (card) => card.id == 'csp11.flashcard.elimination_control',
    );
  });

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  DailyDiscoveryService buildDaily({
    required String learnerId,
    required FlashcardCollectionRepository collection,
    DailyDiscoveryRepository? discovery,
  }) {
    final unlock = FlashcardUnlockService(
      repository: collection,
      userIdOverride: learnerId,
    );
    return DailyDiscoveryService(
      discoveryRepository: discovery ?? MemoryDailyDiscoveryRepository(),
      unlockService: unlock,
      userIdOverride: learnerId,
    );
  }

  test(
    'same learner and local date get the same deterministic offer',
    () async {
      final date = DateTime(2026, 9, 20);
      final a = buildDaily(
        learnerId: 'learner-daily',
        collection: MemoryFlashcardCollectionRepository(),
      );
      final b = buildDaily(
        learnerId: 'learner-daily',
        collection: MemoryFlashcardCollectionRepository(),
      );

      final offerA = await a.offerForDate(
        localDate: date,
        packages: <FlashcardContentPackage>[referencePackage],
      );
      final offerB = await b.offerForDate(
        localDate: date,
        packages: <FlashcardContentPackage>[referencePackage],
      );

      expect(offerA.status, DailyDiscoveryStatus.offered);
      expect(offerB.cardId, offerA.cardId);
      expect(offerB.conceptId, offerA.conceptId);
      expect(offerB.unlockEventId, offerA.unlockEventId);
    },
  );

  test('reopening the same day returns the persisted offer', () async {
    final collection = MemoryFlashcardCollectionRepository();
    final discovery = MemoryDailyDiscoveryRepository();
    final service = buildDaily(
      learnerId: 'learner-reopen',
      collection: collection,
      discovery: discovery,
    );
    final date = DateTime(2026, 9, 20);

    final first = await service.offerForDate(
      localDate: date,
      packages: <FlashcardContentPackage>[referencePackage],
      offeredAt: DateTime.utc(2026, 9, 20, 6),
    );
    final second = await service.offerForDate(
      localDate: date,
      packages: <FlashcardContentPackage>[referencePackage],
      offeredAt: DateTime.utc(2026, 9, 20, 18),
    );

    expect(second.toJson(), first.toJson());
  });

  test('Daily Discovery selects only an unowned FCQ100 card', () async {
    final collection = MemoryFlashcardCollectionRepository();
    final unlock = FlashcardUnlockService(
      repository: collection,
      userIdOverride: 'learner-filter',
    );
    await unlock.apply(
      card: hierarchy,
      request: FlashcardUnlockRequest(
        eventId: 'quiz:filter',
        cardId: hierarchy.id,
        conceptId: hierarchy.conceptId,
        source: FlashcardAcquisitionSource.questionCompletion,
        questionOutcome: FlashcardQuestionOutcome.correct,
        questionId: 930001,
      ),
    );

    final service = DailyDiscoveryService(
      discoveryRepository: MemoryDailyDiscoveryRepository(),
      unlockService: unlock,
      userIdOverride: 'learner-filter',
    );

    final offer = await service.offerForDate(
      localDate: DateTime(2026, 9, 20),
      packages: <FlashcardContentPackage>[referencePackage],
    );

    expect(offer.cardId, elimination.id);
  });

  test('package that fails FCQ100 contributes no Daily Discovery card', () async {
    final json = referencePackage.toJson();
    final cards = json['cards'] as List<dynamic>;
    final first = Map<String, dynamic>.from(cards.first as Map);
    first['whyItMatters'] = '';
    cards[0] = first;
    final invalidPackage = FlashcardContentPackage.fromJson(json);

    final service = buildDaily(
      learnerId: 'learner-invalid-package',
      collection: MemoryFlashcardCollectionRepository(),
    );
    final state = await service.offerForDate(
      localDate: DateTime(2026, 9, 20),
      packages: <FlashcardContentPackage>[invalidPackage],
    );

    expect(state.status, DailyDiscoveryStatus.empty);
  });

  test('Daily Discovery rejects mismatched learner identity', () async {
    final unlock = FlashcardUnlockService(
      repository: MemoryFlashcardCollectionRepository(),
      userIdOverride: 'learner-b',
    );
    final service = DailyDiscoveryService(
      discoveryRepository: MemoryDailyDiscoveryRepository(),
      unlockService: unlock,
      userIdOverride: 'learner-a',
    );

    await expectLater(
      service.offerForDate(
        localDate: DateTime(2026, 9, 20),
        packages: <FlashcardContentPackage>[referencePackage],
      ),
      throwsStateError,
    );
  });

  test('claim is idempotent and never creates duplicate ownership', () async {
    final collection = MemoryFlashcardCollectionRepository();
    final discovery = MemoryDailyDiscoveryRepository();
    final service = buildDaily(
      learnerId: 'learner-claim',
      collection: collection,
      discovery: discovery,
    );
    final date = DateTime(2026, 9, 20);

    final first = await service.claimForDate(
      localDate: date,
      packages: <FlashcardContentPackage>[referencePackage],
      claimedAt: DateTime.utc(2026, 9, 20, 12),
    );
    final second = await service.claimForDate(
      localDate: date,
      packages: <FlashcardContentPackage>[referencePackage],
      claimedAt: DateTime.utc(2026, 9, 20, 13),
    );

    expect(first.state.status, DailyDiscoveryStatus.claimed);
    expect(first.unlockEvent?.kind, FlashcardUnlockEventKind.newlyCollected);
    expect(second.state.status, DailyDiscoveryStatus.claimed);
    expect(second.unlockEvent?.kind, FlashcardUnlockEventKind.duplicateIgnored);

    final owned = await collection.loadAllOwnership(learnerId: 'learner-claim');
    expect(owned, hasLength(1));
    expect(owned.single.reinforcementCount, 0);
  });

  test('all-owned collection receives a persisted empty day', () async {
    final collection = MemoryFlashcardCollectionRepository();
    final unlock = FlashcardUnlockService(
      repository: collection,
      userIdOverride: 'learner-complete',
    );

    await unlock.apply(
      card: hierarchy,
      request: FlashcardUnlockRequest(
        eventId: 'quiz:all:one',
        cardId: hierarchy.id,
        conceptId: hierarchy.conceptId,
        source: FlashcardAcquisitionSource.questionCompletion,
        questionOutcome: FlashcardQuestionOutcome.correct,
        questionId: 930001,
      ),
    );
    await unlock.apply(
      card: elimination,
      request: FlashcardUnlockRequest(
        eventId: 'quiz:all:two',
        cardId: elimination.id,
        conceptId: elimination.conceptId,
        source: FlashcardAcquisitionSource.questionCompletion,
        questionOutcome: FlashcardQuestionOutcome.incorrect,
        questionId: 930002,
      ),
    );

    final discovery = MemoryDailyDiscoveryRepository();
    final service = DailyDiscoveryService(
      discoveryRepository: discovery,
      unlockService: unlock,
      userIdOverride: 'learner-complete',
    );

    final first = await service.offerForDate(
      localDate: DateTime(2026, 9, 20),
      packages: <FlashcardContentPackage>[referencePackage],
    );
    final second = await service.offerForDate(
      localDate: DateTime(2026, 9, 20),
      packages: <FlashcardContentPackage>[referencePackage],
    );

    expect(first.status, DailyDiscoveryStatus.empty);
    expect(first.hasOffer, isFalse);
    expect(second.toJson(), first.toJson());
  });

  test('SharedPreferences Daily Discovery state is learner-scoped', () async {
    final repository = SharedPreferencesDailyDiscoveryRepository();
    final state = DailyDiscoveryState(
      dateKey: '2026-09-20',
      status: DailyDiscoveryStatus.offered,
      offeredAt: DateTime.utc(2026, 9, 20, 7),
      cardId: hierarchy.id,
      conceptId: hierarchy.conceptId,
      unlockEventId: 'daily:2026-09-20:${hierarchy.id}',
    );

    await repository.saveState(learnerId: 'learner-a', state: state);

    expect(
      await repository.loadState(
        learnerId: 'learner-a',
        dateKey: '2026-09-20',
      ),
      isNotNull,
    );
    expect(
      await repository.loadState(
        learnerId: 'learner-b',
        dateKey: '2026-09-20',
      ),
      isNull,
    );
  });
}
