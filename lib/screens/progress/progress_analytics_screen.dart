import 'package:flutter/material.dart';

import 'package:exam_platform/theme/glass/student_glass.dart';

import '../../app/theme.dart';
import '../courses/csp/domain_screen.dart';
import '../courses/csp/domain_screen_dark.dart';
import '../../features/learning_twin/integration/learning_twin_progress_guidance.dart';
import '../../models/progress_analytics_snapshot.dart';
import '../../models/student_progress_dashboard.dart';
import '../../services/progress_analytics_event_bus.dart';
import '../../services/progress_overview_snapshot_service.dart';
import 'progress_domain_detail_screen.dart';
import 'widgets/progress_charts.dart';

class ProgressAnalyticsScreen extends StatefulWidget {
  final Future<StudentProgressDashboard> Function()? dashboardLoader;
  final bool isDarkMode;

  const ProgressAnalyticsScreen({
    super.key,
    this.dashboardLoader,
    required this.isDarkMode,
  });

  @override
  State<ProgressAnalyticsScreen> createState() =>
      ProgressAnalyticsScreenState();
}

class ProgressAnalyticsScreenState extends State<ProgressAnalyticsScreen> {
  final ProgressOverviewSnapshotService _service =
      const ProgressOverviewSnapshotService();

  ProgressAnalyticsSnapshot? _snapshot;
  bool _initialLoading = true;
  bool _refreshing = false;
  Object? _error;
  DateTime? _lastAuthoritativeRefresh;

  @override
  void initState() {
    super.initState();

    _snapshot = _service.peek();
    _initialLoading = _snapshot == null;

    _loadCachedThenRevalidate();
  }

  Future<void> onVisible() async {
    final stale =
        _lastAuthoritativeRefresh == null ||
        DateTime.now().difference(_lastAuthoritativeRefresh!) >
            const Duration(minutes: 3);

    if (ProgressAnalyticsEventBus.isDirty) {
      await _reconcileLocal();
    }

    if (stale) {
      await _refreshAuthoritative(silent: _snapshot != null);
    }
  }

  Future<void> refresh() async {
    await _refreshAuthoritative(silent: false);
  }

  Future<void> _loadCachedThenRevalidate() async {
    try {
      final cached = await _service.loadCached();

      if (mounted && cached != null) {
        setState(() {
          _snapshot = cached;
          _initialLoading = false;
          _error = null;
        });
      }

      if (ProgressAnalyticsEventBus.isDirty || cached == null) {
        await _reconcileLocal();
      }
    } catch (_) {
      // Authoritative refresh below remains the final source.
    }

    await _refreshAuthoritative(silent: _snapshot != null);
  }

  Future<void> _reconcileLocal() async {
    try {
      final local = await _service.bootstrapLocal();

      if (!mounted || local == null) {
        return;
      }

      setState(() {
        _snapshot = local;
        _initialLoading = false;
        _error = null;
      });
    } catch (_) {
      // Local snapshot acceleration is optional.
    }
  }

