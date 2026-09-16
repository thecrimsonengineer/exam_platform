import '../domain/learning_twin_domain.dart';
import 'learning_twin_progress_insight.dart';

/// Converts an M5 progress insight into an M3 message candidate.
///
/// This bridge does not decide whether the message may be shown. The resulting
/// candidate must still pass through [LearningTwinDecisionService].
///
/// The insight's [LearningTwinProgressInsight.domainId] is a recommendation
/// target. It is deliberately not used as the message's context-matching
/// domain unless [scopeDomainId] is explicitly supplied by a future host.
final class LearningTwinProgressMessageBridge {
  const LearningTwinProgressMessageBridge();

  LearningTwinMessage toCandidate({
    required LearningTwinProgressInsight insight,
    required String screenId,
    String? scopeDomainId,
  }) {
    if (screenId.trim().isEmpty) {
      throw ArgumentError.value(screenId, 'screenId', 'must not be empty');
    }

    return LearningTwinMessage(
      id: _messageId(insight),
      state: _stateFor(insight.type),
      trigger: _triggerFor(insight.type),
      title: insight.title,
      body: insight.body,
      action: _actionFor(insight),
      unsolicited: true,
      allowRepeat: false,
      priority: insight.priority,
      screenId: screenId,
      domainId: scopeDomainId,
    );
  }

  String _messageId(LearningTwinProgressInsight insight) {
    final target = insight.domainId ?? 'global';

    return switch (insight.type) {
      LearningTwinProgressInsightType.startLearning =>
        'm5-start-learning-$target-v1',
      LearningTwinProgressInsightType.continueLearning =>
        'm5-continue-learning-$target-v1',
      LearningTwinProgressInsightType.addPractice =>
        'm5-add-practice-$target-v1',
      LearningTwinProgressInsightType.weakDomainRemediation =>
        'm5-weak-domain-$target-v1',
      LearningTwinProgressInsightType.masteryAcknowledgement =>
        'm5-mastery-$target-v1',
    };
  }

  LearningTwinState _stateFor(LearningTwinProgressInsightType type) {
    return switch (type) {
      LearningTwinProgressInsightType.startLearning =>
        LearningTwinState.recommend,
      LearningTwinProgressInsightType.continueLearning =>
        LearningTwinState.recommend,
      LearningTwinProgressInsightType.addPractice =>
        LearningTwinState.recommend,
      LearningTwinProgressInsightType.weakDomainRemediation =>
        LearningTwinState.remediate,
      LearningTwinProgressInsightType.masteryAcknowledgement =>
        LearningTwinState.celebrate,
    };
  }

  LearningTwinTrigger _triggerFor(LearningTwinProgressInsightType type) {
    return switch (type) {
      LearningTwinProgressInsightType.startLearning =>
        LearningTwinTrigger.recommendationAvailable,
      LearningTwinProgressInsightType.continueLearning =>
        LearningTwinTrigger.recommendationAvailable,
      LearningTwinProgressInsightType.addPractice =>
        LearningTwinTrigger.recommendationAvailable,
      LearningTwinProgressInsightType.weakDomainRemediation =>
        LearningTwinTrigger.remediationOpportunity,
      LearningTwinProgressInsightType.masteryAcknowledgement =>
        LearningTwinTrigger.milestoneReached,
    };
  }

  LearningTwinAction? _actionFor(LearningTwinProgressInsight insight) {
    final target = insight.domainId;

    return switch (insight.type) {
      LearningTwinProgressInsightType.weakDomainRemediation
          when target != null =>
        LearningTwinAction(
          id: 'm5-review-$target-v1',
          label: 'Review domain',
          type: LearningTwinActionType.openContent,
          targetId: target,
        ),
      LearningTwinProgressInsightType.continueLearning when target != null =>
        LearningTwinAction(
          id: 'm5-continue-$target-v1',
          label: 'Continue learning',
          type: LearningTwinActionType.continueLearning,
          targetId: target,
        ),
      LearningTwinProgressInsightType.addPractice when target != null =>
        LearningTwinAction(
          id: 'm5-practice-$target-v1',
          label: 'Start practice',
          type: LearningTwinActionType.startPractice,
          targetId: target,
        ),
      _ => null,
    };
  }
}
