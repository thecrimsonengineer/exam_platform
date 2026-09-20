import 'dart:io';

import 'package:exam_platform/features/flashcards/flashcards.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FlashcardContentPackage referencePackage;
  late Flashcard hierarchy;

  setUpAll(() {
    referencePackage = const FlashcardPackageJsonCodec().decode(
      File(
        'assets/flashcards/run3/fc_reference_package.v1.json',
      ).readAsStringSync(),
    );
    hierarchy = referencePackage.cards.firstWhere(
      (card) => card.id == 'csp11.flashcard.hierarchy_of_controls',
    );
  });

  FlashcardOwnership owned(
    Flashcard card, {
    required DateTime firstViewedAt,
  }) {
    final value = FlashcardOwnership(
      cardId: card.id,
      conceptId: card.conceptId,
      acquiredAt: firstViewedAt.subtract(const Duration(hours: 1)),
      acquisitionSource: FlashcardAcquisitionSource.dailyDiscovery,
      firstQuestionOutcome: FlashcardQuestionOutcome.notApplicable,
      firstViewedAt: firstViewedAt,
      appliedEventIds: <String>['daily:${card.id}'],
    );
    value.validate();
    return value;
  }

  FlashcardReviewState dueState(
    Flashcard card, {
    required DateTime activatedAt,
    required DateTime dueAt,
  }) {
    return FlashcardReviewState(
      cardId: card.id,
      conceptId: card.conceptId,
      activatedAt: activatedAt,
      stage: FlashcardReviewStage.learning,
      dueAt: dueAt,
      intervalMinutes: FlashcardIntervalPolicy.initialIntervalMinutes,
    );
  }

  test('session builder interleaves sibling groups when possible', () {
    final now = DateTime.utc(2026, 9, 25, 8);
    final activated = DateTime.utc(2026, 9, 20, 8);
    final cardA = hierarchy;
    final cardB = Flashcard(
      id: 'csp11.flashcard.synthetic_b',
      conceptId: 'csp11.concept.synthetic_b',
      version: hierarchy.version,
      type: hierarchy.type,
      frontLabel: 'Synthetic B',
      backDefinition: hierarchy.backDefinition,
      primaryPlacement: hierarchy.primaryPlacement,
      whyItMatters: hierarchy.whyItMatters,
      keyPoint: hierarchy.keyPoint,
      sourceRefs: hierarchy.sourceRefs,
      lifecycle: hierarchy.lifecycle,
      tags: hierarchy.tags,
    );
    final cardC = Flashcard(
      id: 'csp11.flashcard.synthetic_c',
      conceptId: 'csp11.concept.synthetic_c',
      version: hierarchy.version,
      type: hierarchy.type,
      frontLabel: 'Synthetic C',
      backDefinition: hierarchy.backDefinition,
      primaryPlacement: const FlashcardPlacement(
        domainId: 'd04',
        competencyId: 'd04_c01',
      ),
      whyItMatters: hierarchy.whyItMatters,
      keyPoint: hierarchy.keyPoint,
      sourceRefs: hierarchy.sourceRefs,
      lifecycle: hierarchy.lifecycle,
      tags: hierarchy.tags,
    );

    final reviews = <FlashcardReviewState>[
      dueState(
        cardA,
        activatedAt: activated,
        dueAt: now.subtract(const Duration(hours: 3)),
      ),
      dueState(
        cardB,
        activatedAt: activated,
        dueAt: now.subtract(const Duration(hours: 2)),
      ),
      dueState(
        cardC,
        activatedAt: activated,
        dueAt: now.subtract(const Duration(hours: 1)),
      ),
    ];
    final ownership = <String, FlashcardOwnership>{
      cardA.id: owned(cardA, firstViewedAt: activated),
      cardB.id: owned(cardB, firstViewedAt: activated),
      cardC.id: owned(cardC, firstViewedAt: activated),
    };

    final plan = const FlashcardReviewSessionBuilder().build(
      reviewStates: reviews,
      cardsById: <String, Flashcard>{
        cardA.id: cardA,
        cardB.id: cardB,
        cardC.id: cardC,
      },
      ownershipByCardId: ownership,
      now: now,
    );

    expect(
      plan.cardIds,
      <String>[cardA.id, cardC.id, cardB.id],
    );
  });

  test('interrupted session retry does not double-count a review', () async {
    final firstViewed = DateTime.utc(2026, 9, 20, 8);
    final now = DateTime.utc(2026, 9, 22, 8);
    final ownership = owned(
      hierarchy,
      firstViewedAt: firstViewed,
    );

    final reviewRepository = MemoryFlashcardReviewRepository();
    final memoryService = FlashcardMemoryService(
      repository: reviewRepository,
      userIdOverride: 'learner-recovery',
    );
    await memoryService.activateFromOwnership(ownership);

    final sessionRepository = _FailSecondSaveSessionRepository();
    final sessionService = FlashcardReviewSessionService(
      sessionRepository: sessionRepository,
      memoryService: memoryService,
      userIdOverride: 'learner-recovery',
    );

    final started = await sessionService.startOrResume(
      sessionId: 'session-recovery',
      now: now,
      cardsById: <String, Flashcard>{
        hierarchy.id: hierarchy,
      },
      ownershipByCardId: <String, FlashcardOwnership>{
        hierarchy.id: ownership,
      },
    );
    expect(started.currentCardId, hierarchy.id);

    await expectLater(
      sessionService.rateCurrent(
        sessionId: 'session-recovery',
        rating: FlashcardReviewRating.gotIt,
        reviewedAt: now,
      ),
      throwsStateError,
    );

    final afterFailure = await memoryService.load(hierarchy.id);
    expect(afterFailure?.reviewCount, 1);

    final resumable = await sessionService.load('session-recovery');
    expect(resumable?.nextIndex, 0);
    expect(resumable?.currentCardId, hierarchy.id);

    final retried = await sessionService.rateCurrent(
      sessionId: 'session-recovery',
      rating: FlashcardReviewRating.gotIt,
      reviewedAt: now,
    );

    expect(
      retried.reviewEvent.kind,
      FlashcardReviewEventKind.duplicateIgnored,
    );
    expect(retried.session.isCompleted, isTrue);

    final finalState = await memoryService.load(hierarchy.id);
    expect(finalState?.reviewCount, 1);
    expect(finalState?.gotItCount, 1);
  });

  test('startOrResume returns the persisted session unchanged', () async {
    final firstViewed = DateTime.utc(2026, 9, 20, 8);
    final now = DateTime.utc(2026, 9, 22, 8);
    final ownership = owned(
      hierarchy,
      firstViewedAt: firstViewed,
    );

    final memoryService = FlashcardMemoryService(
      repository: MemoryFlashcardReviewRepository(),
      userIdOverride: 'learner-resume',
    );
    await memoryService.activateFromOwnership(ownership);

    final repository = MemoryFlashcardReviewSessionRepository();
    final service = FlashcardReviewSessionService(
      sessionRepository: repository,
      memoryService: memoryService,
      userIdOverride: 'learner-resume',
    );

    final first = await service.startOrResume(
      sessionId: 'session-same',
      now: now,
      cardsById: <String, Flashcard>{
        hierarchy.id: hierarchy,
      },
      ownershipByCardId: <String, FlashcardOwnership>{
        hierarchy.id: ownership,
      },
    );
    final second = await service.startOrResume(
      sessionId: 'session-same',
      now: now.add(const Duration(hours: 1)),
      cardsById: <String, Flashcard>{},
      ownershipByCardId: <String, FlashcardOwnership>{},
    );

    expect(second.toJson(), first.toJson());
  });
}

class _FailSecondSaveSessionRepository
    extends MemoryFlashcardReviewSessionRepository {
  int _saveCalls = 0;
  bool _failed = false;

  @override
  Future<void> save({
    required String learnerId,
    required FlashcardReviewSessionState state,
  }) async {
    _saveCalls++;
    if (_saveCalls == 2 && !_failed) {
      _failed = true;
      throw StateError('simulated session checkpoint failure');
    }
    await super.save(learnerId: learnerId, state: state);
  }
}
