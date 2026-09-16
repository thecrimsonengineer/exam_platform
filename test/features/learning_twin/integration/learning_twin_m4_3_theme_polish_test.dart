import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('M4.3 dark Twin hosts inject the CSP11 dark theme locally', () async {
    final cases = <String, String>{
      'lib/screens/courses/csp/csp_study_hub_screen_dark.dart':
          'LearningTwinStudyHubGuidance',
      'lib/screens/courses/csp/domain_screen_dark.dart':
          'LearningTwinDomainGuidance',
      'lib/widgets/csp/study_content/study_content_renderer_dark.dart':
          'LearningTwinCompetencyGuidance',
    };

    for (final entry in cases.entries) {
      final text = await File(entry.key).readAsString();

      expect(
        text,
        contains("app/theme.dart"),
        reason: '${entry.key} must import the app dark theme.',
      );
      expect(
        text,
        contains('AppTheme.darkTheme'),
        reason: '${entry.key} must supply dark theme context to the Twin.',
      );
      expect(
        RegExp(entry.value).allMatches(text).length,
        1,
        reason: '${entry.key} must still contain exactly one Twin host.',
      );
    }
  });

  test('competency renderers use encoding-safe bullet separators', () async {
    for (final path in <String>[
      'lib/widgets/csp/study_content/study_content_renderer.dart',
      'lib/widgets/csp/study_content/study_content_renderer_dark.dart',
    ]) {
      final text = await File(path).readAsString();

      expect(
        text,
        isNot(contains('â€¢')),
        reason: '$path must not contain the mojibake bullet sequence.',
      );
      expect(
        text,
        contains(r'\u2022'),
        reason: '$path should use an encoding-safe Unicode escape.',
      );
    }
  });

  test(
    'dark competency renderer uses the same progress session cache path',
    () async {
      const path =
          'lib/widgets/csp/study_content/study_content_renderer_dark.dart';
      final text = await File(path).readAsString();

      expect(text, contains('StudentLearningProgressSessionCache.peek()'));
      expect(text, contains('StudentLearningProgressSessionCache.load('));
      expect(text, contains('loader: _progressService.loadAllProgress'));
    },
  );

  test('M4.3 does not add automatic Twin guidance to subtopic pages', () async {
    for (final path in <String>[
      'lib/screens/courses/csp/study_subtopic_screen.dart',
      'lib/screens/courses/csp/study_subtopic_screen_dark.dart',
    ]) {
      final text = await File(path).readAsString();
      expect(text, isNot(contains('features/learning_twin/integration/')));
    }
  });
}
