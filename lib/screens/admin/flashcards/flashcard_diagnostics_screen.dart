import 'package:flutter/material.dart';

import '../../../features/flashcards/integration/flashcard_integration_models.dart';
import '../../../features/flashcards/integration/flashcard_integration_service.dart';
import '../../../models/question.dart';
import '../../../models/study_content.dart';
import '../../../services/study_content/local_study_content_repository.dart';

class FlashcardDiagnosticsScreen extends StatefulWidget {
  const FlashcardDiagnosticsScreen({
    super.key,
    this.learnerIdOverride,
    this.integrationService,
    this.studyContentRepository,
  });

  final String? learnerIdOverride;
  final FlashcardIntegrationService? integrationService;
  final LocalStudyContentRepository? studyContentRepository;

  @override
  State<FlashcardDiagnosticsScreen> createState() =>
      _FlashcardDiagnosticsScreenState();
}

class _FlashcardDiagnosticsScreenState
    extends State<FlashcardDiagnosticsScreen> {
  late final FlashcardIntegrationService _integration;
  late final LocalStudyContentRepository _studyContentRepository;

  Future<_FlashcardDiagnosticsSnapshot>? _future;

  @override
  void initState() {
    super.initState();
    _integration =
        widget.integrationService ??
        FlashcardIntegrationService.local(
          userIdOverride: widget.learnerIdOverride,
        );
    _studyContentRepository =
        widget.studyContentRepository ?? LocalStudyContentRepository();
    _future = _load();
  }

  Future<_FlashcardDiagnosticsSnapshot> _load() async {
    final published = await _studyContentRepository.loadPublished();
    final eligibleQuestionIds = _questionIds(published);

    final mapping = await _integration.questionMappingCoverage(
      eligibleQuestionIds,
    );
    final placement = await _integration.validateStudyContentPlacements(
      published,
    );
    final source = await _integration.sourceQuality();

    FlashcardCollectionQualityReport? collection;
    Object? collectionError;
    try {
      collection = await _integration.collectionQuality();
    } catch (error) {
      collectionError = error;
    }

    return _FlashcardDiagnosticsSnapshot(
      publishedStudyContentCount: published.length,
      eligibleQuestionCount: eligibleQuestionIds.length,
      mapping: mapping,
      placement: placement,
      source: source,
      collection: collection,
      collectionError: collectionError,
    );
  }

  Set<int> _questionIds(Iterable<StudyContent> contents) {
    final ids = <int>{};
    for (final content in contents) {
      for (final topic in content.topics) {
        for (final subtopic in topic.subtopics) {
          for (final question in subtopic.questions.whereType<Question>()) {
            if (question.id > 0) {
              ids.add(question.id);
            }
          }
        }
      }
    }
    return ids;
  }

  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flashcard Diagnostics'),
        actions: [
          IconButton(
            tooltip: 'Refresh Flashcard diagnostics',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FutureBuilder<_FlashcardDiagnosticsSnapshot>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return _ErrorPanel(
              message: snapshot.error?.toString() ?? 'Diagnostics unavailable.',
              onRetry: _refresh,
            );
          }

          final value = snapshot.data!;
          return ListView(
            key: const ValueKey('flashcard-diagnostics-list'),
            padding: const EdgeInsets.all(18),
            children: [
              _SummaryHeader(snapshot: value),
              const SizedBox(height: 14),
              _MappingPanel(report: value.mapping),
              const SizedBox(height: 14),
              _SourcePanel(report: value.source),
              const SizedBox(height: 14),
              _PlacementPanel(report: value.placement),
              const SizedBox(height: 14),
              _CollectionPanel(
                report: value.collection,
                error: value.collectionError,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({required this.snapshot});

  final _FlashcardDiagnosticsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final checks = <bool>[
      snapshot.mapping.passed,
      snapshot.source.passed,
      snapshot.placement.passed,
      if (snapshot.collection != null) snapshot.collection!.passed,
    ];
    final passed = checks.every((value) => value);

    return _DiagnosticCard(
      title: passed ? 'FC7 integration health is green' : 'FC7 needs attention',
      icon: passed ? Icons.verified_rounded : Icons.warning_amber_rounded,
      passed: passed,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _Metric(
            label: 'Local StudyContent',
            value: snapshot.publishedStudyContentCount.toString(),
          ),
          _Metric(
            label: 'Eligible Questions',
            value: snapshot.eligibleQuestionCount.toString(),
          ),
          _Metric(
            label: 'Flashcard packages',
            value: snapshot.source.packageCount.toString(),
          ),
          _Metric(
            label: 'Learner-ready cards',
            value: snapshot.source.cardCount.toString(),
          ),
        ],
      ),
    );
  }
}

class _MappingPanel extends StatelessWidget {
  const _MappingPanel({required this.report});

  final FlashcardQuestionMappingCoverage report;

  @override
  Widget build(BuildContext context) {
    return _DiagnosticCard(
      key: const ValueKey('flashcard-diagnostics-mapping'),
      title: 'Question → Concept mapping',
      icon: Icons.account_tree_outlined,
      passed: report.passed,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _metricRow(
            context,
            'Coverage',
            '${report.mappedCount} / ${report.eligibleCount} '
                '(${(report.coverageRatio * 100).toStringAsFixed(1)}%)',
          ),
          _metricRow(
            context,
            'Unmapped',
            report.unmappedQuestionIds.length.toString(),
          ),
          _metricRow(
            context,
            'Conflicting',
            report.conflictingQuestionIds.length.toString(),
          ),
          if (report.unmappedQuestionIds.isNotEmpty)
            _IdWrap(
              label: 'Unmapped Question IDs',
              values: report.unmappedQuestionIds.map((id) => '$id').toList(),
            ),
          if (report.conflictingQuestionIds.isNotEmpty)
            _IdWrap(
              label: 'Conflicting Question IDs',
              values: report.conflictingQuestionIds.map((id) => '$id').toList(),
            ),
        ],
      ),
    );
  }
}

