import 'dart:convert';
import 'dart:io';

import 'package:exam_platform/screens/startup/startup_motion_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const policyPath = 'content/micro_learning/startup_pedagogy_policy_v1.json';

  Map<String, dynamic> loadPolicy() =>
      jsonDecode(File(policyPath).readAsStringSync()) as Map<String, dynamic>;

  test('ML-7 timing contract matches actual startup motion policy', () {
    final policy = loadPolicy();
    final contract = Map<String, dynamic>.from(
      policy['startupContract'] as Map,
    );

    expect(
      contract['fullMotionDurationMs'],
      StartupMotionPolicy.full.duration.inMilliseconds,
    );
    expect(
      contract['reducedMotionDurationMs'],
      StartupMotionPolicy.reduced.duration.inMilliseconds,
    );
  });

  test('ML-7 remains bound to the seven-second startup fail-open ceiling', () {
    final source = File(
      'lib/screens/startup/csp11_startup_screen.dart',
    ).readAsStringSync();
    final policy = loadPolicy();
    final contract = Map<String, dynamic>.from(
      policy['startupContract'] as Map,
    );

    expect(contract['watchdogCeilingMs'], 7000);
    expect(
      source,
      contains('static const _hardTimeout = Duration(seconds: 7);'),
    );
  });

  test('reduced motion cannot carry motion-only learning meaning', () {
    final policy = loadPolicy();
    final accessibility = Map<String, dynamic>.from(
      policy['accessibilityRules'] as Map,
    );

    expect(accessibility['reducedMotionMeaningMustBeEquivalent'], isTrue);
    expect(accessibility['decorativeAnimationCannotCarryMeaning'], isTrue);
    expect(StartupMotionPolicy.reduced.playLottie, isFalse);
    expect(StartupMotionPolicy.reduced.animateAmbient, isFalse);
  });
}
