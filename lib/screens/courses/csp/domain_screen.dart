import 'package:exam_platform/features/learning_twin/integration/learning_twin_domain_guidance.dart';
import 'package:flutter/material.dart';

import 'package:exam_platform/theme/glass/student_glass.dart';

import '../../../data/csp11_blueprint.dart';
import '../../../app/app_colors.dart';
import '../../../app/app_radius.dart';
import '../../../app/app_spacing.dart';
import '../../../app/app_text_styles.dart';
import 'study_content_screen.dart';
import 'quiz/quiz_screen.dart';

class DomainScreen extends StatefulWidget {
  final int domainNumber;

  const DomainScreen({super.key, required this.domainNumber});

  @override
  State<DomainScreen> createState() => _DomainScreenState();
}

class _DomainScreenState extends State<DomainScreen> {
  late Csp11Domain _domain;

  @override
  void initState() {
    super.initState();

    _domain = csp11Domains.firstWhere(
      (domain) => domain.number == widget.domainNumber,
    );

  }

  void _openPracticeQuiz() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizScreen(domain: widget.domainNumber),
      ),
    );
  }

  void _openCompetency({
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
          domainTitle: _domain.title,
          loadingTitle: title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StudentGlassScaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
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
                  const SizedBox(height: 16),
                  LearningTwinDomainGuidance(domainId: _domain.id),
                  const SizedBox(height: AppSpacing.xl),
                  _buildQuickActions(),
                  const SizedBox(height: AppSpacing.xl),
                  _buildLearningAreas(),
                  const SizedBox(height: AppSpacing.xl),
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
      scrolledUnderElevation: 0,
      backgroundColor: AppColors.background.withValues(alpha: 0.96),
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        tooltip: 'Back',
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.pop(context),
      ),
      titleSpacing: 4,
      title: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.10),
              ),
            ),
            child: const Icon(
              Icons.shield_rounded,
              color: AppColors.primary,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'CSP11',
            style: AppTextStyles.subtitle.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(width: 7),
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.45),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            'Domain ${widget.domainNumber}',
            style: AppTextStyles.caption.copyWith(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    final domainNumber = widget.domainNumber.toString().padLeft(2, '0');

    return StudentGlassSurface(
      constraints: const BoxConstraints(minHeight: 340),
      padding: const EdgeInsets.all(AppSpacing.xl),
      borderRadius: BorderRadius.circular(AppRadius.large),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF102A56).withValues(alpha: 0.82),
          const Color(0xFF1E4C91).withValues(alpha: 0.76),
          const Color(0xFF5B36A8).withValues(alpha: 0.72),
        ],
        stops: const [0.0, 0.58, 1.0],
      ),
      borderColor: Colors.white.withValues(alpha: 0.14),
      shadowColor: AppColors.primary.withValues(alpha: 0.18),
      child: Stack(
        children: [
          Positioned(
            top: -55,
            right: -35,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.07),
                  width: 22,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -75,
            right: 55,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.025),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _heroPill(
                    icon: Icons.verified_rounded,
                    text: 'DOMAIN $domainNumber',
                  ),
                  _heroPill(
                    icon: Icons.trending_up_rounded,
                    text: '${_domain.weightPercent}% WEIGHT',
                    accent: Colors.amber.shade300,
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                _domain.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  height: 1.08,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 13),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Text(
                  'Build strong exam readiness through focused learning, deliberate practice, and measurable progress across this CSP11 domain.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 14.5,
                    height: 1.55,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 560;

                  if (compact) {
                    return Wrap(
                      spacing: 24,
                      runSpacing: 16,
                      children: [
                        _heroMetric(
                          value: '${_domain.weightPercent}%',
                          label: 'Exam Weight',
                          icon: Icons.assessment_rounded,
                        ),
                        _heroMetric(
                          value: 'Ready',
                          label: 'Learning Path',
                          icon: Icons.route_rounded,
                        ),
                        _heroMetric(
                          value: 'CSP11',
                          label: 'Exam Framework',
                          icon: Icons.workspace_premium_rounded,
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      _heroMetric(
                        value: '${_domain.weightPercent}%',
                        label: 'Exam Weight',
                        icon: Icons.assessment_rounded,
                      ),
                      _heroDivider(),
                      _heroMetric(
                        value: 'Ready',
                        label: 'Learning Path',
                        icon: Icons.route_rounded,
                      ),
                      _heroDivider(),
                      _heroMetric(
                        value: 'CSP11',
                        label: 'Exam Framework',
                        icon: Icons.workspace_premium_rounded,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroPill({
    required IconData icon,
    required String text,
    Color? accent,
  }) {
    final iconColor = accent ?? Colors.white.withValues(alpha: 0.92);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 14),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: accent ?? Colors.white.withValues(alpha: 0.94),
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.9,
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroMetric({
    required String value,
    required String label,
    required IconData icon,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: Icon(
            icon,
            color: Colors.white.withValues(alpha: 0.88),
            size: 17,
          ),
        ),
        const SizedBox(width: 9),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.60),
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _heroDivider() {
    return Container(
      width: 1,
      height: 38,
      margin: const EdgeInsets.symmetric(horizontal: 28),
      color: Colors.white.withValues(alpha: 0.13),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          eyebrow: 'YOUR NEXT MOVE',
          title: 'Continue Learning',
          subtitle: 'Choose how you want to progress through this domain.',
        ),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 680;

            final studyCard = _premiumActionCard(
              icon: Icons.menu_book_rounded,
              title: 'Study Materials',
              subtitle: 'LEARN',
              description:
                  'Explore published competencies and continue through the learning path.',
              color: const Color(0xFF2563EB),
              onTap: _scrollToLearningAreas,
            );

            final quizCard = _premiumActionCard(
              icon: Icons.quiz_rounded,
              title: 'Practice Quiz',
              subtitle: 'PRACTICE',
              description:
                  'Challenge your knowledge with domain-specific exam questions.',
              color: const Color(0xFF7C3AED),
              onTap: _openPracticeQuiz,
            );

            if (compact) {
              return Column(
                children: [
                  studyCard,
                  const SizedBox(height: AppSpacing.md),
                  quizCard,
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: studyCard),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: quizCard),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _sectionHeader({
    required String eyebrow,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow,
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: AppTextStyles.title.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTextStyles.body.copyWith(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _premiumActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: StudentGlassSurface(
          borderRadius: BorderRadius.circular(AppRadius.card),
          tint: Colors.white.withValues(alpha: 0.50),
          borderColor: color.withValues(alpha: 0.16),
          shadowColor: Colors.black.withValues(alpha: 0.07),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.card),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.withValues(alpha: 0.16),
                        color.withValues(alpha: 0.06),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color.withValues(alpha: 0.12)),
                  ),
                  child: Icon(icon, color: color, size: 25),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: color,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        title,
                        style: AppTextStyles.subtitle.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: color,
                    size: 17,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLearningAreas() {
    final competencies = _domain.competencies;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          eyebrow: 'LEARNING PATH',
          title: 'Learning Areas',
          subtitle: 'Choose a competency to open its published learning path.',
        ),
        const SizedBox(height: AppSpacing.md),
        Column(
          children: List.generate(
            competencies.length,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _premiumContentCard(competencies[index], index),
            ),
          ),
        ),
      ],
    );
  }

  Widget _premiumContentCard(Csp11Competency content, int index) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: () {
          _openCompetency(
            domainId: _domain.id,
            competencyId: content.id,
            title: 'Competency ${content.number}',
          );
        },
        child: StudentGlassSurface(
          borderRadius: BorderRadius.circular(AppRadius.card),
          tint: Colors.white.withValues(alpha: 0.50),
          borderColor: AppColors.primary.withValues(alpha: 0.12),
          shadowColor: Colors.black.withValues(alpha: 0.06),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.card),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary.withValues(alpha: 0.12),
                        AppColors.primary.withValues(alpha: 0.045),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.10),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}'.padLeft(2, '0'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.card),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        content.statement,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.subtitle.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: 0.07,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'COMPETENCY',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.7,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Published content',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPracticeSection() {
    return StudentGlassSurface(
      padding: const EdgeInsets.all(AppSpacing.xl),
      borderRadius: BorderRadius.circular(AppRadius.large),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.primary.withValues(alpha: 0.10),
          const Color(0xFF7C3AED).withValues(alpha: 0.06),
        ],
      ),
      borderColor: AppColors.primary.withValues(alpha: 0.14),
      shadowColor: AppColors.primary.withValues(alpha: 0.08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.10),
                  ),
                ),
                child: const Icon(
                  Icons.psychology_alt_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ready to Practice?',
                      style: AppTextStyles.title.copyWith(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Test your understanding with domain-specific questions designed to strengthen exam readiness.',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13.5,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton.icon(
              onPressed: _openPracticeQuiz,
              icon: const Icon(Icons.play_arrow_rounded, size: 22),
              label: const Text(
                'START PRACTICE QUIZ',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.7,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                ),
                elevation: 5,
                shadowColor: AppColors.primary.withValues(alpha: 0.28),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _premiumLoadingCard() {
    return StudentGlassSurface(
      padding: const EdgeInsets.all(AppSpacing.xl),
      borderRadius: BorderRadius.circular(AppRadius.card),
      tint: Colors.white.withValues(alpha: 0.50),
      borderColor: AppColors.primary.withValues(alpha: 0.12),
      child: Row(
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Loading Content',
                  style: AppTextStyles.subtitle.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Fetching published learning areas...',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _premiumMessageCard({
    required IconData icon,
    required String title,
    required String message,
    required Color color,
  }) {
    return StudentGlassSurface(
      padding: const EdgeInsets.all(AppSpacing.xl),
      borderRadius: BorderRadius.circular(AppRadius.card),
      tint: Colors.white.withValues(alpha: 0.50),
      borderColor: color.withValues(alpha: 0.18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 23),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.subtitle.copyWith(
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _scrollToLearningAreas() {
    // Learning materials are immediately below the quick actions.
    // Keep this lightweight so it behaves naturally on mobile.
  }
}
