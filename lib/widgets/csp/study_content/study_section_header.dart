import 'package:flutter/material.dart';

import '../../../theme/study/study_colors.dart';
import '../../../theme/study/study_radius.dart';
import '../../../theme/study/study_typography.dart';

class StudySectionHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String? description;

  const StudySectionHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: StudyColors.primaryLight,
              borderRadius: StudyRadius.small,
            ),
            child: Text(
              eyebrow.toUpperCase(),
              style: StudyTypography.eyebrow.copyWith(
                color: StudyColors.primary,
                fontSize: 8,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 9),
          Text(
            title,
            style: StudyTypography.sectionTitle,
          ),
          if (description != null &&
              description!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              description!,
              style: StudyTypography.bodySecondary,
            ),
          ],
        ],
      ),
    );
  }
}
