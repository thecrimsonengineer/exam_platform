import 'dart:io';

import 'package:exam_platform/features/flashcards/flashcards.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FlashcardContentPackage package;
  late MemoryFlashcardPackageRepository packageRepository;
  late MemoryFlashcardCollectionRepository collectionRepository;
  late MemoryDailyDiscoveryRepository discoveryRepository;
  late MemoryFlashcardReviewRepository reviewRepository;
  late MemoryFlashcardReviewSessionRepository sessionRepository;

  setUp(() {
    package = const FlashcardPackageJsonCodec().decode(
      File(
        'assets/flashcards/run3/fc_reference_package.v1.json',
      ).readAsStringSync(),
    );
    packageRepository = MemoryFlashcardPackageRepository(
      seed: <FlashcardContentPackage>[package],
    );
    collectionRepository = MemoryFlashcardCollectionRepository();
    discoveryRepository = MemoryDailyDiscoveryRepository();
    reviewRepository = MemoryFlashcardReviewRepository();
    sessionRepository = MemoryFlashcardReviewSessionRepository();
  });

  FlashcardLearnerExperienceController buildController(
    DateTime Function() now,
  ) {
    return FlashcardLearnerExperienceController(
      packageRepository: packageRepository,
      collectionRepository: collectionRepository,
      discoveryRepository: discoveryRepository,
      reviewRepository: reviewRepository,
      sessionRepository: sessionRepository,
      userIdOverride: 'fc6-learner',
      now: now,
    );
  }

  test('snapshot aggregates collection, domain and Daily Discovery', () async {
    final now = DateTime.utc(2026, 9, 20, 8);
    final controller = buildController(() => now);

    final snapshot = await controller.load();

    expect(snapshot.cardsById, hasLength(2));
    expect(snapshot.collectionStatistics.totalOwned, 0);
    expect(snapshot.domainSummaries, hasLength(1));
    expect(snapshot.domainSummaries.single.domainId, 'd03');
    expect(snapshot.domainSummaries.single.totalCards, 2);
    expect(snapshot.dailyDiscovery?.status, DailyDiscoveryStatus.offered);
    expect(snapshot.dailyCard, isNotNull);
    expect(snapshot.primarySourceFooterFor(snapshot.dailyCard!.id)?.label,
        contains('Source: NIOSH'));
  });

  test('claim then first reveal activates memory without UI scheduling', () async {
    var now = DateTime.utc(2026, 9, 20, 8);
    final controller = buildController(() => now);

    final claim = await controller.claimDaily();
    var snapshot = controller.lastSnapshot!;

    expect(claim.state.status, DailyDiscoveryStatus.claimed);
    expect(snapshot.collectionStatistics.totalOwned, 1);
    expect(snapshot.collectionStatistics.unseenCount, 1);
    expect(snapshot.memoryStatistics.activeCount, 0);

    await controller.revealCard(claim.state.cardId);
    snapshot = controller.lastSnapshot!;

    expect(snapshot.collectionStatistics.unseenCount, 0);
    expect(snapshot.memoryStatistics.activeCount, 1);
    expect(snapshot.memoryStatistics.dueCount, 0);

    now = now.add(const Duration(days: 2));
    snapshot = await controller.load();

    expect(snapshot.memoryStatistics.dueCount, 1);

    final session = await controller.startOrResumeReview();
    expect(session.cardIds, <String>[claim.state.cardId]);

    final resumed = await controller.load();
    expect(resumed.activeSession?.sessionId, session.sessionId);
    expect(resumed.activeSession?.remainingCount, 1);
  });

  test('conflicting duplicate learner card identity fails closed', () async {
    final duplicate = FlashcardContentPackage(
      schemaVersion: package.schemaVersion,
      deck: package.deck,
      concepts: package.concepts,
      cards: <Flashcard>[
        Flashcard(
          id: package.cards.first.id,
          conceptId: package.cards.first.conceptId,
          version: package.cards.first.version,
          type: package.cards.first.type,
          frontLabel: 'Changed learner wording',
          backDefinition: package.cards.first.backDefinition,
          primaryPlacement: package.cards.first.primaryPlacement,
          sourceRefs: package.cards.first.sourceRefs,
          lifecycle: package.cards.first.lifecycle,
        ),
      ],
      questionMappings: package.questionMappings,
      sources: package.sources,
    );

    final repository = MemoryFlashcardPackageRepository(
      seed: <FlashcardContentPackage>[
        package,
        duplicate,
      ],
    );
    final controller = FlashcardLearnerExperienceController(
      packageRepository: repository,
      collectionRepository: collectionRepository,
      discoveryRepository: discoveryRepository,
      reviewRepository: reviewRepository,
      sessionRepository: sessionRepository,
      userIdOverride: 'fc6-conflict',
      now: () => DateTime.utc(2026, 9, 20, 8),
    );

    await expectLater(controller.load(), throwsA(isA<FormatException>()));
  });
}
