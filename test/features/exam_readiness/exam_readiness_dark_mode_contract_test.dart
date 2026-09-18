import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Home exam readiness entry preserves the learner theme', () {
    final lightHome = File(
      'lib/screens/home/home_screen.dart',
    ).readAsStringSync();
    final darkHome = File(
      'lib/screens/home/home_screen_dark.dart',
    ).readAsStringSync();

    for (final source in [lightHome, darkHome]) {
      expect(source, contains('examReadinessRoute<void>'));
      expect(
        source,
        contains("Theme.of(context).brightness == Brightness.dark"),
      );
      expect(source, contains("ValueKey('home-exam-readiness')"));
    }
  });

  test('nested exam readiness routes preserve the active theme', () {
    final planSource = File(
      'lib/features/exam_readiness/screens/exam_readiness_plan_screen.dart',
    ).readAsStringSync();
    final profileSource = File(
      'lib/features/exam_readiness/screens/readiness_profile_screen.dart',
    ).readAsStringSync();

    expect(planSource, contains('examReadinessRoute<ExamStudyPlan>'));
    expect(planSource, contains('examReadinessRoute<void>'));
    expect(profileSource, contains('examReadinessRoute<void>'));
  });

  test('new exam readiness screens use theme-derived surfaces', () {
    const paths = <String>[
      'lib/features/exam_readiness/screens/exam_plan_setup_screen.dart',
      'lib/features/exam_readiness/screens/exam_readiness_plan_screen.dart',
      'lib/features/exam_readiness/screens/readiness_profile_screen.dart',
      'lib/features/exam_readiness/screens/competency_readiness_screen.dart',
      'lib/features/exam_readiness/screens/todays_plan_screen.dart',
    ];

    for (final path in paths) {
      final source = File(path).readAsStringSync();
      expect(
        source,
        contains('Theme.of(context)'),
        reason: '$path must inherit the active Material theme.',
      );
      expect(
        source,
        isNot(contains('backgroundColor: Colors.white')),
        reason: '$path must not force a light-only scaffold or surface.',
      );
    }
  });
}
