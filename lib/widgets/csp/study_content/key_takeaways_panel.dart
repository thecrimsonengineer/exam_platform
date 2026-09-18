import 'package:flutter/material.dart';

import 'package:exam_platform/theme/glass/student_glass.dart';

import '../../../theme/study/study_colors.dart';
import '../../../theme/study/study_radius.dart';
import '../../../theme/study/study_shadows.dart';
import '../../../theme/study/study_typography.dart';

class KeyTakeawaysPanel extends StatelessWidget {
  final List<String> takeaways;
  final String title;

  const KeyTakeawaysPanel({
    super.key,
    required this.takeaways,
    this.title = 'KEY TAKEAWAYS',
  });

  @override
  Widget build(BuildContext context) {
    if (takeaways.isEmpty) {
      return const SizedBox.shrink();
    }

    return StudentGlassSurface(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 14),
      padding: const EdgeInsets.all(18),
      borderRadius: StudyRadius.large,
      tint: StudyColors.surface.withValues(alpha: 0.56),
      borderColor: StudyColors.border.withValues(alpha: 0.72),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: StudyTypography.eyebrow.copyWith(
              color: StudyColors.primary,
              fontSize: 8,
            ),
          ),
          const SizedBox(height: 10),
          ...takeaways.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Icon(
                      Icons.circle,
                      size: 6,
                      color: StudyColors.primary,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      item,
                      style: StudyTypography.bodySecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
