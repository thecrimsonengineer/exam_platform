import 'package:flutter/widgets.dart';

import '../../theme/motion/csp11_motion.dart';
import 'csp11_fade_in.dart';

enum Csp11StatusKind { loading, empty, error }

class Csp11StatusReveal extends StatelessWidget {
  const Csp11StatusReveal({super.key, required this.kind, required this.child});

  final Csp11StatusKind kind;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final duration = switch (kind) {
      Csp11StatusKind.loading => Csp11MotionDuration.quick,
      Csp11StatusKind.empty => Csp11MotionDuration.standard,
      Csp11StatusKind.error => Csp11MotionDuration.quick,
    };

    return Csp11FadeIn(duration: duration, child: child);
  }
}
