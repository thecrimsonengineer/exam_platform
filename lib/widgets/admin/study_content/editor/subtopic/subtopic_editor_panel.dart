import 'package:flutter/material.dart';

import '../../../../../models/study_content.dart';
import '../../../../../theme/study/study_colors.dart';
import '../../../../../theme/study/study_radius.dart';
import '../../../../../theme/study/study_shadows.dart';
import '../../../../../theme/study/study_typography.dart';

class SubtopicEditorPanel extends StatefulWidget {
  final StudySubtopic? subtopic;

  /// Called when the user saves the edited subtopic.
  ///
  /// The editor creates a new immutable StudySubtopic instance and
  /// returns it through this callback.
  final ValueChanged<StudySubtopic>? onSave;

  /// Optional callback used when the user cancels editing.
  final VoidCallback? onCancel;

  const SubtopicEditorPanel({
    super.key,
    required this.subtopic,
    this.onSave,
    this.onCancel,
  });

  @override
  State<SubtopicEditorPanel> createState() => _SubtopicEditorPanelState();
}

class _SubtopicEditorPanelState extends State<SubtopicEditorPanel> {
  late final TextEditingController _idController;
  late final TextEditingController _titleController;

  late List<String> _learningObjectives;

  final List<TextEditingController> _objectiveControllers = [];

  bool _hasChanges = false;

  StudySubtopic? get subtopic => widget.subtopic;

  @override
  void initState() {
    super.initState();

    final current = widget.subtopic;

    _idController = TextEditingController(text: current?.id ?? '');

    _titleController = TextEditingController(text: current?.title ?? '');

    _learningObjectives = List<String>.from(
      current?.learningObjectives ?? const <String>[],
    );

    _createObjectiveControllers();

    _idController.addListener(_markChanged);
    _titleController.addListener(_markChanged);
  }

