import 'evidence_confidence.dart';
import 'readiness_gap.dart';

enum ReadinessState {
  unknown,
  insufficientEvidence,
  learning,
  developing,
  provisional,
  strong,
  stable,
  atRisk,
  stale,
}

enum ConfidenceCalibrationState { unavailable, good, watch, needsAttention }

enum DifficultyReadinessState { unavailable, emerging, developing, strong }

class ReadinessDimension {
  const ReadinessDimension({
    required this.code,
    required this.value,
    required this.evidenceConfidence,
    this.reasonCodes = const <String>[],
  });

  final String code;
  final double? value;
  final EvidenceConfidence evidenceConfidence;
  final List<String> reasonCodes;

  bool get isAvailable => value != null;

  int? get percent => value == null ? null : (value!.clamp(0, 1) * 100).round();

  Map<String, dynamic> toJson() => {
    'code': code,
    'value': value,
    'evidenceConfidence': evidenceConfidence.name,
    'reasonCodes': reasonCodes,
  };

  factory ReadinessDimension.fromJson(Map<String, dynamic> json) {
    return ReadinessDimension(
      code: json['code']?.toString() ?? '',
      value: _nullableDouble(json['value']),
      evidenceConfidence: _confidence(json['evidenceConfidence']),
      reasonCodes: _strings(json['reasonCodes']),
    );
  }
}

class DifficultyReadinessProfile {
  const DifficultyReadinessProfile({
    required this.standardAccuracy,
    required this.hardAccuracy,
    required this.ultraHardAccuracy,
    required this.dimension,
    required this.state,
  });

  final double? standardAccuracy;
  final double? hardAccuracy;
  final double? ultraHardAccuracy;
  final ReadinessDimension dimension;
  final DifficultyReadinessState state;

  Map<String, dynamic> toJson() => {
    'standardAccuracy': standardAccuracy,
    'hardAccuracy': hardAccuracy,
    'ultraHardAccuracy': ultraHardAccuracy,
    'dimension': dimension.toJson(),
    'state': state.name,
  };

  factory DifficultyReadinessProfile.fromJson(Map<String, dynamic> json) {
    return DifficultyReadinessProfile(
      standardAccuracy: _nullableDouble(json['standardAccuracy']),
      hardAccuracy: _nullableDouble(json['hardAccuracy']),
      ultraHardAccuracy: _nullableDouble(json['ultraHardAccuracy']),
      dimension: ReadinessDimension.fromJson(_map(json['dimension'])),
      state: _difficultyState(json['state']),
    );
  }
}

class CompetencyReadinessProfile {
  const CompetencyReadinessProfile({
    required this.competencyId,
    required this.generatedAt,
    required this.readinessAlgorithmVersion,
    required this.knowledgeMastery,
    required this.applicationAbility,
    required this.retention,
    required this.difficultyPerformance,
    required this.blueprintCoverage,
    required this.confidenceCalibration,
    required this.recentPerformance,
    required this.stability,
    required this.evidenceConfidence,
    required this.readinessState,
    required this.gaps,
    required this.limitingFactors,
    required this.explanationCodes,
  });

  static const String currentAlgorithmVersion = 'm7c-v1';

  final String competencyId;
  final DateTime generatedAt;
  final String readinessAlgorithmVersion;
  final ReadinessDimension knowledgeMastery;
  final ReadinessDimension applicationAbility;
  final ReadinessDimension retention;
  final DifficultyReadinessProfile difficultyPerformance;
  final ReadinessDimension blueprintCoverage;
  final ReadinessDimension confidenceCalibration;
  final ReadinessDimension recentPerformance;
  final ReadinessDimension stability;
  final EvidenceConfidence evidenceConfidence;
  final ReadinessState readinessState;
  final List<ReadinessGap> gaps;
  final List<String> limitingFactors;
  final List<String> explanationCodes;

  bool get hasCriticalGap =>
      gaps.any((gap) => gap.severity == ReadinessGapSeverity.critical);

  bool get hasEvidenceGap =>
      gaps.any((gap) => gap.type == ReadinessGapType.evidenceGap);

  Map<String, dynamic> toJson() => {
    'competencyId': competencyId,
    'generatedAt': generatedAt.toIso8601String(),
    'readinessAlgorithmVersion': readinessAlgorithmVersion,
    'knowledgeMastery': knowledgeMastery.toJson(),
    'applicationAbility': applicationAbility.toJson(),
    'retention': retention.toJson(),
    'difficultyPerformance': difficultyPerformance.toJson(),
    'blueprintCoverage': blueprintCoverage.toJson(),
    'confidenceCalibration': confidenceCalibration.toJson(),
    'recentPerformance': recentPerformance.toJson(),
    'stability': stability.toJson(),
    'evidenceConfidence': evidenceConfidence.name,
    'readinessState': readinessState.name,
    'gaps': gaps.map((gap) => gap.toJson()).toList(growable: false),
    'limitingFactors': limitingFactors,
    'explanationCodes': explanationCodes,
  };

