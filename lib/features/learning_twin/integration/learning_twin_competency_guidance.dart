import 'package:exam_platform/features/learning_twin/domain/learning_twin_domain.dart';
import 'package:exam_platform/features/learning_twin/ui/learning_twin_ui.dart';
import 'package:flutter/material.dart';

/// Controlled M4 guidance for the competency content index.
///
/// This surface deliberately stays deterministic. It does not inspect learner
/// progress or choose adaptive recommendations; those remain M5 work.
class LearningTwinCompetencyGuidance extends StatefulWidget {
  const LearningTwinCompetencyGuidance({
    super.key,
    required this.domainId,
    required this.competencyId,
  }) : assert(domainId != ''),
       assert(competencyId != '');

  final String domainId;
  final String competencyId;

  @override
  State<LearningTwinCompetencyGuidance> createState() =>
      _LearningTwinCompetencyGuidanceState();
}

class _LearningTwinCompetencyGuidanceState
    extends State<LearningTwinCompetencyGuidance> {
  static const _screenId = 'csp-competency-overview';

  static const _message = LearningTwinMessage(
    id: 'csp-competency-study-first-v1',
    state: LearningTwinState.explain,
    trigger: LearningTwinTrigger.screenVisit,
    title: 'Study first, then test recall',
    body:
        'Open one topic at a time and finish its subtopics. Use practice after '
        'you can explain the main ideas in your own words.',
    priority: 90,
    screenId: _screenId,
  );

  static const _decisionService = DeterministicLearningTwinDecisionService();

  static int _nextVisitSequence = 0;

  late LearningTwinContext _learningContext;
  LearningTwinSessionState _sessionState = LearningTwinSessionState.empty();
  LearningTwinDecision _decision = const LearningTwinDecision.none(
    LearningTwinDecisionReason.noEligibleMessage,
  );

  @override
  void initState() {
    super.initState();
    _beginVisit();
  }

  @override
  void didUpdateWidget(covariant LearningTwinCompetencyGuidance oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.domainId != widget.domainId ||
        oldWidget.competencyId != widget.competencyId) {
      _beginVisit();
    }
  }

  void _beginVisit() {
    final visitSequence = _nextVisitSequence++;

    _learningContext = LearningTwinContext(
      screenId: _screenId,
      visitId:
          '$_screenId-${widget.domainId}-${widget.competencyId}-$visitSequence',
      trigger: LearningTwinTrigger.screenVisit,
      domainId: widget.domainId,
      competencyId: widget.competencyId,
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
      candidates: const <LearningTwinMessage>[_message],
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

    return LearningTwinCard(
      title: message.title ?? 'Learning Guide',
      message: message.body,
      asset: LearningTwinAsset.explain,
      onDismiss: _dismiss,
    );
  }
}
