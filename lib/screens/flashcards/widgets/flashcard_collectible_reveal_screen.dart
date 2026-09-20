import 'dart:async';

import 'package:flutter/material.dart';

import '../../../features/flashcards/collection/flashcard_ownership.dart';
import '../../../features/flashcards/learner/flashcard_learner_experience_controller.dart';
import '../../../features/flashcards/models/flashcard.dart';
import '../../../services/haptics/csp11_haptic_service.dart';
import '../../../theme/glass/student_glass.dart';
import 'flashcard_card_view.dart';
import 'flashcard_source_details_sheet.dart';

class FlashcardCollectibleRevealScreen extends StatefulWidget {
  const FlashcardCollectibleRevealScreen({
    super.key,
    required this.card,
    required this.ownership,
    required this.snapshot,
    required this.controller,
  });

  final Flashcard card;
  final FlashcardOwnership ownership;
  final FlashcardLearnerSnapshot snapshot;
  final FlashcardLearnerExperienceController controller;

  @override
  State<FlashcardCollectibleRevealScreen> createState() =>
      _FlashcardCollectibleRevealScreenState();
}

class _FlashcardCollectibleRevealScreenState
    extends State<FlashcardCollectibleRevealScreen> {
  late bool _revealed;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _revealed = widget.ownership.isFirstViewed;
  }

  Future<void> _reveal() async {
    if (_revealed || _busy) {
      return;
    }

    setState(() => _busy = true);
    try {
      await widget.controller.revealCard(widget.card.id);
      if (!mounted) {
        return;
      }
      setState(() => _revealed = true);
      await Csp11Haptics.success();
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _showSources() {
    unawaited(
      showFlashcardSourceDetailsSheet(
        context,
        details: widget.snapshot.sourceDetailsFor(widget.card.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StudentGlassScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.ownership.isUnseen ? 'New concept' : 'Concept card',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Column(
                children: [
                  FlashcardCardView(
                    card: widget.card,
                    isFlipped: _revealed,
                    sourceFooter: widget.snapshot.primarySourceFooterFor(
                      widget.card.id,
                    ),
                    onReveal: _revealed || _busy
                        ? null
                        : () => unawaited(_reveal()),
                    onSourceTap: _revealed ? _showSources : null,
                  ),
                  const SizedBox(height: 18),
                  if (!_revealed)
                    FilledButton.icon(
                      key: const ValueKey('flashcard-reveal-button'),
                      onPressed: _busy ? null : () => unawaited(_reveal()),
                      icon: _busy
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.visibility_rounded),
                      label: const Text('Reveal card'),
                    )
                  else
                    Text(
                      'Memory review is now active for this concept.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
