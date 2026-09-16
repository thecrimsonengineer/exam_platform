import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('M5.1 bridge remains deterministic and infrastructure-free', () async {
    const path =
        'lib/features/learning_twin/coaching/learning_twin_progress_message_bridge.dart';
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
      expect(
        text,
        isNot(contains(token)),
        reason: '$token must not enter the M5.1 bridge.',
      );
    }

    expect(text, contains('LearningTwinMessage'));
    expect(text, contains('LearningTwinProgressInsight'));
    expect(text, contains('scopeDomainId'));
    expect(text, contains('allowRepeat: false'));
  });

  test(
    'M5.1 does not integrate adaptive coaching into learner screens',
    () async {
      for (final path in <String>[
        'lib/screens/courses/csp/csp_study_hub_screen.dart',
        'lib/screens/courses/csp/csp_study_hub_screen_dark.dart',
        'lib/screens/courses/csp/domain_screen.dart',
        'lib/screens/courses/csp/domain_screen_dark.dart',
        'lib/screens/progress/progress_analytics_screen.dart',
      ]) {
        final text = await File(path).readAsString();
        expect(
          text,
          isNot(contains('learning_twin_progress_message_bridge')),
          reason: '$path must not become an M5.1 adaptive host yet.',
        );
        expect(
          text,
          isNot(contains('LearningTwinProgressMessageBridge')),
          reason: '$path must not instantiate the M5.1 bridge yet.',
        );
      }
    },
  );

  test('M3 remains the only deterministic decision authority', () async {
    const path =
        'lib/features/learning_twin/domain/learning_twin_decision_service.dart';
    final text = await File(path).readAsString();

    expect(text, contains('if (context.isTimedExamActive)'));
    expect(text, contains('message.matchesContext(context)'));
    expect(text, contains('sessionState.hasDismissed(message.id)'));
    expect(text, contains('sessionState.hasShown(message.id)'));
  });
}
