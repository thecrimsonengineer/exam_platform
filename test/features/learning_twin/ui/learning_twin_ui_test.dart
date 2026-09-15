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
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: child,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('canonical avatar exposes image semantics', (tester) async {
    await pumpAt(tester, const LearningTwinAvatar(size: 48));

    expect(find.bySemanticsLabel('Naveed Learning Guide'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('M2.1 components render at narrow phone width', (tester) async {
    await pumpAt(
      tester,
      Column(
        children: [
          const LearningTwinBubble(message: 'Explain this safely.'),
          const SizedBox(height: 12),
          LearningTwinCard(
            title: 'Card',
            message: 'Responsive card content.',
            onDismiss: () {},
          ),
          const SizedBox(height: 12),
          LearningTwinCompactTip(message: 'Compact guidance.', onTap: () {}),
          const SizedBox(height: 12),
          LearningTwinHero(
            title: 'Hero',
            message: 'Large but unobtrusive treatment.',
            onAction: () {},
            actionLabel: 'Continue',
          ),
        ],
      ),
      size: const Size(320, 760),
    );

    expect(find.text('Explain this safely.'), findsOneWidget);
    expect(find.text('Compact guidance.'), findsOneWidget);
    expect(find.text('Hero'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('M2.1 components render in dark theme', (tester) async {
    await pumpAt(
      tester,
      const LearningTwinBubble(
        asset: LearningTwinAsset.explain,
        message: 'Dark theme parity.',
      ),
      brightness: Brightness.dark,
    );

    expect(find.text('Dark theme parity.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('runtime Twin UI has no avatar_maker or Firebase imports', () async {
    final directory = Directory('lib/features/learning_twin/ui');
    expect(directory.existsSync(), isTrue);

    final dartFiles = directory
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    for (final file in dartFiles) {
      final text = await file.readAsString();
      expect(
        text,
        isNot(contains('avatar_maker')),
        reason: 'avatar_maker leaked into ${file.path}',
      );
      expect(
        text,
        isNot(contains('cloud_firestore')),
        reason: 'Firestore leaked into ${file.path}',
      );
      expect(
        text,
        isNot(contains('firebase_')),
        reason: 'Firebase leaked into ${file.path}',
      );
    }
  });

  test('M2.1 remains isolated from production entry points', () async {
    final main = await File('lib/main.dart').readAsString();
    final navigation = await File(
      'lib/screens/navigation/bottom_navigation.dart',
    ).readAsString();

    expect(main, isNot(contains('features/learning_twin/ui')));
    expect(navigation, isNot(contains('features/learning_twin/ui')));
    expect(main, isNot(contains('learning_twin_ui_showcase')));
    expect(navigation, isNot(contains('learning_twin_ui_showcase')));
  });
}
