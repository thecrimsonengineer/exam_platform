enum EvidenceDebtLevel { none, low, moderate, high, critical }

class EvidenceDebtAssessment {
  const EvidenceDebtAssessment({
    required this.level,
    required this.score,
    required this.reasonCodes,
  });

  final EvidenceDebtLevel level;
  final double score;
  final List<String> reasonCodes;

  Map<String, dynamic> toJson() => {
    'level': level.name,
    'score': score,
    'reasonCodes': reasonCodes,
  };

  factory EvidenceDebtAssessment.fromJson(Map<String, dynamic> json) {
    return EvidenceDebtAssessment(
      level: EvidenceDebtLevel.values.firstWhere(
        (item) => item.name == json['level']?.toString(),
        orElse: () => EvidenceDebtLevel.none,
      ),
      score: _unit(json['score']),
      reasonCodes: _strings(json['reasonCodes']),
    );
  }
}

class LearningPriorityScore {
  const LearningPriorityScore({
    required this.competencyId,
    required this.blueprintImportance,
    required this.masteryGap,
    required this.applicationGap,
    required this.retentionRisk,
    required this.coverageGap,
    required this.evidenceDebt,
    required this.staleness,
    required this.difficultyWeakness,
    required this.examProximity,
    required this.prerequisiteImportance,
    required this.recentStudyPenalty,
    required this.evidenceDebtLevel,
    required this.totalScore,
    required this.reasonCodes,
  });

  final String competencyId;
  final double blueprintImportance;
  final double masteryGap;
  final double applicationGap;
  final double retentionRisk;
  final double coverageGap;
  final double evidenceDebt;
  final double staleness;
  final double difficultyWeakness;
  final double examProximity;
  final double prerequisiteImportance;
  final double recentStudyPenalty;
  final EvidenceDebtLevel evidenceDebtLevel;
  final double totalScore;
  final List<String> reasonCodes;

  Map<String, double> get components => {
    'blueprintImportance': blueprintImportance,
    'masteryGap': masteryGap,
    'applicationGap': applicationGap,
    'retentionRisk': retentionRisk,
    'coverageGap': coverageGap,
    'evidenceDebt': evidenceDebt,
    'staleness': staleness,
    'difficultyWeakness': difficultyWeakness,
    'examProximity': examProximity,
    'prerequisiteImportance': prerequisiteImportance,
    'recentStudyPenalty': recentStudyPenalty,
  };

  Map<String, dynamic> toJson() => {
    'competencyId': competencyId,
    ...components,
    'evidenceDebtLevel': evidenceDebtLevel.name,
    'totalScore': totalScore,
    'reasonCodes': reasonCodes,
  };

  factory LearningPriorityScore.fromJson(Map<String, dynamic> json) {
    return LearningPriorityScore(
      competencyId: json['competencyId']?.toString() ?? '',
      blueprintImportance: _unit(json['blueprintImportance']),
      masteryGap: _unit(json['masteryGap']),
      applicationGap: _unit(json['applicationGap']),
      retentionRisk: _unit(json['retentionRisk']),
      coverageGap: _unit(json['coverageGap']),
      evidenceDebt: _unit(json['evidenceDebt']),
      staleness: _unit(json['staleness']),
      difficultyWeakness: _unit(json['difficultyWeakness']),
      examProximity: _unit(json['examProximity']),
      prerequisiteImportance: _unit(json['prerequisiteImportance']),
      recentStudyPenalty: _unit(json['recentStudyPenalty']),
      evidenceDebtLevel: EvidenceDebtLevel.values.firstWhere(
        (item) => item.name == json['evidenceDebtLevel']?.toString(),
        orElse: () => EvidenceDebtLevel.none,
      ),
      totalScore: _unit(json['totalScore']),
      reasonCodes: _strings(json['reasonCodes']),
    );
  }
}

double _unit(dynamic value) {
  final parsed = value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '') ?? 0.0;
  return parsed.clamp(0.0, 1.0).toDouble();
}

List<String> _strings(dynamic value) {
  if (value is! Iterable) return const <String>[];
  return value
      .map((item) => item?.toString() ?? '')
      .where((item) => item.trim().isNotEmpty)
      .toList(growable: false);
}
