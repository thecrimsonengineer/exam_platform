import 'package:flutter/material.dart';

import '../coaching/learning_twin_practice_context.dart';
import '../coaching/learning_twin_practice_message_bridge.dart';
import '../domain/learning_twin_domain.dart';
import '../ui/learning_twin_ui.dart';

/// Non-blocking host for pre-practice Learning Twin guidance.
///
/// The quiz/session remains the host-owned [child]. The Learning Twin receives
/// only [LearningTwinPracticeContext], never the quiz's protected question
/// payload.
class LearningTwinPracticeSessionHost extends StatelessWidget {
  const LearningTwinPracticeSessionHost({
    super.key,
    required this.practiceContext,
    required this.child,
    this.theme,
    this.isTimedExamActive = false,
  });

  final LearningTwinPracticeContext practiceContext;
  final Widget child;
  final ThemeData? theme;
  final bool isTimedExamActive;

  @override
  Widget build(BuildContext context) {
    final content = ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          LearningTwinPrePracticeGuidance(
            practiceContext: practiceContext,
            isTimedExamActive: isTimedExamActive,
          ),
          Expanded(child: child),
        ],
      ),
    );

    final routeTheme = theme;
    if (routeTheme == null) {
      return content;
    }

    return Theme(data: routeTheme, child: content);
  }
}

/// First M6 practice-coach surface.
///
/// Sanitized practice metadata is converted into one deterministic candidate.
/// The frozen M3 decision service still decides whether the candidate may be
/// shown. Timed-exam suppression therefore remains fail-closed at the decision
/// layer rather than in presentation code.
class LearningTwinPrePracticeGuidance extends StatefulWidget {
  const LearningTwinPrePracticeGuidance({
    super.key,
    required this.practiceContext,
    this.isTimedExamActive = false,
  });

  final LearningTwinPracticeContext practiceContext;
  final bool isTimedExamActive;

  @override
  State<LearningTwinPrePracticeGuidance> createState() =>
      _LearningTwinPrePracticeGuidanceState();
}

class _LearningTwinPrePracticeGuidanceState
    extends State<LearningTwinPrePracticeGuidance> {
  static const _screenId = 'practice-quiz';
  static const _bridge = LearningTwinPracticeMessageBridge();
  static const _decisionService = DeterministicLearningTwinDecisionService();

  static int _nextVisitSequence = 0;

  late final LearningTwinContext _learningContext;
  late LearningTwinSessionState _sessionState;
  late LearningTwinDecision _decision;
  late final LearningTwinMessage _candidate;

  @override
  void initState() {
    super.initState();

    _candidate = _bridge.toCandidate(
      practiceContext: widget.practiceContext,
      screenId: _screenId,
    );

    final visitSequence = _nextVisitSequence++;

    _learningContext = LearningTwinContext(
      screenId: _screenId,
      visitId: '$_screenId-$visitSequence',
      trigger: _candidate.trigger,
      isTimedExamActive: widget.isTimedExamActive,
      domainId: widget.practiceContext.domainId,
      competencyId: _clean(widget.practiceContext.competencyId),
      subtopicId: _clean(widget.practiceContext.subtopicId),
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
      LearningTwinState.remediate ||
      LearningTwinState.explain ||
      LearningTwinState.important ||
      LearningTwinState.warning => LearningTwinAsset.explain,
      LearningTwinState.celebrate => LearningTwinAsset.success,
      _ => LearningTwinAsset.neutral,
    };
  }

  @override
  Widget build(BuildContext context) {
    final message = _decision.message;

    if (message == null) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
        child: LearningTwinCard(
          key: const ValueKey<String>('learning-twin-pre-practice-guidance'),
          title: message.title ?? 'Learning Guide',
          message: message.body,
          asset: _assetFor(message.state),
          onDismiss: _dismiss,
        ),
      ),
    );
  }
}
