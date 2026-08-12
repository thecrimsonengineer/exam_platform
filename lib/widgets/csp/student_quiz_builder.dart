import 'package:flutter/material.dart';

import '../../data/csp11_blueprint.dart';
import '../../models/content_repository.dart';
import '../../services/quiz_service.dart';
import '../../services/study_content/content_repository_service.dart';
import '../../screens/courses/csp/quiz/quiz_screen.dart';

class StudentQuizBuilder extends StatefulWidget {
  const StudentQuizBuilder({super.key});

  @override
  State<StudentQuizBuilder> createState() => _StudentQuizBuilderState();
}

class _StudentQuizBuilderState extends State<StudentQuizBuilder> {
  final QuizService _quizService = QuizService();
  final ContentRepositoryService _contentService = ContentRepositoryService();

  List<ContentPackageSummary> _packages = <ContentPackageSummary>[];

  bool _loading = true;

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
      await _quizService.initialize();

      final packages = await _contentService.loadPackages();

      final published = packages
          .where(
            (package) =>
                package.isPublishedCopy &&
                package.content.status.toLowerCase() == 'published',
          )
          .toList();

      if (!mounted) {
        return;
      }

      setState(() {
        _packages = published;
        _loading = false;
      });

      _refreshAvailableCount();
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
      });

      _showMessage('Unable to load the quiz builder.\n$error');
    }
  }

  List<ContentPackageSummary> get _publishedPackages {
    return _packages;
  }

  List<ContentPackageSummary> get _domainPackages {
    if (_domain == null) {
      return _publishedPackages;
    }

    return _publishedPackages
        .where(
          (package) =>
              domainForContentId(package.content.domainId)?.number == _domain,
        )
        .toList();
  }

  List<ContentPackageSummary> get _competencyPackages {
    if (_competencyId == null) {
      return _domainPackages;
    }

    return _domainPackages
        .where((package) => package.content.competencyId == _competencyId)
        .toList();
  }

  List<String> get _competencyIds {
    final values = _domainPackages
        .map((package) => package.content.competencyId)
        .where((id) => id.trim().isNotEmpty)
        .toSet()
        .toList();

    values.sort();

    return values;
  }

  List<_SubtopicChoice> get _subtopics {
    final values = <String, _SubtopicChoice>{};

    for (final package in _competencyPackages) {
      for (final subtopic in package.content.subtopics) {
        values[subtopic.id] = _SubtopicChoice(
          id: subtopic.id,
          title: subtopic.title,
          competencyId: package.content.competencyId,
        );
      }
    }

    final result = values.values.toList();

    result.sort((a, b) => a.title.compareTo(b.title));

    return result;
  }

  void _refreshAvailableCount() {
    final count = _quizService.getAvailableQuestionCount(
      domain: _scope == 'all' ? null : _domain,
      competencyId: _scope == 'competency' || _scope == 'subtopic'
          ? _competencyId
          : null,
      subtopicId: _scope == 'subtopic' ? _subtopicId : null,
      difficulty: _difficulty,
      cognitiveLevel: _cognitiveLevel,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _availableCount = count;
    });
  }

  void _changeScope(String value) {
    setState(() {
      _scope = value;

      if (value == 'all') {
        _domain = null;
        _competencyId = null;
        _subtopicId = null;
      }

      if (value == 'domain') {
        _competencyId = null;
        _subtopicId = null;
      }

      if (value == 'competency') {
        _subtopicId = null;
      }

      if (value == 'subtopic') {
        _subtopicId = null;
      }
    });

    _refreshAvailableCount();
  }

  void _changeDomain(int? value) {
    setState(() {
      _domain = value;
      _competencyId = null;
      _subtopicId = null;
    });

    _refreshAvailableCount();
  }

  void _changeCompetency(String? value) {
    setState(() {
      _competencyId = value;
      _subtopicId = null;
    });

    _refreshAvailableCount();
  }

  void _changeSubtopic(String? value) {
    setState(() {
      _subtopicId = value;
    });

    _refreshAvailableCount();
  }

  void _changeDifficulty(String? value) {
    setState(() {
      _difficulty = value == 'Any' ? null : value;
    });

    _refreshAvailableCount();
  }

  void _changeCognitiveLevel(String? value) {
    setState(() {
      _cognitiveLevel = value == 'Any' ? null : value;
    });

    _refreshAvailableCount();
  }

  void _startQuiz() {
    if (_availableCount < _questionCount) {
      _showMessage(
        'Only $_availableCount published questions '
        'are available for the selected criteria. '
        '$_questionCount were requested.',
      );
      return;
    }

    try {
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

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              QuizScreen(domain: _domain ?? 0, customQuestions: questions),
        ),
      );
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Bad state: ', ''));
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _competencyLabel(String id) {
    for (final package in _domainPackages) {
      if (package.content.competencyId == id) {
        return 'Competency '
            '${package.content.competencyNumber} • '
            '${package.content.title}';
      }
    }

    return id;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Card(
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

    return Card(
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
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Practice Quiz',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Build a CSP11 quiz from published questions.',
                        style: TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            const Text(
              'QUIZ SCOPE',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.4,
                color: Colors.black54,
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
                      '$_availableCount published '
                      'questions available',
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

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _availableCount >= _questionCount
                    ? _startQuiz
                    : null,
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text('Start $_questionCount-Question Quiz'),
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
              child: Text(item.title, overflow: TextOverflow.ellipsis),
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
