import 'dart:ui';

import 'package:exam_platform/screens/startup/startup_motion_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StartupMotionPolicy', () {
    test('selects reduced mode when animations are disabled', () {
      final policy = StartupMotionPolicy.resolve(
        disableAnimations: true,
        reduceMotion: false,
        logicalSize: const Size(400, 800),
        devicePixelRatio: 3,
      );

      expect(policy.mode, StartupMotionMode.reduced);
      expect(policy.duration, const Duration(milliseconds: 250));
      expect(policy.particleCount, 0);
      expect(policy.blurSigma, 0);
      expect(policy.playLottie, isFalse);
      expect(policy.animateAmbient, isFalse);
    });

    test('selects reduced mode for platform reduce-motion requests', () {
      final policy = StartupMotionPolicy.resolve(
        disableAnimations: false,
        reduceMotion: true,
        logicalSize: const Size(400, 800),
        devicePixelRatio: 3,
      );

      expect(policy, same(StartupMotionPolicy.reduced));
    });

    test('selects balanced mode for high raster workload', () {
      final policy = StartupMotionPolicy.resolve(
        disableAnimations: false,
        reduceMotion: false,
        logicalSize: const Size(430, 932),
        devicePixelRatio: 3.5,
      );

      expect(policy.mode, StartupMotionMode.balanced);
      expect(policy.particleCount, 20);
      expect(policy.blurSigma, 8);
      expect(policy.playLottie, isTrue);
    });

    test('selects balanced mode for narrow viewports', () {
      final policy = StartupMotionPolicy.resolve(
        disableAnimations: false,
        reduceMotion: false,
        logicalSize: const Size(320, 640),
        devicePixelRatio: 2,
      );

      expect(policy.mode, StartupMotionMode.balanced);
    });

    test('keeps full mode when no reduction trigger applies', () {
      final policy = StartupMotionPolicy.resolve(
        disableAnimations: false,
        reduceMotion: false,
        logicalSize: const Size(800, 600),
        devicePixelRatio: 1,
      );

      expect(policy, same(StartupMotionPolicy.full));
      expect(policy.duration, const Duration(milliseconds: 4800));
      expect(policy.particleCount, 34);
      expect(policy.blurSigma, 15);
    });
  });
}
