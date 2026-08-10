import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../../../models/study_content.dart';
import '../../../../../theme/study/study_colors.dart';
import '../../../../../theme/study/study_radius.dart';
import '../../../../../theme/study/study_shadows.dart';
import '../../../../../theme/study/study_typography.dart';

/// Admin editor for a single ContentBlock.
///
/// ContentBlock intentionally remains a generic model:
///
///   id
///   type
///   data
///
/// This editor provides a structured interface for the commonly used
/// block data fields while preserving the original block model.
///
/// Supported block types follow the existing Study Content renderer:
///
/// text
/// heading
/// image
/// table
/// formula
/// example
/// caseStudy
/// reference
/// warning
/// examTip
/// remember
/// checklist
/// quote
class ContentBlockEditorPanel extends StatefulWidget {
  final ContentBlock block;
  final ValueChanged<ContentBlock> onSave;
  final VoidCallback? onCancel;

  const ContentBlockEditorPanel({
    super.key,
    required this.block,
    required this.onSave,
    this.onCancel,
  });

  @override
  State<ContentBlockEditorPanel> createState() =>
      _ContentBlockEditorPanelState();
}

class _ContentBlockEditorPanelState extends State<ContentBlockEditorPanel> {
  static const List<String> _supportedTypes = [
    'text',
    'heading',
    'image',
    'table',
    'formula',
    'example',
    'caseStudy',
    'reference',
    'warning',
    'examTip',
    'remember',
    'checklist',
    'quote',
  ];

  late String _selectedType;

  late final TextEditingController _titleController;
  late final TextEditingController _textController;
  late final TextEditingController _contentController;
  late final TextEditingController _imageController;
  late final TextEditingController _sourceController;
  late final TextEditingController _urlController;
  late final TextEditingController _formulaController;
  late final TextEditingController _columnsController;
  late final TextEditingController _rowsController;

  int _headingLevel = 2;

  bool _showAdvanced = false;

