import 'package:flutter/material.dart';

import '../../models/question.dart';
import '../../models/study_content.dart';
import '../../services/question_bank_service.dart';
import '../../services/study_content/local_study_content_repository.dart';

class QuestionBankScreen extends StatefulWidget {
  const QuestionBankScreen({super.key});

  @override
  State<QuestionBankScreen> createState() => _QuestionBankScreenState();
}

class _QuestionBankScreenState extends State<QuestionBankScreen> {
  final LocalStudyContentRepository _contentRepository =
      LocalStudyContentRepository();

  final QuestionBankService _questionService = QuestionBankService();

  List<StudyContent> _content = <StudyContent>[];
  StudyContent? _selectedContent;
  int? _selectedSubtopicIndex;
  List<Question> _questions = <Question>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _questionService.initialize();

    final drafts = await _contentRepository.loadDrafts();
    final published = await _contentRepository.loadPublished();

    final byId = <String, StudyContent>{};

    for (final item in [...drafts, ...published]) {
      byId[item.id] = item;
    }

    final items = byId.values.toList()
      ..sort((a, b) {
        final titleCompare = a.title.compareTo(b.title);

        if (titleCompare != 0) {
          return titleCompare;
        }

        return a.version.compareTo(b.version);
      });

    if (!mounted) {
      return;
    }

    setState(() {
      _content = items;
      _selectedContent = items.isEmpty ? null : items.first;
      _selectedSubtopicIndex = items.isEmpty || items.first.subtopics.isEmpty
          ? null
          : 0;
      _loading = false;
    });

