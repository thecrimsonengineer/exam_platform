import 'package:flutter/widgets.dart';

import '../../theme/motion/csp11_motion.dart';

class Csp11Pressable extends StatefulWidget {
  const Csp11Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.enabled = true,
    this.pressedScale = 0.985,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool enabled;
  final double pressedScale;

  @override
  State<Csp11Pressable> createState() => _Csp11PressableState();
}

class _Csp11PressableState extends State<Csp11Pressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value || !widget.enabled) {
      return;
    }

    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final reduced = Csp11MotionPreferences.reduced(context);
    final interactive = widget.enabled && widget.onTap != null;
    final scale = reduced || !interactive || !_pressed
        ? 1.0
        : widget.pressedScale;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: interactive ? widget.onTap : null,
      onTapDown: interactive ? (_) => _setPressed(true) : null,
      onTapUp: interactive ? (_) => _setPressed(false) : null,
      onTapCancel: interactive ? () => _setPressed(false) : null,
      child: AnimatedScale(
        scale: scale,
        duration: reduced
            ? Duration.zero
            : Csp11MotionDuration.instant,
        curve: Csp11MotionCurve.standard,
        child: widget.child,
      ),
    );
  }
}
