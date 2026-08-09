import 'package:flutter/material.dart';

import '../../app/app_colors.dart';
import '../../app/app_radius.dart';
import '../../app/app_spacing.dart';
import '../../app/app_text_styles.dart';

import '../../screens/courses/csp/domain_screen.dart';

class DomainListCard extends StatelessWidget {
  const DomainListCard({super.key});

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
            Text('CSP11 Examination Domains', style: AppTextStyles.title),

            const SizedBox(height: AppSpacing.sm),

            Text(
              'Select a domain to begin studying.',
              style: AppTextStyles.body,
            ),

            const SizedBox(height: AppSpacing.card),

            _domainTile(
              context,
              number: 1,
              title: 'Advanced Application of Safety Principles',
              weight: '25%',
            ),

            _domainTile(
              context,
              number: 2,
              title: 'Program Management',
              weight: '25%',
            ),

            _domainTile(
              context,
              number: 3,
              title: 'Risk Management',
              weight: '15%',
            ),

            _domainTile(
              context,
              number: 4,
              title: 'Emergency Management',
              weight: '9%',
            ),

            _domainTile(
              context,
              number: 5,
              title: 'Environmental Management',
              weight: '6%',
            ),

            _domainTile(
              context,
              number: 6,
              title: 'Occupational Health and Applied Science',
              weight: '10%',
            ),

            _domainTile(context, number: 7, title: 'Training', weight: '10%'),
          ],
        ),
      ),
    );
  }

  Widget _domainTile(
    BuildContext context, {
    required int number,
    required String title,
    required String weight,
  }) {
    return Card(
      elevation: 0,
      color: AppColors.background,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary,
          child: Text(
            '$number',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        title: Text(title, style: AppTextStyles.subtitle),

        subtitle: Text('Exam Weight: $weight', style: AppTextStyles.caption),

        trailing: const Icon(Icons.arrow_forward_ios, size: 16),

        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DomainScreen(
                domainNumber: number,
                domainTitle: title,
                examWeight: weight,
              ),
            ),
          );
        },
      ),
    );
  }
}
