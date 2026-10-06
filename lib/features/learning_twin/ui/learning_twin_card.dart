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
    this.invertSurfaceContrast = false,
  });

  final String title;
  final String message;
  final LearningTwinAsset asset;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onDismiss;
  final bool invertSurfaceContrast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    final inverseSurface = isDarkMode
        ? const Color(0xFFF7F9FC)
        : const Color(0xFF101827);
    final inverseTextPrimary = isDarkMode
        ? const Color(0xFF18243A)
        : const Color(0xFFF7F9FC);
    final inverseTextSecondary = isDarkMode
        ? const Color(0xFF536176)
        : const Color(0xFFCFD8E6);
    final inverseBorder = isDarkMode
        ? const Color(0x1F18243A)
        : const Color(0x26FFFFFF);
    final inverseShadow = isDarkMode
        ? const Color(0x52000000)
        : const Color(0x40000000);

    final titleColor = invertSurfaceContrast ? inverseTextPrimary : null;
    final bodyColor = invertSurfaceContrast ? inverseTextSecondary : null;
    final dismissColor = invertSurfaceContrast
        ? inverseTextSecondary
        : colors.onSurfaceVariant;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            color: titleColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(color: bodyColor),
        ),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: 10),
          FilledButton.tonal(
            style: invertSurfaceContrast
                ? FilledButton.styleFrom(
                    backgroundColor: isDarkMode
                        ? const Color(0xFFE5EAF1)
                        : const Color(0xFF24344D),
                    foregroundColor: inverseTextPrimary,
                  )
                : null,
            onPressed: onAction,
            child: Text(actionLabel!),
          ),
        ],
      ],
    );

    final cardBody = Padding(
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
                  icon: Icon(Icons.close, color: dismissColor),
                ),
              ),
            ],
          );
        },
      ),
    );

    if (!invertSurfaceContrast) {
      return StudentGlassCard(clipBehavior: Clip.antiAlias, child: cardBody);
    }

    return StudentGlassSurface(
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          inverseSurface,
          Color.lerp(
            inverseSurface,
            isDarkMode ? Colors.white : const Color(0xFF1A2940),
            isDarkMode ? 0.08 : 0.18,
          )!,
        ],
      ),
      borderColor: inverseBorder,
      shadowColor: inverseShadow,
      child: cardBody,
    );
  }
}
