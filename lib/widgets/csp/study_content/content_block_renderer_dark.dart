import 'package:flutter/material.dart';

import '../../../models/study_content.dart';
import '../../../theme/study/study_colors_dark.dart';
import '../../../theme/study/study_icons.dart';
import '../../../theme/study/study_radius.dart';
import '../../../theme/study/study_shadows.dart';
import '../../../theme/study/study_typography_dark.dart';
import 'study_icon_badge.dart';

extension _ContentBlockView on ContentBlock {
  String get content => data['content']?.toString() ?? '';

  String get text =>
      data['text']?.toString() ?? data['content']?.toString() ?? '';

  String get title => data['title']?.toString() ?? '';

  String get image =>
      data['image']?.toString() ?? data['url']?.toString() ?? '';

  int get level {
    final value = data['level'];

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 1;
  }

  List<String> get columns {
    final value = data['columns'];

    if (value is! List) {
      return const [];
    }

    return value.map((item) => item?.toString() ?? '').toList();
  }

  List<List<String>> get rows {
    final value = data['rows'];

    if (value is! List) {
      return const [];
    }

    return value
        .whereType<List>()
        .map((row) => row.map((item) => item?.toString() ?? '').toList())
        .toList();
  }
}

/// Premium renderer for all CSP Study Content blocks.
///
/// The underlying ContentBlock model remains unchanged.
/// Each supported block type receives its own visual treatment.
class DarkContentBlockRenderer extends StatelessWidget {
  final ContentBlock block;

  const DarkContentBlockRenderer({super.key, required this.block});

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
      child: Text(text, style: DarkStudyTypography.bodyLarge),
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
        accent = DarkStudyColors.primary;
        icon = StudyIcons.heading;
        break;

      case 2:
        fontSize = 23;
        accent = DarkStudyColors.primary;
        icon = StudyIcons.topic;
        break;

      case 3:
        fontSize = 20;
        accent = DarkStudyColors.accent;
        icon = StudyIcons.topic;
        break;

      case 4:
        fontSize = 18;
        accent = DarkStudyColors.textSecondary;
        icon = StudyIcons.text;
        break;

      case 5:
        fontSize = 17;
        accent = DarkStudyColors.textSecondary;
        icon = StudyIcons.text;
        break;

      default:
        fontSize = 16;
        accent = DarkStudyColors.textSecondary;
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
                  color: DarkStudyColors.textPrimary,
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

