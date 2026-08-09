import 'package:flutter/material.dart';

import '../../app/app_colors.dart';
import '../../app/app_radius.dart';
import '../../app/app_spacing.dart';
import '../../app/app_text_styles.dart';

import '../../widgets/featured_course_card.dart';
import 'csp/csp_overview_screen.dart';

class CoursesScreen extends StatelessWidget {
  const CoursesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(title: const Text("Courses")),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.page),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Choose your certification", style: AppTextStyles.heading),

            const SizedBox(height: AppSpacing.sm),

            Text(
              "Begin learning with industry-recognized certifications.",
              style: AppTextStyles.body,
            ),

            const SizedBox(height: AppSpacing.xl),

            TextField(
              decoration: InputDecoration(
                hintText: "Search courses...",
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

            FeaturedCourseCard(
              title: "CSP 11",
              subtitle: "Certified Safety Professional",
              questions: 1850,
              domains: 7,
              progress: 0.72,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CSPOverviewScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: AppSpacing.section),

            Text("Coming Soon", style: AppTextStyles.title),

            const SizedBox(height: AppSpacing.md),

            _comingSoon("ASP"),
            _comingSoon("NEBOSH IDIP"),
            _comingSoon("NEBOSH IGC"),
            _comingSoon("CRSP"),
            _comingSoon("IOSH"),
            _comingSoon("OPITO"),
          ],
        ),
      ),
    );
  }

  Widget _comingSoon(String title) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),

      child: ListTile(
        leading: const Icon(Icons.lock_outline),
        title: Text(title),
        subtitle: const Text("Coming Soon"),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}
