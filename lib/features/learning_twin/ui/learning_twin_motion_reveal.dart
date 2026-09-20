import 'package:flutter/widgets.dart';

import 'package:exam_platform/widgets/motion/csp11_completion_reveal.dart';
import 'package:exam_platform/widgets/motion/csp11_slide_fade.dart';

class LearningTwinMotionReveal extends StatelessWidget {
  const LearningTwinMotionReveal({
    super.key,
    required this.motionKey,
    required this.child,
    this.celebratory = false,
  });

  final String motionKey;
  final Widget child;
  final bool celebratory;

  @override
  Widget build(BuildContext context) {
    if (celebratory) {
      return Csp11CompletionReveal(
        key: ValueKey<String>('learning-twin-celebration-$motionKey'),
        celebratory: true,
        child: child,
      );
    }

    return Csp11SlideFade(
      key: ValueKey<String>('learning-twin-reveal-$motionKey'),
      beginOffset: const Offset(0, 0.02),
      child: child,
    );
  }
}
