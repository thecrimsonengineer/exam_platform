import 'package:flutter/material.dart';

import 'learning_twin_asset.dart';
import 'learning_twin_avatar.dart';

class LearningTwinCelebration extends StatelessWidget {
  const LearningTwinCelebration({
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(message, style: theme.textTheme.bodyMedium),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: 12),
          FilledButton.tonal(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ],
    );

    return Semantics(
      container: true,
      liveRegion: true,
      label: 'Learning milestone',
      child: Card(
        color: colors.tertiaryContainer,
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 420;

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const LearningTwinAvatar(
                      asset: LearningTwinAsset.success,
                      size: 72,
                    ),
                    const SizedBox(height: 10),
                    copy,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const LearningTwinAvatar(
                    asset: LearningTwinAsset.success,
                    size: 88,
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: copy),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
