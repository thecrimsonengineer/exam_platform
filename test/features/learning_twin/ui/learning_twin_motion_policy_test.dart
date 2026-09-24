import 'package:exam_platform/features/learning_twin/ui/learning_twin_motion_error.dart';
import 'package:exam_platform/features/learning_twin/ui/learning_twin_motion_policy.dart';
import 'package:exam_platform/features/learning_twin/ui/learning_twin_motion_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const allowed = LearningTwinMotionPolicyInput(
    animationEnabled: true,
    platformAnimationsDisabled: false,
    visible: true,
    appActive: true,
    manifestValid: true,
    stateAvailable: true,
  );

  test('permits animation when every presentation gate passes', () {
    final decision = LearningTwinMotionPolicy.resolve(
      LearningTwinMotionState.celebrate,
      allowed,
    );

    expect(decision.animate, isTrue);
    expect(
      decision.fallbackReason,
      LearningTwinMotionFallbackReason.none,
    );
  });

  test('platform reduced motion always wins', () {
    const input = LearningTwinMotionPolicyInput(
      animationEnabled: true,
      platformAnimationsDisabled: true,
      visible: true,
      appActive: true,
      manifestValid: true,
      stateAvailable: true,
      developerForceAnimation: true,
    );

    final decision = LearningTwinMotionPolicy.resolve(
      LearningTwinMotionState.celebrate,
      input,
    );

    expect(decision.animate, isFalse);
    expect(
      decision.effectiveState,
      LearningTwinMotionState.reducedMotion,
    );
    expect(
      decision.fallbackReason,
      LearningTwinMotionFallbackReason.reducedMotion,
    );
  });

  test('disabled animation resolves to static fallback', () {
    const input = LearningTwinMotionPolicyInput(
      animationEnabled: false,
      platformAnimationsDisabled: false,
      visible: true,
      appActive: true,
      manifestValid: true,
      stateAvailable: true,
    );

    final decision = LearningTwinMotionPolicy.resolve(
      LearningTwinMotionState.explain,
      input,
    );

    expect(decision.animate, isFalse);
    expect(
      decision.fallbackReason,
      LearningTwinMotionFallbackReason.animationDisabled,
    );
  });

  test('visibility and lifecycle gates deny playback', () {
    const hidden = LearningTwinMotionPolicyInput(
      animationEnabled: true,
      platformAnimationsDisabled: false,
      visible: false,
      appActive: true,
      manifestValid: true,
      stateAvailable: true,
    );
    const inactive = LearningTwinMotionPolicyInput(
      animationEnabled: true,
      platformAnimationsDisabled: false,
      visible: true,
      appActive: false,
      manifestValid: true,
      stateAvailable: true,
    );

    expect(
      LearningTwinMotionPolicy.resolve(
        LearningTwinMotionState.idle,
        hidden,
      ).fallbackReason,
      LearningTwinMotionFallbackReason.notVisible,
    );
    expect(
      LearningTwinMotionPolicy.resolve(
        LearningTwinMotionState.idle,
        inactive,
      ).fallbackReason,
      LearningTwinMotionFallbackReason.appInactive,
    );
  });

  test('invalid manifest and missing state fail closed', () {
    const invalidManifest = LearningTwinMotionPolicyInput(
      animationEnabled: true,
      platformAnimationsDisabled: false,
      visible: true,
      appActive: true,
      manifestValid: false,
      stateAvailable: true,
    );
    const missingState = LearningTwinMotionPolicyInput(
      animationEnabled: true,
      platformAnimationsDisabled: false,
      visible: true,
      appActive: true,
      manifestValid: true,
      stateAvailable: false,
    );

    expect(
      LearningTwinMotionPolicy.resolve(
        LearningTwinMotionState.idle,
        invalidManifest,
      ).fallbackReason,
      LearningTwinMotionFallbackReason.manifestInvalid,
    );
    expect(
      LearningTwinMotionPolicy.resolve(
        LearningTwinMotionState.idle,
        missingState,
      ).fallbackReason,
      LearningTwinMotionFallbackReason.stateMissing,
    );
  });
}
