import 'package:flutter/material.dart';

import '../../app/app_colors.dart';
import '../../app/app_radius.dart';
import '../../app/app_spacing.dart';
import '../../app/app_text_styles.dart';
import '../../data/csp11_blueprint.dart';

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
            ...csp11Domains.map((domain) => _domainTile(context, domain)),
          ],
        ),
      ),
    );
  }

  Widget _domainTile(BuildContext context, Csp11Domain domain) {
    return Card(
      elevation: 0,
      color: AppColors.background,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary,
          child: Text(
            '${domain.number}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(domain.title, style: AppTextStyles.subtitle),
        subtitle: Text(
          'Exam Weight: ${domain.weightPercent}%',
          style: AppTextStyles.caption,
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DomainScreen(domainNumber: domain.number),
            ),
          );
        },
      ),
    );
  }
}
