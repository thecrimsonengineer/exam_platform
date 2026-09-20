import 'package:flutter/material.dart';

import '../theme/motion/csp11_motion.dart';

abstract final class Csp11Route {
  static PageRoute<T> forward<T>({
    required Widget child,
    RouteSettings? settings,
  }) {
    return _build<T>(
      child: child,
      settings: settings,
      beginOffset: const Offset(0.035, 0),
      duration: Csp11MotionDuration.standard,
    );
  }

  static PageRoute<T> detail<T>({
    required Widget child,
    RouteSettings? settings,
  }) {
    return _build<T>(
      child: child,
      settings: settings,
      beginOffset: const Offset(0, 0.025),
      duration: Csp11MotionDuration.standard,
    );
  }

  static PageRoute<T> modal<T>({
    required Widget child,
    RouteSettings? settings,
  }) {
    return _build<T>(
      child: child,
      settings: settings,
      beginOffset: const Offset(0, 0.04),
      duration: Csp11MotionDuration.emphasized,
    );
  }

  static PageRoute<T> replacement<T>({
    required Widget child,
    RouteSettings? settings,
  }) {
    return _build<T>(
      child: child,
      settings: settings,
      beginOffset: Offset.zero,
      duration: Csp11MotionDuration.standard,
      beginScale: 0.985,
    );
  }

  static PageRoute<T> _build<T>({
    required Widget child,
    required Offset beginOffset,
    required Duration duration,
    RouteSettings? settings,
    double beginScale = 1,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final reduced = Csp11MotionPreferences.reduced(context);
        final curved = CurvedAnimation(
          parent: animation,
          curve: Csp11MotionCurve.enter,
          reverseCurve: Csp11MotionCurve.exit,
        );

        if (reduced) {
          return FadeTransition(opacity: curved, child: child);
        }

        final offsetAnimation = Tween<Offset>(
          begin: beginOffset,
          end: Offset.zero,
        ).animate(curved);
        final scaleAnimation = Tween<double>(
          begin: beginScale,
          end: 1,
        ).animate(curved);

        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: offsetAnimation,
            child: ScaleTransition(scale: scaleAnimation, child: child),
          ),
        );
      },
    );
  }
}
