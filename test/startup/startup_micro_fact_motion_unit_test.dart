import 'package:exam_platform/screens/startup/startup_micro_fact_motion.dart';
import 'package:exam_platform/screens/startup/startup_motion_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  double progressAtFrame(double frame) => frame / 144;

  test('reduced motion is always static and fully visible', () {
    for (final progress in [0.0, 0.25, 0.5, 0.9, 1.0]) {
      final frame = StartupMicroFactMotion.sample(
        progress: progress,
        mode: StartupMotionMode.reduced,
      );

      expect(frame.opacity, 1);
      expect(frame.translateY, 0);
      expect(frame.scale, 1);
      expect(frame.visible, isTrue);
    }
  });

  test('full motion enters, holds, exits, then becomes transparent', () {
    final before = StartupMicroFactMotion.sample(
      progress: progressAtFrame(0),
      mode: StartupMotionMode.full,
    );
    final entering = StartupMicroFactMotion.sample(
      progress: progressAtFrame(20),
      mode: StartupMotionMode.full,
    );
    final holding = StartupMicroFactMotion.sample(
      progress: progressAtFrame(60),
      mode: StartupMotionMode.full,
    );
    final exiting = StartupMicroFactMotion.sample(
      progress: progressAtFrame(120),
      mode: StartupMotionMode.full,
    );
    final after = StartupMicroFactMotion.sample(
      progress: progressAtFrame(132),
      mode: StartupMotionMode.full,
    );

    expect(before.opacity, 0);
    expect(before.visible, isFalse);

    expect(entering.opacity, greaterThan(0));
    expect(entering.opacity, lessThan(1));
    expect(entering.translateY, greaterThan(0));
    expect(entering.scale, lessThan(1));

    expect(holding.opacity, 1);
    expect(holding.translateY, 0);
    expect(holding.scale, 1);

    expect(exiting.opacity, greaterThan(0));
    expect(exiting.opacity, lessThan(1));
    expect(exiting.translateY, lessThan(0));
    expect(exiting.scale, greaterThan(1));

    expect(after.opacity, 0);
    expect(after.visible, isFalse);
  });

  test('balanced mode uses smaller translation and scale excursions', () {
    final fullEnter = StartupMicroFactMotion.sample(
      progress: progressAtFrame(20),
      mode: StartupMotionMode.full,
    );
    final balancedEnter = StartupMicroFactMotion.sample(
      progress: progressAtFrame(20),
      mode: StartupMotionMode.balanced,
    );
    final fullExit = StartupMicroFactMotion.sample(
      progress: progressAtFrame(120),
      mode: StartupMotionMode.full,
    );
    final balancedExit = StartupMicroFactMotion.sample(
      progress: progressAtFrame(120),
      mode: StartupMotionMode.balanced,
    );

    expect(balancedEnter.translateY, lessThan(fullEnter.translateY));
    expect(
      (1 - balancedEnter.scale).abs(),
      lessThan((1 - fullEnter.scale).abs()),
    );
    expect(balancedExit.translateY.abs(), lessThan(fullExit.translateY.abs()));
    expect(
      (balancedExit.scale - 1).abs(),
      lessThan((fullExit.scale - 1).abs()),
    );
  });

  test('sampling clamps progress without changing the startup clock', () {
    final before = StartupMicroFactMotion.sample(
      progress: -10,
      mode: StartupMotionMode.full,
    );
    final after = StartupMicroFactMotion.sample(
      progress: 10,
      mode: StartupMotionMode.full,
    );

    expect(before.opacity, 0);
    expect(after.opacity, 0);
  });
}
