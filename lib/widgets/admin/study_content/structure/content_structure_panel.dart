import 'package:flutter/material.dart';

import '../../../../models/study_content.dart';
import '../../../../theme/study/study_colors.dart';
import '../../../../theme/study/study_radius.dart';
import '../../../../theme/study/study_shadows.dart';
import '../../../../theme/study/study_typography.dart';

import 'subtopic_structure_card.dart';

class ContentStructurePanel extends StatefulWidget {
  final StudyContent? content;

  const ContentStructurePanel({super.key, required this.content});

  @override
  State<ContentStructurePanel> createState() => _ContentStructurePanelState();
}

class _ContentStructurePanelState extends State<ContentStructurePanel> {
  bool _expandAll = false;
  int _structureRefreshKey = 0;

  StudyContent? get content => widget.content;

  @override
  Widget build(BuildContext context) {
    if (content == null) {
      return _buildEmpty();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeading(),
          const SizedBox(height: 20),
          _buildCompetencyCard(),
          const SizedBox(height: 14),
          _buildInspectorToolbar(),
          const SizedBox(height: 18),
          _buildStructureSummary(),
          const SizedBox(height: 24),
          _buildHierarchyHeader(),
          const SizedBox(height: 12),
          if (content!.subtopics.isEmpty)
            _buildNoSubtopics()
          else
            KeyedSubtree(
              key: ValueKey(_structureRefreshKey),
              child: Column(
                children: List.generate(
                  content!.subtopics.length,
                  (index) => SubtopicStructureCard(
                    subtopic: content!.subtopics[index],
                    index: index,
                    forceExpanded: _expandAll,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ==========================================================
  // HEADER
  // ==========================================================

  Widget _buildHeading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: StudyColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                'STRUCTURE INSPECTOR',
                style: StudyTypography.eyebrow.copyWith(
                  color: StudyColors.primary,
                  fontSize: 9.5,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            const SizedBox(width: 9),
            _buildReadOnlyBadge(),
          ],
        ),
        const SizedBox(height: 9),
        Text(
          'Content Structure',
          style: StudyTypography.heroTitle.copyWith(
            color: StudyColors.textPrimary,
            fontSize: 30,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          'Inspect the complete hierarchy parsed from the imported '
          'CSP11 competency package before editing or publishing.',
          style: StudyTypography.bodySecondary.copyWith(
            fontSize: 14.5,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: StudyColors.surfaceSoft,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: StudyColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.visibility_outlined,
            size: 13,
            color: StudyColors.textSecondary,
          ),
          const SizedBox(width: 5),
          Text(
            'READ ONLY',
            style: StudyTypography.caption.copyWith(
              color: StudyColors.textSecondary,
              fontWeight: FontWeight.w800,
              fontSize: 9,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // COMPETENCY
  // ==========================================================

  Widget _buildCompetencyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: StudyColors.surface,
        borderRadius: StudyRadius.large,
        border: Border.all(color: StudyColors.border),
        boxShadow: StudyShadows.soft,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 650;

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildCompetencyIcon(),
                    const SizedBox(width: 14),
                    Expanded(child: _buildCompetencyIdentity()),
                  ],
                ),
                const SizedBox(height: 14),
                _buildStatusBadge(),
              ],
            );
          }

          return Row(
            children: [
              _buildCompetencyIcon(),
              const SizedBox(width: 14),
              Expanded(child: _buildCompetencyIdentity()),
              const SizedBox(width: 14),
              _buildStatusBadge(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCompetencyIcon() {
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: StudyColors.primary.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        Icons.account_tree_rounded,
        color: StudyColors.primary,
        size: 24,
      ),
    );
  }

  Widget _buildCompetencyIdentity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'COMPETENCY',
          style: StudyTypography.eyebrow.copyWith(
            color: StudyColors.textSecondary,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content!.title.isEmpty ? 'Untitled Competency' : content!.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: StudyTypography.sectionTitle.copyWith(
            color: StudyColors.textPrimary,
            fontSize: 19,
          ),
        ),
        const SizedBox(height: 5),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            _metadataChip(Icons.tag_rounded, content!.competencyId),
            _metadataChip(Icons.layers_outlined, content!.domainId),
            _metadataChip(
              Icons.numbers_rounded,
              'C${content!.competencyNumber}',
            ),
          ],
        ),
      ],
    );
  }

