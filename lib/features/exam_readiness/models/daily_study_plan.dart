import 'study_plan_block.dart';

enum DailyStudyPlanStatus { active, completed, superseded, stale }

enum DailyStudyPlanGenerationReason {
  initial,
  manualRequest,
  capacityChanged,
  scheduleChanged,
  dailyRollover,
  assessmentCompleted,
  majorPerformanceShift,
  examDateChanged,
  studyScheduleChanged,
  criticalGapDetected,
  missedStudyDay,
}

class DailyStudyPlan {
  const DailyStudyPlan({
    required this.planId,
    required this.userId,
    required this.date,
    required this.generatedAt,
    required this.planVersion,
    required this.plannerAlgorithmVersion,
    required this.availableMinutes,
    required this.allocatedMinutes,
    required this.generationReason,
    required this.sourceEvidenceVersion,
    required this.sourceReadinessVersion,
    required this.blocks,
    required this.status,
    required this.schemaVersion,
    this.previousPlanId,
    this.inputSnapshotVersion = '',
  });

  static const int currentSchemaVersion = 1;
  static const String currentAlgorithmVersion = 'm7d-v1';

  final String planId;
  final String userId;
  final DateTime date;
  final DateTime generatedAt;
  final int planVersion;
  final String plannerAlgorithmVersion;
  final int availableMinutes;
  final int allocatedMinutes;
  final DailyStudyPlanGenerationReason generationReason;
  final String sourceEvidenceVersion;
  final String sourceReadinessVersion;
  final List<StudyPlanBlock> blocks;
  final DailyStudyPlanStatus status;
  final int schemaVersion;
  final String? previousPlanId;
  final String inputSnapshotVersion;

  bool get hasStartedBlock => blocks.any((block) => block.isLocked);

  DailyStudyPlan copyWith({
    String? planId,
    String? userId,
    DateTime? date,
    DateTime? generatedAt,
    int? planVersion,
    String? plannerAlgorithmVersion,
    int? availableMinutes,
    int? allocatedMinutes,
    DailyStudyPlanGenerationReason? generationReason,
    String? sourceEvidenceVersion,
    String? sourceReadinessVersion,
    List<StudyPlanBlock>? blocks,
    DailyStudyPlanStatus? status,
    int? schemaVersion,
    String? previousPlanId,
    bool clearPreviousPlanId = false,
    String? inputSnapshotVersion,
  }) {
    return DailyStudyPlan(
      planId: planId ?? this.planId,
      userId: userId ?? this.userId,
      date: _dateOnly(date ?? this.date),
      generatedAt: generatedAt ?? this.generatedAt,
      planVersion: planVersion ?? this.planVersion,
      plannerAlgorithmVersion:
          plannerAlgorithmVersion ?? this.plannerAlgorithmVersion,
      availableMinutes: availableMinutes ?? this.availableMinutes,
      allocatedMinutes: allocatedMinutes ?? this.allocatedMinutes,
      generationReason: generationReason ?? this.generationReason,
      sourceEvidenceVersion:
          sourceEvidenceVersion ?? this.sourceEvidenceVersion,
      sourceReadinessVersion:
          sourceReadinessVersion ?? this.sourceReadinessVersion,
      blocks: List<StudyPlanBlock>.unmodifiable(blocks ?? this.blocks),
      status: status ?? this.status,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      previousPlanId: clearPreviousPlanId
          ? null
          : (previousPlanId ?? this.previousPlanId),
      inputSnapshotVersion:
          inputSnapshotVersion ?? this.inputSnapshotVersion,
    );
  }

  DailyStudyPlan nextVersion({
    required DateTime generatedAt,
    required List<StudyPlanBlock> blocks,
    required int availableMinutes,
    required DailyStudyPlanGenerationReason generationReason,
    required String sourceEvidenceVersion,
    required String sourceReadinessVersion,
  }) {
    return copyWith(
      generatedAt: generatedAt,
      planVersion: planVersion + 1,
      availableMinutes: availableMinutes,
      allocatedMinutes: blocks.fold<int>(
        0,
        (sum, block) => sum + block.plannedMinutes,
      ),
      generationReason: generationReason,
      sourceEvidenceVersion: sourceEvidenceVersion,
      sourceReadinessVersion: sourceReadinessVersion,
      blocks: blocks,
      status: DailyStudyPlanStatus.active,
      previousPlanId: '$planId:v$planVersion',
      inputSnapshotVersion:
          'e:$sourceEvidenceVersion|r:$sourceReadinessVersion',
    );
  }

