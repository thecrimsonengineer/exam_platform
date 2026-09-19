import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'csp11_haptic_event.dart';

abstract interface class Csp11HapticDriver {
  Future<void> trigger(Csp11HapticEvent event);
}

class FlutterCsp11HapticDriver implements Csp11HapticDriver {
  const FlutterCsp11HapticDriver();

  @override
  Future<void> trigger(Csp11HapticEvent event) {
    if (kIsWeb) {
      return Future<void>.value();
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return _triggerSupportedPlatform(event);
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return Future<void>.value();
    }
  }

  Future<void> _triggerSupportedPlatform(Csp11HapticEvent event) {
    return switch (event) {
      Csp11HapticEvent.selection => HapticFeedback.selectionClick(),
      Csp11HapticEvent.navigation => HapticFeedback.lightImpact(),
      Csp11HapticEvent.confirm => HapticFeedback.mediumImpact(),
      Csp11HapticEvent.success => HapticFeedback.mediumImpact(),
      Csp11HapticEvent.warning => HapticFeedback.heavyImpact(),
      Csp11HapticEvent.error => HapticFeedback.vibrate(),
      Csp11HapticEvent.criticalDecision => HapticFeedback.heavyImpact(),
      Csp11HapticEvent.completion => HapticFeedback.mediumImpact(),
    };
  }
}
