enum EvidenceConfidence {
  none,
  veryLow,
  low,
  moderate,
  high,
  veryHigh,
}

enum EvidenceState {
  unassessed,
  insufficient,
  emerging,
  adequate,
  robust,
  stale,
}

enum EvidenceRecencyBand {
  noEvidence,
  veryRecent,
  recent,
  aging,
  stale,
  veryStale,
}

extension EvidenceConfidenceX on EvidenceConfidence {
  int get rank => index;

  String get label {
    switch (this) {
      case EvidenceConfidence.none:
        return 'NONE';
      case EvidenceConfidence.veryLow:
        return 'VERY LOW';
      case EvidenceConfidence.low:
        return 'LOW';
      case EvidenceConfidence.moderate:
        return 'MODERATE';
      case EvidenceConfidence.high:
        return 'HIGH';
      case EvidenceConfidence.veryHigh:
        return 'VERY HIGH';
    }
  }
}

class EvidenceConfidenceBreakdown {
  const EvidenceConfidenceBreakdown({
    required this.quantity,
    required this.breadth,
    required this.recency,
    required this.difficulty,
    required this.retention,
    required this.diversity,
    required this.overall,
    required this.repeatedAttemptConcentration,
  });

  final EvidenceConfidence quantity;
  final EvidenceConfidence breadth;
  final EvidenceConfidence recency;
  final EvidenceConfidence difficulty;
  final EvidenceConfidence retention;
  final EvidenceConfidence diversity;
  final EvidenceConfidence overall;
  final double repeatedAttemptConcentration;

  Map<String, dynamic> toJson() {
    return {
      'quantity': quantity.name,
      'breadth': breadth.name,
      'recency': recency.name,
      'difficulty': difficulty.name,
      'retention': retention.name,
      'diversity': diversity.name,
      'overall': overall.name,
      'repeatedAttemptConcentration': repeatedAttemptConcentration,
    };
  }

  factory EvidenceConfidenceBreakdown.fromJson(Map<String, dynamic> json) {
    return EvidenceConfidenceBreakdown(
      quantity: _confidence(json['quantity']),
      breadth: _confidence(json['breadth']),
      recency: _confidence(json['recency']),
      difficulty: _confidence(json['difficulty']),
      retention: _confidence(json['retention']),
      diversity: _confidence(json['diversity']),
      overall: _confidence(json['overall']),
      repeatedAttemptConcentration: _toDouble(
        json['repeatedAttemptConcentration'],
      ),
    );
  }

  static EvidenceConfidence _confidence(dynamic value) {
    final name = value?.toString();
    for (final item in EvidenceConfidence.values) {
      if (item.name == name) {
        return item;
      }
    }
    return EvidenceConfidence.none;
  }
}

double _toDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
