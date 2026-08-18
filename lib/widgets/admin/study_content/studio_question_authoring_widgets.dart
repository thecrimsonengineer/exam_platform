import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../../../models/question.dart';
import '../../../models/study_content.dart';
import '../../../services/complete_question_paste_parser.dart';
import '../../../services/studio/studio_question_import_service.dart';
import '../../../services/studio/studio_question_service.dart';
import '../../../services/question_quality_validator.dart';

class StudioQuestionEditorDialog extends StatefulWidget {
  final StudyContent content;
  final StudySubtopic subtopic;
  final StudioQuestionService questionService;
  final Question? existing;

  const StudioQuestionEditorDialog({
    super.key,
    required this.content,
    required this.subtopic,
    required this.questionService,
    this.existing,
  });

  @override
  State<StudioQuestionEditorDialog> createState() =>
      _StudioQuestionEditorDialogState();
}

class _StudioQuestionEditorDialogState
    extends State<StudioQuestionEditorDialog> {
  late final TextEditingController _stem;
  late final TextEditingController _optionA;
  late final TextEditingController _optionB;
  late final TextEditingController _optionC;
  late final TextEditingController _optionD;
  late final TextEditingController _explanation;
  late final TextEditingController _reference;
  late final TextEditingController _tags;

  int _correctAnswer = 0;

  @override
  void initState() {
    super.initState();

    final q = widget.existing;

    _stem = TextEditingController(text: q?.question ?? '');
    _optionA = TextEditingController(
      text: q != null && q.options.length > 0 ? q.options[0] : '',
    );
    _optionB = TextEditingController(
      text: q != null && q.options.length > 1 ? q.options[1] : '',
    );
    _optionC = TextEditingController(
      text: q != null && q.options.length > 2 ? q.options[2] : '',
    );
    _optionD = TextEditingController(
      text: q != null && q.options.length > 3 ? q.options[3] : '',
    );
    _explanation = TextEditingController(text: q?.explanation ?? '');
    _reference = TextEditingController(text: q?.reference ?? '');
    _tags = TextEditingController(text: q?.tags.join(', ') ?? '');

    _correctAnswer = q?.correctAnswer ?? 0;
  }

  @override
  void dispose() {
    _stem.dispose();
    _optionA.dispose();
    _optionB.dispose();
    _optionC.dispose();
    _optionD.dispose();
    _explanation.dispose();
    _reference.dispose();
    _tags.dispose();
    super.dispose();
  }

  void _save() {
    final question = Question(
      id: widget.existing?.id ?? widget.questionService.nextQuestionId(),
      domain: _domainNumber(widget.content.domainId),
      competencyId: widget.content.competencyId,
      subtopicId: widget.subtopic.id,
      topicId: widget.subtopic.mainContent.isEmpty
          ? ''
          : widget.subtopic.mainContent.first.id,
      quizId: widget.questionService.resolveQuizId(
        content: widget.content,
        subtopic: widget.subtopic,
      ),
      contentPackageId: widget.content.id,
      question: _stem.text.trim(),
      options: [
        _optionA.text.trim(),
        _optionB.text.trim(),
        _optionC.text.trim(),
        _optionD.text.trim(),
      ],
      correctAnswer: _correctAnswer,
      explanation: _explanation.text.trim(),
      bestAnswerRationale: widget.existing?.bestAnswerRationale ?? '',
      reference: _reference.text.trim(),
      difficulty: widget.existing?.difficulty ?? 'Hard',
      cognitiveLevel: widget.existing?.cognitiveLevel ?? 'analysis',
      questionType: 'scenario_mcq',
      status: widget.existing?.status ?? 'draft',
      version: widget.existing?.version ?? 1,
      tags: _tags.text
          .split(RegExp(r'[,;\n]'))
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList(),
    );

    Navigator.of(context).pop(question);
  }

  int _domainNumber(String domainId) {
    final match = RegExp(r'\d+').firstMatch(domainId);
    return int.tryParse(match?.group(0) ?? '') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.existing == null
            ? 'Create Practice Question'
            : 'Edit Practice Question',
      ),
      content: SizedBox(
        width: 760,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _stem,
                minLines: 4,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'Question stem',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              _optionField('Option A', _optionA, 0),
              const SizedBox(height: 10),
              _optionField('Option B', _optionB, 1),
              const SizedBox(height: 10),
              _optionField('Option C', _optionC, 2),
              const SizedBox(height: 10),
              _optionField('Option D', _optionD, 3),
              const SizedBox(height: 12),
              TextField(
                controller: _explanation,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Explanation',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _reference,
                decoration: const InputDecoration(
                  labelText: 'Reference',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _tags,
                decoration: const InputDecoration(
                  labelText: 'Tags',
                  hintText: 'CSP11, safety, risk assessment',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.save_rounded),
          label: const Text('Save Draft'),
        ),
      ],
    );
  }

  Widget _optionField(
    String label,
    TextEditingController controller,
    int index,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Radio<int>(
          value: index,
          groupValue: _correctAnswer,
          onChanged: (value) {
            if (value == null) return;
            setState(() => _correctAnswer = value);
          },
        ),
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }
}

