import 'package:exam_platform/services/settings/haptic_preference_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('haptic preference defaults ON when no saved value exists', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await HapticPreferenceService.initialize();

    expect(HapticPreferenceService.enabled.value, isTrue);
  });

  test('saved haptic preference is restored locally', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      HapticPreferenceService.preferenceKey: false,
    });

    await HapticPreferenceService.initialize();

    expect(HapticPreferenceService.enabled.value, isFalse);
  });

  test('setEnabled persists the local haptic preference', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await HapticPreferenceService.initialize();

    await HapticPreferenceService.setEnabled(false);

    final preferences = await SharedPreferences.getInstance();
    expect(HapticPreferenceService.enabled.value, isFalse);
    expect(
      preferences.getBool(HapticPreferenceService.preferenceKey),
      isFalse,
    );
  });
}
