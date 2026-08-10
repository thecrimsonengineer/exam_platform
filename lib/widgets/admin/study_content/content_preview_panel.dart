import 'package:flutter/material.dart';

import '../../../models/study_content.dart';
import '../../../theme/study/study_colors.dart';
import '../../../theme/study/study_radius.dart';
import '../../../theme/study/study_typography.dart';
import '../../csp/study_content/study_content_renderer.dart';

/// Admin-side final preview.
///
/// This reuses the exact student-facing StudyContentRenderer.
/// No second preview renderer is created here.
class ContentPreviewPanel extends StatelessWidget {
  final StudyContent? content;
  final VoidCallback? onExit;

  const ContentPreviewPanel({super.key, required this.content, this.onExit});

  @override
  Widget build(BuildContext context) {
    final studyContent = content;

    if (studyContent == null) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        _buildPreviewToolbar(studyContent),
        Expanded(
          child: ClipRect(child: StudyContentRenderer(content: studyContent)),
        ),
      ],
    );
  }

  Widget _buildPreviewToolbar(StudyContent content) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: StudyColors.surface,
        border: Border(bottom: BorderSide(color: StudyColors.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: StudyColors.successLight,
              borderRadius: StudyRadius.small,
            ),
            child: const Icon(
              Icons.visibility_rounded,
              size: 17,
              color: StudyColors.success,
            ),
          ),
          const SizedBox(width: 10),
          const Text('Student Preview', style: StudyTypography.label),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: StudyColors.surfaceSoft,
              borderRadius: StudyRadius.pillRadius,
            ),
            child: Text(
              'LIVE RENDER',
              style: StudyTypography.eyebrow.copyWith(
                fontSize: 8,
                color: StudyColors.textSecondary,
              ),
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              content.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: StudyTypography.bodySecondary,
              textAlign: TextAlign.right,
            ),
          ),
          if (onExit != null) ...[
            const SizedBox(width: 14),
            OutlinedButton.icon(
              onPressed: onExit,
              icon: const Icon(Icons.arrow_back_rounded, size: 16),
              label: const Text('Back to Studio'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      color: StudyColors.background,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(32),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 560),
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: StudyColors.surface,
          borderRadius: StudyRadius.large,
          border: Border.all(color: StudyColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: StudyColors.primaryLight,
                borderRadius: StudyRadius.medium,
              ),
              child: const Icon(
                Icons.visibility_rounded,
                size: 26,
                color: StudyColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No content available for preview',
              style: StudyTypography.cardTitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 7),
            const Text(
              'Import a complete competency package first. '
              'The final preview will then use the exact student-facing renderer.',
              style: StudyTypography.bodySecondary,
              textAlign: TextAlign.center,
            ),
            if (onExit != null) ...[
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: onExit,
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: const Text('Back to Studio'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
