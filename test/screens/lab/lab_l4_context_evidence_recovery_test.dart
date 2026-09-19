import 'dart:io';

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

  test('L4H learner player has no quiz-style wrong/correct verdict', () {
    final source = File(
      'lib/screens/lab/lab_reference_player_screen.dart',
    ).readAsStringSync();

    expect(source, isNot(contains('Wrong answer')));
    expect(source, isNot(contains('Correct answer')));
    expect(source, isNot(contains("Text('CRITICAL')")));
    expect(source, isNot(contains("Text('OPTIMAL')")));
  });
}
