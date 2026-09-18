import '../../../data/csp11_blueprint.dart';
import '../models/advanced_readiness_snapshot.dart';
import '../models/competency_dependency.dart';
import '../models/competency_evidence_snapshot.dart';
import '../models/competency_readiness_profile.dart';
import '../models/daily_study_plan.dart';
import '../models/readiness_gap.dart';
import '../models/readiness_index_snapshot.dart';
import '../models/readiness_trajectory_point.dart';
import '../models/study_capacity_snapshot.dart';
import 'capacity_pressure_service.dart';
import 'coverage_projection_service.dart';
import 'exam_preparation_phase_service.dart';
import 'readiness_checkpoint_service.dart';
import 'readiness_index_service.dart';
import 'readiness_trajectory_service.dart';
import 'recovery_protection_service.dart';
import 'root_gap_reasoning_service.dart';

class AdvancedReadinessService {
  const AdvancedReadinessService({
    this.phaseService = const ExamPreparationPhaseService(),
    this.capacityPressureService = const CapacityPressureService(),
    this.trajectoryService = const ReadinessTrajectoryService(),
    this.indexService = const ReadinessIndexService(),
    this.checkpointService = const ReadinessCheckpointService(),
    this.coverageProjectionService = const CoverageProjectionService(),
    this.recoveryService = const RecoveryProtectionService(),
    this.rootGapService = const RootGapReasoningService(),
  });

  static const String currentAlgorithmVersion = 'm7f-advanced-readiness-v1';

  final ExamPreparationPhaseService phaseService;
  final CapacityPressureService capacityPressureService;
  final ReadinessTrajectoryService trajectoryService;
  final ReadinessIndexService indexService;
  final ReadinessCheckpointService checkpointService;
  final CoverageProjectionService coverageProjectionService;
  final RecoveryProtectionService recoveryService;
  final RootGapReasoningService rootGapService;

  AdvancedReadinessSnapshot build({
    required ExamReadinessDashboard dashboard,
    required Map<String, CompetencyEvidenceSnapshot> evidenceByCompetency,
    required StudyCapacitySnapshot capacity,
    required DateTime currentDate,
    required DateTime examDate,
    required Iterable<ReadinessTrajectoryPoint> trajectoryHistory,
    required Iterable<DailyStudyPlan> dailyPlanHistory,
    DailyStudyPlan? todayPlan,
    bool ultraHardAvailable = false,
    Iterable<CompetencyDependency> dependencies =
        const <CompetencyDependency>[],
  }) {
    final today = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day,
    );
    final exam = DateTime(examDate.year, examDate.month, examDate.day);
    final daysUntilExam = exam.difference(today).inDays;
    final phase = phaseService.phaseFor(
      currentDate: today,
      examDate: exam,
    );

    final pressure = capacityPressureService.calculate(
      capacity: capacity,
      phase: phase,
      profiles: dashboard.profiles.values,
      generatedAt: currentDate,
    );

    final point = trajectoryService.pointFromDashboard(
      dashboard,
      date: today,
    );
    final combinedHistory = <ReadinessTrajectoryPoint>[
      ...trajectoryHistory.where((item) => !_sameDay(item.date, today)),
      point,
    ];
    final trajectory = trajectoryService.summarize(combinedHistory);
    final projection = coverageProjectionService.project(
      trajectory: trajectory,
      daysToExam: daysUntilExam,
    );

    final evidenceSummary = _evidenceSummary(
      dashboard: dashboard,
      evidenceByCompetency: evidenceByCompetency,
    );
    final index = indexService.evaluate(
      dashboard: dashboard,
      evidence: evidenceSummary,
      generatedAt: currentDate,
    );

    final checkpoint = checkpointService.nextCheckpoint(
      currentDate: today,
      examDate: exam,
      ultraHardAvailable: ultraHardAvailable,
    );

    final recovery = recoveryService.evaluate(
      history: dailyPlanHistory,
      today: today,
      declaredMinutes:
          todayPlan?.availableMinutes ??
          capacity.averageMinutesPerStudyDay.round(),
    );

