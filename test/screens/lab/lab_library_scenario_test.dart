import 'package:exam_platform/screens/lab/lab_library_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void _useTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('L4A scenario library is simple and hides difficulty', (
    tester,
  ) async {
    _useTallViewport(tester);

    await tester.pumpWidget(const MaterialApp(home: LabLibraryScreen()));

    expect(find.text('Safety Decision LAB'), findsOneWidget);
    expect(find.byKey(const ValueKey('lab-learner-intro')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('lab-available-scenarios-heading')),
      findsOneWidget,
    );
    expect(find.text('Confined Space H2S SIMOPS Response'), findsOneWidget);
    expect(find.text('8–12 min'), findsOneWidget);
    expect(find.text('3–5 decisions'), findsOneWidget);
    expect(find.text('Confined Space'), findsOneWidget);
    expect(find.text('H2S'), findsOneWidget);
    expect(find.textContaining('difficulty'), findsNothing);
    expect(find.text('Professional safety judgement'), findsNothing);
  });

  testWidgets('L4A How LAB works guidance expands on demand', (tester) async {
    _useTallViewport(tester);

    await tester.pumpWidget(const MaterialApp(home: LabLibraryScreen()));

    expect(
      find.text('Once confirmed, that decision is locked for the current attempt.'),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('lab-how-it-works-toggle')));
    await tester.pumpAndSettle();

    expect(find.text('Read the situation'), findsOneWidget);
    expect(find.text('Choose one action'), findsOneWidget);
    expect(find.text('Confirm your decision'), findsOneWidget);
    expect(find.text('See what happens next'), findsOneWidget);
    expect(
      find.text('Once confirmed, that decision is locked for the current attempt.'),
      findsOneWidget,
    );
  });

  testWidgets('L4B briefing comes before L4C mode selection', (tester) async {
    _useTallViewport(tester);

    await tester.pumpWidget(const MaterialApp(home: LabLibraryScreen()));

    const scenarioId = 'confined_space_h2s_simops';
    final start = find.byKey(
      const ValueKey('lab-scenario-open-$scenarioId'),
    );

    await tester.ensureVisible(start);
    await tester.tap(start);
    await tester.pumpAndSettle();

    expect(find.text('Scenario Briefing'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('lab-scenario-briefing')),
      findsOneWidget,
    );
    expect(find.text('Your role'), findsOneWidget);
    expect(find.text('Situation'), findsOneWidget);
    expect(find.text('Your objective'), findsOneWidget);
    expect(find.text('People involved'), findsOneWidget);
    expect(find.text('What you know so far'), findsOneWidget);
    expect(find.byKey(const ValueKey('lab-mode-guided')), findsNothing);

    final continueButton = find.byKey(
      const ValueKey('lab-briefing-continue'),
    );
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);
    await tester.pumpAndSettle();

    expect(find.text('Choose LAB Mode'), findsOneWidget);
    expect(find.byKey(const ValueKey('lab-mode-guided')), findsOneWidget);
    expect(find.byKey(const ValueKey('lab-mode-professional')), findsOneWidget);
    expect(find.byKey(const ValueKey('lab-mode-assessment')), findsOneWidget);
  });
}