class StudioCompleteQuestionPasteDialog extends StatefulWidget {
  final StudyContent content;
  final StudySubtopic subtopic;
  final StudioQuestionService questionService;

  const StudioCompleteQuestionPasteDialog({
    super.key,
    required this.content,
    required this.subtopic,
    required this.questionService,
  });

  @override
  State<StudioCompleteQuestionPasteDialog> createState() =>
      _StudioCompleteQuestionPasteDialogState();
}

class _StudioCompleteQuestionPasteDialogState
    extends State<StudioCompleteQuestionPasteDialog> {
  final CompleteQuestionPasteParser _parser =
      const CompleteQuestionPasteParser();

  final StudioQuestionImportService _importer =
      const StudioQuestionImportService();

  final TextEditingController _controller = TextEditingController();

  Question? _preview;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _parse() {
    setState(() {
      _error = null;
      _preview = null;
    });

    try {
      final parsed = _parser.parse(_controller.text);

      final question = _importer.fromPaste(
        parsed: parsed,
        id: widget.questionService.nextQuestionId(),
        content: widget.content,
        subtopic: widget.subtopic,
        quizId: widget.questionService.resolveQuizId(
          content: widget.content,
          subtopic: widget.subtopic,
        ),
      );

      setState(() => _preview = question);
    } catch (error) {
      setState(() {
        _error = error.toString().replaceFirst('FormatException: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final question = _preview;
    final issues = question == null
        ? const <QuestionQualityIssue>[]
        : widget.questionService.validate(question);

    final hasErrors = issues.any((issue) => issue.isError);

    return AlertDialog(
      title: const Text('Import Complete Question'),
      content: SizedBox(
        width: 820,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _controller,
                minLines: 12,
                maxLines: 22,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText:
                      'QUESTION:\n...\n\n'
                      'OPTION A:\n...\n\n'
                      'OPTION B:\n...\n\n'
                      'OPTION C:\n...\n\n'
                      'OPTION D:\n...\n\n'
                      'BEST ANSWER:\nC\n\n'
                      'EXPLANATION:\n...\n\n'
                      'REFERENCE:\n...\n\n'
                      'TAGS:\nCSP11, safety',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  FilledButton.icon(
                    onPressed: _parse,
                    icon: const Icon(Icons.preview_rounded),
                    label: const Text('Preview'),
                  ),
                  if (_error != null) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              _previewPanel(question, issues),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: question == null || hasErrors
              ? null
              : () => Navigator.of(context).pop(question),
          icon: const Icon(Icons.save_rounded),
          label: const Text('Use Question'),
        ),
      ],
    );
  }

  Widget _previewPanel(Question? question, List<QuestionQualityIssue> issues) {
    if (question == null) {
      return const Center(child: Text('Parse the question to preview it.'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Preview',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Text(
          question.question,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        ...question.options.asMap().entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              '${String.fromCharCode(65 + entry.key)}. '
              '${entry.value}'
              '${entry.key == question.correctAnswer ? ' [BEST]' : ''}',
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text('Explanation: ${question.explanation}'),
        const SizedBox(height: 6),
        Text('Reference: ${question.reference}'),
        const SizedBox(height: 6),
        Text('Tags: ${question.tags.join(', ')}'),
        if (issues.isNotEmpty) ...[
          const SizedBox(height: 14),
          _qualityFeedbackPanel(issues),
        ],
      ],
    );
  }

  Widget _qualityFeedbackPanel(List<QuestionQualityIssue> issues) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 18),
              SizedBox(width: 6),
              Text(
                'NEEDS IMPROVEMENT',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...issues.map(
            (issue) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text('• ${issue.message}'),
            ),
          ),
        ],
      ),
    );
  }
}

class StudioJsonQuestionImportDialog extends StatefulWidget {
  final StudyContent content;
  final StudySubtopic subtopic;
  final StudioQuestionService questionService;

  const StudioJsonQuestionImportDialog({
    super.key,
    required this.content,
    required this.subtopic,
    required this.questionService,
  });

  @override
  State<StudioJsonQuestionImportDialog> createState() =>
      _StudioJsonQuestionImportDialogState();
}

