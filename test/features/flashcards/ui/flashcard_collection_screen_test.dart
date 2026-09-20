import 'dart:io';

import 'package:exam_platform/features/flashcards/flashcards.dart';
import 'package:exam_platform/screens/flashcards/flashcards_screen.dart';
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

  Future<FlashcardLearnerExperienceController> buildController() async {
    final packageRepository = MemoryFlashcardPackageRepository(
      seed: <FlashcardContentPackage>[package],
    );
    final collectionRepository = MemoryFlashcardCollectionRepository();
    final now = DateTime.utc(2026, 9, 20, 8);
    final owned = FlashcardOwnership(
      cardId: package.cards.first.id,
      conceptId: package.cards.first.conceptId,
      acquiredAt: now.subtract(const Duration(hours: 1)),
      acquisitionSource: FlashcardAcquisitionSource.dailyDiscovery,
      firstQuestionOutcome: FlashcardQuestionOutcome.notApplicable,
      appliedEventIds: const <String>['seed-owned'],
    );
    owned.validate();
    await collectionRepository.saveOwnership(
      learnerId: 'fc6-widget',
      ownership: owned,
    );

    return FlashcardLearnerExperienceController(
      packageRepository: packageRepository,
      collectionRepository: collectionRepository,
      discoveryRepository: MemoryDailyDiscoveryRepository(),
      reviewRepository: MemoryFlashcardReviewRepository(),
      sessionRepository: MemoryFlashcardReviewSessionRepository(),
      userIdOverride: 'fc6-widget',
      now: () => now,
    );
  }

  Future<void> pumpAtWidth(
    WidgetTester tester, {
    required double width,
    required ThemeMode themeMode,
  }) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = await buildController();
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(useMaterial3: true),
        darkTheme: ThemeData.dark(useMaterial3: true),
        themeMode: themeMode,
        home: FlashcardsScreen(controller: controller),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Collection home renders at phone width in light mode', (
    tester,
  ) async {
    await pumpAtWidth(tester, width: 360, themeMode: ThemeMode.light);

    expect(find.text('My Collection'), findsWidgets);
    expect(find.text('DAILY DISCOVERY'), findsOneWidget);
    expect(find.text('Newly Collected'), findsOneWidget);
    expect(find.text('Collection by Domain'), findsOneWidget);
    expect(find.text('Hierarchy of Controls'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Collection home renders at tablet width in dark mode', (
    tester,
  ) async {
    await pumpAtWidth(tester, width: 900, themeMode: ThemeMode.dark);

    expect(find.text('My Collection'), findsWidgets);
    expect(find.text('Domain 3'), findsWidgets);
    expect(
      find.byKey(const ValueKey('flashcards-review-button')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
