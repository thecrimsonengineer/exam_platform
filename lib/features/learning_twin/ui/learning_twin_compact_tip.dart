import 'package:flutter/material.dart';

import 'learning_twin_asset.dart';
import 'learning_twin_avatar.dart';

class LearningTwinCompactTip extends StatelessWidget {
  const LearningTwinCompactTip({
    super.key,
    required this.message,
    this.asset = LearningTwinAsset.neutral,
    this.onTap,
  });

  final String message;
  final LearningTwinAsset asset;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final child = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          LearningTwinAvatar(asset: asset, size: 40),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
          if (onTap != null) ...[
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
          ],
        ],
      ),
    );

    return Semantics(
      container: true,
      button: onTap != null,
      child: Material(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: onTap == null ? child : InkWell(onTap: onTap, child: child),
      ),
    );
  }
}
