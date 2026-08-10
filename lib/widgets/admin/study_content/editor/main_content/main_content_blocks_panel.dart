import 'package:flutter/material.dart';

import '../../../../../models/study_content.dart';
import '../../../../../theme/study/study_colors.dart';
import '../../../../../theme/study/study_radius.dart';
import '../../../../../theme/study/study_shadows.dart';
import '../../../../../theme/study/study_typography.dart';

/// Displays and manages the ContentBlocks belonging to one
/// MainContentTopic.
///
/// This widget deliberately does not mutate MainContentTopic.
/// The parent editor owns the immutable content state and receives
/// changes through callbacks.
///
/// Responsibilities:
/// - Display content blocks
/// - Select a block
/// - Request block editing
/// - Request duplication
/// - Request movement
/// - Request deletion
/// - Request creation of a new block
class MainContentBlocksPanel extends StatelessWidget {
  final List<ContentBlock> blocks;

  final int? selectedIndex;

  final ValueChanged<int>? onBlockSelected;

  final ValueChanged<int>? onEditBlock;

  final ValueChanged<int>? onDuplicateBlock;

  final ValueChanged<int>? onMoveBlockUp;

  final ValueChanged<int>? onMoveBlockDown;

  final ValueChanged<int>? onDeleteBlock;

  final VoidCallback? onAddBlock;

