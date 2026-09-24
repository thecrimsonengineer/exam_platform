import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'package:exam_platform/theme/glass/student_glass.dart';

import '../../data/csp11_blueprint.dart';
import '../../services/questions/published_question_package.dart';
import '../../services/quiz_service.dart';
import '../../features/learning_twin/coaching/learning_twin_practice_context.dart';
import '../../features/learning_twin/integration/learning_twin_pre_practice_guidance.dart';
import '../../screens/courses/csp/quiz/quiz_screen.dart';

class StudentQuizBuilder extends StatefulWidget {
  const StudentQuizBuilder({super.key});

  @override
  State<StudentQuizBuilder> createState() => _StudentQuizBuilderState();
}

class _StudentQuizBuilderState extends State<StudentQuizBuilder> {
  final QuizService _quizService = QuizService.shared;

  static const int _maxRuntimeScopePackages = 4;

  List<PublishedQuestionPackageDescriptor> _catalog =
      <PublishedQuestionPackageDescriptor>[];

  bool _loading = true;
  bool _startingQuiz = false;
  int _prepareGeneration = 0;

  String _scope = 'all';

  int? _domain;
  String? _competencyId;
  String? _subtopicId;

  String? _difficulty;
  String? _cognitiveLevel;

  int _questionCount = 10;

  int _availableCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final catalog = await _quizService.loadCatalogMetadata();

      if (!mounted) {
        return;
      }

      setState(() {
        _catalog = catalog;
        _loading = false;
        _availableCount = _catalogueScopeCount();
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _availableCount = 0;
      });

