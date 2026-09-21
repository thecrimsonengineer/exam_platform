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
    final now = DateTime.utc(2026, 9, 21, 8);
    final card = package.cards.first;

    final ownership = FlashcardOwnership(
      cardId: card.id,
      conceptId: card.conceptId,
      acquiredAt: now.subtract(const Duration(hours: 2)),
      acquisitionSource: FlashcardAcquisitionSource.dailyDiscovery,
      firstQuestionOutcome: FlashcardQuestionOutcome.notApplicable,
      appliedEventIds: const <String>['fc8-responsive-owned'],
    );
    ownership.validate();
    await collectionRepository.saveOwnership(
      learnerId: 'fc8-responsive',
      ownership: ownership,
    );

    return FlashcardLearnerExperienceController(
      packageRepository: packageRepository,
      collectionRepository: collectionRepository,
      discoveryRepository: MemoryDailyDiscoveryRepository(),
      reviewRepository: MemoryFlashcardReviewRepository(),
      sessionRepository: MemoryFlashcardReviewSessionRepository(),
      userIdOverride: 'fc8-responsive',
      now: () => now,
    );
  }

  Future<void> pump(
    WidgetTester tester, {
    required double width,
    required ThemeMode themeMode,
    double textScale = 1,
    bool disableAnimations = false,
  }) async {
    tester.view.physicalSize = Size(width, 1200);
    tester.view.devicePixelRatio = 1;

    final controller = await buildController();
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(useMaterial3: true),
        darkTheme: ThemeData.dark(useMaterial3: true),
        themeMode: themeMode,
        builder: (context, child) {
          final media = MediaQuery.of(context);
          return MediaQuery(
            data: media.copyWith(
              textScaler: TextScaler.linear(textScale),
              disableAnimations: disableAnimations,
            ),
            child: child!,
          );
        },
        home: FlashcardsScreen(controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('My Collection'), findsWidgets);
    expect(find.text('DAILY DISCOVERY'), findsOneWidget);
    expect(find.text('Collection by Domain'), findsOneWidget);
    expect(tester.takeException(), isNull);
  }

  tearDown(() {
    // Tests deliberately mutate the synthetic display surface.
  });

  testWidgets('FC8 phone widths render in both light and dark modes', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final width in <double>[360, 390, 412, 430]) {
      await pump(tester, width: width, themeMode: ThemeMode.light);
      await pump(tester, width: width, themeMode: ThemeMode.dark);
    }
  });

  testWidgets('FC8 tablet layout remains healthy in light and dark modes', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pump(tester, width: 900, themeMode: ThemeMode.light);
    await pump(tester, width: 900, themeMode: ThemeMode.dark);

    expect(
      find.byKey(const ValueKey('flashcards-review-button')),
      findsOneWidget,
    );
  });

  testWidgets('FC8 supports large text with reduced motion enabled', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pump(
      tester,
      width: 390,
      themeMode: ThemeMode.dark,
      textScale: 2,
      disableAnimations: true,
    );

    expect(find.text('Hierarchy of Controls'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
