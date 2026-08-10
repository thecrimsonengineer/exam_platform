import 'package:flutter/material.dart';

import '../../../models/study_content.dart';
import '../../../theme/study/study_colors.dart';
import '../../../theme/study/study_gradients.dart';
import '../../../theme/study/study_icons.dart';
import '../../../theme/study/study_radius.dart';
import '../../../theme/study/study_shadows.dart';
import '../../../theme/study/study_spacing.dart';
import '../../../theme/study/study_typography.dart';
import 'study_content_navigation.dart';
import 'study_subtopic_anchor.dart';
import 'study_subtopic_renderer.dart';

/// Premium student-facing renderer for a complete CSP competency.
///
/// Includes:
/// - Premium competency hero
/// - Study overview
/// - Subtopic sections
/// - Real subtopic navigation
/// - Study progress indicator
/// - Previous / next navigation
class StudyContentRenderer extends StatefulWidget {
  final StudyContent content;

  const StudyContentRenderer({super.key, required this.content});

  @override
  State<StudyContentRenderer> createState() => _StudyContentRendererState();
}

class _StudyContentRendererState extends State<StudyContentRenderer> {
  late final ScrollController _scrollController;

  late List<GlobalKey> _subtopicKeys;

  int _currentSubtopic = 0;

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController();

