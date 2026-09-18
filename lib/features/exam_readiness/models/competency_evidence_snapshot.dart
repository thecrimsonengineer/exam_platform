import 'evidence_confidence.dart';

class EvidenceCoverage {
  const EvidenceCoverage({
    required this.topicsAvailable,
    required this.topicsAssessed,
    required this.subtopicsAvailable,
    required this.subtopicsAssessed,
  });

  final int topicsAvailable;
  final int topicsAssessed;
  final int subtopicsAvailable;
  final int subtopicsAssessed;

  double get coverageRatio {
    if (subtopicsAvailable > 0) {
      return (subtopicsAssessed / subtopicsAvailable).clamp(0, 1);
    }
    if (topicsAvailable > 0) {
      return (topicsAssessed / topicsAvailable).clamp(0, 1);
    }
    return 0;
  }

  Map<String, dynamic> toJson() => {
    'topicsAvailable': topicsAvailable,
    'topicsAssessed': topicsAssessed,
    'subtopicsAvailable': subtopicsAvailable,
    'subtopicsAssessed': subtopicsAssessed,
    'coverageRatio': coverageRatio,
  };

  factory EvidenceCoverage.fromJson(Map<String, dynamic> json) {
    return EvidenceCoverage(
      topicsAvailable: _int(json['topicsAvailable']),
      topicsAssessed: _int(json['topicsAssessed']),
      subtopicsAvailable: _int(json['subtopicsAvailable']),
      subtopicsAssessed: _int(json['subtopicsAssessed']),
    );
  }
}

class AttemptEvidenceStats {
  const AttemptEvidenceStats({
    required this.total,
    required this.correct,
    required this.incorrect,
    required this.uniqueQuestions,
    required this.repeatedAttempts,
  });

  final int total;
  final int correct;
  final int incorrect;
  final int uniqueQuestions;
  final int repeatedAttempts;

  double? get accuracy => total == 0 ? null : correct / total;

  Map<String, dynamic> toJson() => {
    'total': total,
    'correct': correct,
    'incorrect': incorrect,
    'uniqueQuestions': uniqueQuestions,
    'repeatedAttempts': repeatedAttempts,
  };

  factory AttemptEvidenceStats.fromJson(Map<String, dynamic> json) {
    return AttemptEvidenceStats(
      total: _int(json['total']),
      correct: _int(json['correct']),
      incorrect: _int(json['incorrect']),
      uniqueQuestions: _int(json['uniqueQuestions']),
      repeatedAttempts: _int(json['repeatedAttempts']),
    );
  }
}

class CognitionEvidenceStats {
  const CognitionEvidenceStats({
    required this.recallAttempts,
    required this.recallCorrect,
    required this.applicationAttempts,
    required this.applicationCorrect,
    required this.analysisAttempts,
    required this.analysisCorrect,
  });

  final int recallAttempts;
  final int recallCorrect;
  final int applicationAttempts;
  final int applicationCorrect;
  final int analysisAttempts;
  final int analysisCorrect;

  double? get recallAccuracy =>
      recallAttempts == 0 ? null : recallCorrect / recallAttempts;
  double? get applicationAccuracy => applicationAttempts == 0
      ? null
      : applicationCorrect / applicationAttempts;
  double? get analysisAccuracy =>
      analysisAttempts == 0 ? null : analysisCorrect / analysisAttempts;

  int get activeLanes => [
    recallAttempts,
    applicationAttempts,
    analysisAttempts,
  ].where((count) => count > 0).length;

  Map<String, dynamic> toJson() => {
    'recallAttempts': recallAttempts,
    'recallCorrect': recallCorrect,
    'applicationAttempts': applicationAttempts,
    'applicationCorrect': applicationCorrect,
    'analysisAttempts': analysisAttempts,
    'analysisCorrect': analysisCorrect,
  };

