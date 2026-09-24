import 'learning_twin_motion_state.dart';

enum LearningTwinMotionSurface {
  hero,
  card,
  celebration,
  compactTip,
  inlineBlock,
  bubble,
  coachSheet,
}

abstract final class LearningTwinMotionRollout {
  /// LTAM-5 may request the Hero pilot, but runtime activation remains gated
  /// until the reviewed canonical idle clip is admitted to the repository.
  static const bool heroPilotRequested = true;
  static const bool canonicalIdleClipAdmitted = false;
  static const String? canonicalIdleClipSha256 = null;

  static const bool heroMotionEnabled =
      heroPilotRequested && canonicalIdleClipAdmitted;

  static const bool cardMotionEnabled = false;
  static const bool celebrationMotionEnabled = false;
  static const bool compactTipMotionEnabled = false;
  static const bool inlineBlockMotionEnabled = false;
  static const bool bubbleMotionEnabled = false;
  static const bool coachSheetMotionEnabled = false;

  static bool enabledFor(LearningTwinMotionSurface surface) {
    return switch (surface) {
      LearningTwinMotionSurface.hero => heroMotionEnabled,
      LearningTwinMotionSurface.card => cardMotionEnabled,
      LearningTwinMotionSurface.celebration => celebrationMotionEnabled,
      LearningTwinMotionSurface.compactTip => compactTipMotionEnabled,
      LearningTwinMotionSurface.inlineBlock => inlineBlockMotionEnabled,
      LearningTwinMotionSurface.bubble => bubbleMotionEnabled,
      LearningTwinMotionSurface.coachSheet => coachSheetMotionEnabled,
    };
  }

  static bool stateAllowedFor(
    LearningTwinMotionSurface surface,
    LearningTwinMotionState state,
  ) {
    return switch (surface) {
      LearningTwinMotionSurface.hero => state == LearningTwinMotionState.idle,
      LearningTwinMotionSurface.card ||
      LearningTwinMotionSurface.celebration ||
      LearningTwinMotionSurface.compactTip ||
      LearningTwinMotionSurface.inlineBlock ||
      LearningTwinMotionSurface.bubble ||
      LearningTwinMotionSurface.coachSheet => false,
    };
  }

  static String? blockedReasonFor(LearningTwinMotionSurface surface) {
    if (surface == LearningTwinMotionSurface.hero &&
        heroPilotRequested &&
        !canonicalIdleClipAdmitted) {
      return 'canonical_idle_clip_not_admitted';
    }

    if (!enabledFor(surface)) {
      return 'surface_rollout_disabled';
    }

    return null;
  }
}
