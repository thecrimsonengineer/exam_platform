import 'package:flutter/material.dart';

import '../../app/app_colors.dart';
import '../../app/app_radius.dart';
import '../../app/app_spacing.dart';
import '../../app/app_text_styles.dart';

class PerformanceSummaryCard extends StatelessWidget {
  const PerformanceSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),

      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.card),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Text("Performance Summary", style: AppTextStyles.title),

            const SizedBox(height: AppSpacing.card),

            Row(
              children: [
                Expanded(child: _tile("72%", "Overall", Icons.trending_up)),

                Expanded(child: _tile("1332", "Questions", Icons.quiz)),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            Row(
              children: [
                Expanded(child: _tile("81%", "Average", Icons.star)),

                Expanded(
                  child: _tile("18", "Day Streak", Icons.local_fire_department),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(String value, String label, IconData icon) {
    return Container(
      margin: const EdgeInsets.all(6),

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: AppColors.background,

        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),

      child: Column(
        children: [
          Icon(icon, color: AppColors.primary),

          const SizedBox(height: 10),

          Text(value, style: AppTextStyles.statistic),

          const SizedBox(height: 6),

          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}
