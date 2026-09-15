import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('M4 integration bridge stays narrow and deterministic', () async {
    final file = File(
      'lib/features/learning_twin/integration/'
      'learning_twin_study_hub_guidance.dart',
    );
    expect(file.existsSync(), isTrue);

    final text = await file.readAsString();

    for (final token in <String>[
      'avatar_maker',
      'cloud_firestore',
      'firebase_',
      'SharedPreferences',
      'student_learning_progress',
      'student_progress_dashboard',
      'Navigator.',
      'showDialog(',
      'showModalBottomSheet(',
      'DateTime.now',
      'Random(',
      'dart:math',
    ]) {
      expect(
        text,
        isNot(contains(token)),
        reason: '$token must not enter the M4.1 integration bridge',
      );
    }

    expect(text, contains('DeterministicLearningTwinDecisionService'));
    expect(text, contains('LearningTwinSessionState'));
    expect(text, contains('LearningTwinCard'));
  });

  test(
    'only the approved Study Hub light and dark surfaces host M4.1',
    () async {
      const integrationImport =
          'features/learning_twin/integration/'
          'learning_twin_study_hub_guidance.dart';

      for (final path in <String>[
        'lib/screens/courses/csp/csp_study_hub_screen.dart',
        'lib/screens/courses/csp/csp_study_hub_screen_dark.dart',
      ]) {
        final text = await File(path).readAsString();

        expect(text, contains(integrationImport), reason: path);
        expect(
          RegExp('LearningTwinStudyHubGuidance\\(').allMatches(text).length,
          1,
          reason: '$path must contain exactly one M4.1 host',
        );
      }
    },
  );

  test('M4.1 does not wire Learning Twin directly into app shell', () async {
    for (final path in <String>[
      'lib/main.dart',
      'lib/screens/navigation/bottom_navigation.dart',
    ]) {
      final text = await File(path).readAsString();

      expect(
        text,
        isNot(contains('learning_twin_study_hub_guidance.dart')),
        reason: '$path must not directly own M4 guidance',
      );
      expect(
        text,
        isNot(contains('DeterministicLearningTwinDecisionService')),
        reason: '$path must not become a Learning Twin decision owner',
      );
    }
  });
}
