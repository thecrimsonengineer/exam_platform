import 'package:exam_platform/features/exam_readiness/models/daily_study_plan.dart';
import 'package:exam_platform/features/exam_readiness/models/learner_assessment_attempt.dart';
import 'package:exam_platform/features/exam_readiness/models/study_plan_block.dart';
import 'package:exam_platform/features/exam_readiness/models/study_plan_block_outcome.dart';

import '../../m7d/_support/m7d_fixture.dart';

LearnerAssessmentAttempt m7eAttempt({
  String attemptId = 'a1',
  int questionId = 1,
  String competencyId = 'd03_c02',
  bool correct = true,
  DateTime? answeredAt,
  String cognitiveLevel = 'application',
  AttemptDifficultyLane difficultyLane = AttemptDifficultyLane.hard,
  LearnerConfidenceLevel? confidence,
}) {
  return LearnerAssessmentAttempt(
    attemptId: attemptId,
    questionId: questionId,
    domainNumber: 3,
    competencyId: competencyId,
    topicId: '${competencyId}_t01',
    subtopicId: '${competencyId}_t01_s01',
    correct: correct,
    answeredAt: answeredAt ?? DateTime(2026, 9, 18, 10),
    cognitiveLevel: cognitiveLevel,
    questionType: 'scenario_mcq',
    difficultyLane: difficultyLane,
    publishedAtAttempt: true,
    questionVersion: 1,
    sessionKind: 'practice',
    confidence: confidence,
  );
}

StudyPlanBlockOutcome m7eOutcome({
  String outcomeId = 'outcome-1',
  String planId = 'plan-1',
  int planVersion = 1,
  String blockId = 'block-1',
  String competencyId = 'd03_c02',
  DateTime? completedAt,
  int minutesSpent = 20,
  int questionsAttempted = 5,
  int questionsCorrect = 3,
  double? applicationAccuracy = 0.6,
  double? analysisAccuracy,
  double? ultraHardAccuracy,
  int confidenceSamples = 0,
  bool contentCompleted = false,
  int? learnerRating,
  bool abandoned = false,
}) {
  return StudyPlanBlockOutcome(
    outcomeId: outcomeId,
    planId: planId,
    planVersion: planVersion,
    blockId: blockId,
    competencyId: competencyId,
    completedAt: completedAt ?? DateTime(2026, 9, 18, 11),
    minutesSpent: minutesSpent,
    questionsAttempted: questionsAttempted,
    questionsCorrect: questionsCorrect,
    applicationAccuracy: applicationAccuracy,
    analysisAccuracy: analysisAccuracy,
    ultraHardAccuracy: ultraHardAccuracy,
    confidenceSamples: confidenceSamples,
    contentCompleted: contentCompleted,
    learnerRating: learnerRating,
    abandoned: abandoned,
  );
}

StudyPlanBlock m7eBlock({
  String blockId = 'block-1',
  String competencyId = 'd03_c02',
  StudyPlanBlockType type = StudyPlanBlockType.standardPractice,
  int minutes = 20,
  StudyPlanBlockStatus status = StudyPlanBlockStatus.planned,
  DateTime? createdAt,
}) {
  return StudyPlanBlock(
    blockId: blockId,
    type: type,
    domainId: 'd03',
    competencyId: competencyId,
    subtopicId: '${competencyId}_t01_s01',
    topicId: '${competencyId}_t01',
    plannedMinutes: minutes,
    questionCount: 5,
    priorityScore: 0.75,
    priorityBreakdown: m7dPriority(
      competencyId: competencyId,
      totalScore: 0.75,
    ),
    reasonCodes: const ['TEST_PRIORITY'],
    reasonText: 'Fixture priority reason.',
    status: status,
    createdAt: createdAt ?? DateTime(2026, 9, 18, 8),
    manualChanges: const [],
  );
}

DailyStudyPlan m7ePlan({
  String planId = 'plan-1',
  DateTime? date,
  int version = 1,
  DailyStudyPlanStatus status = DailyStudyPlanStatus.active,
  DailyStudyPlanGenerationReason reason =
      DailyStudyPlanGenerationReason.initial,
  int availableMinutes = 60,
  List<StudyPlanBlock>? blocks,
  String? previousPlanId,
}) {
  final values = blocks ?? [m7eBlock()];
  return DailyStudyPlan(
    planId: planId,
    userId: 'u1',
    date: date ?? DateTime(2026, 9, 19),
    generatedAt: DateTime(2026, 9, 18, 8),
    planVersion: version,
    plannerAlgorithmVersion: DailyStudyPlan.currentAlgorithmVersion,
    availableMinutes: availableMinutes,
    allocatedMinutes: values.fold(
      0,
      (sum, block) => sum + block.plannedMinutes,
    ),
    generationReason: reason,
    sourceEvidenceVersion: 'e1',
    sourceReadinessVersion: 'r1',
    inputSnapshotVersion: 'e:e1|r:r1',
    previousPlanId: previousPlanId,
    blocks: values,
    status: status,
    schemaVersion: DailyStudyPlan.currentSchemaVersion,
  );
}
