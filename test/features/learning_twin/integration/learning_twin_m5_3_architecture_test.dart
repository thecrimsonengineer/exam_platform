import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('M5.3 integration widget delegates navigation to its host', () async {
    const path =
        'lib/features/learning_twin/integration/learning_twin_progress_guidance.dart';
    final text = await File(path).readAsString();

    expect(text, contains('ValueChanged<String>? onOpenDomain'));
    expect(text, contains('LearningTwinProgressActionPolicy'));
    expect(text, contains('onAction:'));
    expect(text, isNot(contains('Navigator.')));
    expect(text, isNot(contains('MaterialPageRoute')));
  });

  test('Progress host owns canonical Domain learning navigation', () async {
    const path = 'lib/screens/progress/progress_analytics_screen.dart';
    final text = await File(path).readAsString();

    expect(text, contains('onOpenDomain:'));
    expect(text, contains('DomainScreen('));
    expect(text, contains('DarkDomainScreen('));
    expect(text, contains('Navigator.of(context).push('));
    expect(text, contains('target.domainNumber'));
  });

  test(
    'M5.3 action policy remains fail-closed and infrastructure-free',
    () async {
      const path =
          'lib/features/learning_twin/coaching/learning_twin_progress_action_policy.dart';
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
          reason: '$token must not enter the M5.3 action policy.',
        );
      }

      expect(text, contains('LearningTwinActionType.openContent'));
      expect(text, contains('LearningTwinActionType.continueLearning'));
      expect(text, contains('_ => null'));
    },
  );
}