  factory CognitionEvidenceStats.fromJson(Map<String, dynamic> json) {
    return CognitionEvidenceStats(
      recallAttempts: _int(json['recallAttempts']),
      recallCorrect: _int(json['recallCorrect']),
      applicationAttempts: _int(json['applicationAttempts']),
      applicationCorrect: _int(json['applicationCorrect']),
      analysisAttempts: _int(json['analysisAttempts']),
      analysisCorrect: _int(json['analysisCorrect']),
    );
  }
}

class DifficultyEvidenceStats {
  const DifficultyEvidenceStats({
    required this.standardAttempts,
    required this.standardCorrect,
    required this.hardAttempts,
    required this.hardCorrect,
    required this.ultraHardAttempts,
    required this.ultraHardCorrect,
  });

  final int standardAttempts;
  final int standardCorrect;
  final int hardAttempts;
  final int hardCorrect;
  final int ultraHardAttempts;
  final int ultraHardCorrect;

  double? get standardAccuracy =>
      standardAttempts == 0 ? null : standardCorrect / standardAttempts;
  double? get hardAccuracy =>
      hardAttempts == 0 ? null : hardCorrect / hardAttempts;
  double? get ultraHardAccuracy =>
      ultraHardAttempts == 0 ? null : ultraHardCorrect / ultraHardAttempts;

  int get activeLanes => [
    standardAttempts,
    hardAttempts,
    ultraHardAttempts,
  ].where((count) => count > 0).length;

  Map<String, dynamic> toJson() => {
    'standardAttempts': standardAttempts,
    'standardCorrect': standardCorrect,
    'hardAttempts': hardAttempts,
    'hardCorrect': hardCorrect,
    'ultraHardAttempts': ultraHardAttempts,
    'ultraHardCorrect': ultraHardCorrect,
  };

  factory DifficultyEvidenceStats.fromJson(Map<String, dynamic> json) {
    return DifficultyEvidenceStats(
      standardAttempts: _int(json['standardAttempts']),
      standardCorrect: _int(json['standardCorrect']),
      hardAttempts: _int(json['hardAttempts']),
      hardCorrect: _int(json['hardCorrect']),
      ultraHardAttempts: _int(json['ultraHardAttempts']),
      ultraHardCorrect: _int(json['ultraHardCorrect']),
    );
  }
}

class RetentionEvidenceStats {
  const RetentionEvidenceStats({
    required this.delayedAttempts,
    required this.delayedCorrect,
    required this.immediateAttempts,
    required this.shortDelayAttempts,
    required this.mediumDelayAttempts,
    required this.longDelayAttempts,
    required this.lastReviewedAt,
    required this.daysSinceReview,
  });

  final int delayedAttempts;
  final int delayedCorrect;
  final int immediateAttempts;
  final int shortDelayAttempts;
  final int mediumDelayAttempts;
  final int longDelayAttempts;
  final DateTime? lastReviewedAt;
  final int? daysSinceReview;

  double? get delayedAccuracy =>
      delayedAttempts == 0 ? null : delayedCorrect / delayedAttempts;

  Map<String, dynamic> toJson() => {
    'delayedAttempts': delayedAttempts,
    'delayedCorrect': delayedCorrect,
    'immediateAttempts': immediateAttempts,
    'shortDelayAttempts': shortDelayAttempts,
    'mediumDelayAttempts': mediumDelayAttempts,
    'longDelayAttempts': longDelayAttempts,
    'lastReviewedAt': lastReviewedAt?.toIso8601String(),
    'daysSinceReview': daysSinceReview,
  };

  factory RetentionEvidenceStats.fromJson(Map<String, dynamic> json) {
    return RetentionEvidenceStats(
      delayedAttempts: _int(json['delayedAttempts']),
      delayedCorrect: _int(json['delayedCorrect']),
      immediateAttempts: _int(json['immediateAttempts']),
      shortDelayAttempts: _int(json['shortDelayAttempts']),
      mediumDelayAttempts: _int(json['mediumDelayAttempts']),
      longDelayAttempts: _int(json['longDelayAttempts']),
      lastReviewedAt: DateTime.tryParse(
        json['lastReviewedAt']?.toString() ?? '',
      ),
      daysSinceReview: json['daysSinceReview'] == null
          ? null
          : _int(json['daysSinceReview']),
    );
  }
}

