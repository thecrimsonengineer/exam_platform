import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('root MaterialApp follows the persisted learner theme mode', () {
    final source = File('lib/main.dart').readAsStringSync();

    expect(source, contains('ThemeModeService.isDarkMode'));
    expect(source, contains('darkTheme: AppTheme.darkTheme'));
    expect(
      source,
      contains('themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light'),
    );
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
        reason: '$path must not force a light-only scaffold/surface.',
      );
    }
  });
}
