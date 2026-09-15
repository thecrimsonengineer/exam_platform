import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String read(String path) => File(path).readAsStringSync();

  test(
    'light and dark Progress wrappers explicitly select their theme mode',
    () {
      final light = read('lib/screens/progress/progress_screen.dart');
      final dark = read('lib/screens/progress/progress_screen_dark.dart');

      expect(light, contains('isDarkMode: false'));
      expect(dark, contains('isDarkMode: true'));
    },
  );

  test('analytics overview owns explicit light and dark themes', () {
    final source = read('lib/screens/progress/progress_analytics_screen.dart');

    expect(source, contains('AppTheme.darkTheme'));
    expect(source, contains('AppTheme.lightTheme'));
    expect(source, contains('required this.isDarkMode'));
    expect(source, contains('Color(0xFF0A111D)'));
    expect(source, contains('Color(0xFFF6F8FC)'));
    expect(source, contains('isDarkMode: widget.isDarkMode'));
  });

  test('Domain analytics receives and applies the selected theme mode', () {
    final source = read(
      'lib/screens/progress/progress_domain_detail_screen.dart',
    );

    expect(source, contains('required this.isDarkMode'));
    expect(source, contains('AppTheme.darkTheme'));
    expect(source, contains('AppTheme.lightTheme'));
    expect(source, contains('Color(0xFF0A111D)'));
    expect(source, contains('Color(0xFFF6F8FC)'));
  });
}
