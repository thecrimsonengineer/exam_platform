import 'package:flutter/material.dart';
import '../../theme/study/study_colors.dart';
import '../../theme/study/study_radius.dart';
import '../../theme/study/study_shadows.dart';
import '../../theme/study/study_typography.dart';
import '../../models/student_competency_progress.dart';

/// Compact learner-facing competency progress card.
///
/// All progress values come from StudentCompetencyProgress.
/// This widget intentionally contains no progress calculation logic.
class CompetencyProgressCard extends StatelessWidget {
  final StudentCompetencyProgress progress;

  const CompetencyProgressCard({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    final percentage = (progress.progress * 100).round();
    final completed = progress.completedSubtopics;
    final total = progress.totalSubtopics;

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'COMPETENCY PROGRESS',
                      style: StudyTypography.eyebrow.copyWith(
                        color: StudyColors.primary,
                        fontSize: 8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      progress.competencyTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: StudyTypography.cardTitle.copyWith(fontSize: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$percentage%',
                style: StudyTypography.cardTitle.copyWith(
                  color: StudyColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress.progress,
              minHeight: 7,
              backgroundColor: StudyColors.surfaceSoft,
              valueColor: const AlwaysStoppedAnimation<Color>(
                StudyColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Text(
                '$completed of $total subtopics completed',
                style: StudyTypography.caption,
              ),
              const Spacer(),
              Text(
                progress.statusLabel,
                style: StudyTypography.eyebrow.copyWith(
                  color: progress.completedSubtopics == total && total > 0
                      ? const Color(0xFF1F8A4C)
                      : StudyColors.textSecondary,
                  fontSize: 8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
