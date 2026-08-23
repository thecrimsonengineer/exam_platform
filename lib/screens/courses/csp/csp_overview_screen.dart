import 'package:flutter/material.dart';

import '../../../app/app_spacing.dart';

import '../../../widgets/csp/hero_card.dart';
import '../../../widgets/csp/performance_summary_card.dart';
import '../../../widgets/csp/domain_list_card.dart';
import '../../../widgets/csp/student_quiz_builder.dart';

import '../../home/home_screen.dart';

class CSPOverviewScreen extends StatelessWidget {
  const CSPOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CSP 11'),
        leading: IconButton(
          tooltip: 'Home',
          icon: const Icon(Icons.home_rounded),
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
            );
          },
        ),
      ),
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