  Widget _metadataChip(IconData icon, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: StudyColors.surfaceSoft,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: StudyColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: StudyColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            value.isEmpty ? 'Not assigned' : value,
            style: StudyTypography.caption.copyWith(
              color: StudyColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    final status = content!.status.trim().isEmpty ? 'draft' : content!.status;

    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 7, color: color),
          const SizedBox(width: 7),
          Text(
            status.toUpperCase(),
            style: StudyTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'published':
        return StudyColors.success;
      case 'review':
        return StudyColors.info;
      case 'archived':
        return StudyColors.textSecondary;
      default:
        return StudyColors.warning;
    }
  }

  // ==========================================================
  // INSPECTOR TOOLBAR
  // ==========================================================

  Widget _buildInspectorToolbar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: StudyColors.surfaceSoft,
        borderRadius: StudyRadius.medium,
        border: Border.all(color: StudyColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 650;

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildToolbarLabel(),
                const SizedBox(height: 10),
                _buildToolbarActions(),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: _buildToolbarLabel()),
              _buildToolbarActions(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildToolbarLabel() {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: StudyColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.account_tree_outlined,
            size: 16,
            color: StudyColors.primary,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hierarchy Controls',
                style: StudyTypography.label.copyWith(
                  color: StudyColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Control the visibility of the content tree.',
                style: StudyTypography.caption.copyWith(
                  color: StudyColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToolbarActions() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: _collapseAll,
          icon: const Icon(Icons.unfold_less_rounded, size: 17),
          label: const Text('Collapse All'),
        ),
        FilledButton.icon(
          onPressed: _expandAllContent,
          icon: const Icon(Icons.unfold_more_rounded, size: 17),
          label: const Text('Expand All'),
        ),
      ],
    );
  }

  void _expandAllContent() {
    setState(() {
      _expandAll = true;
      _structureRefreshKey++;
    });
  }

  void _collapseAll() {
    setState(() {
      _expandAll = false;
      _structureRefreshKey++;
    });
  }

  // ==========================================================
  // STRUCTURE SUMMARY
  // ==========================================================

