import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String read(String path) => File(path).readAsStringSync();

  test('dark mode defaults ON when no saved preference exists', () {
    final source = read('lib/services/settings/theme_mode_service.dart');

    expect(source, contains('ValueNotifier<bool>(true)'));

    expect(source, contains('preferences.getBool(_preferenceKey) ?? true'));

    expect(
      source,
      isNot(contains('preferences.getBool(_preferenceKey) ?? false')),
    );
  });

  test('saved learner theme choice remains persistent', () {
    final source = read('lib/services/settings/theme_mode_service.dart');

    expect(source, contains("csp11.ui.dark_mode.v1"));

    expect(
      source,
      contains('await preferences.setBool(_preferenceKey, enabled)'),
    );
  });
}
