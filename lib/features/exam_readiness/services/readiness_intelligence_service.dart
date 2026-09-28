import '../models/advanced_readiness_snapshot.dart';
import '../models/competency_readiness_profile.dart';
import '../models/evidence_confidence.dart';
import '../models/readiness_gap.dart';
import '../models/readiness_intelligence_snapshot.dart';
import '../models/readiness_index_snapshot.dart';

class ReadinessIntelligenceService {
  const ReadinessIntelligenceService();

  static const String currentAlgorithmVersion =
      'erdp1-readiness-intelligence-v1';

  ReadinessIntelligenceSnapshot build({
    required ExamReadinessDashboard dashboard,
    required AdvancedReadinessSnapshot advanced,
    int dueFlashcards = 0,
    int? daysUntilExam,
    DateTime? generatedAt,
  }) {
    final profiles = dashboard.profiles.values.toList(growable: false);

    final strong = profiles
        .where(
          (profile) =>
              profile.readinessState == ReadinessState.strong ||
              profile.readinessState == ReadinessState.stable,
        )
        .map((profile) => profile.competencyId)
        .toList(growable: false);

    final evidenceGap = profiles
        .where(
          (profile) =>
              profile.readinessState == ReadinessState.unknown ||
              profile.readinessState == ReadinessState.insufficientEvidence ||
              profile.hasEvidenceGap,
        )
        .map((profile) => profile.competencyId)
        .toList(growable: false);

    final weak = profiles
        .where(
          (profile) =>
              !evidenceGap.contains(profile.competencyId) &&
              (profile.readinessState == ReadinessState.learning ||
                  profile.readinessState == ReadinessState.developing ||
                  profile.readinessState == ReadinessState.provisional ||
                  profile.readinessState == ReadinessState.atRisk ||
                  profile.readinessState == ReadinessState.stale ||
                  profile.hasCriticalGap),
        )
        .map((profile) => profile.competencyId)
        .toList(growable: false);

    final recency = _averageDimension(
      code: 'recency',
      dimensions: profiles.map((profile) => profile.recentPerformance),
    );

    final evidenceSufficiency = profiles.isEmpty
        ? 0.0
        : profiles
                  .where(
                    (profile) =>
                        profile.readinessState != ReadinessState.unknown &&
                        profile.readinessState !=
                            ReadinessState.insufficientEvidence,
                  )
                  .length /
              profiles.length;

    final score =
        advanced.readinessIndex.availability ==
            ReadinessIndexAvailability.available
        ? advanced.readinessIndex.score
        : null;

    final state = _state(
      score: score,
      evidenceSufficiency: evidenceSufficiency,
      weakCount: weak.length,
      criticalGaps: advanced.criticalGaps,
    );

    final action = _nextBestAction(
      profiles: profiles,
      weakCompetencyIds: weak,
      evidenceGapCompetencyIds: evidenceGap,
      dueFlashcards: dueFlashcards,
      daysUntilExam: daysUntilExam,
    );

    final reasons = <String>{
      ...advanced.reasonCodes,
      if (evidenceGap.isNotEmpty) 'ERDP1_EVIDENCE_GAPS_PRESENT',
      if (weak.isNotEmpty) 'ERDP1_WEAK_COMPETENCIES_PRESENT',
      if (dueFlashcards > 0) 'ERDP1_FLASHCARDS_DUE',
      if (action != null) ...action.reasonCodes,
    }.toList(growable: false);

    return ReadinessIntelligenceSnapshot(
      generatedAt: generatedAt ?? advanced.generatedAt,
      state: state,
      overallScore: score,
      evidenceConfidence: dashboard.evidenceConfidence,
      knowledge: dashboard.knowledgeMastery,
      application: dashboard.applicationAbility,
      retention: dashboard.retention,
      blueprintCoverage: dashboard.blueprintCoverage.ratio,
      difficultyCoverage: dashboard.difficultyPerformance,
      recency: recency,
      confidenceCalibration: dashboard.confidenceCalibration,
      evidenceSufficiency: evidenceSufficiency.clamp(0.0, 1.0),
      strongCompetencyIds: strong,
      weakCompetencyIds: weak,
      evidenceGapCompetencyIds: evidenceGap,
      dueFlashcards: dueFlashcards < 0 ? 0 : dueFlashcards,
      nextBestAction: action,
      reasonCodes: reasons,
      algorithmVersion: currentAlgorithmVersion,
    );
  }

  ReadinessIntelligenceState _state({
    required int? score,
    required double evidenceSufficiency,
    required int weakCount,
    required int criticalGaps,
  }) {
    if (evidenceSufficiency < 0.35 || score == null) {
      return ReadinessIntelligenceState.insufficientEvidence;
    }
    if (criticalGaps > 0 || (score < 45 && weakCount > 0)) {
      return ReadinessIntelligenceState.atRisk;
    }
    if (score >= 80 && weakCount == 0) {
      return ReadinessIntelligenceState.strong;
    }
    if (score >= 60) {
      return ReadinessIntelligenceState.progressing;
    }
    return ReadinessIntelligenceState.building;
  }

