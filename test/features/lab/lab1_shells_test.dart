import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final contracts = <({String path, String needle})>[
    (
      path: 'lib/screens/navigation/bottom_navigation.dart',
      needle: "label: 'Home'",
    ),
    (
      path: 'lib/screens/navigation/bottom_navigation.dart',
      needle: "label: 'Learn'",
    ),
    (
      path: 'lib/screens/navigation/bottom_navigation.dart',
      needle: "label: 'Practice'",
    ),
    (
      path: 'lib/screens/navigation/bottom_navigation.dart',
      needle: "label: 'LAB'",
    ),
    (
      path: 'lib/screens/navigation/bottom_navigation.dart',
      needle: "label: 'Flashcards'",
    ),
    (
      path: 'lib/screens/navigation/bottom_navigation.dart',
      needle: "ValueKey('bottom-nav-lab')",
    ),
    (
      path: 'lib/screens/navigation/bottom_navigation.dart',
      needle: "ValueKey('bottom-nav-practice')",
    ),
    (
      path: 'lib/screens/navigation/bottom_navigation.dart',
      needle: 'LabLibraryScreen',
    ),
    (
      path: 'lib/screens/navigation/bottom_navigation.dart',
      needle: 'PracticeHubScreen',
    ),
    (
      path: 'lib/screens/navigation/bottom_navigation.dart',
      needle: 'FlashcardsScreen',
    ),
    (
      path: 'lib/screens/navigation/bottom_navigation.dart',
      needle: 'DarkFlashcardsScreen',
    ),
    (
      path: 'lib/screens/navigation/bottom_navigation.dart',
      needle: 'onOpenFlashcards: () => _selectTab(4)',
    ),
    (path: 'lib/screens/navigation/bottom_navigation.dart', needle: 'case 2:'),
    (path: 'lib/screens/navigation/bottom_navigation.dart', needle: 'case 3:'),
    (path: 'lib/screens/navigation/bottom_navigation.dart', needle: 'case 4:'),
    (
      path: 'lib/screens/navigation/bottom_navigation.dart',
      needle: 'StudentGlassScaffold',
    ),
    (
      path: 'lib/screens/navigation/bottom_navigation.dart',
      needle: 'BackdropFilter',
    ),
    (
      path: 'lib/screens/navigation/bottom_navigation.dart',
      needle: 'ThemeModeService.isDarkMode',
    ),
    (
      path: 'lib/screens/navigation/bottom_navigation.dart',
      needle: 'AppTheme.studentGlassDarkTheme',
    ),
    (
      path: 'lib/screens/navigation/bottom_navigation.dart',
      needle: 'AppTheme.studentGlassLightTheme',
    ),
    (
      path: 'lib/screens/lab/lab_library_screen.dart',
      needle: 'class LabLibraryScreen',
    ),
    (
      path: 'lib/screens/lab/lab_library_screen.dart',
      needle: 'Safety Decision LAB',
    ),
    (path: 'lib/screens/lab/lab_library_screen.dart', needle: 'Decision LABs'),
    (
      path: 'lib/screens/lab/lab_library_screen.dart',
      needle: 'Irreversible after confirm',
    ),
    (
      path: 'lib/screens/lab/lab_library_screen.dart',
      needle: 'No runtime AI branching',
    ),
    (
      path: 'lib/screens/lab/lab_library_screen.dart',
      needle: "ValueKey('lab-open-player-shell')",
    ),
    (
      path: 'lib/screens/lab/lab_library_screen.dart',
      needle: 'LabPlayerShellScreen',
    ),
    (
      path: 'lib/screens/lab/lab_library_screen.dart',
      needle: 'StudentGlassSurface',
    ),
    (path: 'lib/screens/lab/lab_library_screen.dart', needle: 'SafeArea'),
    (
      path: 'lib/screens/lab/lab_library_screen.dart',
      needle: 'Theme.of(context).brightness',
    ),
    (
      path: 'lib/screens/lab/lab_player_shell_screen.dart',
      needle: 'class LabPlayerShellScreen',
    ),
    (
      path: 'lib/screens/lab/lab_player_shell_screen.dart',
      needle: 'Scene → Decision → Consequence → Story Gate',
    ),
    (
      path: 'lib/screens/lab/lab_player_shell_screen.dart',
      needle: 'Guided LAB',
    ),
    (
      path: 'lib/screens/lab/lab_player_shell_screen.dart',
      needle: 'Professional LAB',
    ),
    (
      path: 'lib/screens/lab/lab_player_shell_screen.dart',
      needle: 'Assessment LAB',
    ),
    (
      path: 'lib/screens/settings/settings_screen.dart',
      needle: "ValueKey('settings-full-progress')",
    ),
    (
      path: 'lib/screens/settings/settings_screen.dart',
      needle: "title: 'Full Progress'",
    ),
    (
      path: 'lib/screens/settings/settings_screen.dart',
      needle: 'ProgressScreen',
    ),
    (
      path: 'lib/screens/settings/settings_screen_dark.dart',
      needle: "ValueKey('settings-full-progress')",
    ),
    (
      path: 'lib/screens/settings/settings_screen_dark.dart',
      needle: 'DarkProgressScreen',
    ),
    (
      path: 'lib/screens/admin/admin_home_screen.dart',
      needle: 'LAB1000 Studio',
    ),
    (
      path: 'lib/screens/admin/admin_home_screen.dart',
      needle: 'Lab1000StudioScreen',
    ),
    (
      path: 'lib/screens/admin/admin_home_screen.dart',
      needle: '_openLabStudio',
    ),
    (
      path: 'lib/screens/admin/lab/lab1000_studio_screen.dart',
      needle: 'JSON-first LAB authoring',
    ),
    (
      path: 'lib/screens/admin/lab/lab1000_studio_screen.dart',
      needle: 'Deterministic runtime contract',
    ),
    (
      path: 'lib/screens/admin/lab/lab1000_studio_screen.dart',
      needle: 'L1 boundary',
    ),
    (
      path: 'lib/screens/admin/lab/lab1000_studio_screen.dart',
      needle: 'Runtime LLM branching',
    ),
    (
      path: 'lib/screens/admin/lab/lab1000_studio_screen.dart',
      needle: 'SafeArea',
    ),
    (
      path: 'lib/screens/admin/lab/lab1000_studio_screen.dart',
      needle: 'LAB-0 through LAB-3 only',
    ),
    (path: 'lib/screens/app/app_root_screen.dart', needle: 'AdminGate'),
  ];

  for (var i = 0; i < contracts.length; i++) {
    test('LAB-1 shell contract ' + (i + 1).toString(), () {
      final contract = contracts[i];
      final source = File(contract.path).readAsStringSync();
      expect(source, contains(contract.needle));
    });
  }
}
