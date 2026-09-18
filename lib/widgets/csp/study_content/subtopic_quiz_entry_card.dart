import 'package:flutter/material.dart';

import 'package:exam_platform/theme/glass/student_glass.dart';

import '../../../models/subtopic_quiz_status.dart';
import '../../../theme/study/study_colors.dart';
import '../../../theme/study/study_radius.dart';
import '../../../theme/study/study_typography.dart';

class SubtopicQuizEntryCard extends StatelessWidget {
  final SubtopicQuizStatus status;
  final VoidCallback onOpenQuiz;

  const SubtopicQuizEntryCard({
    super.key,
    required this.status,
    required this.onOpenQuiz,
  });

  @override
  Widget build(BuildContext context) {
    final score = status.score;
    final scoreText = score == null ? null : '${(score * 100).round()}%';

    return StudentGlassSurface(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      borderRadius: StudyRadius.large,
      tint: StudyColors.surface.withValues(alpha: 0.56),
      borderColor: StudyColors.border.withValues(alpha: 0.72),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PRACTICE QUIZ',
            style: StudyTypography.eyebrow.copyWith(
              color: StudyColors.primary,
              fontSize: 8,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${status.questionCount} questions',
            style: StudyTypography.cardTitle,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                status.statusLabel,
                style: StudyTypography.eyebrow.copyWith(
                  color: status.status == SubtopicQuizStatusType.completed
                      ? const Color(0xFF1F8A4C)
                      : StudyColors.textSecondary,
                  fontSize: 8,
                ),
              ),
              if (scoreText != null) ...[
                const Spacer(),
                Text(
                  scoreText,
                  style: StudyTypography.cardTitle.copyWith(
                    color: StudyColors.primary,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onOpenQuiz,
              child: Text(
                status.status == SubtopicQuizStatusType.completed
                    ? 'REVIEW QUIZ'
                    : 'START QUIZ',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
