import 'package:flutter/widgets.dart';

import '../../theme/motion/csp11_motion.dart';

class Csp11StateSwitcher extends StatelessWidget {
  const Csp11StateSwitcher({
    super.key,
    required this.child,
    this.duration = Csp11MotionDuration.standard,
  });

  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final reduced = Csp11MotionPreferences.reduced(context);
    final effectiveDuration = reduced ? Csp11MotionDuration.instant : duration;

    return AnimatedSwitcher(
      duration: effectiveDuration,
      switchInCurve: Csp11MotionCurve.enter,
      switchOutCurve: Csp11MotionCurve.exit,
      transitionBuilder: (child, animation) {
        if (reduced) {
          return FadeTransition(opacity: animation, child: child);
        }

        final slide = Tween<Offset>(
          begin: const Offset(0.015, 0),
          end: Offset.zero,
        ).animate(animation);

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: slide, child: child),
        );
      },
      child: child,
    );
  }
}
