import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'M3 domain layer remains deterministic and presentation independent',
    () async {
      final directory = Directory('lib/features/learning_twin/domain');
      expect(directory.existsSync(), isTrue);

      final files = directory
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'));

      const forbidden = <String>[
        'package:flutter/',
        'package:flutter_',
        'avatar_maker',
        'cloud_firestore',
        'firebase_',
        'LearningTwinAvatar',
        'LearningTwinBubble',
        'LearningTwinCard',
        'LearningTwinHero',
        'Navigator.',
        'showDialog(',
        'showModalBottomSheet(',
        'dart:math',
        'Random(',
        'DateTime.now',
      ];

      for (final file in files) {
        final text = await file.readAsString();
        for (final token in forbidden) {
          expect(
            text,
            isNot(contains(token)),
            reason: '$token leaked into ${file.path}',
          );
        }
      }
    },
  );

  test('M3 barrel exports the complete guidance-domain contract', () async {
    final barrel = await File(
      'lib/features/learning_twin/domain/learning_twin_domain.dart',
    ).readAsString();

    for (final exportName in <String>[
      'learning_twin_action.dart',
      'learning_twin_context.dart',
      'learning_twin_decision.dart',
      'learning_twin_decision_service.dart',
      'learning_twin_message.dart',
      'learning_twin_repository.dart',
      'learning_twin_session_state.dart',
      'learning_twin_state.dart',
      'learning_twin_trigger.dart',
    ]) {
      expect(barrel, contains(exportName));
    }
  });

  test('production entry points do not import M3 domain layer yet', () async {
    for (final path in <String>[
      'lib/main.dart',
      'lib/screens/navigation/bottom_navigation.dart',
    ]) {
      final file = File(path);
      expect(file.existsSync(), isTrue, reason: '$path must exist');
      final text = await file.readAsString();
      expect(
        text,
        isNot(contains('features/learning_twin/domain')),
        reason: '$path must remain outside M3 until M4 integration',
      );
    }
  });
}
