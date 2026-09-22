import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const homeSources = <String>[
    'lib/screens/home/home_screen.dart',
    'lib/screens/home/home_screen_dark.dart',
  ];

  group('HOME-R4 live Home plan contract', () {
    for (final path in homeSources) {
      test('$path uses the read-only authoritative plan projection', () {
        final source = File(path).readAsStringSync();

        for (final required in <String>[
          'DailyStudyPlanRepository',
          'TodayPlanSummaryService',
          'loadLatestForDate(DateTime.now())',
          'FutureBuilder<TodayPlanSummary?>',
          'TodayPlanHomeSection',
          'TodaysPlanScreen(',
          'StudyContentSearchPanel',
          '_buildContinueLearning(snapshot, data)',
          '_buildProgressIntelligence(snapshot, data)',
        ]) {
          expect(
            source,
            contains(required),
            reason: '$path must preserve or add R4 surface: $required',
          );
        }

        for (final forbidden in <String>[
          'DailyStudyPlanService(',
          'PhaseAwareDailyPlanService(',
          'planService.generate(',
          'phaseAwarePlanService.generate(',
          'savePlan(',
          'refreshRemote: true',
        ]) {
          expect(
            source,
            isNot(contains(forbidden)),
            reason: '$path must not generate or persist an independent plan',
          );
        }
      });
    }
  });
}
