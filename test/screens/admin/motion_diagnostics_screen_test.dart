import 'dart:io';

import 'package:exam_platform/screens/admin/motion_diagnostics_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Motion Diagnostics exposes local semantic motion samples', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: MotionDiagnosticsScreen()),
    );

    expect(
      find.byKey(const ValueKey('motion-diagnostics-reduced-status')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('motion-diagnostics-replay')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('motion-diagnostics-toggle-state')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('motion-diagnostics-replay-completion')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('motion-diagnostics-flip')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('motion-diagnostics-toggle-state')),
    );
    await tester.pumpAndSettle();
    expect(find.text('State B'), findsOneWidget);
  });

  test('Motion Diagnostics has no backend or direct haptic dependency', () {
    final source = File(
      'lib/screens/admin/motion_diagnostics_screen.dart',
    ).readAsStringSync();

    for (final forbidden in <String>[
      'cloud_firestore',
      'firebase_',
      'supabase',
      'Csp11Haptics',
      'HapticFeedback.',
    ]) {
      expect(source, isNot(contains(forbidden)));
    }
  });
}
