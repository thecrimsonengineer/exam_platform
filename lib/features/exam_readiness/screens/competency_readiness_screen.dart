import 'package:flutter/material.dart';

import 'package:exam_platform/theme/glass/student_glass.dart';

import '../models/competency_readiness_profile.dart';
import '../models/evidence_confidence.dart';

class CompetencyReadinessScreen extends StatelessWidget {
  const CompetencyReadinessScreen({super.key, required this.profile});

  final CompetencyReadinessProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return StudentGlassScaffold(
      key: const ValueKey('m7c-competency-readiness-screen'),
      appBar: AppBar(title: Text(profile.competencyId.toUpperCase())),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
          children: [
            Container(
              key: const ValueKey('m7c-competency-state-card'),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [scheme.primaryContainer, scheme.secondaryContainer],
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'READINESS STATE',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _stateLabel(profile.readinessState),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Evidence confidence: ${profile.evidenceConfidence.label}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _DimensionList(profile: profile),
            const SizedBox(height: 14),
            _DifficultyCard(profile: profile),
            const SizedBox(height: 14),
            _GapCard(profile: profile),
            const SizedBox(height: 14),
            _ReasonCodeCard(profile: profile),
          ],
        ),
      ),
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

class _DimensionList extends StatelessWidget {
  const _DimensionList({required this.profile});

  final CompetencyReadinessProfile profile;

  @override
  Widget build(BuildContext context) {
    final dimensions = <({String label, ReadinessDimension dimension})>[
      (label: 'Knowledge mastery', dimension: profile.knowledgeMastery),
      (label: 'Application ability', dimension: profile.applicationAbility),
      (label: 'Retention', dimension: profile.retention),
      (label: 'Blueprint coverage', dimension: profile.blueprintCoverage),
      (
        label: 'Confidence calibration',
        dimension: profile.confidenceCalibration,
      ),
      (label: 'Recent performance', dimension: profile.recentPerformance),
      (label: 'Stability', dimension: profile.stability),
    ];

    return StudentGlassSurface(
      key: const ValueKey('m7c-competency-dimensions'),
      padding: const EdgeInsets.all(18),
      borderRadius: BorderRadius.circular(20),
      tint: Theme.of(
        context,
      ).colorScheme.surfaceContainerLow.withValues(alpha: 0.54),
      borderColor: Theme.of(
        context,
      ).colorScheme.outlineVariant.withValues(alpha: 0.62),
      child: Column(
        children: [
          for (var i = 0; i < dimensions.length; i++) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    dimensions[i].label,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  dimensions[i].dimension.percent == null
                      ? 'INSUFFICIENT EVIDENCE'
                      : '${dimensions[i].dimension.percent}%',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            if (i < dimensions.length - 1) const Divider(height: 22),
          ],
        ],
      ),
    );
  }
}

class _DifficultyCard extends StatelessWidget {
  const _DifficultyCard({required this.profile});

  final CompetencyReadinessProfile profile;

  @override
  Widget build(BuildContext context) {
    final difficulty = profile.difficultyPerformance;

    return StudentGlassSurface(
      key: const ValueKey('m7c-difficulty-lanes'),
      padding: const EdgeInsets.all(18),
      borderRadius: BorderRadius.circular(20),
      tint: Theme.of(
        context,
      ).colorScheme.surfaceContainerLow.withValues(alpha: 0.54),
      borderColor: Theme.of(
        context,
      ).colorScheme.outlineVariant.withValues(alpha: 0.62),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Difficulty profile',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          _Lane(label: 'Standard', value: difficulty.standardAccuracy),
          _Lane(label: 'Hard', value: difficulty.hardAccuracy),
          _Lane(label: 'Ultra Hard', value: difficulty.ultraHardAccuracy),
        ],
      ),
    );
  }
}

class _Lane extends StatelessWidget {
  const _Lane({required this.label, required this.value});

  final String label;
  final double? value;

  @override
  Widget build(BuildContext context) {
    final percentage = value == null ? null : (value! * 100).round();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            percentage == null ? 'NO EVIDENCE' : '$percentage%',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _GapCard extends StatelessWidget {
  const _GapCard({required this.profile});

  final CompetencyReadinessProfile profile;

  @override
  Widget build(BuildContext context) {
    return StudentGlassSurface(
      key: const ValueKey('m7c-gap-card'),
      padding: const EdgeInsets.all(18),
      borderRadius: BorderRadius.circular(20),
      tint: Theme.of(
        context,
      ).colorScheme.surfaceContainerLow.withValues(alpha: 0.54),
      borderColor: Theme.of(
        context,
      ).colorScheme.outlineVariant.withValues(alpha: 0.62),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Readiness gaps',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          if (profile.gaps.isEmpty)
            const Text('No structured readiness gaps are currently identified.')
          else
            for (final gap in profile.gaps)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('• ${gap.explanation}'),
              ),
        ],
      ),
    );
  }
}

class _ReasonCodeCard extends StatelessWidget {
  const _ReasonCodeCard({required this.profile});

  final CompetencyReadinessProfile profile;

  @override
  Widget build(BuildContext context) {
    return StudentGlassSurface(
      key: const ValueKey('m7c-reason-code-card'),
      padding: const EdgeInsets.all(18),
      borderRadius: BorderRadius.circular(20),
      tint: Theme.of(
        context,
      ).colorScheme.surfaceContainerLow.withValues(alpha: 0.54),
      borderColor: Theme.of(
        context,
      ).colorScheme.outlineVariant.withValues(alpha: 0.62),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Why this state?',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          for (final code in profile.explanationCodes.take(8))
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(code),
            ),
        ],
      ),
    );
  }
}
