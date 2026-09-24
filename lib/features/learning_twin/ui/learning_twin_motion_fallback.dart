import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'learning_twin_motion_state.dart';

String learningTwinFallbackPathFor(LearningTwinMotionState state) {
  return switch (state) {
    LearningTwinMotionState.explain ||
    LearningTwinMotionState.insightReady ||
    LearningTwinMotionState.resultReview =>
      'assets/learning_twin/naveed_twin_explain.svg',
    LearningTwinMotionState.celebrate || LearningTwinMotionState.checkpoint =>
      'assets/learning_twin/naveed_twin_success.svg',
    LearningTwinMotionState.idle ||
    LearningTwinMotionState.welcome ||
    LearningTwinMotionState.thinking ||
    LearningTwinMotionState.focus ||
    LearningTwinMotionState.encourage ||
    LearningTwinMotionState.examReady ||
    LearningTwinMotionState.reducedMotion =>
      'assets/learning_twin/naveed_twin.svg',
  };
}

class LearningTwinMotionFallback extends StatelessWidget {
  const LearningTwinMotionFallback({
    super.key,
    required this.assetPath,
    required this.size,
    required this.decorative,
    required this.semanticLabel,
    this.compactCrop = true,
  });

  final String assetPath;
  final double size;
  final bool decorative;
  final String semanticLabel;
  final bool compactCrop;

  bool get _shouldCrop => compactCrop && size <= 72;

  @override
  Widget build(BuildContext context) {
    Widget picture = SvgPicture.asset(assetPath, fit: BoxFit.contain);

    if (_shouldCrop) {
      picture = ClipRect(
        child: Transform.scale(
          scale: 1.75,
          alignment: Alignment.topCenter,
          child: picture,
        ),
      );
    }

    final framed = SizedBox.square(
      dimension: size,
      child: ColoredBox(
        color: Theme.of(context).colorScheme.inverseSurface,
        child: picture,
      ),
    );

    if (decorative) {
      return ExcludeSemantics(child: framed);
    }

    return Semantics(
      image: true,
      label: semanticLabel,
      child: ExcludeSemantics(child: framed),
    );
  }
}
