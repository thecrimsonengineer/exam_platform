import 'package:flutter/material.dart';

import '../../../theme/study/study_colors.dart';
import '../../../theme/study/study_radius.dart';
import '../../../theme/study/study_typography.dart';

enum StudyCalloutType {
  keyPoint,
  example,
  examTip,
  important,
  caution,
}

class StudyContentCallout extends StatelessWidget {
  final StudyCalloutType type;
  final String title;
  final String content;

  const StudyContentCallout({
    super.key,
    required this.type,
    required this.title,
    required this.content,
  });

  IconData get _icon {
    switch (type) {
      case StudyCalloutType.keyPoint:
        return Icons.lightbulb_outline_rounded;
      case StudyCalloutType.example:
        return Icons.auto_awesome_outlined;
      case StudyCalloutType.examTip:
        return Icons.school_outlined;
      case StudyCalloutType.important:
        return Icons.priority_high_rounded;
      case StudyCalloutType.caution:
        return Icons.warning_amber_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: StudyColors.surface,
        borderRadius: StudyRadius.medium,
        border: Border.all(color: StudyColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _icon,
            color: StudyColors.primary,
            size: 21,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: StudyTypography.cardTitle.copyWith(
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  content,
                  style: StudyTypography.bodySecondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