  @override
  void initState() {
    super.initState();

    final initialType = widget.block.type.trim();

    _selectedType = _supportedTypes.contains(initialType)
        ? initialType
        : 'text';

    _titleController = TextEditingController(text: widget.block.title);

    _textController = TextEditingController(text: widget.block.text);

    _contentController = TextEditingController(text: widget.block.content);

    _imageController = TextEditingController(text: widget.block.image ?? '');

    _sourceController = TextEditingController(
      text: _stringValue(widget.block.data['source']),
    );

    _urlController = TextEditingController(
      text: _stringValue(widget.block.data['url']),
    );

    _formulaController = TextEditingController(
      text: _stringValue(widget.block.data['formula']),
    );

    _columnsController = TextEditingController(
      text: widget.block.columns.join(', '),
    );

    _rowsController = TextEditingController(
      text: _rowsToText(widget.block.rows),
    );

    _headingLevel = widget.block.level.clamp(1, 6);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _textController.dispose();
    _contentController.dispose();
    _imageController.dispose();
    _sourceController.dispose();
    _urlController.dispose();
    _formulaController.dispose();
    _columnsController.dispose();
    _rowsController.dispose();

    super.dispose();
  }

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
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBlockIdentity(),
                const SizedBox(height: 22),
                _buildTypeSelector(),
                const SizedBox(height: 22),
                _buildDynamicEditor(),
                const SizedBox(height: 22),
                _buildAdvancedSection(),
                const SizedBox(height: 24),
                _buildActions(),
              ],
            ),
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
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Content Block Editor',
                  style: StudyTypography.subSectionTitle,
                ),
                SizedBox(height: 3),
                Text(
                  'Configure one structured learning block.',
                  style: StudyTypography.bodySecondary,
                ),
              ],
            ),
          ),
          _buildTypeBadge(),
        ],
      ),
    );
  }

  Widget _buildTypeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: StudyColors.primaryLight,
        borderRadius: StudyRadius.pillRadius,
      ),
      child: Text(
        _formatType(_selectedType).toUpperCase(),
        style: StudyTypography.label.copyWith(
          color: StudyColors.primary,
          fontSize: 9.5,
          letterSpacing: 0.7,
        ),
      ),
    );
  }

  // ==========================================================
  // IDENTITY
  // ==========================================================

  Widget _buildBlockIdentity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('BLOCK IDENTITY', Icons.fingerprint_rounded),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: StudyColors.surfaceSoft,
            borderRadius: StudyRadius.medium,
            border: Border.all(color: StudyColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: StudyColors.background,
                  borderRadius: StudyRadius.small,
                ),
                child: const Icon(
                  Icons.tag_rounded,
                  size: 18,
                  color: StudyColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CONTENT BLOCK ID',
                      style: StudyTypography.eyebrow.copyWith(fontSize: 8.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.block.id.isEmpty
                          ? 'Not assigned'
                          : widget.block.id,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: StudyTypography.label.copyWith(fontSize: 11.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // TYPE SELECTOR
  // ==========================================================

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('BLOCK TYPE', Icons.category_rounded),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _selectedType,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Content Block Type',
            prefixIcon: const Icon(Icons.layers_rounded),
            filled: true,
            fillColor: StudyColors.surfaceSoft,
            border: OutlineInputBorder(
              borderRadius: StudyRadius.medium,
              borderSide: BorderSide(color: StudyColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: StudyRadius.medium,
              borderSide: BorderSide(color: StudyColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: StudyRadius.medium,
              borderSide: const BorderSide(
                color: StudyColors.primary,
                width: 1.3,
              ),
            ),
          ),
          items: _supportedTypes.map((type) {
            return DropdownMenuItem<String>(
              value: type,
              child: Row(
                children: [
                  Icon(
                    _iconForType(type),
                    size: 18,
                    color: StudyColors.primary,
                  ),
                  const SizedBox(width: 9),
                  Text(_formatType(type)),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value == null) {
              return;
            }

            setState(() {
              _selectedType = value;
            });
          },
        ),
        const SizedBox(height: 7),
        Text(
          'Changing the type changes the editor fields, but does not discard the existing block until Save is pressed.',
          style: StudyTypography.bodySecondary.copyWith(fontSize: 10.5),
        ),
      ],
    );
  }

  // ==========================================================
  // DYNAMIC EDITOR
  // ==========================================================

  Widget _buildDynamicEditor() {
    switch (_selectedType) {
      case 'heading':
        return _buildHeadingEditor();

      case 'image':
        return _buildImageEditor();

      case 'table':
        return _buildTableEditor();

      case 'formula':
        return _buildFormulaEditor();

      case 'example':
      case 'caseStudy':
      case 'reference':
      case 'warning':
      case 'examTip':
      case 'remember':
      case 'quote':
        return _buildRichContentEditor();

      case 'checklist':
        return _buildChecklistEditor();

      case 'text':
      default:
        return _buildTextEditor();
    }
  }

  // ==========================================================
  // TEXT
  // ==========================================================

  Widget _buildTextEditor() {
    return _editorCard(
      title: 'Text Content',
      icon: Icons.notes_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _textArea(
            controller: _textController,
            label: 'Text',
            hint: 'Enter the learning content for this text block.',
            minLines: 8,
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // HEADING
  // ==========================================================

  Widget _buildHeadingEditor() {
    return _editorCard(
      title: 'Heading',
      icon: Icons.title_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _textField(
            controller: _titleController,
            label: 'Heading Text',
            hint: 'Enter the heading',
            icon: Icons.title_rounded,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            initialValue: _headingLevel,
            decoration: InputDecoration(
              labelText: 'Heading Level',
              prefixIcon: const Icon(Icons.format_size_rounded),
              filled: true,
              fillColor: StudyColors.surfaceSoft,
              border: OutlineInputBorder(
                borderRadius: StudyRadius.medium,
                borderSide: BorderSide(color: StudyColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: StudyRadius.medium,
                borderSide: BorderSide(color: StudyColors.border),
              ),
            ),
            items: List.generate(6, (index) {
              final level = index + 1;

              return DropdownMenuItem<int>(
                value: level,
                child: Text('Heading $level'),
              );
            }),
            onChanged: (value) {
              if (value == null) {
                return;
              }

              setState(() {
                _headingLevel = value;
              });
            },
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // IMAGE
  // ==========================================================

  Widget _buildImageEditor() {
    return _editorCard(
      title: 'Image Block',
      icon: Icons.image_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _textField(
            controller: _imageController,
            label: 'Image Path or URL',
            hint: 'assets/images/example.png or https://...',
            icon: Icons.image_outlined,
          ),
          const SizedBox(height: 16),
          _textField(
            controller: _titleController,
            label: 'Caption / Title',
            hint: 'Optional image caption',
            icon: Icons.subtitles_rounded,
          ),
          const SizedBox(height: 14),
          _infoBox(
            icon: Icons.info_outline_rounded,
            text:
                'The existing renderer reads the image value from the block data. Keep the path or URL compatible with the existing asset strategy.',
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // TABLE
  // ==========================================================

  Widget _buildTableEditor() {
    return _editorCard(
      title: 'Table Block',
      icon: Icons.table_chart_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _textArea(
            controller: _columnsController,
            label: 'Columns',
            hint: 'Column 1, Column 2, Column 3',
            minLines: 2,
          ),
          const SizedBox(height: 16),
          _textArea(
            controller: _rowsController,
            label: 'Rows',
            hint: 'Cell 1 | Cell 2 | Cell 3\nCell 4 | Cell 5 | Cell 6',
            minLines: 6,
          ),
          const SizedBox(height: 10),
          _infoBox(
            icon: Icons.table_rows_rounded,
            text:
                'Use one row per line and separate cells with the | character.',
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // FORMULA
  // ==========================================================

  Widget _buildFormulaEditor() {
    return _editorCard(
      title: 'Formula Block',
      icon: Icons.functions_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _textArea(
            controller: _formulaController,
            label: 'Formula',
            hint: 'Enter the formula representation used by your renderer.',
            minLines: 5,
          ),
          const SizedBox(height: 16),
          _textArea(
            controller: _contentController,
            label: 'Explanation',
            hint: 'Optional explanation of the formula.',
            minLines: 5,
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // RICH CONTENT
  // ==========================================================

  Widget _buildRichContentEditor() {
    return _editorCard(
      title: '${_formatType(_selectedType)} Content',
      icon: _iconForType(_selectedType),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _textField(
            controller: _titleController,
            label: 'Title',
            hint: 'Optional ${_formatType(_selectedType).toLowerCase()} title',
            icon: Icons.title_rounded,
          ),
          const SizedBox(height: 16),
          _textArea(
            controller: _contentController,
            label: 'Content',
            hint:
                'Enter the content for this ${_formatType(_selectedType).toLowerCase()} block.',
            minLines: 8,
          ),
          const SizedBox(height: 16),
          _textField(
            controller: _sourceController,
            label: 'Source',
            hint: 'Optional source',
            icon: Icons.source_rounded,
          ),
          const SizedBox(height: 14),
          _textField(
            controller: _urlController,
            label: 'Reference URL',
            hint: 'Optional URL',
            icon: Icons.link_rounded,
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // CHECKLIST
  // ==========================================================

  Widget _buildChecklistEditor() {
    return _editorCard(
      title: 'Checklist',
      icon: Icons.checklist_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _textField(
            controller: _titleController,
            label: 'Checklist Title',
            hint: 'Optional checklist title',
            icon: Icons.title_rounded,
          ),
          const SizedBox(height: 16),
          _textArea(
            controller: _contentController,
            label: 'Checklist Items',
            hint: 'One checklist item per line.',
            minLines: 8,
          ),
          const SizedBox(height: 10),
          _infoBox(
            icon: Icons.check_circle_outline_rounded,
            text:
                'Enter each checklist item on a separate line. The final renderer can interpret the resulting content according to the existing block schema.',
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // ADVANCED
  // ==========================================================

  Widget _buildAdvancedSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: StudyColors.surfaceSoft,
        borderRadius: StudyRadius.medium,
        border: Border.all(color: StudyColors.border),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _showAdvanced = !_showAdvanced;
              });
            },
            borderRadius: StudyRadius.medium,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: StudyColors.background,
                      borderRadius: StudyRadius.small,
                    ),
                    child: const Icon(
                      Icons.data_object_rounded,
                      size: 17,
                      color: StudyColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Advanced Data', style: StudyTypography.label),
                        SizedBox(height: 2),
                        Text(
                          'Inspect the generated block payload',
                          style: StudyTypography.bodySecondary,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _showAdvanced
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: StudyColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (_showAdvanced)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 10),
                  Text(
                    'Generated data',
                    style: StudyTypography.label.copyWith(fontSize: 11),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxHeight: 280),
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: StudyColors.background,
                      borderRadius: StudyRadius.small,
                      border: Border.all(color: StudyColors.border),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        const JsonEncoder.withIndent(
                          '  ',
                        ).convert(_buildDataPreview()),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          height: 1.45,
                        ),
                      ),
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
  // ACTIONS
  // ==========================================================

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: widget.onCancel,
            icon: const Icon(Icons.close_rounded, size: 17),
            label: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save_rounded, size: 17),
            label: const Text('Save Content Block'),
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // COMMON UI
  // ==========================================================

  Widget _editorCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: StudyColors.surfaceSoft,
        borderRadius: StudyRadius.medium,
        border: Border.all(color: StudyColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: StudyColors.primaryLight,
                  borderRadius: StudyRadius.small,
                ),
                child: Icon(icon, size: 18, color: StudyColors.primary),
              ),
              const SizedBox(width: 10),
              Text(title, style: StudyTypography.subSectionTitle),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: StudyColors.surface,
        border: OutlineInputBorder(
          borderRadius: StudyRadius.medium,
          borderSide: BorderSide(color: StudyColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: StudyRadius.medium,
          borderSide: BorderSide(color: StudyColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: StudyRadius.medium,
          borderSide: const BorderSide(color: StudyColors.primary, width: 1.3),
        ),
      ),
    );
  }

  Widget _textArea({
    required TextEditingController controller,
    required String label,
    required String hint,
    int minLines = 5,
  }) {
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: null,
      keyboardType: TextInputType.multiline,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        alignLabelWithHint: true,
        filled: true,
        fillColor: StudyColors.surface,
        border: OutlineInputBorder(
          borderRadius: StudyRadius.medium,
          borderSide: BorderSide(color: StudyColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: StudyRadius.medium,
          borderSide: BorderSide(color: StudyColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: StudyRadius.medium,
          borderSide: const BorderSide(color: StudyColors.primary, width: 1.3),
        ),
      ),
    );
  }

  Widget _infoBox({required IconData icon, required String text}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: StudyColors.primaryLight,
        borderRadius: StudyRadius.small,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: StudyColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: StudyTypography.bodySecondary.copyWith(fontSize: 10.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 15, color: StudyColors.primary),
        const SizedBox(width: 7),
        Text(
          label,
          style: StudyTypography.eyebrow.copyWith(
            color: StudyColors.primary,
            fontSize: 9,
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // DATA
  // ==========================================================

  Map<String, dynamic> _buildDataPreview() {
    switch (_selectedType) {
      case 'heading':
        return {'title': _titleController.text.trim(), 'level': _headingLevel};

      case 'image':
        return {
          'image': _imageController.text.trim(),
          'title': _titleController.text.trim(),
        };

      case 'table':
        return {'columns': _parseColumns(), 'rows': _parseRows()};

      case 'formula':
        return {
          'formula': _formulaController.text.trim(),
          'content': _contentController.text.trim(),
        };

      case 'example':
      case 'caseStudy':
      case 'reference':
      case 'warning':
      case 'examTip':
      case 'remember':
      case 'quote':
        return {
          'title': _titleController.text.trim(),
          'content': _contentController.text.trim(),
          'source': _sourceController.text.trim(),
          'url': _urlController.text.trim(),
        };

      case 'checklist':
        return {
          'title': _titleController.text.trim(),
          'content': _contentController.text.trim(),
        };

      case 'text':
      default:
        return {'text': _textController.text};
    }
  }

  // ==========================================================
  // SAVE
  // ==========================================================

  void _save() {
    final id = widget.block.id.trim();

    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Content Block ID cannot be empty.')),
      );
      return;
    }

    if (_selectedType == 'text' && _textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Text content cannot be empty.')),
      );
      return;
    }

    final data = _buildDataPreview();

    final updatedBlock = ContentBlock(
      id: id,
      type: _selectedType,
      data: Map<String, dynamic>.from(data),
    );

    widget.onSave(updatedBlock);
  }

  // ==========================================================
  // HELPERS
  // ==========================================================

  String _stringValue(dynamic value) {
    return value?.toString() ?? '';
  }

  List<String> _parseColumns() {
    return _columnsController.text
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  List<List<String>> _parseRows() {
    return _rowsController.text
        .split('\n')
        .map((line) => line.split('|').map((cell) => cell.trim()).toList())
        .where((row) => row.any((cell) => cell.isNotEmpty))
        .toList();
  }

  String _rowsToText(List<List<String>> rows) {
    return rows.map((row) => row.join(' | ')).join('\n');
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
