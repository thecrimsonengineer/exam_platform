import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Progress overview contains exactly one adaptive M5.2 host', () async {
    const path = 'lib/screens/progress/progress_analytics_screen.dart';
    final text = await File(path).readAsString();

    expect(
      RegExp(r'LearningTwinProgressGuidance\s*\(').allMatches(text).length,
      1,
    );
    expect(
      text,
      contains(
        "features/learning_twin/integration/learning_twin_progress_guidance.dart",
      ),
    );
  });

  test(
    'M5.2 guidance remains local, deterministic and navigation-free',
    () async {
      const path =
          'lib/features/learning_twin/integration/learning_twin_progress_guidance.dart';
      final text = await File(path).readAsString();

      for (final token in <String>[
        'cloud_firestore',
        'firebase_',
        'SharedPreferences',
        'DateTime.now',
        'Random(',
        'dart:math',
        'Navigator.',
        'showDialog(',
        'showModalBottomSheet(',
      ]) {
        expect(
          text,
          isNot(contains(token)),
          reason: '$token must not enter the M5.2 first adaptive host.',
        );
      }

      expect(text, contains('DeterministicLearningTwinProgressInterpreter'));
      expect(text, contains('LearningTwinProgressMessageBridge'));
      expect(text, contains('DeterministicLearningTwinDecisionService'));
      expect(text, contains('LearningTwinSessionState'));
      expect(text, contains('onDismiss: _dismiss'));
      expect(text, isNot(contains('onAction:')));
    },
  );

  test('M5.2 does not spread adaptive guidance to study subtopics', () async {
    for (final path in <String>[
      'lib/screens/courses/csp/study_subtopic_screen.dart',
      'lib/screens/courses/csp/study_subtopic_screen_dark.dart',
    ]) {
      final text = await File(path).readAsString();
      expect(text, isNot(contains('LearningTwinProgressGuidance')));
    }
  });
}
