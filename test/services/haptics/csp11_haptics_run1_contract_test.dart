import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String read(String path) => File(path).readAsStringSync();

  test('Run 1 initializes the local haptic preference at app startup', () {
    final mainSource = read('lib/main.dart');

    expect(mainSource, contains('HapticPreferenceService.initialize()'));
    expect(
      read('lib/services/settings/haptic_preference_service.dart'),
      contains('csp11.ui.haptics_enabled.v1'),
    );
  });

  test('light and dark Settings expose the same haptic preference control', () {
    for (final path in <String>[
      'lib/screens/settings/settings_screen.dart',
      'lib/screens/settings/settings_screen_dark.dart',
    ]) {
      final source = read(path);
      expect(source, contains("ValueKey('settings-haptics')"));
      expect(source, contains('Haptic feedback'));
      expect(source, contains('HapticPreferenceService.enabled'));
      expect(source, contains('HapticPreferenceService.setEnabled'));
      expect(source, contains('HapticPreferenceService.toggle'));
    }
  });

  test('bottom navigation haptics only run through the dedicated tap path', () {
    final navigation = read('lib/screens/navigation/bottom_navigation.dart');

    expect(navigation, contains('_selectBottomNavigationTab'));
    expect(navigation, contains('Csp11Haptics.navigation()'));
    expect(
      navigation,
      contains('onDestinationSelected: _selectBottomNavigationTab'),
    );
    expect(navigation, contains('if (_selectedIndex == index)'));
    expect(navigation, contains('return;'));

    expect(
      navigation,
      contains('onOpenStudy: () => _selectTab(1)'),
    );
    expect(
      navigation,
      contains('onOpenFlashcards: () => _selectTab(4)'),
    );
  });

  test('Flutter HapticFeedback is isolated to the production driver', () {
    final driver = read('lib/services/haptics/csp11_haptic_driver.dart');
    final service = read('lib/services/haptics/csp11_haptic_service.dart');

    expect(driver, contains('HapticFeedback.selectionClick()'));
    expect(driver, contains('HapticFeedback.lightImpact()'));
    expect(driver, contains('HapticFeedback.mediumImpact()'));
    expect(driver, contains('HapticFeedback.heavyImpact()'));
    expect(driver, contains('HapticFeedback.vibrate()'));
    expect(service, isNot(contains('HapticFeedback.')));
  });
}
