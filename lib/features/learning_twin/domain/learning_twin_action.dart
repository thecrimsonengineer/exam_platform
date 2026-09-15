enum LearningTwinActionType {
  none,
  dismiss,
  openContent,
  startPractice,
  reviewResults,
  continueLearning,
  retryPractice,
  viewRecommendation,
}

final class LearningTwinAction {
  const LearningTwinAction({
    required this.id,
    required this.label,
    required this.type,
    this.targetId,
  }) : assert(id != ''),
       assert(label != '');

  final String id;
  final String label;
  final LearningTwinActionType type;
  final String? targetId;
}
