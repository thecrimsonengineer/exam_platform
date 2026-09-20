import 'package:flutter/widgets.dart';

import '../../theme/motion/csp11_motion.dart';

class Csp11CompletionReveal extends StatelessWidget {
  const Csp11CompletionReveal({
    super.key,
    required this.child,
    this.celebratory = false,
  });

  final Widget child;
  final bool celebratory;

  @override
  Widget build(BuildContext context) {
    if (Csp11MotionPreferences.reduced(context)) {
      return child;
    }

    final duration = celebratory
        ? Csp11MotionDuration.celebration
        : Csp11MotionDuration.emphasized;
    final curve = celebratory
        ? Csp11MotionCurve.emphasized
        : Csp11MotionCurve.enter;
    final beginScale = celebratory ? 0.94 : 0.985;
    final beginOffset = celebratory ? 10.0 : 6.0;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: duration,
      curve: curve,
      child: child,
      builder: (context, value, child) {
        final scale = beginScale + ((1 - beginScale) * value);
        final offset = beginOffset * (1 - value);

        return Opacity(
          opacity: value.clamp(0, 1),
          child: Transform.translate(
            offset: Offset(0, offset),
            child: Transform.scale(scale: scale, child: child),
          ),
        );
      },
    );
  }
}
