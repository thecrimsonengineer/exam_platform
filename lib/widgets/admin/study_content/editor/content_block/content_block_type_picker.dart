import 'package:flutter/material.dart';

import '../../../../../theme/study/study_colors.dart';
import '../../../../../theme/study/study_radius.dart';
import '../../../../../theme/study/study_shadows.dart';
import '../../../../../theme/study/study_typography.dart';

/// Reusable picker for creating a new ContentBlock.
///
/// The picker only selects the block type. It does not create or save
/// the ContentBlock itself. The parent decides how the selected type
/// should be converted into a new block and passed to the editor.
class ContentBlockTypePicker extends StatelessWidget {
  final ValueChanged<String> onTypeSelected;
  final VoidCallback? onCancel;

  const ContentBlockTypePicker({
    super.key,
    required this.onTypeSelected,
    this.onCancel,
  });

  static const List<_ContentBlockTypeDefinition> _types = [
    _ContentBlockTypeDefinition(
      type: 'text',
      title: 'Text',
      description: 'Standard explanatory learning content.',
      icon: Icons.notes_rounded,
    ),
    _ContentBlockTypeDefinition(
      type: 'heading',
      title: 'Heading',
      description: 'A section or subsection heading.',
      icon: Icons.title_rounded,
    ),
    _ContentBlockTypeDefinition(
      type: 'image',
      title: 'Image',
      description: 'An instructional image or visual.',
      icon: Icons.image_rounded,
    ),
    _ContentBlockTypeDefinition(
      type: 'table',
      title: 'Table',
      description: 'Structured information arranged in rows and columns.',
      icon: Icons.table_chart_rounded,
    ),
    _ContentBlockTypeDefinition(
      type: 'formula',
      title: 'Formula',
      description: 'A calculation, equation, or mathematical expression.',
      icon: Icons.functions_rounded,
    ),
    _ContentBlockTypeDefinition(
      type: 'example',
      title: 'Example',
      description: 'A practical example explaining a concept.',
      icon: Icons.lightbulb_rounded,
    ),
    _ContentBlockTypeDefinition(
      type: 'caseStudy',
      title: 'Case Study',
      description: 'A realistic scenario for applied learning.',
      icon: Icons.cases_rounded,
    ),
    _ContentBlockTypeDefinition(
      type: 'reference',
      title: 'Reference',
      description: 'Supporting reference or source information.',
      icon: Icons.menu_book_rounded,
    ),
    _ContentBlockTypeDefinition(
      type: 'warning',
      title: 'Warning',
      description: 'Important caution or risk-related information.',
      icon: Icons.warning_rounded,
    ),
    _ContentBlockTypeDefinition(
      type: 'examTip',
      title: 'Exam Tip',
      description: 'A focused point to help with exam preparation.',
      icon: Icons.tips_and_updates_rounded,
    ),
    _ContentBlockTypeDefinition(
      type: 'remember',
      title: 'Remember',
      description: 'A key fact or concept worth retaining.',
      icon: Icons.psychology_rounded,
    ),
    _ContentBlockTypeDefinition(
      type: 'checklist',
      title: 'Checklist',
      description: 'A sequence of items for review or verification.',
      icon: Icons.checklist_rounded,
    ),
    _ContentBlockTypeDefinition(
      type: 'quote',
      title: 'Quote',
      description: 'A highlighted quotation or statement.',
      icon: Icons.format_quote_rounded,
    ),
  ];

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
            padding: const EdgeInsets.all(20),
            child: _buildGrid(context),
          ),
          if (onCancel != null) _buildFooter(),
        ],
      ),
    );
  }

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
              Icons.add_box_rounded,
              color: StudyColors.primary,
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Content Block',
                  style: StudyTypography.subSectionTitle,
                ),
                SizedBox(height: 3),
                Text(
                  'Choose the type of learning block you want to create.',
                  style: StudyTypography.bodySecondary,
                ),
              ],
            ),
          ),
          _buildCountBadge(),
        ],
      ),
    );
  }

  Widget _buildCountBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: StudyColors.primaryLight,
        borderRadius: StudyRadius.pillRadius,
      ),
      child: Text(
        '${_types.length} TYPES',
        style: StudyTypography.label.copyWith(
          color: StudyColors.primary,
          fontSize: 9,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _buildGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int columns;

        if (constraints.maxWidth >= 1100) {
          columns = 3;
        } else if (constraints.maxWidth >= 700) {
          columns = 2;
        } else {
          columns = 1;
        }

        final spacing = 12.0;
        final itemWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: _types.map((definition) {
            return SizedBox(
              width: itemWidth,
              child: _buildTypeCard(context, definition),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildTypeCard(
    BuildContext context,
    _ContentBlockTypeDefinition definition,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          onTypeSelected(definition.type);
        },
        borderRadius: StudyRadius.medium,
        child: Ink(
          decoration: BoxDecoration(
            color: StudyColors.surfaceSoft,
            borderRadius: StudyRadius.medium,
            border: Border.all(color: StudyColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: StudyColors.primaryLight,
                    borderRadius: StudyRadius.small,
                  ),
                  child: Icon(
                    definition.icon,
                    size: 20,
                    color: StudyColors.primary,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              definition.title,
                              style: StudyTypography.label.copyWith(
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: StudyColors.textSecondary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        definition.description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: StudyTypography.bodySecondary.copyWith(
                          fontSize: 10.5,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Select a block type to continue to the block editor.',
              style: StudyTypography.bodySecondary,
            ),
          ),
          const SizedBox(width: 14),
          OutlinedButton.icon(
            onPressed: onCancel,
            icon: const Icon(Icons.close_rounded, size: 17),
            label: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

/// Internal definition used by the picker UI.
class _ContentBlockTypeDefinition {
  final String type;
  final String title;
  final String description;
  final IconData icon;

  const _ContentBlockTypeDefinition({
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
  });
}
