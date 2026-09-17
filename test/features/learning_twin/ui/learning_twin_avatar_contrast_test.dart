import 'package:exam_platform/features/learning_twin/ui/learning_twin_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<Color> renderAvatarBox(
    WidgetTester tester, {
    required ThemeData theme,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Scaffold(body: Center(child: LearningTwinAvatar())),
      ),
    );

    final avatarFinder = find.byType(LearningTwinAvatar);
    expect(avatarFinder, findsOneWidget);

    final boxFinder = find.descendant(
      of: avatarFinder,
      matching: find.byType(ColoredBox),
    );
    expect(boxFinder, findsOneWidget);

    return tester.widget<ColoredBox>(boxFinder).color;
  }

  testWidgets('light mode gives the avatar a dark inverse-surface box', (
    tester,
  ) async {
    final theme = ThemeData.light(useMaterial3: true);
    final color = await renderAvatarBox(tester, theme: theme);

    expect(color, theme.colorScheme.inverseSurface);
    expect(color.computeLuminance(), lessThan(0.5));
  });

  testWidgets('dark mode gives the avatar a light inverse-surface box', (
    tester,
  ) async {
    final theme = ThemeData.dark(useMaterial3: true);
    final color = await renderAvatarBox(tester, theme: theme);

    expect(color, theme.colorScheme.inverseSurface);
    expect(color.computeLuminance(), greaterThan(0.5));
  });
}
