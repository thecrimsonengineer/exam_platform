import 'package:flutter/material.dart';

import '../../../models/study_content.dart';
import '../../../theme/study/study_colors.dart';
import '../../../theme/study/study_gradients.dart';
import '../../../theme/study/study_icons.dart';
import '../../../theme/study/study_radius.dart';
import '../../../theme/study/study_shadows.dart';
import '../../../theme/study/study_spacing.dart';
import '../../../theme/study/study_typography.dart';
import '../../../widgets/csp/study_content/study_content_navigation.dart';
import '../../../widgets/csp/study_content/study_subtopic_renderer.dart';

/// Student-facing screen for one CSP competency subtopic.
///
/// Each subtopic is presented as its own screen so a competency does not
/// become one very long document. Previous/next navigation keeps the
/// learning flow continuous.
class StudySubtopicScreen extends StatelessWidget {
  final StudyContent content;
  final int subtopicIndex;

  const StudySubtopicScreen({
    super.key,
    required this.content,
    required this.subtopicIndex,
  });

  @override
  Widget build(BuildContext context) {
    final subtopics = content.subtopics;

    if (subtopics.isEmpty ||
        subtopicIndex < 0 ||
        subtopicIndex >= subtopics.length) {
      return const Scaffold(
        body: Center(child: Text('Study subtopic is unavailable.')),
      );
    }

    final subtopic = subtopics[subtopicIndex];
    final domain = _getDomainNumber(content.domainId);
    final hasPrevious = subtopicIndex > 0;
    final hasNext = subtopicIndex < subtopics.length - 1;
    final progress = (subtopicIndex + 1) / subtopics.length;

    return Scaffold(
      backgroundColor: StudyColors.background,
      appBar: _buildAppBar(context, subtopic),
      body: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 900;

                return SingleChildScrollView(
                  padding: EdgeInsets.only(
                    bottom: 36,
                    left: isDesktop
                        ? StudySpacing.pageHorizontalDesktop
                        : StudySpacing.pageHorizontal,
                    right: isDesktop
                        ? StudySpacing.pageHorizontalDesktop
                        : StudySpacing.pageHorizontal,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: StudySpacing.maxContentWidth,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSubtopicHero(
                            subtopic: subtopic,
                            domain: domain,
                            index: subtopicIndex,
                            total: subtopics.length,
                            isDesktop: isDesktop,
                          ),
                          const SizedBox(height: 24),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(isDesktop ? 28 : 20),
                            decoration: BoxDecoration(
                              color: StudyColors.surface,
                              borderRadius: StudyRadius.large,
                              border: Border.all(color: StudyColors.border),
                              boxShadow: StudyShadows.soft,
                            ),
                            child: StudySubtopicRenderer(
                              subtopic: subtopic,
                              domain: domain,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          StudyContentNavigation(
            progress: progress,
            previousLabel: hasPrevious
                ? 'Previous Subtopic'
                : 'Competency Overview',
            nextLabel: hasNext ? 'Next Subtopic' : 'Back to Competency',
            onPrevious: hasPrevious
                ? () => _openSubtopic(context, subtopicIndex - 1)
                : () => Navigator.of(context).pop(),
            onNext: hasNext
                ? () => _openSubtopic(context, subtopicIndex + 1)
                : () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    StudySubtopic subtopic,
  ) {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: StudyColors.surface,
      foregroundColor: StudyColors.textPrimary,
      titleSpacing: StudySpacing.pageHorizontal,
      leading: IconButton(
        tooltip: 'Back to Competency',
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back_rounded, size: 21),
      ),
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: StudyColors.primaryLight,
              borderRadius: StudyRadius.small,
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              size: 19,
              color: StudyColors.primary,
            ),
          ),
          const SizedBox(width: StudySpacing.sm),
          Expanded(
            child: Text(
              subtopic.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: StudyTypography.cardTitle.copyWith(
                color: StudyColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtopicHero({
    required StudySubtopic subtopic,
    required int domain,
    required int index,
    required int total,
    required bool isDesktop,
  }) {
    final title = subtopic.title.trim().isEmpty
        ? 'Study Subtopic'
        : subtopic.title.trim();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: StudyGradients.hero,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        boxShadow: StudyShadows.soft,
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          isDesktop ? 30 : 22,
          isDesktop ? 30 : 24,
          isDesktop ? 30 : 22,
          isDesktop ? 28 : 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'DOMAIN ${domain.toString().padLeft(2, '0')}',
                  style: StudyTypography.eyebrow.copyWith(
                    color: Colors.white.withValues(alpha: 0.68),
                  ),
                ),
                const SizedBox(width: 9),
                Icon(
                  StudyIcons.next,
                  size: 15,
                  color: Colors.white.withValues(alpha: 0.42),
                ),
                const SizedBox(width: 9),
                Text(
                  'COMPETENCY ${content.competencyNumber}',
                  style: StudyTypography.eyebrow.copyWith(
                    color: Colors.white.withValues(alpha: 0.68),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: StudyRadius.medium,
                border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
              ),
              child: Text(
                '${index + 1}'.padLeft(2, '0'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: StudyTypography.heroTitle.copyWith(
                color: Colors.white,
                fontSize: isDesktop ? 34 : 28,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Subtopic ${index + 1} of $total',
              style: StudyTypography.bodyLarge.copyWith(
                color: Colors.white.withValues(alpha: 0.78),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openSubtopic(BuildContext context, int index) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            StudySubtopicScreen(content: content, subtopicIndex: index),
      ),
    );
  }

  int _getDomainNumber(String domainId) {
    final match = RegExp(r'\d+').firstMatch(domainId);

    if (match == null) {
      return 0;
    }

    return int.tryParse(match.group(0)!) ?? 0;
  }
}
