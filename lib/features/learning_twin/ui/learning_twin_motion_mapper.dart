import '../domain/learning_twin_state.dart';
import 'learning_twin_motion_state.dart';

abstract final class LearningTwinMotionMapper {
  static LearningTwinMotionState map(LearningTwinState state) {
    return switch (state) {
      LearningTwinState.idle => LearningTwinMotionState.idle,
      LearningTwinState.welcome => LearningTwinMotionState.welcome,
      LearningTwinState.explain => LearningTwinMotionState.explain,
      LearningTwinState.tip => LearningTwinMotionState.insightReady,
      LearningTwinState.important => LearningTwinMotionState.focus,
      LearningTwinState.warning => LearningTwinMotionState.focus,
      LearningTwinState.encourage => LearningTwinMotionState.encourage,
      LearningTwinState.celebrate => LearningTwinMotionState.celebrate,
      LearningTwinState.remediate => LearningTwinMotionState.focus,
      LearningTwinState.recommend => LearningTwinMotionState.insightReady,
      LearningTwinState.checkpoint => LearningTwinMotionState.checkpoint,
      LearningTwinState.examReady => LearningTwinMotionState.examReady,
      LearningTwinState.resultReview => LearningTwinMotionState.resultReview,
    };
  }
}
