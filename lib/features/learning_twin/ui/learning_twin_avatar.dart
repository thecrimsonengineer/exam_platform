import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'learning_twin_asset.dart';

class LearningTwinAvatar extends StatelessWidget {
  const LearningTwinAvatar({
    super.key,
    this.asset = LearningTwinAsset.neutral,
    this.size = 56,
    this.decorative = false,
    this.compactCrop = true,
    this.semanticLabel,
  }) : assert(size > 0);

  final LearningTwinAsset asset;
  final double size;
  final bool decorative;
  final bool compactCrop;
  final String? semanticLabel;

  bool get _shouldCrop =>
      compactCrop && size <= 72 && asset != LearningTwinAsset.hero;

  @override
  Widget build(BuildContext context) {
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

    // Keep the Learning Twin avatar visually distinct from the surrounding
    // surface in both themes. Material's inverseSurface is intentionally the
    // opposite-brightness surface: dark in light mode and light in dark mode.
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
