import 'package:exam_platform/screens/startup/csp11_startup_screen.dart';
import 'package:exam_platform/screens/startup/startup_motion_policy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const destinationKey = ValueKey('startup-test-destination');

  Widget app({
    StartupMotionPolicy? policy,
    String assetPath = 'assets/startup/csp11_startup_master.json',
  }) {
    return MaterialApp(
      home: Csp11StartupScreen(
        motionPolicyOverride: policy,
        startupAssetPath: assetPath,
        child: const SizedBox(key: destinationKey, child: Text('Destination')),
      ),
    );
  }

  testWidgets('reduced motion uses a short static handoff', (tester) async {
    await tester.pumpWidget(app(policy: StartupMotionPolicy.reduced));
    await tester.pump();

    expect(find.byKey(const ValueKey('csp11-startup-overlay')), findsOneWidget);
    expect(find.text('CSP11'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const ValueKey('csp11-startup-overlay')), findsNothing);
    expect(find.byKey(destinationKey), findsOneWidget);
  });

  testWidgets('missing startup asset fails open to the real app', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        policy: StartupMotionPolicy.full,
        assetPath: 'assets/startup/does_not_exist.json',
      ),
    );

    expect(find.byKey(const ValueKey('csp11-startup-overlay')), findsOneWidget);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    expect(find.byKey(const ValueKey('csp11-startup-overlay')), findsNothing);
    expect(find.byKey(destinationKey), findsOneWidget);
  });

  testWidgets('watchdog removes an overlay that outlives its ceiling', (
    tester,
  ) async {
    const slowPolicy = StartupMotionPolicy(
      mode: StartupMotionMode.full,
      duration: Duration(seconds: 20),
      particleCount: 0,
      blurSigma: 0,
      playLottie: false,
      animateAmbient: false,
    );

    await tester.pumpWidget(app(policy: slowPolicy));
    await tester.pump();

    expect(find.byKey(const ValueKey('csp11-startup-overlay')), findsOneWidget);

    await tester.pump(const Duration(seconds: 7));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byKey(const ValueKey('csp11-startup-overlay')), findsNothing);
    expect(find.byKey(destinationKey), findsOneWidget);
  });

  testWidgets('backgrounding pauses startup motion and resume continues it', (
    tester,
  ) async {
    await tester.pumpWidget(app(policy: StartupMotionPolicy.full));
    await tester.pump();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byKey(const ValueKey('csp11-startup-overlay')), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));

    expect(find.byKey(const ValueKey('csp11-startup-overlay')), findsNothing);
    expect(find.byKey(destinationKey), findsOneWidget);
  });
}
