import 'package:exam_platform/features/exam_readiness/screens/exam_readiness_plan_screen.dart';
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

  testWidgets('Practice hub renders all six modes in light mode', (
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
    expect(
      find.byKey(const ValueKey('practice-hub-exam-readiness')),
      findsOneWidget,
    );
    expect(find.text('Exam Readiness'), findsOneWidget);
    expect(find.byType(BackdropFilter), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Practice hub renders all six modes in dark mode', (
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
    expect(
      find.byKey(const ValueKey('practice-hub-exam-readiness')),
      findsOneWidget,
    );
    expect(find.text('Exam Readiness'), findsOneWidget);
    expect(find.byType(BackdropFilter), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Exam Readiness entry opens the readiness plan route', (
    tester,
  ) async {
    await pumpHub(tester, brightness: Brightness.light);

    final entry = find.byKey(
      const ValueKey('practice-hub-exam-readiness'),
    );
    await tester.scrollUntilVisible(entry, 500);
    await tester.pump();

    final tappable = find.descendant(
      of: entry,
      matching: find.byType(InkWell),
    );
    expect(tappable, findsOneWidget);

    await tester.tap(tappable);
    await tester.pump();

    expect(find.byType(ExamReadinessPlanScreen), findsOneWidget);
  });

  testWidgets('Exam Readiness entry remains available in dark mode', (
    tester,
  ) async {
    await pumpHub(tester, brightness: Brightness.dark);

    final entry = find.byKey(
      const ValueKey('practice-hub-exam-readiness'),
    );
    await tester.scrollUntilVisible(entry, 500);
    await tester.pump();

    expect(entry, findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
