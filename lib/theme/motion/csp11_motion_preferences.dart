import 'package:flutter/widgets.dart';

abstract final class Csp11MotionPreferences {
  static bool reduced(BuildContext context) {
    return MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  }

  static Duration duration(
    BuildContext context,
    Duration normal, {
    Duration reduced = Duration.zero,
  }) {
    return Csp11MotionPreferences.reduced(context) ? reduced : normal;
  }
}
