import 'study_plan_block.dart';
import 'study_plan_execution_target.dart';

enum StudyPlanCarryForwardStatus { pending, consumed }

class StudyPlanCarryForward {
  const StudyPlanCarryForward({
    required this.id,
    required this.learnerId,
    required this.originalPlanId,
    required this.originalBlockId,
    required this.sourceBlock,
    required this.executionTarget,
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
  final StudyPlanBlock sourceBlock;
  final StudyPlanExecutionTarget executionTarget;
  final String reason;
  final DateTime createdAt;
  final DateTime dueDate;
  final StudyPlanCarryForwardStatus status;
  final DateTime? consumedAt;

  String get domainId => sourceBlock.domainId;
  String get competencyId => sourceBlock.competencyId;
  String get subtopicId => sourceBlock.subtopicId;
  String get topicId => sourceBlock.topicId;
  StudyPlanBlockType get blockType => sourceBlock.type;
  int get minutes => sourceBlock.plannedMinutes;

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
    sourceBlock: sourceBlock,
    executionTarget: executionTarget,
    reason: reason,
    createdAt: createdAt,
    dueDate: dueDate,
    status: StudyPlanCarryForwardStatus.consumed,
    consumedAt: at,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'learnerId': learnerId,
    'originalPlanId': originalPlanId,
    'originalBlockId': originalBlockId,
    'sourceBlock': sourceBlock.toJson(),
    'executionTarget': executionTarget.toJson(),
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

    final sourceRaw = json['sourceBlock'];
    final targetRaw = json['executionTarget'];
    if (sourceRaw is! Map || targetRaw is! Map) {
      throw const FormatException(
        'Carry-forward source or execution target is missing.',
      );
    }

    return StudyPlanCarryForward(
      id: json['id']?.toString() ?? '',
      learnerId: json['learnerId']?.toString() ?? '',
      originalPlanId: json['originalPlanId']?.toString() ?? '',
      originalBlockId: json['originalBlockId']?.toString() ?? '',
      sourceBlock: StudyPlanBlock.fromJson(
        Map<String, dynamic>.from(sourceRaw),
      ),
      executionTarget: StudyPlanExecutionTarget.fromJson(
        Map<String, dynamic>.from(targetRaw),
      ),
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
