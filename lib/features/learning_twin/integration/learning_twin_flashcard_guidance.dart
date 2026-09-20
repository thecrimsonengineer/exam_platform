import 'package:flutter/material.dart';

import '../../flashcards/integration/flashcard_integration_models.dart';
import '../domain/learning_twin_domain.dart';
import '../ui/learning_twin_ui.dart';

class LearningTwinFlashcardGuidance extends StatefulWidget {
  const LearningTwinFlashcardGuidance({super.key, required this.summary});

  final FlashcardLearningTwinSummary summary;

  @override
  State<LearningTwinFlashcardGuidance> createState() =>
      _LearningTwinFlashcardGuidanceState();
}

class _LearningTwinFlashcardGuidanceState
    extends State<LearningTwinFlashcardGuidance> {
  static const _screenId = 'flashcard-collection';
  static const _decisionService = DeterministicLearningTwinDecisionService();

  static int _nextVisitSequence = 0;

  late final LearningTwinContext _context;
  late LearningTwinSessionState _sessionState;
  late LearningTwinDecision _decision;

  @override
  void initState() {
    super.initState();

    final sequence = _nextVisitSequence++;
    final candidate = _candidateFor(widget.summary);

    _context = LearningTwinContext(
      screenId: _screenId,
      visitId: '$_screenId-$sequence',
      trigger: candidate?.trigger ?? LearningTwinTrigger.screenVisit,
    );
    _sessionState = LearningTwinSessionState.empty();
    _decision = candidate == null
        ? const LearningTwinDecision.none(
            LearningTwinDecisionReason.noEligibleMessage,
          )
        : _decisionService.decide(
            context: _context,
            candidates: <LearningTwinMessage>[candidate],
            sessionState: _sessionState,
          );

    final message = _decision.message;
    if (message != null) {
      _sessionState = _sessionState.markShown(
        message: message,
        context: _context,
      );
    }
  }

  @override
  void didUpdateWidget(covariant LearningTwinFlashcardGuidance oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_summarySignature(oldWidget.summary) ==
        _summarySignature(widget.summary)) {
      return;
    }

    final candidate = _candidateFor(widget.summary);
    setState(() {
      _decision = candidate == null
          ? const LearningTwinDecision.none(
              LearningTwinDecisionReason.noEligibleMessage,
            )
          : _decisionService.decide(
              context: LearningTwinContext(
                screenId: _screenId,
                visitId: _context.visitId,
                trigger: candidate.trigger,
              ),
              candidates: <LearningTwinMessage>[candidate],
              sessionState: _sessionState,
            );

      final message = _decision.message;
      if (message != null) {
        _sessionState = _sessionState.markShown(
          message: message,
          context: _context,
        );
      }
    });
  }

  void _dismiss() {
    final message = _decision.message;
    if (message == null) {
      return;
    }

    setState(() {
      _sessionState = _sessionState.dismiss(message.id);
      _decision = const LearningTwinDecision.none(
        LearningTwinDecisionReason.noEligibleMessage,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final message = _decision.message;
    if (message == null) {
      return const SizedBox.shrink();
    }

    return LearningTwinMotionReveal(
      motionKey: message.id,
      celebratory: message.state == LearningTwinState.celebrate,
      child: LearningTwinCard(
        key: const ValueKey<String>('learning-twin-flashcard-guidance'),
        title: message.title ?? 'Learning Guide',
        message: message.body,
        asset: _assetFor(message.state),
        onDismiss: _dismiss,
      ),
    );
  }

  static LearningTwinMessage? _candidateFor(
    FlashcardLearningTwinSummary summary,
  ) {
    if (summary.dueCount > 0) {
      final domainText = summary.dueDomainIds.isEmpty
          ? ''
          : ' across ${summary.dueDomainIds.length} CSP11 '
                'domain${summary.dueDomainIds.length == 1 ? '' : 's'}';

      return LearningTwinMessage(
        id: 'flashcard-due-v1-${summary.dueCount}-${summary.weakCount}',
        state: LearningTwinState.recommend,
        trigger: LearningTwinTrigger.recommendationAvailable,
        title: 'A short memory review is ready',
        body:
            'You have ${summary.dueCount} concept '
            'card${summary.dueCount == 1 ? '' : 's'} due$domainText. '
            '${summary.weakCount > 0 ? 'The review queue will prioritise ${summary.weakCount} weaker concept${summary.weakCount == 1 ? '' : 's'} while keeping the scheduler rules unchanged.' : 'A quick review now can keep these concepts active.'}',
        priority: 130,
        screenId: _screenId,
      );
    }

    if (summary.unseenCount > 0) {
      return LearningTwinMessage(
        id: 'flashcard-unseen-v1-${summary.unseenCount}',
        state: LearningTwinState.tip,
        trigger: LearningTwinTrigger.recommendationAvailable,
        title: 'New concept cards are waiting',
        body:
            'You have ${summary.unseenCount} collected '
            'card${summary.unseenCount == 1 ? '' : 's'} that '
            '${summary.unseenCount == 1 ? 'has' : 'have'} not been revealed yet. '
            'Open a card when you are ready. Its memory schedule begins only after the meaning is revealed.',
        priority: 110,
        screenId: _screenId,
      );
    }

    if (summary.ownedCount > 0 && summary.totalReviewEvents > 0) {
      return LearningTwinMessage(
        id: 'flashcard-clear-v1',
        state: LearningTwinState.encourage,
        trigger: LearningTwinTrigger.recommendationAvailable,
        title: 'Your concept review queue is clear',
        body:
            'No Flashcards are due right now. Your Collection has '
            '${summary.ownedCount} concept card${summary.ownedCount == 1 ? '' : 's'} '
            'and ${summary.totalReviewEvents} completed memory '
            'review${summary.totalReviewEvents == 1 ? '' : 's'}.',
        priority: 80,
        screenId: _screenId,
      );
    }

    return null;
  }

  static LearningTwinAsset _assetFor(LearningTwinState state) {
    return switch (state) {
      LearningTwinState.celebrate => LearningTwinAsset.success,
      LearningTwinState.remediate ||
      LearningTwinState.explain ||
      LearningTwinState.important ||
      LearningTwinState.warning => LearningTwinAsset.explain,
      _ => LearningTwinAsset.neutral,
    };
  }

  static String _summarySignature(FlashcardLearningTwinSummary summary) {
    return <Object>[
      summary.ownedCount,
      summary.unseenCount,
      summary.dueCount,
      summary.weakCount,
      summary.totalReviewEvents,
      ...summary.dueDomainIds,
    ].join('|');
  }
}
