enum LearningTwinMotionErrorCode {
  manifestMissing,
  malformedJson,
  unsupportedSchema,
  invalidTwinId,
  invalidDefaultState,
  missingCanonicalState,
  duplicateState,
  unsupportedState,
  invalidDescriptor,
  remoteAssetPath,
  pathTraversal,
  assetLoadFailure,
}

final class LearningTwinMotionFailure {
  const LearningTwinMotionFailure(this.code, this.message);

  final LearningTwinMotionErrorCode code;
  final String message;

  @override
  String toString() => 'LearningTwinMotionFailure($code, $message)';
}

enum LearningTwinMotionFallbackReason {
  none,
  animationDisabled,
  reducedMotion,
  notVisible,
  appInactive,
  compactSurface,
  manifestInvalid,
  stateMissing,
  developerForcedStatic,
  assetLoadFailure,
}
