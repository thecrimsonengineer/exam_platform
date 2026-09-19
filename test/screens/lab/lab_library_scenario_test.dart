import 'package:exam_platform/screens/lab/lab_library_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void _useTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('Safety Decision LAB explains the learner experience', (
    tester,
  ) async {
    _useTallViewport(tester);

    await tester.pumpWidget(
      const MaterialApp(home: LabLibraryScreen()),
    );

    expect(find.text('Safety Decision LAB'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('lab-learner-intro')),
      findsOneWidget,
    );
    expect(find.text('How a LAB works'), findsOneWidget);
    expect(find.text('What you get at the end'), findsOneWidget);
    expect(find.text('Choose how you want to practise'), findsOneWidget);
    expect(find.text('Guided LAB'), findsOneWidget);
    expect(find.text('Professional LAB'), findsOneWidget);
    expect(find.text('Assessment LAB'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('lab-available-scenarios-heading')),
      findsOneWidget,
    );
  });

  testWidgets('scenario card opens mode selection for that scenario', (
    tester,
  ) async {
    _useTallViewport(tester);

    await tester.pumpWidget(
      const MaterialApp(home: LabLibraryScreen()),
    );

    const scenarioId = 'confined_space_h2s_simops';
    final button = find.byKey(
      const ValueKey('lab-scenario-open-$scenarioId'),
    );

    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(find.text('Choose LAB Mode'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('lab-selected-scenario-title')),
      findsOneWidget,
    );
    expect(
      find.text('Confined Space H2S SIMOPS Response'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('lab-mode-guided')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('lab-mode-professional')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('lab-mode-assessment')),
      findsOneWidget,
    );
  });
}