class ConfidenceCalibrationStats {
  const ConfidenceCalibrationStats({
    required this.confidenceSamples,
    required this.calibrationError,
    required this.overconfidenceRate,
    required this.underconfidenceRate,
    required this.highConfidenceIncorrectCount,
  });

  final int confidenceSamples;
  final double? calibrationError;
  final double? overconfidenceRate;
  final double? underconfidenceRate;
  final int highConfidenceIncorrectCount;

  Map<String, dynamic> toJson() => {
    'confidenceSamples': confidenceSamples,
    'calibrationError': calibrationError,
    'overconfidenceRate': overconfidenceRate,
    'underconfidenceRate': underconfidenceRate,
    'highConfidenceIncorrectCount': highConfidenceIncorrectCount,
  };

  factory ConfidenceCalibrationStats.fromJson(Map<String, dynamic> json) {
    return ConfidenceCalibrationStats(
      confidenceSamples: _int(json['confidenceSamples']),
      calibrationError: _nullableDouble(json['calibrationError']),
      overconfidenceRate: _nullableDouble(json['overconfidenceRate']),
      underconfidenceRate: _nullableDouble(json['underconfidenceRate']),
      highConfidenceIncorrectCount: _int(json['highConfidenceIncorrectCount']),
    );
  }
}

class RecencyEvidenceStats {
  const RecencyEvidenceStats({
    required this.attempts7d,
    required this.attempts30d,
    required this.lastAttemptAt,
    required this.band,
  });

  final int attempts7d;
  final int attempts30d;
  final DateTime? lastAttemptAt;
  final EvidenceRecencyBand band;

  Map<String, dynamic> toJson() => {
    'attempts7d': attempts7d,
    'attempts30d': attempts30d,
    'lastAttemptAt': lastAttemptAt?.toIso8601String(),
    'band': band.name,
  };

  factory RecencyEvidenceStats.fromJson(Map<String, dynamic> json) {
    return RecencyEvidenceStats(
      attempts7d: _int(json['attempts7d']),
      attempts30d: _int(json['attempts30d']),
      lastAttemptAt: DateTime.tryParse(json['lastAttemptAt']?.toString() ?? ''),
      band: _recencyBand(json['band']),
    );
  }
}

class EvidenceQualitySnapshot {
  const EvidenceQualitySnapshot({
    required this.quantity,
    required this.breadth,
    required this.recency,
    required this.diversity,
    required this.confidenceLevel,
    required this.breakdown,
    required this.state,
  });

  final EvidenceConfidence quantity;
  final EvidenceConfidence breadth;
  final EvidenceConfidence recency;
  final EvidenceConfidence diversity;
  final EvidenceConfidence confidenceLevel;
  final EvidenceConfidenceBreakdown breakdown;
  final EvidenceState state;

  Map<String, dynamic> toJson() => {
    'quantity': quantity.name,
    'breadth': breadth.name,
    'recency': recency.name,
    'diversity': diversity.name,
    'confidenceLevel': confidenceLevel.name,
    'breakdown': breakdown.toJson(),
    'state': state.name,
  };

  factory EvidenceQualitySnapshot.fromJson(Map<String, dynamic> json) {
    return EvidenceQualitySnapshot(
      quantity: _confidence(json['quantity']),
      breadth: _confidence(json['breadth']),
      recency: _confidence(json['recency']),
      diversity: _confidence(json['diversity']),
      confidenceLevel: _confidence(json['confidenceLevel']),
      breakdown: EvidenceConfidenceBreakdown.fromJson(_map(json['breakdown'])),
      state: _state(json['state']),
    );
  }
}

class CompetencyEvidenceSnapshot {
  const CompetencyEvidenceSnapshot({
    required this.competencyId,
    required this.generatedAt,
    required this.schemaVersion,
    required this.algorithmVersion,
    required this.sourceAttemptCount,
    required this.coverage,
    required this.attempts,
    required this.cognition,
    required this.difficulty,
    required this.retention,
    required this.confidence,
    required this.recency,
    required this.evidenceQuality,
    required this.traceability,
  });

