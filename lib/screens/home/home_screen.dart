import 'package:flutter/material.dart';

import '../../app/app_colors.dart';
import '../../app/app_radius.dart';
import '../../app/app_spacing.dart';
import '../../app/app_text_styles.dart';

import '../../widgets/continue_learning_card.dart';
import '../../widgets/course_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  final String userName = 'Naveed';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(title: const Text('Exam Platform'), centerTitle: false),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.page),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Good Morning, $userName 👋', style: AppTextStyles.heading),

            const SizedBox(height: AppSpacing.sm),

            Text(
              'Continue your learning or start a new certification today.',
              style: AppTextStyles.body,
            ),

            const SizedBox(height: AppSpacing.xl),

            TextField(
              decoration: InputDecoration(
                hintText: 'Search certifications...',
                prefixIcon: const Icon(Icons.search),

                filled: true,
                fillColor: AppColors.surface,

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  borderSide: BorderSide.none,
                ),

                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  borderSide: BorderSide.none,
                ),

                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.section),

            Text('Continue Learning', style: AppTextStyles.title),

            const SizedBox(height: AppSpacing.md),

            ContinueLearningCard(
              course: 'CSP 11',
              subtitle: 'Certified Safety Professional',
              progress: 0.72,
              completedQuestions: 1332,
              totalQuestions: 1850,
              onPressed: () {},
            ),

            const SizedBox(height: AppSpacing.section),

            Text('Popular Certifications', style: AppTextStyles.title),

            const SizedBox(height: AppSpacing.md),

            CourseCard(
              title: 'CSP 11',
              subtitle: 'Certified Safety Professional',
              questions: 1850,
              progress: 0.72,
              icon: Icons.workspace_premium,
              onTap: () {},
            ),

            CourseCard(
              title: 'NEBOSH IG',
              subtitle: 'International General Certificate',
              questions: 1500,
              progress: 0.43,
              icon: Icons.public,
              onTap: () {},
            ),

            CourseCard(
              title: 'ASP',
              subtitle: 'Associate Safety Professional',
              questions: 1100,
              progress: 0.15,
              icon: Icons.shield_outlined,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}
