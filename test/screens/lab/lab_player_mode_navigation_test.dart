import 'package:exam_platform/features/lab/lab_contracts.dart';
import 'package:exam_platform/screens/lab/lab_player_shell_screen.dart';
import 'package:exam_platform/screens/lab/lab_reference_player_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int maxPumps = 40,
}) async {
  for (var i = 0; i < maxPumps; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Expected widget was not found after pumping.');
}

void _useTallTestViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets(
    'L4C modes stack vertically and L4D/L4E Guided flow stays coherent',
    (tester) async {
      _useTallTestViewport(tester);

      await tester.pumpWidget(const MaterialApp(home: LabPlayerShellScreen()));

      final guided = find.byKey(const ValueKey('lab-mode-guided'));
      final professional = find.byKey(const ValueKey('lab-mode-professional'));
      final assessment = find.byKey(const ValueKey('lab-mode-assessment'));

      expect(guided, findsOneWidget);
      expect(professional, findsOneWidget);
      expect(assessment, findsOneWidget);

      expect(
        tester.getCenter(guided).dy,
        lessThan(tester.getCenter(professional).dy),
      );
      expect(
        tester.getCenter(professional).dy,
        lessThan(tester.getCenter(assessment).dy),
      );

      await tester.tap(guided);
      await _pumpUntilFound(
        tester,
        find.byKey(const ValueKey('lab-reference-player')),
      );

      expect(find.text('Guided LAB'), findsWidgets);
      expect(
        find.byKey(const ValueKey('lab-situation-heading')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('lab-action-heading')),
        findsOneWidget,
      );
      expect(find.text('What is happening now'), findsOneWidget);
      expect(find.text('What would you do?'), findsOneWidget);
      expect(find.byKey(const ValueKey('lab-option-p1')), findsOneWidget);
      expect(find.byKey(const ValueKey('lab-option-p2')), findsOneWidget);
      expect(find.byKey(const ValueKey('lab-option-p3')), findsOneWidget);
      expect(find.byKey(const ValueKey('lab-option-p4')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('lab-option-p1')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('lab-confirm-decision')));
      await _pumpUntilFound(
        tester,
        find.byKey(const ValueKey('lab-consequence-screen')),
      );

      expect(find.text('You decided'), findsOneWidget);
      expect(find.text('What happened next'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('lab-guided-consequence-insight')),
        findsOneWidget,
      );
      expect(find.text('OPTIMAL'), findsNothing);
      expect(find.textContaining('permit_safe'), findsNothing);
      expect(find.textContaining('H2S may be present'), findsNothing);

      await tester.tap(
        find.byKey(const ValueKey('lab-consequence-continue')),
      );
      await _pumpUntilFound(tester, find.textContaining('H2S may be present'));

      expect(find.text('Decision 2'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('lab-option-g1')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('lab-confirm-decision')));
      await _pumpUntilFound(
        tester,
        find.byKey(const ValueKey('lab-consequence-screen')),
      );
      await tester.tap(
        find.byKey(const ValueKey('lab-consequence-continue')),
      );
      await _pumpUntilFound(
        tester,
        find.textContaining('Nearby line-breaking SIMOPS begins'),
      );

      expect(find.text('Decision 3'), findsOneWidget);
      expect(find.byKey(const ValueKey('lab-option-s1')), findsOneWidget);
    },
  );

  testWidgets('L4E Professional consequence avoids coaching', (tester) async {
    _useTallTestViewport(tester);

    await tester.pumpWidget(
      const MaterialApp(
        home: LabReferencePlayerScreen(mode: LabMode.professional),
      ),
    );
    await _pumpUntilFound(
      tester,
      find.byKey(const ValueKey('lab-reference-player')),
      maxPumps: 80,
    );

    await tester.tap(find.byKey(const ValueKey('lab-option-p1')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('lab-confirm-decision')));
    await _pumpUntilFound(
      tester,
      find.byKey(const ValueKey('lab-consequence-screen')),
    );

    expect(find.text('What happened next'), findsOneWidget);
    expect(find.text('Why this mattered'), findsNothing);
    expect(find.text('OPTIMAL'), findsNothing);
  });

  testWidgets('L4E Assessment consequence avoids coaching', (tester) async {
    _useTallTestViewport(tester);

    await tester.pumpWidget(
      const MaterialApp(
        home: LabReferencePlayerScreen(mode: LabMode.assessment),
      ),
    );
    await _pumpUntilFound(
      tester,
      find.byKey(const ValueKey('lab-reference-player')),
      maxPumps: 80,
    );

    await tester.tap(find.byKey(const ValueKey('lab-option-p1')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('lab-confirm-decision')));
    await _pumpUntilFound(
      tester,
      find.byKey(const ValueKey('lab-consequence-screen')),
    );

    expect(find.text('What happened next'), findsOneWidget);
    expect(find.text('Why this mattered'), findsNothing);
    expect(find.text('OPTIMAL'), findsNothing);
  });
}
