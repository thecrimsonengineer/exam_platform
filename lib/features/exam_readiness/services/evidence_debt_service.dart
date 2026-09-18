import '../models/competency_readiness_profile.dart';
import '../models/evidence_confidence.dart';
import '../models/learning_priority_score.dart';

class EvidenceDebtService {
  const EvidenceDebtService();

  EvidenceDebtAssessment assess({
    required CompetencyReadinessProfile? profile,
    bool requireUltraHardEvidence = false,
  }) {
    if (profile == null) {
      return const EvidenceDebtAssessment(
        level: EvidenceDebtLevel.critical,
        score: 1.0,
        reasonCodes: ['NO_ASSESSMENT_EVIDENCE'],
      );
    }

    final reasons = <String>[];
    var score = 0.0;

    void add(String reason, double value) {
      if (!reasons.contains(reason)) {
        reasons.add(reason);
      }
      if (value > score) score = value;
    }

    switch (profile.evidenceConfidence) {
      case EvidenceConfidence.none:
      case EvidenceConfidence.veryLow:
        add('INSUFFICIENT_ASSESSMENT_EVIDENCE', 1.0);
      case EvidenceConfidence.low:
        add('LOW_EVIDENCE_CONFIDENCE', 0.82);
      case EvidenceConfidence.moderate:
        add('MODERATE_EVIDENCE_CONFIDENCE', 0.45);
      case EvidenceConfidence.high:
      case EvidenceConfidence.veryHigh:
        break;
    }

    if (profile.blueprintCoverage.value == null ||
        profile.blueprintCoverage.value! < 0.35) {
      add('INADEQUATE_BLUEPRINT_BREADTH', 0.82);
    }
    if (profile.applicationAbility.value == null) {
      add('NO_APPLICATION_EVIDENCE', 0.90);
    }
    if (profile.retention.value == null) {
      add('NO_DELAYED_RETENTION_EVIDENCE', 0.68);
    }
    if (profile.difficultyPerformance.hardAccuracy == null) {
      add('NO_HARD_EVIDENCE', 0.58);
    }
    if (requireUltraHardEvidence &&
        profile.difficultyPerformance.ultraHardAccuracy == null) {
      add('NO_ULTRA_HARD_EVIDENCE', 0.72);
    }
    if (profile.readinessState == ReadinessState.stale) {
      add('STALE_EVIDENCE', 0.82);
    }

    final level = score >= 0.90
        ? EvidenceDebtLevel.critical
        : score >= 0.75
        ? EvidenceDebtLevel.high
        : score >= 0.50
        ? EvidenceDebtLevel.moderate
        : score > 0
        ? EvidenceDebtLevel.low
        : EvidenceDebtLevel.none;

    return EvidenceDebtAssessment(
      level: level,
      score: score.clamp(0.0, 1.0).toDouble(),
      reasonCodes: List<String>.unmodifiable(reasons),
    );
  }
}