    _subtopicKeys = List.generate(
      widget.content.subtopics.length,
      (_) => GlobalKey(),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.content;
    final domain = _getDomainNumber(content.domainId);

    final totalSubtopics = content.subtopics.length;

    final progress = totalSubtopics == 0
        ? 0.0
        : (_currentSubtopic + 1) / totalSubtopics;

    final hasPrevious = _currentSubtopic > 0;

    final hasNext = totalSubtopics > 0 && _currentSubtopic < totalSubtopics - 1;

    return Container(
      color: StudyColors.background,
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final isDesktop = constraints.maxWidth >= 900;

                return CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    SliverToBoxAdapter(
                      child: _buildHero(
                        context,
                        domain: domain,
                        isDesktop: isDesktop,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _buildContentArea(
                        context,
                        domain: domain,
                        isDesktop: isDesktop,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // ==================================================
          // STICKY STUDY NAVIGATION
          // ==================================================
          StudyContentNavigation(
            progress: progress,
            previousLabel: hasPrevious ? 'Previous Subtopic' : 'Previous',
            nextLabel: hasNext ? 'Next Subtopic' : 'Complete',
            onPrevious: hasPrevious ? _goPrevious : null,
            onNext: hasNext ? _goNext : null,
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // NAVIGATION
  // ==========================================================

  void _goPrevious() {
    if (_currentSubtopic <= 0) {
      return;
    }

    setState(() {
      _currentSubtopic--;
    });

    _scrollToSubtopic();
  }

  void _goNext() {
    if (_currentSubtopic >= widget.content.subtopics.length - 1) {
      return;
    }

    setState(() {
      _currentSubtopic++;
    });

    _scrollToSubtopic();
  }

  void _scrollToSubtopic() {
    if (_currentSubtopic < 0 || _currentSubtopic >= _subtopicKeys.length) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final targetContext = _subtopicKeys[_currentSubtopic].currentContext;

      if (targetContext == null) {
        return;
      }

      Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        alignment: 0.05,
      );
    });
  }

  // ==========================================================
  // HERO
  // ==========================================================

  Widget _buildHero(
    BuildContext context, {
    required int domain,
    required bool isDesktop,
  }) {
    final title = widget.content.title.trim();

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: StudyGradients.hero),
      child: Stack(
        children: [
          Positioned(
            right: -80,
            top: -100,
            child: _buildHeroOrb(size: 260, opacity: 0.07),
          ),
          Positioned(
            right: 90,
            bottom: -140,
            child: _buildHeroOrb(size: 220, opacity: 0.05),
          ),
          SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: StudySpacing.maxContentWidth,
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    isDesktop
                        ? StudySpacing.pageHorizontalDesktop
                        : StudySpacing.pageHorizontal,
                    isDesktop ? 36 : 28,
                    isDesktop
                        ? StudySpacing.pageHorizontalDesktop
                        : StudySpacing.pageHorizontal,
                    isDesktop ? 40 : 32,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeroBreadcrumb(domain),
                      const SizedBox(height: 26),
                      _buildDomainBadge(domain),
                      const SizedBox(height: 14),
                      Text(
                        title.isEmpty ? 'Training' : title,
                        style: StudyTypography.heroTitle.copyWith(
                          color: Colors.white,
                          fontSize: isDesktop ? 40 : 32,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Competency '
                        '${widget.content.competencyNumber}',
                        style: StudyTypography.bodyLarge.copyWith(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 28),
                      _buildHeroStats(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBreadcrumb(int domain) {
    return Row(
      children: [
        const Icon(StudyIcons.back, size: 18, color: Colors.white),
        const SizedBox(width: 8),
        Text(
          'TRAINING',
          style: StudyTypography.eyebrow.copyWith(
            color: Colors.white.withValues(alpha: 0.82),
          ),
        ),
        const SizedBox(width: 10),
        Icon(
          StudyIcons.next,
          size: 17,
          color: Colors.white.withValues(alpha: 0.45),
        ),
        const SizedBox(width: 10),
        Text(
          'DOMAIN '
          '${domain.toString().padLeft(2, '0')}',
          style: StudyTypography.eyebrow.copyWith(
            color: Colors.white.withValues(alpha: 0.62),
          ),
        ),
      ],
    );
  }

  Widget _buildDomainBadge(int domain) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: StudyRadius.pillRadius,
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Text(
        'CSP11 • DOMAIN '
        '${domain.toString().padLeft(2, '0')}',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildHeroStats() {
    final subtopicCount = widget.content.subtopics.length;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildHeroStat(
          icon: StudyIcons.subtopic,
          label: 'SUBTOPICS',
          value: '$subtopicCount',
        ),
        _buildHeroStat(
          icon: StudyIcons.book,
          label: 'STUDY CONTENT',
          value: 'Ready',
        ),
        _buildHeroStat(
          icon: StudyIcons.progress,
          label: 'FOCUS',
          value: 'Exam',
        ),
      ],
    );
  }

  Widget _buildHeroStat({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        borderRadius: StudyRadius.medium,
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 19, color: Colors.white.withValues(alpha: 0.88)),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.9,
                  color: Colors.white.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroOrb({required double size, required double opacity}) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: opacity),
        ),
      ),
    );
  }

  // ==========================================================
  // CONTENT AREA
  // ==========================================================

  Widget _buildContentArea(
    BuildContext context, {
    required int domain,
    required bool isDesktop,
  }) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: StudySpacing.maxContentWidth,
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            isDesktop
                ? StudySpacing.pageHorizontalDesktop
                : StudySpacing.pageHorizontal,
            28,
            isDesktop
                ? StudySpacing.pageHorizontalDesktop
                : StudySpacing.pageHorizontal,
            80,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOverviewCard(),
              const SizedBox(height: 28),
              if (widget.content.subtopics.isEmpty)
                _buildNoContentMessage()
              else
                ...widget.content.subtopics.asMap().entries.map((entry) {
                  final index = entry.key;
                  final subtopic = entry.value;

                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index == widget.content.subtopics.length - 1
                          ? 0
                          : StudySpacing.sectionGap,
                    ),
                    child: StudySubtopicAnchor(
                      anchorKey: _subtopicKeys[index],
                      child: _buildSubtopicSection(
                        context,
                        subtopic: subtopic,
                        domain: domain,
                        index: index,
                        isDesktop: isDesktop,
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // OVERVIEW CARD
  // ==========================================================

  Widget _buildOverviewCard() {
    final subtopicCount = widget.content.subtopics.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(StudySpacing.cardPaddingLarge),
      decoration: BoxDecoration(
        color: StudyColors.surface,
        borderRadius: StudyRadius.large,
        border: Border.all(color: StudyColors.border),
        boxShadow: StudyShadows.soft,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 650;

          final progressContent = Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: StudyColors.primaryLight,
                  borderRadius: StudyRadius.medium,
                ),
                child: const Icon(
                  StudyIcons.study,
                  color: StudyColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'YOUR STUDY PATH',
                      style: StudyTypography.eyebrow.copyWith(
                        color: StudyColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$subtopicCount '
                      '${subtopicCount == 1 ? 'subtopic' : 'subtopics'} '
                      'available',
                      style: StudyTypography.bodySecondary,
                    ),
                  ],
                ),
              ),
            ],
          );

          final focusContent = Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: StudyColors.examTipLight,
                  borderRadius: StudyRadius.medium,
                ),
                child: const Icon(
                  StudyIcons.examTip,
                  color: StudyColors.examTip,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('EXAM FOCUS', style: StudyTypography.eyebrow),
                    SizedBox(height: 4),
                    Text(
                      'Study the concepts, then test your understanding.',
                      style: StudyTypography.bodySecondary,
                    ),
                  ],
                ),
              ),
            ],
          );

          if (compact) {
            return Column(
              children: [
                progressContent,
                const SizedBox(height: 18),
                const Divider(height: 1),
                const SizedBox(height: 18),
                focusContent,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: progressContent),
              Container(width: 1, height: 48, color: StudyColors.border),
              const SizedBox(width: 24),
              Expanded(child: focusContent),
            ],
          );
        },
      ),
    );
  }

  // ==========================================================
  // SUBTOPIC SECTION
  // ==========================================================

  Widget _buildSubtopicSection(
    BuildContext context, {
    required StudySubtopic subtopic,
    required int domain,
    required int index,
    required bool isDesktop,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubtopicHeader(subtopic, index),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: StudyColors.surface,
            borderRadius: StudyRadius.large,
            border: Border.all(color: StudyColors.border),
            boxShadow: StudyShadows.soft,
          ),
          child: ClipRRect(
            borderRadius: StudyRadius.large,
            child: Padding(
              padding: EdgeInsets.all(isDesktop ? 28 : 20),
              child: StudySubtopicRenderer(subtopic: subtopic, domain: domain),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubtopicHeader(StudySubtopic subtopic, int index) {
    final title = subtopic.title.trim();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: StudyGradients.heroSoft,
            borderRadius: StudyRadius.medium,
            boxShadow: StudyShadows.soft,
          ),
          child: Text(
            '${index + 1}'.padLeft(2, '0'),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SUBTOPIC ${index + 1}',
                style: StudyTypography.eyebrow.copyWith(
                  color: StudyColors.primary,
                ),
              ),
              if (title.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(title, style: StudyTypography.sectionTitle),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // EMPTY STATE
  // ==========================================================

  Widget _buildNoContentMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(StudySpacing.cardPaddingLarge),
      decoration: BoxDecoration(
        color: StudyColors.surface,
        borderRadius: StudyRadius.large,
        border: Border.all(color: StudyColors.border),
        boxShadow: StudyShadows.soft,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: StudyColors.surfaceSoft,
              borderRadius: StudyRadius.medium,
            ),
            child: const Icon(
              StudyIcons.book,
              color: StudyColors.textSecondary,
              size: 21,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Content coming soon', style: StudyTypography.cardTitle),
                SizedBox(height: 5),
                Text(
                  'No study content is available for this competency yet.',
                  style: StudyTypography.bodySecondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // DOMAIN NUMBER
  // ==========================================================

  int _getDomainNumber(String domainId) {
    final match = RegExp(r'\d+').firstMatch(domainId);

    if (match == null) {
      return 0;
    }

    return int.tryParse(match.group(0)!) ?? 0;
  }
}