  Widget _buildStructureSummary() {
    final topics = _topicCount();
    final blocks = _blockCount();
    final objectives = _objectiveCount();
    final entries = _entryCount();
    final quizzes = _quizCount();

    final metrics = [
      _StructureMetric(
        Icons.account_tree_outlined,
        content!.subtopics.length,
        'Subtopics',
      ),
      _StructureMetric(Icons.flag_outlined, objectives, 'Objectives'),
      _StructureMetric(Icons.menu_book_outlined, topics, 'Main Topics'),
      _StructureMetric(Icons.view_agenda_outlined, blocks, 'Blocks'),
      _StructureMetric(Icons.article_outlined, entries, 'Entries'),
      _StructureMetric(Icons.quiz_outlined, quizzes, 'Quiz References'),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        var columns = 2;

        if (width >= 1050) {
          columns = 6;
        } else if (width >= 780) {
          columns = 3;
        } else if (width >= 500) {
          columns = 2;
        }

        final itemWidth = (width - ((columns - 1) * 10)) / columns;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: metrics
              .map(
                (metric) => SizedBox(width: itemWidth, child: _metric(metric)),
              )
              .toList(),
        );
      },
    );
  }

  Widget _metric(_StructureMetric metric) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: StudyColors.surface,
        borderRadius: StudyRadius.medium,
        border: Border.all(color: StudyColors.border),
        boxShadow: StudyShadows.soft,
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: StudyColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(metric.icon, size: 17, color: StudyColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${metric.value}',
                  style: StudyTypography.sectionTitle.copyWith(
                    color: StudyColors.textPrimary,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  metric.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: StudyTypography.caption.copyWith(
                    color: StudyColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // HIERARCHY HEADER
  // ==========================================================

  Widget _buildHierarchyHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CONTENT HIERARCHY',
                style: StudyTypography.eyebrow.copyWith(
                  color: StudyColors.textSecondary,
                  fontSize: 9.5,
                  letterSpacing: 0.9,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${content!.subtopics.length} '
                '${content!.subtopics.length == 1 ? 'subtopic' : 'subtopics'} '
                'detected',
                style: StudyTypography.sectionTitle.copyWith(
                  color: StudyColors.textPrimary,
                  fontSize: 17,
                ),
              ),
            ],
          ),
        ),
        _buildHierarchyLegend(),
      ],
    );
  }

  Widget _buildHierarchyLegend() {
    return Wrap(
      spacing: 6,
      runSpacing: 5,
      alignment: WrapAlignment.end,
      children: [
        _legendItem(Icons.account_tree_outlined, 'Subtopic'),
        _legendItem(Icons.menu_book_outlined, 'Topic'),
        _legendItem(Icons.view_agenda_outlined, 'Block'),
      ],
    );
  }

  Widget _legendItem(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: StudyColors.surfaceSoft,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: StudyColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: StudyColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: StudyTypography.caption.copyWith(
              color: StudyColors.textSecondary,
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // EMPTY STATES
  // ==========================================================

  Widget _buildNoSubtopics() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: StudyColors.surface,
        borderRadius: StudyRadius.large,
        border: Border.all(color: StudyColors.border),
        boxShadow: StudyShadows.soft,
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: StudyColors.warning.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.account_tree_outlined,
              size: 28,
              color: StudyColors.warning,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No subtopics detected',
            style: StudyTypography.sectionTitle.copyWith(
              color: StudyColors.textPrimary,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'The imported competency does not currently contain '
            'any subtopics.',
            textAlign: TextAlign.center,
            style: StudyTypography.bodySecondary.copyWith(
              fontSize: 13.5,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 520),
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: StudyColors.surface,
            borderRadius: StudyRadius.large,
            border: Border.all(color: StudyColors.border),
            boxShadow: StudyShadows.soft,
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: StudyColors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.account_tree_outlined,
                  size: 32,
                  color: StudyColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No imported content',
                style: StudyTypography.sectionTitle.copyWith(
                  color: StudyColors.textPrimary,
                  fontSize: 19,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                'Import a complete CSP11 competency package first. '
                'The parsed hierarchy will appear here.',
                textAlign: TextAlign.center,
                style: StudyTypography.bodySecondary.copyWith(
                  fontSize: 13.5,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // STATISTICS
  // ==========================================================

  int _objectiveCount() {
    return content!.subtopics.fold<int>(
      0,
      (total, subtopic) => total + subtopic.learningObjectives.length,
    );
  }

  int _topicCount() {
    return content!.subtopics.fold<int>(
      0,
      (total, subtopic) => total + subtopic.mainContent.length,
    );
  }

  int _blockCount() {
    return content!.subtopics.fold<int>(
      0,
      (total, subtopic) =>
          total +
          subtopic.mainContent.fold<int>(
            0,
            (topicTotal, topic) => topicTotal + topic.blocks.length,
          ),
    );
  }

  int _entryCount() {
    return content!.subtopics.fold<int>(
      0,
      (total, subtopic) =>
          total +
          subtopic.keyPoints.length +
          subtopic.examples.length +
          subtopic.caseStudies.length +
          subtopic.formulas.length +
          subtopic.references.length +
          subtopic.examTips.length +
          subtopic.commonMistakes.length +
          subtopic.keyTakeaways.length,
    );
  }

  int _quizCount() {
    return content!.subtopics.fold<int>(0, (total, subtopic) {
      final topicQuizCount = subtopic.mainContent.fold<int>(
        0,
        (topicTotal, topic) => topicTotal + topic.quizzes.length,
      );

      return total + subtopic.quizzes.length + topicQuizCount;
    });
  }
}

// ============================================================
// SUPPORTING MODEL
// ============================================================

class _StructureMetric {
  final IconData icon;
  final int value;
  final String label;

  const _StructureMetric(this.icon, this.value, this.label);
}
