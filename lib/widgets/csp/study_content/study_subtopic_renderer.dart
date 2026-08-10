import 'package:flutter/material.dart';

import '../../../models/study_content.dart';
import '../../../theme/study/study_colors.dart';
import '../../../theme/study/study_icons.dart';
import '../../../theme/study/study_radius.dart';
import '../../../theme/study/study_shadows.dart';
import '../../../theme/study/study_spacing.dart';
import '../../../theme/study/study_typography.dart';
import 'main_content_topic_renderer.dart';
import 'quiz_block.dart';
import 'study_icon_badge.dart';

/// Premium renderer for a complete CSP study subtopic.
///
/// Every section is optional. Empty sections are automatically hidden.
class StudySubtopicRenderer extends StatelessWidget {
  final StudySubtopic subtopic;
  final int domain;

  const StudySubtopicRenderer({
    super.key,
    required this.subtopic,
    required this.domain,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubtopicTitle(),
        _buildLearningObjectives(),
        _buildMainContent(),
        _buildKeyPoints(),
        _buildExamples(),
        _buildCaseStudies(),
        _buildFormulas(),
        _buildReferences(),
        _buildExamTips(),
        _buildCommonMistakes(),
        _buildKeyTakeaways(),
        _buildQuizzes(),
      ],
    );
  }

  // ==========================================================
  // SUBTOPIC TITLE
  // ==========================================================

  Widget _buildSubtopicTitle() {
    final title = subtopic.title.trim();

    if (title.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 26),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: StudyColors.primaryLight,
        borderRadius: StudyRadius.large,
        border: Border.all(color: StudyColors.primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const StudyIconBadge(
            icon: StudyIcons.topic,
            color: StudyColors.primary,
            backgroundColor: StudyColors.surface,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'STUDY SUBTOPIC',
                  style: StudyTypography.eyebrow.copyWith(
                    color: StudyColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(title, style: StudyTypography.sectionTitle),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // LEARNING OBJECTIVES
  // ==========================================================

  Widget _buildLearningObjectives() {
    if (subtopic.learningObjectives.isEmpty) {
      return const SizedBox.shrink();
    }

    final objectives = subtopic.learningObjectives
        .map((objective) => objective.trim())
        .where((objective) => objective.isNotEmpty)
        .toList();

    if (objectives.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildSection(
      title: 'Learning Objectives',
      eyebrow: 'WHAT YOU SHOULD KNOW',
      icon: StudyIcons.objectives,
      accent: StudyColors.primary,
      background: StudyColors.primaryLight,
      child: Column(
        children: objectives.asMap().entries.map((entry) {
          final index = entry.key;
          final objective = entry.value;

          return Padding(
            padding: EdgeInsets.only(
              bottom: index == objectives.length - 1 ? 0 : 10,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: StudyColors.surface,
                borderRadius: StudyRadius.medium,
                border: Border.all(color: StudyColors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: StudyColors.primaryLight,
                      borderRadius: StudyRadius.small,
                    ),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: StudyColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      objective,
                      style: StudyTypography.body.copyWith(fontSize: 14.5),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ==========================================================
  // MAIN CONTENT
  // ==========================================================

  Widget _buildMainContent() {
    if (subtopic.mainContent.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildSection(
      title: 'Main Content',
      eyebrow: 'CORE LEARNING',
      icon: StudyIcons.book,
      accent: StudyColors.primary,
      background: StudyColors.surfaceSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: subtopic.mainContent
            .map(
              (MainContentTopic topic) =>
                  MainContentTopicRenderer(topic: topic, domain: domain),
            )
            .toList(),
      ),
    );
  }

  // ==========================================================
  // KEY POINTS
  // ==========================================================

  Widget _buildKeyPoints() {
    if (subtopic.keyPoints.isEmpty) {
      return const SizedBox.shrink();
    }

    final points = subtopic.keyPoints
        .where((entry) => entry.content.trim().isNotEmpty)
        .toList();

    if (points.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildSection(
      title: 'Key Points',
      eyebrow: 'HIGH-VALUE CONCEPTS',
      icon: StudyIcons.remember,
      accent: StudyColors.accent,
      background: StudyColors.accentLight,
      child: _buildContentEntryList(points, accent: StudyColors.accent),
    );
  }

  // ==========================================================
  // WORKPLACE EXAMPLES
  // ==========================================================

  Widget _buildExamples() {
    if (subtopic.examples.isEmpty) {
      return const SizedBox.shrink();
    }

    final examples = subtopic.examples
        .where((entry) => entry.content.trim().isNotEmpty)
        .toList();

    if (examples.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildSection(
      title: 'Workplace Examples',
      eyebrow: 'APPLY THE CONCEPT',
      icon: StudyIcons.caseStudy,
      accent: StudyColors.accent,
      background: StudyColors.accentLight,
      child: _buildContentEntryList(examples, accent: StudyColors.accent),
    );
  }

  // ==========================================================
  // CASE STUDIES
  // ==========================================================

  Widget _buildCaseStudies() {
    if (subtopic.caseStudies.isEmpty) {
      return const SizedBox.shrink();
    }

    final caseStudies = subtopic.caseStudies
        .where((entry) => entry.content.trim().isNotEmpty)
        .toList();

    if (caseStudies.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildSection(
      title: 'Case Studies',
      eyebrow: 'SCENARIO ANALYSIS',
      icon: StudyIcons.caseStudy,
      accent: StudyColors.caseStudy,
      background: StudyColors.caseStudyLight,
      child: _buildContentEntryList(caseStudies, accent: StudyColors.caseStudy),
    );
  }

  // ==========================================================
  // FORMULAS
  // ==========================================================

  Widget _buildFormulas() {
    if (subtopic.formulas.isEmpty) {
      return const SizedBox.shrink();
    }

    final formulas = subtopic.formulas
        .where((entry) => entry.content.trim().isNotEmpty)
        .toList();

    if (formulas.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildSection(
      title: 'Formulas',
      eyebrow: 'CALCULATIONS & METHODS',
      icon: StudyIcons.formula,
      accent: StudyColors.primary,
      background: StudyColors.primaryLight,
      child: Column(
        children: formulas.asMap().entries.map((entry) {
          final index = entry.key;
          final formula = entry.value;

          return Padding(
            padding: EdgeInsets.only(
              bottom: index == formulas.length - 1 ? 0 : 12,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: StudyColors.surface,
                borderRadius: StudyRadius.medium,
                border: Border.all(
                  color: StudyColors.primary.withValues(alpha: 0.12),
                ),
                boxShadow: StudyShadows.soft,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (formula.title.trim().isNotEmpty) ...[
                    Row(
                      children: [
                        const StudyIconBadge(
                          icon: StudyIcons.formula,
                          color: StudyColors.primary,
                          backgroundColor: StudyColors.primaryLight,
                          size: 34,
                          iconSize: 17,
                          showShadow: false,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            formula.title.trim(),
                            style: StudyTypography.cardTitle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                  ],
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      color: StudyColors.surfaceSoft,
                      borderRadius: StudyRadius.small,
                    ),
                    child: SelectableText(
                      formula.content.trim(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 17,
                        fontFamily: 'monospace',
                        height: 1.55,
                        fontWeight: FontWeight.w600,
                        color: StudyColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ==========================================================
  // REFERENCES
  // ==========================================================

  Widget _buildReferences() {
    if (subtopic.references.isEmpty) {
      return const SizedBox.shrink();
    }

    final references = subtopic.references
        .where(
          (entry) =>
              entry.title.trim().isNotEmpty ||
              entry.content.trim().isNotEmpty ||
              entry.source.trim().isNotEmpty ||
              entry.url.trim().isNotEmpty,
        )
        .toList();

    if (references.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildSection(
      title: 'References',
      eyebrow: 'SOURCE MATERIAL',
      icon: StudyIcons.reference,
      accent: StudyColors.reference,
      background: StudyColors.referenceLight,
      child: Column(
        children: references.asMap().entries.map((entry) {
          final index = entry.key;
          final reference = entry.value;

          return Padding(
            padding: EdgeInsets.only(
              bottom: index == references.length - 1 ? 0 : 12,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: StudyColors.surface,
                borderRadius: StudyRadius.medium,
                border: Border.all(color: StudyColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (reference.title.trim().isNotEmpty)
                    Text(
                      reference.title.trim(),
                      style: StudyTypography.cardTitle,
                    ),
                  if (reference.source.trim().isNotEmpty) ...[
                    const SizedBox(height: 7),
                    Text(
                      reference.source.trim(),
                      style: StudyTypography.bodySecondary.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (reference.content.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      reference.content.trim(),
                      style: StudyTypography.bodySecondary,
                    ),
                  ],
                  if (reference.url.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: StudyColors.referenceLight,
                        borderRadius: StudyRadius.small,
                      ),
                      child: SelectableText(
                        reference.url.trim(),
                        style: StudyTypography.bodySecondary.copyWith(
                          color: StudyColors.reference,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ==========================================================
  // EXAM TIPS
  // ==========================================================

  Widget _buildExamTips() {
    if (subtopic.examTips.isEmpty) {
      return const SizedBox.shrink();
    }

    final tips = subtopic.examTips
        .where((entry) => entry.content.trim().isNotEmpty)
        .toList();

    if (tips.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildSection(
      title: 'Exam Tips',
      eyebrow: 'EXAM FOCUS',
      icon: StudyIcons.examTip,
      accent: StudyColors.examTip,
      background: StudyColors.examTipLight,
      child: _buildContentEntryList(tips, accent: StudyColors.examTip),
    );
  }

  // ==========================================================
  // COMMON MISTAKES
  // ==========================================================

  Widget _buildCommonMistakes() {
    if (subtopic.commonMistakes.isEmpty) {
      return const SizedBox.shrink();
    }

    final mistakes = subtopic.commonMistakes
        .where((entry) => entry.content.trim().isNotEmpty)
        .toList();

    if (mistakes.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildSection(
      title: 'Common Mistakes',
      eyebrow: 'EXAM TRAPS',
      icon: StudyIcons.warning,
      accent: StudyColors.warning,
      background: StudyColors.warningLight,
      child: _buildContentEntryList(mistakes, accent: StudyColors.warning),
    );
  }

  // ==========================================================
  // KEY TAKEAWAYS
  // ==========================================================

  Widget _buildKeyTakeaways() {
    if (subtopic.keyTakeaways.isEmpty) {
      return const SizedBox.shrink();
    }

    final takeaways = subtopic.keyTakeaways
        .where((entry) => entry.content.trim().isNotEmpty)
        .toList();

    if (takeaways.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildSection(
      title: 'Key Takeaways',
      eyebrow: 'FINAL REVISION',
      icon: StudyIcons.completed,
      accent: StudyColors.success,
      background: StudyColors.successLight,
      child: _buildContentEntryList(takeaways, accent: StudyColors.success),
    );
  }

  // ==========================================================
  // QUIZZES
  // ==========================================================

  Widget _buildQuizzes() {
    if (subtopic.quizzes.isEmpty) {
      return const SizedBox.shrink();
    }

    final quizzes = subtopic.quizzes
        .where((quiz) => quiz.quizId.trim().isNotEmpty)
        .toList();

    if (quizzes.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildSection(
      title: 'Practice Questions',
      eyebrow: 'TEST YOUR KNOWLEDGE',
      icon: StudyIcons.quiz,
      accent: StudyColors.primary,
      background: StudyColors.primaryLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: quizzes.asMap().entries.map((entry) {
          final index = entry.key;
          final quiz = entry.value;

          return Padding(
            padding: EdgeInsets.only(
              bottom: index == quizzes.length - 1 ? 0 : 12,
            ),
            child: QuizBlock(quiz: quiz, domain: domain),
          );
        }).toList(),
      ),
    );
  }

  // ==========================================================
  // CONTENT ENTRY LIST
  // ==========================================================

  Widget _buildContentEntryList(
    List<ContentEntry> entries, {
    required Color accent,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: entries.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;

        final title = item.title.trim();
        final content = item.content.trim();

        return Padding(
          padding: EdgeInsets.only(
            bottom: index == entries.length - 1 ? 0 : 10,
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: StudyColors.surface,
              borderRadius: StudyRadius.medium,
              border: Border.all(color: StudyColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.10),
                    borderRadius: StudyRadius.small,
                  ),
                  child: Icon(StudyIcons.completed, size: 16, color: accent),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title.isNotEmpty)
                        Text(title, style: StudyTypography.cardTitle),
                      if (content.isNotEmpty) ...[
                        if (title.isNotEmpty) const SizedBox(height: 6),
                        Text(
                          content,
                          style: StudyTypography.bodySecondary.copyWith(
                            fontSize: 14.5,
                            height: 1.55,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ==========================================================
  // SHARED SECTION
  // ==========================================================

  Widget _buildSection({
    required String title,
    required String eyebrow,
    required IconData icon,
    required Color accent,
    required Color background,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 26),
      decoration: BoxDecoration(
        color: background,
        borderRadius: StudyRadius.large,
        border: Border.all(color: accent.withValues(alpha: 0.14)),
        boxShadow: StudyShadows.soft,
      ),
      child: ClipRRect(
        borderRadius: StudyRadius.large,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.045),
                border: Border(
                  bottom: BorderSide(color: accent.withValues(alpha: 0.10)),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  StudyIconBadge(
                    icon: icon,
                    color: accent,
                    backgroundColor: StudyColors.surface,
                    size: 42,
                    iconSize: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          eyebrow,
                          style: StudyTypography.eyebrow.copyWith(
                            color: accent,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(title, style: StudyTypography.subSectionTitle),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(StudySpacing.cardPadding),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}
