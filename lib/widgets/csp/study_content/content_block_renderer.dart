import 'package:flutter/material.dart';

import '../../../models/study_content.dart';
import '../../../theme/study/study_colors.dart';
import '../../../theme/study/study_icons.dart';
import '../../../theme/study/study_radius.dart';
import '../../../theme/study/study_shadows.dart';
import '../../../theme/study/study_typography.dart';
import 'study_icon_badge.dart';

/// Premium renderer for all CSP Study Content blocks.
///
/// The underlying ContentBlock model remains unchanged.
/// Each supported block type receives its own visual treatment.
class ContentBlockRenderer extends StatelessWidget {
  final ContentBlock block;

  const ContentBlockRenderer({super.key, required this.block});

  @override
  Widget build(BuildContext context) {
    switch (block.type) {
      case 'text':
        return _buildText();

      case 'heading':
        return _buildHeading();

      case 'image':
        return _buildImage();

      case 'table':
        return _buildTable();

      case 'formula':
        return _buildFormula();

      case 'example':
        return _buildExample();

      case 'caseStudy':
        return _buildCaseStudy();

      case 'reference':
        return _buildReference();

      case 'warning':
        return _buildWarning();

      case 'examTip':
        return _buildExamTip();

      case 'remember':
        return _buildRemember();

      case 'checklist':
        return _buildChecklist();

      case 'quote':
        return _buildQuote();

      default:
        return const SizedBox.shrink();
    }
  }

  // ==========================================================
  // TEXT
  // ==========================================================

