import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../theme/motion/csp11_motion.dart';

class Csp11FlipCard extends StatelessWidget {
  const Csp11FlipCard({
    super.key,
    required this.front,
    required this.back,
    required this.isFlipped,
    this.duration = Csp11MotionDuration.emphasized,
  });

  final Widget front;
  final Widget back;
  final bool isFlipped;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    if (Csp11MotionPreferences.reduced(context)) {
      return isFlipped ? back : front;
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: isFlipped ? 1 : 0),
      duration: duration,
      curve: Csp11MotionCurve.standard,
      builder: (context, value, _) {
        final angle = value * math.pi;
        final showBack = value >= 0.5;
        final visibleChild = showBack
            ? Transform(
                alignment: Alignment.center,
                transform: Matrix4.rotationY(math.pi),
                child: back,
              )
            : front;

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle),
          child: visibleChild,
        );
      },
    );
  }
}
