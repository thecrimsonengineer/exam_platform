import 'package:flutter/material.dart';

import '../../../../models/study_content.dart';
import '../../../../theme/study/study_colors.dart';
import '../../../../theme/study/study_radius.dart';
import '../../../../theme/study/study_typography.dart';

class ContentBlockStructureCard extends StatelessWidget {
  final ContentBlock block;
  final int index;

  const ContentBlockStructureCard({
    super.key,
    required this.block,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final typeLabel = _formatType(block.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: StudyColors.background,
        borderRadius: StudyRadius.medium,
        border: Border.all(color: StudyColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIndex(),
            const SizedBox(width: 12),
            Expanded(child: _buildContent(typeLabel)),
          ],
        ),
      ),
    );
  }

  Widget _buildIndex() {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: StudyColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        '${index + 1}'.padLeft(2, '0'),
        style: StudyTypography.label.copyWith(
          color: StudyColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildContent(String typeLabel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _typeIcon(),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                typeLabel,
                style: StudyTypography.label.copyWith(
                  color: StudyColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          block.id.isEmpty ? 'No block ID' : block.id,
          style: StudyTypography.caption.copyWith(
            color: StudyColors.textSecondary,
          ),
        ),
        if (_previewText().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            _previewText(),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: StudyTypography.bodySecondary.copyWith(
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
      ],
    );
  }

  Widget _typeIcon() {
    IconData icon;

    switch (block.type.toLowerCase()) {
      case 'heading':
        icon = Icons.title_rounded;
        break;
      case 'image':
        icon = Icons.image_rounded;
        break;
      case 'table':
        icon = Icons.table_chart_rounded;
        break;
      case 'formula':
        icon = Icons.functions_rounded;
        break;
      case 'example':
        icon = Icons.lightbulb_outline_rounded;
        break;
      case 'caseStudy':
      case 'casestudy':
        icon = Icons.business_center_outlined;
        break;
      case 'reference':
        icon = Icons.link_rounded;
        break;
      case 'warning':
        icon = Icons.warning_amber_rounded;
        break;
      case 'examTip':
      case 'examtip':
        icon = Icons.school_rounded;
        break;
      case 'remember':
        icon = Icons.bookmark_rounded;
        break;
      case 'checklist':
        icon = Icons.checklist_rounded;
        break;
      case 'quote':
        icon = Icons.format_quote_rounded;
        break;
      default:
        icon = Icons.article_outlined;
    }

    return Icon(icon, size: 18, color: StudyColors.primary);
  }

  String _previewText() {
    final data = block.data;

    final candidates = [
      data['title'],
      data['content'],
      data['text'],
      data['description'],
      data['value'],
    ];

    for (final value in candidates) {
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }

    return '';
  }

  String _formatType(String value) {
    if (value.trim().isEmpty) {
      return 'Content Block';
    }

    final normalized = value.replaceAll('_', ' ').replaceAll('-', ' ').trim();

    return normalized
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}
