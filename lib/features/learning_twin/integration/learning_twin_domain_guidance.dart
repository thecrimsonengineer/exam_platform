import 'package:exam_platform/features/learning_twin/domain/learning_twin_domain.dart';
import 'package:exam_platform/features/learning_twin/ui/learning_twin_ui.dart';
import 'package:flutter/material.dart';

/// Controlled M4 guidance for a CSP domain overview.
///
/// The integration bridge owns context construction and presentation mapping.
/// Eligibility remains owned by the frozen M3 decision service.
class LearningTwinDomainGuidance extends StatefulWidget {
  const LearningTwinDomainGuidance({super.key, required this.domainId})
    : assert(domainId != '');

  final String domainId;

  @override
  State<LearningTwinDomainGuidance> createState() =>
      _LearningTwinDomainGuidanceState();
}

class _LearningTwinDomainGuidanceState
    extends State<LearningTwinDomainGuidance> {
  static const _screenId = 'csp-domain';

  static const _message = LearningTwinMessage(
    id: 'csp-domain-focus-v1',
    state: LearningTwinState.tip,
    trigger: LearningTwinTrigger.screenVisit,
    title: 'Work one learning area at a time',
    body:
        'Choose one competency, study it through, then use practice to check '
        'what you can explain without looking back.',
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
  void didUpdateWidget(covariant LearningTwinDomainGuidance oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.domainId != widget.domainId) {
      _beginVisit();
    }
  }

  void _beginVisit() {
    final visitSequence = _nextVisitSequence++;

    _learningContext = LearningTwinContext(
      screenId: _screenId,
      visitId: '$_screenId-${widget.domainId}-$visitSequence',
      trigger: LearningTwinTrigger.screenVisit,
      domainId: widget.domainId,
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
