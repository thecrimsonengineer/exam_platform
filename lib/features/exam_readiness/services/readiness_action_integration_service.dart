import '../models/daily_study_plan.dart';
import '../models/readiness_intelligence_snapshot.dart';
import '../models/study_plan_block.dart';

class ReadinessActionBinding {
  const ReadinessActionBinding({
    required this.action,
    required this.block,
    required this.requiresReplan,
    required this.reasonCode,
  });

  final ReadinessNextAction? action;
  final StudyPlanBlock? block;
  final bool requiresReplan;
  final String reasonCode;

  bool get isActionable => action != null && block != null && !requiresReplan;
}

class ReadinessActionIntegrationService {
  const ReadinessActionIntegrationService();

  ReadinessActionBinding bind({
    required ReadinessIntelligenceSnapshot readiness,
    required DailyStudyPlan plan,
  }) {
    final action = readiness.nextBestAction;
    if (action == null) {
      return const ReadinessActionBinding(
        action: null,
        block: null,
        requiresReplan: false,
        reasonCode: 'ERDP7_NO_ACTION_REQUIRED',
      );
    }

    final candidates = plan.blocks
        .where((block) {
          if (!_isExecutable(block.status)) return false;
          final targetCompetency = action.competencyId.trim().toLowerCase();
          if (targetCompetency.isNotEmpty &&
              block.competencyId.trim().toLowerCase() != targetCompetency) {
            return false;
          }
          return _matches(action.kind, block);
        })
        .toList(growable: false);

    if (candidates.isEmpty) {
      return ReadinessActionBinding(
        action: action,
        block: null,
        requiresReplan: true,
        reasonCode: 'ERDP7_AUTHORITATIVE_PLAN_REPLAN_REQUIRED',
      );
    }

    final started = candidates.where(
      (block) => block.status == StudyPlanBlockStatus.started,
    );
    final block = started.isNotEmpty ? started.first : candidates.first;

    return ReadinessActionBinding(
      action: action,
      block: block,
      requiresReplan: false,
      reasonCode: block.status == StudyPlanBlockStatus.started
          ? 'ERDP7_RESUME_AUTHORITATIVE_PLAN_BLOCK'
          : 'ERDP7_USE_AUTHORITATIVE_PLAN_BLOCK',
    );
  }

  bool _isExecutable(StudyPlanBlockStatus status) =>
      status == StudyPlanBlockStatus.planned ||
      status == StudyPlanBlockStatus.shortened ||
      status == StudyPlanBlockStatus.started;

  bool _matches(ReadinessNextActionKind kind, StudyPlanBlock block) {
    final reasons = block.reasonCodes
        .map((reason) => reason.trim().toUpperCase())
        .toSet();
    final applicationRepair =
        block.type == StudyPlanBlockType.repair &&
        reasons.contains('APPLICATION_GAP');
    final practiceRepair =
        block.type == StudyPlanBlockType.repair &&
        (reasons.contains('KNOWLEDGE_MASTERY_GAP') ||
            reasons.contains('DIFFICULTY_PERFORMANCE_GAP'));

    return switch (kind) {
      ReadinessNextActionKind.diagnostic =>
        block.type == StudyPlanBlockType.diagnostic,
      ReadinessNextActionKind.targetedPractice =>
        block.type == StudyPlanBlockType.standardPractice ||
            block.type == StudyPlanBlockType.ultraHardPractice ||
            block.type == StudyPlanBlockType.mixedRetrieval ||
            block.type == StudyPlanBlockType.competencyRecheck ||
            practiceRepair,
      ReadinessNextActionKind.flashcardReview =>
        block.type == StudyPlanBlockType.spacedReview ||
            block.type == StudyPlanBlockType.recovery,
      ReadinessNextActionKind.studyReview =>
        block.type == StudyPlanBlockType.learn ||
            block.type == StudyPlanBlockType.continueLearning,
      ReadinessNextActionKind.lab => applicationRepair,
      ReadinessNextActionKind.confidenceCalibration =>
        block.type == StudyPlanBlockType.confidenceCalibration,
      ReadinessNextActionKind.simulation =>
        block.type == StudyPlanBlockType.examSimulation,
    };
  }
}
