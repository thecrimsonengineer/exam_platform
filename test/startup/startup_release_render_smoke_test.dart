import 'package:exam_platform/screens/startup/csp11_startup_screen.dart';
import 'package:exam_platform/screens/startup/startup_motion_policy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const destinationKey = ValueKey('sm5-render-destination');

  Widget app(StartupMotionPolicy policy) {
    return MaterialApp(
      home: Csp11StartupScreen(
        motionPolicyOverride: policy,
        child: const SizedBox(key: destinationKey, child: Text('Destination')),
      ),
    );
  }

  testWidgets('full startup renders feature beats and hands off cleanly', (
    tester,
  ) async {
    await tester.pumpWidget(app(StartupMotionPolicy.full));
    await tester.pump();

    expect(find.byKey(const ValueKey('csp11-startup-overlay')), findsOneWidget);
    expect(find.text('CSP11'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.pump(const Duration(milliseconds: 750));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('LEARN'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('PRACTICE'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.pump(const Duration(milliseconds: 650));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('DECISION LAB'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('REMEMBER'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.pump(const Duration(seconds: 2));

    expect(find.byKey(const ValueKey('csp11-startup-overlay')), findsNothing);
    expect(find.byKey(destinationKey), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('balanced startup completes without rendering exceptions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(app(StartupMotionPolicy.balanced));
    await tester.pump();

    expect(find.byKey(const ValueKey('csp11-startup-overlay')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pump(const Duration(milliseconds: 2400));
    expect(find.byKey(const ValueKey('csp11-startup-overlay')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pump(const Duration(milliseconds: 2600));

    expect(find.byKey(const ValueKey('csp11-startup-overlay')), findsNothing);
    expect(find.byKey(destinationKey), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
