import 'dart:io';

import 'package:exam_platform/features/learning_twin/ui/learning_twin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpAt(
    WidgetTester tester,
    Widget child, {
    Size size = const Size(390, 844),
    Brightness brightness = Brightness.light,
    bool disableAnimations = false,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          brightness: brightness,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: brightness,
          ),
        ),
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            disableAnimations: disableAnimations,
          ),
          child: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: child,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('remaining M2 surfaces render at narrow phone width', (
    tester,
  ) async {
    await pumpAt(
      tester,
      Column(
        children: [
          LearningTwinInlineBlock(
            title: 'Inline',
            message: 'Inline guidance.',
            actionLabel: 'Review',
            onAction: () {},
          ),
          const SizedBox(height: 12),
          LearningTwinCoachSheet(
            title: 'Coach',
            message: 'Choose a next step.',
            primaryActionLabel: 'Continue',
            onPrimaryAction: () {},
            onDismiss: () {},
          ),
          const SizedBox(height: 12),
          LearningTwinCelebration(
            title: 'Milestone',
            message: 'Progress acknowledged.',
            actionLabel: 'Done',
            onAction: () {},
          ),
        ],
      ),
      size: const Size(320, 760),
    );

    expect(find.text('Inline guidance.'), findsOneWidget);
    expect(find.text('Choose a next step.'), findsOneWidget);
    expect(find.text('Progress acknowledged.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'M2 completion surfaces support dark and reduced-motion contexts',
    (tester) async {
      await pumpAt(
        tester,
        const Column(
          children: [
            LearningTwinInlineBlock(
              title: 'Dark inline',
              message: 'Dark theme parity.',
            ),
            SizedBox(height: 12),
            LearningTwinCoachSheet(
              title: 'Dark coach',
              message: 'Reduced-motion safe.',
            ),
            SizedBox(height: 12),
            LearningTwinCelebration(
              title: 'Dark milestone',
              message: 'Static celebration.',
            ),
          ],
        ),
        brightness: Brightness.dark,
        disableAnimations: true,
      );

      expect(find.text('Dark theme parity.'), findsOneWidget);
      expect(find.text('Reduced-motion safe.'), findsOneWidget);
      expect(find.text('Static celebration.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('coach sheet exposes standard dismiss control', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await pumpAt(
        tester,
        LearningTwinCoachSheet(
          title: 'Coach',
          message: 'Accessible controls.',
          onDismiss: () {},
        ),
      );

      expect(find.byTooltip('Dismiss guidance'), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp('Learning guide coaching')),
        findsOneWidget,
      );
    } finally {
      semantics.dispose();
    }
  });

  test('M2 runtime UI remains presentation-only', () async {
    final directory = Directory('lib/features/learning_twin/ui');
    expect(directory.existsSync(), isTrue);

    final dartFiles = directory
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    const forbidden = <String>[
      'avatar_maker',
      'cloud_firestore',
      'firebase_',
      'Navigator.',
      'showDialog(',
      'showModalBottomSheet(',
      'AnimationController',
      'AnimatedBuilder',
      'TickerProvider',
    ];

    for (final file in dartFiles) {
      final text = await file.readAsString();
      for (final token in forbidden) {
        expect(
          text,
          isNot(contains(token)),
          reason: '$token leaked into ${file.path}',
        );
      }
    }
  });

  test('M2 barrel exports the complete presentation catalog', () async {
    final barrel = await File(
      'lib/features/learning_twin/ui/learning_twin_ui.dart',
    ).readAsString();

    for (final exportName in <String>[
      'learning_twin_avatar.dart',
      'learning_twin_bubble.dart',
      'learning_twin_card.dart',
      'learning_twin_compact_tip.dart',
      'learning_twin_hero.dart',
      'learning_twin_inline_block.dart',
      'learning_twin_coach_sheet.dart',
      'learning_twin_celebration.dart',
    ]) {
      expect(barrel, contains(exportName));
    }
  });
}
