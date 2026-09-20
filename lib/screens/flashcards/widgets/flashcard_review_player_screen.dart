import 'dart:async';

import 'package:flutter/material.dart';

import '../../../features/flashcards/learner/flashcard_learner_experience_controller.dart';
import '../../../features/flashcards/memory/flashcard_review_session_state.dart';
import '../../../features/flashcards/memory/flashcard_review_state.dart';
import '../../../services/haptics/csp11_haptic_service.dart';
import '../../../theme/glass/student_glass.dart';
import '../../../widgets/motion/csp11_completion_reveal.dart';
import 'flashcard_card_view.dart';
import 'flashcard_source_details_sheet.dart';

class FlashcardReviewPlayerScreen extends StatefulWidget {
  const FlashcardReviewPlayerScreen({
    super.key,
    required this.controller,
    required this.snapshot,
    required this.session,
  });

  final FlashcardLearnerExperienceController controller;
  final FlashcardLearnerSnapshot snapshot;
  final FlashcardReviewSessionState session;

  @override
  State<FlashcardReviewPlayerScreen> createState() =>
      _FlashcardReviewPlayerScreenState();
}

class _FlashcardReviewPlayerScreenState
    extends State<FlashcardReviewPlayerScreen> {
  late FlashcardReviewSessionState _session;
  bool _revealed = false;
  bool _busy = false;
  bool _swipeEnabled = true;

  @override
  void initState() {
    super.initState();
    _session = widget.session;
  }

  void _reveal() {
    if (_revealed || _session.isCompleted) {
      return;
    }
    setState(() => _revealed = true);
    unawaited(Csp11Haptics.selection());
  }

  Future<void> _rate(FlashcardReviewRating rating) async {
    if (_busy || !_revealed || _session.isCompleted) {
      return;
    }

    setState(() => _busy = true);
    try {
      final result = await widget.controller.rateCurrent(
        sessionId: _session.sessionId,
        rating: rating,
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _session = result.session;
        _revealed = false;
      });

      switch (rating) {
        case FlashcardReviewRating.again:
          await Csp11Haptics.warning();
        case FlashcardReviewRating.hard:
          await Csp11Haptics.confirm();
        case FlashcardReviewRating.gotIt:
          await Csp11Haptics.success();
      }

      if (_session.isCompleted) {
        await Csp11Haptics.completion();
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _handleHorizontalDrag(DragEndDetails details) {
    if (!_swipeEnabled || !_revealed || _busy || _session.isCompleted) {
      return;
    }

    final velocity = details.primaryVelocity ?? 0;
    if (velocity > 320) {
      unawaited(_rate(FlashcardReviewRating.gotIt));
    } else if (velocity < -320) {
      unawaited(_rate(FlashcardReviewRating.again));
    }
  }

  void _showSources(String cardId) {
    unawaited(
      showFlashcardSourceDetailsSheet(
        context,
        details: widget.snapshot.sourceDetailsFor(cardId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_session.isCompleted) {
      return _CompletionView(session: _session);
    }

    final cardId = _session.currentCardId;
    final card = cardId == null ? null : widget.snapshot.cardsById[cardId];
    if (card == null) {
      return StudentGlassScaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Review'),
        ),
        body: const Center(
          child: Text('This review card is no longer available.'),
        ),
      );
    }

    final total = _session.cardIds.length;
    final currentNumber = _session.nextIndex + 1;

    return StudentGlassScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Memory review',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            tooltip: _swipeEnabled
                ? 'Disable swipe shortcuts'
                : 'Enable swipe shortcuts',
            onPressed: () {
              setState(() => _swipeEnabled = !_swipeEnabled);
              unawaited(Csp11Haptics.selection());
            },
            icon: Icon(
              _swipeEnabled
                  ? Icons.swipe_rounded
                  : Icons.touch_app_outlined,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 660),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: total == 0 ? 1 : currentNumber / total,
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '$currentNumber / $total',
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragEnd: _handleHorizontalDrag,
                    child: FlashcardCardView(
                      card: card,
                      isFlipped: _revealed,
                      sourceFooter:
                          widget.snapshot.primarySourceFooterFor(card.id),
                      onReveal: _revealed ? null : _reveal,
                      onSourceTap:
                          _revealed ? () => _showSources(card.id) : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!_revealed)
                    FilledButton.icon(
                      key: const ValueKey('review-reveal-button'),
                      onPressed: _reveal,
                      icon: const Icon(Icons.visibility_rounded),
                      label: const Text('Reveal meaning'),
                    )
                  else ...[
                    if (_swipeEnabled)
                      Text(
                        'Optional shortcut: swipe left for Again or right for Got It.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            key: const ValueKey('review-again-button'),
                            onPressed: _busy
                                ? null
                                : () => unawaited(
                                      _rate(FlashcardReviewRating.again),
                                    ),
                            child: const Text('Again'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            key: const ValueKey('review-hard-button'),
                            onPressed: _busy
                                ? null
                                : () => unawaited(
                                      _rate(FlashcardReviewRating.hard),
                                    ),
                            child: const Text('Hard'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton(
                            key: const ValueKey('review-got-it-button'),
                            onPressed: _busy
                                ? null
                                : () => unawaited(
                                      _rate(FlashcardReviewRating.gotIt),
                                    ),
                            child: const Text('Got It'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompletionView extends StatelessWidget {
  const _CompletionView({required this.session});

  final FlashcardReviewSessionState session;

  @override
  Widget build(BuildContext context) {
    return StudentGlassScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Review complete',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Csp11CompletionReveal(
              celebratory: true,
              child: StudentGlassSurface(
                constraints: const BoxConstraints(maxWidth: 520),
                borderRadius: BorderRadius.circular(28),
                padding: const EdgeInsets.all(28),
                child: Column(
                  children: [
                    Icon(
                      Icons.task_alt_rounded,
                      size: 54,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Memory session complete',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${session.completedCount} concept cards reviewed.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Back to collection'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
