import 'package:flutter/material.dart';

import '../../../models/study_content.dart';

/// Central renderer for all CSP study-content blocks.
///
/// The renderer is intentionally tolerant of missing or incomplete data.
/// Unknown block types are ignored rather than causing the student screen
/// to fail.
class ContentBlockRenderer extends StatelessWidget {
  final ContentBlock block;

  const ContentBlockRenderer({
    super.key,
    required this.block,
  });

  @override
  Widget build(BuildContext context) {
    switch (block.type) {
      case 'text':
        return _buildText(context);

      case 'heading':
        return _buildHeading(context);

      case 'image':
        return _buildImage(context);

      case 'table':
        return _buildTable(context);

      case 'formula':
        return _buildFormula(context);

      case 'caseStudy':
        return _buildCaseStudy(context);

      case 'reference':
        return _buildReference(context);

      case 'warning':
        return _buildWarning(context);

      case 'examTip':
        return _buildExamTip(context);

      case 'remember':
        return _buildRemember(context);

      case 'checklist':
        return _buildChecklist(context);

      case 'quote':
        return _buildQuote(context);

      default:
        return const SizedBox.shrink();
    }
  }

  // ==========================================================
  // Text
  // ==========================================================

  Widget _buildText(BuildContext context) {
    final text = block.content.trim();

    if (text.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          height: 1.6,
        ),
      ),
    );
  }

  // ==========================================================
  // Heading
  // ==========================================================

  Widget _buildHeading(BuildContext context) {
    final text = block.text.trim();

    if (text.isEmpty) {
      return const SizedBox.shrink();
    }

    final int level = block.level.clamp(1, 6);

    double fontSize;

    switch (level) {
      case 1:
        fontSize = 26;
        break;
      case 2:
        fontSize = 22;
        break;
      case 3:
        fontSize = 20;
        break;
      case 4:
        fontSize = 18;
        break;
      case 5:
        fontSize = 17;
        break;
      default:
        fontSize = 16;
    }

    return Padding(
      padding: const EdgeInsets.only(
        top: 10,
        bottom: 10,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          height: 1.3,
        ),
      ),
    );
  }

  // ==========================================================
  // Image
  // ==========================================================

  Widget _buildImage(BuildContext context) {
    final imagePath = block.image;

    // If no image has been added, nothing is displayed.
    if (imagePath == null || imagePath.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(
        top: 8,
        bottom: 18,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          imagePath,
          width: double.infinity,
          fit: BoxFit.contain,
          errorBuilder: (
            BuildContext context,
            Object error,
            StackTrace? stackTrace,
          ) {
            // A missing image must never break the study screen.
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  // ==========================================================
  // Table
  // ==========================================================

  Widget _buildTable(BuildContext context) {
    final columns = block.columns;
    final rows = block.rows;

    if (columns.isEmpty || rows.isEmpty) {
      return const SizedBox.shrink();
    }

    final title = block.title.trim();

    return Padding(
      padding: const EdgeInsets.only(
        top: 8,
        bottom: 18,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) ...[
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
          ],
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 28,
              headingRowHeight: 48,
              dataRowMinHeight: 48,
              dataRowMaxHeight: 100,
              columns: columns
                  .map(
                    (column) => DataColumn(
                      label: Text(
                        column,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              rows: rows.map((row) {
                final cells = List<String>.generate(
                  columns.length,
                  (index) {
                    if (index < row.length) {
                      return row[index];
                    }

                    return '';
                  },
                );

                return DataRow(
                  cells: cells
                      .map(
                        (cell) => DataCell(
                          Text(
                            cell,
                            style: const TextStyle(
                              fontSize: 14,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // Formula
  // ==========================================================

  Widget _buildFormula(BuildContext context) {
    final formula = block.content.trim();

    if (formula.isEmpty) {
      return const SizedBox.shrink();
    }

    final title = block.title.trim();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(
        top: 8,
        bottom: 18,
      ),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade100,
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) ...[
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
          ],
          Center(
            child: Text(
              formula,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontFamily: 'monospace',
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // Case Study
  // ==========================================================

  Widget _buildCaseStudy(BuildContext context) {
    return _buildInformationCard(
      context,
      title: block.title,
      content: block.content,
      icon: Icons.business_center_outlined,
    );
  }

  // ==========================================================
  // Reference
  // ==========================================================

  Widget _buildReference(BuildContext context) {
    // Reference-specific information is stored in the flexible
    // ContentBlock.data map rather than as direct ContentBlock fields.
    final source = block.data['source']?.toString().trim() ?? '';
    final url = block.data['url']?.toString().trim() ?? '';
    final title = block.title.trim();
    final content = block.content.trim();

    if (source.isEmpty &&
        url.isEmpty &&
        title.isEmpty &&
        content.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(
        top: 8,
        bottom: 18,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade100,
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.menu_book_outlined),
              SizedBox(width: 8),
              Text(
                'Reference',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (title.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (source.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(source),
          ],
          if (content.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(content),
          ],
          if (url.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              url,
              style: TextStyle(
                color: Colors.blue.shade700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================================
  // Warning
  // ==========================================================

  Widget _buildWarning(BuildContext context) {
    return _buildInformationCard(
      context,
      title: block.title.isEmpty ? 'Important' : block.title,
      content: block.content,
      icon: Icons.warning_amber_rounded,
    );
  }

  // ==========================================================
  // Exam Tip
  // ==========================================================

  Widget _buildExamTip(BuildContext context) {
    return _buildInformationCard(
      context,
      title: block.title.isEmpty ? 'Exam Tip' : block.title,
      content: block.content,
      icon: Icons.lightbulb_outline,
    );
  }

  // ==========================================================
  // Remember
  // ==========================================================

  Widget _buildRemember(BuildContext context) {
    return _buildInformationCard(
      context,
      title: block.title.isEmpty ? 'Remember' : block.title,
      content: block.content,
      icon: Icons.bookmark_outline,
    );
  }

  // ==========================================================
  // Checklist
  // ==========================================================

  Widget _buildChecklist(BuildContext context) {
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
      margin: const EdgeInsets.only(
        top: 8,
        bottom: 18,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) ...[
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
          ],
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_box_outlined,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.4,
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

  // ==========================================================
  // Quote
  // ==========================================================

  Widget _buildQuote(BuildContext context) {
    final quote = block.content.trim();

    if (quote.isEmpty) {
      return const SizedBox.shrink();
    }

    final title = block.title.trim();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(
        top: 8,
        bottom: 18,
      ),
      padding: const EdgeInsets.fromLTRB(
        18,
        16,
        18,
        16,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade100,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) ...[
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            '“$quote”',
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // Shared Information Card
  // ==========================================================

  Widget _buildInformationCard(
    BuildContext context, {
    required String title,
    required String content,
    required IconData icon,
  }) {
    final cleanTitle = title.trim();
    final cleanContent = content.trim();

    if (cleanTitle.isEmpty && cleanContent.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(
        top: 8,
        bottom: 18,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (cleanTitle.isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  size: 21,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    cleanTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          if (cleanContent.isNotEmpty) ...[
            if (cleanTitle.isNotEmpty)
              const SizedBox(height: 10),
            Text(
              cleanContent,
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}