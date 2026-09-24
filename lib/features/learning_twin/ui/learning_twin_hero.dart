import 'package:flutter/material.dart';

import 'package:exam_platform/theme/glass/student_glass.dart';

import 'learning_twin_asset.dart';
import 'learning_twin_avatar.dart';
import 'learning_twin_motion_rollout.dart';
import 'learning_twin_motion_state.dart';

class LearningTwinHero extends StatelessWidget {
  const LearningTwinHero({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.motionPilotEnabled = LearningTwinMotionRollout.heroMotionEnabled,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Presentation-only LTAM-5 Hero pilot switch.
  ///
  /// The production default remains fail-closed until the canonical reviewed
  /// idle Lottie clip is admitted. Tests and controlled review builds may
  /// explicitly enable this path to exercise fallback and lifecycle behavior.
  final bool motionPilotEnabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final pilotState =
        motionPilotEnabled &&
            LearningTwinMotionRollout.stateAllowedFor(
              LearningTwinMotionSurface.hero,
              LearningTwinMotionState.idle,
            )
        ? LearningTwinMotionState.idle
        : null;

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

    Widget avatar(double size) {
      return LearningTwinAvatar(
        asset: LearningTwinAsset.hero,
        size: size,
        compactCrop: false,
        motionState: pilotState,
        animationEnabled: pilotState != null,
        motionSurface: 'hero',
      );
    }

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
                Center(child: avatar(150)),
                const SizedBox(height: 14),
                copy,
              ],
            );
          }

          return Row(
            children: [
              avatar(180),
              const SizedBox(width: 24),
              Expanded(child: copy),
            ],
          );
        },
      ),
    );
  }
}
