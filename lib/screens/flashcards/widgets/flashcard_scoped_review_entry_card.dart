import 'dart:async';

import 'package:flutter/material.dart';

import '../../../features/flashcards/integration/flashcard_integration_models.dart';
import '../../../features/flashcards/integration/flashcard_integration_service.dart';
import '../../../features/flashcards/learner/flashcard_learner_experience_controller.dart';
import '../../../navigation/csp11_route.dart';
import '../../../services/haptics/csp11_haptic_service.dart';
import '../../../theme/glass/student_glass.dart';
import 'flashcard_review_player_screen.dart';

class FlashcardScopedReviewEntryCard extends StatefulWidget {
  const FlashcardScopedReviewEntryCard({
    super.key,
    required this.scope,
    required this.title,
    required this.subtitle,
    this.integrationService,
    this.learnerController,
  });

  final FlashcardReviewScope scope;
  final String title;
  final String subtitle;
  final FlashcardIntegrationService? integrationService;
  final FlashcardLearnerExperienceController? learnerController;

  @override
  State<FlashcardScopedReviewEntryCard> createState() =>
      _FlashcardScopedReviewEntryCardState();
}

class _FlashcardScopedReviewEntryCardState
    extends State<FlashcardScopedReviewEntryCard> {
  late final FlashcardIntegrationService _integration;
  late final FlashcardLearnerExperienceController _learnerController;

  FlashcardScopedReviewSummary? _summary;
  bool _loading = true;
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    _integration =
        widget.integrationService ?? FlashcardIntegrationService.local();
    _learnerController =
        widget.learnerController ?? FlashcardLearnerExperienceController.local();
    unawaited(_refresh());
  }

  @override
  void didUpdateWidget(covariant FlashcardScopedReviewEntryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scope.storageKey != widget.scope.storageKey) {
      unawaited(_refresh());
    }
  }

  Future<void> _refresh() async {
    if (mounted) {
      setState(() => _loading = true);
    }

    try {
      final summary = await _integration.scopedReviewSummary(
        scope: widget.scope,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _summary = summary;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _summary = null;
        _loading = false;
      });
    }
  }

  Future<void> _openReview() async {
    final summary = _summary;
    if (_opening || summary == null || !summary.canReview) {
      return;
    }

    setState(() => _opening = true);
    try {
      final session = await _integration.startOrResumeScopedReview(
        scope: widget.scope,
      );
      if (session.cardIds.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No Flashcards are due in this learning area.'),
            ),
          );
        }
        return;
      }

      final snapshot = await _learnerController.load();
      if (!mounted) {
        return;
      }

      await Csp11Haptics.navigation();
      if (!mounted) {
        return;
      }

      await Navigator.of(context).push(
        Csp11Route.forward<void>(
          child: FlashcardReviewPlayerScreen(
            controller: _learnerController,
            snapshot: snapshot,
            session: session,
          ),
        ),
      );
      await _refresh();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Flashcard review is unavailable: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _opening = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final summary = _summary;

    final active = summary?.activeSession;
    final dueCount = summary?.dueCards ?? 0;
    final title = active != null
        ? 'Resume Flashcard review'
        : dueCount > 0
        ? '$dueCount Flashcard${dueCount == 1 ? '' : 's'} due'
        : widget.title;
    final detail = active != null
        ? '${active.remainingCount} card${active.remainingCount == 1 ? '' : 's'} remain in this saved review.'
        : dueCount > 0
        ? widget.subtitle
        : 'No cards are due in this scope right now.';

    return StudentGlassSurface(
      key: ValueKey('flashcard-review-entry-${widget.scope.storageKey}'),
      width: double.infinity,
      borderRadius: BorderRadius.circular(20),
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: .11),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.all(11),
              child: Icon(
                Icons.style_rounded,
                color: scheme.primary,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _loading ? 'Checking your local memory queue…' : detail,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                if (!_loading && summary != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${summary.ownedCards} owned • '
                    '${summary.unseenCards} unseen • '
                    '${summary.dueCards} due',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            key: ValueKey(
              'flashcard-review-entry-action-${widget.scope.storageKey}',
            ),
            onPressed:
                _loading || _opening || summary?.canReview != true
                ? null
                : () => unawaited(_openReview()),
            icon: _opening
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow_rounded, size: 18),
            label: Text(active != null ? 'Resume' : 'Review'),
          ),
        ],
      ),
    );
  }
}
