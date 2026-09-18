import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists and broadcasts the learner-facing dark-mode choice.
///
/// The root MaterialApp follows this notifier, so learner pages and pushed
/// routes inherit the same persisted light/dark preference. Individual screens
/// should use Theme.of(context) and the active ColorScheme rather than forcing
/// light-only surface colors.
class ThemeModeService {
  ThemeModeService._();

  static const String _preferenceKey = 'csp11.ui.dark_mode.v1';

  static final ValueNotifier<bool> isDarkMode = ValueNotifier<bool>(true);

  static Future<void> initialize() async {
    final preferences = await SharedPreferences.getInstance();
    isDarkMode.value = preferences.getBool(_preferenceKey) ?? true;
  }

  static Future<void> setDarkMode(bool enabled) async {
    if (isDarkMode.value != enabled) {
      isDarkMode.value = enabled;
    }

    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_preferenceKey, enabled);
  }

  static Future<void> toggle() => setDarkMode(!isDarkMode.value);
}
