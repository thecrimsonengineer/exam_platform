import 'package:flutter/material.dart';

import '../../../models/question.dart';
import '../../../models/studio_question_context.dart';
import '../../../models/study_content.dart';
import '../../../services/complete_question_paste_parser.dart';
import '../../../services/question_bank_service.dart';
import '../../../services/question_quality_validator.dart';
import '../../../services/study_content/local_study_content_repository.dart';
import 'study_content/study_content_studio_screen.dart';

class QuestionBankScreen extends StatefulWidget {
  final int? initialQuestionId;

  const QuestionBankScreen({super.key, this.initialQuestionId});

  @override
  State<QuestionBankScreen> createState() => _QuestionBankScreenState();
}

class _QuestionBankScreenState extends State<QuestionBankScreen> {
  final LocalStudyContentRepository _contentRepository =
      LocalStudyContentRepository();

  final QuestionBankService _questionService = QuestionBankService();

  final CompleteQuestionPasteParser _pasteParser =
      const CompleteQuestionPasteParser();

  List<StudyContent> _content = <StudyContent>[];

  StudyContent? _selectedContent;

  int? _selectedSubtopicIndex;

  List<Question> _questions = <Question>[];

  bool _loading = true;

  bool _answerLengthCheckEnabled = true;

  int? _focusedQuestionId;

  @override
  void initState() {
    super.initState();

    _questionService.answerLengthCheckEnabled = true;

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

    final initialQuestionId = widget.initialQuestionId;
    Question? initialQuestion;

    if (initialQuestionId != null) {
      for (final question in _questionService.allManagedQuestions()) {
        if (question.id == initialQuestionId) {
          initialQuestion = question;
          break;
        }
      }
    }

    StudyContent? initialContent;
    int? initialSubtopicIndex;

    final resolvedInitialQuestion = initialQuestion;

    if (resolvedInitialQuestion != null) {
      for (final item in items) {
        final packageMatches =
            resolvedInitialQuestion.contentPackageId.trim().isNotEmpty &&
            item.id == resolvedInitialQuestion.contentPackageId;

        if (packageMatches ||
            item.competencyId == resolvedInitialQuestion.competencyId) {
          final subtopicIndex = item.subtopics.indexWhere(
            (subtopic) => subtopic.id == resolvedInitialQuestion.subtopicId,
          );

          if (subtopicIndex >= 0) {
            initialContent = item;
            initialSubtopicIndex = subtopicIndex;
            break;
          }
        }
      }
    }

    setState(() {
      _content = items;
      _selectedContent = initialContent ?? (items.isEmpty ? null : items.first);
      final selectedContent = _selectedContent;
      _selectedSubtopicIndex =
          initialSubtopicIndex ??
          (selectedContent == null || selectedContent.subtopics.isEmpty
              ? null
              : 0);
      _focusedQuestionId = initialQuestion?.id;
      _loading = false;
    });

    _refreshQuestions();

    if (initialQuestion != null) {
      _scheduleFocusQuestion(initialQuestion.id);
    }
  }

  String _quizId(StudyContent content, StudySubtopic subtopic) {
    return StudioQuestionContext.canonicalQuizId(content.id, subtopic.id);
  }

