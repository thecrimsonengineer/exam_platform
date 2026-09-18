import 'package:exam_platform/features/exam_readiness/models/exam_study_plan.dart';
import 'package:exam_platform/features/exam_readiness/repositories/exam_study_plan_repository.dart';
import 'package:exam_platform/features/exam_readiness/screens/exam_plan_setup_screen.dart';
import 'package:exam_platform/features/exam_readiness/screens/exam_readiness_plan_screen.dart';
import 'package:exam_platform/services/auth/learner_local_identity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

ExamStudyPlan _plan() {
  return ExamStudyPlan.create(
    id: 'plan-1',
    userId: 'u1',
    examDate: DateTime(2026, 12, 15),
    studyDaysOfWeek: const {1, 2, 3, 5, 6},
    defaultMinutesPerStudyDay: 60,
    now: DateTime(2026, 9, 18, 10),
  );
}

Future<ExamStudyPlanRepository> _repositoryWithPlan() async {
  final repository = ExamStudyPlanRepository(userIdOverride: 'u1');
  await repository.savePlan(_plan(), syncRemote: false);
  return repository;
}

class _PermissionDeniedRemote implements ExamStudyPlanRemoteStore {
  int saveCalls = 0;
  int deactivateCalls = 0;

  @override
  Future<List<ExamStudyPlan>> loadPlans(String userId) async {
    throw StateError('cloud_firestore/permission-denied');
  }

  @override
  Future<void> savePlan(ExamStudyPlan plan) async {
    saveCalls++;
    throw StateError('cloud_firestore/permission-denied');
  }

  @override
  Future<void> deactivateOtherPlans({
    required String userId,
    required String activePlanId,
  }) async {
    deactivateCalls++;
    throw StateError('cloud_firestore/permission-denied');
  }
}

