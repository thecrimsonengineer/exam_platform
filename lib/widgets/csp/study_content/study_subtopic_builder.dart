import 'package:flutter/material.dart';

import '../../../theme/study/study_colors.dart';
import '../../../theme/study/study_radius.dart';
import '../../../theme/study/study_shadows.dart';
import '../../../theme/study/study_typography.dart';

class StudySubtopicBuilder extends StatefulWidget {
  const StudySubtopicBuilder({super.key});

  @override
  State<StudySubtopicBuilder> createState() => _StudySubtopicBuilderState();
}

class _StudySubtopicBuilderState extends State<StudySubtopicBuilder> {
  final List<_SubtopicDraft> _subtopics = [];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 24),
        _buildSummary(),
        const SizedBox(height: 20),
        _buildSubtopicList(),
      ],
    );
  }

  // ==========================================================
  // HEADER
  // ==========================================================

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SUBTOPIC BUILDER',
                style: StudyTypography.eyebrow.copyWith(
                  color: StudyColors.primary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Build the learning structure',
                style: StudyTypography.heroTitle.copyWith(
                  color: StudyColors.textPrimary,
                  fontSize: 30,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                'Create, edit and reorder the subtopics '
                'within this competency.',
                style: StudyTypography.bodySecondary.copyWith(fontSize: 14.5),
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        FilledButton.icon(
          onPressed: _addSubtopic,
          icon: const Icon(Icons.add_rounded, size: 19),
          label: const Text('Add Subtopic'),
          style: FilledButton.styleFrom(
            backgroundColor: StudyColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: StudyRadius.medium),
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // SUMMARY
  // ==========================================================

  Widget _buildSummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: StudyColors.surface,
        borderRadius: StudyRadius.large,
        border: Border.all(color: StudyColors.border),
        boxShadow: StudyShadows.soft,
      ),
      child: Row(
        children: [
          _buildSummaryItem(
            icon: Icons.account_tree_rounded,
            label: 'SUBTOPICS',
            value: '${_subtopics.length}',
            color: StudyColors.primary,
          ),
          const SizedBox(width: 14),
          _buildSummaryItem(
            icon: Icons.menu_book_rounded,
            label: 'CONTENT TOPICS',
            value: '${_contentTopicCount()}',
            color: StudyColors.accent,
          ),
          const SizedBox(width: 14),
          _buildSummaryItem(
            icon: Icons.quiz_rounded,
            label: 'QUIZZES',
            value: '${_quizCount()}',
            color: StudyColors.examTip,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: StudyRadius.medium,
          border: Border.all(color: color.withValues(alpha: 0.10)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: StudyRadius.small,
              ),
              child: Icon(icon, size: 19, color: color),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: StudyTypography.eyebrow.copyWith(
                      color: color,
                      fontSize: 8,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(value, style: StudyTypography.subSectionTitle),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // SUBTOPIC LIST
  // ==========================================================

  Widget _buildSubtopicList() {
    if (_subtopics.isEmpty) {
      return _buildEmptyState();
    }

    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _subtopics.length,

      // Flutter 3.41+ replacement for deprecated onReorder.
      onReorderItem: (oldIndex, newIndex) {
        _reorderSubtopics(oldIndex, newIndex);
      },

      buildDefaultDragHandles: false,
      itemBuilder: (context, index) {
        final subtopic = _subtopics[index];

        return Padding(
          key: ValueKey(subtopic.id),
          padding: const EdgeInsets.only(bottom: 14),
          child: _buildSubtopicCard(subtopic, index),
        );
      },
    );
  }

  // ==========================================================
  // SUBTOPIC CARD
  // ==========================================================

  Widget _buildSubtopicCard(_SubtopicDraft subtopic, int index) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: StudyColors.surface,
        borderRadius: StudyRadius.large,
        border: Border.all(color: StudyColors.border),
        boxShadow: StudyShadows.soft,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
            decoration: BoxDecoration(
              color: StudyColors.surfaceSoft,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              border: Border(bottom: BorderSide(color: StudyColors.border)),
            ),
            child: Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: StudyColors.primaryLight,
                      borderRadius: StudyRadius.medium,
                    ),
                    child: const Icon(
                      Icons.drag_indicator_rounded,
                      color: StudyColors.primary,
                      size: 21,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: StudyColors.primary,
                    borderRadius: StudyRadius.medium,
                  ),
                  child: Text(
                    '${index + 1}'.padLeft(2, '0'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SUBTOPIC ${index + 1}',
                        style: StudyTypography.eyebrow.copyWith(
                          color: StudyColors.primary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtopic.title.isEmpty
                            ? 'Untitled Subtopic'
                            : subtopic.title,
                        style: StudyTypography.subSectionTitle,
                      ),
                    ],
                  ),
                ),
                _buildMoreMenu(subtopic, index),
              ],
            ),
          ),
          _buildSubtopicDetails(subtopic),
        ],
      ),
    );
  }

  Widget _buildSubtopicDetails(_SubtopicDraft subtopic) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              _buildDetail(
                Icons.flag_outlined,
                'OBJECTIVES',
                subtopic.objectives.length,
              ),
              const SizedBox(width: 10),
              _buildDetail(
                Icons.push_pin_outlined,
                'KEY POINTS',
                subtopic.keyPoints.length,
              ),
              const SizedBox(width: 10),
              _buildDetail(
                Icons.menu_book_outlined,
                'TOPICS',
                subtopic.contentTopics,
              ),
              const SizedBox(width: 10),
              _buildDetail(Icons.quiz_outlined, 'QUIZZES', subtopic.quizzes),
            ],
          ),
          if (subtopic.description.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: StudyColors.surfaceSoft,
                borderRadius: StudyRadius.medium,
                border: Border.all(color: StudyColors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.notes_rounded,
                    size: 18,
                    color: StudyColors.textSecondary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      subtopic.description,
                      style: StudyTypography.bodySecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetail(IconData icon, String label, int value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: StudyColors.surfaceSoft,
          borderRadius: StudyRadius.small,
          border: Border.all(color: StudyColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 17, color: StudyColors.textSecondary),
            const SizedBox(height: 5),
            Text('$value', style: StudyTypography.cardTitle),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: StudyTypography.eyebrow.copyWith(
                fontSize: 7,
                color: StudyColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // MORE MENU
  // ==========================================================

  Widget _buildMoreMenu(_SubtopicDraft subtopic, int index) {
    return PopupMenuButton<String>(
      tooltip: 'Subtopic actions',
      icon: const Icon(
        Icons.more_vert_rounded,
        color: StudyColors.textSecondary,
      ),
      shape: RoundedRectangleBorder(borderRadius: StudyRadius.medium),
      onSelected: (value) {
        switch (value) {
          case 'edit':
            _editSubtopic(subtopic);
            break;

          case 'duplicate':
            _duplicateSubtopic(index);
            break;

          case 'delete':
            _deleteSubtopic(index);
            break;
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: 'edit',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.edit_rounded, size: 19),
            title: Text('Edit'),
          ),
        ),
        PopupMenuItem(
          value: 'duplicate',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.copy_rounded, size: 19),
            title: Text('Duplicate'),
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.delete_outline_rounded, size: 19),
            title: Text('Delete'),
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // EMPTY STATE
  // ==========================================================

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 50),
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
              color: StudyColors.primaryLight,
              borderRadius: StudyRadius.large,
            ),
            child: const Icon(
              Icons.account_tree_rounded,
              size: 30,
              color: StudyColors.primary,
            ),
          ),
          const SizedBox(height: 18),
          Text('No subtopics yet', style: StudyTypography.sectionTitle),
          const SizedBox(height: 7),
          const Text(
            'Start building this competency by adding '
            'your first subtopic.',
            textAlign: TextAlign.center,
            style: StudyTypography.bodySecondary,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _addSubtopic,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add First Subtopic'),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // ADD SUBTOPIC
  // ==========================================================

  Future<void> _addSubtopic() async {
    final result = await _showSubtopicEditor();

    if (result == null) {
      return;
    }

    setState(() {
      _subtopics.add(result);
    });

    _showSavedMessage('Subtopic added');
  }

  // ==========================================================
  // EDIT SUBTOPIC
  // ==========================================================

  Future<void> _editSubtopic(_SubtopicDraft subtopic) async {
    final result = await _showSubtopicEditor(existing: subtopic);

    if (result == null) {
      return;
    }

    final index = _subtopics.indexWhere((item) => item.id == subtopic.id);

    if (index == -1) {
      return;
    }

    setState(() {
      _subtopics[index] = result;
    });

    _showSavedMessage('Subtopic updated');
  }

  // ==========================================================
  // DUPLICATE
  // ==========================================================

  void _duplicateSubtopic(int index) {
    final original = _subtopics[index];

    final duplicate = original.copyWith(
      id: _generateId(),
      title: '${original.title} Copy',
    );

    setState(() {
      _subtopics.insert(index + 1, duplicate);
    });

    _showSavedMessage('Subtopic duplicated');
  }

  // ==========================================================
  // DELETE
  // ==========================================================

  Future<void> _deleteSubtopic(int index) async {
    final subtopic = _subtopics[index];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Subtopic?'),
          content: Text(
            'Delete "${subtopic.title.isEmpty ? 'Untitled Subtopic' : subtopic.title}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: StudyColors.warning,
              ),
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _subtopics.removeAt(index);
    });

    _showSavedMessage('Subtopic deleted');
  }

  // ==========================================================
  // REORDER
  // ==========================================================

  void _reorderSubtopics(int oldIndex, int newIndex) {
    setState(() {
      final item = _subtopics.removeAt(oldIndex);

      _subtopics.insert(newIndex, item);
    });
  }

  // ==========================================================
  // EDITOR DIALOG
  // ==========================================================

  Future<_SubtopicDraft?> _showSubtopicEditor({
    _SubtopicDraft? existing,
  }) async {
    final titleController = TextEditingController(text: existing?.title ?? '');

    final descriptionController = TextEditingController(
      text: existing?.description ?? '',
    );

    final objectiveController = TextEditingController();

    final keyPointController = TextEditingController();

    final objectives = List<String>.from(existing?.objectives ?? []);

    final keyPoints = List<String>.from(existing?.keyPoints ?? []);

    return showDialog<_SubtopicDraft>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 760,
                  maxHeight: 760,
                ),
                child: Column(
                  children: [
                    _buildEditorDialogHeader(
                      context,
                      existing == null ? 'Add Subtopic' : 'Edit Subtopic',
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDialogField(
                              controller: titleController,
                              label: 'Subtopic Title',
                              hint: 'Enter subtopic title',
                              required: true,
                            ),
                            const SizedBox(height: 18),
                            _buildDialogField(
                              controller: descriptionController,
                              label: 'Description',
                              hint: 'Optional short description',
                              maxLines: 3,
                            ),
                            const SizedBox(height: 24),
                            _buildListEditor(
                              title: 'Learning Objectives',
                              eyebrow: 'WHAT THE LEARNER SHOULD ACHIEVE',
                              icon: Icons.flag_rounded,
                              items: objectives,
                              controller: objectiveController,
                              hint: 'Enter learning objective',
                              onAdd: () {
                                final value = objectiveController.text.trim();

                                if (value.isEmpty) {
                                  return;
                                }

                                setDialogState(() {
                                  objectives.add(value);
                                  objectiveController.clear();
                                });
                              },
                              onDelete: (index) {
                                setDialogState(() {
                                  objectives.removeAt(index);
                                });
                              },
                            ),
                            const SizedBox(height: 24),
                            _buildListEditor(
                              title: 'Key Points',
                              eyebrow: 'HIGH-VALUE CONCEPTS',
                              icon: Icons.push_pin_rounded,
                              items: keyPoints,
                              controller: keyPointController,
                              hint: 'Enter key point',
                              onAdd: () {
                                final value = keyPointController.text.trim();

                                if (value.isEmpty) {
                                  return;
                                }

                                setDialogState(() {
                                  keyPoints.add(value);
                                  keyPointController.clear();
                                });
                              },
                              onDelete: (index) {
                                setDialogState(() {
                                  keyPoints.removeAt(index);
                                });
                              },
                            ),
                            const SizedBox(height: 24),
                            _buildComingSections(),
                          ],
                        ),
                      ),
                    ),
                    _buildDialogActions(
                      context,
                      titleController,
                      descriptionController,
                      objectives,
                      keyPoints,
                      existing,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEditorDialogHeader(BuildContext context, String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 18, 16, 18),
      decoration: BoxDecoration(
        color: StudyColors.surfaceSoft,
        border: Border(bottom: BorderSide(color: StudyColors.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: StudyColors.primaryLight,
              borderRadius: StudyRadius.medium,
            ),
            child: const Icon(
              Icons.account_tree_rounded,
              color: StudyColors.primary,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: StudyTypography.subSectionTitle)),
          IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool required = false,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        hintText: hint,
        filled: true,
        fillColor: StudyColors.surfaceSoft,
        border: OutlineInputBorder(
          borderRadius: StudyRadius.medium,
          borderSide: const BorderSide(color: StudyColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: StudyRadius.medium,
          borderSide: const BorderSide(color: StudyColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: StudyRadius.medium,
          borderSide: const BorderSide(color: StudyColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildListEditor({
    required String title,
    required String eyebrow,
    required IconData icon,
    required List<String> items,
    required TextEditingController controller,
    required String hint,
    required VoidCallback onAdd,
    required void Function(int index) onDelete,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: StudyColors.surfaceSoft,
        borderRadius: StudyRadius.large,
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
                  color: StudyColors.primaryLight,
                  borderRadius: StudyRadius.medium,
                ),
                child: Icon(icon, color: StudyColors.primary, size: 19),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eyebrow,
                      style: StudyTypography.eyebrow.copyWith(
                        color: StudyColors.primary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(title, style: StudyTypography.cardTitle),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: StudyColors.surface,
                  borderRadius: StudyRadius.pillRadius,
                  border: Border.all(color: StudyColors.border),
                ),
                child: Text(
                  '${items.length}',
                  style: StudyTypography.label.copyWith(
                    color: StudyColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (items.isNotEmpty)
            ...items.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: StudyColors.surface,
                    borderRadius: StudyRadius.medium,
                    border: Border.all(color: StudyColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: StudyColors.primaryLight,
                          borderRadius: StudyRadius.small,
                        ),
                        child: Text(
                          '${entry.key + 1}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: StudyColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(entry.value, style: StudyTypography.body),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          onDelete(entry.key);
                        },
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: StudyColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  onSubmitted: (_) => onAdd(),
                  decoration: InputDecoration(
                    hintText: hint,
                    filled: true,
                    fillColor: StudyColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: StudyRadius.medium,
                      borderSide: const BorderSide(color: StudyColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: StudyRadius.medium,
                      borderSide: const BorderSide(color: StudyColors.border),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 50,
                child: FilledButton(
                  onPressed: onAdd,
                  child: const Icon(Icons.add_rounded),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComingSections() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: StudyColors.primaryLight,
        borderRadius: StudyRadius.large,
        border: Border.all(color: StudyColors.primary.withValues(alpha: 0.12)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('NEXT CONTENT LAYERS', style: StudyTypography.eyebrow),
          SizedBox(height: 8),
          Text(
            'Main Content Topics • Content Blocks • '
            'Examples • Case Studies • Formulas • '
            'References • Exam Tips • Common Mistakes • '
            'Key Takeaways • Quizzes',
            style: StudyTypography.bodySecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildDialogActions(
    BuildContext context,
    TextEditingController titleController,
    TextEditingController descriptionController,
    List<String> objectives,
    List<String> keyPoints,
    _SubtopicDraft? existing,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 14),
      decoration: BoxDecoration(
        color: StudyColors.surface,
        border: Border(top: BorderSide(color: StudyColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: () {
              final title = titleController.text.trim();

              if (title.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enter a subtopic title.')),
                );
                return;
              }

              final result = _SubtopicDraft(
                id: existing?.id ?? _generateId(),
                title: title,
                description: descriptionController.text.trim(),
                objectives: List<String>.from(objectives),
                keyPoints: List<String>.from(keyPoints),
                contentTopics: existing?.contentTopics ?? 0,
                quizzes: existing?.quizzes ?? 0,
              );

              Navigator.pop(context, result);
            },
            icon: const Icon(Icons.check_rounded, size: 18),
            label: Text(existing == null ? 'Create Subtopic' : 'Save Changes'),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // HELPERS
  // ==========================================================

  int _contentTopicCount() {
    return _subtopics.fold(0, (total, item) => total + item.contentTopics);
  }

  int _quizCount() {
    return _subtopics.fold(0, (total, item) => total + item.quizzes);
  }

  String _generateId() {
    return 'subtopic_${DateTime.now().microsecondsSinceEpoch}';
  }

  void _showSavedMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}

// ============================================================
// DRAFT MODEL
// ============================================================

class _SubtopicDraft {
  final String id;
  final String title;
  final String description;
  final List<String> objectives;
  final List<String> keyPoints;
  final int contentTopics;
  final int quizzes;

  const _SubtopicDraft({
    required this.id,
    required this.title,
    required this.description,
    required this.objectives,
    required this.keyPoints,
    required this.contentTopics,
    required this.quizzes,
  });

  _SubtopicDraft copyWith({
    String? id,
    String? title,
    String? description,
    List<String>? objectives,
    List<String>? keyPoints,
    int? contentTopics,
    int? quizzes,
  }) {
    return _SubtopicDraft(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      objectives: objectives ?? List<String>.from(this.objectives),
      keyPoints: keyPoints ?? List<String>.from(this.keyPoints),
      contentTopics: contentTopics ?? this.contentTopics,
      quizzes: quizzes ?? this.quizzes,
    );
  }
}
