import 'package:flutter/material.dart';

import '../../../data/csp11_blueprint.dart';
import '../models/competency_readiness_profile.dart';
import '../models/evidence_confidence.dart';
import '../repositories/evidence_snapshot_repository.dart';
import '../repositories/learner_assessment_attempt_repository.dart';
import '../repositories/readiness_snapshot_repository.dart';
import '../services/readiness_profile_service.dart';
import 'competency_readiness_screen.dart';

class ReadinessProfileScreen extends StatefulWidget {
  const ReadinessProfileScreen({
    super.key,
    this.evidenceRepository,
    this.attemptRepository,
    this.readinessService = const ReadinessProfileService(),
    this.readinessRepository,
    this.now,
  });

  final EvidenceSnapshotRepository? evidenceRepository;
  final LearnerAssessmentAttemptRepository? attemptRepository;
  final ReadinessProfileService readinessService;
  final ReadinessSnapshotRepository? readinessRepository;
  final DateTime Function()? now;

  @override
  State<ReadinessProfileScreen> createState() => _ReadinessProfileScreenState();
}

class _ReadinessProfileScreenState extends State<ReadinessProfileScreen> {
  late Future<ExamReadinessDashboard> _future;

  EvidenceSnapshotRepository get _evidenceRepository =>
      widget.evidenceRepository ??
      EvidenceSnapshotRepository(
        remoteStore: FirebaseEvidenceSnapshotRemoteStore(),
      );

  LearnerAssessmentAttemptRepository get _attemptRepository =>
      widget.attemptRepository ?? const LearnerAssessmentAttemptRepository();

  ReadinessSnapshotRepository get _readinessRepository =>
      widget.readinessRepository ?? ReadinessSnapshotRepository();

  DateTime get _now => widget.now?.call() ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<ExamReadinessDashboard> _load({bool refreshRemote = false}) async {
    var evidence = await _evidenceRepository.loadLocal();

    if (refreshRemote) {
      try {
        evidence = await _evidenceRepository.refreshFromRemote();
      } catch (_) {
        // Local evidence remains the safe fallback.
      }
    }

    final attempts = await _attemptRepository.loadAll();

    final dashboard = widget.readinessService.buildDashboard(
      evidenceByCompetency: evidence,
      attempts: attempts,
      now: _now,
    );

    try {
      await _readinessRepository.saveMany(dashboard.profiles.values);
    } catch (_) {
      await _readinessRepository.saveMany(
        dashboard.profiles.values,
        syncRemote: false,
      );
    }

    return dashboard;
  }

  Future<void> _refresh() async {
    final future = _load(refreshRemote: true);
    setState(() => _future = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('m7c-readiness-screen'),
      appBar: AppBar(
        title: const Text('Exam Readiness'),
        actions: [
          IconButton(
            key: const ValueKey('m7c-refresh'),
            onPressed: _refresh,
            tooltip: 'Refresh readiness evidence',
            icon: const Icon(Icons.sync_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<ExamReadinessDashboard>(
          future: _future,
          builder: (context, async) {
            if (async.connectionState == ConnectionState.waiting &&
                !async.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            if (async.hasError) {
              return _ReadinessError(
                message: async.error.toString(),
                onRetry: _refresh,
              );
            }

            final dashboard = async.data;
            if (dashboard == null) {
              return _ReadinessError(
                message: 'Readiness evidence is unavailable.',
                onRetry: _refresh,
              );
            }

            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
                children: [
                  _EvidenceHero(dashboard: dashboard),
                  const SizedBox(height: 14),
                  _ReadinessDimensions(dashboard: dashboard),
                  const SizedBox(height: 14),
                  _AttentionCard(dashboard: dashboard),
                  const SizedBox(height: 14),
                  _LimitationsCard(dashboard: dashboard),
                  const SizedBox(height: 18),
                  _CompetencyMatrix(
                    dashboard: dashboard,
                    onTap: (profile) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              CompetencyReadinessScreen(profile: profile),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'CSP11 shows separate readiness dimensions. It does not '
                    'calculate a single exam-readiness percentage or predict '
                    'whether you will pass the exam.',
                    key: const ValueKey('m7c-no-composite-index'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.45,
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

class _EvidenceHero extends StatelessWidget {
  const _EvidenceHero({required this.dashboard});

  final ExamReadinessDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      key: const ValueKey('m7c-evidence-hero'),
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
            'EVIDENCE CONFIDENCE',
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            dashboard.evidenceConfidence.label,
            key: const ValueKey('m7c-evidence-confidence'),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${dashboard.blueprintCoverage.competenciesAssessed}/'
            '${dashboard.blueprintCoverage.competenciesTotal} competencies '
            'currently have assessment evidence.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadinessDimensions extends StatelessWidget {
  const _ReadinessDimensions({required this.dashboard});

  final ExamReadinessDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final items = <({String label, ReadinessDimension dimension})>[
      (label: 'Knowledge mastery', dimension: dashboard.knowledgeMastery),
      (label: 'Application ability', dimension: dashboard.applicationAbility),
      (label: 'Retention', dimension: dashboard.retention),
      (
        label: 'Difficulty readiness',
        dimension: dashboard.difficultyPerformance,
      ),
      (
        label: 'Confidence calibration',
        dimension: dashboard.confidenceCalibration,
      ),
    ];

    return Column(
      key: const ValueKey('m7c-readiness-dimensions'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Readiness dimensions',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        for (var index = 0; index < items.length; index++) ...[
          _DimensionCard(
            key: ValueKey('m7c-dimension-$index'),
            label: items[index].label,
            dimension: items[index].dimension,
          ),
          if (index < items.length - 1) const SizedBox(height: 10),
        ],
        const SizedBox(height: 10),
        _CoverageCard(summary: dashboard.blueprintCoverage),
      ],
    );
  }
}

class _DimensionCard extends StatelessWidget {
  const _DimensionCard({
    super.key,
    required this.label,
    required this.dimension,
  });

  final String label;
  final ReadinessDimension dimension;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final percent = dimension.percent;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final value = Text(
            percent == null ? 'INSUFFICIENT EVIDENCE' : '$percent%',
            style: theme.textTheme.labelLarge?.copyWith(
              color: percent == null ? scheme.onSurfaceVariant : scheme.primary,
              fontWeight: FontWeight.w900,
            ),
          );

          final labelWidget = Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          );

          if (constraints.maxWidth < 340) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                labelWidget,
                const SizedBox(height: 8),
                value,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: labelWidget),
              const SizedBox(width: 12),
              value,
            ],
          );
        },
      ),
    );
  }
}

class _CoverageCard extends StatelessWidget {
  const _CoverageCard({required this.summary});

  final BlueprintCoverageSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      key: const ValueKey('m7c-blueprint-coverage'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Blueprint coverage',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${summary.percent}%',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${summary.competenciesAssessed}/${summary.competenciesTotal} '
            'competencies assessed',
          ),
          if (summary.subtopicsTotal > 0)
            Text(
              '${summary.subtopicsAssessed}/${summary.subtopicsTotal} '
              'subtopics assessed',
            ),
        ],
      ),
    );
  }
}

