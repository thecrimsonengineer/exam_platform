import 'package:flutter/widgets.dart';

import '../../theme/motion/csp11_motion.dart';

class Csp11FadeIn extends StatelessWidget {
  const Csp11FadeIn({
    super.key,
    required this.child,
    this.duration = Csp11MotionDuration.standard,
    this.curve = Csp11MotionCurve.enter,
  });

  final Widget child;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    final effectiveDuration = Csp11MotionPreferences.duration(
      context,
      duration,
    );

    if (effectiveDuration == Duration.zero) {
      return child;
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: effectiveDuration,
      curve: curve,
      child: child,
      builder: (context, value, child) {
        return Opacity(opacity: value, child: child);
      },
    );
  }
}
