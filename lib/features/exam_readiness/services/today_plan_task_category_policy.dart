import '../models/study_plan_block.dart';
import '../models/today_plan_task_category.dart';

class TodayPlanTaskCategoryPolicy {
  const TodayPlanTaskCategoryPolicy();

  static const Set<String> _reviewRecoveryReasonCodes = <String>{
    'RETENTION_DUE',
  };

  static const Set<String> _practiceRepairReasonCodes = <String>{
    'APPLICATION_GAP',
    'KNOWLEDGE_MASTERY_GAP',
    'DIFFICULTY_PERFORMANCE_GAP',
  };

  TodayPlanTaskCategory categoryFor(StudyPlanBlock block) {
    switch (block.type) {
      case StudyPlanBlockType.learn:
      case StudyPlanBlockType.continueLearning:
        return TodayPlanTaskCategory.learn;

      case StudyPlanBlockType.repair:
        return _isPracticeRepair(block)
            ? TodayPlanTaskCategory.practice
            : TodayPlanTaskCategory.learn;

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

  bool _isPracticeRepair(StudyPlanBlock block) {
    final reasons = block.reasonCodes
        .map((reason) => reason.trim().toUpperCase())
        .toSet();
    return reasons.any(_practiceRepairReasonCodes.contains);
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
