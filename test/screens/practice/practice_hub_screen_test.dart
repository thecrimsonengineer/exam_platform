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

  void expectPracticeModesOnly() {
    expect(find.byKey(const ValueKey('practice-hub-daily')), findsOneWidget);
    expect(find.byKey(const ValueKey('practice-hub-weak')), findsOneWidget);
    expect(find.byKey(const ValueKey('practice-hub-random')), findsOneWidget);
    expect(find.byKey(const ValueKey('practice-hub-custom')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('practice-hub-ultra-hard')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('practice-hub-exam-readiness')),
      findsNothing,
    );
    expect(find.text('Ultra Hard • DQG300'), findsOneWidget);
  }

  testWidgets('Practice hub renders five practice modes in light mode', (
    tester,
  ) async {
    await pumpHub(tester, brightness: Brightness.light);

    expectPracticeModesOnly();
    expect(find.byType(BackdropFilter), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Practice hub renders five practice modes in dark mode', (
    tester,
  ) async {
    await pumpHub(tester, brightness: Brightness.dark);

    expectPracticeModesOnly();
    expect(find.byType(BackdropFilter), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Practice hub contains no standalone Exam Readiness planner', (
    tester,
  ) async {
    await pumpHub(tester, brightness: Brightness.light);

    expect(
      find.byKey(const ValueKey('practice-hub-exam-readiness')),
      findsNothing,
    );
    expect(find.text('Exam Readiness'), findsNothing);
  });
}
