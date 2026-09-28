enum LearningEvidenceSourceKind {
  question,
  flashcard,
  lab,
  study,
  simulation,
  microLearning,
}

enum LearningEvidenceStrength { none, context, supporting, strong }

class LearningEvidenceEvent {
  const LearningEvidenceEvent({
    required this.evidenceEventId,
    required this.sourceOutcomeId,
    required this.planId,
    required this.planVersion,
    required this.blockId,
    required this.domainId,
    required this.competencyId,
    required this.topicId,
    required this.subtopicId,
    required this.sourceKind,
    required this.strength,
    required this.occurredAt,
    required this.questionsAttempted,
    required this.questionsCorrect,
    required this.confidenceSamples,
    required this.contentCompleted,
    required this.abandoned,
    required this.signalCodes,
    this.performanceScore,
    this.applicationScore,
    this.retentionScore,
    this.schemaVersion = currentSchemaVersion,
  });

  static const int currentSchemaVersion = 1;

  final String evidenceEventId;
  final String sourceOutcomeId;
  final String planId;
  final int planVersion;
  final String blockId;
  final String domainId;
  final String competencyId;
  final String topicId;
  final String subtopicId;
  final LearningEvidenceSourceKind sourceKind;
  final LearningEvidenceStrength strength;
  final DateTime occurredAt;
  final int questionsAttempted;
  final int questionsCorrect;
  final int confidenceSamples;
  final bool contentCompleted;
  final bool abandoned;
  final double? performanceScore;
  final double? applicationScore;
  final double? retentionScore;
  final List<String> signalCodes;
  final int schemaVersion;

  bool get hasDirectMasteryCredit =>
      strength == LearningEvidenceStrength.strong ||
      strength == LearningEvidenceStrength.supporting;

  bool get isZeroCredit => strength == LearningEvidenceStrength.none;

  void validate() {
    if (evidenceEventId.trim().isEmpty ||
        sourceOutcomeId.trim().isEmpty ||
        planId.trim().isEmpty ||
        blockId.trim().isEmpty) {
      throw StateError('Learning evidence identifiers cannot be blank.');
    }
    if (!RegExp(r'^d\d{2}_c\d{2}$').hasMatch(competencyId)) {
      throw StateError('Learning evidence competency ID is not canonical.');
    }
    if (planVersion < 1 ||
        questionsAttempted < 0 ||
        questionsCorrect < 0 ||
        confidenceSamples < 0) {
      throw StateError('Learning evidence counts cannot be negative.');
    }
    if (questionsCorrect > questionsAttempted) {
      throw StateError('Correct questions cannot exceed attempted questions.');
    }
    for (final score in [performanceScore, applicationScore, retentionScore]) {
      if (score != null && (score < 0 || score > 1)) {
        throw StateError('Learning evidence scores must be between zero and one.');
      }
    }

    final expectedStrength = switch (sourceKind) {
      LearningEvidenceSourceKind.question => LearningEvidenceStrength.strong,
      LearningEvidenceSourceKind.flashcard =>
        LearningEvidenceStrength.supporting,
      LearningEvidenceSourceKind.lab => LearningEvidenceStrength.strong,
      LearningEvidenceSourceKind.study => LearningEvidenceStrength.context,
      LearningEvidenceSourceKind.simulation => LearningEvidenceStrength.strong,
      LearningEvidenceSourceKind.microLearning => LearningEvidenceStrength.none,
    };
    if (strength != expectedStrength) {
      throw StateError(
        'Learning evidence strength does not match its source hierarchy.',
      );
    }
    if (sourceKind == LearningEvidenceSourceKind.microLearning &&
        (performanceScore != null ||
            applicationScore != null ||
            retentionScore != null)) {
      throw StateError('Micro-learning exposure cannot carry readiness credit.');
    }
  }

  Map<String, dynamic> toJson() {
    validate();
    return {
      'evidenceEventId': evidenceEventId,
      'sourceOutcomeId': sourceOutcomeId,
      'planId': planId,
      'planVersion': planVersion,
      'blockId': blockId,
      'domainId': domainId,
      'competencyId': competencyId,
      'topicId': topicId,
      'subtopicId': subtopicId,
      'sourceKind': sourceKind.name,
      'strength': strength.name,
      'occurredAt': occurredAt.toIso8601String(),
      'questionsAttempted': questionsAttempted,
      'questionsCorrect': questionsCorrect,
      'confidenceSamples': confidenceSamples,
      'contentCompleted': contentCompleted,
      'abandoned': abandoned,
      'performanceScore': performanceScore,
      'applicationScore': applicationScore,
      'retentionScore': retentionScore,
      'signalCodes': signalCodes,
      'schemaVersion': schemaVersion,
    };
  }

  factory LearningEvidenceEvent.fromJson(Map<String, dynamic> json) {
    final occurredAt = DateTime.tryParse(json['occurredAt']?.toString() ?? '');
    if (occurredAt == null) {
      throw const FormatException('Invalid learning evidence timestamp.');
    }

    final event = LearningEvidenceEvent(
      evidenceEventId: json['evidenceEventId']?.toString() ?? '',
      sourceOutcomeId: json['sourceOutcomeId']?.toString() ?? '',
      planId: json['planId']?.toString() ?? '',
      planVersion: _int(json['planVersion'], 1),
      blockId: json['blockId']?.toString() ?? '',
      domainId: json['domainId']?.toString() ?? '',
      competencyId: json['competencyId']?.toString() ?? '',
      topicId: json['topicId']?.toString() ?? '',
      subtopicId: json['subtopicId']?.toString() ?? '',
      sourceKind: LearningEvidenceSourceKind.values.firstWhere(
        (item) => item.name == json['sourceKind']?.toString(),
        orElse: () => LearningEvidenceSourceKind.study,
      ),
      strength: LearningEvidenceStrength.values.firstWhere(
        (item) => item.name == json['strength']?.toString(),
        orElse: () => LearningEvidenceStrength.context,
      ),
      occurredAt: occurredAt,
      questionsAttempted: _int(json['questionsAttempted']),
      questionsCorrect: _int(json['questionsCorrect']),
      confidenceSamples: _int(json['confidenceSamples']),
      contentCompleted: json['contentCompleted'] == true,
      abandoned: json['abandoned'] == true,
      performanceScore: _nullableDouble(json['performanceScore']),
      applicationScore: _nullableDouble(json['applicationScore']),
      retentionScore: _nullableDouble(json['retentionScore']),
      signalCodes: _strings(json['signalCodes']),
      schemaVersion: _int(json['schemaVersion'], currentSchemaVersion),
    );
    event.validate();
    return event;
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
