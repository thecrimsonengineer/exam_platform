import 'package:flutter/material.dart';

import '../../app/app_colors.dart';
import '../../app/app_radius.dart';
import '../../app/app_spacing.dart';
import '../../app/app_text_styles.dart';

class HeroCard extends StatelessWidget {
  const HeroCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(AppSpacing.card),

      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),

        borderRadius: BorderRadius.circular(AppRadius.card),

        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          /// Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),

                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.20),
                  shape: BoxShape.circle,
                ),

                child: const Icon(
                  Icons.workspace_premium,
                  color: Colors.amber,
                  size: 34,
                ),
              ),

              const SizedBox(width: AppSpacing.md),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      "CSP 11",
                      style: AppTextStyles.heading.copyWith(
                        color: Colors.white,
                      ),
                    ),

                    Text(
                      "Certified Safety Professional",
                      style: AppTextStyles.body.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),

              const Icon(Icons.verified, color: Colors.amber),
            ],
          ),

          const SizedBox(height: AppSpacing.card),

          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.medium),

            child: LinearProgressIndicator(
              value: 0.72,
              minHeight: 10,

              backgroundColor: Colors.white24,

              valueColor: const AlwaysStoppedAnimation(Colors.amber),
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          Text(
            "1332 / 1850 Questions Completed",
            style: AppTextStyles.caption.copyWith(color: Colors.white),
          ),

          const SizedBox(height: AppSpacing.card),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,

            children: [
              _stat(Icons.menu_book, "7 Domains"),

              _stat(Icons.local_fire_department, "18 Day Streak"),

              _stat(Icons.star, "81%"),
            ],
          ),

          const SizedBox(height: AppSpacing.card),

          SizedBox(
            width: double.infinity,

            child: FilledButton.icon(
              onPressed: () {},

              icon: const Icon(Icons.play_arrow),

              label: const Text("Continue Learning"),

              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 18),

        const SizedBox(width: 6),

        Text(text, style: const TextStyle(color: Colors.white)),
      ],
    );
  }
}
