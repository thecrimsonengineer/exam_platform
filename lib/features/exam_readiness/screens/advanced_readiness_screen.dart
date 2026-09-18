import 'package:flutter/material.dart';

import '../models/advanced_readiness_snapshot.dart';
import '../models/competency_readiness_profile.dart';
import '../models/evidence_confidence.dart';
import '../models/readiness_trajectory_point.dart';
import '../models/recovery_protection_snapshot.dart';
import '../repositories/daily_study_plan_repository.dart';
import '../repositories/evidence_snapshot_repository.dart';
import '../repositories/exam_study_plan_repository.dart';
import '../repositories/readiness_history_repository.dart';
import '../services/advanced_readiness_service.dart';
import '../services/exam_study_capacity_service.dart';
import '../services/ultra_hard_availability_service.dart';

class AdvancedReadinessScreen extends StatefulWidget {
  const AdvancedReadinessScreen({
    super.key,
    required this.dashboard,
    this.examPlanRepository,
    this.evidenceRepository,
    this.dailyPlanRepository,
    this.historyRepository,
    this.advancedService = const AdvancedReadinessService(),
    this.capacityService = const ExamStudyCapacityService(),
    this.ultraHardAvailabilityService,
    this.now,
  });

  final ExamReadinessDashboard dashboard;
  final ExamStudyPlanRepository? examPlanRepository;
  final EvidenceSnapshotRepository? evidenceRepository;
  final DailyStudyPlanRepository? dailyPlanRepository;
  final ReadinessHistoryRepository? historyRepository;
  final AdvancedReadinessService advancedService;
  final ExamStudyCapacityService capacityService;
  final UltraHardAvailabilityService? ultraHardAvailabilityService;
  final DateTime Function()? now;

  @override
  State<AdvancedReadinessScreen> createState() =>
      _AdvancedReadinessScreenState();
}

class _AdvancedReadinessScreenState extends State<AdvancedReadinessScreen> {
  late Future<AdvancedReadinessSnapshot> _future;

  ExamStudyPlanRepository get _examPlanRepository =>
      widget.examPlanRepository ?? ExamStudyPlanRepository();

  EvidenceSnapshotRepository get _evidenceRepository =>
      widget.evidenceRepository ?? EvidenceSnapshotRepository();

  DailyStudyPlanRepository get _dailyPlanRepository =>
      widget.dailyPlanRepository ?? DailyStudyPlanRepository();

  ReadinessHistoryRepository get _historyRepository =>
      widget.historyRepository ?? const ReadinessHistoryRepository();

  UltraHardAvailabilityService get _ultraHardAvailabilityService =>
      widget.ultraHardAvailabilityService ?? UltraHardAvailabilityService();

  DateTime get _now => widget.now?.call() ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<AdvancedReadinessSnapshot> _load() async {
    final plan = await _examPlanRepository.loadActivePlan();
    if (plan == null) {
      throw StateError(
        'Create an exam plan before opening Advanced Readiness.',
      );
    }

    final now = _now;
    final evidence = await _evidenceRepository.loadLocal();
    final history = await _historyRepository.loadAll();
    final dailyHistory = await _dailyPlanRepository.loadHistory();
    final todayPlan = await _dailyPlanRepository.loadLatestForDate(now);
    final capacity = widget.capacityService.calculate(plan: plan, now: now);

    var ultraHardAvailable = false;
    try {
      ultraHardAvailable =
          (await _ultraHardAvailabilityService.loadAvailableCompetencyIds())
              .isNotEmpty;
    } catch (_) {
      ultraHardAvailable = false;
    }

    final snapshot = widget.advancedService.build(
      dashboard: widget.dashboard,
      evidenceByCompetency: evidence,
      capacity: capacity,
      currentDate: now,
      examDate: plan.examDate,
      trajectoryHistory: history,
      dailyPlanHistory: dailyHistory,
      todayPlan: todayPlan,
      ultraHardAvailable: ultraHardAvailable,
    );

    await _historyRepository.saveDaily(snapshot.latestTrajectoryPoint);
    return snapshot;
  }

