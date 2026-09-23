import 'package:flutter/material.dart';

import '../../services/settings/theme_mode_service.dart';
import 'settings_screen.dart';
import 'settings_screen_dark.dart';

/// Keeps the Settings destination synchronized with the learner theme toggle.
class SettingsRoute extends StatelessWidget {
  const SettingsRoute({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ThemeModeService.isDarkMode,
      builder: (context, isDarkMode, _) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: isDarkMode
              ? const DarkSettingsScreen(key: ValueKey('settings-route-dark'))
              : const SettingsScreen(key: ValueKey('settings-route-light')),
        );
      },
    );
  }
}