class _SourcePanel extends StatelessWidget {
  const _SourcePanel({required this.report});

  final FlashcardSourceQualityReport report;

  @override
  Widget build(BuildContext context) {
    return _DiagnosticCard(
      key: const ValueKey('flashcard-diagnostics-source'),
      title: 'Source quality',
      icon: Icons.verified_user_outlined,
      passed: report.passed,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _metricRow(
            context,
            'Verified primary coverage',
            '${report.cardsWithVerifiedPrimarySource} / ${report.cardCount}',
          ),
          _metricRow(
            context,
            'Verified sources',
            report.verifiedSourceCount.toString(),
          ),
          _metricRow(
            context,
            'Needs review',
            report.needsReviewSourceCount.toString(),
          ),
          _metricRow(context, 'Stale', report.staleSourceCount.toString()),
          _metricRow(context, 'Blocked', report.blockedSourceCount.toString()),
        ],
      ),
    );
  }
}

class _PlacementPanel extends StatelessWidget {
  const _PlacementPanel({required this.report});

  final FlashcardStudyContentPlacementReport report;

  @override
  Widget build(BuildContext context) {
    return _DiagnosticCard(
      key: const ValueKey('flashcard-diagnostics-placement'),
      title: 'StudyContent placement integrity',
      icon: Icons.layers_outlined,
      passed: report.passed,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _metricRow(context, 'Cards checked', report.checkedCards.toString()),
          _metricRow(context, 'Issues', report.issues.length.toString()),
          for (final issue in report.issues.take(20))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '${issue.cardId} • ${issue.level} • '
                '${issue.identifier}: ${issue.message}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}

class _CollectionPanel extends StatelessWidget {
  const _CollectionPanel({required this.report, required this.error});

  final FlashcardCollectionQualityReport? report;
  final Object? error;

  @override
  Widget build(BuildContext context) {
    final value = report;
    if (value == null) {
      return _DiagnosticCard(
        key: const ValueKey('flashcard-diagnostics-collection'),
        title: 'Collection quality',
        icon: Icons.person_off_outlined,
        passed: false,
        child: Text(
          'Learner-scoped collection diagnostics are unavailable for this '
          'admin session. ${error ?? ''}',
        ),
      );
    }

    return _DiagnosticCard(
      key: const ValueKey('flashcard-diagnostics-collection'),
      title: 'Collection and memory quality',
      icon: Icons.collections_bookmark_outlined,
      passed: value.passed,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _metricRow(context, 'Owned', value.ownedCount.toString()),
          _metricRow(context, 'Unseen', value.unseenCount.toString()),
          _metricRow(
            context,
            'Memory states',
            value.reviewStateCount.toString(),
          ),
          _metricRow(context, 'Due now', value.dueCount.toString()),
          _metricRow(
            context,
            'Orphan ownership',
            value.orphanOwnershipCardIds.length.toString(),
          ),
          _metricRow(
            context,
            'Concept mismatches',
            value.conceptMismatchCardIds.length.toString(),
          ),
          _metricRow(
            context,
            'Orphan review state',
            value.orphanReviewCardIds.length.toString(),
          ),
          _metricRow(
            context,
            'Review before reveal',
            value.reviewBeforeRevealCardIds.length.toString(),
          ),
        ],
      ),
    );
  }
}

class _DiagnosticCard extends StatelessWidget {
  const _DiagnosticCard({
    super.key,
    required this.title,
    required this.icon,
    required this.passed,
    required this.child,
  });

  final String title;
  final IconData icon;
  final bool passed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = passed ? Colors.green : scheme.error;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Chip(
                  label: Text(passed ? 'PASS' : 'CHECK'),
                  side: BorderSide(color: accent.withValues(alpha: .35)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text('$label: $value'));
  }
}

class _IdWrap extends StatelessWidget {
  const _IdWrap({required this.label, required this.values});

  final String label;
  final List<String> values;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: values.map((value) => Chip(label: Text(value))).toList(),
          ),
        ],
      ),
    );
  }
}

Widget _metricRow(BuildContext context, String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 42),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 14),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _FlashcardDiagnosticsSnapshot {
  const _FlashcardDiagnosticsSnapshot({
    required this.publishedStudyContentCount,
    required this.eligibleQuestionCount,
    required this.mapping,
    required this.placement,
    required this.source,
    required this.collection,
    required this.collectionError,
  });

  final int publishedStudyContentCount;
  final int eligibleQuestionCount;
  final FlashcardQuestionMappingCoverage mapping;
  final FlashcardStudyContentPlacementReport placement;
  final FlashcardSourceQualityReport source;
  final FlashcardCollectionQualityReport? collection;
  final Object? collectionError;
}