  factory CompetencyReadinessProfile.fromJson(Map<String, dynamic> json) {
    final generatedAt = DateTime.tryParse(
      json['generatedAt']?.toString() ?? '',
    );
    if (generatedAt == null) {
      throw const FormatException('Invalid readiness profile timestamp.');
    }

    return CompetencyReadinessProfile(
      competencyId: json['competencyId']?.toString() ?? '',
      generatedAt: generatedAt,
      readinessAlgorithmVersion:
          json['readinessAlgorithmVersion']?.toString() ??
          currentAlgorithmVersion,
      knowledgeMastery: ReadinessDimension.fromJson(
        _map(json['knowledgeMastery']),
      ),
      applicationAbility: ReadinessDimension.fromJson(
        _map(json['applicationAbility']),
      ),
      retention: ReadinessDimension.fromJson(_map(json['retention'])),
      difficultyPerformance: DifficultyReadinessProfile.fromJson(
        _map(json['difficultyPerformance']),
      ),
      blueprintCoverage: ReadinessDimension.fromJson(
        _map(json['blueprintCoverage']),
      ),
      confidenceCalibration: ReadinessDimension.fromJson(
        _map(json['confidenceCalibration']),
      ),
      recentPerformance: ReadinessDimension.fromJson(
        _map(json['recentPerformance']),
      ),
      stability: ReadinessDimension.fromJson(_map(json['stability'])),
      evidenceConfidence: _confidence(json['evidenceConfidence']),
      readinessState: _readinessState(json['readinessState']),
      gaps: (json['gaps'] is List)
          ? (json['gaps'] as List)
                .whereType<Map>()
                .map(
                  (item) =>
                      ReadinessGap.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList(growable: false)
          : const <ReadinessGap>[],
      limitingFactors: _strings(json['limitingFactors']),
      explanationCodes: _strings(json['explanationCodes']),
    );
  }
}

class BlueprintCoverageSummary {
  const BlueprintCoverageSummary({
    required this.competenciesTotal,
    required this.competenciesAssessed,
    required this.topicsTotal,
    required this.topicsAssessed,
    required this.subtopicsTotal,
    required this.subtopicsAssessed,
  });

  final int competenciesTotal;
  final int competenciesAssessed;
  final int topicsTotal;
  final int topicsAssessed;
  final int subtopicsTotal;
  final int subtopicsAssessed;

  double get ratio {
    if (subtopicsTotal > 0) {
      return (subtopicsAssessed / subtopicsTotal).clamp(0, 1);
    }
    if (topicsTotal > 0) {
      return (topicsAssessed / topicsTotal).clamp(0, 1);
    }
    if (competenciesTotal > 0) {
      return (competenciesAssessed / competenciesTotal).clamp(0, 1);
    }
    return 0;
  }

  int get percent => (ratio * 100).round();
}

class ExamReadinessDashboard {
  const ExamReadinessDashboard({
    required this.generatedAt,
    required this.algorithmVersion,
    required this.evidenceConfidence,
    required this.knowledgeMastery,
    required this.applicationAbility,
    required this.retention,
    required this.blueprintCoverage,
    required this.difficultyPerformance,
    required this.confidenceCalibration,
    required this.criticalGapCount,
    required this.weakCompetencyCount,
    required this.evidenceGapCount,
    required this.staleCompetencyCount,
    required this.profiles,
    required this.domainCoverage,
  });

  final DateTime generatedAt;
  final String algorithmVersion;
  final EvidenceConfidence evidenceConfidence;
  final ReadinessDimension knowledgeMastery;
  final ReadinessDimension applicationAbility;
  final ReadinessDimension retention;
  final BlueprintCoverageSummary blueprintCoverage;
  final ReadinessDimension difficultyPerformance;
  final ReadinessDimension confidenceCalibration;
  final int criticalGapCount;
  final int weakCompetencyCount;
  final int evidenceGapCount;
  final int staleCompetencyCount;
  final Map<String, CompetencyReadinessProfile> profiles;
  final Map<String, BlueprintCoverageSummary> domainCoverage;

  bool get hasCompositeReadinessIndex => false;
}

Map<String, dynamic> _map(dynamic value) {
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return <String, dynamic>{};
}

List<String> _strings(dynamic value) {
  if (value is! List) return const <String>[];
  return value.map((item) => item.toString()).toList(growable: false);
}

double? _nullableDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble().clamp(0, 1);
  final parsed = double.tryParse(value.toString());
  return parsed?.clamp(0, 1);
}

EvidenceConfidence _confidence(dynamic value) {
  final name = value?.toString();
  return EvidenceConfidence.values.firstWhere(
    (item) => item.name == name,
    orElse: () => EvidenceConfidence.none,
  );
}

ReadinessState _readinessState(dynamic value) {
  final name = value?.toString();
  return ReadinessState.values.firstWhere(
    (item) => item.name == name,
    orElse: () => ReadinessState.unknown,
  );
}

DifficultyReadinessState _difficultyState(dynamic value) {
  final name = value?.toString();
  return DifficultyReadinessState.values.firstWhere(
    (item) => item.name == name,
    orElse: () => DifficultyReadinessState.unavailable,
  );
}
