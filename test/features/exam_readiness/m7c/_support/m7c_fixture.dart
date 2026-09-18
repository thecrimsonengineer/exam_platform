import 'package:exam_platform/features/exam_readiness/models/competency_evidence_snapshot.dart';
import 'package:exam_platform/features/exam_readiness/models/evidence_confidence.dart';
import 'package:exam_platform/features/exam_readiness/models/learner_assessment_attempt.dart';

CompetencyEvidenceSnapshot m7cEvidence({
  String competencyId = 'd03_c02',
  int totalAttempts = 12,
  int correct = 9,
  int uniqueQuestions = 10,
  int topicsAvailable = 4,
  int topicsAssessed = 3,
  int subtopicsAvailable = 8,
  int subtopicsAssessed = 6,
  int recallAttempts = 2,
  int recallCorrect = 2,
  int applicationAttempts = 6,
  int applicationCorrect = 4,
  int analysisAttempts = 4,
  int analysisCorrect = 3,
  int standardAttempts = 4,
  int standardCorrect = 4,
  int hardAttempts = 4,
  int hardCorrect = 3,
  int ultraHardAttempts = 4,
  int ultraHardCorrect = 2,
  int delayedAttempts = 4,
  int delayedCorrect = 3,
  int confidenceSamples = 5,
  double? calibrationError = 0.15,
  int highConfidenceIncorrectCount = 0,
  int attempts7d = 6,
  int attempts30d = 10,
  EvidenceRecencyBand recencyBand = EvidenceRecencyBand.recent,
  EvidenceConfidence overallConfidence = EvidenceConfidence.high,
  EvidenceConfidence quantity = EvidenceConfidence.high,
  EvidenceConfidence breadth = EvidenceConfidence.high,
  EvidenceConfidence recency = EvidenceConfidence.high,
  EvidenceConfidence difficulty = EvidenceConfidence.veryHigh,
  EvidenceConfidence retention = EvidenceConfidence.moderate,
  EvidenceConfidence diversity = EvidenceConfidence.veryHigh,
  EvidenceState evidenceState = EvidenceState.robust,
  double repeatedAttemptConcentration = 0.10,
  DateTime? generatedAt,
}) {
  return CompetencyEvidenceSnapshot(
    competencyId: competencyId,
    generatedAt: generatedAt ?? DateTime(2026, 9, 18, 12),
    schemaVersion: CompetencyEvidenceSnapshot.currentSchemaVersion,
    algorithmVersion: CompetencyEvidenceSnapshot.currentAlgorithmVersion,
    sourceAttemptCount: totalAttempts,
    coverage: EvidenceCoverage(
      topicsAvailable: topicsAvailable,
      topicsAssessed: topicsAssessed,
      subtopicsAvailable: subtopicsAvailable,
      subtopicsAssessed: subtopicsAssessed,
    ),
    attempts: AttemptEvidenceStats(
      total: totalAttempts,
      correct: correct,
      incorrect: totalAttempts - correct,
      uniqueQuestions: uniqueQuestions,
      repeatedAttempts: totalAttempts - uniqueQuestions,
    ),
    cognition: CognitionEvidenceStats(
      recallAttempts: recallAttempts,
      recallCorrect: recallCorrect,
      applicationAttempts: applicationAttempts,
      applicationCorrect: applicationCorrect,
      analysisAttempts: analysisAttempts,
      analysisCorrect: analysisCorrect,
    ),
    difficulty: DifficultyEvidenceStats(
      standardAttempts: standardAttempts,
      standardCorrect: standardCorrect,
      hardAttempts: hardAttempts,
      hardCorrect: hardCorrect,
      ultraHardAttempts: ultraHardAttempts,
      ultraHardCorrect: ultraHardCorrect,
    ),
    retention: RetentionEvidenceStats(
      delayedAttempts: delayedAttempts,
      delayedCorrect: delayedCorrect,
      immediateAttempts: 1,
      shortDelayAttempts: delayedAttempts > 0 ? 1 : 0,
      mediumDelayAttempts: delayedAttempts > 1 ? delayedAttempts - 1 : 0,
      longDelayAttempts: 0,
      lastReviewedAt: DateTime(2026, 9, 17),
      daysSinceReview: 1,
    ),
    confidence: ConfidenceCalibrationStats(
      confidenceSamples: confidenceSamples,
      calibrationError: calibrationError,
      overconfidenceRate: confidenceSamples == 0 ? null : 0.1,
      underconfidenceRate: confidenceSamples == 0 ? null : 0.1,
      highConfidenceIncorrectCount: highConfidenceIncorrectCount,
    ),
    recency: RecencyEvidenceStats(
      attempts7d: attempts7d,
      attempts30d: attempts30d,
      lastAttemptAt: DateTime(2026, 9, 17),
      band: recencyBand,
    ),
    evidenceQuality: EvidenceQualitySnapshot(
      quantity: quantity,
      breadth: breadth,
      recency: recency,
      diversity: diversity,
      confidenceLevel: overallConfidence,
      breakdown: EvidenceConfidenceBreakdown(
        quantity: quantity,
        breadth: breadth,
        recency: recency,
        difficulty: difficulty,
        retention: retention,
        diversity: diversity,
        overall: overallConfidence,
        repeatedAttemptConcentration: repeatedAttemptConcentration,
      ),
      state: evidenceState,
    ),
    traceability: const ['fixture evidence'],
  );
}

List<LearnerAssessmentAttempt> m7cAttempts({
  String competencyId = 'd03_c02',
  int count = 10,
  DateTime? endAt,
  int correctEvery = 2,
}) {
  final end = endAt ?? DateTime(2026, 9, 18, 10);
  return [
    for (var i = 0; i < count; i++)
      LearnerAssessmentAttempt(
        attemptId: 'm7c-${competencyId}-${i}',
        questionId: i + 1,
        domainNumber: 3,
        competencyId: competencyId,
        topicId: 't${(i % 4) + 1}',
        subtopicId: 's${(i % 8) + 1}',
        correct: correctEvery <= 1 ? true : i % correctEvery != 0,
        answeredAt: end.subtract(Duration(days: count - i - 1)),
        cognitiveLevel: i.isEven ? 'application' : 'analysis',
        questionType: 'scenario_mcq',
        difficultyLane: i % 3 == 0
            ? AttemptDifficultyLane.ultraHard
            : i.isEven
            ? AttemptDifficultyLane.hard
            : AttemptDifficultyLane.standard,
        publishedAtAttempt: true,
        questionVersion: 1,
        sessionKind: 'practice',
      ),
  ];
}
