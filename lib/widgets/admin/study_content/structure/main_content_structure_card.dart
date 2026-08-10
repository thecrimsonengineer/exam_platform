import 'package:flutter/material.dart';

import '../../../../models/study_content.dart';
import '../../../../theme/study/study_colors.dart';
import '../../../../theme/study/study_radius.dart';
import '../../../../theme/study/study_shadows.dart';
import '../../../../theme/study/study_typography.dart';

import 'content_block_structure_card.dart';

class MainContentStructureCard extends StatefulWidget {
  final MainContentTopic topic;
  final int index;

  /// Controls the expansion state from the parent Structure Inspector.
  final bool? forceExpanded;

  const MainContentStructureCard({
    super.key,
    required this.topic,
    required this.index,
    this.forceExpanded,
  });

  @override
  State<MainContentStructureCard> createState() =>
      _MainContentStructureCardState();
}

class _MainContentStructureCardState extends State<MainContentStructureCard> {
  late bool _isExpanded;

  MainContentTopic get topic => widget.topic;

  @override
  void initState() {
    super.initState();

    _isExpanded = widget.forceExpanded ?? widget.index == 0;
  }

  @override
  void didUpdateWidget(covariant MainContentStructureCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.forceExpanded != null &&
        widget.forceExpanded != oldWidget.forceExpanded) {
      _isExpanded = widget.forceExpanded!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: StudyColors.surface,
        borderRadius: StudyRadius.medium,
        border: Border.all(color: StudyColors.border),
        boxShadow: StudyShadows.soft,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: PageStorageKey<String>('main-content-${topic.id}'),
          initiallyExpanded: _isExpanded,
          maintainState: true,
          onExpansionChanged: (expanded) {
            setState(() {
              _isExpanded = expanded;
            });
          },
          tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          collapsedBackgroundColor: StudyColors.surface,
          backgroundColor: StudyColors.surface,
          collapsedShape: RoundedRectangleBorder(
            borderRadius: StudyRadius.medium,
            side: BorderSide.none,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: StudyRadius.medium,
            side: BorderSide.none,
          ),
          iconColor: StudyColors.primary,
          collapsedIconColor: StudyColors.textSecondary,
          title: Text(
            topic.title.isEmpty ? 'Untitled Main Content Topic' : topic.title,
            style: StudyTypography.sectionTitle.copyWith(
              color: StudyColors.textPrimary,
              fontSize: 15,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              topic.id,
              style: StudyTypography.caption.copyWith(
                color: StudyColors.textSecondary,
              ),
            ),
          ),
          trailing: _buildMetrics(),
          children: [
            _buildTopicHeader(),
            const SizedBox(height: 12),
            if (topic.blocks.isNotEmpty)
              ...List.generate(
                topic.blocks.length,
                (blockIndex) => ContentBlockStructureCard(
                  block: topic.blocks[blockIndex],
                  index: blockIndex,
                ),
              )
            else
              _buildEmptyState(
                icon: Icons.view_agenda_outlined,
                text: 'No content blocks in this topic.',
              ),
            if (topic.quizzes.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildQuizSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetrics() {
    return Wrap(
      spacing: 6,
      children: [
        _metric(Icons.view_agenda_outlined, '${topic.blocks.length}'),
        if (topic.quizzes.isNotEmpty)
          _metric(Icons.quiz_outlined, '${topic.quizzes.length}'),
      ],
    );
  }

  Widget _buildTopicHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: StudyColors.background,
        borderRadius: StudyRadius.small,
        border: Border.all(color: StudyColors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.menu_book_rounded, color: StudyColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Main Content Topic',
              style: StudyTypography.label.copyWith(
                color: StudyColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            '${topic.blocks.length} blocks',
            style: StudyTypography.caption.copyWith(
              color: StudyColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: StudyColors.primary.withValues(alpha: 0.05),
        borderRadius: StudyRadius.small,
        border: Border.all(color: StudyColors.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.quiz_rounded, size: 18, color: StudyColors.primary),
              const SizedBox(width: 8),
              Text(
                'Quiz References',
                style: StudyTypography.label.copyWith(
                  color: StudyColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...topic.quizzes.map(
            (quiz) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                children: [
                  const Icon(
                    Icons.link_rounded,
                    size: 15,
                    color: StudyColors.textSecondary,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      quiz.quizId,
                      style: StudyTypography.caption.copyWith(
                        color: StudyColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(IconData icon, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: StudyColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: StudyColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: StudyColors.textSecondary),
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

  Widget _buildEmptyState({required IconData icon, required String text}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: StudyColors.background,
        borderRadius: StudyRadius.small,
        border: Border.all(color: StudyColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: StudyColors.textSecondary),
          const SizedBox(width: 10),
          Text(
            text,
            style: StudyTypography.bodySecondary.copyWith(fontSize: 13),
          ),
        ],
      ),
    );
  }
}
