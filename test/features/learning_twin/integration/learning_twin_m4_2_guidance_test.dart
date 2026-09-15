import 'package:exam_platform/features/learning_twin/integration/learning_twin_competency_guidance.dart';
import 'package:exam_platform/features/learning_twin/integration/learning_twin_domain_guidance.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget testApp({
    required Widget child,
    required Brightness brightness,
    double width = 320,
  }) {
    return MaterialApp(
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
          child: SizedBox(width: width, child: child),
        ),
      ),
    );
  }

  testWidgets('domain guidance renders at phone width and respects dismissal', (
    tester,
  ) async {
    await tester.pumpWidget(
      testApp(
        brightness: Brightness.light,
        child: const LearningTwinDomainGuidance(domainId: 'd01'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Work one learning area at a time'), findsOneWidget);
    expect(find.byTooltip('Dismiss guidance'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Dismiss guidance'));
    await tester.pump();

    expect(find.text('Work one learning area at a time'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('domain guidance starts a new visit when domain changes', (
    tester,
  ) async {
    await tester.pumpWidget(
      testApp(
        brightness: Brightness.light,
        child: const LearningTwinDomainGuidance(domainId: 'd01'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Dismiss guidance'));
    await tester.pump();
    expect(find.text('Work one learning area at a time'), findsNothing);

    await tester.pumpWidget(
      testApp(
        brightness: Brightness.light,
        child: const LearningTwinDomainGuidance(domainId: 'd02'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Work one learning area at a time'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'competency guidance renders in dark mode and respects dismissal',
    (tester) async {
      await tester.pumpWidget(
        testApp(
          brightness: Brightness.dark,
          child: const LearningTwinCompetencyGuidance(
            domainId: 'd01',
            competencyId: 'd01_c01',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Study first, then test recall'), findsOneWidget);
      expect(find.byTooltip('Dismiss guidance'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byTooltip('Dismiss guidance'));
      await tester.pump();

      expect(find.text('Study first, then test recall'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('competency guidance handles a narrow phone surface', (
    tester,
  ) async {
    await tester.pumpWidget(
      testApp(
        brightness: Brightness.light,
        width: 280,
        child: const LearningTwinCompetencyGuidance(
          domainId: 'd07',
          competencyId: 'd07_c06',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Study first, then test recall'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
