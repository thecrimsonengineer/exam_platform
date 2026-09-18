import 'package:flutter/material.dart';

import 'package:exam_platform/theme/glass/student_glass.dart';

import 'learning_twin_asset.dart';
import 'learning_twin_avatar.dart';

class LearningTwinCard extends StatelessWidget {
  const LearningTwinCard({
    super.key,
    required this.title,
    required this.message,
    this.asset = LearningTwinAsset.neutral,
    this.actionLabel,
    this.onAction,
    this.onDismiss,
  });

  final String title;
  final String message;
  final LearningTwinAsset asset;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(message, style: theme.textTheme.bodyMedium),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: 10),
          FilledButton.tonal(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ],
    );

    return StudentGlassCard(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 340;

            final body = compact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LearningTwinAvatar(asset: asset, size: 56),
                      const SizedBox(height: 10),
                      content,
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LearningTwinAvatar(asset: asset, size: 56),
                      const SizedBox(width: 12),
                      Expanded(child: content),
                    ],
                  );

            if (onDismiss == null) {
              return body;
            }

            return Stack(
              children: [
                Padding(padding: const EdgeInsets.only(right: 36), child: body),
                Positioned(
                  right: 0,
                  top: 0,
                  child: IconButton(
                    tooltip: 'Dismiss guidance',
                    onPressed: onDismiss,
                    icon: Icon(Icons.close, color: colors.onSurfaceVariant),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
