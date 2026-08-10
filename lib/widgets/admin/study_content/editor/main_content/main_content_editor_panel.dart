import 'package:flutter/material.dart';

import '../../../../../models/study_content.dart';
import '../../../../../theme/study/study_colors.dart';
import '../../../../../theme/study/study_radius.dart';
import '../../../../../theme/study/study_shadows.dart';
import '../../../../../theme/study/study_typography.dart';
import '../content_block/content_block_editor_panel.dart';
import '../content_block/content_block_type_picker.dart';
import 'main_content_blocks_panel.dart';

/// Admin editor for one MainContentTopic.
///
/// This editor changes the topic title while preserving the existing
/// content blocks and quiz references. Content blocks will be edited by
/// the dedicated Content Block Editor in the next stage.
class MainContentEditorPanel extends StatefulWidget {
  final MainContentTopic topic;
  final ValueChanged<MainContentTopic> onSave;
  final VoidCallback? onCancel;

  const MainContentEditorPanel({
    super.key,
    required this.topic,
    required this.onSave,
    this.onCancel,
  });

  @override
  State<MainContentEditorPanel> createState() => _MainContentEditorPanelState();
}

class _MainContentEditorPanelState extends State<MainContentEditorPanel> {
  late final TextEditingController _titleController;
  late List<ContentBlock> _blocks;
  bool _showAdvanced = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.topic.title);
    _blocks = List<ContentBlock>.from(widget.topic.blocks);
  }

  @override
  void didUpdateWidget(covariant MainContentEditorPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.topic.id != widget.topic.id ||
        oldWidget.topic.title != widget.topic.title) {
      _titleController.text = widget.topic.title;
    }

    if (oldWidget.topic.id != widget.topic.id ||
        oldWidget.topic.blocks != widget.topic.blocks) {
      _blocks = List<ContentBlock>.from(widget.topic.blocks);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
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
                _buildIdentitySection(),
                const SizedBox(height: 20),
                _buildTitleSection(),
                const SizedBox(height: 20),
                _buildContentBlocksSection(),
                const SizedBox(height: 20),
                _buildQuizSummary(),
                const SizedBox(height: 20),
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
              Icons.menu_book_rounded,
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
                  'Main Content Editor',
                  style: StudyTypography.subSectionTitle,
                ),
                SizedBox(height: 3),
                Text(
                  'Edit the topic while preserving its existing content.',
                  style: StudyTypography.bodySecondary,
                ),
              ],
            ),
          ),
          _buildEditingBadge(),
        ],
      ),
    );
  }

  Widget _buildEditingBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: StudyColors.infoLight,
        borderRadius: StudyRadius.pillRadius,
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.edit_rounded, size: 14, color: StudyColors.info),
          SizedBox(width: 6),
          Text(
            'EDITING',
            style: TextStyle(
              color: StudyColors.info,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('TOPIC IDENTITY', Icons.fingerprint_rounded),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 680;
            final id = _metadataCard(
              'CONTENT ID',
              widget.topic.id,
              Icons.tag_rounded,
            );
            final blocks = _metadataCard(
              'CONTENT BLOCKS',
              '${_blocks.length}',
              Icons.view_agenda_rounded,
            );
            final quizzes = _metadataCard(
              'QUIZ REFERENCES',
              '${widget.topic.quizzes.length}',
              Icons.quiz_rounded,
            );

            if (compact) {
              return Column(
                children: [
                  id,
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: blocks),
                      const SizedBox(width: 10),
                      Expanded(child: quizzes),
                    ],
                  ),
                ],
              );
            }

            return Row(
              children: [
                Expanded(flex: 2, child: id),
                const SizedBox(width: 10),
                Expanded(child: blocks),
                const SizedBox(width: 10),
                Expanded(child: quizzes),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _metadataCard(String label, String value, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: StudyColors.surfaceSoft,
        borderRadius: StudyRadius.medium,
        border: Border.all(color: StudyColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: StudyColors.primaryLight,
              borderRadius: StudyRadius.small,
            ),
            child: Icon(icon, size: 17, color: StudyColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: StudyTypography.eyebrow.copyWith(fontSize: 8.5),
                ),
                const SizedBox(height: 3),
                Text(
                  value.isEmpty ? 'Not assigned' : value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: StudyTypography.label.copyWith(fontSize: 11.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('TOPIC TITLE', Icons.title_rounded),
        const SizedBox(height: 12),
        TextField(
          controller: _titleController,
          textInputAction: TextInputAction.done,
          minLines: 1,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: 'Main Content Topic Title',
            hintText: 'Enter the main content topic title',
            prefixIcon: const Icon(Icons.menu_book_rounded),
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
        ),
        const SizedBox(height: 7),
        Text(
          'The title identifies this topic within the selected subtopic.',
          style: StudyTypography.bodySecondary.copyWith(fontSize: 10.5),
        ),
      ],
    );
  }

  Widget _buildContentBlocksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('CONTENT BLOCKS', Icons.view_agenda_rounded),
        const SizedBox(height: 12),
        MainContentBlocksPanel(
          blocks: _blocks,
          selectedIndex: null,
          onBlockSelected: (index) {},
          onEditBlock: _editBlock,
          onDuplicateBlock: _duplicateBlock,
          onMoveBlockUp: _moveBlockUp,
          onMoveBlockDown: _moveBlockDown,
          onDeleteBlock: _deleteBlock,
          onAddBlock: _showBlockTypePicker,
        ),
      ],
    );
  }

  // ==========================================================
  // CONTENT BLOCK WORKFLOW
  // ==========================================================

  Future<void> _showBlockTypePicker() async {
    final selectedType = await showDialog<String>(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(24),
          backgroundColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000, maxHeight: 760),
            child: ContentBlockTypePicker(
              onTypeSelected: (type) {
                Navigator.of(context).pop(type);
              },
              onCancel: () {
                Navigator.of(context).pop();
              },
            ),
          ),
        );
      },
    );

    if (!mounted || selectedType == null) {
      return;
    }

    final newBlock = ContentBlock(
      id: _generateBlockId(selectedType),
      type: selectedType,
      data: _initialBlockData(selectedType),
    );

    setState(() {
      _blocks = List<ContentBlock>.from(_blocks)..add(newBlock);
    });

    await _editBlock(_blocks.length - 1);
  }

  Future<void> _editBlock(int index) async {
    if (index < 0 || index >= _blocks.length) {
      return;
    }

    final block = _blocks[index];

    final updatedBlock = await showDialog<ContentBlock>(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(20),
          backgroundColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000, maxHeight: 900),
            child: SingleChildScrollView(
              child: ContentBlockEditorPanel(
                block: block,
                onSave: (updated) {
                  Navigator.of(context).pop(updated);
                },
                onCancel: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
          ),
        );
      },
    );

    if (!mounted || updatedBlock == null) {
      return;
    }

    if (index < 0 || index >= _blocks.length) {
      return;
    }

    setState(() {
      final updatedBlocks = List<ContentBlock>.from(_blocks);
      updatedBlocks[index] = updatedBlock;
      _blocks = updatedBlocks;
    });
  }

  void _duplicateBlock(int index) {
    if (index < 0 || index >= _blocks.length) {
      return;
    }

    final original = _blocks[index];

    final duplicate = ContentBlock(
      id: _generateBlockId(original.type),
      type: original.type,
      data: Map<String, dynamic>.from(original.data),
    );

    setState(() {
      final updatedBlocks = List<ContentBlock>.from(_blocks);
      updatedBlocks.insert(index + 1, duplicate);
      _blocks = updatedBlocks;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Content block duplicated.')));
  }

  void _moveBlockUp(int index) {
    if (index <= 0 || index >= _blocks.length) {
      return;
    }

    setState(() {
      final updatedBlocks = List<ContentBlock>.from(_blocks);
      final current = updatedBlocks.removeAt(index);
      updatedBlocks.insert(index - 1, current);
      _blocks = updatedBlocks;
    });
  }

  void _moveBlockDown(int index) {
    if (index < 0 || index >= _blocks.length - 1) {
      return;
    }

    setState(() {
      final updatedBlocks = List<ContentBlock>.from(_blocks);
      final current = updatedBlocks.removeAt(index);
      updatedBlocks.insert(index + 1, current);
      _blocks = updatedBlocks;
    });
  }

  Future<void> _deleteBlock(int index) async {
    if (index < 0 || index >= _blocks.length) {
      return;
    }

    final block = _blocks[index];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Content Block?'),
          content: Text(
            'This will remove "${_blockDisplayName(block)}" from this Main Content topic. '
            'The change will take effect in the topic editor state and will be saved when you press Save Main Content.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: StudyColors.danger,
              ),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) {
      return;
    }

    setState(() {
      final updatedBlocks = List<ContentBlock>.from(_blocks);
      updatedBlocks.removeAt(index);
      _blocks = updatedBlocks;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Content block deleted.')));
  }

  String _generateBlockId(String type) {
    final safeType = type
        .trim()
        .replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_')
        .toLowerCase();

    final timestamp = DateTime.now().millisecondsSinceEpoch;

    return '${widget.topic.id}_${safeType}_$timestamp';
  }

  Map<String, dynamic> _initialBlockData(String type) {
    switch (type) {
      case 'heading':
        return {'title': '', 'level': 2};

      case 'image':
        return {'image': '', 'title': ''};

      case 'table':
        return {'columns': <String>[], 'rows': <List<String>>[]};

      case 'formula':
        return {'formula': '', 'content': ''};

      case 'example':
      case 'caseStudy':
      case 'reference':
      case 'warning':
      case 'examTip':
      case 'remember':
      case 'quote':
        return {'title': '', 'content': '', 'source': '', 'url': ''};

      case 'checklist':
        return {'title': '', 'content': ''};

      case 'text':
      default:
        return {'text': ''};
    }
  }

  String _blockDisplayName(ContentBlock block) {
    final title = block.title.trim();

    if (title.isNotEmpty) {
      return title;
    }

    if (block.type.trim().isNotEmpty) {
      return block.type;
    }

    return 'Content Block';
  }

  Widget _buildQuizSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('QUIZ REFERENCES', Icons.quiz_rounded),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: StudyColors.surfaceSoft,
            borderRadius: StudyRadius.medium,
            border: Border.all(color: StudyColors.border),
          ),
          child: widget.topic.quizzes.isEmpty
              ? const Row(
                  children: [
                    Icon(
                      Icons.quiz_outlined,
                      size: 20,
                      color: StudyColors.textSecondary,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'No quiz is linked directly to this main content topic.',
                        style: StudyTypography.bodySecondary,
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.link_rounded,
                          size: 19,
                          color: StudyColors.info,
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            '${widget.topic.quizzes.length} quiz reference${widget.topic.quizzes.length == 1 ? '' : 's'}',
                            style: StudyTypography.label.copyWith(fontSize: 12),
                          ),
                        ),
                        _countBadge(
                          widget.topic.quizzes.length,
                          StudyColors.info,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    for (var i = 0; i < widget.topic.quizzes.length; i++)
                      _quizRow(widget.topic.quizzes[i], i),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _quizRow(QuizReference quiz, int index) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: index == 0 ? 0 : 7),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: StudyColors.background,
        borderRadius: StudyRadius.small,
        border: Border.all(color: StudyColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: StudyColors.infoLight,
              borderRadius: StudyRadius.small,
            ),
            child: Text(
              '${index + 1}',
              style: StudyTypography.label.copyWith(
                color: StudyColors.info,
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              quiz.quizId,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: StudyTypography.label.copyWith(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

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
            onTap: () => setState(() => _showAdvanced = !_showAdvanced),
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
                      Icons.settings_outlined,
                      size: 17,
                      color: StudyColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Advanced Information',
                          style: StudyTypography.label,
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Technical content metadata',
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
                children: [
                  const Divider(),
                  const SizedBox(height: 10),
                  _advancedRow('Stable ID', widget.topic.id),
                  const SizedBox(height: 9),
                  _advancedRow('Block Count', '${_blocks.length}'),
                  const SizedBox(height: 9),
                  _advancedRow('Quiz Count', '${widget.topic.quizzes.length}'),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _advancedRow(String label, String value) {
    return Row(
      children: [
        Expanded(child: Text(label, style: StudyTypography.bodySecondary)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: StudyTypography.label.copyWith(fontSize: 11),
          ),
        ),
      ],
    );
  }

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
            label: const Text('Save Main Content'),
          ),
        ),
      ],
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

  Widget _countBadge(int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: StudyRadius.pillRadius,
      ),
      child: Text(
        '$count',
        style: StudyTypography.label.copyWith(color: color, fontSize: 10),
      ),
    );
  }

  void _save() {
    final title = _titleController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Main Content Topic title cannot be empty.'),
        ),
      );
      return;
    }

    final updatedTopic = MainContentTopic(
      id: widget.topic.id,
      title: title,
      blocks: List<ContentBlock>.from(_blocks),
      quizzes: List<QuizReference>.from(widget.topic.quizzes),
    );

    widget.onSave(updatedTopic);
  }
}
