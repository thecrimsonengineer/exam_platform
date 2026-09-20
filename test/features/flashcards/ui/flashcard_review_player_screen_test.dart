import 'dart:io';

import 'package:exam_platform/features/flashcards/flashcards.dart';
import 'package:exam_platform/screens/flashcards/widgets/flashcard_review_player_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FlashcardContentPackage package;

  setUpAll(() {
    package = const FlashcardPackageJsonCodec().decode(
      File(
        'assets/flashcards/run3/fc_reference_package.v1.json',
      ).readAsStringSync(),
    );
  });

  testWidgets(
    'review player reveals source and keeps rating buttons available',
    (tester) async {
      final now = DateTime.utc(2026, 9, 22, 8);
      final firstViewed = DateTime.utc(2026, 9, 20, 8);
      final card = package.cards.first;

      final packageRepository = MemoryFlashcardPackageRepository(
        seed: <FlashcardContentPackage>[package],
      );
      final collectionRepository = MemoryFlashcardCollectionRepository();
      final reviewRepository = MemoryFlashcardReviewRepository();
      final sessionRepository = MemoryFlashcardReviewSessionRepository();

      final ownership = FlashcardOwnership(
        cardId: card.id,
        conceptId: card.conceptId,
        acquiredAt: firstViewed.subtract(const Duration(hours: 1)),
        acquisitionSource: FlashcardAcquisitionSource.dailyDiscovery,
        firstQuestionOutcome: FlashcardQuestionOutcome.notApplicable,
        firstViewedAt: firstViewed,
        appliedEventIds: const <String>['seed-review'],
      );
      ownership.validate();
      await collectionRepository.saveOwnership(
        learnerId: 'fc6-review-widget',
        ownership: ownership,
      );

      final review = FlashcardReviewState(
        cardId: card.id,
        conceptId: card.conceptId,
        activatedAt: firstViewed,
        stage: FlashcardReviewStage.learning,
        dueAt: firstViewed.add(const Duration(days: 1)),
        intervalMinutes: FlashcardIntervalPolicy.initialIntervalMinutes,
      );
      review.validate();
      await reviewRepository.save(
        learnerId: 'fc6-review-widget',
        state: review,
      );

      final controller = FlashcardLearnerExperienceController(
        packageRepository: packageRepository,
        collectionRepository: collectionRepository,
        discoveryRepository: MemoryDailyDiscoveryRepository(),
        reviewRepository: reviewRepository,
        sessionRepository: sessionRepository,
        userIdOverride: 'fc6-review-widget',
        now: () => now,
      );

      final snapshot = await controller.load(at: now);
      final session = await controller.startOrResumeReview(at: now);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(useMaterial3: true),
          home: FlashcardReviewPlayerScreen(
            controller: controller,
            snapshot: snapshot,
            session: session,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hierarchy of Controls'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('review-reveal-button')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('review-reveal-button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('review-again-button')), findsOneWidget);
      expect(find.byKey(const ValueKey('review-hard-button')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('review-got-it-button')),
        findsOneWidget,
      );
      expect(find.textContaining('Source: NIOSH'), findsOneWidget);

      await tester.tap(find.byKey(ValueKey('flashcard-source-${card.id}')));
      await tester.pumpAndSettle();

      expect(find.text('Source details'), findsOneWidget);
      expect(find.text('Open official source'), findsOneWidget);

      await tester.tap(find.byTooltip('Close source details'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('review-got-it-button')));
      await tester.pumpAndSettle();

      expect(find.text('Memory session complete'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
