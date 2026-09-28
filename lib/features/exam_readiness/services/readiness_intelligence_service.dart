import '../models/advanced_readiness_snapshot.dart';
import '../models/competency_readiness_profile.dart';
import '../models/readiness_intelligence_snapshot.dart';
import '../models/readiness_index_snapshot.dart';

class ReadinessIntelligenceService {
  const ReadinessIntelligenceService();

  static const String currentAlgorithmVersion = 'erdp1-readiness-intelligence-v1';

  ReadinessIntelligenceSnapshot build({
    required ExamReadinessDashboard dashboard,
    required AdvancedReadinessSnapshot advanced,
    int dueFlashcards = 0,
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

    final score = advanced.readinessIndex.availability ==
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
  }) {
    if (evidenceGapCompetencyIds.isNotEmpty) {
      final competencyId = evidenceGapCompetencyIds.first;
      return ReadinessNextAction(
        kind: ReadinessNextActionKind.diagnostic,
        competencyId: competencyId,
        minutes: 15,
        reasonCodes: const <String>['ERDP1_INSUFFICIENT_EVIDENCE_DIAGNOSTIC'],
        reasonText: 'Build enough evidence to distinguish a true weakness from an evidence gap.',
      );
    }

    if (weakCompetencyIds.isNotEmpty) {
      final competencyId = weakCompetencyIds.first;
      final profile = profiles.firstWhere(
        (item) => item.competencyId == competencyId,
      );

      if (_isRetentionPrimary(profile) && dueFlashcards > 0) {
        return ReadinessNextAction(
          kind: ReadinessNextActionKind.flashcardReview,
          competencyId: competencyId,
          minutes: 10,
          reasonCodes: const <String>['ERDP1_RETENTION_GAP_FLASHCARD_REVIEW'],
          reasonText: 'Retention is the limiting factor, so use a short spaced-recall intervention.',
        );
      }

      if (_isApplicationPrimary(profile)) {
        return ReadinessNextAction(
          kind: ReadinessNextActionKind.lab,
          competencyId: competencyId,
          minutes: 15,
          reasonCodes: const <String>['ERDP1_APPLICATION_GAP_APPLIED_PRACTICE'],
          reasonText: 'Application evidence is weaker than knowledge evidence, so use an applied task.',
        );
      }

      return ReadinessNextAction(
        kind: ReadinessNextActionKind.targetedPractice,
        competencyId: competencyId,
        minutes: 15,
        reasonCodes: const <String>['ERDP1_WEAK_COMPETENCY_TARGETED_PRACTICE'],
        reasonText: 'Current evidence supports a genuine weakness that needs targeted practice.',
      );
    }

    if (dueFlashcards > 0) {
      return ReadinessNextAction(
        kind: ReadinessNextActionKind.flashcardReview,
        competencyId: '',
        minutes: 10,
        reasonCodes: const <String>['ERDP1_RETENTION_MAINTENANCE_DUE'],
        reasonText: 'No major weakness is leading, but spaced recall is due for retention maintenance.',
      );
    }

    return null;
  }

  bool _isRetentionPrimary(CompetencyReadinessProfile profile) {
    final retention = profile.retention.value;
    final knowledge = profile.knowledgeMastery.value;
    if (retention == null || knowledge == null) return false;
    return retention + 0.12 < knowledge;
  }

  bool _isApplicationPrimary(CompetencyReadinessProfile profile) {
    final application = profile.applicationAbility.value;
    final knowledge = profile.knowledgeMastery.value;
    if (application == null || knowledge == null) return false;
    return application + 0.12 < knowledge;
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
        evidenceConfidence: const CompetencyReadinessProfilePlaceholder()
            .noneConfidence,
        reasonCodes: const <String>['ERDP1_DIMENSION_UNAVAILABLE'],
      );
    }

    final average = available
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

class CompetencyReadinessProfilePlaceholder {
  const CompetencyReadinessProfilePlaceholder();

  // Kept local so the projection does not fabricate readiness evidence.
  dynamic get noneConfidence => throw UnimplementedError();
}
