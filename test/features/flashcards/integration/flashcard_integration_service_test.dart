import 'dart:convert';
import 'dart:io';

import 'package:exam_platform/features/flashcards/flashcards.dart';
import 'package:exam_platform/models/study_content.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FlashcardContentPackage referencePackage;
  late MemoryFlashcardPackageRepository packageRepository;
  late MemoryFlashcardCollectionRepository collectionRepository;
  late MemoryFlashcardReviewRepository reviewRepository;
  late MemoryFlashcardReviewSessionRepository sessionRepository;

  setUp(() {
    referencePackage = const FlashcardPackageJsonCodec().decode(
      File(
        'assets/flashcards/run3/fc_reference_package.v1.json',
      ).readAsStringSync(),
    );
    packageRepository = MemoryFlashcardPackageRepository(
      seed: <FlashcardContentPackage>[referencePackage],
    );
    collectionRepository = MemoryFlashcardCollectionRepository();
    reviewRepository = MemoryFlashcardReviewRepository();
    sessionRepository = MemoryFlashcardReviewSessionRepository();
  });

  FlashcardIntegrationService service({
    String learnerId = 'fc7-learner',
  }) {
    return FlashcardIntegrationService(
      packageRepository: packageRepository,
      collectionRepository: collectionRepository,
      reviewRepository: reviewRepository,
      sessionRepository: sessionRepository,
      userIdOverride: learnerId,
    );
  }

  test('Question completion resolves mapping and collects after persistence',
      () async {
    final integration = service();
    final at = DateTime.utc(2026, 9, 20, 10);

    final result = await integration.recordQuestionCompletion(
      questionId: 930001,
      correct: false,
      eventId: 'quiz-attempt-1-q930001',
      occurredAt: at,
    );

    expect(
      result.status,
      FlashcardQuestionCompletionStatus.newlyCollected,
    );
    expect(result.conceptId, 'csp11.concept.hierarchy_of_controls');
    expect(result.cardId, 'csp11.flashcard.hierarchy_of_controls');
    expect(result.frontLabel, 'Hierarchy of Controls');
    expect(result.unlockEvent?.ownership.acquiredAt, at);
    expect(result.unlockEvent?.ownership.incorrectSignalCount, 1);

    final persisted = await collectionRepository.loadOwnership(
      learnerId: 'fc7-learner',
      cardId: 'csp11.flashcard.hierarchy_of_controls',
    );
    expect(persisted, isNotNull);
  });

  test('repeated mapped Question reinforces and same event is idempotent',
      () async {
    final integration = service();

    final first = await integration.recordQuestionCompletion(
      questionId: 930001,
      correct: true,
      eventId: 'quiz-attempt-1-q930001',
      occurredAt: DateTime.utc(2026, 9, 20, 10),
    );
    final reinforced = await integration.recordQuestionCompletion(
      questionId: 930001,
      correct: false,
      eventId: 'quiz-attempt-2-q930001',
      occurredAt: DateTime.utc(2026, 9, 20, 11),
    );
    final duplicate = await integration.recordQuestionCompletion(
      questionId: 930001,
      correct: false,
      eventId: 'quiz-attempt-2-q930001',
      occurredAt: DateTime.utc(2026, 9, 20, 11),
    );

    expect(
      first.status,
      FlashcardQuestionCompletionStatus.newlyCollected,
    );
    expect(
      reinforced.status,
      FlashcardQuestionCompletionStatus.reinforced,
    );
    expect(
      duplicate.status,
      FlashcardQuestionCompletionStatus.duplicateIgnored,
    );
    expect(duplicate.unlockEvent?.ownership.reinforcementCount, 1);
    expect(duplicate.unlockEvent?.ownership.correctSignalCount, 1);
    expect(duplicate.unlockEvent?.ownership.incorrectSignalCount, 1);
  });

  test('unmapped Question is a no-op rather than a Quiz failure', () async {
    final result = await service().recordQuestionCompletion(
      questionId: 999999,
      correct: true,
      eventId: 'quiz-attempt-unmapped',
    );

    expect(result.status, FlashcardQuestionCompletionStatus.noMapping);
    expect(
      await collectionRepository.loadAllOwnership(
        learnerId: 'fc7-learner',
      ),
      isEmpty,
    );
  });

  test('aggregate mapping coverage identifies unmapped Questions', () async {
    final report = await service().questionMappingCoverage(
      const <int>[930001, 930002, 930003],
    );

    expect(report.mappedQuestionIds, <int>[930001, 930002]);
    expect(report.unmappedQuestionIds, <int>[930003]);
    expect(report.conflictingQuestionIds, isEmpty);
    expect(report.coverageRatio, closeTo(2 / 3, 0.0001));
    expect(report.passed, isFalse);
  });

  test('conflicting cross-package Question mapping fails closed', () async {
    final json = referencePackage.toJson();
    final deck = Map<String, dynamic>.from(json['deck']! as Map)
      ..['id'] = 'd03_c02_flashcards_v2'
      ..['version'] = 2;
    json['deck'] = deck;

    final mappings = (json['questionMappings']! as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    mappings.first['conceptId'] = 'csp11.concept.elimination_control';
    json['questionMappings'] = mappings;

    final conflicting = FlashcardContentPackage.fromJson(json);
    expect(const Fcq100Validator().validate(conflicting).passed, isTrue);

    packageRepository = MemoryFlashcardPackageRepository(
      seed: <FlashcardContentPackage>[
        referencePackage,
        conflicting,
      ],
    );

    final report = await service().questionMappingCoverage(
      const <int>[930001, 930002],
    );
    expect(report.conflictingQuestionIds, <int>[930001]);

    await expectLater(
      service().recordQuestionCompletion(
        questionId: 930001,
        correct: true,
        eventId: 'conflict',
      ),
      throwsFormatException,
    );
  });

  test('StudyContent placement validation uses real canonical hierarchy',
      () async {
    const content = StudyContent(
      id: 'content-d03-c02-v1',
      domainId: 'd03',
      competencyId: 'd03_c02',
      competencyNumber: 2,
      title: 'Risk Management',
      status: 'published',
      version: 1,
      topics: <StudyTopic>[],
    );

    final valid = await service().validateStudyContentPlacements(
      const <StudyContent>[content],
    );
    final invalid = await service().validateStudyContentPlacements(
      const <StudyContent>[],
    );

    expect(valid.passed, isTrue);
    expect(valid.checkedCards, 2);
    expect(invalid.passed, isFalse);
    expect(invalid.issues, hasLength(2));
    expect(invalid.issues.every((issue) => issue.level == 'competency'), isTrue);
  });

  test('scoped review includes only due cards inside requested placement',
      () async {
    final card = referencePackage.cards.first;
    final viewedAt = DateTime.utc(2026, 9, 18, 8);
    final now = DateTime.utc(2026, 9, 20, 8);

    final ownership = FlashcardOwnership(
      cardId: card.id,
      conceptId: card.conceptId,
      acquiredAt: viewedAt.subtract(const Duration(hours: 1)),
      acquisitionSource: FlashcardAcquisitionSource.questionCompletion,
      firstQuestionOutcome: FlashcardQuestionOutcome.correct,
      firstViewedAt: viewedAt,
      correctSignalCount: 1,
      appliedEventIds: const <String>['seed-question'],
    );
    ownership.validate();
    await collectionRepository.saveOwnership(
      learnerId: 'fc7-learner',
      ownership: ownership,
    );

    final review = FlashcardReviewState(
      cardId: card.id,
      conceptId: card.conceptId,
      activatedAt: viewedAt,
      stage: FlashcardReviewStage.learning,
      dueAt: viewedAt.add(const Duration(days: 1)),
      intervalMinutes: FlashcardIntervalPolicy.initialIntervalMinutes,
    );
    review.validate();
    await reviewRepository.save(
      learnerId: 'fc7-learner',
      state: review,
    );

    const scope = FlashcardReviewScope(
      domainId: 'd03',
      competencyId: 'd03_c02',
    );
    final summary = await service().scopedReviewSummary(
      scope: scope,
      now: now,
    );
    final session = await service().startOrResumeScopedReview(
      scope: scope,
      now: now,
    );

    expect(summary.totalCards, 2);
    expect(summary.ownedCards, 1);
    expect(summary.dueCards, 1);
    expect(session.cardIds, <String>[card.id]);

    final resumed = await service().startOrResumeScopedReview(
      scope: scope,
      now: now.add(const Duration(minutes: 5)),
    );
    expect(resumed.sessionId, session.sessionId);
  });

  test('source and collection quality reports expose actionable health',
      () async {
    final source = await service().sourceQuality();
    final collection = await service().collectionQuality(
      now: DateTime.utc(2026, 9, 20, 8),
    );

    expect(source.packageCount, 1);
    expect(source.cardCount, 2);
    expect(source.cardsWithPrimarySource, 2);
    expect(source.cardsWithVerifiedPrimarySource, 2);
    expect(source.verifiedSourceCount, 1);
    expect(source.passed, isTrue);

    expect(collection.ownedCount, 0);
    expect(collection.orphanOwnershipCardIds, isEmpty);
    expect(collection.orphanReviewCardIds, isEmpty);
    expect(collection.passed, isTrue);
  });

  test('Learning Twin summary is sanitized to counts and Domain IDs only',
      () async {
    final card = referencePackage.cards.first;
    final viewedAt = DateTime.utc(2026, 9, 18, 8);
    final now = DateTime.utc(2026, 9, 20, 8);
    final ownership = FlashcardOwnership(
      cardId: card.id,
      conceptId: card.conceptId,
      acquiredAt: viewedAt.subtract(const Duration(hours: 1)),
      acquisitionSource: FlashcardAcquisitionSource.questionCompletion,
      firstQuestionOutcome: FlashcardQuestionOutcome.incorrect,
      firstViewedAt: viewedAt,
      incorrectSignalCount: 1,
      appliedEventIds: const <String>['seed-twin'],
    );
    ownership.validate();
    await collectionRepository.saveOwnership(
      learnerId: 'fc7-learner',
      ownership: ownership,
    );

    final review = FlashcardReviewState(
      cardId: card.id,
      conceptId: card.conceptId,
      activatedAt: viewedAt,
      stage: FlashcardReviewStage.relearning,
      dueAt: now.subtract(const Duration(minutes: 1)),
      intervalMinutes: FlashcardIntervalPolicy.relearningIntervalMinutes,
      reviewCount: 1,
      lapseCount: 1,
      againCount: 1,
      lastReviewedAt: now.subtract(const Duration(minutes: 11)),
      lastRating: FlashcardReviewRating.again,
      appliedReviewEventIds: const <String>['review-again'],
    );
    review.validate();
    await reviewRepository.save(
      learnerId: 'fc7-learner',
      state: review,
    );

    final summary = await service().learningTwinSummary(now: now);
    final json = summary.toSanitizedJson();
    final encoded = jsonEncode(json);

    expect(summary.ownedCount, 1);
    expect(summary.dueCount, 1);
    expect(summary.weakCount, 1);
    expect(summary.dueDomainIds, <String>['d03']);
    expect(encoded, isNot(contains('Hierarchy of Controls')));
    expect(encoded, isNot(contains('csp11.flashcard')));
    expect(encoded, isNot(contains('930001')));
    expect(encoded, isNot(contains('cdc.gov')));
    expect(
      json.keys,
      <String>[
        'ownedCount',
        'unseenCount',
        'dueCount',
        'weakCount',
        'totalReviewEvents',
        'dueDomainIds',
      ],
    );
  });
}
