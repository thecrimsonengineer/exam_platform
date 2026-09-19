import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HapticPreferenceService {
  HapticPreferenceService._();

  static const String preferenceKey = 'csp11.ui.haptics_enabled.v1';

  static final ValueNotifier<bool> enabled = ValueNotifier<bool>(true);

  static Future<void> initialize() async {
    final preferences = await SharedPreferences.getInstance();
    enabled.value = preferences.getBool(preferenceKey) ?? true;
  }

  static Future<void> setEnabled(bool value) async {
    if (enabled.value != value) {
      enabled.value = value;
    }

    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(preferenceKey, value);
  }

  static Future<void> toggle() => setEnabled(!enabled.value);
}
