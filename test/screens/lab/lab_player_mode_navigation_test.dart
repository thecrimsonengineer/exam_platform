import 'package:exam_platform/screens/lab/lab_player_shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('LAB modes are stacked vertically and Guided opens the player', (
    tester,
  ) async {
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
    await tester.pumpAndSettle();

    expect(find.text('Guided LAB'), findsWidgets);
    expect(find.byKey(const ValueKey('lab-reference-player')), findsOneWidget);
    expect(find.byKey(const ValueKey('lab-decision-prompt')), findsOneWidget);
    expect(find.byKey(const ValueKey('lab-confirm-decision')), findsOneWidget);
  });

  testWidgets('Professional mode opens the player', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: LabPlayerShellScreen()),
    );

    await tester.tap(
      find.byKey(const ValueKey('lab-mode-professional')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Professional LAB'), findsWidgets);
    expect(find.byKey(const ValueKey('lab-reference-player')), findsOneWidget);
  });

  testWidgets('Assessment mode opens the player', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: LabPlayerShellScreen()),
    );

    await tester.tap(
      find.byKey(const ValueKey('lab-mode-assessment')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Assessment LAB'), findsWidgets);
    expect(find.byKey(const ValueKey('lab-reference-player')), findsOneWidget);
  });
}