  Future<void> _refresh() async {
    final future = _load();
    setState(() => _future = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('m7f-advanced-readiness-screen'),
      appBar: AppBar(
        title: const Text('Advanced Readiness'),
        actions: [
          IconButton(
            key: const ValueKey('m7f-refresh'),
            onPressed: _refresh,
            tooltip: 'Refresh advanced readiness',
            icon: const Icon(Icons.sync_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<AdvancedReadinessSnapshot>(
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
            final snapshot = async.data;
            if (snapshot == null) {
              return _ErrorState(
                message: 'Advanced readiness is unavailable.',
                onRetry: _refresh,
              );
            }

            return RefreshIndicator(
              onRefresh: _refresh,
              child: AdvancedReadinessSummaryView(snapshot: snapshot),
            );
          },
        ),
      ),
    );
  }
}

class AdvancedReadinessSummaryView extends StatelessWidget {
  const AdvancedReadinessSummaryView({super.key, required this.snapshot});

  final AdvancedReadinessSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ListView(
      key: const ValueKey('m7f-advanced-readiness-summary'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
      children: [
        Container(
          key: const ValueKey('m7f-phase-hero'),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [scheme.primaryContainer, scheme.secondaryContainer],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                snapshot.phase.name.toUpperCase(),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${snapshot.daysUntilExam.clamp(0, 9999)} days until exam',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Evidence confidence: ${snapshot.evidenceConfidence.label}',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _IndexCard(snapshot: snapshot),
        const SizedBox(height: 14),
        _CapacityCard(snapshot: snapshot),
        const SizedBox(height: 14),
        _CountsCard(snapshot: snapshot),
        const SizedBox(height: 14),
        _TrajectoryCard(snapshot: snapshot),
        if (snapshot.nextCheckpoint != null) ...[
          const SizedBox(height: 14),
          _CheckpointCard(snapshot: snapshot),
        ],
        if (snapshot.recoveryProtection.recommendsChange) ...[
          const SizedBox(height: 14),
          _RecoveryCard(snapshot: snapshot),
        ],
        if (snapshot.rootGapCandidates.isNotEmpty) ...[
          const SizedBox(height: 14),
          _RootGapCard(snapshot: snapshot),
        ],
        if (snapshot.planChangeExplanation != null) ...[
          const SizedBox(height: 14),
          _PlanExplanationCard(snapshot: snapshot),
        ],
      ],
    );
  }
}

class _IndexCard extends StatelessWidget {
  const _IndexCard({required this.snapshot});
  final AdvancedReadinessSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final index = snapshot.readinessIndex;
    final theme = Theme.of(context);
    return _Card(
      key: const ValueKey('m7f-readiness-index'),
      title: 'CSP11 Readiness Index',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            index.isAvailable ? '${index.score} / 100' : 'Not yet available',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text('Evidence confidence: ${index.evidenceConfidence.label}'),
          const SizedBox(height: 8),
          Text(
            index.isAvailable
                ? 'This is a study-readiness index built from current evidence. It is not an exam outcome prediction.'
                : 'More evidence is required before CSP11 can produce a trustworthy composite readiness estimate.',
          ),
        ],
      ),
    );
  }
}

class _CapacityCard extends StatelessWidget {
  const _CapacityCard({required this.snapshot});
  final AdvancedReadinessSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final pressure = snapshot.capacityPressure;
    return _Card(
      key: const ValueKey('m7f-capacity-pressure'),
      title: 'Capacity pressure: ${pressure.state.name.toUpperCase()}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available planned capacity: '
            '${pressure.availableHours.toStringAsFixed(1)} hours',
          ),
          Text(
            'Estimated priority workload: '
            '${pressure.estimatedPriorityWorkloadMinHours.toStringAsFixed(1)}-'
            '${pressure.estimatedPriorityWorkloadMaxHours.toStringAsFixed(1)} hours',
          ),
          if (pressure.demandExceedsCapacity) ...[
            const SizedBox(height: 10),
            const Text(
              'You can choose to increase weekly minutes, add a study day, '
              'reduce low-priority review, or prioritize critical competencies. '
              'CSP11 will not silently increase your declared workload.',
            ),
          ],
        ],
      ),
    );
  }
}

