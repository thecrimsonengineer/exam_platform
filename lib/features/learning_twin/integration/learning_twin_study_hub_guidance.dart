import 'package:exam_platform/features/learning_twin/domain/learning_twin_domain.dart';
import 'package:exam_platform/features/learning_twin/ui/learning_twin_ui.dart';
import 'package:flutter/material.dart';

/// First controlled M4 integration surface.
///
/// This widget owns the bridge between the frozen M3 decision layer and the
/// frozen M2 presentation layer. The Study Hub itself remains presentation
/// agnostic and does not decide whether guidance is allowed.
class LearningTwinStudyHubGuidance extends StatefulWidget {
  const LearningTwinStudyHubGuidance({super.key});

  @override
  State<LearningTwinStudyHubGuidance> createState() =>
      _LearningTwinStudyHubGuidanceState();
}

class _LearningTwinStudyHubGuidanceState
    extends State<LearningTwinStudyHubGuidance> {
  static const _screenId = 'csp-study-hub';

  static const _welcomeMessage = LearningTwinMessage(
    id: 'csp-study-hub-welcome-v1',
    state: LearningTwinState.welcome,
    trigger: LearningTwinTrigger.screenVisit,
    title: 'Start with one domain',
    body:
        'Choose the domain you want to study now and keep this session focused. '
        'I will stay out of the way while you work.',
    priority: 100,
    screenId: _screenId,
  );

  static const _decisionService = DeterministicLearningTwinDecisionService();

  static int _nextVisitSequence = 0;

  late final LearningTwinContext _learningContext;
  late LearningTwinSessionState _sessionState;
  late LearningTwinDecision _decision;

  @override
  void initState() {
    super.initState();

    final visitSequence = _nextVisitSequence++;
    _learningContext = LearningTwinContext(
      screenId: _screenId,
      visitId: '$_screenId-$visitSequence',
      trigger: LearningTwinTrigger.screenVisit,
    );

    _sessionState = LearningTwinSessionState.empty();
    _decision = _decide();

    final message = _decision.message;
    if (message != null) {
      _sessionState = _sessionState.markShown(
        message: message,
        context: _learningContext,
      );
    }
  }

  LearningTwinDecision _decide() {
    return _decisionService.decide(
      context: _learningContext,
      candidates: const <LearningTwinMessage>[_welcomeMessage],
      sessionState: _sessionState,
    );
  }

  void _dismiss() {
    final message = _decision.message;
    if (message == null) {
      return;
    }

    setState(() {
      _sessionState = _sessionState.dismiss(message.id);
      _decision = _decide();
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
        title: message.title ?? 'Learning Guide',
        message: message.body,
        asset: LearningTwinAsset.neutral,
        onDismiss: _dismiss,
      ),
    );
  }
}
