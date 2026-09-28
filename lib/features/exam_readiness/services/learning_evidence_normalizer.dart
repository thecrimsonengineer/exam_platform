import '../models/learning_evidence_event.dart';
import '../models/study_plan_block.dart';
import '../models/study_plan_block_outcome.dart';

class LearningEvidenceNormalizer {
  const LearningEvidenceNormalizer();

  LearningEvidenceEvent fromStudyPlanOutcome({
    required StudyPlanBlock block,
    required StudyPlanBlockOutcome outcome,
  }) {
    outcome.validate();
    if (block.blockId != outcome.blockId ||
        block.competencyId.trim().toLowerCase() != outcome.competencyId) {
      throw StateError('Study-plan outcome does not match its source block.');
    }

    final sourceKind = _sourceKind(block: block, outcome: outcome);
    final strength = switch (sourceKind) {
      LearningEvidenceSourceKind.question => LearningEvidenceStrength.strong,
      LearningEvidenceSourceKind.flashcard =>
        LearningEvidenceStrength.supporting,
      LearningEvidenceSourceKind.lab => LearningEvidenceStrength.strong,
      LearningEvidenceSourceKind.study => LearningEvidenceStrength.context,
      LearningEvidenceSourceKind.simulation => LearningEvidenceStrength.strong,
      LearningEvidenceSourceKind.microLearning => LearningEvidenceStrength.none,
    };

    final overallAccuracy = outcome.overallAccuracy;
    final applicationScore =
        sourceKind == LearningEvidenceSourceKind.simulation ||
            sourceKind == LearningEvidenceSourceKind.lab
        ? outcome.applicationAccuracy ??
              outcome.analysisAccuracy ??
              overallAccuracy
        : null;

    final codes = <String>{
      'SOURCE_${sourceKind.name.toUpperCase()}',
      'STRENGTH_${strength.name.toUpperCase()}',
      if (outcome.abandoned) 'ACTIVITY_ABANDONED',
      if (outcome.questionsAttempted > 0 && outcome.questionsCorrect == 0)
        'QUESTION_MISS_SIGNAL',
      if (overallAccuracy != null && overallAccuracy < 0.60)
        'LOW_PERFORMANCE_SIGNAL',
      if (sourceKind == LearningEvidenceSourceKind.flashcard)
        'FLASHCARD_SUPPORT_REQUIRES_RECALL_QUALITY',
      if (sourceKind == LearningEvidenceSourceKind.study)
        'STUDY_COMPLETION_CONTEXT_ONLY',
    }.toList(growable: false)..sort();

    final event = LearningEvidenceEvent(
      evidenceEventId: 'erdp6-${outcome.outcomeId}',
      sourceOutcomeId: outcome.outcomeId,
      planId: outcome.planId,
      planVersion: outcome.planVersion,
      blockId: outcome.blockId,
      domainId: block.domainId,
      competencyId: outcome.competencyId,
      topicId: block.topicId,
      subtopicId: block.subtopicId,
      sourceKind: sourceKind,
      strength: strength,
      occurredAt: outcome.completedAt,
      questionsAttempted: outcome.questionsAttempted,
      questionsCorrect: outcome.questionsCorrect,
      confidenceSamples: outcome.confidenceSamples,
      contentCompleted: outcome.contentCompleted,
      abandoned: outcome.abandoned,
      performanceScore:
          sourceKind == LearningEvidenceSourceKind.question ||
              sourceKind == LearningEvidenceSourceKind.simulation
          ? overallAccuracy
          : null,
      applicationScore: applicationScore,
      retentionScore: null,
      signalCodes: codes,
    );
    event.validate();
    return event;
  }

  LearningEvidenceSourceKind _sourceKind({
    required StudyPlanBlock block,
    required StudyPlanBlockOutcome outcome,
  }) {
    if (block.type == StudyPlanBlockType.examSimulation) {
      return LearningEvidenceSourceKind.simulation;
    }
    if (block.type == StudyPlanBlockType.spacedReview) {
      return LearningEvidenceSourceKind.flashcard;
    }
    if (block.type == StudyPlanBlockType.repair &&
        outcome.applicationAccuracy != null &&
        block.reasonCodes.any(
          (reason) => reason.trim().toUpperCase() == 'APPLICATION_GAP',
        )) {
      return LearningEvidenceSourceKind.lab;
    }
    if (outcome.questionsAttempted > 0) {
      return LearningEvidenceSourceKind.question;
    }
    return LearningEvidenceSourceKind.study;
  }
}
