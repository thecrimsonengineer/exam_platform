import 'package:flutter/material.dart';

import '../models/exam_study_plan.dart';
import '../models/study_capacity_snapshot.dart';
import '../repositories/exam_study_plan_repository.dart';
import '../services/exam_study_capacity_service.dart';
import 'exam_plan_setup_screen.dart';

class ExamReadinessPlanScreen extends StatefulWidget {
  const ExamReadinessPlanScreen({super.key, this.repository, this.now});

  final ExamStudyPlanRepository? repository;
  final DateTime Function()? now;

  @override
  State<ExamReadinessPlanScreen> createState() =>
      _ExamReadinessPlanScreenState();
}

class _ExamReadinessPlanScreenState extends State<ExamReadinessPlanScreen> {
  static const _capacityService = ExamStudyCapacityService();

  late Future<_M7APlanViewData> _future;

  ExamStudyPlanRepository get _repository =>
      widget.repository ??
      ExamStudyPlanRepository(remoteStore: FirebaseExamStudyPlanRemoteStore());

  DateTime get _now => widget.now?.call() ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_M7APlanViewData> _load({bool refreshRemote = false}) async {
    ExamStudyPlan? plan;
    String? syncNotice;

    try {
      plan = await _repository.loadActivePlan(refreshRemote: refreshRemote);
    } catch (_) {
      plan = await _repository.loadActivePlan();
      syncNotice =
          'Cloud refresh was unavailable. Showing the latest local plan.';
    }

    if (plan == null) {
      return _M7APlanViewData(plan: null, snapshot: null, notice: syncNotice);
    }

    return _M7APlanViewData(
      plan: plan,
      snapshot: _capacityService.calculate(plan: plan, now: _now),
      notice: syncNotice,
    );
  }

  Future<void> _refresh({bool remote = false}) async {
    final next = _load(refreshRemote: remote);
    setState(() => _future = next);
    await next;
  }

  Future<void> _openSetup(ExamStudyPlan? current) async {
    final result = await Navigator.of(context).push<ExamStudyPlan>(
      MaterialPageRoute(
        builder: (_) => ExamPlanSetupScreen(
          repository: _repository,
          initialPlan: current,
          now: widget.now,
        ),
      ),
    );

    if (result != null && mounted) {
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam Readiness Plan'),
        actions: [
          IconButton(
            key: const ValueKey('m7a-refresh-cloud'),
            tooltip: 'Refresh plan',
            onPressed: () => _refresh(remote: true),
            icon: const Icon(Icons.sync_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<_M7APlanViewData>(
          future: _future,
          builder: (context, async) {
            if (async.connectionState == ConnectionState.waiting &&
                !async.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            if (async.hasError) {
              return _ErrorState(
                message: async.error.toString(),
                onRetry: _refresh,
              );
            }

            final data = async.data ?? const _M7APlanViewData();
            final plan = data.plan;
            final snapshot = data.snapshot;

            if (plan == null || snapshot == null) {
              return _EmptyPlanState(onCreate: () => _openSetup(null));
            }

            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
                children: [
                  if (data.notice != null) ...[
                    Container(
                      key: const ValueKey('m7a-local-cache-notice'),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: scheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        data.notice!,
                        style: TextStyle(
                          color: scheme.onTertiaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  _ExamHero(plan: plan, snapshot: snapshot),
                  const SizedBox(height: 14),
                  _CapacityGrid(snapshot: snapshot),
                  const SizedBox(height: 14),
                  _PlanDetails(plan: plan),
                  const SizedBox(height: 18),
                  FilledButton.tonalIcon(
                    key: const ValueKey('m7a-edit-plan'),
                    onPressed: () => _openSetup(plan),
                    icon: const Icon(Icons.edit_calendar_rounded),
                    label: const Text('Edit exam plan'),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'M7A calculates time and capacity only. Knowledge, '
                    'application, retention and readiness interpretation are '
                    'added by later evidence phases and are never inferred '
                    'from the countdown alone.',
                    key: const ValueKey('m7a-no-readiness-claim'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ExamHero extends StatelessWidget {
  const _ExamHero({required this.plan, required this.snapshot});

  final ExamStudyPlan plan;
  final StudyCapacitySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      key: const ValueKey('m7a-exam-hero'),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primaryContainer, scheme.secondaryContainer],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CSP EXAM',
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatDate(plan.examDate),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              Text(
                '${snapshot.calendarDaysRemaining}',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  height: 0.95,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'days until exam',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _CapacityGrid extends StatelessWidget {
  const _CapacityGrid({required this.snapshot});

  final StudyCapacitySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 650 ? 3 : 1;
        const gap = 12.0;
        final width = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - gap * (columns - 1)) / columns;

        final items = [
          (
            key: 'm7a-study-days-remaining',
            icon: Icons.calendar_view_week_rounded,
            value: '${snapshot.plannedStudyDaysRemaining}',
            label: 'study days remaining',
          ),
          (
            key: 'm7a-study-hours-remaining',
            icon: Icons.schedule_rounded,
            value: '${snapshot.plannedHoursRemaining.toStringAsFixed(1)} h',
            label: 'planned study capacity',
          ),
          (
            key: 'm7a-current-week-capacity',
            icon: Icons.today_rounded,
            value: '${snapshot.studyDaysThisWeek}',
            label: 'study days this week',
          ),
        ];

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: items
              .map(
                (item) => SizedBox(
                  width: width,
                  child: _CapacityCard(
                    key: ValueKey(item.key),
                    icon: item.icon,
                    value: item.value,
                    label: item.label,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _CapacityCard extends StatelessWidget {
  const _CapacityCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, color: scheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
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
}

class _PlanDetails extends StatelessWidget {
  const _PlanDetails({required this.plan});

  final ExamStudyPlan plan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final weekdays = plan.studyDaysOfWeek.toList()..sort();

    return Container(
      key: const ValueKey('m7a-plan-details'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Study schedule',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Text('Days: ${weekdays.map(_weekday).join(', ')}'),
          const SizedBox(height: 6),
          Text('Default: ${plan.defaultMinutesPerStudyDay} min per study day'),
          const SizedBox(height: 6),
          Text('Plan version: ${plan.planVersion}'),
        ],
      ),
    );
  }

  String _weekday(int weekday) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return labels[weekday - 1];
  }
}

class _EmptyPlanState extends StatelessWidget {
  const _EmptyPlanState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.event_available_rounded,
                size: 64,
                color: scheme.primary,
              ),
              const SizedBox(height: 18),
              Text(
                'Create your exam readiness plan',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Start with your exam date, study days and available minutes. '
                'CSP11 will calculate your realistic study capacity.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                key: const ValueKey('m7a-create-plan'),
                onPressed: onCreate,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create exam plan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              key: const ValueKey('m7a-plan-load-error'),
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _M7APlanViewData {
  const _M7APlanViewData({this.plan, this.snapshot, this.notice});

  final ExamStudyPlan? plan;
  final StudyCapacitySnapshot? snapshot;
  final String? notice;
}
