import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_radius.dart';
import '../../../app/app_spacing.dart';
import '../../../app/app_text_styles.dart';

import 'quiz/quiz_screen.dart';
import 'study_notes_screen.dart';

class DomainScreen extends StatelessWidget {
  final int domainNumber;
  final String domainTitle;
  final String examWeight;

  const DomainScreen({
    super.key,
    required this.domainNumber,
    required this.domainTitle,
    required this.examWeight,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('Domain $domainNumber')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.page),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(domainTitle, style: AppTextStyles.heading),

            const SizedBox(height: AppSpacing.sm),

            Chip(label: Text('Exam Weight: $examWeight')),

            const SizedBox(height: AppSpacing.section),

            _menuCard(
              context,
              icon: Icons.menu_book,
              title: 'Study Notes',
              subtitle: domainNumber == 7
                  ? 'Read chapter-wise notes'
                  : 'Coming soon',
              onTap: () {
                if (domainNumber != 7) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Study Notes for this domain are coming soon.',
                      ),
                    ),
                  );
                  return;
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => StudyNotesScreen()),
                );
              },
            ),

            _menuCard(
              context,
              icon: Icons.psychology,
              title: 'Flashcards',
              subtitle: 'Review key concepts quickly',
            ),

            _menuCard(
              context,
              icon: Icons.quiz,
              title: 'Practice Quiz',
              subtitle: 'Practice domain questions',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => QuizScreen(domain: domainNumber),
                  ),
                );
              },
            ),

            _menuCard(
              context,
              icon: Icons.bookmark,
              title: 'Bookmarked Questions',
              subtitle: 'Review saved questions',
            ),

            _menuCard(
              context,
              icon: Icons.calculate,
              title: 'Formula Sheet',
              subtitle: 'Important equations and formulas',
            ),

            _menuCard(
              context,
              icon: Icons.library_books,
              title: 'Reference Books',
              subtitle: 'Recommended reading',
            ),

            _menuCard(
              context,
              icon: Icons.bar_chart,
              title: 'Statistics',
              subtitle: 'View your performance',
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(title, style: AppTextStyles.title),
        subtitle: Text(subtitle, style: AppTextStyles.caption),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
