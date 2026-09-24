import 'dart:async';

import 'package:exam_platform/screens/startup/csp11_startup_screen.dart';
import 'package:exam_platform/screens/startup/startup_motion_policy.dart';
import 'package:exam_platform/services/micro_learning/local_micro_fact_repository.dart';
import 'package:exam_platform/services/micro_learning/startup_micro_fact_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const destinationKey = ValueKey('ml12-destination');

  Widget app({
    StartupMicroFactService? service,
    int? ordinal = 0,
  }) {
    return MaterialApp(
      home: Csp11StartupScreen(
        microFactService: service,
        microFactRotationOrdinalOverride: ordinal,
        motionPolicyOverride: StartupMotionPolicy.full,
        child: const SizedBox(
          key: destinationKey,
          child: Text('Destination'),
        ),
      ),
    );
  }

  testWidgets('renders one local MicroFact without replacing feature beats', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.byKey(const ValueKey('startup-microfact-card')), findsOneWidget);
    expect(find.text('LEARN'), findsWidgets);
    expect(find.byKey(const ValueKey('csp11-startup-overlay')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pump(const Duration(seconds: 5));

    expect(find.byKey(const ValueKey('csp11-startup-overlay')), findsNothing);
    expect(find.byKey(destinationKey), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('micro-learning load never delays startup handoff', (
    tester,
  ) async {
    final neverCompletes = Completer<String>();
    final service = StartupMicroFactService(
      repository: LocalMicroFactRepository(
        assetLoader: (_) => neverCompletes.future,
      ),
      clock: () => DateTime(2026, 9, 24),
    );

    await tester.pumpWidget(app(service: service));
    await tester.pump();

    expect(find.byKey(const ValueKey('csp11-startup-overlay')), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));

    expect(find.byKey(const ValueKey('csp11-startup-overlay')), findsNothing);
    expect(find.byKey(destinationKey), findsOneWidget);
    expect(find.byKey(const ValueKey('startup-microfact-card')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed local fact load fails soft and preserves navigation', (
    tester,
  ) async {
    final service = StartupMicroFactService(
      repository: LocalMicroFactRepository(
        assetLoader: (_) async => throw StateError('bundle unavailable'),
      ),
      clock: () => DateTime(2026, 9, 24),
    );

    await tester.pumpWidget(app(service: service));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byKey(const ValueKey('startup-microfact-card')), findsNothing);

    await tester.pump(const Duration(seconds: 5));

    expect(find.byKey(const ValueKey('csp11-startup-overlay')), findsNothing);
    expect(find.byKey(destinationKey), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
