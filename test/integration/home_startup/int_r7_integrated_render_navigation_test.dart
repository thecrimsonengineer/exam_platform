import 'package:exam_platform/features/exam_readiness/screens/todays_plan_screen.dart';
import 'package:exam_platform/screens/auth/learner_authorized_shell.dart';
import 'package:exam_platform/screens/home/home_screen.dart';
import 'package:exam_platform/screens/home/home_screen_dark.dart';
import 'package:exam_platform/screens/navigation/bottom_navigation.dart';
import 'package:exam_platform/screens/startup/csp11_startup_screen.dart';
import 'package:exam_platform/screens/startup/startup_motion_policy.dart';
import 'package:exam_platform/services/auth/learner_local_identity.dart';
import 'package:exam_platform/services/online_access/learner_connectivity_signal_source.dart';
import 'package:exam_platform/services/online_access/learner_online_access_gate.dart';
import 'package:exam_platform/services/online_access/learner_online_access_session_controller.dart';
import 'package:exam_platform/services/settings/theme_mode_service.dart';
import 'package:exam_platform/services/student_learning_position_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const userId = 'int-r7-learner';

  setUp(() {
    SharedPreferences.setMockInitialValues(_savedLearnerState(userId));
    LearnerLocalIdentity.activate(userId);
    ThemeModeService.isDarkMode.value = false;
  });

  tearDown(() {
    LearnerLocalIdentity.clear();
    ThemeModeService.isDarkMode.value = true;
  });

  testWidgets(
    'reduced Startup hands off once to the authorized learner shell and Home R',
    (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_integratedApp(userId));
      await tester.pump();

      expect(
        find.byKey(const ValueKey('csp11-startup-overlay')),
        findsOneWidget,
      );
      expect(find.byType(MaterialApp), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const ValueKey('csp11-startup-overlay')), findsNothing);
      expect(find.byType(BottomNavigationScreen), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(DarkHomeScreen), findsNothing);

      await tester.pump(const Duration(milliseconds: 200));

      expect(
        find.byKey(const ValueKey('home-study-content-search')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('home-continue-card')), findsOneWidget);
      expect(find.byKey(const ValueKey('home-continue')), findsOneWidget);
      expect(find.byKey(const ValueKey('home-progress-panel')), findsOneWidget);
      expect(find.byKey(const ValueKey('home-exam-readiness')), findsOneWidget);

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Learn'), findsOneWidget);
      expect(find.text('Practice'), findsOneWidget);
      expect(find.text('LAB'), findsOneWidget);
      expect(find.text('Flashcards'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'bottom navigation renders each learner destination exactly once',
    (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_integratedApp(userId));
      await tester.pump(const Duration(milliseconds: 450));

      final destinations = <String>[
        'Learn',
        'Practice',
        'LAB',
        'Flashcards',
        'Home',
      ];

      for (var index = 0; index < destinations.length; index++) {
        final label = destinations[index];
        await tester.tap(find.text(label));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        final navigation = tester.widget<NavigationBar>(
          find.byType(NavigationBar),
        );
        final expectedIndex = label == 'Home' ? 0 : index + 1;
        expect(navigation.selectedIndex, expectedIndex);
        expect(find.byType(NavigationBar), findsOneWidget);

        final exception = tester.takeException();
        expect(
          exception,
          isNull,
          reason: 'Destination $label must render without overflow.',
        );
      }

      expect(find.byType(HomeScreen), findsOneWidget);
    },
  );

  testWidgets(
    'theme switch replaces Home presentation without duplicating shell',
    (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_integratedApp(userId));
      await tester.pump(const Duration(milliseconds: 450));

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(DarkHomeScreen), findsNothing);

      ThemeModeService.isDarkMode.value = true;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.byType(HomeScreen), findsNothing);
      expect(find.byType(DarkHomeScreen), findsOneWidget);
      expect(find.byType(BottomNavigationScreen), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);

      ThemeModeService.isDarkMode.value = false;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(DarkHomeScreen), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Home opens authoritative Today Plan after Startup handoff', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_integratedApp(userId));
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pump(const Duration(milliseconds: 250));

    final openPlan = find.widgetWithText(TextButton, "Open Today's Plan");
    expect(openPlan, findsOneWidget);

    final homeScroll = find.byKey(
      const PageStorageKey<String>('csp11-home-scroll'),
    );
    expect(homeScroll, findsOneWidget);

    await tester.drag(homeScroll, const Offset(0, -700));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(openPlan);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.byType(TodaysPlanScreen), findsOneWidget);
    expect(find.byType(BottomNavigationScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'repeat app launch creates one fresh Startup overlay and one shell',
    (tester) async {
      await tester.pumpWidget(_integratedApp(userId));
      await tester.pump();

      expect(
        find.byKey(const ValueKey('csp11-startup-overlay')),
        findsOneWidget,
      );

      await tester.pump(const Duration(milliseconds: 450));
      expect(find.byKey(const ValueKey('csp11-startup-overlay')), findsNothing);
      expect(find.byType(BottomNavigationScreen), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      await tester.pumpWidget(_integratedApp(userId));
      await tester.pump();

      expect(
        find.byKey(const ValueKey('csp11-startup-overlay')),
        findsOneWidget,
      );

      await tester.pump(const Duration(milliseconds: 450));

      expect(find.byKey(const ValueKey('csp11-startup-overlay')), findsNothing);
      expect(find.byType(BottomNavigationScreen), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

Widget _integratedApp(String userId) {
  final controller = LearnerOnlineAccessSessionController(
    validator: const _AuthorizedValidator(),
    currentUserId: () => userId,
  );

  return MaterialApp(
    home: Csp11StartupScreen(
      motionPolicyOverride: StartupMotionPolicy.reduced,
      child: LearnerAuthorizedShell(
        userId: userId,
        controller: controller,
        connectivitySignalSource: const _AlwaysOnlineConnectivitySource(),
      ),
    ),
  );
}

Map<String, Object> _savedLearnerState(String userId) {
  final prefix = StudentLearningPositionService.storagePrefixForUser(userId);
  final now = DateTime(2026, 9, 22, 20);

  return <String, Object>{
    '$prefix.domain_id': 'd04',
    '$prefix.domain_number': 4,
    '$prefix.domain_title': 'Advanced Sciences and Math',
    '$prefix.competency_id': 'd04_c01',
    '$prefix.competency_title': 'Engineering and quantitative foundations',
    '$prefix.subtopic_id': 'd04_c01_s01',
    '$prefix.subtopic_title': 'Reliability and probability foundations',
    '$prefix.last_opened_at': now.toIso8601String(),
  };
}

class _AuthorizedValidator implements LearnerOnlineAccessValidator {
  const _AuthorizedValidator();

  @override
  Future<LearnerOnlineAccessResult> validate({
    bool forceRefreshToken = false,
  }) async {
    return LearnerOnlineAccessResult(
      status: LearnerOnlineAccessStatus.authorized,
      checkedAt: DateTime.utc(2026, 9, 22),
    );
  }
}

class _AlwaysOnlineConnectivitySource
    implements LearnerConnectivitySignalSource {
  const _AlwaysOnlineConnectivitySource();

  @override
  Future<bool> hasConnectivity() async => true;

  @override
  Stream<bool> get changes => const Stream<bool>.empty();
}
