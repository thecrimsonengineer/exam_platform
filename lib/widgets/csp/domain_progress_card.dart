import 'package:flutter/material.dart';

import '../../models/student_progress_dashboard.dart';
import '../../theme/study/study_colors.dart';
import '../../theme/study/study_radius.dart';
import '../../theme/study/study_shadows.dart';
import '../../theme/study/study_typography.dart';

/// Learner-facing progress card for one CSP11 domain.
///
/// The widget is presentation-only. Progress is supplied by the existing
/// StudentDomainProgress model and is never fabricated here.
class DomainProgressCard extends StatelessWidget {
  final StudentDomainProgress domain;

  const DomainProgressCard({super.key, required this.domain});

  @override
  Widget build(BuildContext context) {
    final percentage = (domain.subtopicProgress * 100).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: StudyColors.surface,
        borderRadius: StudyRadius.large,
        border: Border.all(color: StudyColors.border),
        boxShadow: StudyShadows.soft,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: StudyColors.primaryLight,
              borderRadius: StudyRadius.medium,
            ),
            child: Text(
              domain.domainNumber.toString().padLeft(2, '0'),
              style: const TextStyle(
                color: StudyColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  domain.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: StudyTypography.cardTitle.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: domain.subtopicProgress,
                    minHeight: 6,
                    backgroundColor: StudyColors.surfaceSoft,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      StudyColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${domain.completedSubtopics}/${domain.subtopicCount} '
                  'subtopics',
                  style: StudyTypography.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$percentage%',
                style: StudyTypography.cardTitle.copyWith(
                  color: StudyColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                domain.completed
                    ? 'COMPLETED'
                    : domain.inProgress
                    ? 'IN PROGRESS'
                    : 'NOT STARTED',
                style: StudyTypography.eyebrow.copyWith(
                  color: domain.completed
                      ? const Color(0xFF1F8A4C)
                      : StudyColors.textSecondary,
                  fontSize: 7,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
