import 'package:exam_platform/features/learning_twin/domain/learning_twin_state.dart';
import 'package:exam_platform/features/learning_twin/ui/learning_twin_motion_mapper.dart';
import 'package:exam_platform/features/learning_twin/ui/learning_twin_motion_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps every LearningTwinState using the frozen LTAM-4 contract', () {
    final expected = <LearningTwinState, LearningTwinMotionState>{
      LearningTwinState.idle: LearningTwinMotionState.idle,
      LearningTwinState.welcome: LearningTwinMotionState.welcome,
      LearningTwinState.explain: LearningTwinMotionState.explain,
      LearningTwinState.tip: LearningTwinMotionState.insightReady,
      LearningTwinState.important: LearningTwinMotionState.focus,
      LearningTwinState.warning: LearningTwinMotionState.focus,
      LearningTwinState.encourage: LearningTwinMotionState.encourage,
      LearningTwinState.celebrate: LearningTwinMotionState.celebrate,
      LearningTwinState.remediate: LearningTwinMotionState.focus,
      LearningTwinState.recommend: LearningTwinMotionState.insightReady,
      LearningTwinState.checkpoint: LearningTwinMotionState.checkpoint,
      LearningTwinState.examReady: LearningTwinMotionState.examReady,
      LearningTwinState.resultReview: LearningTwinMotionState.resultReview,
    };

    expect(expected.length, LearningTwinState.values.length);

    for (final state in LearningTwinState.values) {
      expect(
        LearningTwinMotionMapper.map(state),
        expected[state],
        reason: 'Unexpected LTAM-4 motion mapping for ${state.name}.',
      );
    }
  });

  test('reduced motion is presentation-only', () {
    expect(
      canonicalLearningTwinMotionStates,
      isNot(contains(LearningTwinMotionState.reducedMotion)),
    );
  });
}
