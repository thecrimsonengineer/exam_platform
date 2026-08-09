import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../app/app_text_styles.dart';
import '../app/app_spacing.dart';
import '../app/app_radius.dart';

class CourseCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final int questions;
  final double progress;
  final IconData icon;
  final VoidCallback? onTap;

  const CourseCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.questions,
    required this.progress,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.large),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Icon(icon, color: AppColors.primary, size: 28),
                  ),

                  const SizedBox(width: AppSpacing.md),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: AppTextStyles.title),

                        const SizedBox(height: 4),

                        Text(subtitle, style: AppTextStyles.body),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              LinearProgressIndicator(
                value: progress,
                borderRadius: BorderRadius.circular(10),
              ),

              const SizedBox(height: AppSpacing.sm),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("$questions Questions", style: AppTextStyles.caption),

                  Text(
                    "${(progress * 100).round()}%",
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
