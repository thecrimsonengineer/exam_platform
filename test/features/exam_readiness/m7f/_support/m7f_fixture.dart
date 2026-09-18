import 'package:exam_platform/features/exam_readiness/models/competency_readiness_profile.dart';
import 'package:exam_platform/features/exam_readiness/models/evidence_confidence.dart';
import 'package:exam_platform/features/exam_readiness/models/study_capacity_snapshot.dart';

import '../../m7d/_support/m7d_fixture.dart';

StudyCapacitySnapshot m7fCapacity({
  int minutes = 600,
  int daysRemaining = 30,
}) {
  return StudyCapacitySnapshot(
    generatedAt: DateTime(2026, 9, 18, 8),
    examDate: DateTime(2026, 9, 18).add(Duration(days: daysRemaining)),
    calendarDaysRemaining: daysRemaining,
    plannedStudyDaysRemaining: daysRemaining > 0 ? 20 : 0,
    plannedMinutesRemaining: minutes,
    studyDaysThisWeek: 5,
    minutesThisWeek: 300,
    averageMinutesPerStudyDay: 60,
    weeksRemaining: daysRemaining / 7,
    examTimeHorizon: ExamTimeHorizon.nearTerm,
    schemaVersion: StudyCapacitySnapshot.currentSchemaVersion,
  );
}

ExamReadinessDashboard m7fDashboard({
  EvidenceConfidence evidenceConfidence = EvidenceConfidence.high,
  double? knowledge = 0.80,
  double? application = 0.80,
  double? retention = 0.80,
  double? difficulty = 0.80,
  double? calibration = 0.80,
  double? recentPerformance = 0.80,
  int competenciesTotal = 10,
  int competenciesAssessed = 8,
  Map<String, CompetencyReadinessProfile>? profiles,
}) {
  ReadinessDimension dimension(String code, double? value) {
    return ReadinessDimension(
      code: code,
      value: value,
      evidenceConfidence: evidenceConfidence,
    );
  }

  final resolvedProfiles =
      profiles ??
      <String, CompetencyReadinessProfile>{
        'd01_c01': m7dProfile(
          competencyId: 'd01_c01',
          evidenceConfidence: evidenceConfidence,
          knowledge: knowledge,
          application: application,
          retention: retention,
          difficulty: difficulty,
          calibration: calibration,
          recentPerformance: recentPerformance,
        ),
      };

  return ExamReadinessDashboard(
    generatedAt: DateTime(2026, 9, 18, 12),
    algorithmVersion: 'm7c-v1',
    evidenceConfidence: evidenceConfidence,
    knowledgeMastery: dimension('KNOWLEDGE', knowledge),
    applicationAbility: dimension('APPLICATION', application),
    retention: dimension('RETENTION', retention),
    blueprintCoverage: BlueprintCoverageSummary(
      competenciesTotal: competenciesTotal,
      competenciesAssessed: competenciesAssessed,
      topicsTotal: competenciesTotal,
      topicsAssessed: competenciesAssessed,
      subtopicsTotal: competenciesTotal,
      subtopicsAssessed: competenciesAssessed,
    ),
    difficultyPerformance: dimension('DIFFICULTY', difficulty),
    confidenceCalibration: dimension('CONFIDENCE', calibration),
    criticalGapCount: 0,
    weakCompetencyCount: 0,
    evidenceGapCount: 0,
    staleCompetencyCount: 0,
    profiles: resolvedProfiles,
    domainCoverage: const <String, BlueprintCoverageSummary>{},
  );
}
