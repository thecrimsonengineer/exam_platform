import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String read(String path) => File(path).readAsStringSync();

  test(
    'HOME-R9 freezes final Home information architecture in both themes',
    () {
      for (final path in <String>[
        'lib/screens/home/home_screen.dart',
        'lib/screens/home/home_screen_dark.dart',
      ]) {
        final source = read(path);

        final hero = source.indexOf('_buildHero(context, snapshot, data)');
        final search = source.indexOf('StudyContentSearchPanel(');
        final resume = source.indexOf('_buildContinueLearning(snapshot, data)');
        final today = source.indexOf('FutureBuilder<TodayPlanSummary?>(');
        final progress = source.indexOf(
          '_buildProgressIntelligence(snapshot, data)',
        );

        expect(hero, greaterThanOrEqualTo(0));
        expect(search, greaterThan(hero));
        expect(resume, greaterThan(search));
        expect(today, greaterThan(resume));
        expect(progress, greaterThan(today));

        for (final forbidden in <String>[
          'YOUR WORKSPACE',
          'QUICK PRACTICE',
          'Train with intent',
          'BookmarkedQuestionsScreen',
          'PracticeQuickLaunchScreen',
          'onOpenStudy',
          'onOpenFlashcards',
          'Icons.bookmark_border_rounded',
        ]) {
          expect(source, isNot(contains(forbidden)));
        }
      }
    },
  );

  test('HOME-R9 preserves one authoritative daily-plan path', () {
    for (final path in <String>[
      'lib/screens/home/home_screen.dart',
      'lib/screens/home/home_screen_dark.dart',
    ]) {
      final source = read(path);

      expect(source, contains('DailyStudyPlanRepository'));
      expect(source, contains('loadLatestForDate(DateTime.now())'));
      expect(source, contains('TodayPlanSummaryService'));
      expect(source, isNot(contains('DailyStudyPlanService(')));
      expect(source, isNot(contains('PhaseAwareDailyPlanService(')));
      expect(source, isNot(contains('refreshRemote: true')));
    }
  });

  test(
    'HOME-R9 category summary filter launch and completion layers remain shared',
    () {
      expect(
        read(
          'lib/features/exam_readiness/models/today_plan_task_category.dart',
        ),
        contains('enum TodayPlanTaskCategory { learn, practice, remember }'),
      );

      expect(
        read(
          'lib/features/exam_readiness/services/today_plan_summary_service.dart',
        ),
        contains('categoryPolicy.categoryFor(block)'),
      );

      final today = read(
        'lib/features/exam_readiness/screens/todays_plan_screen.dart',
      );
      expect(today, contains('TodayPlanPresentationFilter presentationFilter'));
      expect(today, contains('StudyPlanBlockLauncher blockLauncher'));
      expect(
        today,
        contains(
          'StudyPlanCompletionEvidenceService completionEvidenceService',
        ),
      );
      expect(today, isNot(contains('copyWith(blocks: visibleBlocks')));
    },
  );

  test('HOME-R9 completion still requires real evidence', () {
    final completion = read(
      'lib/features/exam_readiness/services/study_plan_completion_evidence_service.dart',
    );
    final quiz = read('lib/screens/courses/csp/quiz/quiz_screen.dart');
    final progress = read('lib/models/student_learning_progress.dart');

    expect(completion, contains('final questionIds = <int>{};'));
    expect(
      completion,
      contains('progress.lastCompletedAt ?? progress.completedAt'),
    );
    expect(quiz, contains('sessionKind: widget.assessmentSessionKind'));
    expect(quiz, contains('await Future.wait('));
    expect(progress, contains('final DateTime? lastCompletedAt;'));
  });

  test(
    'HOME-R9 Home Settings preserves reactive theme and auth-root sign-out',
    () {
      final navigation = read('lib/screens/navigation/bottom_navigation.dart');
      final route = read('lib/screens/settings/settings_route.dart');

      expect(
        navigation,
        contains("import '../settings/settings_route.dart';"),
      );
      expect(navigation, contains('const SettingsRoute()'));
      expect(
        navigation,
        contains('HomeScreen(\n          onOpenSettings: _openSettings,'),
      );
      expect(
        navigation,
        contains('DarkHomeScreen(\n            onOpenSettings: _openSettings,'),
      );

      expect(route, contains('ThemeModeService.isDarkMode'));
      expect(route, contains('ValueListenableBuilder<bool>'));
      expect(route, contains('DarkSettingsScreen'));
      expect(route, contains('SettingsScreen'));

      for (final path in <String>[
        'lib/screens/settings/settings_screen.dart',
        'lib/screens/settings/settings_screen_dark.dart',
      ]) {
        final settings = read(path);

        expect(settings, contains('ThemeModeService.setDarkMode'));
        expect(settings, contains('ThemeModeService.toggle()'));
        expect(settings, contains('AuthStateService().signOut()'));
        expect(settings, contains('rootNavigator: true'));
        expect(settings, contains('popUntil((route) => route.isFirst)'));
      }
    },
  );

  test(
    'HOME-R9 Bookmarks live under Settings and storage keys stay frozen',
    () {
      for (final path in <String>[
        'lib/screens/settings/settings_screen.dart',
        'lib/screens/settings/settings_screen_dark.dart',
      ]) {
        final source = read(path);
        expect(source, contains('settings-full-progress'));
        expect(source, contains('settings-bookmarked-questions'));
        expect(source, contains('BookmarkedQuestionsScreen('));
      }

      final bookmarkService = read('lib/services/bookmark_service.dart');
      expect(bookmarkService, contains("'bookmarked_question_ids'"));
      expect(bookmarkService, contains("'bookmarked_question_snapshots_v2'"));
    },
  );
}
