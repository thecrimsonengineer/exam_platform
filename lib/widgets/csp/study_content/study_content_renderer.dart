import 'package:flutter/material.dart';

import '../../../models/study_content.dart';
import '../../../screens/courses/csp/study_subtopic_screen.dart';
import '../../../theme/study/study_colors.dart';
import '../../../theme/study/study_gradients.dart';
import '../../../theme/study/study_icons.dart';
import '../../../theme/study/study_radius.dart';
import '../../../theme/study/study_shadows.dart';
import '../../../theme/study/study_spacing.dart';
import '../../../theme/study/study_typography.dart';

/// Premium student-facing renderer for a CSP competency index.
///
/// The competency screen is intentionally an overview and subtopic launcher.
/// Each subtopic opens on its own screen so long competencies remain easy to
/// navigate and study.
class StudyContentRenderer extends StatelessWidget {
  final StudyContent content;

  const StudyContentRenderer({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    final domain = _getDomainNumber(content.domainId);
    final subtopics = content.subtopics;

    return Container(
      color: StudyColors.background,
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildHero(domain),
            LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 900;

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
                        48,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildOverviewCard(subtopics.length),
                          const SizedBox(height: 26),
                          _buildSectionHeader(subtopics.length),
                          const SizedBox(height: 14),
                          ...subtopics.asMap().entries.map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _buildSubtopicCard(
                                context,
                                subtopic: entry.value,
                                index: entry.key,
                                total: subtopics.length,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(int domain) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: StudyGradients.hero),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: StudySpacing.maxContentWidth,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              StudySpacing.pageHorizontalDesktop,
              36,
              StudySpacing.pageHorizontalDesktop,
              38,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CSP11 • DOMAIN ${domain.toString().padLeft(2, '0')}',
                  style: StudyTypography.eyebrow.copyWith(
                    color: Colors.white.withValues(alpha: 0.68),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  content.title,
                  style: StudyTypography.heroTitle.copyWith(
                    color: Colors.white,
                    fontSize: 40,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  'Competency ${content.competencyNumber} • Choose a subtopic to begin studying',
                  style: StudyTypography.bodyLarge.copyWith(
                    color: Colors.white.withValues(alpha: 0.78),
                  ),
                ),
                const SizedBox(height: 26),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildHeroStat(
                      icon: StudyIcons.subtopic,
                      label: 'SUBTOPICS',
                      value: '${content.subtopics.length}',
                    ),
                    _buildHeroStat(
                      icon: StudyIcons.book,
                      label: 'CONTENT TOPICS',
                      value: '${_topicCount()}',
                    ),
                    _buildHeroStat(
                      icon: StudyIcons.quiz,
                      label: 'PRACTICE LINKS',
                      value: '${_quizCount()}',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
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

  Widget _buildOverviewCard(int count) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
            width: 46,
            height: 46,
            alignment: Alignment.center,
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
                const SizedBox(height: 5),
                Text(
                  '$count ${count == 1 ? 'subtopic' : 'subtopics'}',
                  style: StudyTypography.subSectionTitle,
                ),
                const SizedBox(height: 5),
                Text(
                  'Each subtopic opens on its own study screen. Use Previous and Next to move through the competency without returning to this page.',
                  style: StudyTypography.bodySecondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(int count) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LEARNING SECTIONS',
                style: StudyTypography.eyebrow.copyWith(
                  color: StudyColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Choose a subtopic',
                style: StudyTypography.sectionTitle,
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: StudyColors.surface,
            borderRadius: StudyRadius.pillRadius,
            border: Border.all(color: StudyColors.border),
          ),
          child: Text(
            '$count ${count == 1 ? 'SECTION' : 'SECTIONS'}',
            style: StudyTypography.eyebrow.copyWith(
              color: StudyColors.textSecondary,
              fontSize: 9,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubtopicCard(
    BuildContext context, {
    required StudySubtopic subtopic,
    required int index,
    required int total,
  }) {
    final topicCount = subtopic.mainContent.length;
    final objectiveCount = subtopic.learningObjectives.length;
    final quizCount = _subtopicQuizCount(subtopic);

    return Material(
      color: StudyColors.surface,
      borderRadius: StudyRadius.large,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => StudySubtopicScreen(
              content: content,
              subtopicIndex: index,
            ),
          ),
        ),
        borderRadius: StudyRadius.large,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: StudyRadius.large,
            border: Border.all(color: StudyColors.border),
            boxShadow: StudyShadows.soft,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: StudyGradients.heroSoft,
                  borderRadius: StudyRadius.medium,
                ),
                child: Text(
                  '${index + 1}'.padLeft(2, '0'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SUBTOPIC ${index + 1} OF $total',
                      style: StudyTypography.eyebrow.copyWith(
                        color: StudyColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtopic.title.isEmpty
                          ? 'Untitled Subtopic'
                          : subtopic.title,
                      style: StudyTypography.subSectionTitle,
                    ),
                    const SizedBox(height: 9),
                    Wrap(
                      spacing: 8,
                      runSpacing: 7,
                      children: [
                        _buildMetaChip('$topicCount topics'),
                        _buildMetaChip('$objectiveCount objectives'),
                        if (quizCount > 0)
                          _buildMetaChip('$quizCount practice links'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: StudyColors.primaryLight,
                  borderRadius: StudyRadius.medium,
                ),
                child: const Icon(
                  StudyIcons.next,
                  color: StudyColors.primary,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetaChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: StudyColors.surfaceSoft,
        borderRadius: StudyRadius.pillRadius,
        border: Border.all(color: StudyColors.border),
      ),
      child: Text(
        label,
        style: StudyTypography.caption.copyWith(
          color: StudyColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  int _topicCount() {
    return content.subtopics.fold<int>(
      0,
      (sum, subtopic) => sum + subtopic.mainContent.length,
    );
  }

  int _quizCount() {
    return content.subtopics.fold<int>(
      0,
      (sum, subtopic) => sum + _subtopicQuizCount(subtopic),
    );
  }

  int _subtopicQuizCount(StudySubtopic subtopic) {
    return subtopic.quizzes.length +
        subtopic.mainContent.fold<int>(
          0,
          (sum, topic) => sum + topic.quizzes.length,
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
