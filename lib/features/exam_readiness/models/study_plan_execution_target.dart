import 'study_plan_block.dart';

enum StudyPlanExecutionTargetKind {
  studyContent,
  practiceSession,
  review,
  flashcardReview,
  examSimulation,
}

class StudyPlanExecutionTarget {
  const StudyPlanExecutionTarget({
    required this.kind,
    required this.blockId,
    required this.blockType,
    required this.domainId,
    required this.domainNumber,
    required this.domainTitle,
    required this.competencyId,
    required this.competencyTitle,
    required this.plannedMinutes,
    required this.questionCount,
    this.topicId,
    this.subtopicId,
    this.cardIds = const <String>[],
    this.dueOnly = false,
    this.weakOnly = false,
    this.sourceEvidenceIds = const <String>[],
    this.targetCardCount,
    this.reviewReason,
  });

  final StudyPlanExecutionTargetKind kind;
  final String blockId;
  final StudyPlanBlockType blockType;
  final String domainId;
  final int domainNumber;
  final String domainTitle;
  final String competencyId;
  final String competencyTitle;
  final int plannedMinutes;
  final int questionCount;
  final String? topicId;
  final String? subtopicId;

  /// Optional explicit card scope for a targeted Flashcard review.
  final List<String> cardIds;

  /// Requests cards currently due for spaced review when runtime SRS state is available.
  final bool dueOnly;

  /// Requests weak-card filtering when learner retention state is available.
  final bool weakOnly;

  /// Evidence identifiers that caused this review assignment, when available.
  final List<String> sourceEvidenceIds;

  /// Optional target number of cards. Null lets the Flashcards runtime choose safely.
  final int? targetCardCount;

  /// Human-readable reason for the targeted review assignment.
  final String? reviewReason;

  List<String> get competencyIds => <String>[competencyId];

  int get targetMinutes => plannedMinutes;

  StudyPlanExecutionTarget copyWith({
    StudyPlanExecutionTargetKind? kind,
    String? blockId,
    StudyPlanBlockType? blockType,
    String? domainId,
    int? domainNumber,
    String? domainTitle,
    String? competencyId,
    String? competencyTitle,
    int? plannedMinutes,
    int? questionCount,
    String? topicId,
    bool clearTopicId = false,
    String? subtopicId,
    bool clearSubtopicId = false,
    List<String>? cardIds,
    bool? dueOnly,
    bool? weakOnly,
    List<String>? sourceEvidenceIds,
    int? targetCardCount,
    bool clearTargetCardCount = false,
    String? reviewReason,
    bool clearReviewReason = false,
  }) {
    return StudyPlanExecutionTarget(
      kind: kind ?? this.kind,
      blockId: blockId ?? this.blockId,
      blockType: blockType ?? this.blockType,
      domainId: domainId ?? this.domainId,
      domainNumber: domainNumber ?? this.domainNumber,
      domainTitle: domainTitle ?? this.domainTitle,
      competencyId: competencyId ?? this.competencyId,
      competencyTitle: competencyTitle ?? this.competencyTitle,
      plannedMinutes: plannedMinutes ?? this.plannedMinutes,
      questionCount: questionCount ?? this.questionCount,
      topicId: clearTopicId ? null : (topicId ?? this.topicId),
      subtopicId: clearSubtopicId ? null : (subtopicId ?? this.subtopicId),
      cardIds: List<String>.unmodifiable(cardIds ?? this.cardIds),
      dueOnly: dueOnly ?? this.dueOnly,
      weakOnly: weakOnly ?? this.weakOnly,
      sourceEvidenceIds: List<String>.unmodifiable(
        sourceEvidenceIds ?? this.sourceEvidenceIds,
      ),
      targetCardCount: clearTargetCardCount
          ? null
          : (targetCardCount ?? this.targetCardCount),
      reviewReason: clearReviewReason
          ? null
          : (reviewReason ?? this.reviewReason),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'kind': kind.name,
    'blockId': blockId,
    'blockType': blockType.name,
    'domainId': domainId,
    'domainNumber': domainNumber,
    'domainTitle': domainTitle,
    'competencyId': competencyId,
    'competencyTitle': competencyTitle,
    'plannedMinutes': plannedMinutes,
    'questionCount': questionCount,
    'topicId': topicId,
    'subtopicId': subtopicId,
    'cardIds': cardIds,
    'dueOnly': dueOnly,
    'weakOnly': weakOnly,
    'sourceEvidenceIds': sourceEvidenceIds,
    'targetCardCount': targetCardCount,
    'reviewReason': reviewReason,
  };

  factory StudyPlanExecutionTarget.fromJson(Map<String, dynamic> json) {
    return StudyPlanExecutionTarget(
      kind: StudyPlanExecutionTargetKind.values.firstWhere(
        (value) => value.name == json['kind']?.toString(),
        orElse: () => StudyPlanExecutionTargetKind.studyContent,
      ),
      blockId: json['blockId']?.toString() ?? '',
      blockType: StudyPlanBlockType.values.firstWhere(
        (value) => value.name == json['blockType']?.toString(),
        orElse: () => StudyPlanBlockType.recovery,
      ),
      domainId: json['domainId']?.toString() ?? '',
      domainNumber: _int(json['domainNumber']),
      domainTitle: json['domainTitle']?.toString() ?? '',
      competencyId: json['competencyId']?.toString() ?? '',
      competencyTitle: json['competencyTitle']?.toString() ?? '',
      plannedMinutes: _int(json['plannedMinutes']),
      questionCount: _int(json['questionCount']),
      topicId: _nullableString(json['topicId']),
      subtopicId: _nullableString(json['subtopicId']),
      cardIds: _strings(json['cardIds']),
      dueOnly: json['dueOnly'] == true,
      weakOnly: json['weakOnly'] == true,
      sourceEvidenceIds: _strings(json['sourceEvidenceIds']),
      targetCardCount: json['targetCardCount'] == null
          ? null
          : _int(json['targetCardCount']),
      reviewReason: _nullableString(json['reviewReason']),
    );
  }
}

int _int(dynamic value) =>
    value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;

String? _nullableString(dynamic value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

List<String> _strings(dynamic value) {
  if (value is! Iterable) return const <String>[];
  return value
      .map((item) => item?.toString() ?? '')
      .where((item) => item.trim().isNotEmpty)
      .toList(growable: false);
}
