import 'plan_regeneration_reason.dart';

class LearningStateUpdateEvent {
  const LearningStateUpdateEvent({
    required this.eventId,
    required this.outcomeId,
    required this.competencyId,
    required this.occurredAt,
    required this.regenerationReason,
    required this.previousReadinessState,
    required this.nextReadinessState,
    required this.previousKnowledge,
    required this.nextKnowledge,
    required this.previousApplication,
    required this.nextApplication,
    required this.previousRetention,
    required this.nextRetention,
    required this.stalePlanVersionsCreated,
    required this.misconceptionCodes,
    required this.reasonCodes,
    this.schemaVersion = currentSchemaVersion,
  });

  static const int currentSchemaVersion = 1;

  final String eventId;
  final String outcomeId;
  final String competencyId;
  final DateTime occurredAt;
  final PlanRegenerationReason regenerationReason;
  final String? previousReadinessState;
  final String nextReadinessState;
  final double? previousKnowledge;
  final double? nextKnowledge;
  final double? previousApplication;
  final double? nextApplication;
  final double? previousRetention;
  final double? nextRetention;
  final int stalePlanVersionsCreated;
  final List<String> misconceptionCodes;
  final List<String> reasonCodes;
  final int schemaVersion;

  Map<String, dynamic> toJson() => {
    'eventId': eventId,
    'outcomeId': outcomeId,
    'competencyId': competencyId,
    'occurredAt': occurredAt.toIso8601String(),
    'regenerationReason': regenerationReason.name,
    'previousReadinessState': previousReadinessState,
    'nextReadinessState': nextReadinessState,
    'previousKnowledge': previousKnowledge,
    'nextKnowledge': nextKnowledge,
    'previousApplication': previousApplication,
    'nextApplication': nextApplication,
    'previousRetention': previousRetention,
    'nextRetention': nextRetention,
    'stalePlanVersionsCreated': stalePlanVersionsCreated,
    'misconceptionCodes': misconceptionCodes,
    'reasonCodes': reasonCodes,
    'schemaVersion': schemaVersion,
  };

  factory LearningStateUpdateEvent.fromJson(Map<String, dynamic> json) {
    final occurredAt = DateTime.tryParse(json['occurredAt']?.toString() ?? '');
    if (occurredAt == null) {
      throw const FormatException('Invalid learning-state event timestamp.');
    }

    return LearningStateUpdateEvent(
      eventId: json['eventId']?.toString() ?? '',
      outcomeId: json['outcomeId']?.toString() ?? '',
      competencyId: json['competencyId']?.toString() ?? '',
      occurredAt: occurredAt,
      regenerationReason: PlanRegenerationReason.values.firstWhere(
        (item) => item.name == json['regenerationReason']?.toString(),
        orElse: () => PlanRegenerationReason.assessmentCompleted,
      ),
      previousReadinessState: json['previousReadinessState']?.toString(),
      nextReadinessState: json['nextReadinessState']?.toString() ?? '',
      previousKnowledge: _nullableDouble(json['previousKnowledge']),
      nextKnowledge: _nullableDouble(json['nextKnowledge']),
      previousApplication: _nullableDouble(json['previousApplication']),
      nextApplication: _nullableDouble(json['nextApplication']),
      previousRetention: _nullableDouble(json['previousRetention']),
      nextRetention: _nullableDouble(json['nextRetention']),
      stalePlanVersionsCreated: _int(json['stalePlanVersionsCreated']),
      misconceptionCodes: _strings(json['misconceptionCodes']),
      reasonCodes: _strings(json['reasonCodes']),
      schemaVersion: _int(json['schemaVersion'], currentSchemaVersion),
    );
  }
}

int _int(dynamic value, [int fallback = 0]) => value is num
    ? value.toInt()
    : int.tryParse(value?.toString() ?? '') ?? fallback;

double? _nullableDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

List<String> _strings(dynamic value) {
  if (value is! Iterable) return const <String>[];
  return value
      .map((item) => item?.toString() ?? '')
      .where((item) => item.trim().isNotEmpty)
      .toList(growable: false);
}
