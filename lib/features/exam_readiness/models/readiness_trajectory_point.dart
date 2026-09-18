import 'evidence_confidence.dart';

class ReadinessTrajectoryPoint {
  const ReadinessTrajectoryPoint({
    required this.date,
    required this.knowledge,
    required this.application,
    required this.retention,
    required this.coverage,
    required this.difficulty,
    required this.evidenceConfidence,
    required this.algorithmVersion,
  });

  final DateTime date;
  final double? knowledge;
  final double? application;
  final double? retention;
  final double? coverage;
  final double? difficulty;
  final EvidenceConfidence evidenceConfidence;
  final String algorithmVersion;

  Map<String, dynamic> toJson() => {
    'date': DateTime(date.year, date.month, date.day).toIso8601String(),
    'knowledge': knowledge,
    'application': application,
    'retention': retention,
    'coverage': coverage,
    'difficulty': difficulty,
    'evidenceConfidence': evidenceConfidence.name,
    'algorithmVersion': algorithmVersion,
  };

  factory ReadinessTrajectoryPoint.fromJson(Map<String, dynamic> json) {
    final date = DateTime.tryParse(json['date']?.toString() ?? '');
    if (date == null) {
      throw const FormatException('Invalid readiness trajectory date.');
    }

    return ReadinessTrajectoryPoint(
      date: DateTime(date.year, date.month, date.day),
      knowledge: _nullableUnit(json['knowledge']),
      application: _nullableUnit(json['application']),
      retention: _nullableUnit(json['retention']),
      coverage: _nullableUnit(json['coverage']),
      difficulty: _nullableUnit(json['difficulty']),
      evidenceConfidence: _confidence(json['evidenceConfidence']),
      algorithmVersion: json['algorithmVersion']?.toString() ?? '',
    );
  }
}

enum ReadinessTrendDirection { unavailable, declining, stable, improving }

class ReadinessDimensionTrend {
  const ReadinessDimensionTrend({
    required this.startValue,
    required this.endValue,
    required this.delta,
    required this.direction,
  });

  final double? startValue;
  final double? endValue;
  final double? delta;
  final ReadinessTrendDirection direction;
}

class ReadinessTrajectorySummary {
  const ReadinessTrajectorySummary({
    required this.startDate,
    required this.endDate,
    required this.windowDays,
    required this.knowledge,
    required this.application,
    required this.retention,
    required this.coverage,
    required this.difficulty,
    required this.latestEvidenceConfidence,
    required this.algorithmVersion,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final int windowDays;
  final ReadinessDimensionTrend knowledge;
  final ReadinessDimensionTrend application;
  final ReadinessDimensionTrend retention;
  final ReadinessDimensionTrend coverage;
  final ReadinessDimensionTrend difficulty;
  final EvidenceConfidence latestEvidenceConfidence;
  final String algorithmVersion;

  bool get hasMeaningfulWindow => startDate != null && endDate != null;
}

double? _nullableUnit(dynamic value) {
  if (value == null) return null;
  final parsed = value is num
      ? value.toDouble()
      : double.tryParse(value.toString());
  return parsed?.clamp(0.0, 1.0).toDouble();
}

EvidenceConfidence _confidence(dynamic value) {
  final name = value?.toString();
  return EvidenceConfidence.values.firstWhere(
    (item) => item.name == name,
    orElse: () => EvidenceConfidence.none,
  );
}
