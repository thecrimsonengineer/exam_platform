import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Iterable<File> dartFiles(String path) {
  return Directory(path)
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'));
}

void main() {
  test('LTAM-5 remains presentation-only and local-only', () async {
    for (final file in dartFiles('lib/features/learning_twin/ui')) {
      final text = await file.readAsString();

      for (final token in <String>[
        'cloud_firestore',
        'firebase_',
        'supabase',
        'SharedPreferences',
        'RemoteConfig',
        'package:http',
      ]) {
        expect(
          text,
          isNot(contains(token)),
          reason: '$token leaked into ${file.path}',
        );
      }
    }
  });

  test('domain and coaching remain motion-agnostic', () async {
    for (final root in <String>[
      'lib/features/learning_twin/domain',
      'lib/features/learning_twin/coaching',
    ]) {
      for (final file in dartFiles(root)) {
        final text = await file.readAsString();
        expect(text, isNot(contains('LearningTwinMotionState')));
        expect(text, isNot(contains('LearningTwinMotionRollout')));
        expect(text, isNot(contains('package:lottie')));
      }
    }
  });

  test('startup MicroFact remains outside the LTAM-5 Hero pilot', () async {
    final startup = await File(
      'lib/screens/startup/startup_micro_fact_card.dart',
    ).readAsString();
    final bridge = await File(
      'lib/features/learning_twin/integration/'
      'micro_learning_twin_presentation.dart',
    ).readAsString();

    expect(startup, isNot(contains('motionState:')));
    expect(startup, isNot(contains('animationEnabled: true')));
    expect(bridge, isNot(contains('LearningTwinMotionRollout')));
    expect(bridge, isNot(contains('LearningTwinMotionState')));
  });

  test('only LearningTwinHero consumes the LTAM-5 rollout switch', () async {
    for (final file in dartFiles('lib/features/learning_twin')) {
      final text = await file.readAsString();
      if (!text.contains('LearningTwinMotionRollout')) {
        continue;
      }

      expect(
        file.path.endsWith('learning_twin_motion_rollout.dart') ||
            file.path.endsWith('learning_twin_hero.dart') ||
            file.path.endsWith('learning_twin_ui.dart'),
        isTrue,
        reason: 'Rollout switch escaped Hero pilot boundary: ${file.path}',
      );
    }
  });

  test('no LTAM-5 business behavior waits on animation completion', () async {
    for (final file in dartFiles('lib/features/learning_twin')) {
      if (file.path.contains('learning_twin_motion_')) {
        continue;
      }

      final text = await file.readAsString();
      expect(
        text,
        isNot(contains('onMotionCompleted:')),
        reason: 'Business surface depends on animation completion: ${file.path}',
      );
    }
  });
}
