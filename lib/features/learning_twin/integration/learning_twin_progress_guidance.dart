import 'package:exam_platform/features/learning_twin/coaching/learning_twin_coaching.dart';
import 'package:exam_platform/features/learning_twin/domain/learning_twin_domain.dart';
import 'package:exam_platform/features/learning_twin/ui/learning_twin_ui.dart';
import 'package:exam_platform/models/progress_analytics_snapshot.dart';
import 'package:flutter/material.dart';

/// First adaptive M5 learner surface.
///
/// The Progress screen supplies an already-built local analytics snapshot.
/// This widget interprets that snapshot once for the current screen visit,
/// converts the insight to an M3 candidate, and lets the frozen M3 decision
/// service decide whether it may be shown.
///
/// The selected guidance remains stable for the visit even if the Progress
/// screen silently refreshes its snapshot. This avoids replacing or repeating
/// an unsolicited intervention while the learner is reading it.
class LearningTwinProgressGuidance extends StatefulWidget {
  const LearningTwinProgressGuidance({
    super.key,
    required this.snapshot,
    this.onOpenDomain,
  });

  final ProgressAnalyticsSnapshot snapshot;
  final ValueChanged<String>? onOpenDomain;

  @override
  State<LearningTwinProgressGuidance> createState() =>
      _LearningTwinProgressGuidanceState();
}

class _LearningTwinProgressGuidanceState
    extends State<LearningTwinProgressGuidance> {
  static const _screenId = 'progress-overview';

  static const _interpreter = DeterministicLearningTwinProgressInterpreter();
  static const _bridge = LearningTwinProgressMessageBridge();
  static const _decisionService = DeterministicLearningTwinDecisionService();
  static const _actionPolicy = LearningTwinProgressActionPolicy();

  static int _nextVisitSequence = 0;

  late final LearningTwinContext _learningContext;
  late LearningTwinSessionState _sessionState;
  late LearningTwinDecision _decision;
  bool _actionConsumed = false;

  @override
  void initState() {
    super.initState();

    final insight = _interpreter.interpret(widget.snapshot);
    final candidate = _bridge.toCandidate(
      insight: insight,
      screenId: _screenId,
    );

    final visitSequence = _nextVisitSequence++;

    _learningContext = LearningTwinContext(
      screenId: _screenId,
      visitId: '$_screenId-$visitSequence',
      trigger: candidate.trigger,
    );

    _sessionState = LearningTwinSessionState.empty();
    _decision = _decisionService.decide(
      context: _learningContext,
      candidates: <LearningTwinMessage>[candidate],
      sessionState: _sessionState,
    );

    final message = _decision.message;
    if (message != null) {
      _sessionState = _sessionState.markShown(
        message: message,
        context: _learningContext,
      );
    }
  }

  void _dismiss() {
    final message = _decision.message;
    if (message == null) {
      return;
    }

    setState(() {
      _sessionState = _sessionState.dismiss(message.id);
      _decision = _decisionService.decide(
        context: _learningContext,
        candidates: <LearningTwinMessage>[message],
        sessionState: _sessionState,
      );
    });
  }

  void _performAction(LearningTwinProgressActionBinding binding) {
    final openDomain = widget.onOpenDomain;

    if (_actionConsumed || openDomain == null) {
      return;
    }

    setState(() {
      _actionConsumed = true;
    });

    openDomain(binding.targetDomainId);
  }

  LearningTwinAsset _assetFor(LearningTwinState state) {
    return switch (state) {
      LearningTwinState.celebrate => LearningTwinAsset.success,
      LearningTwinState.remediate ||
      LearningTwinState.explain ||
      LearningTwinState.important ||
      LearningTwinState.warning => LearningTwinAsset.explain,
      _ => LearningTwinAsset.neutral,
    };
  }

  @override
  Widget build(BuildContext context) {
    final message = _decision.message;

    if (message == null) {
      return const SizedBox.shrink();
    }

    final actionBinding = _actionConsumed
        ? null
        : _actionPolicy.resolve(message);

    VoidCallback? actionCallback;
    String? actionLabel;
    if (widget.onOpenDomain != null && actionBinding != null) {
      final binding = actionBinding;
      actionLabel = binding.label;
      actionCallback = () => _performAction(binding);
    }

    return LearningTwinCard(
      key: const ValueKey<String>('learning-twin-progress-guidance'),
      title: message.title ?? 'Learning Guide',
      message: message.body,
      asset: _assetFor(message.state),
      actionLabel: actionLabel,
      onAction: actionCallback,
      onDismiss: _dismiss,
    );
  }
}
