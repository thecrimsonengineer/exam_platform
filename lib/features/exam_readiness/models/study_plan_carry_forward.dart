import 'study_plan_block.dart';
import 'study_plan_execution_target.dart';

enum StudyPlanCarryForwardStatus { pending, consumed }

class StudyPlanCarryForward {
  const StudyPlanCarryForward({
    required this.id,
    required this.learnerId,
    required this.originalPlanId,
    required this.originalBlockId,
    required this.domainId,
    required this.competencyId,
    required this.subtopicId,
    required this.topicId,
    required this.blockType,
    required this.executionTarget,
    required this.minutes,
    required this.reason,
    required this.createdAt,
    required this.dueDate,
    required this.status,
    this.consumedAt,
  });

  final String id;
  final String learnerId;
  final String originalPlanId;
  final String originalBlockId;
  final String domainId;
  final String competencyId;
  final String subtopicId;
  final String topicId;
  final StudyPlanBlockType blockType;
  final StudyPlanExecutionTarget executionTarget;
  final int minutes;
  final String reason;
  final DateTime createdAt;
  final DateTime dueDate;
  final StudyPlanCarryForwardStatus status;
  final DateTime? consumedAt;

  static String deterministicId({
    required String planId,
    required String blockId,
    required DateTime dueDate,
  }) {
    final day = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final suffix =
        '${day.year}${day.month.toString().padLeft(2, '0')}${day.day.toString().padLeft(2, '0')}';
    return 'cf:$planId:$blockId:$suffix';
  }

  StudyPlanCarryForward markConsumed(DateTime at) => StudyPlanCarryForward(
    id: id,
    learnerId: learnerId,
    originalPlanId: originalPlanId,
    originalBlockId: originalBlockId,
    domainId: domainId,
    competencyId: competencyId,
    subtopicId: subtopicId,
    topicId: topicId,
    blockType: blockType,
    executionTarget: executionTarget,
    minutes: minutes,
    reason: reason,
    createdAt: createdAt,
    dueDate: dueDate,
    status: StudyPlanCarryForwardStatus.consumed,
    consumedAt: at,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'learnerId': learnerId,
    'originalPlanId': originalPlanId,
    'originalBlockId': originalBlockId,
    'domainId': domainId,
    'competencyId': competencyId,
    'subtopicId': subtopicId,
    'topicId': topicId,
    'blockType': blockType.name,
    'executionTarget': executionTarget.toJson(),
    'minutes': minutes,
    'reason': reason,
    'createdAt': createdAt.toIso8601String(),
    'dueDate': _dateOnly(dueDate).toIso8601String(),
    'status': status.name,
    'consumedAt': consumedAt?.toIso8601String(),
  };

  factory StudyPlanCarryForward.fromJson(Map<String, dynamic> json) {
    final createdAt = DateTime.tryParse(json['createdAt']?.toString() ?? '');
    final dueDate = DateTime.tryParse(json['dueDate']?.toString() ?? '');
    if (createdAt == null || dueDate == null) {
      throw const FormatException('Invalid carry-forward timestamp.');
    }

    final targetRaw = json['executionTarget'];
    if (targetRaw is! Map) {
      throw const FormatException('Carry-forward execution target is missing.');
    }

    return StudyPlanCarryForward(
      id: json['id']?.toString() ?? '',
      learnerId: json['learnerId']?.toString() ?? '',
      originalPlanId: json['originalPlanId']?.toString() ?? '',
      originalBlockId: json['originalBlockId']?.toString() ?? '',
      domainId: json['domainId']?.toString() ?? '',
      competencyId: json['competencyId']?.toString() ?? '',
      subtopicId: json['subtopicId']?.toString() ?? '',
      topicId: json['topicId']?.toString() ?? '',
      blockType: StudyPlanBlockType.values.firstWhere(
        (value) => value.name == json['blockType']?.toString(),
        orElse: () => StudyPlanBlockType.recovery,
      ),
      executionTarget: StudyPlanExecutionTarget.fromJson(
        Map<String, dynamic>.from(targetRaw),
      ),
      minutes: json['minutes'] is num
          ? (json['minutes'] as num).toInt()
          : int.tryParse(json['minutes']?.toString() ?? '') ?? 0,
      reason: json['reason']?.toString() ?? '',
      createdAt: createdAt,
      dueDate: _dateOnly(dueDate),
      status: StudyPlanCarryForwardStatus.values.firstWhere(
        (value) => value.name == json['status']?.toString(),
        orElse: () => StudyPlanCarryForwardStatus.pending,
      ),
      consumedAt: DateTime.tryParse(json['consumedAt']?.toString() ?? ''),
    );
  }
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
