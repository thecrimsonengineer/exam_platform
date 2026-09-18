import 'capacity_pressure_snapshot.dart';
import 'coverage_projection.dart';
import 'evidence_confidence.dart';
import 'exam_preparation_phase.dart';
import 'readiness_checkpoint.dart';
import 'readiness_index_snapshot.dart';
import 'readiness_trajectory_point.dart';
import 'recovery_protection_snapshot.dart';

class AdvancedReadinessSnapshot {
  const AdvancedReadinessSnapshot({
    required this.generatedAt,
    required this.daysUntilExam,
    required this.phase,
    required this.capacityPressure,
    required this.readinessIndex,
    required this.trajectory,
    required this.coverageProjection,
    required this.nextCheckpoint,
    required this.recoveryProtection,
    required this.evidenceConfidence,
    required this.strongCompetencies,
    required this.developingCompetencies,
    required this.criticalGaps,
    required this.insufficientEvidenceCompetencies,
    required this.todayPlanMinutes,
    required this.todayBlockCount,
    required this.planChangeExplanation,
    required this.reasonCodes,
    required this.algorithmVersion,
  });

  final DateTime generatedAt;
  final int daysUntilExam;
  final ExamPreparationPhase phase;
  final CapacityPressureSnapshot capacityPressure;
  final ReadinessIndexSnapshot readinessIndex;
  final ReadinessTrajectorySummary trajectory;
  final CoverageProjection coverageProjection;
  final ReadinessCheckpoint? nextCheckpoint;
  final RecoveryProtectionSnapshot recoveryProtection;
  final EvidenceConfidence evidenceConfidence;
  final int strongCompetencies;
  final int developingCompetencies;
  final int criticalGaps;
  final int insufficientEvidenceCompetencies;
  final int todayPlanMinutes;
  final int todayBlockCount;
  final String? planChangeExplanation;
  final List<String> reasonCodes;
  final String algorithmVersion;
}
