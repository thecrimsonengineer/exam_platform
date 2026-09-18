import 'package:exam_platform/features/exam_readiness/models/competency_readiness_profile.dart';
import 'package:exam_platform/features/exam_readiness/models/evidence_confidence.dart';
import 'package:exam_platform/features/exam_readiness/models/learning_priority_score.dart';
import 'package:exam_platform/features/exam_readiness/models/readiness_gap.dart';
import 'package:exam_platform/models/question.dart';
import 'package:exam_platform/services/ultra_hard_question_contract.dart';

CompetencyReadinessProfile m7dProfile({
  String competencyId = 'd03_c02',
  EvidenceConfidence evidenceConfidence = EvidenceConfidence.high,
  ReadinessState readinessState = ReadinessState.developing,
  double? knowledge = 0.70,
  double? application = 0.62,
  double? retention = 0.72,
  double? coverage = 0.75,
  double? difficulty = 0.62,
  double? calibration = 0.80,
  double? recentPerformance = 0.68,
  double? stability = 0.72,
  double? standardAccuracy = 0.80,
  double? hardAccuracy = 0.65,
  double? ultraHardAccuracy = 0.55,
  List<ReadinessGap> gaps = const <ReadinessGap>[],
  DateTime? generatedAt,
}) {
  ReadinessDimension dimension(String code, double? value) =>
      ReadinessDimension(
        code: code,
        value: value,
        evidenceConfidence: evidenceConfidence,
      );

  final difficultyState = difficulty == null
      ? DifficultyReadinessState.unavailable
      : difficulty >= 0.75
      ? DifficultyReadinessState.strong
      : difficulty >= 0.55
      ? DifficultyReadinessState.developing
      : DifficultyReadinessState.emerging;

  return CompetencyReadinessProfile(
    competencyId: competencyId,
    generatedAt: generatedAt ?? DateTime(2026, 9, 18, 12),
    readinessAlgorithmVersion:
        CompetencyReadinessProfile.currentAlgorithmVersion,
    knowledgeMastery: dimension('KNOWLEDGE', knowledge),
    applicationAbility: dimension('APPLICATION', application),
    retention: dimension('RETENTION', retention),
    difficultyPerformance: DifficultyReadinessProfile(
      standardAccuracy: standardAccuracy,
      hardAccuracy: hardAccuracy,
      ultraHardAccuracy: ultraHardAccuracy,
      dimension: dimension('DIFFICULTY', difficulty),
      state: difficultyState,
    ),
    blueprintCoverage: dimension('COVERAGE', coverage),
    confidenceCalibration: dimension('CONFIDENCE', calibration),
    recentPerformance: dimension('RECENT', recentPerformance),
    stability: dimension('STABILITY', stability),
    evidenceConfidence: evidenceConfidence,
    readinessState: readinessState,
    gaps: gaps,
    limitingFactors: gaps
        .where(
          (gap) =>
              gap.severity == ReadinessGapSeverity.high ||
              gap.severity == ReadinessGapSeverity.critical,
        )
        .map((gap) => gap.reasonCode)
        .toList(growable: false),
    explanationCodes: gaps.map((gap) => gap.reasonCode).toList(growable: false),
  );
}

ReadinessGap m7dGap({
  ReadinessGapType type = ReadinessGapType.applicationGap,
  ReadinessGapSeverity severity = ReadinessGapSeverity.high,
  String competencyId = 'd03_c02',
  String reasonCode = 'APPLICATION_GAP',
  String explanation = 'Application evidence is weak.',
  bool evidenceLimited = false,
}) {
  return ReadinessGap(
    type: type,
    severity: severity,
    competencyId: competencyId,
    reasonCode: reasonCode,
    explanation: explanation,
    evidenceLimited: evidenceLimited,
  );
}

Question m7dQuestion({
  int id = 1,
  String competencyId = 'd03_c02',
  bool ultraHard = true,
  String status = 'published',
}) {
  return Question(
    id: id,
    domain: 3,
    competencyId: competencyId,
    subtopicId: 'd03_c02_t01_s01',
    topicId: 'd03_c02_t01',
    quizId: 'd03_c02_t01_s01_quiz',
    contentPackageId: 'pkg',
    question: 'A scenario question?',
    options: const ['A', 'B', 'C', 'D'],
    correctAnswer: 0,
    explanation: 'Explanation',
    reference: 'Reference',
    difficulty: 'Hard',
    cognitiveLevel: 'application',
    questionType: 'scenario_mcq',
    status: status,
    version: 1,
    tags: ultraHard
        ? const [UltraHardQuestionContract.classificationTag]
        : const ['standard-bank'],
  );
}

LearningPriorityScore m7dPriority({
  String competencyId = 'd03_c02',
  double totalScore = 0.75,
}) {
  return LearningPriorityScore(
    competencyId: competencyId,
    blueprintImportance: 0.6,
    masteryGap: 0.3,
    applicationGap: 0.4,
    retentionRisk: 0.2,
    coverageGap: 0.25,
    evidenceDebt: 0.4,
    staleness: 0,
    difficultyWeakness: 0.35,
    examProximity: 0.5,
    prerequisiteImportance: 0,
    recentStudyPenalty: 0,
    evidenceDebtLevel: EvidenceDebtLevel.low,
    totalScore: totalScore,
    reasonCodes: const ['HIGH_BLUEPRINT_PRIORITY'],
  );
}
