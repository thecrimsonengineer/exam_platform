import 'dart:ui';

enum StartupMotionMode { full, balanced, reduced }

class StartupMotionPolicy {
  const StartupMotionPolicy({
    required this.mode,
    required this.duration,
    required this.particleCount,
    required this.blurSigma,
    required this.playLottie,
    required this.animateAmbient,
  });

  static const full = StartupMotionPolicy(
    mode: StartupMotionMode.full,
    duration: Duration(milliseconds: 4800),
    particleCount: 34,
    blurSigma: 15,
    playLottie: true,
    animateAmbient: true,
  );

  static const balanced = StartupMotionPolicy(
    mode: StartupMotionMode.balanced,
    duration: Duration(milliseconds: 4800),
    particleCount: 20,
    blurSigma: 8,
    playLottie: true,
    animateAmbient: true,
  );

  static const reduced = StartupMotionPolicy(
    mode: StartupMotionMode.reduced,
    duration: Duration(milliseconds: 250),
    particleCount: 0,
    blurSigma: 0,
    playLottie: false,
    animateAmbient: false,
  );

  final StartupMotionMode mode;
  final Duration duration;
  final int particleCount;
  final double blurSigma;
  final bool playLottie;
  final bool animateAmbient;

  bool get isReduced => mode == StartupMotionMode.reduced;

  static StartupMotionPolicy resolve({
    required bool disableAnimations,
    required bool reduceMotion,
    required Size logicalSize,
    required double devicePixelRatio,
  }) {
    if (disableAnimations || reduceMotion) {
      return reduced;
    }

    final pixelRatio = devicePixelRatio.clamp(1.0, 8.0).toDouble();
    final physicalPixelLoad =
        logicalSize.width * logicalSize.height * pixelRatio * pixelRatio;
    final shortestSide =
        logicalSize.width < logicalSize.height ? logicalSize.width : logicalSize.height;

    if (physicalPixelLoad >= 4500000 || shortestSide < 360) {
      return balanced;
    }

    return full;
  }
}
