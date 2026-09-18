import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String read(String path) => File(path).readAsStringSync();

  test('P6 persists the learner dark-mode preference', () {
    final mainSource = read('lib/main.dart');
    final service = read('lib/services/settings/theme_mode_service.dart');
    final settings = read('lib/screens/settings/settings_screen.dart');

    expect(mainSource, contains('await ThemeModeService.initialize();'));

    expect(service, contains('csp11.ui.dark_mode.v1'));

    expect(service, contains('ValueNotifier<bool> isDarkMode'));

    expect(service, contains('setDarkMode(bool enabled)'));

    expect(settings, contains('settings-dark-mode'));

    expect(settings, contains('ThemeModeService.setDarkMode'));
  });

  test('P6 wires dark variants for all five immediate navigation pages', () {
    final navigation = read('lib/screens/navigation/bottom_navigation.dart');

    expect(navigation, contains('DarkHomeScreen'));
    expect(navigation, contains('DarkCspStudyHubScreen'));
    expect(navigation, contains('PracticeHubScreen'));
    expect(navigation, contains('LabLibraryScreen'));
    expect(navigation, contains('DarkFlashcardsScreen'));
    expect(navigation, contains('DarkSettingsScreen'));

    expect(navigation, isNot(contains('DarkProgressScreen')));
    expect(navigation, contains('AppTheme.darkTheme'));

    expect(navigation, contains('ThemeModeService.isDarkMode'));
  });

  test('P6 supports dark mode across the Phase L learner destinations', () {
    final home = read('lib/screens/home/home_screen_dark.dart');
    final study = read(
      'lib/screens/courses/csp/csp_study_hub_screen_dark.dart',
    );
    final practice = read('lib/screens/practice/practice_hub_screen.dart');
    final lab = read('lib/screens/lab/lab_library_screen.dart');
    final flashcards = read(
      'lib/screens/flashcards/flashcards_screen_dark.dart',
    );
    final progress = read('lib/screens/progress/progress_screen_dark.dart');
    final settings = read('lib/screens/settings/settings_screen_dark.dart');

    expect(home, contains('class DarkHomeScreen'));
    expect(study, contains('class DarkCspStudyHubScreen'));
    expect(practice, contains('Theme.of(context)'));
    expect(lab, contains('Theme.of(context).brightness'));
    expect(flashcards, contains('class DarkFlashcardsScreen'));
    expect(progress, contains('class DarkProgressScreen'));
    expect(settings, contains('class DarkSettingsScreen'));
  });
}