    final rootGaps = rootGapService.identify(
      dependencies: dependencies,
      profiles: dashboard.profiles,
    );

    final strong = dashboard.profiles.values
        .where(
          (profile) =>
              profile.readinessState == ReadinessState.strong ||
              profile.readinessState == ReadinessState.stable,
        )
        .length;
    final developing = dashboard.profiles.values
        .where(
          (profile) =>
              profile.readinessState == ReadinessState.learning ||
              profile.readinessState == ReadinessState.developing ||
              profile.readinessState == ReadinessState.provisional,
        )
        .length;
    final insufficient = dashboard.profiles.values
        .where(
          (profile) =>
              profile.readinessState == ReadinessState.unknown ||
              profile.readinessState == ReadinessState.insufficientEvidence,
        )
        .length;

    final explanation = todayPlan == null
        ? null
        : todayPlan.blocks.isEmpty
        ? 'No learning blocks are scheduled for today.'
        : '${todayPlan.generationReason.name}: '
              '${todayPlan.blocks.first.reasonText}';

    final reasons = <String>{
      'EXAM_PHASE_${phase.name.toUpperCase()}',
      ...pressure.reasonCodes,
      ...index.reasonCodes,
      ...projection.reasonCodes,
      ...recovery.reasonCodes,
      ...?checkpoint?.reasonCodes,
      ...rootGaps.expand((item) => item.reasonCodes),
      ...?todayPlan?.blocks.expand((block) => block.reasonCodes),
    }.toList(growable: false);

    return AdvancedReadinessSnapshot(
      generatedAt: currentDate,
      daysUntilExam: daysUntilExam,
      phase: phase,
      capacityPressure: pressure,
      readinessIndex: index,
      trajectory: trajectory,
      latestTrajectoryPoint: point,
      coverageProjection: projection,
      nextCheckpoint: checkpoint,
      recoveryProtection: recovery,
      evidenceConfidence: dashboard.evidenceConfidence,
      strongCompetencies: strong,
      developingCompetencies: developing,
      criticalGaps: dashboard.criticalGapCount,
      insufficientEvidenceCompetencies: insufficient,
      todayPlanMinutes: todayPlan?.allocatedMinutes ?? 0,
      todayBlockCount: todayPlan?.blocks.length ?? 0,
      planChangeExplanation: explanation,
      rootGapCandidates: rootGaps,
      reasonCodes: reasons,
      algorithmVersion: currentAlgorithmVersion,
    );
  }

  ReadinessIndexEvidenceSummary _evidenceSummary({
    required ExamReadinessDashboard dashboard,
    required Map<String, CompetencyEvidenceSnapshot> evidenceByCompetency,
  }) {
    final totalCompetencies = csp11Domains.fold<int>(
      0,
      (sum, domain) => sum + domain.competencies.length,
    );
    final snapshots = evidenceByCompetency.values.toList(growable: false);
    final assessed = snapshots
        .where((snapshot) => snapshot.sourceAttemptCount > 0)
        .length;
    final attempts = snapshots.fold<int>(
      0,
      (sum, snapshot) => sum + snapshot.sourceAttemptCount,
    );
    final application = snapshots
        .where(
          (snapshot) =>
              snapshot.cognition.applicationAttempts +
                  snapshot.cognition.analysisAttempts >=
              3,
        )
        .length;
    final retention = snapshots
        .where((snapshot) => snapshot.retention.delayedAttempts > 0)
        .length;
    final blindSpots = dashboard.profiles.values
        .where(
          (profile) => profile.gaps.any(
            (gap) =>
                gap.evidenceLimited &&
                (gap.severity == ReadinessGapSeverity.high ||
                    gap.severity == ReadinessGapSeverity.critical),
          ),
        )
        .length;

    return ReadinessIndexEvidenceSummary(
      totalCompetencies: totalCompetencies,
      assessedCompetencies: assessed,
      totalAttempts: attempts,
      applicationEvidenceCompetencies: application,
      retentionEvidenceCompetencies: retention,
      criticalEvidenceBlindSpots: blindSpots,
    );
  }

  bool _sameDay(DateTime left, DateTime right) =>
      left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}