class _AttentionCard extends StatelessWidget {
  const _AttentionCard({required this.dashboard});

  final ExamReadinessDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Critical gaps', dashboard.criticalGapCount),
      ('Weak competencies', dashboard.weakCompetencyCount),
      ('Evidence gaps', dashboard.evidenceGapCount),
      ('Stale competencies', dashboard.staleCompetencyCount),
    ];

    return Container(
      key: const ValueKey('m7c-attention-card'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Areas requiring attention',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(child: Text(item.$1)),
                  Text(
                    '${item.$2}',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _LimitationsCard extends StatelessWidget {
  const _LimitationsCard({required this.dashboard});

  final ExamReadinessDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final limitations = <String>[];

    for (final profile in dashboard.profiles.values) {
      for (final gap in profile.gaps) {
        if (gap.evidenceLimited &&
            !limitations.contains(gap.explanation) &&
            limitations.length < 4) {
          limitations.add(gap.explanation);
        }
      }
    }

    if (limitations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      key: const ValueKey('m7c-limitations-card'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current limitations',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          for (final limitation in limitations)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('• $limitation'),
            ),
        ],
      ),
    );
  }
}

class _CompetencyMatrix extends StatelessWidget {
  const _CompetencyMatrix({required this.dashboard, required this.onTap});

  final ExamReadinessDashboard dashboard;
  final ValueChanged<CompetencyReadinessProfile> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('m7c-competency-matrix'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Competency matrix',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        for (final domain in csp11Domains) ...[
          Text(
            'D${domain.number.toString().padLeft(2, '0')}  ${domain.title}',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          for (final competency in domain.competencies)
            _CompetencyRow(
              competencyId: competency.id,
              profile: dashboard.profiles[competency.id],
              onTap: onTap,
            ),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}

class _CompetencyRow extends StatelessWidget {
  const _CompetencyRow({
    required this.competencyId,
    required this.profile,
    required this.onTap,
  });

  final String competencyId;
  final CompetencyReadinessProfile? profile;
  final ValueChanged<CompetencyReadinessProfile> onTap;

  @override
  Widget build(BuildContext context) {
    final state = profile?.readinessState ?? ReadinessState.unknown;

    return ListTile(
      key: ValueKey('m7c-competency-$competencyId'),
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      title: Text(
        competencyId.toUpperCase(),
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      trailing: Text(
        _stateLabel(state),
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
      onTap: profile == null ? null : () => onTap(profile!),
    );
  }

  String _stateLabel(ReadinessState state) {
    return switch (state) {
      ReadinessState.unknown => 'UNASSESSED',
      ReadinessState.insufficientEvidence => 'INSUFFICIENT EVIDENCE',
      ReadinessState.learning => 'LEARNING',
      ReadinessState.developing => 'DEVELOPING',
      ReadinessState.provisional => 'PROVISIONAL',
      ReadinessState.strong => 'STRONG',
      ReadinessState.stable => 'STABLE',
      ReadinessState.atRisk => 'AT RISK',
      ReadinessState.stale => 'STALE',
    };
  }
}

class _ReadinessError extends StatelessWidget {
  const _ReadinessError({required this.message, required this.onRetry});

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
              key: const ValueKey('m7c-error'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
