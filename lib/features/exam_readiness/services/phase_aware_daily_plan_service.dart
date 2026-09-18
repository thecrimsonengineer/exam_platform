import '../models/competency_readiness_profile.dart';
import '../models/daily_study_plan.dart';
import '../models/evidence_confidence.dart';
import '../models/exam_preparation_phase.dart';
import '../models/readiness_gap.dart';
import '../models/study_plan_block.dart';
import 'daily_study_plan_service.dart';
import 'exam_preparation_phase_service.dart';

class PhaseAwareDailyPlanService {
  const PhaseAwareDailyPlanService({
    this.baseService = const DailyStudyPlanService(),
    this.phaseService = const ExamPreparationPhaseService(),
  });

  static const String currentAlgorithmVersion = 'm7f-phase-aware-v1';

  final DailyStudyPlanService baseService;
  final ExamPreparationPhaseService phaseService;

  DailyStudyPlan generate({
    required String userId,
    required DateTime date,
    required DateTime generatedAt,
    required DateTime examDate,
    required int availableMinutes,
    required Map<String, CompetencyReadinessProfile> readinessProfiles,
    Set<String> ultraHardAvailableCompetencyIds = const <String>{},
    Set<String> recentlyStudiedCompetencyIds = const <String>{},
    DailyStudyPlan? existingPlan,
    DailyStudyPlanGenerationReason generationReason =
        DailyStudyPlanGenerationReason.initial,
  }) {
    final phase = phaseService.phaseFor(currentDate: date, examDate: examDate);
    final allocation = phaseService.configuration.allocationFor(phase);

    final base = baseService.generate(
      userId: userId,
      date: date,
      generatedAt: generatedAt,
      examDate: examDate,
      availableMinutes: availableMinutes,
      readinessProfiles: readinessProfiles,
      ultraHardAvailableCompetencyIds: ultraHardAvailableCompetencyIds,
      recentlyStudiedCompetencyIds: recentlyStudiedCompetencyIds,
      existingPlan: existingPlan,
      generationReason: generationReason,
    );

    final blocks = <StudyPlanBlock>[
      for (final block in base.blocks)
        if (block.isLocked)
          block
        else
          _adaptBlock(
            block: block,
            phase: phase,
            allocation: allocation,
            profile: readinessProfiles[block.competencyId],
            ultraHardAvailable: ultraHardAvailableCompetencyIds.contains(
              block.competencyId,
            ),
          ),
    ];

    final plan = base.copyWith(
      plannerAlgorithmVersion: currentAlgorithmVersion,
      blocks: blocks,
      allocatedMinutes: blocks.fold<int>(
        0,
        (sum, block) => sum + block.plannedMinutes,
      ),
      inputSnapshotVersion:
          '${base.inputSnapshotVersion}|phase:${phase.name}|'
          'phaseCfg:${phaseService.configuration.version}',
    );
    plan.validate();
    return plan;
  }

  StudyPlanBlock _adaptBlock({
    required StudyPlanBlock block,
    required ExamPreparationPhase phase,
    required PhaseAllocationProfile allocation,
    required CompetencyReadinessProfile? profile,
    required bool ultraHardAvailable,
  }) {
    var type = block.type;

    switch (phase) {
      case ExamPreparationPhase.foundation:
        final coverage = profile?.blueprintCoverage.value;
        if ((type == StudyPlanBlockType.standardPractice ||
                type == StudyPlanBlockType.mixedRetrieval) &&
            (coverage == null || coverage < 0.75)) {
          type =
              profile == null ||
                  profile.evidenceConfidence.rank <= EvidenceConfidence.low.rank
              ? StudyPlanBlockType.diagnostic
              : StudyPlanBlockType.continueLearning;
        }
        break;
      case ExamPreparationPhase.integration:
        if (type == StudyPlanBlockType.continueLearning &&
            profile != null &&
            profile.evidenceConfidence.rank >=
                EvidenceConfidence.moderate.rank) {
          type = StudyPlanBlockType.mixedRetrieval;
        }
        break;
      case ExamPreparationPhase.readiness:
        if ((type == StudyPlanBlockType.learn ||
                type == StudyPlanBlockType.continueLearning) &&
            profile != null &&
            profile.evidenceConfidence.rank >=
                EvidenceConfidence.moderate.rank) {
          type = StudyPlanBlockType.mixedRetrieval;
        }
        if (type == StudyPlanBlockType.standardPractice &&
            ultraHardAvailable &&
            _ultraHardJustified(profile)) {
          type = StudyPlanBlockType.ultraHardPractice;
        }
        break;
      case ExamPreparationPhase.consolidation:
        if ((type == StudyPlanBlockType.learn ||
                type == StudyPlanBlockType.continueLearning) &&
            !_hasCriticalCoverageGap(profile)) {
          type = StudyPlanBlockType.spacedReview;
        } else if (type == StudyPlanBlockType.standardPractice) {
          type = StudyPlanBlockType.mixedRetrieval;
        }
        break;
    }

    final phaseCode = 'EXAM_PHASE_${phase.name.toUpperCase()}';
    final allocationCode =
        'PHASE_ALLOCATION_L${(allocation.learning * 100).round()}_'
        'P${(allocation.practice * 100).round()}_'
        'R${(allocation.review * 100).round()}_'
        'D${(allocation.diagnostics * 100).round()}';

    return block.copyWith(
      type: type,
      questionCount: _questionCount(type, block.plannedMinutes),
      reasonCodes: <String>{
        ...block.reasonCodes,
        phaseCode,
        allocationCode,
        if (type == StudyPlanBlockType.ultraHardPractice) 'ULTRA_HARD_GAP',
      }.toList(growable: false),
      reasonText:
          '${block.reasonText} Current exam phase: ${phase.name.toUpperCase()}.',
    );
  }

  bool _ultraHardJustified(CompetencyReadinessProfile? profile) {
    if (profile == null ||
        profile.evidenceConfidence.rank < EvidenceConfidence.moderate.rank) {
      return false;
    }
    final ultra = profile.difficultyPerformance.ultraHardAccuracy;
    final application = profile.applicationAbility.value;
    return ultra == null ||
        ultra < 0.70 ||
        (application != null && application < 0.70);
  }

  bool _hasCriticalCoverageGap(CompetencyReadinessProfile? profile) {
    if (profile == null) return true;
    return profile.gaps.any(
      (gap) =>
          gap.type == ReadinessGapType.coverageGap &&
          (gap.severity == ReadinessGapSeverity.high ||
              gap.severity == ReadinessGapSeverity.critical),
    );
  }

  int _questionCount(StudyPlanBlockType type, int minutes) {
    switch (type) {
      case StudyPlanBlockType.diagnostic:
      case StudyPlanBlockType.standardPractice:
      case StudyPlanBlockType.ultraHardPractice:
      case StudyPlanBlockType.mixedRetrieval:
      case StudyPlanBlockType.competencyRecheck:
      case StudyPlanBlockType.confidenceCalibration:
      case StudyPlanBlockType.examSimulation:
        return (minutes ~/ 2).clamp(3, 10).toInt();
      default:
        return 0;
    }
  }
}