    _refreshQuestions();
  }

  String _quizId(StudyContent content, StudySubtopic subtopic) {
    return '${content.id}_${subtopic.id}_quiz';
  }

  void _refreshQuestions() {
    final content = _selectedContent;
    final index = _selectedSubtopicIndex;

    if (content == null ||
        index == null ||
        index < 0 ||
        index >= content.subtopics.length) {
      if (mounted) {
        setState(() {
          _questions = <Question>[];
        });
      }
      return;
    }

    final subtopic = content.subtopics[index];
    final quizId = _quizId(content, subtopic);

    final questions = _questionService.byQuizId(quizId)
      ..sort((a, b) => a.id.compareTo(b.id));

    if (!mounted) {
      return;
    }

    setState(() {
      _questions = questions;
    });
  }

  Future<void> _openEditor({Question? question}) async {
    final content = _selectedContent;
    final index = _selectedSubtopicIndex;

    if (content == null ||
        index == null ||
        index < 0 ||
        index >= content.subtopics.length) {
      return;
    }

    final result = await showDialog<Question>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return _QuestionEditorDialog(
          content: content,
          subtopic: content.subtopics[index],
          questionService: _questionService,
          existing: question,
        );
      },
    );

    if (result == null) {
      return;
    }

    await _questionService.saveDraft(result);
    _refreshQuestions();
  }

  Future<void> _publishQuestion(Question question) async {
    try {
      await _questionService.publish(question);

      _refreshQuestions();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Question published.')));
    } catch (error) {
      _showError(error.toString());
    }
  }

  Future<void> _deleteQuestion(Question question) async {
    await _questionService.delete(question.id);
    _refreshQuestions();
  }

  Future<void> _attachQuizToContent() async {
    final content = _selectedContent;
    final index = _selectedSubtopicIndex;

    if (content == null ||
        index == null ||
        index < 0 ||
        index >= content.subtopics.length) {
      return;
    }

    final subtopic = content.subtopics[index];
    final quizId = _quizId(content, subtopic);

    if (_questions.length != 5 ||
        !_questions.every((q) => q.status.toLowerCase() == 'published')) {
      _showError(
        'The subtopic must have exactly 5 published questions '
        'before the quiz can be linked.',
      );
      return;
    }

    if (subtopic.quizzes.any((quiz) => quiz.quizId == quizId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This quiz is already linked to the subtopic.'),
        ),
      );
      return;
    }

    final updatedSubtopic = StudySubtopic(
      id: subtopic.id,
      title: subtopic.title,
      learningObjectives: subtopic.learningObjectives,
      mainContent: subtopic.mainContent,
      keyPoints: subtopic.keyPoints,
      examples: subtopic.examples,
      caseStudies: subtopic.caseStudies,
      formulas: subtopic.formulas,
      references: subtopic.references,
      examTips: subtopic.examTips,
      commonMistakes: subtopic.commonMistakes,
      keyTakeaways: subtopic.keyTakeaways,
      quizzes: [
        ...subtopic.quizzes,
        QuizReference(quizId: quizId),
      ],
    );

    final updatedSubtopics = List<StudySubtopic>.from(content.subtopics);

    updatedSubtopics[index] = updatedSubtopic;

    final updatedContent = StudyContent(
      id: content.id,
      domainId: content.domainId,
      competencyId: content.competencyId,
      competencyNumber: content.competencyNumber,
      title: content.title,
      status: content.status,
      version: content.version,
      subtopics: updatedSubtopics,
    );

    if (content.status.toLowerCase() == 'published') {
      _showError(
        'Link the quiz to the draft version first. '
        'Publish the content version after linking.',
      );
      return;
    }

    await _contentRepository.saveDraft(updatedContent);

    await _load();

    _showSuccess(
      'Quiz linked to the subtopic. '
      'Publish the content version to make it student-visible.',
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message.replaceFirst('Bad state: ', '')),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final content = _selectedContent;
    final index = _selectedSubtopicIndex;

    final subtopic =
        content != null &&
            index != null &&
            index >= 0 &&
            index < content.subtopics.length
        ? content.subtopics[index]
        : null;

    final publishedCount = _questions
        .where((q) => q.status.toLowerCase() == 'published')
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('CSP11 Question Bank'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Row(
              children: [
                SizedBox(width: 330, child: _buildNavigator()),
                Expanded(
                  child: _buildWorkspace(content, subtopic, publishedCount),
                ),
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
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
      color: Colors.white,
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'QUESTION AUTHORING',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.6,
                  color: Color(0xFF64748B),
                ),
              ),
              SizedBox(height: 4),
              Text(
                'CSP11 High-Level Practice Questions',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          _ruleChip('5 questions / subtopic'),
          _ruleChip('Hard • Application / Analysis'),
          _ruleChip('4 options • 1 BEST answer'),
        ],
      ),
    );
  }

  Widget _ruleChip(String text) {
    return Chip(
      label: Text(
        text,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      ),
      backgroundColor: const Color(0xFFF1F5F9),
      side: BorderSide.none,
    );
  }

  Widget _buildNavigator() {
    return Container(
      color: const Color(0xFFF9FAFC),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CONTENT TARGET',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<StudyContent>(
            initialValue: _selectedContent,
            decoration: const InputDecoration(
              labelText: 'Competency',
              border: OutlineInputBorder(),
            ),
            items: _content
                .map(
                  (item) => DropdownMenuItem<StudyContent>(
                    value: item,
                    child: Text('${item.title} • v${item.version}'),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedContent = value;
                _selectedSubtopicIndex =
                    value == null || value.subtopics.isEmpty ? null : 0;
              });

              _refreshQuestions();
            },
          ),
          const SizedBox(height: 12),
          if (_selectedContent != null)
            DropdownButtonFormField<int>(
              initialValue: _selectedSubtopicIndex,
              decoration: const InputDecoration(
                labelText: 'Subtopic',
                border: OutlineInputBorder(),
              ),
              items: _selectedContent!.subtopics
                  .asMap()
                  .entries
                  .map(
                    (entry) => DropdownMenuItem<int>(
                      value: entry.key,
                      child: Text(
                        '${entry.key + 1}. ${entry.value.title}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSubtopicIndex = value;
                });

                _refreshQuestions();
              },
            ),
          const SizedBox(height: 18),
          const Divider(),
          const SizedBox(height: 10),
          const Text(
            'QUALITY GATE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 10),
          const _RuleRow('Scenario-based', 'Application / Analysis'),
          const _RuleRow('Options', 'Exactly 4'),
          const _RuleRow('Best answer', 'Not longest'),
          const _RuleRow('Explanation', 'Required'),
          const _RuleRow('Reference', 'Required'),
          const _RuleRow('Subtopic quota', 'Exactly 5'),
        ],
      ),
    );
  }

  Widget _buildWorkspace(
    StudyContent? content,
    StudySubtopic? subtopic,
    int publishedCount,
  ) {
    if (content == null || subtopic == null) {
      return const Center(child: Text('Select a competency and subtopic.'));
    }

    final quizId = _quizId(content, subtopic);

    final ready = _questions.length == 5 && publishedCount == 5;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subtopic.title,
                      style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Quiz ID: $quizId',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: _questions.length >= 5 ? null : () => _openEditor(),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create Question'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _metric('Questions', '${_questions.length}/5'),
              const SizedBox(width: 10),
              _metric('Published', '$publishedCount/5'),
              const SizedBox(width: 10),
              _metric('Status', ready ? 'READY' : 'BUILDING'),
            ],
          ),
          const SizedBox(height: 18),
          Expanded(
            child: _questions.isEmpty
                ? _emptyState()
                : ListView.separated(
                    itemCount: _questions.length,
                    separatorBuilder: (context, index) {
                      return const SizedBox(height: 10);
                    },
                    itemBuilder: (context, index) {
                      return _questionCard(_questions[index], index);
                    },
                  ),
          ),
          if (ready) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _attachQuizToContent,
                icon: const Icon(Icons.link_rounded),
                label: const Text('Link Quiz to Student Content'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.psychology_alt_rounded,
              size: 44,
              color: Color(0xFF64748B),
            ),
            SizedBox(height: 14),
            Text(
              'Build the five-question set',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 8),
            Text(
              'Each question must pass the CSP quality gate '
              'before it can be published.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _questionCard(Question question, int index) {
    final published = question.status.toLowerCase() == 'published';

    final issues = _questionService.validate(question);

    final valid = issues.isEmpty;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Q${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(width: 10),
                Chip(label: Text(question.difficulty)),
                const SizedBox(width: 6),
                Chip(label: Text(question.cognitiveLevel.toUpperCase())),
                const Spacer(),
                Text(
                  published ? 'PUBLISHED' : 'DRAFT',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: published
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              question.question,
              style: const TextStyle(
                fontSize: 15,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...question.options.asMap().entries.map((entry) {
              final i = entry.key;
              final isBest = i == question.correctAnswer;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 24,
                      child: Text(
                        String.fromCharCode(65 + i),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Expanded(child: Text(entry.value)),
                    if (isBest)
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Chip(label: Text('BEST')),
                      ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  valid
                      ? 'Quality gate: PASS'
                      : 'Quality gate: '
                            '${issues.length} issue(s)',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: valid ? Colors.green.shade700 : Colors.red.shade700,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _openEditor(question: question),
                  child: const Text('Edit'),
                ),
                if (!published)
                  FilledButton.tonal(
                    onPressed: valid && _questions.length == 5
                        ? () => _publishQuestion(question)
                        : null,
                    child: const Text('Publish'),
                  ),
                IconButton(
                  onPressed: () => _deleteQuestion(question),
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  final String label;
  final String value;

  const _RuleRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionEditorDialog extends StatefulWidget {
  final StudyContent content;
  final StudySubtopic subtopic;
  final QuestionBankService questionService;
  final Question? existing;

  const _QuestionEditorDialog({
    required this.content,
    required this.subtopic,
    required this.questionService,
    this.existing,
  });

  @override
  State<_QuestionEditorDialog> createState() => _QuestionEditorDialogState();
}

class _QuestionEditorDialogState extends State<_QuestionEditorDialog> {
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
      (i) => TextEditingController(text: q?.options.elementAtOrNull(i) ?? ''),
    );

    _explanation = TextEditingController(text: q?.explanation ?? '');

    _rationale = TextEditingController(text: q?.bestAnswerRationale ?? '');

    _reference = TextEditingController(text: q?.reference ?? '');

    _tags = TextEditingController(
      text: q?.tags.join(', ') ?? 'Needs Assessment, CSP11',
    );

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
    final q = Question(
      id: widget.existing?.id ?? widget.questionService.nextQuestionId(),
      domain: _domainNumber(widget.content.domainId),
      competencyId: widget.content.competencyId,
      subtopicId: widget.subtopic.id,
      topicId: widget.subtopic.mainContent.isEmpty
          ? ''
          : widget.subtopic.mainContent.first.id,
      quizId: '${widget.content.id}_${widget.subtopic.id}_quiz',
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
      version: widget.existing?.version ?? 1,
      tags: _tags.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
    );

    final issues = widget.questionService.validate(q);

    if (issues.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(issues.map((e) => e.message).join('\n')),
          duration: const Duration(seconds: 5),
        ),
      );
    }

    Navigator.of(context).pop(q);
  }

  int _domainNumber(String domainId) {
    final match = RegExp(r'\d+').firstMatch(domainId);

    return int.tryParse(match?.group(0) ?? '') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.existing == null ? 'Create CSP Question' : 'Edit CSP Question',
      ),
      content: SizedBox(
        width: 820,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SCENARIO + DECISION',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _stem,
                minLines: 6,
                maxLines: 10,
                decoration: const InputDecoration(
                  labelText: 'Question stem',
                  hintText:
                      'Describe the workplace situation, evidence, constraints, and ask for the BEST action/conclusion.',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _cognitive,
                decoration: const InputDecoration(
                  labelText: 'Cognitive level',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'application',
                    child: Text('Application'),
                  ),
                  DropdownMenuItem(value: 'analysis', child: Text('Analysis')),
                ],
                onChanged: (value) {
                  setState(() {
                    _cognitive = value ?? 'analysis';
                  });
                },
              ),
              const SizedBox(height: 18),
              const Text(
                'ANSWER OPTIONS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                  color: Color(0xFF64748B),
                ),
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
                        tooltip: selected
                            ? 'Best answer'
                            : 'Mark as best answer',
                        onPressed: () {
                          setState(() {
                            _correct = i;
                          });
                        },
                        icon: Icon(
                          selected
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_unchecked_rounded,
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
              const SizedBox(height: 4),
              const SizedBox(height: 16),
              TextField(
                controller: _rationale,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Why is this the BEST answer?',
                  helperText:
                      'Explain why this option is the BEST answer based on the scenario.',
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
                  helperText: 'Comma separated',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Authoring rules are checked before publication. '
                'Drafts can be saved while you work.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save Draft')),
      ],
    );
  }
}

extension<T> on List<T> {
  T? elementAtOrNull(int index) {
    if (index >= 0 && index < length) {
      return this[index];
    }

    return null;
  }
}
