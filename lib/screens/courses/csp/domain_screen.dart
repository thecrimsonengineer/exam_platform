import 'package:flutter/material.dart';

import '../../../data/csp11_blueprint.dart';
import '../../../app/app_colors.dart';
import '../../../app/app_radius.dart';
import '../../../app/app_spacing.dart';
import '../../../app/app_text_styles.dart';
import '../../../services/study_content_loader.dart';
import 'study_content_screen.dart';
import 'quiz/quiz_screen.dart';

class DomainScreen extends StatefulWidget {
  final int domainNumber;

  const DomainScreen({super.key, required this.domainNumber});

  @override
  State<DomainScreen> createState() => _DomainScreenState();
}

class _DomainScreenState extends State<DomainScreen> {
  final StudyContentLoader _loader = const StudyContentLoader();

  late Csp11Domain _domain;

  Future<List<dynamic>>? _contentFuture;

  @override
  void initState() {
    super.initState();

    _domain = csp11Domains.firstWhere(
      (domain) => domain.number == widget.domainNumber,
    );

    _contentFuture = _loadDomainContent();
  }

  Future<List<dynamic>> _loadDomainContent() async {
    final published = await _loader.loadPublishedContent();

    return published
        .where(
          (content) =>
              content.status.toLowerCase() == 'published' &&
              content.domainId ==
                  'domain_${widget.domainNumber.toString().padLeft(2, '0')}',
        )
        .toList();
  }

  void _openPracticeQuiz() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizScreen(domain: widget.domainNumber),
      ),
    );
  }

  void _openStudyContent({
    required String domainId,
    required String competencyId,
    required String title,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudyContentScreen(
          domainId: domainId,
          competencyId: competencyId,
          loadingTitle: title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.md,
                AppSpacing.page,
                AppSpacing.xl,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildHero(),
                  const SizedBox(height: AppSpacing.lg),
                  _buildQuickActions(),
                  const SizedBox(height: AppSpacing.lg),
                  _buildLearningAreas(),
                  const SizedBox(height: AppSpacing.lg),
                  _buildPracticeSection(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'CSP11 • Domain ${widget.domainNumber}',
        style: AppTextStyles.subtitle,
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.large),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.78),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'DOMAIN ${widget.domainNumber.toString().padLeft(2, '0')}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            _domain.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              height: 1.15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Build your understanding, track your progress, and practise the concepts that matter for the CSP examination.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              _heroMetric('${_domain.weightPercent}%', 'Exam weight'),
              const SizedBox(width: AppSpacing.xl),
              _heroMetric('0%', 'Completed'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroMetric(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.72),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _actionCard(
            icon: Icons.menu_book_rounded,
            title: 'Study',
            subtitle: 'Published content',
            onTap: _scrollToLearningAreas,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _actionCard(
            icon: Icons.quiz_rounded,
            title: 'Practice',
            subtitle: 'Domain questions',
            onTap: _openPracticeQuiz,
          ),
        ),
      ],
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.card),
      onTap: onTap,
      child: Card(
        elevation: 1,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.card),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.subtitle),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTextStyles.caption),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 15),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLearningAreas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Learning areas', style: AppTextStyles.title),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Explore the published study content for this domain.',
          style: AppTextStyles.body,
        ),
        const SizedBox(height: AppSpacing.md),
        FutureBuilder<List<dynamic>>(
          future: _contentFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _loadingCard();
            }

            if (snapshot.hasError) {
              return _messageCard(
                icon: Icons.cloud_off_rounded,
                title: 'Content unavailable',
                message:
                    'Published study content could not be loaded right now.',
              );
            }

            final content = snapshot.data ?? [];

            if (content.isEmpty) {
              return _messageCard(
                icon: Icons.auto_stories_outlined,
                title: 'Content is being prepared',
                message:
                    'Published learning content for this domain will appear here when it is available.',
              );
            }

            return Column(
              children: content.map<Widget>((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _contentCard(item),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _contentCard(dynamic content) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: () {
          _openStudyContent(
            domainId: content.domainId,
            competencyId: content.competencyId,
            title: content.title,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.card),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(content.title, style: AppTextStyles.subtitle),
                    const SizedBox(height: AppSpacing.xs),
                    Text('Learning area', style: AppTextStyles.caption),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPracticeSection() {
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                  ),
                  child: const Icon(
                    Icons.psychology_alt_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ready to practise?', style: AppTextStyles.subtitle),
                      const SizedBox(height: 3),
                      Text(
                        'Test your understanding across this domain.',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _openPracticeQuiz,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('START DOMAIN PRACTICE'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loadingCard() {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Row(
          children: [
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: AppSpacing.md),
            Text('Loading published content...', style: AppTextStyles.body),
          ],
        ),
      ),
    );
  }

  Widget _messageCard({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary, size: 30),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.subtitle),
                  const SizedBox(height: AppSpacing.xs),
                  Text(message, style: AppTextStyles.body),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _scrollToLearningAreas() {
    // The learning area is already immediately below the quick actions.
    // This action intentionally remains lightweight on mobile.
  }
}
