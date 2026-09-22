import '../models/study_plan_block.dart';

enum TodayPlanTaskCategory { learn, practice, remember }

class TodayPlanTaskCategoryPolicy {
  const TodayPlanTaskCategoryPolicy();

  static const Set<String> _reviewRecoveryReasonCodes = <String>{
    'RETENTION_DUE',
  };

  TodayPlanTaskCategory categoryFor(StudyPlanBlock block) {
    switch (block.type) {
      case StudyPlanBlockType.learn:
      case StudyPlanBlockType.continueLearning:
      case StudyPlanBlockType.repair:
        return TodayPlanTaskCategory.learn;

      case StudyPlanBlockType.diagnostic:
      case StudyPlanBlockType.standardPractice:
      case StudyPlanBlockType.ultraHardPractice:
      case StudyPlanBlockType.mixedRetrieval:
      case StudyPlanBlockType.competencyRecheck:
      case StudyPlanBlockType.confidenceCalibration:
      case StudyPlanBlockType.examSimulation:
        return TodayPlanTaskCategory.practice;

      case StudyPlanBlockType.spacedReview:
        return TodayPlanTaskCategory.remember;

      case StudyPlanBlockType.recovery:
        return _categoryForRecovery(block);
    }
  }

  TodayPlanTaskCategory _categoryForRecovery(StudyPlanBlock block) {
    final reasons = block.reasonCodes
        .map((reason) => reason.trim().toUpperCase())
        .toSet();

    if (reasons.any(_reviewRecoveryReasonCodes.contains)) {
      return TodayPlanTaskCategory.remember;
    }

    throw StateError(
      'Recovery study-plan block ${block.blockId} cannot be categorized '
      'safely without an explicit review-oriented reason.',
    );
  }
}
