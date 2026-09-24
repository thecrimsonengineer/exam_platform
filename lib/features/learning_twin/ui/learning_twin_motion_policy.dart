import 'learning_twin_motion_error.dart';
import 'learning_twin_motion_state.dart';

final class LearningTwinMotionPolicyInput {
  const LearningTwinMotionPolicyInput({
    required this.animationEnabled,
    required this.platformAnimationsDisabled,
    required this.visible,
    required this.appActive,
    required this.manifestValid,
    required this.stateAvailable,
    this.compactSurface = false,
    this.compactMotionAllowed = true,
    this.developerForceStatic = false,
    this.developerForceAnimation = false,
  });

  final bool animationEnabled;
  final bool platformAnimationsDisabled;
  final bool visible;
  final bool appActive;
  final bool manifestValid;
  final bool stateAvailable;
  final bool compactSurface;
  final bool compactMotionAllowed;
  final bool developerForceStatic;
  final bool developerForceAnimation;
}

final class LearningTwinMotionPolicyDecision {
  const LearningTwinMotionPolicyDecision({
    required this.animate,
    required this.effectiveState,
    required this.fallbackReason,
  });

  final bool animate;
  final LearningTwinMotionState effectiveState;
  final LearningTwinMotionFallbackReason fallbackReason;
}

abstract final class LearningTwinMotionPolicy {
  static LearningTwinMotionPolicyDecision resolve(
    LearningTwinMotionState requestedState,
    LearningTwinMotionPolicyInput input,
  ) {
    if (input.platformAnimationsDisabled) {
      return const LearningTwinMotionPolicyDecision(
        animate: false,
        effectiveState: LearningTwinMotionState.reducedMotion,
        fallbackReason: LearningTwinMotionFallbackReason.reducedMotion,
      );
    }

    if (input.developerForceStatic) {
      return LearningTwinMotionPolicyDecision(
        animate: false,
        effectiveState: requestedState,
        fallbackReason:
            LearningTwinMotionFallbackReason.developerForcedStatic,
      );
    }

    if (!input.animationEnabled && !input.developerForceAnimation) {
      return LearningTwinMotionPolicyDecision(
        animate: false,
        effectiveState: requestedState,
        fallbackReason: LearningTwinMotionFallbackReason.animationDisabled,
      );
    }

    if (!input.visible) {
      return LearningTwinMotionPolicyDecision(
        animate: false,
        effectiveState: requestedState,
        fallbackReason: LearningTwinMotionFallbackReason.notVisible,
      );
    }

    if (!input.appActive) {
      return LearningTwinMotionPolicyDecision(
        animate: false,
        effectiveState: requestedState,
        fallbackReason: LearningTwinMotionFallbackReason.appInactive,
      );
    }

    if (input.compactSurface && !input.compactMotionAllowed) {
      return LearningTwinMotionPolicyDecision(
        animate: false,
        effectiveState: requestedState,
        fallbackReason: LearningTwinMotionFallbackReason.compactSurface,
      );
    }

    if (!input.manifestValid) {
      return LearningTwinMotionPolicyDecision(
        animate: false,
        effectiveState: requestedState,
        fallbackReason: LearningTwinMotionFallbackReason.manifestInvalid,
      );
    }

    if (!input.stateAvailable) {
      return LearningTwinMotionPolicyDecision(
        animate: false,
        effectiveState: requestedState,
        fallbackReason: LearningTwinMotionFallbackReason.stateMissing,
      );
    }

    return LearningTwinMotionPolicyDecision(
      animate: true,
      effectiveState: requestedState,
      fallbackReason: LearningTwinMotionFallbackReason.none,
    );
  }
}
