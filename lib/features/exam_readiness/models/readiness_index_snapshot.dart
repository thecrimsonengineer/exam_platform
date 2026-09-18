import 'evidence_confidence.dart';

enum ReadinessIndexAvailability {
  available,
  insufficientEvidence,
}

class ReadinessIndexEvidenceSummary {
  const ReadinessIndexEvidenceSummary({
    required this.totalCompetencies,
    required this.assessedCompetencies,
    required this.totalAttempts,
    required this.applicationEvidenceCompetencies,
    required this.retentionEvidenceCompetencies,
    required this.criticalEvidenceBlindSpots,
  });

  final int totalCompetencies;
  final int assessedCompetencies;
  final int totalAttempts;
  final int applicationEvidenceCompetencies;
  final int retentionEvidenceCompetencies;
  final int criticalEvidenceBlindSpots;

  double get assessedCompetencyRatio =>
      totalCompetencies <= 0 ? 0 : assessedCompetencies / totalCompetencies;

  double get applicationCompetencyRatio => totalCompetencies <= 0
      ? 0
      : applicationEvidenceCompetencies / totalCompetencies;

  double get retentionCompetencyRatio => totalCompetencies <= 0
      ? 0
      : retentionEvidenceCompetencies / totalCompetencies;

  void validate() {
    if (totalCompetencies < 0 ||
        assessedCompetencies < 0 ||
        totalAttempts < 0 ||
        applicationEvidenceCompetencies < 0 ||
        retentionEvidenceCompetencies < 0 ||
        criticalEvidenceBlindSpots < 0 ||
        assessedCompetencies > totalCompetencies ||
        applicationEvidenceCompetencies > totalCompetencies ||
        retentionEvidenceCompetencies > totalCompetencies) {
      throw StateError('Readiness Index evidence summary is invalid.');
    }
  }
}

class ReadinessIndexGateConfiguration {
  const ReadinessIndexGateConfiguration({
    this.minimumAssessedCompetencyRatio = 0.60,
    this.minimumTotalAttempts = 100,
    this.minimumApplicationCompetencyRatio = 0.35,
    this.minimumRetentionCompetencyRatio = 0.20,
    this.maximumCriticalEvidenceBlindSpots = 1,
    this.minimumEvidenceConfidenceRank = 3,
    this.version = currentVersion,
  });

  static const String currentVersion = 'm7f-readiness-index-gate-v1';

  final double minimumAssessedCompetencyRatio;
  final int minimumTotalAttempts;
  final double minimumApplicationCompetencyRatio;
  final double minimumRetentionCompetencyRatio;
  final int maximumCriticalEvidenceBlindSpots;
  final int minimumEvidenceConfidenceRank;
  final String version;

  void validate() {
    for (final ratio in [
      minimumAssessedCompetencyRatio,
      minimumApplicationCompetencyRatio,
      minimumRetentionCompetencyRatio,
    ]) {
      if (ratio < 0 || ratio > 1) {
        throw StateError('Readiness Index gate ratios must remain within 0-1.');
      }
    }
    if (minimumTotalAttempts < 0 ||
        maximumCriticalEvidenceBlindSpots < 0 ||
        minimumEvidenceConfidenceRank < 0 ||
        minimumEvidenceConfidenceRank >= EvidenceConfidence.values.length) {
      throw StateError('Readiness Index gate thresholds are invalid.');
    }
    if (version.trim().isEmpty) {
      throw StateError('Readiness Index gate must be versioned.');
    }
  }
}

class ReadinessIndexSnapshot {
  const ReadinessIndexSnapshot({
    required this.generatedAt,
    required this.availability,
    required this.score,
    required this.evidenceConfidence,
    required this.components,
    required this.reasonCodes,
    required this.weightConfigurationVersion,
    required this.gateConfigurationVersion,
    required this.algorithmVersion,
  });

  final DateTime generatedAt;
  final ReadinessIndexAvailability availability;
  final int? score;
  final EvidenceConfidence evidenceConfidence;
  final Map<String, double> components;
  final List<String> reasonCodes;
  final String weightConfigurationVersion;
  final String gateConfigurationVersion;
  final String algorithmVersion;

  bool get isAvailable =>
      availability == ReadinessIndexAvailability.available && score != null;

  void validate() {
    if (availability == ReadinessIndexAvailability.available &&
        (score == null || score! < 0 || score! > 100)) {
      throw StateError('Available Readiness Index requires a 0-100 score.');
    }
    if (availability == ReadinessIndexAvailability.insufficientEvidence &&
        score != null) {
      throw StateError(
        'Readiness Index must be withheld when evidence is insufficient.',
      );
    }
    if (weightConfigurationVersion.trim().isEmpty ||
        gateConfigurationVersion.trim().isEmpty ||
        algorithmVersion.trim().isEmpty) {
      throw StateError('Readiness Index outputs must be versioned.');
    }
  }
}