  void _createObjectiveControllers() {
    for (final controller in _objectiveControllers) {
      controller.dispose();
    }

    _objectiveControllers.clear();

    for (final objective in _learningObjectives) {
      final controller = TextEditingController(text: objective);

      controller.addListener(_markChanged);

      _objectiveControllers.add(controller);
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _titleController.dispose();

    for (final controller in _objectiveControllers) {
      controller.dispose();
    }

    super.dispose();
  }

  void _markChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (subtopic == null) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 22),
        _buildIdentitySection(),
        const SizedBox(height: 18),
        _buildObjectivesSection(),
        const SizedBox(height: 18),
        _buildContentSummary(),
        const SizedBox(height: 24),
        _buildActionBar(),
      ],
    );
  }

  // ==========================================================
  // HEADER
  // ==========================================================

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: StudyColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                'SUBTOPIC EDITOR',
                style: StudyTypography.eyebrow.copyWith(
                  color: StudyColors.primary,
                  fontSize: 9.5,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            const SizedBox(width: 9),
            if (_hasChanges) _buildUnsavedBadge(),
          ],
        ),
        const SizedBox(height: 9),
        Text(
          'Edit Subtopic',
          style: StudyTypography.heroTitle.copyWith(
            color: StudyColors.textPrimary,
            fontSize: 30,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          'Update the subtopic identity and learning objectives. '
          'Existing main content and supporting content are preserved.',
          style: StudyTypography.bodySecondary.copyWith(
            fontSize: 14.5,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildUnsavedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: StudyColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: StudyColors.warning.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 7, color: StudyColors.warning),
          const SizedBox(width: 5),
          Text(
            'UNSAVED CHANGES',
            style: StudyTypography.caption.copyWith(
              color: StudyColors.warning,
              fontWeight: FontWeight.w800,
              fontSize: 9,
              letterSpacing: 0.4,
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
    return _buildSectionCard(
      title: 'Subtopic Information',
      icon: Icons.account_tree_rounded,
      description:
          'Define the identifier and display title used by the '
          'content hierarchy.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 700;

          if (compact) {
            return Column(
              children: [
                _buildTextField(
                  controller: _idController,
                  label: 'Subtopic ID',
                  hint: 'e.g. domain_07_01_subtopic_01',
                  icon: Icons.tag_rounded,
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _titleController,
                  label: 'Subtopic Title',
                  hint: 'Enter the subtopic title',
                  icon: Icons.title_rounded,
                  maxLines: 2,
                ),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: _buildTextField(
                  controller: _idController,
                  label: 'Subtopic ID',
                  hint: 'e.g. domain_07_01_subtopic_01',
                  icon: Icons.tag_rounded,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 6,
                child: _buildTextField(
                  controller: _titleController,
                  label: 'Subtopic Title',
                  hint: 'Enter the subtopic title',
                  icon: Icons.title_rounded,
                  maxLines: 2,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: StudyTypography.eyebrow.copyWith(
            color: StudyColors.textSecondary,
            fontSize: 9,
            letterSpacing: 0.7,
          ),
        ),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 19, color: StudyColors.textSecondary),
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
              borderSide: BorderSide(color: StudyColors.primary, width: 1.4),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
          ),
          style: StudyTypography.body.copyWith(
            color: StudyColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // OBJECTIVES
  // ==========================================================

  Widget _buildObjectivesSection() {
    return _buildSectionCard(
      title: 'Learning Objectives',
      icon: Icons.flag_rounded,
      description:
          'Add, remove, edit and reorder the learning objectives '
          'associated with this subtopic.',
      trailing: _buildObjectiveCount(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_objectiveControllers.isEmpty)
            _buildNoObjectives()
          else
            ...List.generate(_objectiveControllers.length, _buildObjectiveRow),
          const SizedBox(height: 8),
          _buildAddObjectiveButton(),
        ],
      ),
    );
  }

  Widget _buildObjectiveCount() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: StudyColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${_objectiveControllers.length}',
        style: StudyTypography.caption.copyWith(
          color: StudyColors.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildObjectiveRow(int index) {
    final controller = _objectiveControllers[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: StudyColors.surfaceSoft,
        borderRadius: StudyRadius.medium,
        border: Border.all(color: StudyColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildObjectiveNumber(index),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: 'Enter learning objective',
                filled: true,
                fillColor: StudyColors.surface,
                border: OutlineInputBorder(
                  borderRadius: StudyRadius.small,
                  borderSide: BorderSide(color: StudyColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: StudyRadius.small,
                  borderSide: BorderSide(color: StudyColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: StudyRadius.small,
                  borderSide: BorderSide(
                    color: StudyColors.primary,
                    width: 1.2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 11,
                ),
              ),
              style: StudyTypography.body.copyWith(
                color: StudyColors.textPrimary,
                fontSize: 13.5,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildObjectiveActions(index),
        ],
      ),
    );
  }

  Widget _buildObjectiveNumber(int index) {
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
        style: StudyTypography.caption.copyWith(
          color: StudyColors.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildObjectiveActions(int index) {
    return Column(
      children: [
        _iconButton(
          icon: Icons.keyboard_arrow_up_rounded,
          tooltip: 'Move up',
          enabled: index > 0,
          onPressed: () {
            _moveObjectiveUp(index);
          },
        ),
        const SizedBox(height: 4),
        _iconButton(
          icon: Icons.keyboard_arrow_down_rounded,
          tooltip: 'Move down',
          enabled: index < _objectiveControllers.length - 1,
          onPressed: () {
            _moveObjectiveDown(index);
          },
        ),
        const SizedBox(height: 4),
        _iconButton(
          icon: Icons.delete_outline_rounded,
          tooltip: 'Delete objective',
          enabled: true,
          destructive: true,
          onPressed: () {
            _removeObjective(index);
          },
        ),
      ],
    );
  }

  Widget _iconButton({
    required IconData icon,
    required String tooltip,
    required bool enabled,
    required VoidCallback onPressed,
    bool destructive = false,
  }) {
    final color = destructive ? StudyColors.danger : StudyColors.textSecondary;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: enabled ? StudyColors.surface : StudyColors.surfaceSoft,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: StudyColors.border),
            ),
            child: Icon(
              icon,
              size: 18,
              color: enabled ? color : StudyColors.border,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoObjectives() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: StudyColors.background,
        borderRadius: StudyRadius.medium,
        border: Border.all(color: StudyColors.border),
      ),
      child: Column(
        children: [
          Icon(Icons.flag_outlined, size: 30, color: StudyColors.textSecondary),
          const SizedBox(height: 9),
          Text(
            'No learning objectives',
            style: StudyTypography.label.copyWith(
              color: StudyColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add the objectives learners should achieve.',
            textAlign: TextAlign.center,
            style: StudyTypography.bodySecondary.copyWith(fontSize: 12.5),
          ),
        ],
      ),
    );
  }

  Widget _buildAddObjectiveButton() {
    return OutlinedButton.icon(
      onPressed: _addObjective,
      icon: const Icon(Icons.add_rounded, size: 18),
      label: const Text('Add Learning Objective'),
    );
  }

  void _addObjective() {
    setState(() {
      _learningObjectives.add('');
      _createObjectiveControllers();
      _hasChanges = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _objectiveControllers.isEmpty) {
        return;
      }

      _objectiveControllers.last.selection = TextSelection.collapsed(
        offset: _objectiveControllers.last.text.length,
      );
    });
  }

  void _removeObjective(int index) {
    if (index < 0 || index >= _objectiveControllers.length) {
      return;
    }

    setState(() {
      _learningObjectives = _objectiveControllers
          .map((controller) => controller.text)
          .toList();

      _learningObjectives.removeAt(index);

      _createObjectiveControllers();
      _hasChanges = true;
    });
  }

  void _moveObjectiveUp(int index) {
    if (index <= 0 || index >= _objectiveControllers.length) {
      return;
    }

    _reorderObjectives(index, index - 1);
  }

  void _moveObjectiveDown(int index) {
    if (index < 0 || index >= _objectiveControllers.length - 1) {
      return;
    }

    _reorderObjectives(index, index + 1);
  }

  void _reorderObjectives(int oldIndex, int newIndex) {
    final values = _objectiveControllers
        .map((controller) => controller.text)
        .toList();

    final value = values.removeAt(oldIndex);
    values.insert(newIndex, value);

    setState(() {
      _learningObjectives = values;
      _createObjectiveControllers();
      _hasChanges = true;
    });
  }

  // ==========================================================
  // CONTENT SUMMARY
  // ==========================================================

  Widget _buildContentSummary() {
    final current = subtopic!;

    return _buildSectionCard(
      title: 'Existing Content',
      icon: Icons.layers_rounded,
      description:
          'The editor preserves the content already associated '
          'with this subtopic.',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _summaryChip(
            Icons.menu_book_outlined,
            current.mainContent.length,
            'Main Topics',
          ),
          _summaryChip(
            Icons.push_pin_outlined,
            current.keyPoints.length,
            'Key Points',
          ),
          _summaryChip(
            Icons.lightbulb_outline_rounded,
            current.examples.length,
            'Examples',
          ),
          _summaryChip(
            Icons.business_center_outlined,
            current.caseStudies.length,
            'Case Studies',
          ),
          _summaryChip(
            Icons.functions_rounded,
            current.formulas.length,
            'Formulas',
          ),
          _summaryChip(
            Icons.link_rounded,
            current.references.length,
            'References',
          ),
          _summaryChip(
            Icons.school_rounded,
            current.examTips.length,
            'Exam Tips',
          ),
          _summaryChip(
            Icons.error_outline_rounded,
            current.commonMistakes.length,
            'Common Mistakes',
          ),
          _summaryChip(
            Icons.bookmark_rounded,
            current.keyTakeaways.length,
            'Key Takeaways',
          ),
          _summaryChip(
            Icons.quiz_outlined,
            current.quizzes.length,
            'Quiz References',
          ),
        ],
      ),
    );
  }

  Widget _summaryChip(IconData icon, int count, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: StudyColors.surfaceSoft,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: StudyColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: StudyColors.primary),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: StudyTypography.label.copyWith(
              color: StudyColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: StudyTypography.caption.copyWith(
              color: StudyColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // ACTION BAR
  // ==========================================================

  Widget _buildActionBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: StudyColors.surface,
        borderRadius: StudyRadius.large,
        border: Border.all(color: StudyColors.border),
        boxShadow: StudyShadows.soft,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 560;

          final buttons = [
            OutlinedButton.icon(
              onPressed: _handleCancel,
              icon: const Icon(Icons.close_rounded, size: 17),
              label: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: _canSave ? _saveSubtopic : null,
              icon: const Icon(Icons.save_rounded, size: 17),
              label: const Text('Save Subtopic'),
            ),
          ];

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [...buttons],
            );
          }

          return Row(
            children: [
              Expanded(
                child: Text(
                  _canSave
                      ? 'Changes are ready to save.'
                      : 'Enter a subtopic ID and title before saving.',
                  style: StudyTypography.bodySecondary.copyWith(fontSize: 12.5),
                ),
              ),
              const SizedBox(width: 12),
              ...buttons.map(
                (button) => Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: button,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  bool get _canSave {
    return _idController.text.trim().isNotEmpty &&
        _titleController.text.trim().isNotEmpty;
  }

  // ==========================================================
  // SAVE / CANCEL
  // ==========================================================

  void _saveSubtopic() {
    if (!_canSave) {
      _showMessage('Subtopic ID and title are required.', isError: true);
      return;
    }

    final current = subtopic!;

    final objectives = _objectiveControllers
        .map((controller) => controller.text.trim())
        .where((value) => value.isNotEmpty)
        .toList();

    final updated = StudySubtopic(
      id: _idController.text.trim(),
      title: _titleController.text.trim(),
      learningObjectives: objectives,
      mainContent: current.mainContent,
      keyPoints: current.keyPoints,
      examples: current.examples,
      caseStudies: current.caseStudies,
      formulas: current.formulas,
      references: current.references,
      examTips: current.examTips,
      commonMistakes: current.commonMistakes,
      keyTakeaways: current.keyTakeaways,
      quizzes: current.quizzes,
    );

    widget.onSave?.call(updated);

    setState(() {
      _hasChanges = false;
    });

    _showMessage('Subtopic changes are ready.');
  }

  void _handleCancel() {
    if (_hasChanges) {
      _showCancelConfirmation();
      return;
    }

    widget.onCancel?.call();
  }

  Future<void> _showCancelConfirmation() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Discard changes?'),
          content: const Text('Your unsaved subtopic changes will be lost.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Keep Editing'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Discard'),
            ),
          ],
        );
      },
    );

    if (discard == true && mounted) {
      widget.onCancel?.call();
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? StudyColors.danger : null,
      ),
    );
  }

  // ==========================================================
  // SECTION CARD
  // ==========================================================

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required String description,
    required Widget child,
    Widget? trailing,
  }) {
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
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 17, 18, 15),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: StudyColors.primary.withValues(alpha: 0.08),
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
                        title,
                        style: StudyTypography.subSectionTitle.copyWith(
                          color: StudyColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        description,
                        style: StudyTypography.caption.copyWith(
                          color: StudyColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 10), trailing],
              ],
            ),
          ),
          Container(
            width: double.infinity,
            height: 1,
            color: StudyColors.border,
          ),
          Padding(padding: const EdgeInsets.all(18), child: child),
        ],
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
        color: StudyColors.surface,
        borderRadius: StudyRadius.large,
        border: Border.all(color: StudyColors.border),
        boxShadow: StudyShadows.soft,
      ),
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: StudyColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.account_tree_outlined,
              size: 30,
              color: StudyColors.primary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No subtopic selected',
            style: StudyTypography.sectionTitle.copyWith(
              color: StudyColors.textPrimary,
              fontSize: 19,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Import content and select a subtopic to begin editing.',
            textAlign: TextAlign.center,
            style: StudyTypography.bodySecondary.copyWith(
              fontSize: 13.5,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
