import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'navigation prewarms analytics and does not force full refresh every tap',
    () {
      final source = File(
        'lib/screens/navigation/bottom_navigation.dart',
      ).readAsStringSync();

      expect(source, contains('LearningActivityTracker.instance'));
      expect(source, contains('ProgressOverviewSnapshotService'));
      expect(source, contains('.onVisible()'));
      expect(source, isNot(contains('currentState?.refresh();')));
    },
  );
}
