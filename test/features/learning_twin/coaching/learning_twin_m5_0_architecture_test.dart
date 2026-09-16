import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('M5.0 interpreter remains pure and deterministic', () async {
    const path =
        'lib/features/learning_twin/coaching/learning_twin_progress_interpreter.dart';
    final text = await File(path).readAsString();

    for (final token in <String>[
      'cloud_firestore',
      'firebase_',
      'SharedPreferences',
      'DateTime.now',
      'Random(',
      'dart:math',
      'Navigator.',
      'BuildContext',
      'Widget',
      'showDialog(',
      'showModalBottomSheet(',
    ]) {
      expect(text, isNot(contains(token)));
    }

    expect(text, contains('ProgressAnalyticsSnapshot'));
    expect(text, contains('minimumQuestionsForAccuracySignal'));
    expect(text, contains('weakAccuracyThreshold'));
  });

  test('M5.0 is not placed on learner screens yet', () async {
    for (final path in <String>[
      'lib/screens/courses/csp/csp_study_hub_screen.dart',
      'lib/screens/courses/csp/csp_study_hub_screen_dark.dart',
      'lib/screens/courses/csp/domain_screen.dart',
      'lib/screens/courses/csp/domain_screen_dark.dart',
      'lib/screens/progress/progress_analytics_screen.dart',
    ]) {
      final text = await File(path).readAsString();
      expect(text, isNot(contains('learning_twin_progress_interpreter')));
    }
  });
}
