import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('learner bottom navigation follows the frozen Phase L order', () {
    final source = File(
      'lib/screens/navigation/bottom_navigation.dart',
    ).readAsStringSync();

    final home = source.indexOf("label: 'Home'");
    final learn = source.indexOf("label: 'Learn'");
    final practice = source.indexOf("label: 'Practice'");
    final lab = source.indexOf("label: 'LAB'");
    final flashcards = source.indexOf("label: 'Flashcards'");

    expect(home, greaterThanOrEqualTo(0));
    expect(learn, greaterThan(home));
    expect(practice, greaterThan(learn));
    expect(lab, greaterThan(practice));
    expect(flashcards, greaterThan(lab));
    expect(source, contains("key: ValueKey('bottom-nav-lab')"));
    expect(source, isNot(contains("label: 'Progress'")));
    expect(source, isNot(contains("label: 'Settings'")));
  });
}
