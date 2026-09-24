enum LearningTwinMotionState {
  idle,
  welcome,
  thinking,
  explain,
  insightReady,
  focus,
  encourage,
  celebrate,
  checkpoint,
  examReady,
  resultReview,
  reducedMotion,
}

const canonicalLearningTwinMotionStates = <LearningTwinMotionState>[
  LearningTwinMotionState.idle,
  LearningTwinMotionState.welcome,
  LearningTwinMotionState.thinking,
  LearningTwinMotionState.explain,
  LearningTwinMotionState.insightReady,
  LearningTwinMotionState.focus,
  LearningTwinMotionState.encourage,
  LearningTwinMotionState.celebrate,
  LearningTwinMotionState.checkpoint,
  LearningTwinMotionState.examReady,
  LearningTwinMotionState.resultReview,
];

LearningTwinMotionState? learningTwinMotionStateFromManifestKey(String value) {
  for (final state in canonicalLearningTwinMotionStates) {
    if (state.manifestKey == value) {
      return state;
    }
  }
  return null;
}

extension LearningTwinMotionStateX on LearningTwinMotionState {
  String get manifestKey => switch (this) {
    LearningTwinMotionState.idle => 'idle',
    LearningTwinMotionState.welcome => 'welcome',
    LearningTwinMotionState.thinking => 'thinking',
    LearningTwinMotionState.explain => 'explain',
    LearningTwinMotionState.insightReady => 'insight_ready',
    LearningTwinMotionState.focus => 'focus',
    LearningTwinMotionState.encourage => 'encourage',
    LearningTwinMotionState.celebrate => 'celebrate',
    LearningTwinMotionState.checkpoint => 'checkpoint',
    LearningTwinMotionState.examReady => 'exam_ready',
    LearningTwinMotionState.resultReview => 'result_review',
    LearningTwinMotionState.reducedMotion => 'reduced_motion',
  };

  int get defaultPriority => switch (this) {
    LearningTwinMotionState.celebrate => 100,
    LearningTwinMotionState.checkpoint => 90,
    LearningTwinMotionState.examReady => 80,
    LearningTwinMotionState.resultReview => 70,
    LearningTwinMotionState.focus => 60,
    LearningTwinMotionState.insightReady => 50,
    LearningTwinMotionState.explain => 40,
    LearningTwinMotionState.encourage => 30,
    LearningTwinMotionState.welcome => 20,
    LearningTwinMotionState.thinking => 10,
    LearningTwinMotionState.idle || LearningTwinMotionState.reducedMotion => 0,
  };

  bool get isLooping => switch (this) {
    LearningTwinMotionState.idle || LearningTwinMotionState.thinking => true,
    _ => false,
  };

  bool get isManifestBacked => this != LearningTwinMotionState.reducedMotion;
}
