import 'package:flutter/material.dart';

import 'package:exam_platform/theme/glass/student_glass.dart';

import 'learning_twin_asset.dart';
import 'learning_twin_avatar.dart';

class LearningTwinInlineBlock extends StatelessWidget {
  const LearningTwinInlineBlock({
    super.key,
    required this.message,
    this.title,
    this.asset = LearningTwinAsset.explain,
    this.actionLabel,
    this.onAction,
  });

  final String? title;
  final String message;
  final LearningTwinAsset asset;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Text(
            title!,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
        ],
        Text(message, style: theme.textTheme.bodyMedium),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: 6),
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ],
    );

    return Semantics(
      container: true,
      child: StudentGlassSurface(
        padding: const EdgeInsets.all(14),
        borderRadius: BorderRadius.circular(16),
        tint: colors.surfaceContainerLow.withValues(alpha: 0.54),
        borderColor: colors.outlineVariant.withValues(alpha: 0.62),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 300;

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LearningTwinAvatar(asset: asset, size: 48),
                  const SizedBox(height: 8),
                  copy,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LearningTwinAvatar(asset: asset, size: 48),
                const SizedBox(width: 12),
                Expanded(child: copy),
              ],
            );
          },
        ),
      ),
    );
  }
}