  Future<void> _refreshAuthoritative({required bool silent}) async {
    if (_refreshing) {
      return;
    }

    if (mounted) {
      setState(() {
        _refreshing = true;
      });
    }

    try {
      final fresh = await _service.refreshAuthoritative(
        dashboardLoader: widget.dashboardLoader,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _snapshot = fresh;
        _initialLoading = false;
        _error = null;
        _lastAuthoritativeRefresh = DateTime.now();
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = error;
        _initialLoading = false;
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
    final snapshot = _snapshot;
    final scheme = Theme.of(context).colorScheme;
    final background = widget.isDarkMode
        ? const Color(0xFF0A111D)
        : const Color(0xFFF6F8FC);

    return StudentGlassScaffold(
      backgroundColor: background,
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
        child: SafeArea(
          child: snapshot == null
              ? (_initialLoading
                    ? _loadingShell(context)
                    : _errorState(context))
              : Stack(
                  children: [
                    RefreshIndicator(
                      onRefresh: refresh,
                      child: _dashboard(context, snapshot),
                    ),
                    if (_refreshing)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: LinearProgressIndicator(
                          minHeight: 2,
                          color: scheme.primary,
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _dashboard(BuildContext context, ProgressAnalyticsSnapshot snapshot) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = width >= 1100
        ? 28.0
        : width >= 700
        ? 22.0
        : 14.0;

    return CustomScrollView(
      key: const PageStorageKey<String>('progress-analytics-v2-scroll'),
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        SliverAppBar(
          pinned: true,
          automaticallyImplyLeading: false,
          title: const Text('Progress analytics'),
          actions: [
            IconButton(
              tooltip: 'Refresh analytics',
              onPressed: refresh,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(horizontal, 14, horizontal, 42),
          sliver: SliverList(
            delegate: SliverChildListDelegate.fixed([
              _hero(context, snapshot),
              const SizedBox(height: 16),
              LearningTwinProgressGuidance(
                snapshot: snapshot,
                onOpenDomain: (domainId) =>
                    _openLearningDomain(context, snapshot, domainId),
              ),
              const SizedBox(height: 16),
              _kpiGrid(context, snapshot),
              const SizedBox(height: 16),
              _responsivePair(
                context,
                ProgressPanel(
                  title: 'Learning time · 7 days',
                  subtitle: 'Foreground app time recorded on this device',
                  child: WeeklyActivityLineChart(
                    values: snapshot.dailyActivity,
                  ),
                ),
                ProgressPanel(
                  title: 'Weekly activity heatmap',
                  subtitle:
                      '${snapshot.activeDays} active days · ${_formatMinutes(snapshot.weeklyMinutes)} total',
                  child: WeeklyActivityHeatmap(values: snapshot.dailyActivity),
                ),
              ),
              const SizedBox(height: 16),
              _responsivePair(
                context,
                ProgressPanel(
                  title: 'Domain completion',
                  subtitle:
                      'Subtopic completion across all seven CSP11 domains',
                  child: DomainProgressBars(domains: snapshot.domains),
                ),
                ProgressPanel(
                  title: 'Question accuracy',
                  subtitle: 'Unique questions answered at least once',
                  child: AccuracyDonut(
                    accuracy: snapshot.accuracy,
                    answered: snapshot.answeredQuestions,
                    correct: snapshot.correctQuestions,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ProgressPanel(
                title: 'Completion analytics',
                subtitle:
                    'Domains, Topics and Subtopics completed against the published structure',
                child: CompletionBars(
                  completedDomains: snapshot.completedDomains,
                  totalDomains: snapshot.totalDomains,
                  completedTopics: snapshot.completedTopics,
                  totalTopics: snapshot.totalTopics,
                  completedSubtopics: snapshot.completedSubtopics,
                  totalSubtopics: snapshot.totalSubtopics,
                ),
              ),
              const SizedBox(height: 16),
              ProgressPanel(
                title: 'Domain analytics table',
                subtitle:
                    'Tap any domain row below for Competency → Topic → Subtopic analytics',
                child: _domainTable(context, snapshot),
              ),
              const SizedBox(height: 20),
              _sectionHeader(context),
              const SizedBox(height: 10),
              ...snapshot.domains.map(
                (domain) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _domainCard(context, domain),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _hero(BuildContext context, ProgressAnalyticsSnapshot snapshot) {
    final percent = (snapshot.overallProgress * 100).round();

    return StudentGlassSurface(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      borderRadius: BorderRadius.circular(26),
      gradient: LinearGradient(
        colors: widget.isDarkMode
            ? [
                const Color(0xFF102A56).withValues(alpha: 0.82),
                const Color(0xFF1E4C91).withValues(alpha: 0.76),
                const Color(0xFF4B318B).withValues(alpha: 0.72),
              ]
            : [
                const Color(0xFF0B63CE).withValues(alpha: 0.82),
                const Color(0xFF2C77D8).withValues(alpha: 0.74),
                const Color(0xFF6A4CC3).withValues(alpha: 0.70),
              ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderColor: Colors.white.withValues(alpha: 0.14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 620;

          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CSP11 LEARNING ANALYTICS',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '$percent%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 48,
                  height: 1,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Overall Subtopic completion',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              LinearProgressIndicator(
                value: snapshot.overallProgress,
                minHeight: 8,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          );

          final weekly = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'THIS WEEK',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _formatMinutes(snapshot.weeklyMinutes),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '${snapshot.studyStreakDays} day streak · ${snapshot.activeDays}/7 active days',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [copy, const SizedBox(height: 22), weekly],
            );
          }

          return Row(
            children: [
              Expanded(child: copy),
              const SizedBox(width: 30),
              weekly,
            ],
          );
        },
      ),
    );
  }

  Widget _kpiGrid(BuildContext context, ProgressAnalyticsSnapshot snapshot) {
    final items = <(String, String, IconData)>[
      (
        '${snapshot.completedDomains}/${snapshot.totalDomains}',
        'Domains completed',
        Icons.shield_rounded,
      ),
      (
        '${snapshot.completedTopics}/${snapshot.totalTopics}',
        'Topics completed',
        Icons.layers_rounded,
      ),
      (
        '${snapshot.completedSubtopics}/${snapshot.totalSubtopics}',
        'Subtopics completed',
        Icons.check_circle_rounded,
      ),
      (
        '${snapshot.answeredQuestions}',
        'Questions answered',
        Icons.quiz_rounded,
      ),
      (
        '${(snapshot.accuracy * 100).round()}%',
        'Question accuracy',
        Icons.track_changes_rounded,
      ),
      (
        _formatMinutes(snapshot.weeklyMinutes),
        'Learning time this week',
        Icons.schedule_rounded,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 3
            : constraints.maxWidth >= 560
            ? 2
            : 1;
        const gap = 10.0;
        final itemWidth =
            (constraints.maxWidth - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: items
              .map((item) {
                return SizedBox(
                  width: itemWidth,
                  child: _kpiCard(context, item.$1, item.$2, item.$3),
                );
              })
              .toList(growable: false),
        );
      },
    );
  }

  Widget _kpiCard(
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

  Widget _responsivePair(BuildContext context, Widget first, Widget second) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 760) {
          return Column(children: [first, const SizedBox(height: 16), second]);
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: first),
            const SizedBox(width: 16),
            Expanded(child: second),
          ],
        );
      },
    );
  }

  Widget _domainTable(
    BuildContext context,
    ProgressAnalyticsSnapshot snapshot,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Domain')),
          DataColumn(label: Text('Progress')),
          DataColumn(label: Text('Topics')),
          DataColumn(label: Text('Subtopics')),
          DataColumn(label: Text('Questions')),
          DataColumn(label: Text('Accuracy')),
          DataColumn(label: Text('Status')),
        ],
        rows: snapshot.domains
            .map((domain) {
              return DataRow(
                onSelectChanged: (_) => _openDomain(context, domain),
                cells: [
                  DataCell(
                    SizedBox(
                      width: 210,
                      child: Text(
                        'D${domain.domainNumber.toString().padLeft(2, '0')} · ${domain.title}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(Text('${(domain.progress * 100).round()}%')),
                  DataCell(
                    Text('${domain.completedTopics}/${domain.totalTopics}'),
                  ),
                  DataCell(
                    Text(
                      '${domain.completedSubtopics}/${domain.totalSubtopics}',
                    ),
                  ),
                  DataCell(Text('${domain.answeredQuestions}')),
                  DataCell(Text('${(domain.accuracy * 100).round()}%')),
                  DataCell(Text(domain.status)),
                ],
              );
            })
            .toList(growable: false),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DOMAIN DRILL-DOWN',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Open a domain for detailed Competency, Topic, Subtopic and question analytics',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }

  Widget _domainCard(
    BuildContext context,
    ProgressDomainAnalyticsSummary domain,
  ) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openDomain(context, domain),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: scheme.primaryContainer,
                foregroundColor: scheme.onPrimaryContainer,
                child: Text(
                  domain.domainNumber.toString().padLeft(2, '0'),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      domain.title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 7),
                    LinearProgressIndicator(
                      value: domain.progress,
                      minHeight: 7,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${domain.completedSubtopics}/${domain.totalSubtopics} subtopics · '
                      '${domain.answeredQuestions} questions · '
                      '${(domain.accuracy * 100).round()}% accuracy',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }

  void _openLearningDomain(
    BuildContext context,
    ProgressAnalyticsSnapshot snapshot,
    String domainId,
  ) {
    ProgressDomainAnalyticsSummary? target;

    for (final domain in snapshot.domains) {
      if (domain.domainId == domainId) {
        target = domain;
        break;
      }
    }

    if (target == null) {
      return;
    }

    final domainNumber = target.domainNumber;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => widget.isDarkMode
            ? DarkDomainScreen(domainNumber: domainNumber)
            : DomainScreen(domainNumber: domainNumber),
      ),
    );
  }

  void _openDomain(
    BuildContext context,
    ProgressDomainAnalyticsSummary domain,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProgressDomainDetailScreen(
          domainId: domain.domainId,
          domainNumber: domain.domainNumber,
          domainTitle: domain.title,
          isDarkMode: widget.isDarkMode,
        ),
      ),
    );
  }

  Widget _loadingShell(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          height: 210,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [scheme.primary, scheme.tertiary]),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Center(
            child: Text(
              'Preparing learning analytics…',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        ...List<Widget>.generate(
          4,
          (_) => Container(
            height: 86,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ],
    );
  }

  Widget _errorState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.insights_rounded, size: 46),
            const SizedBox(height: 12),
            const Text('Progress analytics could not be loaded.'),
            const SizedBox(height: 8),
            Text(
              _error == null
                  ? 'Please try again.'
                  : 'Your learner data is unchanged. Retry the analytics refresh.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            FilledButton(onPressed: refresh, child: const Text('TRY AGAIN')),
          ],
        ),
      ),
    );
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) {
      return '${minutes}m';
    }

    final hours = minutes ~/ 60;
    final remainder = minutes % 60;

    return remainder == 0 ? '${hours}h' : '${hours}h ${remainder}m';
  }
}
