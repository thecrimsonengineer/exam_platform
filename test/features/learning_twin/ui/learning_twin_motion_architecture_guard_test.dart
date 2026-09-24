import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Iterable<File> dartFiles(String path) {
  return Directory(path)
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'));
}

void main() {
  test(
    'domain and coaching never depend on LTAM motion implementation',
    () async {
      for (final root in <String>[
        'lib/features/learning_twin/domain',
        'lib/features/learning_twin/coaching',
      ]) {
        for (final file in dartFiles(root)) {
          final text = await file.readAsString();
          expect(
            text,
            isNot(contains('package:lottie')),
            reason: 'Lottie leaked into ${file.path}',
          );
          expect(
            text,
            isNot(contains('assets/learning_twin/motion/')),
            reason: 'Motion path leaked into ${file.path}',
          );
          expect(
            text,
            isNot(contains('twin_motion_manifest')),
            reason: 'Manifest leaked into ${file.path}',
          );
        }
      }
    },
  );

  test(
    'LTAM-4 motion infrastructure has no backend or network coupling',
    () async {
      for (final file in dartFiles('lib/features/learning_twin/ui')) {
        if (!file.path.contains('learning_twin_motion_')) {
          continue;
        }

        final text = await file.readAsString();
        for (final token in <String>[
          'cloud_firestore',
          'firebase_',
          'supabase',
          'package:http',
          'http://',
          'https://',
        ]) {
          expect(
            text,
            isNot(contains(token)),
            reason: '$token leaked into ${file.path}',
          );
        }
      }
    },
  );

  test('production MicroFact surface remains static during LTAM-4', () async {
    final startupCard = await File(
      'lib/screens/startup/startup_micro_fact_card.dart',
    ).readAsString();
    final bridge = await File(
      'lib/features/learning_twin/integration/'
      'micro_learning_twin_presentation.dart',
    ).readAsString();

    expect(startupCard, isNot(contains('motionState:')));
    expect(startupCard, isNot(contains('animationEnabled: true')));
    expect(bridge, isNot(contains('LearningTwinMotionState')));
  });
}