  const MainContentBlocksPanel({
    super.key,
    required this.blocks,
    this.selectedIndex,
    this.onBlockSelected,
    this.onEditBlock,
    this.onDuplicateBlock,
    this.onMoveBlockUp,
    this.onMoveBlockDown,
    this.onDeleteBlock,
    this.onAddBlock,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: StudyColors.surface,
        borderRadius: StudyRadius.large,
        border: Border.all(color: StudyColors.border),
        boxShadow: StudyShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          Padding(
            padding: const EdgeInsets.all(18),
            child: blocks.isEmpty ? _buildEmptyState() : _buildBlockList(),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // HEADER
  // ==========================================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: StudyColors.surfaceSoft,
        border: Border(bottom: BorderSide(color: StudyColors.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: StudyColors.primaryLight,
              borderRadius: StudyRadius.medium,
            ),
            child: const Icon(
              Icons.view_agenda_rounded,
              color: StudyColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Content Blocks',
                  style: StudyTypography.subSectionTitle,
                ),
                const SizedBox(height: 3),
                Text(
                  '${blocks.length} block${blocks.length == 1 ? '' : 's'} in this topic',
                  style: StudyTypography.bodySecondary,
                ),
              ],
            ),
          ),
          _buildBlockCountBadge(),
        ],
      ),
    );
  }

  Widget _buildBlockCountBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: StudyColors.primaryLight,
        borderRadius: StudyRadius.pillRadius,
      ),
      child: Text(
        '${blocks.length}',
        style: StudyTypography.label.copyWith(
          color: StudyColors.primary,
          fontSize: 11,
        ),
      ),
    );
  }

  // ==========================================================
  // EMPTY STATE
  // ==========================================================

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: StudyColors.surfaceSoft,
        borderRadius: StudyRadius.medium,
        border: Border.all(color: StudyColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: StudyColors.primaryLight,
              borderRadius: StudyRadius.medium,
            ),
            child: const Icon(
              Icons.layers_clear_rounded,
              size: 28,
              color: StudyColors.primary,
            ),
          ),
          const SizedBox(height: 14),
          const Text('No content blocks yet', style: StudyTypography.cardTitle),
          const SizedBox(height: 7),
          const Text(
            'Start building this topic by adding your first learning block.',
            textAlign: TextAlign.center,
            style: StudyTypography.bodySecondary,
          ),
          if (onAddBlock != null) ...[
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onAddBlock,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add Content Block'),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================================
  // BLOCK LIST
  // ==========================================================

  Widget _buildBlockList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < blocks.length; index++)
          _buildBlockCard(blocks[index], index),
        const SizedBox(height: 14),
        _buildAddBlockButton(),
      ],
    );
  }

  // ==========================================================
  // BLOCK CARD
  // ==========================================================

  Widget _buildBlockCard(ContentBlock block, int index) {
    final isSelected = selectedIndex == index;

    final isFirst = index == 0;

    final isLast = index == blocks.length - 1;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: index == blocks.length - 1 ? 0 : 10),
      decoration: BoxDecoration(
        color: isSelected ? StudyColors.primaryLight : StudyColors.surfaceSoft,
        borderRadius: StudyRadius.medium,
        border: Border.all(
          color: isSelected
              ? StudyColors.primary.withValues(alpha: 0.22)
              : StudyColors.border,
          width: isSelected ? 1.2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onBlockSelected == null
              ? null
              : () {
                  onBlockSelected!(index);
                },
          borderRadius: StudyRadius.medium,
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildIndexBadge(index, isSelected),
                    const SizedBox(width: 11),
                    Expanded(child: _buildBlockInformation(block)),
                    const SizedBox(width: 10),
                    _buildSelectionIndicator(isSelected),
                  ],
                ),
                const SizedBox(height: 12),
                _buildActionRow(index: index, isFirst: isFirst, isLast: isLast),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIndexBadge(int index, bool selected) {
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? StudyColors.primary : StudyColors.background,
        borderRadius: StudyRadius.small,
      ),
      child: Text(
        '${index + 1}',
        style: StudyTypography.label.copyWith(
          color: selected ? Colors.white : StudyColors.primary,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildBlockInformation(ContentBlock block) {
    final title = _blockTitle(block);

    final description = _blockDescription(block);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: StudyColors.background,
                borderRadius: StudyRadius.pillRadius,
                border: Border.all(color: StudyColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _iconForType(block.type),
                    size: 13,
                    color: StudyColors.primary,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _formatType(block.type),
                    style: StudyTypography.label.copyWith(
                      color: StudyColors.primary,
                      fontSize: 9.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: StudyTypography.label.copyWith(fontSize: 12),
        ),
        if (description.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: StudyTypography.bodySecondary.copyWith(
              fontSize: 10.5,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSelectionIndicator(bool selected) {
    return Icon(
      selected ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
      size: 19,
      color: selected ? StudyColors.primary : StudyColors.textSecondary,
    );
  }

  // ==========================================================
  // ACTIONS
  // ==========================================================

  Widget _buildActionRow({
    required int index,
    required bool isFirst,
    required bool isLast,
  }) {
    return Container(
      padding: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: StudyColors.border)),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          _actionButton(
            icon: Icons.edit_rounded,
            label: 'Edit',
            onPressed: onEditBlock == null
                ? null
                : () {
                    onEditBlock!(index);
                  },
          ),
          _actionButton(
            icon: Icons.content_copy_rounded,
            label: 'Duplicate',
            onPressed: onDuplicateBlock == null
                ? null
                : () {
                    onDuplicateBlock!(index);
                  },
          ),
          _actionButton(
            icon: Icons.arrow_upward_rounded,
            label: 'Move Up',
            onPressed: isFirst || onMoveBlockUp == null
                ? null
                : () {
                    onMoveBlockUp!(index);
                  },
          ),
          _actionButton(
            icon: Icons.arrow_downward_rounded,
            label: 'Move Down',
            onPressed: isLast || onMoveBlockDown == null
                ? null
                : () {
                    onMoveBlockDown!(index);
                  },
          ),
          _actionButton(
            icon: Icons.delete_outline_rounded,
            label: 'Delete',
            destructive: true,
            onPressed: onDeleteBlock == null
                ? null
                : () {
                    onDeleteBlock!(index);
                  },
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    bool destructive = false,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 14),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: destructive
            ? StudyColors.danger
            : StudyColors.textPrimary,
        side: BorderSide(
          color: destructive
              ? StudyColors.danger.withValues(alpha: 0.25)
              : StudyColors.border,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        textStyle: StudyTypography.label.copyWith(fontSize: 9.5),
        shape: RoundedRectangleBorder(borderRadius: StudyRadius.small),
      ),
    );
  }

  Widget _buildAddBlockButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onAddBlock,
        icon: const Icon(Icons.add_rounded, size: 18),
        label: const Text('Add Content Block'),
        style: OutlinedButton.styleFrom(
          foregroundColor: StudyColors.primary,
          side: BorderSide(color: StudyColors.primary.withValues(alpha: 0.35)),
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: StudyRadius.medium),
        ),
      ),
    );
  }

  // ==========================================================
  // BLOCK INFORMATION
  // ==========================================================

  String _blockTitle(ContentBlock block) {
    final title = block.title.trim();

    if (title.isNotEmpty) {
      return title;
    }

    switch (block.type) {
      case 'text':
        return 'Text Content';

      case 'heading':
        return 'Heading';

      case 'image':
        return 'Image';

      case 'table':
        return 'Table';

      case 'formula':
        return 'Formula';

      case 'example':
        return 'Example';

      case 'caseStudy':
        return 'Case Study';

      case 'reference':
        return 'Reference';

      case 'warning':
        return 'Warning';

      case 'examTip':
        return 'Exam Tip';

      case 'remember':
        return 'Remember';

      case 'checklist':
        return 'Checklist';

      case 'quote':
        return 'Quote';

      default:
        return 'Content Block';
    }
  }

  String _blockDescription(ContentBlock block) {
    final text = block.text.trim();

    if (text.isNotEmpty) {
      return text;
    }

    final content = block.content.trim();

    if (content.isNotEmpty) {
      return content;
    }

    final image = block.image?.trim() ?? '';

    if (image.isNotEmpty) {
      return image;
    }

    if (block.type == 'table' && block.rows.isNotEmpty) {
      return '${block.rows.length} table row${block.rows.length == 1 ? '' : 's'}';
    }

    return '';
  }

  String _formatType(String type) {
    if (type.isEmpty) {
      return 'Unknown';
    }

    final spaced = type
        .replaceAllMapped(
          RegExp(r'([a-z])([A-Z])'),
          (match) => '${match.group(1)} ${match.group(2)}',
        )
        .replaceAll('_', ' ')
        .replaceAll('-', ' ');

    return spaced
        .split(' ')
        .map((word) {
          if (word.isEmpty) {
            return word;
          }

          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'text':
        return Icons.notes_rounded;

      case 'heading':
        return Icons.title_rounded;

      case 'image':
        return Icons.image_rounded;

      case 'table':
        return Icons.table_chart_rounded;

      case 'formula':
        return Icons.functions_rounded;

      case 'example':
        return Icons.lightbulb_rounded;

      case 'caseStudy':
        return Icons.cases_rounded;

      case 'reference':
        return Icons.menu_book_rounded;

      case 'warning':
        return Icons.warning_rounded;

      case 'examTip':
        return Icons.tips_and_updates_rounded;

      case 'remember':
        return Icons.psychology_rounded;

      case 'checklist':
        return Icons.checklist_rounded;

      case 'quote':
        return Icons.format_quote_rounded;

      default:
        return Icons.view_agenda_rounded;
    }
  }
}
