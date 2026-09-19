import 'package:exam_platform/screens/lab/lab_player_shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int maxPumps = 30,
}) async {
  for (var i = 0; i < maxPumps; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Expected widget was not found after pumping.');
}

void _useTallTestViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets(
    'LAB modes are stacked vertically and Guided advances the story',
    (tester) async {
      _useTallTestViewport(tester);

      await tester.pumpWidget(
        const MaterialApp(home: LabPlayerShellScreen()),
      );

      final guided = find.byKey(const ValueKey('lab-mode-guided'));
      final professional = find.byKey(
        const ValueKey('lab-mode-professional'),
      );
      final assessment = find.byKey(
        const ValueKey('lab-mode-assessment'),
      );

      expect(guided, findsOneWidget);
      expect(professional, findsOneWidget);
      expect(assessment, findsOneWidget);

      final guidedCenter = tester.getCenter(guided);
      final professionalCenter = tester.getCenter(professional);
      final assessmentCenter = tester.getCenter(assessment);

      expect(guidedCenter.dy, lessThan(professionalCenter.dy));
      expect(professionalCenter.dy, lessThan(assessmentCenter.dy));

      await tester.tap(guided);
      await _pumpUntilFound(
        tester,
        find.byKey(const ValueKey('lab-reference-player')),
      );

      expect(find.text('Guided LAB'), findsWidgets);
      expect(find.byKey(const ValueKey('lab-decision-prompt')), findsOneWidget);
      expect(find.byKey(const ValueKey('lab-confirm-decision')), findsOneWidget);
      expect(
        find.textContaining('A contractor crew is ready to enter a vessel'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('lab-option-p1')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('lab-confirm-decision')));
      await _pumpUntilFound(
        tester,
        find.textContaining('H2S may be present'),
      );

      expect(
        find.textContaining('H2S may be present'),
        findsOneWidget,
      );
      expect(find.text('Decision 2'), findsOneWidget);
    },
  );

  testWidgets('Professional mode opens the playable LAB', (tester) async {
    _useTallTestViewport(tester);

    await tester.pumpWidget(
      const MaterialApp(home: LabPlayerShellScreen()),
    );

    await tester.tap(
      find.byKey(const ValueKey('lab-mode-professional')),
    );
    await tester.pump();

    expect(find.text('Professional LAB'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('Assessment mode opens the playable LAB', (tester) async {
    _useTallTestViewport(tester);

    await tester.pumpWidget(
      const MaterialApp(home: LabPlayerShellScreen()),
    );

    await tester.tap(
      find.byKey(const ValueKey('lab-mode-assessment')),
    );
    await tester.pump();

    expect(find.text('Assessment LAB'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
