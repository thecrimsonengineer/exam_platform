import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists and broadcasts the app-wide page-transition preference.
class NavigationMotionService {
  NavigationMotionService._();

  static const String _preferenceKey = 'csp11.ui.navigation_motion.v1';

  static final ValueNotifier<bool> isEnabled = ValueNotifier<bool>(true);

  static Future<void> initialize() async {
    final preferences = await SharedPreferences.getInstance();
    isEnabled.value = preferences.getBool(_preferenceKey) ?? true;
  }

  static Future<void> setEnabled(bool enabled) async {
    if (isEnabled.value != enabled) {
      isEnabled.value = enabled;
    }

    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_preferenceKey, enabled);
  }

  static Future<void> toggle() => setEnabled(!isEnabled.value);
}
