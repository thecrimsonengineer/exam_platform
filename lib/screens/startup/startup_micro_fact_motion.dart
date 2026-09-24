import 'startup_motion_policy.dart';

class StartupMicroFactMotionFrame {
  const StartupMicroFactMotionFrame({
    required this.opacity,
    required this.translateY,
    required this.scale,
    required this.visible,
  });

  final double opacity;
  final double translateY;
  final double scale;
  final bool visible;
}

class StartupMicroFactMotion {
  const StartupMicroFactMotion._();

  static const int _totalFrames = 144;
  static const int _enterStartFrame = 12;
  static const int _enterEndFrame = 28;
  static const int _exitStartFrame = 110;
  static const int _exitEndFrame = 130;

  static StartupMicroFactMotionFrame sample({
    required double progress,
    required StartupMotionMode mode,
  }) {
    if (mode == StartupMotionMode.reduced) {
      return const StartupMicroFactMotionFrame(
        opacity: 1,
        translateY: 0,
        scale: 1,
        visible: true,
      );
    }

    final normalized = progress.clamp(0.0, 1.0).toDouble();
    final frame = normalized * _totalFrames;

    if (frame < _enterStartFrame || frame >= _exitEndFrame) {
      return const StartupMicroFactMotionFrame(
        opacity: 0,
        translateY: 10,
        scale: 0.985,
        visible: false,
      );
    }

    if (frame < _enterEndFrame) {
      final t = _easeOutCubic(
        (frame - _enterStartFrame) / (_enterEndFrame - _enterStartFrame),
      );
      final distance = mode == StartupMotionMode.balanced ? 7.0 : 10.0;
      final scaleDepth = mode == StartupMotionMode.balanced ? 0.008 : 0.015;
      return StartupMicroFactMotionFrame(
        opacity: t,
        translateY: distance * (1 - t),
        scale: 1 - (scaleDepth * (1 - t)),
        visible: true,
      );
    }

    if (frame < _exitStartFrame) {
      return const StartupMicroFactMotionFrame(
        opacity: 1,
        translateY: 0,
        scale: 1,
        visible: true,
      );
    }

    final t = _easeInCubic(
      (frame - _exitStartFrame) / (_exitEndFrame - _exitStartFrame),
    );
    final distance = mode == StartupMotionMode.balanced ? 6.0 : 9.0;
    final scaleLift = mode == StartupMotionMode.balanced ? 0.004 : 0.008;
    return StartupMicroFactMotionFrame(
      opacity: 1 - t,
      translateY: -distance * t,
      scale: 1 + (scaleLift * t),
      visible: true,
    );
  }

  static double _easeOutCubic(double value) {
    final t = value.clamp(0.0, 1.0).toDouble();
    final inverse = 1 - t;
    return 1 - (inverse * inverse * inverse);
  }

  static double _easeInCubic(double value) {
    final t = value.clamp(0.0, 1.0).toDouble();
    return t * t * t;
  }
}
