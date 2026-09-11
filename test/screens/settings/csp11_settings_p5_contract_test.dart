import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String read(String path) => File(path).readAsStringSync();

  test('Settings uses premium Home Domain Quiz visual language', () {
    final source = read('lib/screens/settings/settings_screen.dart');

    expect(source, contains('CustomScrollView'));
    expect(source, contains('SliverAppBar'));
    expect(source, contains('BouncingScrollPhysics'));
    expect(source, contains('Color(0xFFF3F6FC)'));
    expect(source, contains('Color(0xFFF7F9FC)'));
    expect(source, contains('Color(0xFFF8F7FC)'));
    expect(source, contains('Color(0xFF102A56)'));
    expect(source, contains('Color(0xFF1E4C91)'));
    expect(source, contains('Color(0xFF5B36A8)'));
    expect(source, contains('BoxConstraints(maxWidth: 1100)'));
  });

  test('Settings contains requested contact destinations', () {
    final links = read('lib/services/settings/settings_external_links.dart');

    expect(links, contains('918129659572'));
    expect(links, contains('csp11app@gmail.com'));
    expect(links, contains('linkedin.com/in/naveedcsp'));
    expect(links, contains('tuition'));
    expect(links, contains('study session'));
    expect(links, contains('classes'));
  });

  test(
    'Settings contains requested legal center and Play Store placeholder',
    () {
      final source = read('lib/screens/settings/settings_screen.dart');

      expect(source, contains('Privacy Policy'));
      expect(source, contains('Terms of Service'));
      expect(source, contains('Legal Disclaimer'));
      expect(source, contains('Rate CSP11'));
      expect(
        source,
        contains('Play Store rating will be linked after release.'),
      );
    },
  );

  test('Settings reset stays inside current UID-owned learner data', () {
    final source = read('lib/screens/settings/settings_screen.dart');

    expect(source, contains('StudentLearningProgressService'));
    expect(source, contains('StudentLearningPositionService'));
    expect(source, contains('StudentQuestionProgressService'));
    expect(source, contains('clearAllProgress()'));
    expect(source, contains('clearPosition()'));
  });
}
