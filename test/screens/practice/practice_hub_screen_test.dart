import 'package:exam_platform/screens/practice/practice_hub_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpHub(
    WidgetTester tester, {
    required Brightness brightness,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.indigo,
            brightness: brightness,
          ),
        ),
        home: const PracticeHubScreen(),
      ),
    );
    await tester.pump();
  }

  testWidgets('Practice hub renders all five modes in light mode', (
    tester,
  ) async {
    await pumpHub(tester, brightness: Brightness.light);

    expect(find.byKey(const ValueKey('practice-hub-daily')), findsOneWidget);
    expect(find.byKey(const ValueKey('practice-hub-weak')), findsOneWidget);
    expect(find.byKey(const ValueKey('practice-hub-random')), findsOneWidget);
    expect(find.byKey(const ValueKey('practice-hub-custom')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('practice-hub-ultra-hard')),
      findsOneWidget,
    );
    expect(find.byType(BackdropFilter), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Practice hub renders all five modes in dark mode', (
    tester,
  ) async {
    await pumpHub(tester, brightness: Brightness.dark);

    expect(find.byKey(const ValueKey('practice-hub-daily')), findsOneWidget);
    expect(find.byKey(const ValueKey('practice-hub-weak')), findsOneWidget);
    expect(find.byKey(const ValueKey('practice-hub-random')), findsOneWidget);
    expect(find.byKey(const ValueKey('practice-hub-custom')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('practice-hub-ultra-hard')),
      findsOneWidget,
    );
    expect(find.byType(BackdropFilter), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