  void _scheduleFocusQuestion(int questionId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final targetContext = _questionCardKeys[questionId]?.currentContext;

      if (targetContext != null) {
        Scrollable.ensureVisible(
          targetContext,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          alignment: 0.12,
        );
      }
    });
  }

  final Map<int, GlobalKey> _questionCardKeys = <int, GlobalKey>{};

  void _openQuestionInPracticeQuestions(Question question) {
    final content = _selectedContent;

    if (content == null) {
      _showError(
        'Unable to locate the Study Content package for this question.',
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StudyContentStudioScreen(
          initialContent: content,
          initialQuestionId: question.id,
        ),
      ),
    );
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

    await _saveDraftWithQualityFeedback(result);

    _refreshQuestions();
  }

  Future<void> _openCompletePaste() async {
    final content = _selectedContent;

    final index = _selectedSubtopicIndex;

    if (content == null ||
        index == null ||
        index < 0 ||
        index >= content.subtopics.length) {
      _showError('Select a competency and subtopic first.');

      return;
    }

    final result = await showDialog<Question>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return _CompleteQuestionPasteDialog(
          parser: _pasteParser,
          questionService: _questionService,
          content: content,
          subtopic: content.subtopics[index],
          answerLengthCheckEnabled: _answerLengthCheckEnabled,
        );
      },
    );

    if (result == null) {
      return;
    }

    await _saveDraftWithQualityFeedback(
      result,
      successMessage: 'Complete question imported as Draft.',
    );

    _refreshQuestions();
  }

  Future<void> _saveDraftWithQualityFeedback(
    Question question, {
    String? successMessage,
  }) async {
    final issues = _questionService.validate(question);

    await _questionService.saveDraft(question);

    if (!mounted) {
      return;
    }

    final errors = issues
        .where((issue) => issue.isError)
        .map((issue) => issue.message)
        .toList();

    if (errors.isNotEmpty) {
      _showError(
        'Question saved as Draft with quality issues:\n\n'
        '${errors.join('\n')}',
      );
      return;
    }

    if (successMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
    }
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

  void _setAnswerLengthCheck(bool enabled) {
    setState(() {
      _answerLengthCheckEnabled = enabled;
    });

    _questionService.answerLengthCheckEnabled = enabled;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message.replaceFirst('Bad state: ', '')),
        backgroundColor: Colors.red.shade700,
      ),
    );
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
          _buildAnswerLengthControl(),
        ],
      ),
    );
  }

  Widget _buildAnswerLengthControl() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: _answerLengthCheckEnabled
            ? const Color(0xFFEFF6FF)
            : const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _answerLengthCheckEnabled
              ? const Color(0xFFBFDBFE)
              : const Color(0xFFFED7AA),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Answer Length Check',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: _answerLengthCheckEnabled
                  ? const Color(0xFF1E40AF)
                  : const Color(0xFF9A3412),
            ),
          ),
          const SizedBox(width: 6),
          Switch(
            value: _answerLengthCheckEnabled,
            onChanged: _setAnswerLengthCheck,
          ),
          Text(
            _answerLengthCheckEnabled ? 'ON' : 'OFF',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: _answerLengthCheckEnabled
                  ? Colors.green.shade700
                  : Colors.orange.shade800,
            ),
          ),
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
                  _focusedQuestionId = null;
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
          const _RuleRow('Best answer', 'Exactly 1'),
          _RuleRow(
            'Answer length',
            _answerLengthCheckEnabled ? 'Checked' : 'Disabled',
          ),
          const _RuleRow('Explanation', 'Required'),
          const _RuleRow('Reference', 'Required'),
          const _RuleRow('Subtopic quota', 'Exactly 5'),
          if (!_answerLengthCheckEnabled)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text(
                'Answer Length Check disabled. '
                'All other quality checks remain active.',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF9A3412),
                ),
              ),
            ),
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

    final ready = _questions.length >= 5 && publishedCount >= 5;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subtopic.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Quiz ID: $quizId',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _openCompletePaste,
                  icon: const Icon(Icons.content_paste_rounded),
                  label: const Text('Paste Complete Question'),
                ),
                const SizedBox(width: 10),
                FilledButton.icon(
                  onPressed: () => _openEditor(),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Create Question'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _metric('Questions', '${_questions.length}/5'),
                const SizedBox(width: 10),
                _metric('Published', '$publishedCount/5'),
                const SizedBox(width: 10),
                _metric('Status', ready ? 'READY' : 'BUILDING'),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: _questions.isEmpty
                ? _emptyState()
                : ListView.separated(
                    itemCount: _questions.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      return _questionCard(_questions[index], index);
                    },
                  ),
          ),
          if (ready)
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _attachQuizToContent,
                icon: const Icon(Icons.link_rounded),
                label: const Text('Link Quiz to Student Content'),
              ),
            ),
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
        constraints: const BoxConstraints(maxWidth: 560),
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
              Icons.content_paste_rounded,
              size: 44,
              color: Color(0xFF64748B),
            ),
            SizedBox(height: 14),
            Text(
              'Build the question set',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 8),
            Text(
              'Use Paste Complete Question to '
              'populate an entire question in one operation.',
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

    final cardKey = _questionCardKeys.putIfAbsent(
      question.id,
      () => GlobalKey(),
    );
    final focused = _focusedQuestionId == question.id;

    return KeyedSubtree(
      key: cardKey,
      child: Card(
        elevation: 0,
        color: focused ? const Color(0xFFEFF6FF) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Q${index + 1}',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(width: 10),
                    Chip(label: Text(question.difficulty)),
                    const SizedBox(width: 6),
                    Chip(label: Text(question.cognitiveLevel.toUpperCase())),
                    const SizedBox(width: 12),
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
                final optionIndex = entry.key;

                final isBest = optionIndex == question.correctAnswer;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 24,
                        child: Text(
                          String.fromCharCode(65 + optionIndex),
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

              if (question.tags.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Text(
                  'TAGS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: question.tags
                      .map(
                        (tag) => Chip(
                          label: Text(tag),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      )
                      .toList(),
                ),
              ],

              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      valid
                          ? 'Quality gate: PASS'
                          : 'Quality gate: '
                                '${issues.length} issue(s)',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: valid
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                      ),
                    ),
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: () => _openEditor(question: question),
                      child: const Text('Edit'),
                    ),
                    TextButton.icon(
                      onPressed: () =>
                          _openQuestionInPracticeQuestions(question),
                      icon: const Icon(Icons.open_in_new_rounded, size: 17),
                      label: const Text('Open in Practice'),
                    ),
                    if (!published)
                      FilledButton.tonal(
                        onPressed: valid
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
              ),
            ],
          ),
        ),
      ),
    );
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

    if (_questions.length < 5 ||
        _questions.where((q) => q.status.toLowerCase() == 'published').length <
            5) {
      _showError(
        'The subtopic must have at least 5 published questions before the quiz can be linked.',
      );

      return;
    }

    if (subtopic.quizzes.any((quiz) => quiz.quizId == quizId)) {
      _showError('This quiz is already linked to the subtopic.');

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
        'Link the quiz to the draft version first. Publish the content version after linking.',
      );

      return;
    }

    await _contentRepository.saveDraft(updatedContent);

    await _load();

    _showSuccess('Quiz linked to the subtopic.');
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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

