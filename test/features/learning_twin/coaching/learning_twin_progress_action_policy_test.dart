import 'package:exam_platform/features/learning_twin/coaching/learning_twin_progress_action_policy.dart';
import 'package:exam_platform/features/learning_twin/domain/learning_twin_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const policy = LearningTwinProgressActionPolicy();

  test('open-content Domain action is allowed', () {
    const message = LearningTwinMessage(
      id: 'm5-weak-domain-d03-v1',
      state: LearningTwinState.remediate,
      trigger: LearningTwinTrigger.remediationOpportunity,
      body: 'Review Risk Management.',
      action: LearningTwinAction(
        id: 'm5-review-d03-v1',
        label: 'Review domain',
        type: LearningTwinActionType.openContent,
        targetId: 'd03',
      ),
    );

    final binding = policy.resolve(message);

    expect(binding?.targetDomainId, 'd03');
    expect(binding?.label, 'Review domain');
  });

  test('continue-learning Domain action is allowed', () {
    const message = LearningTwinMessage(
      id: 'm5-continue-learning-d04-v1',
      state: LearningTwinState.recommend,
      trigger: LearningTwinTrigger.recommendationAvailable,
      body: 'Continue Domain 04.',
      action: LearningTwinAction(
        id: 'm5-continue-d04-v1',
        label: 'Continue learning',
        type: LearningTwinActionType.continueLearning,
        targetId: 'd04',
      ),
    );

    final binding = policy.resolve(message);

    expect(binding?.targetDomainId, 'd04');
    expect(binding?.label, 'Continue learning');
  });

  test('missing target fails closed', () {
    const message = LearningTwinMessage(
      id: 'm5-no-target-v1',
      state: LearningTwinState.recommend,
      trigger: LearningTwinTrigger.recommendationAvailable,
      body: 'Keep learning.',
      action: LearningTwinAction(
        id: 'm5-no-target-action-v1',
        label: 'Continue',
        type: LearningTwinActionType.continueLearning,
      ),
    );

    expect(policy.resolve(message), isNull);
  });

  test('unsupported action type fails closed', () {
    const message = LearningTwinMessage(
      id: 'm5-practice-d03-v1',
      state: LearningTwinState.recommend,
      trigger: LearningTwinTrigger.recommendationAvailable,
      body: 'Practice Domain 03.',
      action: LearningTwinAction(
        id: 'm5-practice-action-d03-v1',
        label: 'Start practice',
        type: LearningTwinActionType.startPractice,
        targetId: 'd03',
      ),
    );

    expect(policy.resolve(message), isNull);
  });
}
