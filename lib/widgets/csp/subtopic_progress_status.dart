import 'package:flutter/material.dart';

import '../../models/student_learning_progress.dart';
import '../../theme/study/study_colors.dart';
import '../../theme/study/study_radius.dart';
import '../../theme/study/study_typography.dart';

/// Compact status indicator for a learner's subtopic progress.
///
/// This widget contains no persistence or calculation logic. The caller
/// supplies the already-resolved StudentLearningState.
class SubtopicProgressStatus extends StatelessWidget {
  final StudentLearningState state;

  const SubtopicProgressStatus({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case StudentLearningState.completed:
        return _buildBadge(
          label: 'COMPLETED',
          icon: Icons.check_circle_rounded,
          foreground: const Color(0xFF1F8A4C),
          background: const Color(0xFFEAF8F0),
          border: const Color(0xFFB9E7CA),
        );

      case StudentLearningState.inProgress:
        return _buildBadge(
          label: 'IN PROGRESS',
          icon: Icons.timelapse_rounded,
          foreground: StudyColors.primary,
          background: StudyColors.primaryLight,
          border: StudyColors.primary.withValues(alpha: 0.18),
        );

      case StudentLearningState.notStarted:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBadge({
    required String label,
    required IconData icon,
    required Color foreground,
    required Color background,
    required Color border,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: StudyRadius.small,
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: foreground,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: StudyTypography.eyebrow.copyWith(
              color: foreground,
              fontSize: 7,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