class _CompleteQuestionPasteDialog extends StatefulWidget {
  final CompleteQuestionPasteParser parser;
  final QuestionBankService questionService;
  final StudyContent content;
  final StudySubtopic subtopic;
  final bool answerLengthCheckEnabled;

  const _CompleteQuestionPasteDialog({
    required this.parser,
    required this.questionService,
    required this.content,
    required this.subtopic,
    required this.answerLengthCheckEnabled,
  });

  @override
  State<_CompleteQuestionPasteDialog> createState() =>
      _CompleteQuestionPasteDialogState();
}

class _CompleteQuestionPasteDialogState
    extends State<_CompleteQuestionPasteDialog> {
  final TextEditingController _pasteController = TextEditingController();

  Question? _previewQuestion;

  String? _parseError;

  bool _parsing = false;

  @override
  void dispose() {
    _pasteController.dispose();
    super.dispose();
  }

  void _parse() {
    setState(() {
      _parsing = true;
      _parseError = null;
      _previewQuestion = null;
    });

    try {
      final parsed = widget.parser.parse(_pasteController.text);

      final baseQuestion = parsed.toQuestion(
        id: widget.questionService.nextQuestionId(),
        domain: _domainNumber(widget.content.domainId),
        competencyId: widget.content.competencyId,
        subtopicId: widget.subtopic.id,
        topicId: widget.subtopic.mainContent.isEmpty
            ? ''
            : widget.subtopic.mainContent.first.id,
        quizId: StudioQuestionContext.canonicalQuizId(
        widget.content.id,
        widget.subtopic.id,
      ),
        contentPackageId: widget.content.id,
      );

      // Preserve the tags parsed from the complete paste.
      // The Question model supports JSON serialization, so rebuild the
      // Question with the parsed tags explicitly attached.
      final question = Question.fromJson({
        ...baseQuestion.toJson(),
        'tags': List<String>.from(parsed.tags),
      });

      setState(() {
        _previewQuestion = question;
        _parsing = false;
      });
    } catch (error) {
      setState(() {
        _parseError = error.toString().replaceFirst('FormatException: ', '');
        _parsing = false;
      });
    }
  }

  int _domainNumber(String domainId) {
    final match = RegExp(r'\d+').firstMatch(domainId);

    return int.tryParse(match?.group(0) ?? '') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final question = _previewQuestion;

    final issues = question == null
        ? <QuestionQualityIssue>[]
        : widget.questionService.validate(question);

    final hasErrors = issues.any((issue) => issue.isError);

    return AlertDialog(
      title: const Text('Paste Complete Question'),
      content: SizedBox(
        width: 900,
        height: 650,
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Paste the complete question below. '
                'The current repository context will be attached automatically.',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _pasteController,
                      expands: true,
                      maxLines: null,
                      minLines: null,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: const InputDecoration(
                        hintText: '''QUESTION:
Describe the question here.

OPTION A:
First answer.

OPTION B:
Second answer.

OPTION C:
Third answer.

OPTION D:
Fourth answer.

BEST ANSWER:
C

EXPLANATION:
Explain why the BEST answer is correct.

REFERENCE:
BCSP CSP11 Examination Blueprint

TAGS:
training needs analysis, competency assessment, CSP11''',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: _buildPreview(question, issues)),
                ],
              ),
            ),
            if (_parseError != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Text(
                  _parseError!,
                  style: const TextStyle(
                    color: Color(0xFF991B1B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton.icon(
                onPressed: _parsing ? null : _parse,
                icon: const Icon(Icons.preview_rounded),
                label: Text(_parsing ? 'Parsing...' : 'Parse & Preview'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: question == null || hasErrors
                    ? null
                    : () => Navigator.pop(context, question),
                icon: const Icon(Icons.save_rounded),
                label: const Text('Import as Draft'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreview(Question? question, List<QuestionQualityIssue> issues) {
    if (question == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(
          child: Text(
            'Preview will appear here after parsing.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64748B)),
          ),
        ),
      );
    }

    final qualityPassed = issues.isEmpty;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'PREVIEW',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    qualityPassed
                        ? 'QUALITY PASS'
                        : '${issues.length} ISSUE(S)',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: qualityPassed
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              question.question,
              style: const TextStyle(fontWeight: FontWeight.w700, height: 1.4),
            ),
            const SizedBox(height: 14),
            ...question.options.asMap().entries.map((entry) {
              final isBest = entry.key == question.correctAnswer;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 22,
                      child: Text(
                        String.fromCharCode(65 + entry.key),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Expanded(child: Text(entry.value)),
                    if (isBest)
                      const Padding(
                        padding: EdgeInsets.only(left: 6),
                        child: Chip(label: Text('BEST')),
                      ),
                  ],
                ),
              );
            }),
            const Divider(height: 24),
            const Text(
              'EXPLANATION',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 5),
            Text(question.explanation),
            const SizedBox(height: 14),
            const Text(
              'REFERENCE',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 5),
            Text(question.reference),
            const SizedBox(height: 14),
            const Text(
              'TAGS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 5),
            Text(question.tags.join(', ')),
            const SizedBox(height: 14),
            if (issues.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'QUALITY CHECK',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF991B1B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...issues.map(
                      (issue) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '• ${issue.message}',
                          style: const TextStyle(color: Color(0xFF991B1B)),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '✓ Question passes the current quality gate.',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF166534),
                  ),
                ),
              ),
            if (!widget.answerLengthCheckEnabled)
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text(
                  '⚠ Answer Length Check disabled.',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF9A3412),
                  ),
                ),
              ),
          ],
        ),
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

    _tags = TextEditingController(text: q?.tags.join(', ') ?? 'CSP11');

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
      quizId: StudioQuestionContext.canonicalQuizId(
        widget.content.id,
        widget.subtopic.id,
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
      version: widget.existing?.version ?? 1,
      tags: _tags.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
    );

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
              TextField(
                controller: _stem,
                minLines: 6,
                maxLines: 10,
                decoration: const InputDecoration(
                  labelText: 'Question stem',
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
              const SizedBox(height: 12),
              TextField(
                controller: _rationale,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Why is this the BEST answer?',
                  helperText: 'Optional authoring rationale.',
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
