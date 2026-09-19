import 'package:flutter/foundation.dart';

import '../settings/haptic_preference_service.dart';
import 'csp11_haptic_driver.dart';
import 'csp11_haptic_event.dart';

class Csp11Haptics {
  Csp11Haptics._();

  static Csp11HapticDriver _driver = const FlutterCsp11HapticDriver();

  static Future<void> trigger(Csp11HapticEvent event) async {
    if (!HapticPreferenceService.enabled.value) {
      return;
    }

    try {
      await _driver.trigger(event);
    } catch (_) {
      // Haptics are an enhancement only. A platform/driver failure must never
      // interrupt the learner action that requested tactile feedback.
    }
  }

  static Future<void> selection() => trigger(Csp11HapticEvent.selection);

  static Future<void> navigation() => trigger(Csp11HapticEvent.navigation);

  static Future<void> confirm() => trigger(Csp11HapticEvent.confirm);

  static Future<void> success() => trigger(Csp11HapticEvent.success);

  static Future<void> warning() => trigger(Csp11HapticEvent.warning);

  static Future<void> error() => trigger(Csp11HapticEvent.error);

  static Future<void> criticalDecision() =>
      trigger(Csp11HapticEvent.criticalDecision);

  static Future<void> completion() => trigger(Csp11HapticEvent.completion);

  @visibleForTesting
  static void debugSetDriver(Csp11HapticDriver driver) {
    _driver = driver;
  }

  @visibleForTesting
  static void debugResetDriver() {
    _driver = const FlutterCsp11HapticDriver();
  }
}