  Widget _buildText() {
    final text = block.content.trim();

    if (text.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: StudyTypography.bodyLarge),
    );
  }

  // ==========================================================
  // HEADING
  // ==========================================================

  Widget _buildHeading() {
    final text = block.text.trim();

    if (text.isEmpty) {
      return const SizedBox.shrink();
    }

    final level = block.level.clamp(1, 6);

    double fontSize;
    Color accent;
    IconData icon;

    switch (level) {
      case 1:
        fontSize = 27;
        accent = StudyColors.primary;
        icon = StudyIcons.heading;
        break;

      case 2:
        fontSize = 23;
        accent = StudyColors.primary;
        icon = StudyIcons.topic;
        break;

      case 3:
        fontSize = 20;
        accent = StudyColors.accent;
        icon = StudyIcons.topic;
        break;

      case 4:
        fontSize = 18;
        accent = StudyColors.textSecondary;
        icon = StudyIcons.text;
        break;

      case 5:
        fontSize = 17;
        accent = StudyColors.textSecondary;
        icon = StudyIcons.text;
        break;

      default:
        fontSize = 16;
        accent = StudyColors.textSecondary;
        icon = StudyIcons.text;
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12, bottom: 14),
      padding: const EdgeInsets.only(left: 14, top: 8, bottom: 8),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: accent, width: 4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StudyIconBadge(
            icon: icon,
            color: accent,
            backgroundColor: accent.withValues(alpha: 0.08),
            size: level <= 2 ? 38 : 34,
            iconSize: level <= 2 ? 19 : 17,
            showShadow: false,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                  color: StudyColors.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // IMAGE
  // ==========================================================

  Widget _buildImage() {
    final imagePath = block.image;

    if (imagePath == null || imagePath.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8, bottom: 18),
      decoration: BoxDecoration(
        color: StudyColors.surfaceSoft,
        borderRadius: StudyRadius.large,
        border: Border.all(color: StudyColors.border),
        boxShadow: StudyShadows.soft,
      ),
      child: ClipRRect(
        borderRadius: StudyRadius.large,
        child: Container(
          padding: const EdgeInsets.all(10),
          color: StudyColors.surfaceSoft,
          child: Image.asset(
            imagePath,
            width: double.infinity,
            fit: BoxFit.contain,
            errorBuilder:
                (BuildContext context, Object error, StackTrace? stackTrace) {
                  return _buildImageError();
                },
          ),
        ),
      ),
    );
  }

  Widget _buildImageError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 42, horizontal: 20),
      decoration: BoxDecoration(
        color: StudyColors.surface,
        borderRadius: StudyRadius.medium,
      ),
      child: Column(
        children: [
          const StudyIconBadge(
            icon: StudyIcons.image,
            color: StudyColors.textMuted,
            backgroundColor: StudyColors.surfaceSoft,
            size: 52,
            iconSize: 27,
            showShadow: false,
          ),
          const SizedBox(height: 10),
          Text(
            'Image unavailable',
            style: StudyTypography.bodySecondary.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // TABLE
  // ==========================================================

  Widget _buildTable() {
    final columns = block.columns;
    final rows = block.rows;

    if (columns.isEmpty || rows.isEmpty) {
      return const SizedBox.shrink();
    }

    final title = block.title.trim();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8, bottom: 18),
      decoration: BoxDecoration(
        color: StudyColors.surface,
        borderRadius: StudyRadius.large,
        border: Border.all(color: StudyColors.border),
        boxShadow: StudyShadows.soft,
      ),
      child: ClipRRect(
        borderRadius: StudyRadius.large,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title.isNotEmpty)
              _buildBlockHeader(
                icon: StudyIcons.table,
                eyebrow: 'DATA & COMPARISON',
                title: title,
                accent: StudyColors.primary,
                background: StudyColors.primaryLight,
              ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(14),
              child: DataTable(
                columnSpacing: 28,
                headingRowHeight: 48,
                dataRowMinHeight: 48,
                dataRowMaxHeight: 110,
                horizontalMargin: 10,
                dividerThickness: 0.6,
                headingRowColor: WidgetStateProperty.all(
                  StudyColors.primaryLight,
                ),
                columns: columns.map((column) {
                  return DataColumn(
                    label: Text(
                      column,
                      style: StudyTypography.label.copyWith(
                        color: StudyColors.primary,
                      ),
                    ),
                  );
                }).toList(),
                rows: rows.map((row) {
                  final cells = List<String>.generate(columns.length, (index) {
                    if (index < row.length) {
                      return row[index];
                    }

                    return '';
                  });

                  return DataRow(
                    cells: cells.map((cell) {
                      return DataCell(
                        Text(
                          cell,
                          style: StudyTypography.bodySecondary.copyWith(
                            color: StudyColors.textPrimary,
                          ),
                        ),
                      );
                    }).toList(),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // FORMULA
  // ==========================================================

  Widget _buildFormula() {
    final formula = block.content.trim();

    if (formula.isEmpty) {
      return const SizedBox.shrink();
    }

    final title = block.title.trim();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8, bottom: 18),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [StudyColors.primaryLight, StudyColors.surface],
        ),
        borderRadius: StudyRadius.large,
        border: Border.all(color: StudyColors.primary.withValues(alpha: 0.15)),
        boxShadow: StudyShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const StudyIconBadge(
                icon: StudyIcons.formula,
                color: StudyColors.primary,
                backgroundColor: StudyColors.primaryLight,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CALCULATION',
                      style: StudyTypography.eyebrow.copyWith(
                        color: StudyColors.primary,
                      ),
                    ),
                    if (title.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(title, style: StudyTypography.cardTitle),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
            decoration: BoxDecoration(
              color: StudyColors.surface,
              borderRadius: StudyRadius.medium,
              border: Border.all(color: StudyColors.border),
            ),
            child: SelectableText(
              formula,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontFamily: 'monospace',
                height: 1.6,
                fontWeight: FontWeight.w600,
                color: StudyColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // EXAMPLE
  // ==========================================================

  Widget _buildExample() {
    return _buildInformationCard(
      title: block.title.isEmpty ? 'Example' : block.title,
      content: block.content,
      icon: StudyIcons.topic,
      eyebrow: 'EXAMPLE',
      accent: StudyColors.accent,
      background: StudyColors.accentLight,
    );
  }

  // ==========================================================
  // CASE STUDY
  // ==========================================================

  Widget _buildCaseStudy() {
    return _buildInformationCard(
      title: block.title.isEmpty ? 'Case Study' : block.title,
      content: block.content,
      icon: StudyIcons.caseStudy,
      eyebrow: 'CASE STUDY',
      accent: StudyColors.caseStudy,
      background: StudyColors.caseStudyLight,
    );
  }

  // ==========================================================
  // REFERENCE
  // ==========================================================

  Widget _buildReference() {
    final source = block.data['source']?.toString().trim() ?? '';
    final url = block.data['url']?.toString().trim() ?? '';

    final title = block.title.trim();
    final content = block.content.trim();

    if (source.isEmpty && url.isEmpty && title.isEmpty && content.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8, bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: StudyColors.referenceLight,
        borderRadius: StudyRadius.large,
        border: Border.all(
          color: StudyColors.reference.withValues(alpha: 0.16),
        ),
        boxShadow: StudyShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const StudyIconBadge(
                icon: StudyIcons.reference,
                color: StudyColors.reference,
                backgroundColor: StudyColors.surface,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'REFERENCE',
                      style: StudyTypography.eyebrow.copyWith(
                        color: StudyColors.reference,
                      ),
                    ),
                    if (title.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(title, style: StudyTypography.cardTitle),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (source.isNotEmpty) ...[
            const SizedBox(height: 15),
            _buildReferenceRow(label: 'SOURCE', value: source),
          ],
          if (content.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildReferenceRow(label: 'DETAIL', value: content),
          ],
          if (url.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildReferenceRow(
              label: 'LINK',
              value: url,
              valueColor: StudyColors.accent,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReferenceRow({
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: StudyColors.surface.withValues(alpha: 0.75),
        borderRadius: StudyRadius.small,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: StudyTypography.eyebrow.copyWith(
              fontSize: 9,
              color: StudyColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(
            value,
            style: StudyTypography.bodySecondary.copyWith(
              color: valueColor ?? StudyColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // WARNING
  // ==========================================================

  Widget _buildWarning() {
    return _buildInformationCard(
      title: block.title.isEmpty ? 'Important' : block.title,
      content: block.content,
      icon: StudyIcons.warning,
      eyebrow: 'IMPORTANT',
      accent: StudyColors.warning,
      background: StudyColors.warningLight,
    );
  }

  // ==========================================================
  // EXAM TIP
  // ==========================================================

  Widget _buildExamTip() {
    return _buildInformationCard(
      title: block.title.isEmpty ? 'Exam Tip' : block.title,
      content: block.content,
      icon: StudyIcons.examTip,
      eyebrow: 'EXAM FOCUS',
      accent: StudyColors.examTip,
      background: StudyColors.examTipLight,
    );
  }

  // ==========================================================
  // REMEMBER
  // ==========================================================

  Widget _buildRemember() {
    return _buildInformationCard(
      title: block.title.isEmpty ? 'Remember' : block.title,
      content: block.content,
      icon: StudyIcons.remember,
      eyebrow: 'REMEMBER',
      accent: StudyColors.remember,
      background: StudyColors.rememberLight,
    );
  }

  // ==========================================================
  // CHECKLIST
  // ==========================================================

  Widget _buildChecklist() {
    final title = block.title.trim();
    final content = block.content.trim();

    if (title.isEmpty && content.isEmpty) {
      return const SizedBox.shrink();
    }

    final items = content
        .split('\n')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8, bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: StudyColors.surface,
        borderRadius: StudyRadius.large,
        border: Border.all(color: StudyColors.success.withValues(alpha: 0.18)),
        boxShadow: StudyShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const StudyIconBadge(
                icon: StudyIcons.checklist,
                color: StudyColors.success,
                backgroundColor: StudyColors.successLight,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CHECKLIST',
                      style: StudyTypography.eyebrow.copyWith(
                        color: StudyColors.success,
                      ),
                    ),
                    if (title.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(title, style: StudyTypography.cardTitle),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;

            return Padding(
              padding: EdgeInsets.only(
                bottom: index == items.length - 1 ? 0 : 10,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: StudyColors.successLight.withValues(alpha: 0.55),
                  borderRadius: StudyRadius.small,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      StudyIcons.completed,
                      size: 19,
                      color: StudyColors.success,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item,
                        style: StudyTypography.body.copyWith(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ==========================================================
  // QUOTE
  // ==========================================================

  Widget _buildQuote() {
    final quote = block.content.trim();

    if (quote.isEmpty) {
      return const SizedBox.shrink();
    }

    final title = block.title.trim();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8, bottom: 18),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [StudyColors.surfaceSoft, StudyColors.surface],
        ),
        borderRadius: StudyRadius.large,
        border: Border.all(color: StudyColors.border),
        boxShadow: StudyShadows.soft,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StudyIconBadge(
            icon: StudyIcons.quote,
            color: StudyColors.primary,
            backgroundColor: StudyColors.primaryLight,
            size: 44,
            iconSize: 22,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title.isNotEmpty) ...[
                  Text(title, style: StudyTypography.cardTitle),
                  const SizedBox(height: 8),
                ],
                Text(
                  '“$quote”',
                  style: StudyTypography.bodyLarge.copyWith(
                    fontStyle: FontStyle.italic,
                    fontSize: 16,
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
  // SHARED INFORMATION CARD
  // ==========================================================

  Widget _buildInformationCard({
    required String title,
    required String content,
    required IconData icon,
    required String eyebrow,
    required Color accent,
    required Color background,
  }) {
    final cleanTitle = title.trim();
    final cleanContent = content.trim();

    if (cleanTitle.isEmpty && cleanContent.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8, bottom: 18),
      decoration: BoxDecoration(
        color: background,
        borderRadius: StudyRadius.large,
        border: Border.all(color: accent.withValues(alpha: 0.18)),
        boxShadow: StudyShadows.soft,
      ),
      child: ClipRRect(
        borderRadius: StudyRadius.large,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.06),
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
                        Text(cleanTitle, style: StudyTypography.cardTitle),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (cleanContent.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(18),
                child: Text(
                  cleanContent,
                  style: StudyTypography.body.copyWith(fontSize: 15),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // BLOCK HEADER
  // ==========================================================

  Widget _buildBlockHeader({
    required IconData icon,
    required String eyebrow,
    required String title,
    required Color accent,
    required Color background,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      color: background,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          StudyIconBadge(
            icon: icon,
            color: accent,
            backgroundColor: StudyColors.surface,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow,
                  style: StudyTypography.eyebrow.copyWith(color: accent),
                ),
                const SizedBox(height: 3),
                Text(title, style: StudyTypography.cardTitle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
