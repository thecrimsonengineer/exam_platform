import 'package:exam_platform/features/learning_twin/integration/learning_twin_study_hub_guidance.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget testApp({required Brightness brightness}) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        brightness: brightness,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: brightness,
        ),
      ),
      home: const Scaffold(
        body: SingleChildScrollView(
          padding: EdgeInsets.all(12),
          child: SizedBox(width: 320, child: LearningTwinStudyHubGuidance()),
        ),
      ),
    );
  }

  testWidgets('study hub guidance renders and dismissal is respected', (
    tester,
  ) async {
    await tester.pumpWidget(testApp(brightness: Brightness.light));
    await tester.pumpAndSettle();

    expect(find.text('Start with one domain'), findsOneWidget);
    expect(
      find.textContaining('Choose the domain you want to study now'),
      findsOneWidget,
    );
    expect(find.byTooltip('Dismiss guidance'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Dismiss guidance'));
    await tester.pump();

    expect(find.text('Start with one domain'), findsNothing);
    expect(find.byTooltip('Dismiss guidance'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('study hub guidance renders in dark mode at compact width', (
    tester,
  ) async {
    await tester.pumpWidget(testApp(brightness: Brightness.dark));
    await tester.pumpAndSettle();

    expect(find.text('Start with one domain'), findsOneWidget);
    expect(find.byTooltip('Dismiss guidance'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