  static const int currentSchemaVersion = 1;
  static const String currentAlgorithmVersion = 'm7b-v1';

  final String competencyId;
  final DateTime generatedAt;
  final int schemaVersion;
  final String algorithmVersion;
  final int sourceAttemptCount;
  final EvidenceCoverage coverage;
  final AttemptEvidenceStats attempts;
  final CognitionEvidenceStats cognition;
  final DifficultyEvidenceStats difficulty;
  final RetentionEvidenceStats retention;
  final ConfidenceCalibrationStats confidence;
  final RecencyEvidenceStats recency;
  final EvidenceQualitySnapshot evidenceQuality;
  final List<String> traceability;

  Map<String, dynamic> toJson() => {
    'competencyId': competencyId,
    'generatedAt': generatedAt.toIso8601String(),
    'schemaVersion': schemaVersion,
    'algorithmVersion': algorithmVersion,
    'sourceAttemptCount': sourceAttemptCount,
    'coverage': coverage.toJson(),
    'attempts': attempts.toJson(),
    'cognition': cognition.toJson(),
    'difficulty': difficulty.toJson(),
    'retention': retention.toJson(),
    'confidence': confidence.toJson(),
    'recency': recency.toJson(),
    'evidenceQuality': evidenceQuality.toJson(),
    'traceability': traceability,
  };

  factory CompetencyEvidenceSnapshot.fromJson(Map<String, dynamic> json) {
    final generatedAt = DateTime.tryParse(
      json['generatedAt']?.toString() ?? '',
    );
    if (generatedAt == null) {
      throw const FormatException('Invalid evidence snapshot timestamp.');
    }

    return CompetencyEvidenceSnapshot(
      competencyId: json['competencyId']?.toString() ?? '',
      generatedAt: generatedAt,
      schemaVersion: _int(
        json['schemaVersion'],
        fallback: currentSchemaVersion,
      ),
      algorithmVersion:
          json['algorithmVersion']?.toString() ?? currentAlgorithmVersion,
      sourceAttemptCount: _int(json['sourceAttemptCount']),
      coverage: EvidenceCoverage.fromJson(_map(json['coverage'])),
      attempts: AttemptEvidenceStats.fromJson(_map(json['attempts'])),
      cognition: CognitionEvidenceStats.fromJson(_map(json['cognition'])),
      difficulty: DifficultyEvidenceStats.fromJson(_map(json['difficulty'])),
      retention: RetentionEvidenceStats.fromJson(_map(json['retention'])),
      confidence: ConfidenceCalibrationStats.fromJson(_map(json['confidence'])),
      recency: RecencyEvidenceStats.fromJson(_map(json['recency'])),
      evidenceQuality: EvidenceQualitySnapshot.fromJson(
        _map(json['evidenceQuality']),
      ),
      traceability: (json['traceability'] is List)
          ? (json['traceability'] as List)
                .map((item) => item.toString())
                .toList(growable: false)
          : const [],
    );
  }
}

Map<String, dynamic> _map(dynamic value) {
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return <String, dynamic>{};
}

int _int(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double? _nullableDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

EvidenceConfidence _confidence(dynamic value) {
  final name = value?.toString();
  return EvidenceConfidence.values.firstWhere(
    (item) => item.name == name,
    orElse: () => EvidenceConfidence.none,
  );
}

EvidenceState _state(dynamic value) {
  final name = value?.toString();
  return EvidenceState.values.firstWhere(
    (item) => item.name == name,
    orElse: () => EvidenceState.unassessed,
  );
}

EvidenceRecencyBand _recencyBand(dynamic value) {
  final name = value?.toString();
  return EvidenceRecencyBand.values.firstWhere(
    (item) => item.name == name,
    orElse: () => EvidenceRecencyBand.noEvidence,
  );
}
