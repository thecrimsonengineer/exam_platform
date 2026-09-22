import 'dart:convert';
import 'dart:io';

import 'package:exam_platform/features/exam_readiness/models/daily_study_plan.dart';
import 'package:exam_platform/features/exam_readiness/models/learning_priority_score.dart';
import 'package:exam_platform/features/exam_readiness/models/study_plan_block.dart';
import 'package:exam_platform/features/exam_readiness/repositories/daily_study_plan_repository.dart';
import 'package:exam_platform/screens/startup/startup_personalization_service.dart';
import 'package:exam_platform/services/student_learning_position_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('INT-R5 behavioral integration contracts', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test(
      'startup personalization reads cached learner state without mutating it',
      () async {
        const userId = 'int-r5-learner';
        final date = DateTime(2026, 9, 22, 18, 0);
        final plan = _plan(
          userId: userId,
          date: date,
          statuses: const <StudyPlanBlockStatus>[
            StudyPlanBlockStatus.planned,
            StudyPlanBlockStatus.completed,
          ],
          minutes: const <int>[20, 15],
        );

        final positionPrefix =
            StudentLearningPositionService.storagePrefixForUser(userId);
        SharedPreferences.setMockInitialValues(<String, Object>{
          '$positionPrefix.domain_id': 'd04',
          '$positionPrefix.domain_number': 4,
          '$positionPrefix.domain_title': 'Advanced Sciences and Math',
          '$positionPrefix.competency_id': 'd04_c01',
          '$positionPrefix.competency_title':
              'Engineering and quantitative foundations',
          '$positionPrefix.subtopic_id': 'd04_c01_s01',
          '$positionPrefix.subtopic_title':
              'Reliability and probability foundations',
          '$positionPrefix.last_opened_at': date
              .subtract(const Duration(minutes: 12))
              .toIso8601String(),
          DailyStudyPlanRepository.storageKeyForUser(userId): jsonEncode(
            <Map<String, dynamic>>[plan.toJson()],
          ),
        });

        final prefs = await SharedPreferences.getInstance();
        final before = _snapshotPreferences(prefs);

        final snapshot = await StartupPersonalizationService().loadForUser(
          userId,
          now: date,
        );

        final after = _snapshotPreferences(prefs);

        expect(after, equals(before));
        expect(snapshot.resumeCode, 'D04 · C01');
        expect(snapshot.resumeTitle, 'Reliability and probability foundations');
        expect(snapshot.todayRemainingActivities, 1);
        expect(snapshot.todayRemainingMinutes, 20);
        expect(snapshot.todayCompletedActivities, 1);
        expect(snapshot.todayTotalActivities, 2);
      },
    );

    test('startup source cannot own planner or completion lifecycle', () {
      final personalization = _read(
        'lib/screens/startup/startup_personalization_service.dart',
      );
      final startup = _read('lib/screens/startup/csp11_startup_screen.dart');

      expect(
        personalization,
        contains('loadLatestForDate(date, refreshRemote: false)'),
      );

      for (final forbidden in <String>[
        'DailyStudyPlanService(',
        'PhaseAwareDailyPlanService(',
        'TodayPlanSummaryService(',
        'TodayPlanTaskCategory',
        'StudyPlanCompletionEvidenceService',
        'savePlan(',
        'savePosition(',
        'clearPosition(',
        'clearLocal(',
        'refreshFromRemote(',
        'refreshRemote: true',
        'markCompleted',
        'completeBlock',
      ]) {
        expect(
          personalization,
          isNot(contains(forbidden)),
          reason: 'Startup personalization must remain read-only: $forbidden',
        );
        expect(
          startup,
          isNot(contains(forbidden)),
          reason:
              'Startup presentation must not own learner lifecycle: $forbidden',
        );
      }
    });

    test('startup hands into one existing learner-shell chain', () {
      final main = _read('lib/main.dart');
      final startup = _read('lib/screens/startup/csp11_startup_screen.dart');
      final auth = _read('lib/screens/auth/auth_gate.dart');
      final learnerShell = _read(
        'lib/screens/auth/learner_authorized_shell.dart',
      );
      final navigation = _read('lib/screens/navigation/bottom_navigation.dart');

      expect(
        main,
        contains('home: const Csp11StartupScreen(child: AuthGate())'),
      );
      expect(_occurrences(main, 'MaterialApp('), 1);

      expect(startup, contains('widget.child,'));
      expect(_occurrences(startup, 'MaterialApp('), 0);
      expect(_occurrences(startup, 'Navigator('), 0);

      expect(auth, contains('return LearnerAuthorizedShell('));
      expect(learnerShell, contains('BottomNavigationScreen('));
      expect(navigation, contains('HomeScreen('));
      expect(navigation, contains('DarkHomeScreen('));
      expect(_occurrences(navigation, 'IndexedStack('), 1);
    });

    test(
      'Home R remains the post-startup learner destination in both themes',
      () {
        for (final path in <String>[
          'lib/screens/home/home_screen.dart',
          'lib/screens/home/home_screen_dark.dart',
        ]) {
          final source = _read(path);

          final hero = source.indexOf('_buildHero(context, snapshot, data)');
          final search = source.indexOf('StudyContentSearchPanel(');
          final resume = source.indexOf(
            '_buildContinueLearning(snapshot, data)',
          );
          final today = source.indexOf('FutureBuilder<TodayPlanSummary?>(');
          final progress = source.indexOf(
            '_buildProgressIntelligence(snapshot, data)',
          );
          final readiness = source.indexOf('EXAM READINESS');

          expect(hero, greaterThanOrEqualTo(0));
          expect(search, greaterThan(hero));
          expect(resume, greaterThan(search));
          expect(today, greaterThan(resume));
          expect(progress, greaterThan(today));
          expect(readiness, greaterThanOrEqualTo(0));

          expect(
            source,
            contains('TodaysPlanScreen(initialCategory: category)'),
          );

          for (final forbidden in <String>[
            'QUICK PRACTICE',
            'Train with intent',
            'PracticeQuickLaunchScreen',
            'BookmarkedQuestionsScreen',
            'settings-bookmarked-questions',
          ]) {
            expect(source, isNot(contains(forbidden)));
          }
        }
      },
    );

    test('Today Plan category launch stays a presentation filter only', () {
      final today = _read(
        'lib/features/exam_readiness/screens/todays_plan_screen.dart',
      );

      expect(today, contains('final TodayPlanTaskCategory? initialCategory;'));
      expect(today, contains('TodayPlanPresentationFilter presentationFilter'));
      expect(
        today,
        contains('visibleBlocks = widget.presentationFilter.apply('),
      );
      expect(today, contains('blocks: plan.blocks,'));
      expect(today, contains('category: _activeCategory,'));
      expect(today, isNot(contains('copyWith(blocks: visibleBlocks')));
    });

    test(
      'Bookmarks remain outside Home under Settings Learning and Progress',
      () {
        for (final path in <String>[
          'lib/screens/settings/settings_screen.dart',
          'lib/screens/settings/settings_screen_dark.dart',
        ]) {
          final source = _read(path);
          final section = source.indexOf("'LEARNING & PROGRESS'");
          final bookmarks = source.indexOf("'settings-bookmarked-questions'");

          expect(section, greaterThanOrEqualTo(0));
          expect(bookmarks, greaterThan(section));
          expect(source, contains('BookmarkedQuestionsScreen('));
        }

        for (final path in <String>[
          'lib/screens/home/home_screen.dart',
          'lib/screens/home/home_screen_dark.dart',
        ]) {
          final source = _read(path);
          expect(source, isNot(contains('BookmarkedQuestionsScreen(')));
          expect(source, isNot(contains('settings-bookmarked-questions')));
        }
      },
    );
  });
}

