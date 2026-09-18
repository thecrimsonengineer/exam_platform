import '../models/competency_readiness_profile.dart';
import '../models/learning_priority_score.dart';
import '../models/readiness_gap.dart';
import 'evidence_debt_service.dart';

class LearningPriorityEngine {
  const LearningPriorityEngine({
    this.evidenceDebtService = const EvidenceDebtService(),
  });

  final EvidenceDebtService evidenceDebtService;

  LearningPriorityScore score({
    required String competencyId,
    required int domainWeightPercent,
    required int daysUntilExam,
    required CompetencyReadinessProfile? profile,
    required bool ultraHardAvailable,
    bool recentlyStudied = false,
    double prerequisiteImportance = 0.0,
  }) {
    final debt = evidenceDebtService.assess(
      profile: profile,
      requireUltraHardEvidence: ultraHardAvailable,
    );

    final blueprintImportance = (domainWeightPercent / 25.0)
        .clamp(0.0, 1.0)
        .toDouble();
    final masteryGap = _gap(profile?.knowledgeMastery.value);
    final applicationGap = _gap(profile?.applicationAbility.value);
    final retentionRisk = _gap(profile?.retention.value);
    final coverageGap = _gap(profile?.blueprintCoverage.value);
    final difficultyWeakness = _gap(
      profile?.difficultyPerformance.dimension.value,
    );
    final staleness = _staleness(profile);
    final examProximity = daysUntilExam <= 0
        ? 1.0
        : (1.0 - (daysUntilExam / 90.0)).clamp(0.0, 1.0).toDouble();
    final recentPenalty = recentlyStudied ? 0.65 : 0.0;
    final prerequisite = prerequisiteImportance.clamp(0.0, 1.0).toDouble();

    final raw =
        blueprintImportance * 0.16 +
        masteryGap * 0.12 +
        applicationGap * 0.16 +
        retentionRisk * 0.10 +
        coverageGap * 0.10 +
        debt.score * 0.16 +
        staleness * 0.06 +
        difficultyWeakness * 0.06 +
        examProximity * 0.08 +
        prerequisite * 0.03 -
        recentPenalty * 0.07;

    final reasons = <String>[];
    if (blueprintImportance >= 0.60) reasons.add('HIGH_BLUEPRINT_PRIORITY');
    if (masteryGap >= 0.42) reasons.add('MASTERY_GAP');
    if (applicationGap >= 0.42) reasons.add('APPLICATION_GAP');
    if (retentionRisk >= 0.42) reasons.add('RETENTION_DUE');
    if (coverageGap >= 0.42) reasons.add('COVERAGE_GAP');
    if (debt.score >= 0.50) reasons.add('EVIDENCE_DEBT');
    if (staleness >= 0.50) reasons.add('STALE_EVIDENCE');
    if (difficultyWeakness >= 0.42) reasons.add('DIFFICULTY_GAP');
    if (examProximity >= 0.60) reasons.add('EXAM_PROXIMITY');
    if (profile?.confidenceCalibration.value != null &&
        profile!.confidenceCalibration.value! < 0.60) {
      reasons.add('CONFIDENCE_MISALIGNMENT');
    }
    if (ultraHardAvailable &&
        profile?.difficultyPerformance.ultraHardAccuracy == null) {
      reasons.add('ULTRA_HARD_GAP');
    }
    if (reasons.isEmpty) reasons.add('MAINTAIN_READINESS');

    return LearningPriorityScore(
      competencyId: competencyId,
      blueprintImportance: blueprintImportance,
      masteryGap: masteryGap,
      applicationGap: applicationGap,
      retentionRisk: retentionRisk,
      coverageGap: coverageGap,
      evidenceDebt: debt.score,
      staleness: staleness,
      difficultyWeakness: difficultyWeakness,
      examProximity: examProximity,
      prerequisiteImportance: prerequisite,
      recentStudyPenalty: recentPenalty,
      evidenceDebtLevel: debt.level,
      totalScore: raw.clamp(0.0, 1.0).toDouble(),
      reasonCodes: List<String>.unmodifiable(reasons),
    );
  }

  double _gap(double? value) => value == null ? 0.0 : 1.0 - value;

  double _staleness(CompetencyReadinessProfile? profile) {
    if (profile == null) return 0.0;
    if (profile.readinessState == ReadinessState.stale) return 1.0;
    if (profile.gaps.any((gap) => gap.type == ReadinessGapType.stalenessGap)) {
      return 0.75;
    }
    return 0.0;
  }
}
