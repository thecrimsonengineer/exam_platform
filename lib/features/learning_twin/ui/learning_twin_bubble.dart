import 'package:flutter/material.dart';

import 'learning_twin_asset.dart';
import 'learning_twin_avatar.dart';

class LearningTwinBubble extends StatelessWidget {
  const LearningTwinBubble({
    super.key,
    required this.message,
    this.title = 'Naveed',
    this.asset = LearningTwinAsset.explain,
    this.avatarSize = 48,
  });

  final String title;
  final String message;
  final LearningTwinAsset asset;
  final double avatarSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    Widget bubble = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(message, style: theme.textTheme.bodyMedium),
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final veryNarrow = constraints.maxWidth < 300;

        if (veryNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LearningTwinAvatar(asset: asset, size: avatarSize),
              const SizedBox(height: 8),
              bubble,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LearningTwinAvatar(asset: asset, size: avatarSize),
            const SizedBox(width: 10),
            Expanded(child: bubble),
          ],
        );
      },
    );
  }
}
