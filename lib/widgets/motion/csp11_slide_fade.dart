import 'package:flutter/widgets.dart';

import '../../theme/motion/csp11_motion.dart';

class Csp11SlideFade extends StatelessWidget {
  const Csp11SlideFade({
    super.key,
    required this.child,
    this.beginOffset = const Offset(0.025, 0),
    this.duration = Csp11MotionDuration.standard,
    this.curve = Csp11MotionCurve.enter,
  });

  final Widget child;
  final Offset beginOffset;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    final reduced = Csp11MotionPreferences.reduced(context);
    final effectiveDuration = reduced ? Csp11MotionDuration.instant : duration;
    final effectiveOffset = reduced ? Offset.zero : beginOffset;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: effectiveDuration,
      curve: curve,
      child: child,
      builder: (context, value, child) {
        final offset = Offset(
          effectiveOffset.dx * (1 - value),
          effectiveOffset.dy * (1 - value),
        );

        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(offset.dx * 100, offset.dy * 100),
            child: child,
          ),
        );
      },
    );
  }
}
