import '../models/competency_evidence_snapshot.dart';
import '../models/competency_readiness_profile.dart';
import '../models/evidence_confidence.dart';
import '../models/readiness_gap.dart';

class ReadinessGapService {
  const ReadinessGapService();

  List<ReadinessGap> build({
    required CompetencyEvidenceSnapshot evidence,
    required ReadinessDimension knowledge,
    required ReadinessDimension application,
    required ReadinessDimension retention,
    required ReadinessDimension coverage,
    required DifficultyReadinessProfile difficulty,
    required ReadinessDimension calibration,
  }) {
    final gaps = <ReadinessGap>[];
    final id = evidence.competencyId;
    final confidence = evidence.evidenceQuality.confidenceLevel;

    if (confidence.rank <= EvidenceConfidence.low.rank) {
      gaps.add(
        ReadinessGap(
          type: ReadinessGapType.evidenceGap,
          severity: confidence == EvidenceConfidence.none ||
                  confidence == EvidenceConfidence.veryLow
              ? ReadinessGapSeverity.high
              : ReadinessGapSeverity.moderate,
          competencyId: id,
          reasonCode: 'INSUFFICIENT_ASSESSMENT_EVIDENCE',
          explanation: '$id has insufficient assessment evidence.',
          evidenceLimited: true,
        ),
      );
    }

    if (coverage.value != null && coverage.value! < 0.50) {
      gaps.add(
        ReadinessGap(
          type: ReadinessGapType.coverageGap,
          severity: coverage.value! < 0.25
              ? ReadinessGapSeverity.high
              : ReadinessGapSeverity.moderate,
          competencyId: id,
          reasonCode: 'LOW_BLUEPRINT_COVERAGE',
          explanation: '$id has limited blueprint coverage.',
          evidenceLimited: true,
        ),
      );
    }

    if (knowledge.value != null && knowledge.value! < 0.58) {
      gaps.add(
        ReadinessGap(
          type: ReadinessGapType.masteryGap,
          severity: knowledge.value! < 0.42
              ? ReadinessGapSeverity.critical
              : ReadinessGapSeverity.high,
          competencyId: id,
          reasonCode: 'KNOWLEDGE_MASTERY_GAP',
          explanation: '$id shows a knowledge-mastery gap.',
          evidenceLimited: false,
        ),
      );
    }

    if (application.value == null) {
      gaps.add(
        ReadinessGap(
          type: ReadinessGapType.evidenceGap,
          severity: ReadinessGapSeverity.moderate,
          competencyId: id,
          reasonCode: 'APPLICATION_EVIDENCE_MISSING',
          explanation: '$id has insufficient Application-level evidence.',
          evidenceLimited: true,
        ),
      );
    } else if (application.value! < 0.58) {
      gaps.add(
        ReadinessGap(
          type: ReadinessGapType.applicationGap,
          severity: application.value! < 0.42
              ? ReadinessGapSeverity.critical
              : ReadinessGapSeverity.high,
          competencyId: id,
          reasonCode: 'APPLICATION_GAP',
          explanation: '$id shows weak application performance.',
          evidenceLimited: false,
        ),
      );
    }

    if (retention.value == null) {
      gaps.add(
        ReadinessGap(
          type: ReadinessGapType.retentionGap,
          severity: ReadinessGapSeverity.moderate,
          competencyId: id,
          reasonCode: 'RETENTION_EVIDENCE_MISSING',
          explanation: '$id has no delayed retention evidence.',
          evidenceLimited: true,
        ),
      );
    } else if (retention.value! < 0.58) {
      gaps.add(
        ReadinessGap(
          type: ReadinessGapType.retentionGap,
          severity: retention.value! < 0.42
              ? ReadinessGapSeverity.high
              : ReadinessGapSeverity.moderate,
          competencyId: id,
          reasonCode: 'RETENTION_GAP',
          explanation: '$id shows weak delayed retrieval performance.',
          evidenceLimited: false,
        ),
      );
    }

    if (difficulty.dimension.value != null &&
        difficulty.dimension.value! < 0.58) {
      gaps.add(
        ReadinessGap(
          type: ReadinessGapType.difficultyGap,
          severity: difficulty.dimension.value! < 0.42
              ? ReadinessGapSeverity.high
              : ReadinessGapSeverity.moderate,
          competencyId: id,
          reasonCode: 'DIFFICULTY_PERFORMANCE_GAP',
          explanation: '$id weakens as question difficulty increases.',
          evidenceLimited: false,
        ),
      );
    }

    if (calibration.value != null && calibration.value! < 0.60) {
      gaps.add(
        ReadinessGap(
          type: ReadinessGapType.confidenceGap,
          severity: calibration.value! < 0.40
              ? ReadinessGapSeverity.high
              : ReadinessGapSeverity.moderate,
          competencyId: id,
          reasonCode: 'CONFIDENCE_MISALIGNMENT',
          explanation: '$id shows confidence calibration that needs attention.',
          evidenceLimited: false,
        ),
      );
    }

    if (evidence.recency.band == EvidenceRecencyBand.stale ||
        evidence.recency.band == EvidenceRecencyBand.veryStale) {
      gaps.add(
        ReadinessGap(
          type: ReadinessGapType.stalenessGap,
          severity: evidence.recency.band == EvidenceRecencyBand.veryStale
              ? ReadinessGapSeverity.high
              : ReadinessGapSeverity.moderate,
          competencyId: id,
          reasonCode: 'STALE_EVIDENCE',
          explanation: '$id has not been assessed recently.',
          evidenceLimited: true,
        ),
      );
    }

    return List<ReadinessGap>.unmodifiable(gaps);
  }
}
