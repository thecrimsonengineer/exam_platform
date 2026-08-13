import 'package:flutter/material.dart';

import '../../models/subtopic_learning_status.dart';
import '../../theme/study/study_colors.dart';
import '../../theme/study/study_radius.dart';
import '../../theme/study/study_shadows.dart';
import '../../theme/study/study_typography.dart';

class SubtopicLearningStatusCard extends StatelessWidget {
  final SubtopicLearningStatus status;

  const SubtopicLearningStatusCard({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final score = status.quizScore;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: StudyColors.surface,
        borderRadius: StudyRadius.large,
        border: Border.all(color: StudyColors.border),
        boxShadow: StudyShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LEARNING STATUS',
            style: StudyTypography.eyebrow.copyWith(
              color: StudyColors.primary,
              fontSize: 8,
            ),
          ),
          const SizedBox(height: 12),
          _row(
            'Study',
            status.studyCompleted ? 'Completed' : 'In progress',
          ),
          const SizedBox(height: 8),
          _row(
            'Topics',
            '${status.completedTopics}/${status.totalTopics}',
          ),
          const SizedBox(height: 8),
          _row(
            'Quiz',
            status.quizCompleted ? 'Completed' : 'Not completed',
          ),
          if (score != null) ...[
            const SizedBox(height: 8),
            _row(
              'Score',
              '${(score * 100).round()}%',
            ),
          ],
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: StudyColors.primaryLight,
              borderRadius: StudyRadius.medium,
            ),
            child: Text(
              status.statusLabel,
              style: StudyTypography.eyebrow.copyWith(
                color: StudyColors.primary,
                fontSize: 8,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: StudyTypography.bodySecondary,
        ),
        const Spacer(),
        Text(
          value,
          style: StudyTypography.cardTitle.copyWith(
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
