import 'package:flutter/material.dart';

import '../../app/app_colors.dart';
import '../../app/app_radius.dart';
import '../../app/app_spacing.dart';
import '../../app/app_text_styles.dart';

class StudyResourcesCard extends StatelessWidget {
  const StudyResourcesCard({super.key});

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
            Text("Study Resources", style: AppTextStyles.title),

            const SizedBox(height: AppSpacing.card),

            _resourceTile(
              icon: Icons.menu_book,
              title: "Study Notes",
              subtitle: "Chapter-wise learning material",
            ),

            _resourceTile(
              icon: Icons.psychology,
              title: "Flashcards",
              subtitle: "Quick concept revision",
            ),

            _resourceTile(
              icon: Icons.calculate,
              title: "Formula Sheet",
              subtitle: "Important equations & formulas",
            ),

            _resourceTile(
              icon: Icons.library_books,
              title: "Reference Books",
              subtitle: "Recommended reading",
            ),
          ],
        ),
      ),
    );
  }

  Widget _resourceTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
        child: Icon(icon, color: AppColors.primary),
      ),
      title: Text(title, style: AppTextStyles.subtitle),
      subtitle: Text(subtitle, style: AppTextStyles.caption),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {},
    );
  }
}
