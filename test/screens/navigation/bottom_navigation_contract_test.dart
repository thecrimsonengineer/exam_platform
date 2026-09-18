import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('learner bottom navigation keeps Practice as the fifth tab', () {
    final source = File(
      'lib/screens/navigation/bottom_navigation.dart',
    ).readAsStringSync();

    expect(
      source,
      contains("key: ValueKey('bottom-nav-practice')"),
    );
    expect(source, contains("label: 'Practice'"));
    expect(source, isNot(contains("label: 'Settings'")));
    expect(
      RegExp(
        r"case 4:\s*return const PracticeHubScreen\(\);",
        multiLine: true,
      ).allMatches(source),
      hasLength(2),
    );
  });
}
