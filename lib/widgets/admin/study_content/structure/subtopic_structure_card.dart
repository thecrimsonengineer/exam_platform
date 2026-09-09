import 'package:flutter/material.dart';

import '../../../../models/study_content.dart';
import '../../../../theme/study/study_colors.dart';
import '../../../../theme/study/study_radius.dart';
import '../../../../theme/study/study_shadows.dart';
import '../../../../theme/study/study_typography.dart';

import 'content_block_structure_card.dart';

class SubtopicStructureCard extends StatefulWidget {
  final StudySubtopic subtopic;
  final int index;

  /// When supplied, this controls the expansion state from the
  /// parent Structure Inspector.
  final bool? forceExpanded;

  const SubtopicStructureCard({
    super.key,
    required this.subtopic,
    required this.index,
    this.forceExpanded,
  });

  @override
  State<SubtopicStructureCard> createState() => _SubtopicStructureCardState();
}

class _SubtopicStructureCardState extends State<SubtopicStructureCard> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();

    _isExpanded = widget.forceExpanded ?? widget.index == 0;
  }

  @override
  void didUpdateWidget(covariant SubtopicStructureCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.forceExpanded != null &&
        widget.forceExpanded != oldWidget.forceExpanded) {
      _isExpanded = widget.forceExpanded!;
    }
  }

  StudySubtopic get subtopic => widget.subtopic;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: StudyColors.surface,
        borderRadius: StudyRadius.large,
        border: Border.all(color: StudyColors.border),
        boxShadow: StudyShadows.soft,
      ),
      child: Material(
        color: StudyColors.surface,
        borderRadius: StudyRadius.large,
        clipBehavior: Clip.antiAlias,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            key: ValueKey('subtopic-${subtopic.id}-${widget.forceExpanded}'),
            initiallyExpanded: _isExpanded,
            maintainState: true,
            onExpansionChanged: (expanded) {
              setState(() {
                _isExpanded = expanded;
              });
            },
            tilePadding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            collapsedBackgroundColor: StudyColors.surface,
            backgroundColor: StudyColors.surface,
            collapsedShape: RoundedRectangleBorder(
              borderRadius: StudyRadius.large,
              side: BorderSide.none,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: StudyRadius.large,
              side: BorderSide.none,
            ),
            iconColor: StudyColors.primary,
            collapsedIconColor: StudyColors.textSecondary,
            leading: _buildNumber(),
            title: Text(
              subtopic.title.isEmpty ? 'Untitled Subtopic' : subtopic.title,
              style: StudyTypography.sectionTitle.copyWith(
                color: StudyColors.textPrimary,
                fontSize: 17,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                subtopic.id,
                style: StudyTypography.caption.copyWith(
                  color: StudyColors.textSecondary,
                ),
              ),
            ),
            trailing: _buildMetrics(),
            children: [
              _buildOverviewStrip(),
              const SizedBox(height: 18),
              _buildObjectives(),
              const SizedBox(height: 18),
              _buildContentBlocks(),
              _buildTextSections(),
              _buildQuizSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumber() {
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: StudyColors.primary.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${widget.index + 1}'.padLeft(2, '0'),
        style: StudyTypography.label.copyWith(
          color: StudyColors.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildMetrics() {
    return Wrap(
      spacing: 5,
      children: [
        _metric(Icons.flag_outlined, '${subtopic.learningObjectives.length}'),
        _metric(Icons.menu_book_outlined, '${subtopic.blocks.length}'),
        _metric(Icons.quiz_outlined, '${subtopic.quizzes.length}'),
      ],
    );
  }

  Widget _metric(IconData icon, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: StudyColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: StudyColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: StudyColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            value,
            style: StudyTypography.caption.copyWith(
              color: StudyColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewStrip() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: StudyColors.background,
        borderRadius: StudyRadius.medium,
        border: Border.all(color: StudyColors.border),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _overviewItem('Objectives', subtopic.learningObjectives.length),
          _overviewItem('Content Blocks', subtopic.blocks.length),
          _overviewItem('Key Points', subtopic.keyPoints.length),
          _overviewItem('Examples', subtopic.examples.length),
          _overviewItem('Case Studies', subtopic.caseStudies.length),
          _overviewItem('Formulas', subtopic.formulas.length),
          _overviewItem('References', subtopic.references.length),
          _overviewItem('Exam Tips', subtopic.examTips.length),
          _overviewItem('Mistakes', subtopic.commonMistakes.length),
          _overviewItem('Takeaways', subtopic.keyTakeaways.length),
          _overviewItem('Quizzes', subtopic.quizzes.length),
        ],
      ),
    );
  }

  Widget _overviewItem(String label, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: StudyColors.surface,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: StudyColors.border),
      ),
      child: Text(
        '$count $label',
        style: StudyTypography.caption.copyWith(
          color: StudyColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildObjectives() {
    if (subtopic.learningObjectives.isEmpty) {
      return _emptySection(
        'Learning Objectives',
        Icons.flag_outlined,
        'No learning objectives supplied.',
      );
    }

    return _sectionCard(
      title: 'Learning Objectives',
      icon: Icons.flag_rounded,
      child: Column(
        children: List.generate(
          subtopic.learningObjectives.length,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: StudyColors.success.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: 14,
                    color: StudyColors.success,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    subtopic.learningObjectives[index],
                    style: StudyTypography.bodySecondary.copyWith(
                      fontSize: 13.5,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContentBlocks() {
    if (subtopic.blocks.isEmpty) {
      return _emptySection(
        'Content Blocks',
        Icons.menu_book_outlined,
        'No content blocks supplied.',
      );
    }

    return _sectionCard(
      title: 'Content Blocks',
      icon: Icons.menu_book_rounded,
      child: Column(
        children: List.generate(
          subtopic.blocks.length,
          (index) => ContentBlockStructureCard(
            block: subtopic.blocks[index],
            index: index,
          ),
        ),
      ),
    );
  }

  Widget _buildTextSections() {
    final sections = <_TextSection>[
      _TextSection(
        title: 'Key Points',
        icon: Icons.push_pin_outlined,
        entries: subtopic.keyPoints,
      ),
      _TextSection(
        title: 'Examples',
        icon: Icons.lightbulb_outline_rounded,
        entries: subtopic.examples,
      ),
      _TextSection(
        title: 'Case Studies',
        icon: Icons.business_center_outlined,
        entries: subtopic.caseStudies,
      ),
      _TextSection(
        title: 'Formulas',
        icon: Icons.functions_rounded,
        entries: subtopic.formulas,
      ),
      _TextSection(
        title: 'References',
        icon: Icons.link_rounded,
        entries: subtopic.references,
      ),
      _TextSection(
        title: 'Exam Tips',
        icon: Icons.school_rounded,
        entries: subtopic.examTips,
      ),
      _TextSection(
        title: 'Common Mistakes',
        icon: Icons.error_outline_rounded,
        entries: subtopic.commonMistakes,
      ),
      _TextSection(
        title: 'Key Takeaways',
        icon: Icons.bookmark_rounded,
        entries: subtopic.keyTakeaways,
      ),
    ];

    final visible = sections.where((section) => section.entries.isNotEmpty);

    if (visible.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: visible
          .map(
            (section) => Padding(
              padding: const EdgeInsets.only(top: 18),
              child: _buildTextSection(section),
            ),
          )
          .toList(),
    );
  }

  Widget _buildTextSection(_TextSection section) {
    return _sectionCard(
      title: section.title,
      icon: section.icon,
      child: Column(
        children: List.generate(
          section.entries.length,
          (index) => _buildEntry(section.entries[index], index),
        ),
      ),
    );
  }

  Widget _buildEntry(String entry, int index) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: StudyColors.background,
        borderRadius: StudyRadius.small,
        border: Border.all(color: StudyColors.border),
      ),
      child: Text(
        '${index + 1}. ${entry.trim().isEmpty ? '(Empty item)' : entry}',
        style: StudyTypography.bodySecondary.copyWith(
          fontSize: 13,
          height: 1.45,
        ),
      ),
    );
  }

  Widget _buildQuizSection() {
    if (subtopic.quizzes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: _sectionCard(
        title: 'Quiz References',
        icon: Icons.quiz_rounded,
        child: Column(
          children: subtopic.quizzes
              .map(
                (quiz) => Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: StudyColors.primary.withValues(alpha: 0.05),
                    borderRadius: StudyRadius.small,
                    border: Border.all(
                      color: StudyColors.primary.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.link_rounded,
                        size: 17,
                        color: StudyColors.primary,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          quiz.quizId,
                          style: StudyTypography.label.copyWith(
                            color: StudyColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 19, color: StudyColors.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: StudyTypography.sectionTitle.copyWith(
                color: StudyColors.textPrimary,
                fontSize: 15,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }

  Widget _emptySection(String title, IconData icon, String message) {
    return _sectionCard(
      title: title,
      icon: icon,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: StudyColors.background,
          borderRadius: StudyRadius.small,
          border: Border.all(color: StudyColors.border),
        ),
        child: Row(
          children: [
            Icon(
              Icons.remove_circle_outline_rounded,
              size: 18,
              color: StudyColors.textSecondary,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                message,
                style: StudyTypography.bodySecondary.copyWith(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TextSection {
  final String title;
  final IconData icon;
  final List<String> entries;

  const _TextSection({
    required this.title,
    required this.icon,
    required this.entries,
  });
}
