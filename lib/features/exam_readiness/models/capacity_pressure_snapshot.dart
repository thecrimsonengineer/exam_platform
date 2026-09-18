import 'exam_preparation_phase.dart';

enum CapacityPressureState {
  low,
  manageable,
  elevated,
  high,
  critical,
}

class CapacityPressureSnapshot {
  const CapacityPressureSnapshot({
    required this.generatedAt,
    required this.phase,
    required this.availableMinutes,
    required this.estimatedPriorityWorkloadMinMinutes,
    required this.estimatedPriorityWorkloadMaxMinutes,
    required this.state,
    required this.criticalGapCount,
    required this.highGapCount,
    required this.evidenceBlindSpotCount,
    required this.scheduledReviewDebtMinutes,
    required this.reasonCodes,
    required this.algorithmVersion,
    required this.schemaVersion,
  });

  static const int currentSchemaVersion = 1;

  final DateTime generatedAt;
  final ExamPreparationPhase phase;
  final int availableMinutes;
  final int estimatedPriorityWorkloadMinMinutes;
  final int estimatedPriorityWorkloadMaxMinutes;
  final CapacityPressureState state;
  final int criticalGapCount;
  final int highGapCount;
  final int evidenceBlindSpotCount;
  final int scheduledReviewDebtMinutes;
  final List<String> reasonCodes;
  final String algorithmVersion;
  final int schemaVersion;

  double get availableHours => availableMinutes / 60;
  double get estimatedPriorityWorkloadMinHours =>
      estimatedPriorityWorkloadMinMinutes / 60;
  double get estimatedPriorityWorkloadMaxHours =>
      estimatedPriorityWorkloadMaxMinutes / 60;

  bool get demandExceedsCapacity =>
      estimatedPriorityWorkloadMinMinutes > availableMinutes;

  void validate() {
    if (availableMinutes < 0 ||
        estimatedPriorityWorkloadMinMinutes < 0 ||
        estimatedPriorityWorkloadMaxMinutes <
            estimatedPriorityWorkloadMinMinutes ||
        criticalGapCount < 0 ||
        highGapCount < 0 ||
        evidenceBlindSpotCount < 0 ||
        scheduledReviewDebtMinutes < 0) {
      throw StateError('Capacity pressure snapshot contains invalid values.');
    }
    if (algorithmVersion.trim().isEmpty) {
      throw StateError('Capacity pressure algorithm must be versioned.');
    }
  }

  Map<String, dynamic> toJson() => {
        'generatedAt': generatedAt.toIso8601String(),
        'phase': phase.name,
        'availableMinutes': availableMinutes,
        'estimatedPriorityWorkloadMinMinutes':
            estimatedPriorityWorkloadMinMinutes,
        'estimatedPriorityWorkloadMaxMinutes':
            estimatedPriorityWorkloadMaxMinutes,
        'state': state.name,
        'criticalGapCount': criticalGapCount,
        'highGapCount': highGapCount,
        'evidenceBlindSpotCount': evidenceBlindSpotCount,
        'scheduledReviewDebtMinutes': scheduledReviewDebtMinutes,
        'reasonCodes': reasonCodes,
        'algorithmVersion': algorithmVersion,
        'schemaVersion': schemaVersion,
      };

  factory CapacityPressureSnapshot.fromJson(Map<String, dynamic> json) {
    final generatedAt =
        DateTime.tryParse(json['generatedAt']?.toString() ?? '');
    if (generatedAt == null) {
      throw const FormatException('Invalid capacity pressure timestamp.');
    }

    return CapacityPressureSnapshot(
      generatedAt: generatedAt,
      phase: _phase(json['phase']),
      availableMinutes: _asInt(json['availableMinutes']),
      estimatedPriorityWorkloadMinMinutes:
          _asInt(json['estimatedPriorityWorkloadMinMinutes']),
      estimatedPriorityWorkloadMaxMinutes:
          _asInt(json['estimatedPriorityWorkloadMaxMinutes']),
      state: _state(json['state']),
      criticalGapCount: _asInt(json['criticalGapCount']),
      highGapCount: _asInt(json['highGapCount']),
      evidenceBlindSpotCount: _asInt(json['evidenceBlindSpotCount']),
      scheduledReviewDebtMinutes:
          _asInt(json['scheduledReviewDebtMinutes']),
      reasonCodes: _strings(json['reasonCodes']),
      algorithmVersion: json['algorithmVersion']?.toString() ?? '',
      schemaVersion: _asInt(
        json['schemaVersion'],
        fallback: currentSchemaVersion,
      ),
    );
  }
}

ExamPreparationPhase _phase(dynamic value) {
  final name = value?.toString();
  return ExamPreparationPhase.values.firstWhere(
    (item) => item.name == name,
    orElse: () => ExamPreparationPhase.foundation,
  );
}

CapacityPressureState _state(dynamic value) {
  final name = value?.toString();
  return CapacityPressureState.values.firstWhere(
    (item) => item.name == name,
    orElse: () => CapacityPressureState.low,
  );
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

List<String> _strings(dynamic value) {
  if (value is! List) return const <String>[];
  return value.map((item) => item.toString()).toList(growable: false);
}
