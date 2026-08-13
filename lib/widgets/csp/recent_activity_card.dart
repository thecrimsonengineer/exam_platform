import 'package:flutter/material.dart';

import '../../models/student_recent_activity.dart';
import '../../theme/study/study_colors.dart';
import '../../theme/study/study_radius.dart';
import '../../theme/study/study_typography.dart';

class RecentActivityCard extends StatelessWidget {
  final StudentRecentActivity activity;

  const RecentActivityCard({
    super.key,
    required this.activity,
  });

  @override
  Widget build(BuildContext context) {
    final icon = switch (activity.type) {
      StudentRecentActivityType.subtopicOpened =>
        Icons.menu_book_rounded,
      StudentRecentActivityType.subtopicCompleted =>
        Icons.check_circle_rounded,
      StudentRecentActivityType.topicCompleted =>
        Icons.task_alt_rounded,
    };

    final color =
        activity.type == StudentRecentActivityType.subtopicCompleted ||
                activity.type ==
                    StudentRecentActivityType.topicCompleted
            ? const Color(0xFF1F8A4C)
            : StudyColors.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: StudyColors.surface,
        borderRadius: StudyRadius.medium,
        border: Border.all(color: StudyColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: StudyRadius.small,
            ),
            child: Icon(icon, size: 19, color: color),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: StudyTypography.cardTitle.copyWith(
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  activity.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: StudyTypography.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            activity.label,
            style: StudyTypography.eyebrow.copyWith(
              color: color,
              fontSize: 7,
            ),
          ),
        ],
      ),
    );
  }
}
