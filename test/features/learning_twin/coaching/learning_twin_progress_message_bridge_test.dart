import 'package:exam_platform/features/learning_twin/coaching/learning_twin_coaching.dart';
import 'package:exam_platform/features/learning_twin/domain/learning_twin_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const bridge = LearningTwinProgressMessageBridge();

  test('weak-domain insight becomes a deterministic remediation candidate', () {
    const insight = LearningTwinProgressInsight(
      type: LearningTwinProgressInsightType.weakDomainRemediation,
      priority: 90,
      title: 'Revisit Domain 03',
      body: 'Review the learning material before another practice set.',
      domainId: 'd03',
      domainNumber: 3,
    );

    final candidate = bridge.toCandidate(
      insight: insight,
      screenId: 'progress-overview',
    );

    expect(candidate.id, 'm5-weak-domain-d03-v1');
    expect(candidate.state, LearningTwinState.remediate);
    expect(candidate.trigger, LearningTwinTrigger.remediationOpportunity);
    expect(candidate.priority, 90);
    expect(candidate.screenId, 'progress-overview');

    // d03 is the recommendation target, not an automatic context constraint.
    expect(candidate.domainId, isNull);
    expect(candidate.action?.type, LearningTwinActionType.openContent);
    expect(candidate.action?.targetId, 'd03');
    expect(candidate.unsolicited, isTrue);
    expect(candidate.allowRepeat, isFalse);
  });

  test('explicit scope domain constrains candidate context independently', () {
    const insight = LearningTwinProgressInsight(
      type: LearningTwinProgressInsightType.continueLearning,
      priority: 60,
      title: 'Continue Domain 04',
      body: 'Continue the active learning path.',
      domainId: 'd04',
      domainNumber: 4,
    );

    final candidate = bridge.toCandidate(
      insight: insight,
      screenId: 'domain-overview',
      scopeDomainId: 'd04',
    );

    expect(candidate.domainId, 'd04');
    expect(candidate.action?.targetId, 'd04');
    expect(candidate.action?.type, LearningTwinActionType.continueLearning);
  });

  test('mastery insight becomes a celebration without navigation action', () {
    const insight = LearningTwinProgressInsight(
      type: LearningTwinProgressInsightType.masteryAcknowledgement,
      priority: 100,
      title: 'Strong progress pattern',
      body: 'Keep consolidating weaker areas.',
    );

    final candidate = bridge.toCandidate(
      insight: insight,
      screenId: 'progress-overview',
    );

    expect(candidate.id, 'm5-mastery-global-v1');
    expect(candidate.state, LearningTwinState.celebrate);
    expect(candidate.trigger, LearningTwinTrigger.milestoneReached);
    expect(candidate.action, isNull);
  });

  test('global add-practice insight does not invent a navigation target', () {
    const insight = LearningTwinProgressInsight(
      type: LearningTwinProgressInsightType.addPractice,
      priority: 80,
      title: 'Add retrieval practice',
      body: 'Use a short practice set.',
    );

    final candidate = bridge.toCandidate(
      insight: insight,
      screenId: 'progress-overview',
    );

    expect(candidate.id, 'm5-add-practice-global-v1');
    expect(candidate.state, LearningTwinState.recommend);
    expect(candidate.trigger, LearningTwinTrigger.recommendationAvailable);
    expect(candidate.action, isNull);
  });

  test('bridge candidate still requires M3 decision approval', () {
    const insight = LearningTwinProgressInsight(
      type: LearningTwinProgressInsightType.weakDomainRemediation,
      priority: 90,
      title: 'Revisit Domain 03',
      body: 'Review the learning material.',
      domainId: 'd03',
      domainNumber: 3,
    );

    final candidate = bridge.toCandidate(
      insight: insight,
      screenId: 'progress-overview',
    );

    const context = LearningTwinContext(
      screenId: 'progress-overview',
      visitId: 'visit-1',
      trigger: LearningTwinTrigger.remediationOpportunity,
    );

    final decision = const DeterministicLearningTwinDecisionService().decide(
      context: context,
      candidates: [candidate],
      sessionState: LearningTwinSessionState.empty(),
    );

    expect(decision.reason, LearningTwinDecisionReason.selected);
    expect(decision.message?.id, candidate.id);
  });

  test('timed exam suppression still wins after M5 bridge conversion', () {
    const insight = LearningTwinProgressInsight(
      type: LearningTwinProgressInsightType.continueLearning,
      priority: 60,
      title: 'Continue learning',
      body: 'Continue the learning path.',
    );

    final candidate = bridge.toCandidate(
      insight: insight,
      screenId: 'progress-overview',
    );

    const context = LearningTwinContext(
      screenId: 'progress-overview',
      visitId: 'visit-exam',
      trigger: LearningTwinTrigger.recommendationAvailable,
      isTimedExamActive: true,
    );

    final decision = const DeterministicLearningTwinDecisionService().decide(
      context: context,
      candidates: [candidate],
      sessionState: LearningTwinSessionState.empty(),
    );

    expect(decision.reason, LearningTwinDecisionReason.timedExamActive);
    expect(decision.hasMessage, isFalse);
  });

  test('empty screen id is rejected', () {
    const insight = LearningTwinProgressInsight(
      type: LearningTwinProgressInsightType.startLearning,
      priority: 40,
      title: 'Start with one domain',
      body: 'Choose one domain.',
    );

    expect(
      () => bridge.toCandidate(insight: insight, screenId: '  '),
      throwsArgumentError,
    );
  });
}
