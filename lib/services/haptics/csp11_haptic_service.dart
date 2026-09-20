import 'package:flutter/foundation.dart';

import '../settings/haptic_preference_service.dart';
import 'csp11_haptic_driver.dart';
import 'csp11_haptic_event.dart';

class Csp11Haptics {
  Csp11Haptics._();

  static Csp11HapticDriver _driver = const FlutterCsp11HapticDriver();
  static final Map<Csp11HapticEvent, DateTime> _lastEmittedAt =
      <Csp11HapticEvent, DateTime>{};
  static DateTime Function() _now = DateTime.now;

  static Future<void> trigger(Csp11HapticEvent event) async {
    if (!HapticPreferenceService.enabled.value) {
      return;
    }

    final now = _now();
    final previous = _lastEmittedAt[event];
    if (previous != null) {
      final elapsed = now.difference(previous);
      if (!elapsed.isNegative && elapsed < _suppressionWindow(event)) {
        return;
      }
    }

    _lastEmittedAt[event] = now;

    try {
      await _driver.trigger(event);
    } catch (_) {
      // Haptics are an enhancement only. A platform/driver failure must never
      // interrupt the learner action that requested tactile feedback.
    }
  }

  static Duration _suppressionWindow(Csp11HapticEvent event) {
    return switch (event) {
      Csp11HapticEvent.selection ||
      Csp11HapticEvent.navigation => const Duration(milliseconds: 80),
      Csp11HapticEvent.confirm ||
      Csp11HapticEvent.success => const Duration(milliseconds: 160),
      Csp11HapticEvent.warning ||
      Csp11HapticEvent.error ||
      Csp11HapticEvent.criticalDecision ||
      Csp11HapticEvent.completion => const Duration(milliseconds: 260),
    };
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
  static void debugSetNow(DateTime Function() now) {
    _now = now;
    _lastEmittedAt.clear();
  }

  @visibleForTesting
  static void debugResetDriver() {
    _driver = const FlutterCsp11HapticDriver();
    _now = DateTime.now;
    _lastEmittedAt.clear();
  }
}
