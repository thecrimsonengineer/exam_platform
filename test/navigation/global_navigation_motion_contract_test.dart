import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String read(String path) => File(path).readAsStringSync();

  test('navigation motion is initialized and applied at the app root', () {
    final mainSource = read('lib/main.dart');

    expect(
      mainSource,
      contains('await NavigationMotionService.initialize();'),
    );
    expect(
      mainSource,
      contains('NavigationMotionService.isEnabled'),
    );
    expect(mainSource, contains('AppNavigationMotion.apply('));
    expect(mainSource, contains('AppTheme.studentGlassLightTheme'));
    expect(mainSource, contains('AppTheme.studentGlassDarkTheme'));
  });

  test('root navigation motion covers every supported target platform', () {
    final motion = read('lib/app/navigation_motion.dart');

    for (final platform in <String>[
      'TargetPlatform.android',
      'TargetPlatform.iOS',
      'TargetPlatform.macOS',
      'TargetPlatform.windows',
      'TargetPlatform.linux',
      'TargetPlatform.fuchsia',
    ]) {
      expect(motion, contains(platform));
    }

    expect(motion, contains('FadeTransition'));
    expect(motion, contains('SlideTransition'));
    expect(motion, contains('Curves.easeOutCubic'));
    expect(motion, contains('disableAnimations'));
    expect(motion, contains('_NoPageTransitionsBuilder'));
  });

  test('light and dark settings expose the persisted motion toggle', () {
    final light = read('lib/screens/settings/settings_screen.dart');
    final dark = read('lib/screens/settings/settings_screen_dark.dart');

    for (final settingsSource in <String>[light, dark]) {
      expect(settingsSource, contains('settings-navigation-motion'));
      expect(settingsSource, contains("title: 'Navigation animation'"));
      expect(
        settingsSource,
        contains('NavigationMotionService.isEnabled'),
      );
      expect(
        settingsSource,
        contains('NavigationMotionService.setEnabled'),
      );
      expect(settingsSource, contains('NavigationMotionService.toggle'));
    }
  });
}
