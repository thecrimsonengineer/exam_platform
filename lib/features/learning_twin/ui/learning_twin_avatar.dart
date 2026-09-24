import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'learning_twin_asset.dart';
import 'learning_twin_motion_controller.dart';
import 'learning_twin_motion_manifest.dart';
import 'learning_twin_motion_renderer.dart';
import 'learning_twin_motion_state.dart';

class LearningTwinAvatar extends StatelessWidget {
  const LearningTwinAvatar({
    super.key,
    this.asset = LearningTwinAsset.neutral,
    this.size = 56,
    this.decorative = false,
    this.compactCrop = true,
    this.semanticLabel,
    this.motionState,
    this.animationEnabled = false,
    this.motionEventKey,
    this.motionVisible = true,
    this.motionController,
    this.motionManifest,
    this.onMotionCompleted,
  }) : assert(size > 0);

  final LearningTwinAsset asset;
  final double size;
  final bool decorative;
  final bool compactCrop;
  final String? semanticLabel;

  /// Opt-in LTAM-4 visual state. Null preserves the original static SVG path.
  final LearningTwinMotionState? motionState;

  /// Production-safe default is false during LTAM-4.
  final bool animationEnabled;
  final String? motionEventKey;
  final bool motionVisible;
  final LearningTwinMotionController? motionController;
  final LearningTwinMotionManifest? motionManifest;
  final VoidCallback? onMotionCompleted;

  bool get _shouldCrop =>
      compactCrop && size <= 72 && asset != LearningTwinAsset.hero;

  @override
  Widget build(BuildContext context) {
    final requestedMotionState = motionState;
    if (requestedMotionState != null) {
      return LearningTwinMotionRenderer(
        state: requestedMotionState,
        size: size,
        animationEnabled: animationEnabled,
        decorative: decorative,
        compactCrop: compactCrop && asset != LearningTwinAsset.hero,
        semanticLabel: semanticLabel ?? asset.semanticLabel,
        eventKey: motionEventKey,
        visible: motionVisible,
        compactSurface: size <= 48,
        fallbackAssetPath: asset.assetPath,
        manifest: motionManifest,
        controller: motionController,
        onCompleted: onMotionCompleted,
      );
    }

    final colors = Theme.of(context).colorScheme;

    Widget picture = SvgPicture.asset(asset.assetPath, fit: BoxFit.contain);

    if (_shouldCrop) {
      picture = ClipRect(
        child: Transform.scale(
          scale: 1.75,
          alignment: Alignment.topCenter,
          child: picture,
        ),
      );
    }

    final sized = SizedBox.square(
      dimension: size,
      child: ColoredBox(color: colors.inverseSurface, child: picture),
    );

    if (decorative) {
      return ExcludeSemantics(child: sized);
    }

    return Semantics(
      image: true,
      label: semanticLabel ?? asset.semanticLabel,
      child: ExcludeSemantics(child: sized),
    );
  }
}
