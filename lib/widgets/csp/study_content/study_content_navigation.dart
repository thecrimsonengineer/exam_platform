import 'package:flutter/material.dart';

import '../../../theme/study/study_colors.dart';
import '../../../theme/study/study_icons.dart';
import '../../../theme/study/study_radius.dart';
import '../../../theme/study/study_shadows.dart';
import '../../../theme/study/study_typography.dart';

class StudyContentNavigation extends StatelessWidget {
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final String? previousLabel;
  final String? nextLabel;
  final double progress;

  const StudyContentNavigation({
    super.key,
    this.onPrevious,
    this.onNext,
    this.previousLabel,
    this.nextLabel,
    this.progress = 0,
  });

  @override
  Widget build(BuildContext context) {
    final safeProgress = progress.clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: StudyColors.surface,
        border: Border(top: BorderSide(color: StudyColors.border)),
        boxShadow: StudyShadows.soft,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Column(
            children: [
              _buildProgress(safeProgress),
              const SizedBox(height: 14),
              _buildNavigation(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgress(double progress) {
    return Row(
      children: [
        Text(
          'STUDY PROGRESS',
          style: StudyTypography.eyebrow.copyWith(
            color: StudyColors.textSecondary,
            fontSize: 9,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ClipRRect(
            borderRadius: StudyRadius.pillRadius,
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: StudyColors.surfaceSoft,
              valueColor: const AlwaysStoppedAnimation<Color>(
                StudyColors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '${(progress * 100).round()}%',
          style: StudyTypography.label.copyWith(color: StudyColors.primary),
        ),
      ],
    );
  }

  Widget _buildNavigation() {
    return Row(
      children: [
        Expanded(
          child: _buildNavigationButton(
            icon: StudyIcons.previous,
            label: previousLabel ?? 'Previous',
            onPressed: onPrevious,
            alignment: Alignment.centerLeft,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildNavigationButton(
            icon: StudyIcons.next,
            label: nextLabel ?? 'Next',
            onPressed: onNext,
            alignment: Alignment.centerRight,
            primary: true,
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required Alignment alignment,
    bool primary = false,
  }) {
    final enabled = onPressed != null;

    final background = primary ? StudyColors.primary : StudyColors.surfaceSoft;

    final foreground = primary ? Colors.white : StudyColors.textPrimary;

    return Align(
      alignment: alignment,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: StudyRadius.medium,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            constraints: const BoxConstraints(minHeight: 50),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: enabled ? background : StudyColors.surfaceSoft,
              borderRadius: StudyRadius.medium,
              border: Border.all(
                color: primary ? StudyColors.primary : StudyColors.border,
              ),
              boxShadow: enabled && primary ? StudyShadows.soft : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!primary) ...[
                  Icon(
                    icon,
                    size: 19,
                    color: enabled ? foreground : StudyColors.textMuted,
                  ),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: StudyTypography.label.copyWith(
                      color: enabled ? foreground : StudyColors.textMuted,
                    ),
                  ),
                ),
                if (primary) ...[
                  const SizedBox(width: 8),
                  Icon(
                    icon,
                    size: 19,
                    color: enabled ? foreground : StudyColors.textMuted,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
