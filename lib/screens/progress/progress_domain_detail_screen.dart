import 'package:flutter/material.dart';

import 'package:exam_platform/theme/glass/student_glass.dart';

import '../../app/theme.dart';
import '../../models/student_progress_dashboard.dart';
import '../../services/progress_domain_detail_service.dart';
import 'widgets/progress_charts.dart';

class ProgressDomainDetailScreen extends StatefulWidget {
  final String domainId;
  final int domainNumber;
  final String domainTitle;
  final bool isDarkMode;

  const ProgressDomainDetailScreen({
    super.key,
    required this.domainId,
    required this.domainNumber,
    required this.domainTitle,
    required this.isDarkMode,
  });

  @override
  State<ProgressDomainDetailScreen> createState() =>
      _ProgressDomainDetailScreenState();
}

class _ProgressDomainDetailScreenState
    extends State<ProgressDomainDetailScreen> {
  final ProgressDomainDetailService _service =
      const ProgressDomainDetailService();

  StudentDomainProgress? _domain;
  bool _loading = true;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final cached = await _service.loadCachedDomain(widget.domainId);

      if (mounted && cached != null) {
        setState(() {
          _domain = cached;
          _loading = false;
        });
      }
    } catch (_) {
      // Cloud load below remains authoritative.
    }

    await _refresh();
  }

  Future<void> _refresh() async {
    if (_refreshing) {
      return;
    }

    if (mounted) {
      setState(() {
        _refreshing = true;
      });
    }

    try {
      final fresh = await _service.loadAuthoritativeDomain(widget.domainId);

      if (!mounted) {
        return;
      }

      setState(() {
        _domain = fresh;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
      });
    } finally {
      if (mounted) {
        setState(() {
          _refreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme;

    return Theme(
      data: theme,
      child: Builder(builder: _buildThemed),
    );
  }

  Widget _buildThemed(BuildContext context) {
    final domain = _domain;
    final scheme = Theme.of(context).colorScheme;
    final background = widget.isDarkMode
        ? const Color(0xFF0A111D)
        : const Color(0xFFF6F8FC);

    return StudentGlassScaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Domain ${widget.domainNumber.toString().padLeft(2, '0')} analytics',
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh domain analytics',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: widget.isDarkMode
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0A111D),
                    Color(0xFF0D1624),
                    Color(0xFF111827),
                  ],
                )
              : const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFF8FAFD),
                    Color(0xFFF3F7FC),
                    Color(0xFFF7F9FC),
                  ],
                ),
        ),
        child: domain == null
            ? (_loading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorState(context))
            : Stack(
                children: [
                  RefreshIndicator(
                    onRefresh: _refresh,
                    child: _content(context, domain),
                  ),
                  if (_refreshing)
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      child: LinearProgressIndicator(
                        minHeight: 2,
                        color: scheme.primary,
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _content(BuildContext context, StudentDomainProgress domain) {
    final accuracy = domain.answeredQuestions == 0
        ? 0.0
        : domain.correctQuestions / domain.answeredQuestions;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 40),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.isDarkMode
                  ? const [
                      Color(0xFF102A56),
                      Color(0xFF1E4C91),
                      Color(0xFF4B318B),
                    ]
                  : const [
                      Color(0xFF0B63CE),
                      Color(0xFF2C77D8),
                      Color(0xFF6A4CC3),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DOMAIN ${domain.domainNumber.toString().padLeft(2, '0')}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                domain.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 18),
              LinearProgressIndicator(
                value: domain.subtopicProgress,
                minHeight: 9,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              const SizedBox(height: 9),
              Text(
                '${(domain.subtopicProgress * 100).round()}% complete',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _metricGrid(context, domain, accuracy),
        const SizedBox(height: 16),
        ProgressPanel(
          title: 'Domain accuracy',
          subtitle: 'Unique answered questions in this domain',
          child: AccuracyDonut(
            accuracy: accuracy,
            answered: domain.answeredQuestions,
            correct: domain.correctQuestions,
          ),
        ),
        const SizedBox(height: 16),
        ProgressPanel(
          title: 'Competency analytics',
          subtitle: 'Completion and question performance by competency',
          child: _competencyTable(context, domain),
        ),
        const SizedBox(height: 16),
        ...domain.competencies.map(
          (competency) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _competencyCard(context, competency),
          ),
        ),
      ],
    );
  }

  Widget _metricGrid(
    BuildContext context,
    StudentDomainProgress domain,
    double accuracy,
  ) {
    final items = <(String, String, IconData)>[
      (
        '${domain.completedTopics}/${domain.topicCount}',
        'Topics complete',
        Icons.layers_rounded,
      ),
      (
        '${domain.completedSubtopics}/${domain.subtopicCount}',
        'Subtopics complete',
        Icons.check_circle_rounded,
      ),
      ('${domain.answeredQuestions}', 'Questions answered', Icons.quiz_rounded),
      (
        '${(accuracy * 100).round()}%',
        'Question accuracy',
        Icons.track_changes_rounded,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 700
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items
              .map((item) {
                return SizedBox(
                  width: width,
                  child: _metricCard(context, item.$1, item.$2, item.$3),
                );
              })
              .toList(growable: false),
        );
      },
    );
  }

  Widget _metricCard(
    BuildContext context,
    String value,
    String label,
    IconData icon,
  ) {
    final scheme = Theme.of(context).colorScheme;

    return StudentGlassSurface(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(18),
      tint: scheme.surfaceContainerLow.withValues(alpha: 0.52),
      borderColor: scheme.outlineVariant.withValues(alpha: 0.64),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: scheme.primaryContainer,
            foregroundColor: scheme.onPrimaryContainer,
            child: Icon(icon, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _competencyTable(BuildContext context, StudentDomainProgress domain) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Competency')),
          DataColumn(label: Text('Topics')),
          DataColumn(label: Text('Subtopics')),
          DataColumn(label: Text('Questions')),
          DataColumn(label: Text('Accuracy')),
        ],
        rows: domain.competencies
            .map((competency) {
              final accuracy = competency.answeredQuestions == 0
                  ? 0
                  : (competency.correctQuestions /
                            competency.answeredQuestions *
                            100)
                        .round();

              return DataRow(
                cells: [
                  DataCell(
                    SizedBox(
                      width: 220,
                      child: Text(
                        'C${competency.competencyNumber.toString().padLeft(2, '0')} · ${competency.title}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      '${competency.completedTopics}/${competency.topicCount}',
                    ),
                  ),
                  DataCell(
                    Text(
                      '${competency.completedSubtopics}/${competency.subtopicCount}',
                    ),
                  ),
                  DataCell(Text('${competency.answeredQuestions}')),
                  DataCell(Text('$accuracy%')),
                ],
              );
            })
            .toList(growable: false),
      ),
    );
  }

  Widget _competencyCard(
    BuildContext context,
    StudentCompetencyProgressDetail competency,
  ) {
    final scheme = Theme.of(context).colorScheme;

    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(18),
      ),
      collapsedShape: RoundedRectangleBorder(
        side: BorderSide(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(18),
      ),
      title: Text(
        'Competency ${competency.competencyNumber}',
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        competency.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        '${(competency.subtopicProgress * 100).round()}%',
        style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w900),
      ),
      children: competency.topics
          .map((topic) {
            final accuracy = topic.answeredQuestions == 0
                ? 0
                : (topic.correctQuestions / topic.answeredQuestions * 100)
                      .round();

            return Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          topic.title,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text('$accuracy% accuracy'),
                    ],
                  ),
                  const SizedBox(height: 7),
                  LinearProgressIndicator(value: topic.progress, minHeight: 7),
                  const SizedBox(height: 5),
                  Text(
                    '${topic.completedSubtopics}/${topic.subtopicCount} subtopics · '
                    '${topic.answeredQuestions} questions answered',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            );
          })
          .toList(growable: false),
    );
  }

  Widget _errorState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.insights_rounded, size: 44),
            const SizedBox(height: 12),
            const Text('Domain analytics could not be loaded.'),
            const SizedBox(height: 14),
            FilledButton(onPressed: _refresh, child: const Text('TRY AGAIN')),
          ],
        ),
      ),
    );
  }
}