    if (imagePath.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8, bottom: 18),
      decoration: BoxDecoration(
        color: DarkStudyColors.surfaceSoft.withValues(alpha: 0.54),
        borderRadius: StudyRadius.large,
        border: Border.all(color: DarkStudyColors.border),
        boxShadow: StudyShadows.soft,
      ),
      child: ClipRRect(
        borderRadius: StudyRadius.large,
        child: Container(
          padding: const EdgeInsets.all(10),
          color: DarkStudyColors.surfaceSoft.withValues(alpha: 0.54),
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
        color: DarkStudyColors.surface.withValues(alpha: 0.58),
        borderRadius: StudyRadius.medium,
      ),
      child: Column(
        children: [
          const StudyIconBadge(
            icon: StudyIcons.image,
            color: DarkStudyColors.textMuted,
            backgroundColor: DarkStudyColors.surfaceSoft,
            size: 52,
            iconSize: 27,
            showShadow: false,
          ),
          const SizedBox(height: 10),
          Text(
            'Image unavailable',
            style: DarkStudyTypography.bodySecondary.copyWith(
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
        color: DarkStudyColors.surface.withValues(alpha: 0.58),
        borderRadius: StudyRadius.large,
        border: Border.all(color: DarkStudyColors.border),
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
                accent: DarkStudyColors.primary,
                background: DarkStudyColors.primaryLight,
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
                  DarkStudyColors.primaryLight,
                ),
                columns: columns.map((column) {
                  return DataColumn(
                    label: Text(
                      column,
                      style: DarkStudyTypography.label.copyWith(
                        color: DarkStudyColors.primary,
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
                          style: DarkStudyTypography.bodySecondary.copyWith(
                            color: DarkStudyColors.textPrimary,
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
          colors: [DarkStudyColors.primaryLight, DarkStudyColors.surface],
        ),
        borderRadius: StudyRadius.large,
        border: Border.all(
          color: DarkStudyColors.primary.withValues(alpha: 0.15),
        ),
        boxShadow: StudyShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const StudyIconBadge(
                icon: StudyIcons.formula,
                color: DarkStudyColors.primary,
                backgroundColor: DarkStudyColors.primaryLight,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CALCULATION',
                      style: DarkStudyTypography.eyebrow.copyWith(
                        color: DarkStudyColors.primary,
                      ),
                    ),
                    if (title.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(title, style: DarkStudyTypography.cardTitle),
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
              color: DarkStudyColors.surface.withValues(alpha: 0.58),
              borderRadius: StudyRadius.medium,
              border: Border.all(color: DarkStudyColors.border),
            ),
            child: SelectableText(
              formula,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontFamily: 'monospace',
                height: 1.6,
                fontWeight: FontWeight.w600,
                color: DarkStudyColors.textPrimary,
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
      accent: DarkStudyColors.accent,
      background: DarkStudyColors.accentLight,
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
      accent: DarkStudyColors.caseStudy,
      background: DarkStudyColors.caseStudyLight,
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
        color: DarkStudyColors.referenceLight,
        borderRadius: StudyRadius.large,
        border: Border.all(
          color: DarkStudyColors.reference.withValues(alpha: 0.16),
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
                color: DarkStudyColors.reference,
                backgroundColor: DarkStudyColors.surface,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'REFERENCE',
                      style: DarkStudyTypography.eyebrow.copyWith(
                        color: DarkStudyColors.reference,
                      ),
                    ),
                    if (title.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(title, style: DarkStudyTypography.cardTitle),
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
              valueColor: DarkStudyColors.accent,
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
        color: DarkStudyColors.surface.withValues(alpha: 0.75),
        borderRadius: StudyRadius.small,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: DarkStudyTypography.eyebrow.copyWith(
              fontSize: 9,
              color: DarkStudyColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(
            value,
            style: DarkStudyTypography.bodySecondary.copyWith(
              color: valueColor ?? DarkStudyColors.textPrimary,
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
      accent: DarkStudyColors.warning,
      background: DarkStudyColors.warningLight,
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
      accent: DarkStudyColors.examTip,
      background: DarkStudyColors.examTipLight,
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
      accent: DarkStudyColors.remember,
      background: DarkStudyColors.rememberLight,
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
        color: DarkStudyColors.surface.withValues(alpha: 0.58),
        borderRadius: StudyRadius.large,
        border: Border.all(
          color: DarkStudyColors.success.withValues(alpha: 0.18),
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
                icon: StudyIcons.checklist,
                color: DarkStudyColors.success,
                backgroundColor: DarkStudyColors.successLight,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CHECKLIST',
                      style: DarkStudyTypography.eyebrow.copyWith(
                        color: DarkStudyColors.success,
                      ),
                    ),
                    if (title.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(title, style: DarkStudyTypography.cardTitle),
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
                  color: DarkStudyColors.successLight.withValues(alpha: 0.55),
                  borderRadius: StudyRadius.small,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      StudyIcons.completed,
                      size: 19,
                      color: DarkStudyColors.success,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item,
                        style: DarkStudyTypography.body.copyWith(fontSize: 14),
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
          colors: [DarkStudyColors.surfaceSoft, DarkStudyColors.surface],
        ),
        borderRadius: StudyRadius.large,
        border: Border.all(color: DarkStudyColors.border),
        boxShadow: StudyShadows.soft,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StudyIconBadge(
            icon: StudyIcons.quote,
            color: DarkStudyColors.primary,
            backgroundColor: DarkStudyColors.primaryLight,
            size: 44,
            iconSize: 22,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title.isNotEmpty) ...[
                  Text(title, style: DarkStudyTypography.cardTitle),
                  const SizedBox(height: 8),
                ],
                Text(
                  '“$quote”',
                  style: DarkStudyTypography.bodyLarge.copyWith(
                    fontStyle: FontStyle.italic,
                    fontSize: 16,
                    color: DarkStudyColors.textSecondary,
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
                    backgroundColor: DarkStudyColors.surface,
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
                        Text(cleanTitle, style: DarkStudyTypography.cardTitle),
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
                  style: DarkStudyTypography.body.copyWith(fontSize: 15),
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
            backgroundColor: DarkStudyColors.surface,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow,
                  style: DarkStudyTypography.eyebrow.copyWith(color: accent),
                ),
                const SizedBox(height: 3),
                Text(title, style: DarkStudyTypography.cardTitle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
