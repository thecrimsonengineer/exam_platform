enum ReadinessGapType {
  masteryGap,
  applicationGap,
  retentionGap,
  coverageGap,
  evidenceGap,
  difficultyGap,
  confidenceGap,
  stalenessGap,
}

enum ReadinessGapSeverity { low, moderate, high, critical }

class ReadinessGap {
  const ReadinessGap({
    required this.type,
    required this.severity,
    required this.competencyId,
    required this.reasonCode,
    required this.explanation,
    required this.evidenceLimited,
  });

  final ReadinessGapType type;
  final ReadinessGapSeverity severity;
  final String competencyId;
  final String reasonCode;
  final String explanation;
  final bool evidenceLimited;

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'severity': severity.name,
    'competencyId': competencyId,
    'reasonCode': reasonCode,
    'explanation': explanation,
    'evidenceLimited': evidenceLimited,
  };

  factory ReadinessGap.fromJson(Map<String, dynamic> json) {
    return ReadinessGap(
      type: _gapType(json['type']),
      severity: _gapSeverity(json['severity']),
      competencyId: json['competencyId']?.toString() ?? '',
      reasonCode: json['reasonCode']?.toString() ?? '',
      explanation: json['explanation']?.toString() ?? '',
      evidenceLimited: json['evidenceLimited'] == true,
    );
  }
}

ReadinessGapType _gapType(dynamic value) {
  final name = value?.toString();
  return ReadinessGapType.values.firstWhere(
    (item) => item.name == name,
    orElse: () => ReadinessGapType.evidenceGap,
  );
}

ReadinessGapSeverity _gapSeverity(dynamic value) {
  final name = value?.toString();
  return ReadinessGapSeverity.values.firstWhere(
    (item) => item.name == name,
    orElse: () => ReadinessGapSeverity.low,
  );
}