class _CountsCard extends StatelessWidget {
  const _CountsCard({required this.snapshot});
  final AdvancedReadinessSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return _Card(
      key: const ValueKey('m7f-readiness-counts'),
      title: 'Current readiness profile',
      child: Wrap(
        spacing: 20,
        runSpacing: 10,
        children: [
          Text('Strong: ${snapshot.strongCompetencies}'),
          Text('Developing: ${snapshot.developingCompetencies}'),
          Text('Critical gaps: ${snapshot.criticalGaps}'),
          Text(
            'Insufficient evidence: '
            '${snapshot.insufficientEvidenceCompetencies}',
          ),
        ],
      ),
    );
  }
}

class _TrajectoryCard extends StatelessWidget {
  const _TrajectoryCard({required this.snapshot});
  final AdvancedReadinessSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final trajectory = snapshot.trajectory;
    final projection = snapshot.coverageProjection;
    return _Card(
      key: const ValueKey('m7f-trajectory'),
      title: 'Readiness trajectory',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!trajectory.hasMeaningfulWindow)
            const Text('A meaningful trend needs at least 14 days of history.')
          else ...[
            Text(
              'Application: ${_trendText(trajectory.application.delta, trajectory.windowDays)}',
            ),
            Text(
              'Retention: ${_trendText(trajectory.retention.delta, trajectory.windowDays)}',
            ),
            Text(
              'Coverage: ${_trendText(trajectory.coverage.delta, trajectory.windowDays)}',
            ),
          ],
          if (projection.isAvailable) ...[
            const SizedBox(height: 10),
            Text(
              'At the recent study pace, estimated blueprint coverage by the '
              'exam date is ${projection.projectedPercent}%.',
            ),
            const Text('This projects coverage only, not examination outcome.'),
          ],
        ],
      ),
    );
  }

  static String _trendText(double? delta, int days) {
    if (delta == null) return 'insufficient evidence';
    final points = (delta * 100).round();
    if (points.abs() < 3) return 'stable over $days days';
    final sign = points > 0 ? '+' : '';
    return '$sign$points points over $days days';
  }
}

class _CheckpointCard extends StatelessWidget {
  const _CheckpointCard({required this.snapshot});
  final AdvancedReadinessSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final checkpoint = snapshot.nextCheckpoint!;
    return _Card(
      key: const ValueKey('m7f-checkpoint'),
      title: checkpoint.status.name == 'due'
          ? 'Readiness checkpoint due'
          : 'Next readiness checkpoint',
      child: Text(
        '${checkpoint.questionCount} questions at the '
        '${checkpoint.milestoneDaysRemaining}-day milestone. '
        'Hard: yes. Ultra Hard: '
        '${checkpoint.includeUltraHard ? 'yes' : 'not currently available'}. '
        'Delayed retrieval: ${checkpoint.includeDelayedRetrieval ? 'yes' : 'no'}.',
      ),
    );
  }
}

class _RecoveryCard extends StatelessWidget {
  const _RecoveryCard({required this.snapshot});
  final AdvancedReadinessSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final recovery = snapshot.recoveryProtection;
    final label = recovery.state == RecoveryProtectionState.recoveryDay
        ? 'Recovery day option'
        : 'Reduced-intensity option';
    return _Card(
      key: const ValueKey('m7f-recovery'),
      title: label,
      child: Text(
        '${recovery.consecutiveMissedStudyDays} recent study days were missed. '
        'If you choose a lighter day, CSP11 suggests '
        '${recovery.suggestedMinutes} minutes instead of '
        '${recovery.declaredMinutes}. The planner will not accumulate an impossible backlog.',
      ),
    );
  }
}

class _RootGapCard extends StatelessWidget {
  const _RootGapCard({required this.snapshot});
  final AdvancedReadinessSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final root = snapshot.rootGapCandidates.first;
    return _Card(
      key: const ValueKey('m7f-root-gap'),
      title: 'Possible root gap',
      child: Text(
        '${root.prerequisiteCompetencyId.toUpperCase()} is an explicitly '
        'registered prerequisite shared by observed gaps in '
        '${root.dependentCompetencyIds.map((id) => id.toUpperCase()).join(', ')}.',
      ),
    );
  }
}

class _PlanExplanationCard extends StatelessWidget {
  const _PlanExplanationCard({required this.snapshot});
  final AdvancedReadinessSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return _Card(
      key: const ValueKey('m7f-plan-explanation'),
      title: "Why today's plan looks this way",
      child: Text(snapshot.planChangeExplanation!),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
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
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
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
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