Widget _app(Widget home, {bool dark = false}) {
  return MaterialApp(
    theme: dark ? ThemeData.dark() : ThemeData.light(),
    home: home,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LearnerLocalIdentity.activate('u1');
  });

  tearDown(LearnerLocalIdentity.clear);

  group('M7A learner UI', () {
    testWidgets('setup screen renders all seven weekday controls', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          ExamPlanSetupScreen(
            repository: ExamStudyPlanRepository(userIdOverride: 'u1'),
            now: () => DateTime(2026, 9, 18, 10),
          ),
        ),
      );

      for (var weekday = 1; weekday <= 7; weekday++) {
        expect(find.byKey(ValueKey('m7a-weekday-$weekday')), findsOneWidget);
      }
    });

    testWidgets('setup screen renders capacity preview', (tester) async {
      await tester.pumpWidget(
        _app(
          ExamPlanSetupScreen(
            repository: ExamStudyPlanRepository(userIdOverride: 'u1'),
            now: () => DateTime(2026, 9, 18, 10),
          ),
        ),
      );

      final preview = find.byKey(const ValueKey('m7a-capacity-preview'));
      await tester.scrollUntilVisible(preview, 260);
      await tester.pump();

      expect(preview, findsOneWidget);
      expect(find.text('YOUR STUDY CAPACITY'), findsOneWidget);
    });

    testWidgets('setup screen supports dark theme', (tester) async {
      await tester.pumpWidget(
        _app(
          ExamPlanSetupScreen(
            repository: ExamStudyPlanRepository(userIdOverride: 'u1'),
            now: () => DateTime(2026, 9, 18, 10),
          ),
          dark: true,
        ),
      );

      expect(
        Theme.of(tester.element(find.byType(Scaffold))).brightness,
        Brightness.dark,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('setup minute choice updates selected chip', (tester) async {
      await tester.pumpWidget(
        _app(
          ExamPlanSetupScreen(
            repository: ExamStudyPlanRepository(userIdOverride: 'u1'),
            now: () => DateTime(2026, 9, 18, 10),
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('m7a-minutes-90')));
      await tester.pump();

      final chip = tester.widget<ChoiceChip>(
        find.byKey(const ValueKey('m7a-minutes-90')),
      );
      expect(chip.selected, isTrue);
    });

    testWidgets('setup allows deselecting a study day', (tester) async {
      await tester.pumpWidget(
        _app(
          ExamPlanSetupScreen(
            repository: ExamStudyPlanRepository(userIdOverride: 'u1'),
            now: () => DateTime(2026, 9, 18, 10),
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('m7a-weekday-1')));
      await tester.pump();

      final chip = tester.widget<FilterChip>(
        find.byKey(const ValueKey('m7a-weekday-1')),
      );
      expect(chip.selected, isFalse);
    });

    testWidgets('empty plan screen shows create action', (tester) async {
      await tester.pumpWidget(
        _app(
          ExamReadinessPlanScreen(
            repository: ExamStudyPlanRepository(userIdOverride: 'u1'),
            now: () => DateTime(2026, 9, 18, 10),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('m7a-create-plan')), findsOneWidget);
      expect(find.text('Create your exam readiness plan'), findsOneWidget);
    });

    testWidgets('saved plan screen renders exam hero', (tester) async {
      final repository = await _repositoryWithPlan();

      await tester.pumpWidget(
        _app(
          ExamReadinessPlanScreen(
            repository: repository,
            now: () => DateTime(2026, 9, 18, 10),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('m7a-exam-hero')), findsOneWidget);
      expect(find.text('15 December 2026'), findsOneWidget);
    });

    testWidgets('saved plan screen renders capacity cards', (tester) async {
      final repository = await _repositoryWithPlan();

      await tester.pumpWidget(
        _app(
          ExamReadinessPlanScreen(
            repository: repository,
            now: () => DateTime(2026, 9, 18, 10),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('m7a-study-days-remaining')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('m7a-study-hours-remaining')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('m7a-current-week-capacity')),
        findsOneWidget,
      );
    });

    testWidgets('M7A screen explicitly avoids readiness claims', (
      tester,
    ) async {
      final repository = await _repositoryWithPlan();

      await tester.pumpWidget(
        _app(
          ExamReadinessPlanScreen(
            repository: repository,
            now: () => DateTime(2026, 9, 18, 10),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final disclaimer = find.byKey(const ValueKey('m7a-no-readiness-claim'));
      await tester.scrollUntilVisible(disclaimer, 400);
      await tester.pump();

      expect(disclaimer, findsOneWidget);
      expect(
        find.textContaining('calculates time and capacity only'),
        findsOneWidget,
      );
    });

    testWidgets('saved plan screen supports dark theme', (tester) async {
      final repository = await _repositoryWithPlan();

      await tester.pumpWidget(
        _app(
          ExamReadinessPlanScreen(
            repository: repository,
            now: () => DateTime(2026, 9, 18, 10),
          ),
          dark: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        Theme.of(tester.element(find.byType(Scaffold))).brightness,
        Brightness.dark,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('readiness plan fits narrow Android width', (tester) async {
      final repository = await _repositoryWithPlan();
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 800);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _app(
          ExamReadinessPlanScreen(
            repository: repository,
            now: () => DateTime(2026, 9, 18, 10),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('setup screen fits narrow Android width', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 800);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _app(
          ExamPlanSetupScreen(
            repository: ExamStudyPlanRepository(userIdOverride: 'u1'),
            now: () => DateTime(2026, 9, 18, 10),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('edit action is present for saved plan', (tester) async {
      final repository = await _repositoryWithPlan();

      await tester.pumpWidget(
        _app(
          ExamReadinessPlanScreen(
            repository: repository,
            now: () => DateTime(2026, 9, 18, 10),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final edit = find.byKey(const ValueKey('m7a-edit-plan'));
      await tester.scrollUntilVisible(edit, 300);

      expect(edit, findsOneWidget);
    });

    testWidgets(
      'create study plan is local-only even when remote store would deny',
      (tester) async {
        final remote = _PermissionDeniedRemote();
        final repository = ExamStudyPlanRepository(
          userIdOverride: 'u1',
          remoteStore: remote,
        );

        await tester.pumpWidget(
          _app(
            ExamPlanSetupScreen(
              repository: repository,
              now: () => DateTime(2026, 9, 18, 10),
            ),
          ),
        );

        final save = find.byKey(const ValueKey('m7a-save-plan'));
        await tester.scrollUntilVisible(save, 300);
        await tester.tap(save);
        await tester.pumpAndSettle();

        expect(remote.saveCalls, 0);
        expect(remote.deactivateCalls, 0);
        expect(await repository.loadActivePlan(), isNotNull);
        expect(find.byKey(const ValueKey('m7a-plan-error')), findsNothing);
      },
    );
  });
}