  void validate() {
    if (planId.trim().isEmpty || userId.trim().isEmpty) {
      throw StateError('Daily plan requires planId and userId.');
    }
    if (availableMinutes < 0 || allocatedMinutes < 0) {
      throw StateError('Daily plan minutes cannot be negative.');
    }
    if (allocatedMinutes > availableMinutes) {
      throw StateError('Allocated minutes exceed available minutes.');
    }

    final ids = <String>{};
    var sum = 0;
    for (final block in blocks) {
      if (!ids.add(block.blockId)) {
        throw StateError('Daily plan contains duplicate block IDs.');
      }
      if (block.reasonCodes.isEmpty || block.reasonText.trim().isEmpty) {
        throw StateError('Every study-plan block must be explainable.');
      }
      if (block.plannedMinutes <= 0) {
        throw StateError('Study-plan block minutes must be positive.');
      }
      sum += block.plannedMinutes;
    }

    if (sum != allocatedMinutes) {
      throw StateError('Allocated minutes do not match block minutes.');
    }
  }

  Map<String, dynamic> toJson() => {
    'planId': planId,
    'userId': userId,
    'date': _dateOnly(date).toIso8601String(),
    'generatedAt': generatedAt.toIso8601String(),
    'planVersion': planVersion,
    'plannerAlgorithmVersion': plannerAlgorithmVersion,
    'availableMinutes': availableMinutes,
    'allocatedMinutes': allocatedMinutes,
    'generationReason': generationReason.name,
    'sourceEvidenceVersion': sourceEvidenceVersion,
    'sourceReadinessVersion': sourceReadinessVersion,
    'blocks': blocks.map((block) => block.toJson()).toList(growable: false),
    'status': status.name,
    'schemaVersion': schemaVersion,
    'previousPlanId': previousPlanId,
    'inputSnapshotVersion': inputSnapshotVersion,
  };

  factory DailyStudyPlan.fromJson(Map<String, dynamic> json) {
    final date = DateTime.tryParse(json['date']?.toString() ?? '');
    final generatedAt = DateTime.tryParse(
      json['generatedAt']?.toString() ?? '',
    );
    if (date == null || generatedAt == null) {
      throw const FormatException('Daily plan contains invalid timestamps.');
    }

    final plan = DailyStudyPlan(
      planId: json['planId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      date: _dateOnly(date),
      generatedAt: generatedAt,
      planVersion: _int(json['planVersion'], 1),
      plannerAlgorithmVersion:
          json['plannerAlgorithmVersion']?.toString() ??
          currentAlgorithmVersion,
      availableMinutes: _int(json['availableMinutes'], 0),
      allocatedMinutes: _int(json['allocatedMinutes'], 0),
      generationReason: DailyStudyPlanGenerationReason.values.firstWhere(
        (item) => item.name == json['generationReason']?.toString(),
        orElse: () => DailyStudyPlanGenerationReason.initial,
      ),
      sourceEvidenceVersion: json['sourceEvidenceVersion']?.toString() ?? '',
      sourceReadinessVersion: json['sourceReadinessVersion']?.toString() ?? '',
      blocks: (json['blocks'] is Iterable)
          ? (json['blocks'] as Iterable)
                .whereType<Map>()
                .map(
                  (item) =>
                      StudyPlanBlock.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList(growable: false)
          : const <StudyPlanBlock>[],
      status: DailyStudyPlanStatus.values.firstWhere(
        (item) => item.name == json['status']?.toString(),
        orElse: () => DailyStudyPlanStatus.active,
      ),
      schemaVersion: _int(json['schemaVersion'], currentSchemaVersion),
      previousPlanId: json['previousPlanId']?.toString(),
      inputSnapshotVersion: json['inputSnapshotVersion']?.toString() ?? '',
    );

    plan.validate();
    return plan;
  }
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

int _int(dynamic value, int fallback) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}
