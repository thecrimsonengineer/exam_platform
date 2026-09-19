import 'package:exam_platform/features/lab/lab_contracts.dart';
import 'package:exam_platform/screens/lab/lab_reference_player_screen.dart';
import 'package:exam_platform/screens/lab/lab_scenario_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int maxPumps = 100,
}) async {
  for (var i = 0; i < maxPumps; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Expected widget was not found after pumping.');
}

void _useTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _chooseAndContinue(
  WidgetTester tester,
  String optionId,
) async {
  final option = find.byKey(ValueKey('lab-option-$optionId'));
  await tester.ensureVisible(option);
  await tester.tap(option);
  await tester.pump();

  final confirm = find.byKey(const ValueKey('lab-confirm-decision'));
  await tester.ensureVisible(confirm);
  await tester.tap(confirm);
  await _pumpUntilFound(
    tester,
    find.byKey(const ValueKey('lab-consequence-screen')),
  );

  final continueButton = find.byKey(
    const ValueKey('lab-consequence-continue'),
  );
  await tester.ensureVisible(continueButton);
  await tester.tap(continueButton);
  await tester.pump();
}

void main() {
  test('L4I defines learner narratives for every reference ending', () {
    const scenario = LabScenarioCatalog.confinedSpaceH2s;

    for (final endingId in <String>[
      'safe_completion',
      'controlled_recovery',
      'incident_contained',
      'major_incident',
      'critical_failure',
    ]) {
      final ending = scenario.endingFor(endingId);
      expect(ending.title, isNotEmpty);
      expect(ending.narrative, isNotEmpty);
      expect(ending.keyTurningPoint, isNotEmpty);
    }
  });

  testWidgets('L4I safe route reaches narrative outcome and journey', (
    tester,
  ) async {
    _useTallViewport(tester);

    await tester.pumpWidget(
      const MaterialApp(
        home: LabReferencePlayerScreen(mode: LabMode.professional),
      ),
    );
    await _pumpUntilFound(
      tester,
      find.byKey(const ValueKey('lab-reference-player')),
    );

    await _chooseAndContinue(tester, 'p1');
    await _pumpUntilFound(tester, find.byKey(const ValueKey('lab-option-g1')));

    await _chooseAndContinue(tester, 'g1');
    await _pumpUntilFound(tester, find.byKey(const ValueKey('lab-option-s1')));

    await _chooseAndContinue(tester, 's1');
    await _pumpUntilFound(
      tester,
      find.byKey(const ValueKey('lab-completion-screen')),
    );

    expect(find.text('Safe completion'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('lab-ending-narrative')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('lab-ending-turning-point')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('lab-ending-journey')), findsOneWidget);
    expect(
      find.textContaining('Permit and isolation'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Changing SIMOPS conditions'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('lab-view-debrief')), findsOneWidget);
    expect(find.text('OPTIMAL'), findsNothing);
  });

  testWidgets('L4J debrief is learner-friendly and replayable', (tester) async {
    _useTallViewport(tester);

    await tester.pumpWidget(
      const MaterialApp(
        home: LabReferencePlayerScreen(mode: LabMode.guided),
      ),
    );
    await _pumpUntilFound(
      tester,
      find.byKey(const ValueKey('lab-reference-player')),
    );

    await _chooseAndContinue(tester, 'p1');
    await _pumpUntilFound(tester, find.byKey(const ValueKey('lab-option-g1')));
    await _chooseAndContinue(tester, 'g1');
    await _pumpUntilFound(tester, find.byKey(const ValueKey('lab-option-s1')));
    await _chooseAndContinue(tester, 's1');
    await _pumpUntilFound(
      tester,
      find.byKey(const ValueKey('lab-completion-screen')),
    );

    final debriefButton = find.byKey(const ValueKey('lab-view-debrief'));
    await tester.ensureVisible(debriefButton);
    await tester.tap(debriefButton);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('lab-learner-debrief')),
      findsOneWidget,
    );
    expect(find.text('Your outcome'), findsOneWidget);
    expect(find.text('Your decision journey'), findsOneWidget);
    expect(find.text('Important turning points'), findsOneWidget);
    expect(find.text('What you handled well'), findsOneWidget);
    expect(find.text('Where risk increased'), findsOneWidget);
    expect(find.text('How you recovered'), findsOneWidget);
    expect(find.text('Patterns noticed'), findsOneWidget);
    expect(find.text('Competencies demonstrated'), findsOneWidget);
    expect(find.text('References'), findsOneWidget);
    expect(find.text('Explore another path'), findsOneWidget);

    expect(find.text('OPTIMAL'), findsNothing);
    expect(find.text('WEAK'), findsNothing);
    expect(find.text('CRITICAL'), findsNothing);
    expect(find.textContaining('permit_safe'), findsNothing);
    expect(find.textContaining('gas_work_convergence'), findsNothing);
    expect(find.textContaining('d07_c01'), findsNothing);

    final replay = find.byKey(const ValueKey('lab-debrief-replay'));
    await tester.ensureVisible(replay);
    await tester.tap(replay);
    await _pumpUntilFound(
      tester,
      find.byKey(const ValueKey('lab-reference-player')),
    );

    expect(find.text('Decision 1'), findsOneWidget);
    expect(find.byKey(const ValueKey('lab-option-p1')), findsOneWidget);
  });
}