String _read(String path) => File(path).readAsStringSync();

Map<String, Object?> _snapshotPreferences(SharedPreferences prefs) {
  final keys = prefs.getKeys().toList()..sort();
  return <String, Object?>{for (final key in keys) key: prefs.get(key)};
}

DailyStudyPlan _plan({
  required String userId,
  required DateTime date,
  required List<StudyPlanBlockStatus> statuses,
  required List<int> minutes,
}) {
  final blocks = <StudyPlanBlock>[
    for (var index = 0; index < statuses.length; index++)
      StudyPlanBlock(
        blockId: 'int-r5-block-$index',
        type: index == 0
            ? StudyPlanBlockType.learn
            : StudyPlanBlockType.standardPractice,
        domainId: 'd04',
        competencyId: 'd04_c01',
        subtopicId: 'd04_c01_s01',
        topicId: 'd04_c01_s01_t01',
        plannedMinutes: minutes[index],
        questionCount: index == 0 ? 0 : 5,
        priorityScore: 0.5,
        priorityBreakdown: _priorityScore,
        reasonCodes: const <String>['INT_R5'],
        reasonText: 'INT-R5 integration contract',
        status: statuses[index],
        createdAt: date,
        manualChanges: const <StudyPlanManualChange>[],
      ),
  ];

  return DailyStudyPlan(
    planId: 'int-r5-plan',
    userId: userId,
    date: date,
    generatedAt: date,
    planVersion: 1,
    plannerAlgorithmVersion: DailyStudyPlan.currentAlgorithmVersion,
    availableMinutes: minutes.fold<int>(0, (sum, value) => sum + value),
    allocatedMinutes: minutes.fold<int>(0, (sum, value) => sum + value),
    generationReason: DailyStudyPlanGenerationReason.initial,
    sourceEvidenceVersion: 'int-r5-evidence',
    sourceReadinessVersion: 'int-r5-readiness',
    blocks: blocks,
    status: DailyStudyPlanStatus.active,
    schemaVersion: DailyStudyPlan.currentSchemaVersion,
  );
}

const _priorityScore = LearningPriorityScore(
  competencyId: 'd04_c01',
  blueprintImportance: 0.5,
  masteryGap: 0.5,
  applicationGap: 0.5,
  retentionRisk: 0.5,
  coverageGap: 0.5,
  evidenceDebt: 0.5,
  staleness: 0.5,
  difficultyWeakness: 0.5,
  examProximity: 0.5,
  prerequisiteImportance: 0.5,
  recentStudyPenalty: 0,
  evidenceDebtLevel: EvidenceDebtLevel.none,
  totalScore: 0.5,
  reasonCodes: <String>['INT_R5'],
);

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
