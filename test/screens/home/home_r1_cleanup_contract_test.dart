import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const homeSources = <String>[
    'lib/screens/home/home_screen.dart',
    'lib/screens/home/home_screen_dark.dart',
  ];

  group('HOME-R1 Home cleanup contract', () {
    for (final path in homeSources) {
      test('$path removes obsolete Home launch surfaces', () {
        final source = File(path).readAsStringSync();

        for (final removed in <String>[
          'YOUR WORKSPACE',
          'QUICK PRACTICE',
          'Train with intent',
          '_buildPrimaryActions',
          '_buildQuickPractice',
          '_openBookmarks',
          '_openPractice',
          '_openQuickPractice',
          'BookmarkedQuestionsScreen',
          'PracticeQuickLaunchScreen',
          'PracticeMode.',
          'class _PrimaryActionData',
          'class _QuickActionData',
        ]) {
          expect(
            source,
            isNot(contains(removed)),
            reason: '$path must not retain obsolete Home surface: $removed',
          );
        }
      });

      test('$path preserves R0-required Home surfaces', () {
        final source = File(path).readAsStringSync();

        for (final preserved in <String>[
          'StudyContentSearchPanel',
          '_buildContinueLearning(snapshot, data)',
          '_buildProgressIntelligence(snapshot, data)',
          'StudentLearningPositionService',
          'home-exam-readiness',
        ]) {
          expect(
            source,
            contains(preserved),
            reason: '$path must preserve required Home surface: $preserved',
          );
        }
      });
    }
  });
}
