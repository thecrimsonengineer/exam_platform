import 'package:exam_platform/features/lab/lab_contracts.dart';
import 'package:exam_platform/screens/lab/lab_reference_player_screen.dart';
import 'package:exam_platform/screens/lab/lab_scenario_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int maxPumps = 80,
}) async {
  for (var i = 0; i < maxPumps; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Expected widget was not found after pumping.');
}

void _useTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 2200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  test('L4F learner status excludes internal route and risk variables', () {
    final status = LabScenarioCatalog.confinedSpaceH2s.learnerStatus(
      <String, Object?>{
        'route': 'critical',
        'risk': 10,
        'permit_verified': true,
        'isolated': true,
        'gas_test_verified': false,
        'rescue_ready': false,
      },
      3,
    );

    final labels = status.map((item) => item.label).toSet();

    expect(labels, contains('Permit'));
    expect(labels, contains('Isolation'));
    expect(labels, contains('Atmospheric test'));
    expect(labels, contains('Rescue readiness'));
    expect(labels, contains('Scenario time'));
    expect(labels, isNot(contains('Risk')));
    expect(labels, isNot(contains('Route')));
  });

  testWidgets('L4F status reflects committed learner-safe state', (tester) async {
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

    await tester.tap(find.byKey(const ValueKey('lab-option-p1')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('lab-confirm-decision')));
    await _pumpUntilFound(
      tester,
      find.byKey(const ValueKey('lab-consequence-screen')),
    );

    final toggle = find.byKey(const ValueKey('lab-situation-status-toggle'));
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('lab-status-permit')), findsOneWidget);
    expect(find.byKey(const ValueKey('lab-status-isolation')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('lab-status-atmospheric-test')),
      findsOneWidget,
    );
    expect(find.text('Verified'), findsNWidgets(2));
    expect(find.textContaining('risk'), findsNothing);
    expect(find.textContaining('route'), findsNothing);
  });

  testWidgets('L4G unlocked evidence can be inspected', (tester) async {
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

    await tester.tap(find.byKey(const ValueKey('lab-option-p1')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('lab-confirm-decision')));
    await _pumpUntilFound(
      tester,
      find.byKey(const ValueKey('lab-consequence-screen')),
    );

    expect(
      find.byKey(const ValueKey('lab-available-evidence-heading')),
      findsOneWidget,
    );
    final permit = find.byKey(const ValueKey('lab-evidence-permit'));
    await tester.ensureVisible(permit);
    await tester.tap(permit);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('lab-evidence-sheet-permit')),
      findsOneWidget,
    );
    expect(find.text('Confined-space permit'), findsWidgets);
    expect(
      find.textContaining('Entry requires verified isolation'),
      findsOneWidget,
    );
  });

  testWidgets('L4H critical decision remains playable through emergency route', (
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

    await tester.tap(find.byKey(const ValueKey('lab-option-p4')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('lab-confirm-decision')));
    await _pumpUntilFound(
      tester,
      find.byKey(const ValueKey('lab-consequence-screen')),
    );

    expect(find.text('What happened next'), findsOneWidget);
    expect(find.text('CRITICAL'), findsNothing);
    expect(find.textContaining('wrong'), findsNothing);
    expect(find.textContaining('correct'), findsNothing);

    final continueButton = find.byKey(
      const ValueKey('lab-consequence-continue'),
    );
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);
    await _pumpUntilFound(
      tester,
      find.textContaining('An H2S alarm occurs'),
    );

    expect(find.byKey(const ValueKey('lab-option-e1')), findsOneWidget);
    expect(find.byKey(const ValueKey('lab-option-e4')), findsOneWidget);
  });
}
