import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../../../models/question.dart';
import '../../../models/study_content.dart';
import '../../../services/complete_question_paste_parser.dart';
import '../../../services/studio/studio_question_import_service.dart';
import '../../../services/studio/studio_question_service.dart';

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
  late final List<TextEditingController> _options;
  late final TextEditingController _explanation;
  late final TextEditingController _rationale;
  late final TextEditingController _reference;
  late final TextEditingController _tags;

  int _correct = 0;
  String _cognitive = 'analysis';

  @override
  void initState() {
    super.initState();
    final q = widget.existing;
    _stem = TextEditingController(text: q?.question ?? '');
    _options = List.generate(
      4,
      (i) => TextEditingController(
        text: q != null && i < q.options.length ? q.options[i] : '',
      ),
    );
    _explanation = TextEditingController(text: q?.explanation ?? '');
    _rationale = TextEditingController(text: q?.bestAnswerRationale ?? '');
    _reference = TextEditingController(text: q?.reference ?? '');
    _tags = TextEditingController(text: q?.tags.join(', ') ?? 'CSP11, CSP11');
    _correct = q?.correctAnswer ?? 0;
    _cognitive = q?.cognitiveLevel ?? 'analysis';
  }

  @override
  void dispose() {
    _stem.dispose();
    for (final controller in _options) {
      controller.dispose();
    }
    _explanation.dispose();
    _rationale.dispose();
    _reference.dispose();
    _tags.dispose();
    super.dispose();
  }

  void _save() {
    final existing = widget.existing;
    final question = Question(
      id: existing?.id ?? widget.questionService.nextQuestionId(),
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
      options: _options.map((controller) => controller.text.trim()).toList(),
      correctAnswer: _correct,
      explanation: _explanation.text.trim(),
      bestAnswerRationale: _rationale.text.trim(),
      reference: _reference.text.trim(),
      difficulty: 'Hard',
      cognitiveLevel: _cognitive,
      questionType: 'scenario_mcq',
      status: 'draft',
      version: existing?.version ?? 1,
      tags: _tags.text
          .split(',')
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
        widget.existing == null ? 'Create Practice Question' : 'Edit Practice Question',
      ),
      content: SizedBox(
        width: 860,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _contextBanner(),
              const SizedBox(height: 14),
              TextField(
                controller: _stem,
                minLines: 5,
                maxLines: 10,
                decoration: const InputDecoration(
                  labelText: 'Question stem',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _cognitive,
                decoration: const InputDecoration(
                  labelText: 'Cognitive level',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'application', child: Text('Application')),
                  DropdownMenuItem(value: 'analysis', child: Text('Analysis')),
                ],
                onChanged: (value) => setState(() => _cognitive = value ?? 'analysis'),
              ),
              const SizedBox(height: 16),
              const Text(
                'ANSWER OPTIONS',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2),
              ),
              const SizedBox(height: 8),
              ...List.generate(4, (i) {
                final selected = _correct == i;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        tooltip: 'Set BEST answer',
                        onPressed: () => setState(() => _correct = i),
                        icon: Icon(
                          selected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                          color: selected ? Colors.blue : Colors.grey,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _options[i],
                          minLines: 2,
                          maxLines: 4,
                          decoration: InputDecoration(
                            labelText: 'Option ${String.fromCharCode(65 + i)}',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              TextField(
                controller: _rationale,
                minLines: 2,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Why is this the BEST answer?',
                  helperText: 'Optional authoring rationale. It is not a distractor field.',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _explanation,
                minLines: 4,
                maxLines: 7,
                decoration: const InputDecoration(
                  labelText: 'Answer explanation',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _reference,
                decoration: const InputDecoration(
                  labelText: 'Reference / source',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _tags,
                decoration: const InputDecoration(
                  labelText: 'Tags',
                  helperText: 'Comma separated, minimum two useful tags.',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.save_rounded),
          label: const Text('Save Draft'),
        ),
      ],
    );
  }

  Widget _contextBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.14)),
      ),
      child: Text(
        'Context: ${widget.content.competencyId}  •  ${widget.subtopic.id}  •  ${widget.content.id}',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
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
  final TextEditingController _paste = TextEditingController();
  final CompleteQuestionPasteParser _parser = const CompleteQuestionPasteParser();
  final StudioQuestionImportService _importer = const StudioQuestionImportService();

  Question? _preview;
  String? _error;

  @override
  void dispose() {
    _paste.dispose();
    super.dispose();
  }

  void _parse() {
    try {
      final parsed = _parser.parse(_paste.text);
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
      setState(() {
        _preview = question;
        _error = null;
      });
    } catch (error) {
      setState(() {
        _preview = null;
        _error = error.toString().replaceFirst('FormatException: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final question = _preview;
    final issues = question == null ? const [] : widget.questionService.validate(question);
    final hasErrors = issues.any((issue) => issue.isError);

    return AlertDialog(
      title: const Text('Import Complete Question'),
      content: SizedBox(
        width: 920,
        height: 620,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: TextField(
                controller: _paste,
                expands: true,
                maxLines: null,
                minLines: null,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  hintText: 'QUESTION:\n...\n\nOPTION A:\n...\n\nOPTION B:\n...\n\nOPTION C:\n...\n\nOPTION D:\n...\n\nBEST ANSWER:\nC\n\nEXPLANATION:\n...\n\nREFERENCE:\n...\n\nTAGS:\nCSP11, safety',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(child: _previewPanel(question, issues)),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        OutlinedButton.icon(onPressed: _parse, icon: const Icon(Icons.preview_rounded), label: const Text('Parse & Preview')),
        FilledButton.icon(
          onPressed: question == null || hasErrors ? null : () => Navigator.pop(context, question),
          icon: const Icon(Icons.save_rounded),
          label: const Text('Import as Draft'),
        ),
      ],
    );
  }

  Widget _previewPanel(Question? question, List<dynamic> issues) {
    if (question == null) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Center(child: Text(_error ?? 'Parse the question to preview it.')),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(question.question, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            ...question.options.asMap().entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Text('${String.fromCharCode(65 + entry.key)}. ${entry.value}${entry.key == question.correctAnswer ? '  [BEST]' : ''}'),
              ),
            ),
            const Divider(height: 22),
            Text('Explanation: ${question.explanation}'),
            const SizedBox(height: 8),
            Text('Reference: ${question.reference}'),
            const SizedBox(height: 8),
            Text('Tags: ${question.tags.join(', ')}'),
            if (issues.isNotEmpty) ...[
              const SizedBox(height: 14),
              ...issues.map((issue) => Text('• ${issue.message}', style: const TextStyle(color: Colors.red))),
            ],
          ],
        ),
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
  final StudioQuestionImportService _importer = const StudioQuestionImportService();
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

  @override
  Widget build(BuildContext context) {
    final errors = <String>[];
    for (var i = 0; i < _questions.length; i++) {
      final issues = widget.questionService.validate(_questions[i]);
      if (issues.any((issue) => issue.isError)) {
        errors.add('Question ${i + 1}: ${issues.where((issue) => issue.isError).map((issue) => issue.message).join('; ')}');
      }
    }

    return AlertDialog(
      title: const Text('Import Question JSON'),
      content: SizedBox(
        width: 760,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose a .json file. Imported questions are automatically attached to the selected Studio subtopic and enter as Draft.'),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Context: ${widget.content.competencyId} • ${widget.subtopic.id} • ${widget.content.id}',
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
                Expanded(child: Text(_fileName ?? 'No file selected', overflow: TextOverflow.ellipsis)),
              ],
            ),
            if (_questions.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text('${_questions.length} question${_questions.length == 1 ? '' : 's'} parsed.', style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              SizedBox(
                height: 180,
                child: ListView.builder(
                  itemCount: _questions.length,
                  itemBuilder: (context, index) => ListTile(
                    dense: true,
                    leading: CircleAvatar(radius: 13, child: Text('${index + 1}')),
                    title: Text(_questions[index].question, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ),
            ],
            if (errors.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(8)),
                child: Text('${errors.length} question(s) have quality errors. Correct them before import.'),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton.icon(
          onPressed: _questions.isEmpty || errors.isNotEmpty ? null : () => Navigator.pop(context, _questions),
          icon: const Icon(Icons.save_rounded),
          label: const Text('Import as Drafts'),
        ),
      ],
    );
  }
}