class _StudioJsonQuestionImportDialogState
    extends State<StudioJsonQuestionImportDialog> {
  final StudioQuestionImportService _importer =
      const StudioQuestionImportService();

  List<Question> _questions = <Question>[];
  String? _fileName;
  String? _error;
  bool _busy = false;

  Future<void> _selectFile() async {
    setState(() {
      _busy = true;
      _error = null;
      _questions = <Question>[];
    });

    try {
      const group = XTypeGroup(label: 'Question JSON', extensions: ['json']);

      final file = await openFile(acceptedTypeGroups: [group]);

      if (file == null) {
        setState(() => _busy = false);
        return;
      }

      final text = await file.readAsString();

      final questions = _importer.fromJsonText(
        input: text,
        nextId: widget.questionService.nextQuestionId,
        content: widget.content,
        subtopic: widget.subtopic,
        quizId: widget.questionService.resolveQuizId(
          content: widget.content,
          subtopic: widget.subtopic,
        ),
      );

      setState(() {
        _fileName = file.name;
        _questions = questions;
        _busy = false;
      });
    } catch (error) {
      setState(() {
        _busy = false;
        _error = error.toString().replaceFirst('FormatException: ', '');
      });
    }
  }

  List<QuestionQualityIssue> _issuesFor(Question question) {
    return widget.questionService.validate(question);
  }

  bool _hasQualityIssues(Question question) {
    return _issuesFor(question).isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final totalIssues = _questions.fold<int>(
      0,
      (total, question) => total + _issuesFor(question).length,
    );

    final needsImprovementCount = _questions.where(_hasQualityIssues).length;

    final readyCount = _questions.length - needsImprovementCount;

    return AlertDialog(
      title: const Text('Import Question JSON'),
      content: SizedBox(
        width: 820,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose a .json file. Imported questions are automatically '
                'attached to the selected Studio subtopic and enter as Draft.',
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Context: ${widget.content.competencyId} • '
                  '${widget.subtopic.id} • ${widget.content.id}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  FilledButton.icon(
                    onPressed: _busy ? null : _selectFile,
                    icon: const Icon(Icons.upload_file_rounded),
                    label: Text(_busy ? 'Reading...' : 'Choose JSON File'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _fileName ?? 'No file selected',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (_questions.isNotEmpty) ...[
                const SizedBox(height: 18),
                Row(
                  children: [
                    Text(
                      '${_questions.length} question'
                      '${_questions.length == 1 ? '' : 's'} parsed.',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const Spacer(),
                    if (needsImprovementCount == 0)
                      _qualityBadge(
                        label: 'READY',
                        icon: Icons.check_circle_rounded,
                      )
                    else
                      _qualityBadge(
                        label: 'NEEDS IMPROVEMENT',
                        icon: Icons.warning_amber_rounded,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: needsImprovementCount == 0
                        ? Colors.green.withValues(alpha: 0.06)
                        : Colors.orange.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    needsImprovementCount == 0
                        ? 'All $readyCount imported questions passed '
                              'the current quality checks.'
                        : '$needsImprovementCount question'
                              '${needsImprovementCount == 1 ? '' : 's'} '
                              'NEEDS IMPROVEMENT. '
                              '$totalIssues quality issue'
                              '${totalIssues == 1 ? '' : 's'} detected. '
                              'These questions can still be imported as '
                              'drafts and improved before publishing.',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 340,
                  child: ListView.separated(
                    itemCount: _questions.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final question = _questions[index];
                      final issues = _issuesFor(question);
                      final needsImprovement = issues.isNotEmpty;

                      return ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 15,
                          child: Text('${index + 1}'),
                        ),
                        title: Text(
                          question.question,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Icon(
                                needsImprovement
                                    ? Icons.warning_amber_rounded
                                    : Icons.check_circle_rounded,
                                size: 16,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                needsImprovement
                                    ? 'NEEDS IMPROVEMENT'
                                    : 'READY',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                            child: needsImprovement
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Quality feedback',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      ...issues.map(
                                        (issue) => Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 5,
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text('• '),
                                              Expanded(
                                                child: Text(issue.message),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : const Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'No quality issues detected. '
                                      'Question is ready for the next '
                                      'Studio workflow stage.',
                                    ),
                                  ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _questions.isEmpty
              ? null
              : () => Navigator.pop(context, _questions),
          icon: const Icon(Icons.save_rounded),
          label: const Text('Import as Drafts'),
        ),
      ],
    );
  }

  Widget _qualityBadge({required String label, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: label == 'READY'
            ? Colors.green.withValues(alpha: 0.10)
            : Colors.orange.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
