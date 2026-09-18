import 'learning_priority_score.dart';

enum StudyPlanBlockType {
  learn,
  continueLearning,
  repair,
  diagnostic,
  spacedReview,
  standardPractice,
  ultraHardPractice,
  mixedRetrieval,
  competencyRecheck,
  confidenceCalibration,
  examSimulation,
  recovery,
}

enum StudyPlanBlockStatus {
  planned,
  started,
  completed,
  skipped,
  movedToTomorrow,
  replaced,
  shortened,
  unavailable,
}

enum StudyPlanManualAction {
  start,
  skip,
  moveToTomorrow,
  replace,
  shorten,
  markUnavailable,
}

class StudyPlanManualChange {
  const StudyPlanManualChange({
    required this.action,
    required this.changedAt,
    required this.note,
    this.previousMinutes,
    this.newMinutes,
  });

  final StudyPlanManualAction action;
  final DateTime changedAt;
  final String note;
  final int? previousMinutes;
  final int? newMinutes;

  Map<String, dynamic> toJson() => {
    'action': action.name,
    'changedAt': changedAt.toIso8601String(),
    'note': note,
    'previousMinutes': previousMinutes,
    'newMinutes': newMinutes,
  };

  factory StudyPlanManualChange.fromJson(Map<String, dynamic> json) {
    final changedAt = DateTime.tryParse(json['changedAt']?.toString() ?? '');
    if (changedAt == null) {
      throw const FormatException('Invalid manual-change timestamp.');
    }

    return StudyPlanManualChange(
      action: StudyPlanManualAction.values.firstWhere(
        (item) => item.name == json['action']?.toString(),
        orElse: () => StudyPlanManualAction.replace,
      ),
      changedAt: changedAt,
      note: json['note']?.toString() ?? '',
      previousMinutes: _nullableInt(json['previousMinutes']),
      newMinutes: _nullableInt(json['newMinutes']),
    );
  }
}

class StudyPlanBlock {
  const StudyPlanBlock({
    required this.blockId,
    required this.type,
    required this.domainId,
    required this.competencyId,
    required this.subtopicId,
    required this.topicId,
    required this.plannedMinutes,
    required this.questionCount,
    required this.priorityScore,
    required this.priorityBreakdown,
    required this.reasonCodes,
    required this.reasonText,
    required this.status,
    required this.createdAt,
    required this.manualChanges,
    this.startedAt,
    this.completedAt,
  });

  final String blockId;
  final StudyPlanBlockType type;
  final String domainId;
  final String competencyId;
  final String subtopicId;
  final String topicId;
  final int plannedMinutes;
  final int questionCount;
  final double priorityScore;
  final LearningPriorityScore priorityBreakdown;
  final List<String> reasonCodes;
  final String reasonText;
  final StudyPlanBlockStatus status;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final List<StudyPlanManualChange> manualChanges;

  bool get isLocked =>
      status == StudyPlanBlockStatus.started ||
      status == StudyPlanBlockStatus.completed;

  bool get isFutureEditable => !isLocked;

  StudyPlanBlock copyWith({
    String? blockId,
    StudyPlanBlockType? type,
    String? domainId,
    String? competencyId,
    String? subtopicId,
    String? topicId,
    int? plannedMinutes,
    int? questionCount,
    double? priorityScore,
    LearningPriorityScore? priorityBreakdown,
    List<String>? reasonCodes,
    String? reasonText,
    StudyPlanBlockStatus? status,
    DateTime? createdAt,
    DateTime? startedAt,
    bool clearStartedAt = false,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    List<StudyPlanManualChange>? manualChanges,
  }) {
    return StudyPlanBlock(
      blockId: blockId ?? this.blockId,
      type: type ?? this.type,
      domainId: domainId ?? this.domainId,
      competencyId: competencyId ?? this.competencyId,
      subtopicId: subtopicId ?? this.subtopicId,
      topicId: topicId ?? this.topicId,
      plannedMinutes: plannedMinutes ?? this.plannedMinutes,
      questionCount: questionCount ?? this.questionCount,
      priorityScore: priorityScore ?? this.priorityScore,
      priorityBreakdown: priorityBreakdown ?? this.priorityBreakdown,
      reasonCodes: List<String>.unmodifiable(reasonCodes ?? this.reasonCodes),
      reasonText: reasonText ?? this.reasonText,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      startedAt: clearStartedAt ? null : (startedAt ?? this.startedAt),
      completedAt: clearCompletedAt
          ? null
          : (completedAt ?? this.completedAt),
      manualChanges: List<StudyPlanManualChange>.unmodifiable(
        manualChanges ?? this.manualChanges,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'blockId': blockId,
    'type': type.name,
    'domainId': domainId,
    'competencyId': competencyId,
    'subtopicId': subtopicId,
    'topicId': topicId,
    'plannedMinutes': plannedMinutes,
    'questionCount': questionCount,
    'priorityScore': priorityScore,
    'priorityBreakdown': priorityBreakdown.toJson(),
    'reasonCodes': reasonCodes,
    'reasonText': reasonText,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'startedAt': startedAt?.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'manualChanges': manualChanges
        .map((item) => item.toJson())
        .toList(growable: false),
  };

  factory StudyPlanBlock.fromJson(Map<String, dynamic> json) {
    final createdAt = DateTime.tryParse(json['createdAt']?.toString() ?? '');
    if (createdAt == null) {
      throw const FormatException('Invalid study-plan block timestamp.');
    }

    return StudyPlanBlock(
      blockId: json['blockId']?.toString() ?? '',
      type: StudyPlanBlockType.values.firstWhere(
        (item) => item.name == json['type']?.toString(),
        orElse: () => StudyPlanBlockType.recovery,
      ),
      domainId: json['domainId']?.toString() ?? '',
      competencyId: json['competencyId']?.toString() ?? '',
      subtopicId: json['subtopicId']?.toString() ?? '',
      topicId: json['topicId']?.toString() ?? '',
      plannedMinutes: _int(json['plannedMinutes']),
      questionCount: _int(json['questionCount']),
      priorityScore: _double(json['priorityScore']),
      priorityBreakdown: LearningPriorityScore.fromJson(
        _map(json['priorityBreakdown']),
      ),
      reasonCodes: _strings(json['reasonCodes']),
      reasonText: json['reasonText']?.toString() ?? '',
      status: StudyPlanBlockStatus.values.firstWhere(
        (item) => item.name == json['status']?.toString(),
        orElse: () => StudyPlanBlockStatus.planned,
      ),
      createdAt: createdAt,
      startedAt: DateTime.tryParse(json['startedAt']?.toString() ?? ''),
      completedAt: DateTime.tryParse(json['completedAt']?.toString() ?? ''),
      manualChanges: (json['manualChanges'] is Iterable)
          ? (json['manualChanges'] as Iterable)
                .whereType<Map>()
                .map(
                  (item) => StudyPlanManualChange.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList(growable: false)
          : const <StudyPlanManualChange>[],
    );
  }
}

Map<String, dynamic> _map(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

List<String> _strings(dynamic value) {
  if (value is! Iterable) return const <String>[];
  return value
      .map((item) => item?.toString() ?? '')
      .where((item) => item.trim().isNotEmpty)
      .toList(growable: false);
}

int _int(dynamic value) =>
    value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;

int? _nullableInt(dynamic value) {
  if (value == null) return null;
  return _int(value);
}

double _double(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0.0;
}
