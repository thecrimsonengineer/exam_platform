import 'package:flutter/widgets.dart';

import '../../theme/motion/csp11_motion.dart';

class Csp11StaggeredReveal extends StatelessWidget {
  const Csp11StaggeredReveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = Csp11MotionDuration.standard,
    this.offset = const Offset(0, 8),
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    if (Csp11MotionPreferences.reduced(context)) {
      return child;
    }

    final total = delay + duration;
    if (total == Duration.zero) {
      return child;
    }

    final delayFraction = delay.inMicroseconds / total.inMicroseconds;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: total,
      curve: Curves.linear,
      child: child,
      builder: (context, value, child) {
        final rawProgress = delayFraction >= 1
            ? 1.0
            : ((value - delayFraction) / (1 - delayFraction)).clamp(0.0, 1.0);
        final progress = Csp11MotionCurve.enter.transform(rawProgress);

        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(
              offset.dx * (1 - progress),
              offset.dy * (1 - progress),
            ),
            child: child,
          ),
        );
      },
    );
  }
}
