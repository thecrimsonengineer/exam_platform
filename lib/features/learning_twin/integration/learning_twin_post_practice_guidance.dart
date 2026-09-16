import 'package:flutter/material.dart';

import '../coaching/learning_twin_practice_result_context.dart';
import '../coaching/learning_twin_practice_result_message_bridge.dart';
import '../domain/learning_twin_domain.dart';
import '../ui/learning_twin_ui.dart';

/// Deterministic, dismissible Learning Twin guidance for a completed practice
/// session. The widget receives only an aggregate sanitized result contract.
class LearningTwinPostPracticeGuidance extends StatefulWidget {
  const LearningTwinPostPracticeGuidance({
    super.key,
    required this.resultContext,
    this.isTimedExamActive = false,
  });

  final LearningTwinPracticeResultContext resultContext;
  final bool isTimedExamActive;

  @override
  State<LearningTwinPostPracticeGuidance> createState() =>
      _LearningTwinPostPracticeGuidanceState();
}

class _LearningTwinPostPracticeGuidanceState
    extends State<LearningTwinPostPracticeGuidance> {
  static const _screenId = 'practice-result';
  static const _bridge = LearningTwinPracticeResultMessageBridge();
  static const _decisionService = DeterministicLearningTwinDecisionService();

  static int _nextVisitSequence = 0;

  late final LearningTwinContext _learningContext;
  late final LearningTwinMessage _candidate;
  late LearningTwinSessionState _sessionState;
  late LearningTwinDecision _decision;

  @override
  void initState() {
    super.initState();

    _candidate = _bridge.toCandidate(
      resultContext: widget.resultContext,
      screenId: _screenId,
    );

    final practice = widget.resultContext.practiceContext;
    final visitSequence = _nextVisitSequence++;

    _learningContext = LearningTwinContext(
      screenId: _screenId,
      visitId: '$_screenId-$visitSequence',
      trigger: LearningTwinTrigger.practiceCompleted,
      isTimedExamActive: widget.isTimedExamActive,
      domainId: practice.domainId,
      competencyId: _clean(practice.competencyId),
      subtopicId: _clean(practice.subtopicId),
    );

    _sessionState = LearningTwinSessionState.empty();
    _decision = _decisionService.decide(
      context: _learningContext,
      candidates: <LearningTwinMessage>[_candidate],
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
        candidates: <LearningTwinMessage>[_candidate],
        sessionState: _sessionState,
      );
    });
  }

  String? _clean(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  LearningTwinAsset _assetFor(LearningTwinState state) {
    return switch (state) {
      LearningTwinState.celebrate => LearningTwinAsset.success,
      LearningTwinState.resultReview ||
      LearningTwinState.remediate ||
      LearningTwinState.explain => LearningTwinAsset.explain,
      _ => LearningTwinAsset.neutral,
    };
  }

  @override
  Widget build(BuildContext context) {
    final message = _decision.message;

    if (message == null) {
      return const SizedBox.shrink();
    }

    return LearningTwinCard(
      key: const ValueKey<String>('learning-twin-post-practice-guidance'),
      title: message.title ?? 'Practice review',
      message: message.body,
      asset: _assetFor(message.state),
      onDismiss: _dismiss,
    );
  }
}
