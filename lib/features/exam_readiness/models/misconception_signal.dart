enum MisconceptionSignalType {
  highConfidenceIncorrect,
  repeatedIncorrect,
  applicationReasoning,
  ultraHardDifficulty,
}

class MisconceptionSignal {
  const MisconceptionSignal({
    required this.competencyId,
    required this.type,
    required this.strength,
    required this.sampleCount,
    required this.reasonCodes,
    required this.generatedAt,
  });

  final String competencyId;
  final MisconceptionSignalType type;
  final double strength;
  final int sampleCount;
  final List<String> reasonCodes;
  final DateTime generatedAt;

  Map<String, dynamic> toJson() => {
    'competencyId': competencyId,
    'type': type.name,
    'strength': strength,
    'sampleCount': sampleCount,
    'reasonCodes': reasonCodes,
    'generatedAt': generatedAt.toIso8601String(),
  };

  factory MisconceptionSignal.fromJson(Map<String, dynamic> json) {
    final generatedAt = DateTime.tryParse(
      json['generatedAt']?.toString() ?? '',
    );
    if (generatedAt == null) {
      throw const FormatException('Invalid misconception timestamp.');
    }

    return MisconceptionSignal(
      competencyId: json['competencyId']?.toString() ?? '',
      type: MisconceptionSignalType.values.firstWhere(
        (item) => item.name == json['type']?.toString(),
        orElse: () => MisconceptionSignalType.repeatedIncorrect,
      ),
      strength: _double(json['strength']).clamp(0, 1),
      sampleCount: _int(json['sampleCount']),
      reasonCodes: _strings(json['reasonCodes']),
      generatedAt: generatedAt,
    );
  }
}

int _int(dynamic value) =>
    value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;

double _double(dynamic value) => value is num
    ? value.toDouble()
    : double.tryParse(value?.toString() ?? '') ?? 0;

List<String> _strings(dynamic value) {
  if (value is! Iterable) return const <String>[];
  return value
      .map((item) => item?.toString() ?? '')
      .where((item) => item.trim().isNotEmpty)
      .toList(growable: false);
}
