import 'package:flutter/material.dart';

import 'package:exam_platform/theme/glass/student_glass.dart';

import 'learning_twin_asset.dart';
import 'learning_twin_avatar.dart';

class LearningTwinHero extends StatelessWidget {
  const LearningTwinHero({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final copy = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(message, style: theme.textTheme.bodyLarge),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: 14),
          FilledButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ],
    );

    return StudentGlassSurface(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(24),
      tint: colors.secondaryContainer.withValues(alpha: 0.58),
      borderColor: colors.secondary.withValues(alpha: 0.20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 560;

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: LearningTwinAvatar(
                    asset: LearningTwinAsset.hero,
                    size: 150,
                    compactCrop: false,
                  ),
                ),
                const SizedBox(height: 14),
                copy,
              ],
            );
          }

          return Row(
            children: [
              const LearningTwinAvatar(
                asset: LearningTwinAsset.hero,
                size: 180,
                compactCrop: false,
              ),
              const SizedBox(width: 24),
              Expanded(child: copy),
            ],
          );
        },
      ),
    );
  }
}
