import 'package:flutter/material.dart';

import '../../../../../models/study_content.dart';
import '../../../../../theme/study/study_colors.dart';
import '../../../../../theme/study/study_radius.dart';
import '../../../../../theme/study/study_shadows.dart';
import '../../../../../theme/study/study_typography.dart';

/// Admin editor for a single MainContentTopic.
///
/// Responsibilities:
/// - Edit the topic title.
/// - Display existing content-block count.
/// - Display existing quiz references.
/// - Preserve existing blocks and quizzes when saving.
/// - Return a new immutable MainContentTopic through [onSave].
///
/// This widget intentionally does not edit ContentBlocks.
/// ContentBlock editing will be handled by the dedicated
/// Content Block Editor later.
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

  bool _showAdvanced = false;

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(text: widget.topic.title);
  }

  @override
  void didUpdateWidget(covariant MainContentEditorPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.topic.id != widget.topic.id ||
        oldWidget.topic.title != widget.topic.title) {
      _titleController.text = widget.topic.title;
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
                _buildContentSummary(),
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
          _buildTopicStatus(),
        ],
      ),
    );
  }

  Widget _buildTopicStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: StudyColors.infoLight,
        borderRadius: StudyRadius.pillRadius,
        border: Border.all(color: StudyColors.info.withValues(alpha: 0.15)),
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

  // ==========================================================
  // IDENTITY
  // ==========================================================

  Widget _buildIdentitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('TOPIC IDENTITY', Icons.fingerprint_rounded),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 680;

            final idCard = _buildMetadataCard(
              label: 'CONTENT ID',
              value: widget.topic.id,
              icon: Icons.tag_rounded,
            );

            final blockCard = _buildMetadataCard(
              label: 'CONTENT BLOCKS',
              value: '${widget.topic.blocks.length}',
              icon: Icons.view_agenda_rounded,
            );

            final quizCard = _buildMetadataCard(
              label: 'QUIZ REFERENCES',
              value: '${widget.topic.quizzes.length}',
              icon: Icons.quiz_rounded,
            );

            if (compact) {
              return Column(
                children: [
                  idCard,
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: blockCard),
                      const SizedBox(width: 10),
                      Expanded(child: quizCard),
                    ],
                  ),
                ],
              );
            }

            return Row(
              children: [
                Expanded(flex: 2, child: idCard),
                const SizedBox(width: 10),
                Expanded(child: blockCard),
                const SizedBox(width: 10),
                Expanded(child: quizCard),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildMetadataCard({
    required String label,
    required String value,
    required IconData icon,
  }) {
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

  // ==========================================================
  // TITLE
  // ==========================================================

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('TOPIC TITLE', Icons.title_rounded),
        const SizedBox(height: 12),
        TextField(
          controller: _titleController,
          textInputAction: TextInputAction.done,
          maxLines: 2,
          minLines: 1,
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

  // ==========================================================
  // CONTENT SUMMARY
  // ==========================================================

  Widget _buildContentSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('CONTENT BLOCKS', Icons.view_agenda_rounded),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
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
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: StudyColors.successLight,
                      borderRadius: StudyRadius.small,
                    ),
                    child: const Icon(
                      Icons.layers_rounded,
                      color: StudyColors.success,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.topic.blocks.length} content blocks',
                          style: StudyTypography.label.copyWith(fontSize: 13),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.topic.blocks.isEmpty
                              ? 'No content blocks have been added yet.'
                              : 'Existing content blocks will be preserved.',
                          style: StudyTypography.bodySecondary.copyWith(
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildCountBadge(
                    widget.topic.blocks.length,
                    StudyColors.success,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildBlockTypeSummary(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBlockTypeSummary() {
    if (widget.topic.blocks.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: StudyColors.background,
          borderRadius: StudyRadius.small,
          border: Border.all(color: StudyColors.border),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 17,
              color: StudyColors.textSecondary,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Content blocks can be created in the Content Block Editor.',
                style: StudyTypography.bodySecondary,
              ),
            ),
          ],
        ),
      );
    }

    final counts = <String, int>{};

    for (final block in widget.topic.blocks) {
      counts[block.type] = (counts[block.type] ?? 0) + 1;
    }

    final entries = counts.entries.toList();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: entries.map((entry) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: StudyColors.background,
            borderRadius: StudyRadius.pillRadius,
            border: Border.all(color: StudyColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatBlockType(entry.key),
                style: StudyTypography.label.copyWith(fontSize: 10),
              ),
              const SizedBox(width: 6),
              Text(
                '${entry.value}',
                style: StudyTypography.label.copyWith(
                  color: StudyColors.primary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _formatBlockType(String type) {
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

  // ==========================================================
  // QUIZ SUMMARY
  // ==========================================================

  Widget _buildQuizSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('QUIZ REFERENCES', Icons.quiz_rounded),
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
              ? _buildNoQuizState()
              : _buildQuizReferences(),
        ),
      ],
    );
  }

  Widget _buildNoQuizState() {
    return const Row(
      children: [
        Icon(Icons.quiz_outlined, size: 20, color: StudyColors.textSecondary),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'No quiz is linked directly to this main content topic.',
            style: StudyTypography.bodySecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildQuizReferences() {
    return Column(
      children: [
        Row(
          children: [
            const Icon(Icons.link_rounded, size: 19, color: StudyColors.info),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                '${widget.topic.quizzes.length} existing quiz reference'
                '${widget.topic.quizzes.length == 1 ? '' : 's'}',
                style: StudyTypography.label.copyWith(fontSize: 12),
              ),
            ),
            _buildCountBadge(widget.topic.quizzes.length, StudyColors.info),
          ],
        ),
        const SizedBox(height: 12),
        for (var index = 0; index < widget.topic.quizzes.length; index++)
          _buildQuizReferenceRow(widget.topic.quizzes[index], index),
      ],
    );
  }

  Widget _buildQuizReferenceRow(QuizReference quiz, int index) {
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
                  _buildAdvancedRow('Stable ID', widget.topic.id),
                  const SizedBox(height: 9),
                  _buildAdvancedRow(
                    'Block Count',
                    '${widget.topic.blocks.length}',
                  ),
                  const SizedBox(height: 9),
                  _buildAdvancedRow(
                    'Quiz Count',
                    '${widget.topic.quizzes.length}',
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAdvancedRow(String label, String value) {
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
            label: const Text('Save Main Content'),
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // HELPERS
  // ==========================================================

  Widget _buildSectionLabel(String label, IconData icon) {
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

  Widget _buildCountBadge(int count, Color color) {
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

  // ==========================================================
  // SAVE
  // ==========================================================

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
      blocks: List<ContentBlock>.from(widget.topic.blocks),
      quizzes: List<QuizReference>.from(widget.topic.quizzes),
    );

    widget.onSave(updatedTopic);
  }
}
