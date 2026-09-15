import 'package:flutter/material.dart';

import 'learning_twin_asset.dart';
import 'learning_twin_avatar.dart';

class LearningTwinCoachSheet extends StatelessWidget {
  const LearningTwinCoachSheet({
    super.key,
    required this.title,
    required this.message,
    this.asset = LearningTwinAsset.explain,
    this.primaryActionLabel,
    this.onPrimaryAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.onDismiss,
  });

  final String title;
  final String message;
  final LearningTwinAsset asset;
  final String? primaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final actions = <Widget>[
      if (primaryActionLabel != null && onPrimaryAction != null)
        FilledButton(
          onPressed: onPrimaryAction,
          child: Text(primaryActionLabel!),
        ),
      if (secondaryActionLabel != null && onSecondaryAction != null)
        TextButton(
          onPressed: onSecondaryAction,
          child: Text(secondaryActionLabel!),
        ),
    ];

    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(message, style: theme.textTheme.bodyMedium),
        if (actions.isNotEmpty) ...[
          const SizedBox(height: 14),
          Wrap(spacing: 8, runSpacing: 8, children: actions),
        ],
      ],
    );

    Widget body = LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 380;

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LearningTwinAvatar(asset: asset, size: 64),
              const SizedBox(height: 12),
              copy,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LearningTwinAvatar(asset: asset, size: 72),
            const SizedBox(width: 16),
            Expanded(child: copy),
          ],
        );
      },
    );

    if (onDismiss != null) {
      body = Stack(
        children: [
          Padding(padding: const EdgeInsets.only(right: 40), child: body),
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              tooltip: 'Dismiss guidance',
              onPressed: onDismiss,
              icon: const Icon(Icons.close),
            ),
          ),
        ],
      );
    }

    return Semantics(
      container: true,
      label: 'Learning guide coaching',
      child: Material(
        color: colors.surfaceContainer,
        elevation: 1,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: Padding(padding: const EdgeInsets.all(20), child: body),
      ),
    );
  }
}
