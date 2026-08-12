import 'package:flutter/material.dart';

import '../../../app/app_spacing.dart';

import '../../../widgets/csp/hero_card.dart';
import '../../../widgets/csp/performance_summary_card.dart';
import '../../../widgets/csp/domain_list_card.dart';
import '../../../widgets/csp/student_quiz_builder.dart';

class CSPOverviewScreen extends StatelessWidget {
  const CSPOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CSP 11')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.page),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            HeroCard(),

            SizedBox(height: AppSpacing.section),

            PerformanceSummaryCard(),

            SizedBox(height: AppSpacing.section),

            StudentQuizBuilder(),

            SizedBox(height: AppSpacing.section),

            DomainListCard(),
          ],
        ),
      ),
    );
  }
}
