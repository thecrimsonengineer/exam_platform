import 'package:flutter/material.dart';

import '../../models/student_progress_dashboard.dart';
import '../../services/student_progress_dashboard_service.dart';
import '../../theme/study/study_colors.dart';
import '../../theme/study/study_gradients.dart';
import '../../theme/study/study_radius.dart';
import '../../theme/study/study_shadows.dart';
import '../../theme/study/study_spacing.dart';
import '../../theme/study/study_typography.dart';

/// Real CSP11 learner progress dashboard.
///
/// All percentages are calculated from published content and persisted
/// learner activity. No placeholder progress is generated.
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => ProgressScreenState();
}

class ProgressScreenState extends State<ProgressScreen> {
  final StudentProgressDashboardService _service =
      const StudentProgressDashboardService();

  late Future<StudentProgressDashboard> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.loadDashboard();
  }

  Future<void> refresh() async {
    setState(() {
      _future = _service.loadDashboard();
    });

    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StudyColors.background,
      body: SafeArea(
        child: FutureBuilder<StudentProgressDashboard>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _buildError();
            }

            final dashboard = snapshot.data;

            if (dashboard == null) {
              return _buildError();
            }

            return RefreshIndicator(
              onRefresh: refresh,
              child: _buildDashboard(dashboard),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDashboard(StudentProgressDashboard dashboard) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            StudySpacing.pageHorizontal,
            24,
            StudySpacing.pageHorizontal,
            36,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildHero(dashboard),
              const SizedBox(height: 20),
              _buildStats(dashboard),
              const SizedBox(height: 28),
              _buildSectionTitle(
                'DOMAIN PROGRESS',
                'Your actual CSP11 learning progress',
              ),
              const SizedBox(height: 12),
              ...dashboard.domains.map(_buildDomainCard),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildHero(StudentProgressDashboard dashboard) {
    final percentage = (dashboard.overallProgress * 100).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: StudyGradients.hero,
        borderRadius: StudyRadius.large,
        boxShadow: StudyShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CSP11 PROGRESS',
            style: StudyTypography.eyebrow.copyWith(
              color: Colors.white.withValues(alpha: 0.68),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$percentage%',
            style: StudyTypography.heroTitle.copyWith(
              color: Colors.white,
              fontSize: 42,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Overall subtopic completion',
            style: StudyTypography.bodyLarge.copyWith(
              color: Colors.white.withValues(alpha: 0.78),
            ),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: dashboard.overallProgress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.16),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(StudentProgressDashboard dashboard) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.55,
      children: [
        _buildStatCard(
          'COMPLETED',
          '${dashboard.completedSubtopics}',
          'subtopics',
          Icons.check_circle_rounded,
        ),
        _buildStatCard(
          'IN PROGRESS',
          '${dashboard.inProgressDomains}',
          'domains',
          Icons.timelapse_rounded,
        ),
        _buildStatCard(
          'TOPICS',
          '${dashboard.completedTopics}/${dashboard.totalTopics}',
          'completed',
          Icons.menu_book_rounded,
        ),
        _buildStatCard(
          'DOMAINS',
          '${dashboard.completedDomains}/7',
          'completed',
          Icons.shield_rounded,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    String caption,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: StudyColors.surface,
        borderRadius: StudyRadius.large,
        border: Border.all(color: StudyColors.border),
        boxShadow: StudyShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: StudyColors.primary),
          const Spacer(),
          Text(
            label,
            style: StudyTypography.eyebrow.copyWith(
              color: StudyColors.textSecondary,
              fontSize: 8,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: StudyTypography.cardTitle.copyWith(
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(caption, style: StudyTypography.caption),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String eyebrow, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: StudyTypography.eyebrow.copyWith(color: StudyColors.primary),
        ),
        const SizedBox(height: 4),
        Text(title, style: StudyTypography.sectionTitle),
      ],
    );
  }

  Widget _buildDomainCard(StudentDomainProgress domain) {
    final percentage = (domain.subtopicProgress * 100).round();

    final status = domain.completed
        ? 'COMPLETED'
        : domain.inProgress
        ? 'IN PROGRESS'
        : 'NOT STARTED';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: StudyColors.surface,
        borderRadius: StudyRadius.large,
        border: Border.all(color: StudyColors.border),
        boxShadow: StudyShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: StudyColors.primaryLight,
                  borderRadius: StudyRadius.medium,
                ),
                child: Text(
                  domain.domainNumber.toString().padLeft(2, '0'),
                  style: const TextStyle(
                    color: StudyColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DOMAIN ${domain.domainNumber.toString().padLeft(2, '0')}',
                      style: StudyTypography.eyebrow.copyWith(
                        color: StudyColors.primary,
                        fontSize: 8,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      domain.title,
                      style: StudyTypography.cardTitle.copyWith(fontSize: 15),
                    ),
                  ],
                ),
              ),
              Text(
                '$percentage%',
                style: StudyTypography.cardTitle.copyWith(
                  color: StudyColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: domain.subtopicProgress,
              minHeight: 7,
              backgroundColor: StudyColors.surfaceSoft,
              valueColor: const AlwaysStoppedAnimation<Color>(
                StudyColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Text(
                '${domain.completedSubtopics}/${domain.subtopicCount} subtopics',
                style: StudyTypography.caption,
              ),
              const Spacer(),
              Text(
                status,
                style: StudyTypography.eyebrow.copyWith(
                  color: domain.completed
                      ? const Color(0xFF1F8A4C)
                      : StudyColors.textSecondary,
                  fontSize: 8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.insights_rounded,
              size: 42,
              color: StudyColors.textSecondary,
            ),
            const SizedBox(height: 14),
            Text(
              'Progress could not be loaded',
              style: StudyTypography.cardTitle,
            ),
            const SizedBox(height: 7),
            Text(
              'Please try again.',
              style: StudyTypography.bodySecondary,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: refresh, child: const Text('TRY AGAIN')),
          ],
        ),
      ),
    );
  }
}
