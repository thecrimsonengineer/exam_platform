import 'package:flutter/material.dart';

import '../../../models/study_content.dart';
import '../../../theme/study/study_colors_dark.dart';
import '../../../theme/study/study_icons.dart';
import '../../../theme/study/study_radius.dart';
import '../../../theme/study/study_shadows.dart';
import '../../../theme/study/study_spacing.dart';
import '../../../theme/study/study_typography_dark.dart';
import 'content_block_renderer_dark.dart';
import 'quiz_block_dark.dart';
import 'study_icon_badge.dart';

/// Premium renderer for a complete CSP study subtopic.
///
/// Every section is optional. Empty sections are automatically hidden.
class DarkStudySubtopicRenderer extends StatelessWidget {
  final StudySubtopic subtopic;
  final int domain;

  const DarkStudySubtopicRenderer({
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
        _buildContentBlocks(),
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
        color: DarkStudyColors.primaryLight,
        borderRadius: StudyRadius.large,
        border: Border.all(
          color: DarkStudyColors.primary.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const StudyIconBadge(
            icon: StudyIcons.topic,
            color: DarkStudyColors.primary,
            backgroundColor: DarkStudyColors.surface,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'STUDY SUBTOPIC',
                  style: DarkStudyTypography.eyebrow.copyWith(
                    color: DarkStudyColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(title, style: DarkStudyTypography.sectionTitle),
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
      accent: DarkStudyColors.primary,
      background: DarkStudyColors.primaryLight,
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
                color: DarkStudyColors.surface,
                borderRadius: StudyRadius.medium,
                border: Border.all(color: DarkStudyColors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: DarkStudyColors.primaryLight,
                      borderRadius: StudyRadius.small,
                    ),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: DarkStudyColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      objective,
                      style: DarkStudyTypography.body.copyWith(fontSize: 14.5),
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
  // CONTENT BLOCKS
  // ==========================================================

  Widget _buildContentBlocks() {
    if (subtopic.blocks.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildSection(
      title: 'Main Content',
      eyebrow: 'CORE LEARNING',
      icon: StudyIcons.book,
      accent: DarkStudyColors.primary,
      background: DarkStudyColors.surfaceSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: subtopic.blocks.asMap().entries.map((entry) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: entry.key == subtopic.blocks.length - 1 ? 0 : 12,
            ),
            child: DarkContentBlockRenderer(block: entry.value),
          );
        }).toList(),
      ),
    );
  }

  // ==========================================================
  // KEY POINTS
  // ==========================================================

  Widget _buildKeyPoints() {
    return _buildStringSection(
      values: subtopic.keyPoints,
      title: 'Key Points',
      eyebrow: 'HIGH-VALUE CONCEPTS',
      icon: StudyIcons.remember,
      accent: DarkStudyColors.accent,
      background: DarkStudyColors.accentLight,
    );
  }

  // ==========================================================
  // WORKPLACE EXAMPLES
  // ==========================================================

  Widget _buildExamples() {
    return _buildStringSection(
      values: subtopic.examples,
      title: 'Workplace Examples',
      eyebrow: 'APPLY THE CONCEPT',
      icon: StudyIcons.caseStudy,
      accent: DarkStudyColors.accent,
      background: DarkStudyColors.accentLight,
    );
  }

  // ==========================================================
  // CASE STUDIES
  // ==========================================================

  Widget _buildCaseStudies() {
    return _buildStringSection(
      values: subtopic.caseStudies,
      title: 'Case Studies',
      eyebrow: 'SCENARIO ANALYSIS',
      icon: StudyIcons.caseStudy,
      accent: DarkStudyColors.caseStudy,
      background: DarkStudyColors.caseStudyLight,
    );
  }

  // ==========================================================
  // FORMULAS
  // ==========================================================

  Widget _buildFormulas() {
    final formulas = _cleanStrings(subtopic.formulas);

    if (formulas.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildSection(
      title: 'Formulas',
      eyebrow: 'CALCULATIONS & METHODS',
      icon: StudyIcons.formula,
      accent: DarkStudyColors.primary,
      background: DarkStudyColors.primaryLight,
      child: Column(
        children: formulas.asMap().entries.map((entry) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: entry.key == formulas.length - 1 ? 0 : 12,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              decoration: BoxDecoration(
                color: DarkStudyColors.surface,
                borderRadius: StudyRadius.medium,
                border: Border.all(
                  color: DarkStudyColors.primary.withValues(alpha: 0.12),
                ),
              ),
              child: SelectableText(
                entry.value,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontFamily: 'monospace',
                  height: 1.55,
                  fontWeight: FontWeight.w600,
                  color: DarkStudyColors.textPrimary,
                ),
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
    return _buildStringSection(
      values: subtopic.references,
      title: 'References',
      eyebrow: 'SOURCE MATERIAL',
      icon: StudyIcons.reference,
      accent: DarkStudyColors.reference,
      background: DarkStudyColors.referenceLight,
      selectable: true,
    );
  }

  // ==========================================================
  // EXAM TIPS
  // ==========================================================

  Widget _buildExamTips() {
    return _buildStringSection(
      values: subtopic.examTips,
      title: 'Exam Tips',
      eyebrow: 'EXAM FOCUS',
      icon: StudyIcons.examTip,
      accent: DarkStudyColors.examTip,
      background: DarkStudyColors.examTipLight,
    );
  }

  // ==========================================================
  // COMMON MISTAKES
  // ==========================================================

  Widget _buildCommonMistakes() {
    return _buildStringSection(
      values: subtopic.commonMistakes,
      title: 'Common Mistakes',
      eyebrow: 'EXAM TRAPS',
      icon: StudyIcons.warning,
      accent: DarkStudyColors.warning,
      background: DarkStudyColors.warningLight,
    );
  }

  // ==========================================================
  // KEY TAKEAWAYS
  // ==========================================================

  Widget _buildKeyTakeaways() {
    return _buildStringSection(
      values: subtopic.keyTakeaways,
      title: 'Key Takeaways',
      eyebrow: 'FINAL REVISION',
      icon: StudyIcons.completed,
      accent: DarkStudyColors.success,
      background: DarkStudyColors.successLight,
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
      accent: DarkStudyColors.primary,
      background: DarkStudyColors.primaryLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: quizzes.asMap().entries.map((entry) {
          final index = entry.key;
          final quiz = entry.value;

          return Padding(
            padding: EdgeInsets.only(
              bottom: index == quizzes.length - 1 ? 0 : 12,
            ),
            child: DarkQuizBlock(quiz: quiz, domain: domain),
          );
        }).toList(),
      ),
    );
  }

  // ==========================================================
  // STRING CONTENT LISTS
  // ==========================================================

  List<String> _cleanStrings(List<String> values) {
    return values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
  }

  Widget _buildStringSection({
    required List<String> values,
    required String title,
    required String eyebrow,
    required IconData icon,
    required Color accent,
    required Color background,
    bool selectable = false,
  }) {
    final items = _cleanStrings(values);

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildSection(
      title: title,
      eyebrow: eyebrow,
      icon: icon,
      accent: accent,
      background: background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.asMap().entries.map((entry) {
          final item = entry.value;

          return Padding(
            padding: EdgeInsets.only(
              bottom: entry.key == items.length - 1 ? 0 : 10,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: DarkStudyColors.surface,
                borderRadius: StudyRadius.medium,
                border: Border.all(color: DarkStudyColors.border),
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
                    child: selectable
                        ? SelectableText(
                            item,
                            style: DarkStudyTypography.bodySecondary.copyWith(
                              fontSize: 14.5,
                              height: 1.55,
                            ),
                          )
                        : Text(
                            item,
                            style: DarkStudyTypography.bodySecondary.copyWith(
                              fontSize: 14.5,
                              height: 1.55,
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
                    backgroundColor: DarkStudyColors.surface,
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
                          style: DarkStudyTypography.eyebrow.copyWith(
                            color: accent,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(title, style: DarkStudyTypography.subSectionTitle),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _ResponsiveSectionPadding(child: child),
          ],
        ),
      ),
    );
  }
}

class _ResponsiveSectionPadding extends StatelessWidget {
  final Widget child;

  const _ResponsiveSectionPadding({required this.child});

  @override
  Widget build(BuildContext context) {
    final isPhone = MediaQuery.sizeOf(context).width < 600;

    return Padding(
      padding: EdgeInsets.all(
        isPhone ? StudySpacing.sm : StudySpacing.cardPadding,
      ),
      child: child,
    );
  }
}
