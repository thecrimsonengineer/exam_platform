import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists and broadcasts the learner-facing dark-mode choice.
///
/// P6.2 covers the five immediate bottom-navigation pages plus Domain, Topic
/// navigation, Quiz and Result. Deeper Subtopic reading pages remain on their
/// existing light presentation until a later phase.
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
