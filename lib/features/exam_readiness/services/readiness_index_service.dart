import '../models/competency_readiness_profile.dart';
import '../models/evidence_confidence.dart';
import '../models/readiness_index_snapshot.dart';
import '../models/readiness_weight_configuration.dart';

class ReadinessIndexService {
  const ReadinessIndexService({
    this.weights = const ReadinessWeightConfiguration(),
    this.gate = const ReadinessIndexGateConfiguration(),
    this.algorithmVersion = currentAlgorithmVersion,
  });

  static const String currentAlgorithmVersion = 'm7f-readiness-index-v1';

  final ReadinessWeightConfiguration weights;
  final ReadinessIndexGateConfiguration gate;
  final String algorithmVersion;

  ReadinessIndexSnapshot evaluate({
    required ExamReadinessDashboard dashboard,
    required ReadinessIndexEvidenceSummary evidence,
    DateTime? generatedAt,
  }) {
    weights.validate();
    gate.validate();
    evidence.validate();

    final reasons = _gateReasons(dashboard: dashboard, evidence: evidence);

    if (reasons.isNotEmpty) {
      return _unavailable(
        dashboard: dashboard,
        reasons: reasons,
        generatedAt: generatedAt,
      );
    }

    final recentPerformance = _average(
      dashboard.profiles.values.map(
        (profile) => profile.recentPerformance.value,
      ),
    );

    final hasBlueprintCoverageDenominator =
        dashboard.blueprintCoverage.competenciesTotal > 0 ||
        dashboard.blueprintCoverage.topicsTotal > 0 ||
        dashboard.blueprintCoverage.subtopicsTotal > 0;

    final components = <String, double?>{
      'knowledgeMastery': dashboard.knowledgeMastery.value,
      'applicationAbility': dashboard.applicationAbility.value,
      'retention': dashboard.retention.value,
      'blueprintCoverage': hasBlueprintCoverageDenominator
          ? dashboard.blueprintCoverage.ratio
          : null,
      'difficultyPerformance': dashboard.difficultyPerformance.value,
      'competencyBreadth': evidence.assessedCompetencyRatio,
      'recentPerformance': recentPerformance,
      'confidenceCalibration': dashboard.confidenceCalibration.value,
    };

    final missing = components.entries
        .where((entry) => entry.value == null)
        .map((entry) => entry.key)
        .toList(growable: false);

    if (missing.isNotEmpty) {
      return _unavailable(
        dashboard: dashboard,
        reasons: [
          'READINESS_DIMENSIONS_INCOMPLETE',
          ...missing.map((name) => 'MISSING_${name.toUpperCase()}'),
        ],
        generatedAt: generatedAt,
      );
    }

    final values = components.map(
      (key, value) => MapEntry(key, value!.clamp(0.0, 1.0).toDouble()),
    );
    final weightMap = weights.asMap();

    var weighted = 0.0;
    for (final entry in values.entries) {
      weighted += entry.value * (weightMap[entry.key] ?? 0);
    }

    final snapshot = ReadinessIndexSnapshot(
      generatedAt: generatedAt ?? dashboard.generatedAt,
      availability: ReadinessIndexAvailability.available,
      score: (weighted.clamp(0.0, 1.0) * 100).round(),
      evidenceConfidence: dashboard.evidenceConfidence,
      components: Map<String, double>.unmodifiable(values),
      reasonCodes: const ['READINESS_INDEX_EVIDENCE_GATE_PASSED'],
      weightConfigurationVersion: weights.version,
      gateConfigurationVersion: gate.version,
      algorithmVersion: algorithmVersion,
    );
    snapshot.validate();
    return snapshot;
  }

  List<String> _gateReasons({
    required ExamReadinessDashboard dashboard,
    required ReadinessIndexEvidenceSummary evidence,
  }) {
    final reasons = <String>[];

    if (evidence.assessedCompetencyRatio <
        gate.minimumAssessedCompetencyRatio) {
      reasons.add('INSUFFICIENT_COMPETENCY_COVERAGE');
    }
    if (evidence.totalAttempts < gate.minimumTotalAttempts) {
      reasons.add('INSUFFICIENT_TOTAL_EVIDENCE');
    }
    if (evidence.applicationCompetencyRatio <
        gate.minimumApplicationCompetencyRatio) {
      reasons.add('INSUFFICIENT_APPLICATION_EVIDENCE');
    }
    if (evidence.retentionCompetencyRatio <
        gate.minimumRetentionCompetencyRatio) {
      reasons.add('INSUFFICIENT_RETENTION_EVIDENCE');
    }
    if (evidence.criticalEvidenceBlindSpots >
        gate.maximumCriticalEvidenceBlindSpots) {
      reasons.add('CRITICAL_EVIDENCE_BLIND_SPOTS');
    }
    if (dashboard.evidenceConfidence.rank <
        gate.minimumEvidenceConfidenceRank) {
      reasons.add('OVERALL_EVIDENCE_CONFIDENCE_TOO_LOW');
    }

    return reasons;
  }

  ReadinessIndexSnapshot _unavailable({
    required ExamReadinessDashboard dashboard,
    required List<String> reasons,
    required DateTime? generatedAt,
  }) {
    final snapshot = ReadinessIndexSnapshot(
      generatedAt: generatedAt ?? dashboard.generatedAt,
      availability: ReadinessIndexAvailability.insufficientEvidence,
      score: null,
      evidenceConfidence: dashboard.evidenceConfidence,
      components: const <String, double>{},
      reasonCodes: List<String>.unmodifiable(reasons),
      weightConfigurationVersion: weights.version,
      gateConfigurationVersion: gate.version,
      algorithmVersion: algorithmVersion,
    );
    snapshot.validate();
    return snapshot;
  }

  double? _average(Iterable<double?> values) {
    final available = values.whereType<double>().toList(growable: false);
    if (available.isEmpty) return null;
    return available.reduce((left, right) => left + right) / available.length;
  }
}