      _showMessage('Unable to load the quiz builder.\n$error');
    }
  }

  List<PublishedQuestionPackageDescriptor> get _domainDescriptors {
    final selectedDomain = _domain;
    if (selectedDomain == null) {
      return List<PublishedQuestionPackageDescriptor>.unmodifiable(_catalog);
    }

    final prefix = 'd${selectedDomain.toString().padLeft(2, '0')}_c';
    return _catalog
        .where(
          (descriptor) =>
              descriptor.competencyId.toLowerCase().startsWith(prefix),
        )
        .toList(growable: false);
  }

  List<String> get _competencyIds {
    final values = _domainDescriptors
        .where((descriptor) => descriptor.publishedQuestionCount > 0)
        .map((descriptor) => descriptor.competencyId)
        .toSet()
        .toList()
      ..sort();

    return values;
  }

  List<_SubtopicChoice> get _subtopics {
    final competencyId = _competencyId;
    if (competencyId == null || competencyId.trim().isEmpty) {
      return const <_SubtopicChoice>[];
    }

    final values = <String, _SubtopicChoice>{};

    for (final question in _quizService.getQuestionsByCompetency(competencyId)) {
      final id = question.subtopicId.trim();
      if (id.isEmpty) {
        continue;
      }

      values[id] = _SubtopicChoice(
        id: id,
        title: id.toUpperCase(),
        competencyId: competencyId,
      );
    }

    final result = values.values.toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    return result;
  }

  int _catalogueScopeCount() {
    if (_scope == 'all') {
      return _catalog.fold<int>(
        0,
        (sum, descriptor) => sum + descriptor.publishedQuestionCount,
      );
    }

    if (_scope == 'domain') {
      if (_domain == null) {
        return 0;
      }
      return _domainDescriptors.fold<int>(
        0,
        (sum, descriptor) => sum + descriptor.publishedQuestionCount,
      );
    }

    final competencyId = _competencyId?.trim();
    if (competencyId == null || competencyId.isEmpty) {
      return 0;
    }

    if (_scope == 'subtopic') {
      return _availablePreparedQuestionCount();
    }

    for (final descriptor in _catalog) {
      if (descriptor.competencyId == competencyId) {
        return descriptor.publishedQuestionCount;
      }
    }

    return 0;
  }

  void _refreshCatalogueCount() {
    if (!mounted) {
      return;
    }

    setState(() {
      _availableCount = _catalogueScopeCount();
    });
  }

  void _scheduleSubtopicPreparation() {
    unawaited(_prepareSubtopicScope());
  }

  Future<void> _prepareSubtopicScope() async {
    final generation = ++_prepareGeneration;
    final competencyId = _competencyId?.trim();

    if (competencyId == null || competencyId.isEmpty) {
      _finishPreparation(generation, availableCount: 0);
      return;
    }

    if (mounted) {
      setState(() {
        _loading = true;
        _availableCount = 0;
      });
    }

    try {
      await _quizService.prepareCompetencies(<String>[competencyId]);

      if (!mounted || generation != _prepareGeneration) {
        return;
      }

      if (_subtopicId != null &&
          !_subtopics.any((item) => item.id == _subtopicId)) {
        _subtopicId = null;
      }

      _finishPreparation(
        generation,
        availableCount: _availablePreparedQuestionCount(),
      );
    } catch (error) {
      if (!mounted || generation != _prepareGeneration) {
        return;
      }

      setState(() {
        _loading = false;
        _availableCount = 0;
      });

      _showMessage('Unable to prepare subtopic questions.\n$error');
    }
  }

  Future<void> _prepareCurrentQuizPool() async {
    if (_scope == 'all') {
      await _prepareBoundedDescriptors(_catalog);
      return;
    }

    if (_scope == 'domain') {
      if (_domain == null) {
        throw StateError('Select a domain before starting the quiz.');
      }
      await _prepareBoundedDescriptors(_domainDescriptors);
      return;
    }

    final competencyId = _competencyId?.trim();
    if (competencyId == null || competencyId.isEmpty) {
      throw StateError('Select a competency before starting the quiz.');
    }

    await _quizService.prepareCompetencies(<String>[competencyId]);
  }

  Future<void> _prepareBoundedDescriptors(
    List<PublishedQuestionPackageDescriptor> descriptors,
  ) async {
    final candidates = descriptors
        .where((descriptor) => descriptor.publishedQuestionCount > 0)
        .toList();

    if (candidates.isEmpty) {
      throw StateError('No published question packages exist for this scope.');
    }

    candidates.shuffle(Random());

    final selected = candidates
        .take(_maxRuntimeScopePackages)
        .map((descriptor) => descriptor.competencyId)
        .toList(growable: false);

    await _quizService.prepareCompetencies(selected);
  }

  int _availablePreparedQuestionCount() {
    return _quizService.getAvailableQuestionCount(
      domain: _scope == 'all' ? null : _domain,
      competencyId: _scope == 'competency' || _scope == 'subtopic'
          ? _competencyId
          : null,
      subtopicId: _scope == 'subtopic' ? _subtopicId : null,
      difficulty: _difficulty,
      cognitiveLevel: _cognitiveLevel,
    );
  }

  void _finishPreparation(int generation, {required int availableCount}) {
    if (!mounted || generation != _prepareGeneration) {
      return;
    }

    setState(() {
      _loading = false;
      _availableCount = availableCount;
    });
  }

  void _refreshPreparedCount() {
    if (!mounted) {
      return;
    }

    setState(() {
      _availableCount = _availablePreparedQuestionCount();
    });
  }

  void _changeScope(String value) {
    setState(() {
      _scope = value;

      if (value == 'all') {
        _domain = null;
        _competencyId = null;
        _subtopicId = null;
      } else if (value == 'domain') {
        _competencyId = null;
        _subtopicId = null;
      } else if (value == 'competency') {
        _subtopicId = null;
      } else if (value == 'subtopic') {
        _subtopicId = null;
      }
    });

    if (value == 'subtopic' &&
        _competencyId != null &&
        _competencyId!.trim().isNotEmpty) {
      _scheduleSubtopicPreparation();
    } else {
      _refreshCatalogueCount();
    }
  }

  void _changeDomain(int? value) {
    setState(() {
      _domain = value;
      _competencyId = null;
      _subtopicId = null;
    });

    _refreshCatalogueCount();
  }

  void _changeCompetency(String? value) {
    setState(() {
      _competencyId = value;
      _subtopicId = null;
    });

    if (_scope == 'subtopic') {
      _scheduleSubtopicPreparation();
    } else {
      _refreshCatalogueCount();
    }
  }

  void _changeSubtopic(String? value) {
    setState(() {
      _subtopicId = value;
    });

    _refreshPreparedCount();
  }

  void _changeDifficulty(String? value) {
    setState(() {
      _difficulty = value == 'Any' ? null : value;
    });

    if (_scope == 'subtopic') {
      _refreshPreparedCount();
    } else {
      _refreshCatalogueCount();
    }
  }

  void _changeCognitiveLevel(String? value) {
    setState(() {
      _cognitiveLevel = value == 'Any' ? null : value;
    });

    if (_scope == 'subtopic') {
      _refreshPreparedCount();
    } else {
      _refreshCatalogueCount();
    }
  }

  Future<void> _startQuiz() async {
    if (_startingQuiz) {
      return;
    }

    final scopeCount = _catalogueScopeCount();
    if (scopeCount < _questionCount) {
      _showMessage(
        'Only $scopeCount published questions exist in the selected scope. '
        '$_questionCount were requested.',
      );
      return;
    }

    setState(() => _startingQuiz = true);

    try {
      await _prepareCurrentQuizPool();

      if (!mounted) {
        return;
      }

      final preparedCount = _availablePreparedQuestionCount();
      if (preparedCount < _questionCount) {
        _showMessage(
          'The selected filters produced only $preparedCount questions in the '
          'bounded runtime sample. Try broader filters or another quiz.',
        );
        return;
      }

      final questions = _quizService.buildQuiz(
        domain: _scope == 'all' ? null : _domain,
        competencyId: _scope == 'competency' || _scope == 'subtopic'
            ? _competencyId
            : null,
        subtopicId: _scope == 'subtopic' ? _subtopicId : null,
        numberOfQuestions: _questionCount,
        difficulty: _difficulty,
        cognitiveLevel: _cognitiveLevel,
      );

      if (questions.isEmpty) {
        _showMessage(
          'No published questions match '
          'the selected criteria.',
        );
        return;
      }

      final practiceRouteTheme = Theme.of(context);

      final learningTwinPracticeContext = LearningTwinPracticeContext(
        mode: LearningTwinPracticeMode.customQuiz,
        questionCount: questions.length,
        domainNumber: _scope == 'all' ? null : _domain,
        competencyId: _scope == 'competency' || _scope == 'subtopic'
            ? _competencyId
            : null,
        subtopicId: _scope == 'subtopic' ? _subtopicId : null,
      );

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LearningTwinPracticeSessionHost(
            practiceContext: learningTwinPracticeContext,
            theme: practiceRouteTheme,
            child: QuizScreen(
              domain: _domain ?? 0,
              customQuestions: questions,
              learningTwinPracticeContext: learningTwinPracticeContext,
            ),
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        _showMessage(error.toString().replaceFirst('Bad state: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _startingQuiz = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _competencyLabel(String id) {
    final competency = competencyForId(id);
    if (competency == null) {
      return id;
    }

    return 'Competency ${competency.number} • ${competency.statement}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return StudentGlassCard(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: const [
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 14),
              Text('Preparing CSP11 practice questions...'),
            ],
          ),
        ),
      );
    }

    return StudentGlassCard(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.psychology_rounded,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Practice Quiz',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Build a CSP11 quiz from published questions.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Text(
              'QUIZ SCOPE',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.4,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _scopeChip('all', 'All CSP11'),
                _scopeChip('domain', 'Domain'),
                _scopeChip('competency', 'Competency'),
                _scopeChip('subtopic', 'Subtopic'),
              ],
            ),

            const SizedBox(height: 18),

            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 720;

                final fields = <Widget>[
                  if (_scope != 'all') _buildDomainDropdown(),

                  if (_scope == 'competency' || _scope == 'subtopic')
                    _buildCompetencyDropdown(),

                  if (_scope == 'subtopic') _buildSubtopicDropdown(),

                  _buildQuestionCount(),

                  _buildDifficulty(),

                  _buildCognitiveLevel(),
                ];

                if (!wide) {
                  return Column(
                    children: fields
                        .map(
                          (field) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: SizedBox(
                              width: double.infinity,
                              child: field,
                            ),
                          ),
                        )
                        .toList(),
                  );
                }

                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: fields
                      .map((field) => SizedBox(width: 210, child: field))
                      .toList(),
                );
              },
            ),

            const SizedBox(height: 18),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: _availableCount >= _questionCount
                    ? Colors.green.withValues(alpha: 0.07)
                    : Colors.orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    _availableCount >= _questionCount
                        ? Icons.check_circle
                        : Icons.info_outline,
                    size: 20,
                    color: _availableCount >= _questionCount
                        ? Colors.green
                        : Colors.orange,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '$_availableCount published questions in scope',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    'Need $_questionCount',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),
            Text(
              _scope == 'all' || _scope == 'domain'
                  ? 'The total comes from compact Supabase catalogue metadata. '
                        'Only up to $_maxRuntimeScopePackages competency packages '
                        'are downloaded to assemble each quiz.'
                  : _scope == 'competency'
                  ? 'The total comes from the published competency package metadata.'
                  : 'Subtopic availability is calculated from the selected competency package.',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed:
                    !_startingQuiz && _availableCount >= _questionCount
                    ? _startQuiz
                    : null,
                icon: _startingQuiz
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow_rounded),
                label: Text(
                  _startingQuiz
                      ? 'Preparing quiz...'
                      : 'Start $_questionCount-Question Quiz',
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scopeChip(String value, String label) {
    final selected = _scope == value;

    return ChoiceChip(
      selected: selected,
      label: Text(label),
      onSelected: (_) => _changeScope(value),
    );
  }

  Widget _buildDomainDropdown() {
    return DropdownButtonFormField<int>(
      isExpanded: true,
      menuMaxHeight: 320,
      initialValue: _domain,
      decoration: const InputDecoration(
        labelText: 'Domain',
        border: OutlineInputBorder(),
      ),
      items: csp11Domains
          .map(
            (domain) => DropdownMenuItem<int>(
              value: domain.number,
              child: Text(
                'D${domain.number} • '
                '${domain.title}',
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: _changeDomain,
    );
  }

  Widget _buildCompetencyDropdown() {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      menuMaxHeight: 320,
      initialValue: _competencyIds.contains(_competencyId)
          ? _competencyId
          : null,
      decoration: const InputDecoration(
        labelText: 'Competency',
        border: OutlineInputBorder(),
      ),
      items: _competencyIds
          .map(
            (id) => DropdownMenuItem<String>(
              value: id,
              child: Text(
                _competencyLabel(id),
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: _changeCompetency,
    );
  }

  Widget _buildSubtopicDropdown() {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      menuMaxHeight: 320,
      initialValue: _subtopics.any((item) => item.id == _subtopicId)
          ? _subtopicId
          : null,
      decoration: const InputDecoration(
        labelText: 'Subtopic',
        border: OutlineInputBorder(),
      ),
      items: _subtopics
          .map(
            (item) => DropdownMenuItem<String>(
              value: item.id,
              child: Text(
                item.title,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: _changeSubtopic,
    );
  }

  Widget _buildQuestionCount() {
    return DropdownButtonFormField<int>(
      initialValue: _questionCount,
      decoration: const InputDecoration(
        labelText: 'Questions',
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: 5, child: Text('5 questions')),
        DropdownMenuItem(value: 10, child: Text('10 questions')),
        DropdownMenuItem(value: 20, child: Text('20 questions')),
        DropdownMenuItem(value: 40, child: Text('40 questions')),
      ],
      onChanged: (value) {
        if (value == null) {
          return;
        }

        setState(() {
          _questionCount = value;
        });

        if (_scope == 'subtopic') {
          _refreshPreparedCount();
        } else {
          _refreshCatalogueCount();
        }
      },
    );
  }

  Widget _buildDifficulty() {
    return DropdownButtonFormField<String>(
      initialValue: _difficulty ?? 'Any',
      decoration: const InputDecoration(
        labelText: 'Difficulty',
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: 'Any', child: Text('Any difficulty')),
        DropdownMenuItem(value: 'Hard', child: Text('Hard')),
        DropdownMenuItem(value: 'Medium', child: Text('Medium')),
        DropdownMenuItem(value: 'Easy', child: Text('Easy')),
      ],
      onChanged: _changeDifficulty,
    );
  }

  Widget _buildCognitiveLevel() {
    return DropdownButtonFormField<String>(
      initialValue: _cognitiveLevel ?? 'Any',
      decoration: const InputDecoration(
        labelText: 'Cognitive level',
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: 'Any', child: Text('Any level')),
        DropdownMenuItem(value: 'Application', child: Text('Application')),
        DropdownMenuItem(value: 'Analysis', child: Text('Analysis')),
      ],
      onChanged: _changeCognitiveLevel,
    );
  }
}

class _SubtopicChoice {
  final String id;
  final String title;
  final String competencyId;

  const _SubtopicChoice({
    required this.id,
    required this.title,
    required this.competencyId,
  });
}