  ReadinessNextAction? _nextBestAction({
    required List<CompetencyReadinessProfile> profiles,
    required List<String> weakCompetencyIds,
    required List<String> evidenceGapCompetencyIds,
    required int dueFlashcards,
    required int? daysUntilExam,
  }) {
    if (evidenceGapCompetencyIds.isNotEmpty) {
      final competencyId = evidenceGapCompetencyIds.first;
      return ReadinessNextAction(
        kind: ReadinessNextActionKind.diagnostic,
        competencyId: competencyId,
        minutes: 15,
        reasonCodes: const <String>['ERDP1_INSUFFICIENT_EVIDENCE_DIAGNOSTIC'],
        reasonText:
            'Build enough evidence to distinguish a true weakness from an evidence gap.',
      );
    }

    final applicationGap = _firstWithGap(
      profiles,
      ReadinessGapType.applicationGap,
    );
    if (applicationGap != null) {
      return ReadinessNextAction(
        kind: ReadinessNextActionKind.lab,
        competencyId: applicationGap.competencyId,
        minutes: 15,
        reasonCodes: const <String>['ERDP1_APPLICATION_GAP_APPLIED_PRACTICE'],
        reasonText:
            'Application evidence is the limiting factor, so use an applied LAB task.',
      );
    }

    final retentionGap = _firstWithGap(profiles, ReadinessGapType.retentionGap);
    if (retentionGap != null &&
        (retentionGap.retention.value != null || dueFlashcards > 0)) {
      return ReadinessNextAction(
        kind: ReadinessNextActionKind.flashcardReview,
        competencyId: retentionGap.competencyId,
        minutes: 10,
        reasonCodes: const <String>['ERDP1_RETENTION_GAP_FLASHCARD_REVIEW'],
        reasonText:
            'Retention is the limiting factor, so use a short spaced-recall intervention.',
      );
    }

    final confidenceGap = _firstWithGap(
      profiles,
      ReadinessGapType.confidenceGap,
    );
    if (confidenceGap != null) {
      return ReadinessNextAction(
        kind: ReadinessNextActionKind.confidenceCalibration,
        competencyId: confidenceGap.competencyId,
        minutes: 10,
        reasonCodes: const <String>['ERDP7_CONFIDENCE_CALIBRATION'],
        reasonText:
            'Confidence and demonstrated performance are misaligned, so recalibrate with targeted questions.',
      );
    }

    final coverageGap = _firstWithGap(
      profiles,
      ReadinessGapType.coverageGap,
      includeEvidenceLimited: true,
    );
    if (coverageGap != null) {
      return ReadinessNextAction(
        kind: ReadinessNextActionKind.studyReview,
        competencyId: coverageGap.competencyId,
        minutes: 15,
        reasonCodes: const <String>['ERDP7_COVERAGE_GAP_STUDY'],
        reasonText:
            'Blueprint coverage is incomplete, so fill the missing learning coverage before adding more assessment.',
      );
    }

    if (weakCompetencyIds.isNotEmpty) {
      return ReadinessNextAction(
        kind: ReadinessNextActionKind.targetedPractice,
        competencyId: weakCompetencyIds.first,
        minutes: 15,
        reasonCodes: const <String>['ERDP1_WEAK_COMPETENCY_TARGETED_PRACTICE'],
        reasonText:
            'Current evidence supports a genuine weakness that needs targeted practice.',
      );
    }

    if (daysUntilExam != null && daysUntilExam >= 0 && daysUntilExam <= 14) {
      return ReadinessNextAction(
        kind: ReadinessNextActionKind.simulation,
        competencyId: '',
        minutes: 20,
        reasonCodes: const <String>['ERDP7_EXAM_PROXIMITY_SIMULATION'],
        reasonText:
            'The exam is close and no larger gap is leading, so rehearse integrated performance with a simulation.',
      );
    }

    if (dueFlashcards > 0) {
      return ReadinessNextAction(
        kind: ReadinessNextActionKind.flashcardReview,
        competencyId: '',
        minutes: 10,
        reasonCodes: const <String>['ERDP1_RETENTION_MAINTENANCE_DUE'],
        reasonText:
            'No major weakness is leading, but spaced recall is due for retention maintenance.',
      );
    }

    return null;
  }

  CompetencyReadinessProfile? _firstWithGap(
    Iterable<CompetencyReadinessProfile> profiles,
    ReadinessGapType type, {
    bool includeEvidenceLimited = false,
  }) {
    for (final profile in profiles) {
      if (profile.gaps.any(
        (gap) =>
            gap.type == type &&
            (includeEvidenceLimited || !gap.evidenceLimited),
      )) {
        return profile;
      }
    }
    return null;
  }

  ReadinessDimension _averageDimension({
    required String code,
    required Iterable<ReadinessDimension> dimensions,
  }) {
    final available = dimensions
        .where((item) => item.value != null)
        .toList(growable: false);
    if (available.isEmpty) {
      return ReadinessDimension(
        code: code,
        value: null,
        evidenceConfidence: EvidenceConfidence.none,
        reasonCodes: const <String>['ERDP1_DIMENSION_UNAVAILABLE'],
      );
    }

    final average =
        available
            .map((item) => item.value!)
            .reduce((left, right) => left + right) /
        available.length;
    final confidence = available
        .map((item) => item.evidenceConfidence)
        .reduce((left, right) => left.rank <= right.rank ? left : right);

    return ReadinessDimension(
      code: code,
      value: average,
      evidenceConfidence: confidence,
      reasonCodes: const <String>['ERDP1_AGGREGATED_RECENCY'],
    );
  }
}
