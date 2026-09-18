import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'navigation prewarms analytics while Full Progress lives under Settings',
    () {
      final navigation = File(
        'lib/screens/navigation/bottom_navigation.dart',
      ).readAsStringSync();
      final settings = File(
        'lib/screens/settings/settings_screen.dart',
      ).readAsStringSync();

      expect(navigation, contains('LearningActivityTracker.instance'));
      expect(navigation, contains('ProgressOverviewSnapshotService'));
      expect(navigation, isNot(contains('ProgressScreen(')));
      expect(settings, contains("title: 'Full Progress'"));
      expect(settings, contains('ProgressScreen'));
    },
  );
}
