import 'dart:io';

import 'package:exam_platform/screens/startup/csp11_startup_screen.dart';
import 'package:exam_platform/screens/startup/startup_motion_policy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('INT-R3 bootstrap and app-root integration', () {
    test('production source keeps one application root and one learner shell path', () {
      final main = File('lib/main.dart').readAsStringSync();
      final startup = File(
        'lib/screens/startup/csp11_startup_screen.dart',
      ).readAsStringSync();
      final auth = File('lib/screens/auth/auth_gate.dart').readAsStringSync();
      final learnerShell = File(
        'lib/screens/auth/learner_authorized_shell.dart',
      ).readAsStringSync();
      final bottomNavigation = File(
        'lib/screens/navigation/bottom_navigation.dart',
      ).readAsStringSync();

      expect(_occurrences(main, 'MaterialApp('), 1);
      expect(
        main,
        contains('home: const Csp11StartupScreen(child: AuthGate())'),
      );

      expect(_occurrences(startup, 'MaterialApp('), 0);
      expect(_occurrences(startup, 'Navigator('), 0);
      expect(_occurrences(startup, 'widget.child'), 1);

      expect(_occurrences(auth, 'MaterialApp('), 0);
      expect(auth, contains('return LearnerAuthorizedShell('));

      expect(_occurrences(learnerShell, 'MaterialApp('), 0);
      expect(learnerShell, contains('BottomNavigationScreen('));

      expect(bottomNavigation, contains('HomeScreen('));
      expect(bottomNavigation, contains('DarkHomeScreen('));
      expect(_occurrences(bottomNavigation, 'IndexedStack('), 1);
    });

    testWidgets(
      'reduced startup removes only the overlay and does not remount the app child',
      (tester) async {
        var initCalls = 0;
        var disposeCalls = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: Csp11StartupScreen(
              motionPolicyOverride: StartupMotionPolicy.reduced,
              child: _LifecycleProbe(
                key: const ValueKey('int-r3-app-child'),
                onInit: () => initCalls += 1,
                onDispose: () => disposeCalls += 1,
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(MaterialApp), findsOneWidget);
        expect(
          find.byKey(const ValueKey('csp11-startup-overlay')),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('int-r3-app-child')), findsOneWidget);
        expect(initCalls, 1);
        expect(disposeCalls, 0);

        await tester.pump(const Duration(milliseconds: 300));

        expect(
          find.byKey(const ValueKey('csp11-startup-overlay')),
          findsNothing,
        );
        expect(find.byKey(const ValueKey('int-r3-app-child')), findsOneWidget);
        expect(find.byType(MaterialApp), findsOneWidget);
        expect(initCalls, 1);
        expect(disposeCalls, 0);
      },
    );

    testWidgets(
      'startup asset failure fails open without recreating the existing app child',
      (tester) async {
        var initCalls = 0;
        var disposeCalls = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: Csp11StartupScreen(
              motionPolicyOverride: StartupMotionPolicy.full,
              startupAssetPath: 'assets/startup/int_r3_missing_asset.json',
              child: _LifecycleProbe(
                key: const ValueKey('int-r3-fail-open-child'),
                onInit: () => initCalls += 1,
                onDispose: () => disposeCalls += 1,
              ),
            ),
          ),
        );

        expect(
          find.byKey(const ValueKey('csp11-startup-overlay')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('int-r3-fail-open-child')),
          findsOneWidget,
        );
        expect(initCalls, 1);

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 20));

        expect(
          find.byKey(const ValueKey('csp11-startup-overlay')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('int-r3-fail-open-child')),
          findsOneWidget,
        );
        expect(find.byType(MaterialApp), findsOneWidget);
        expect(initCalls, 1);
        expect(disposeCalls, 0);
      },
    );

    test('startup remains a presentation layer over existing application state', () {
      final startup = File(
        'lib/screens/startup/csp11_startup_screen.dart',
      ).readAsStringSync();
      final personalization = File(
        'lib/screens/startup/startup_personalization_service.dart',
      ).readAsStringSync();

      expect(startup, contains('return Stack('));
      expect(startup, contains('widget.child,'));
      expect(startup, contains('if (_showOverlay)'));
      expect(startup, contains('setState(() => _showOverlay = false)'));

      expect(personalization, contains('loadLatestForDate(date, refreshRemote: false)'));
      expect(personalization, isNot(contains('DailyStudyPlanService(')));
      expect(personalization, isNot(contains('PhaseAwareDailyPlanService(')));
      expect(personalization, isNot(contains('savePlan(')));
      expect(personalization, isNot(contains('markCompleted')));
    });
  });
}

int _occurrences(String source, String needle) {
  if (needle.isEmpty) {
    return 0;
  }

  var count = 0;
  var start = 0;

  while (true) {
    final index = source.indexOf(needle, start);
    if (index < 0) {
      return count;
    }
    count += 1;
    start = index + needle.length;
  }
}

class _LifecycleProbe extends StatefulWidget {
  const _LifecycleProbe({
    super.key,
    required this.onInit,
    required this.onDispose,
  });

  final VoidCallback onInit;
  final VoidCallback onDispose;

  @override
  State<_LifecycleProbe> createState() => _LifecycleProbeState();
}

class _LifecycleProbeState extends State<_LifecycleProbe> {
  @override
  void initState() {
    super.initState();
    widget.onInit();
  }

  @override
  void dispose() {
    widget.onDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('INT-R3 application child')),
    );
  }
}
