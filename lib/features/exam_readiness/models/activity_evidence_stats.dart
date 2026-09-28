import 'learning_evidence_event.dart';

class ActivityEvidenceStats {
  const ActivityEvidenceStats({
    this.totalEvents = 0,
    this.strongEvents = 0,
    this.supportingEvents = 0,
    this.contextEvents = 0,
    this.zeroCreditEvents = 0,
    this.questionEvents = 0,
    this.flashcardEvents = 0,
    this.labEvents = 0,
    this.studyEvents = 0,
    this.simulationEvents = 0,
    this.microLearningEvents = 0,
    this.strongApplicationSamples = 0,
    this.strongApplicationAccuracy,
    this.supportingRetentionSamples = 0,
    this.supportingRetentionAccuracy,
    this.supportingRetentionDistinctUnits = 0,
    this.supportingRetentionSpacedSamples = 0,
    this.lastEvidenceAt,
  });

  final int totalEvents;
  final int strongEvents;
  final int supportingEvents;
  final int contextEvents;
  final int zeroCreditEvents;
  final int questionEvents;
  final int flashcardEvents;
  final int labEvents;
  final int studyEvents;
  final int simulationEvents;
  final int microLearningEvents;
  final int strongApplicationSamples;
  final double? strongApplicationAccuracy;
  final int supportingRetentionSamples;
  final double? supportingRetentionAccuracy;
  final int supportingRetentionDistinctUnits;
  final int supportingRetentionSpacedSamples;
  final DateTime? lastEvidenceAt;

  int get creditableEvents => strongEvents + supportingEvents + contextEvents;

  int get performanceBearingEvents => labEvents + simulationEvents;

  bool get hasActivityEvidence => totalEvents > 0;

  Map<String, dynamic> toJson() => {
    'totalEvents': totalEvents,
    'strongEvents': strongEvents,
    'supportingEvents': supportingEvents,
    'contextEvents': contextEvents,
    'zeroCreditEvents': zeroCreditEvents,
    'questionEvents': questionEvents,
    'flashcardEvents': flashcardEvents,
    'labEvents': labEvents,
    'studyEvents': studyEvents,
    'simulationEvents': simulationEvents,
    'microLearningEvents': microLearningEvents,
    'strongApplicationSamples': strongApplicationSamples,
    'strongApplicationAccuracy': strongApplicationAccuracy,
    'supportingRetentionSamples': supportingRetentionSamples,
    'supportingRetentionAccuracy': supportingRetentionAccuracy,
    'supportingRetentionDistinctUnits': supportingRetentionDistinctUnits,
    'supportingRetentionSpacedSamples': supportingRetentionSpacedSamples,
    'lastEvidenceAt': lastEvidenceAt?.toIso8601String(),
  };

  factory ActivityEvidenceStats.fromJson(Map<String, dynamic> json) {
    return ActivityEvidenceStats(
      totalEvents: _int(json['totalEvents']),
      strongEvents: _int(json['strongEvents']),
      supportingEvents: _int(json['supportingEvents']),
      contextEvents: _int(json['contextEvents']),
      zeroCreditEvents: _int(json['zeroCreditEvents']),
      questionEvents: _int(json['questionEvents']),
      flashcardEvents: _int(json['flashcardEvents']),
      labEvents: _int(json['labEvents']),
      studyEvents: _int(json['studyEvents']),
      simulationEvents: _int(json['simulationEvents']),
      microLearningEvents: _int(json['microLearningEvents']),
      strongApplicationSamples: _int(json['strongApplicationSamples']),
      strongApplicationAccuracy: _nullableDouble(
        json['strongApplicationAccuracy'],
      ),
      supportingRetentionSamples: _int(json['supportingRetentionSamples']),
      supportingRetentionAccuracy: _nullableDouble(
        json['supportingRetentionAccuracy'],
      ),
      supportingRetentionDistinctUnits: _int(
        json['supportingRetentionDistinctUnits'],
      ),
      supportingRetentionSpacedSamples: _int(
        json['supportingRetentionSpacedSamples'],
      ),
      lastEvidenceAt: DateTime.tryParse(
        json['lastEvidenceAt']?.toString() ?? '',
      ),
    );
  }

  static ActivityEvidenceStats aggregate(
    Iterable<LearningEvidenceEvent> events,
  ) {
    final deduplicated = <String, LearningEvidenceEvent>{};
    for (final event in events) {
      event.validate();
      deduplicated.putIfAbsent(event.evidenceEventId, () => event);
    }

    var strong = 0;
    var supporting = 0;
    var context = 0;
    var zeroCredit = 0;
    var questions = 0;
    var flashcards = 0;
    var labs = 0;
    var study = 0;
    var simulations = 0;
    var microLearning = 0;
    final applicationScores = <double>[];
    final retentionScores = <double>[];
    final retentionUnitIds = <String>{};
    var spacedRetentionSamples = 0;
    DateTime? latest;

    for (final event in deduplicated.values) {
      switch (event.strength) {
        case LearningEvidenceStrength.none:
          zeroCredit++;
          break;
        case LearningEvidenceStrength.context:
          context++;
          break;
        case LearningEvidenceStrength.supporting:
          supporting++;
          break;
        case LearningEvidenceStrength.strong:
          strong++;
          break;
      }

      switch (event.sourceKind) {
        case LearningEvidenceSourceKind.question:
          questions++;
          break;
        case LearningEvidenceSourceKind.flashcard:
          flashcards++;
          break;
        case LearningEvidenceSourceKind.lab:
          labs++;
          if (event.applicationScore != null) {
            applicationScores.add(event.applicationScore!);
          }
          break;
        case LearningEvidenceSourceKind.study:
          study++;
          break;
        case LearningEvidenceSourceKind.simulation:
          simulations++;
          if (event.applicationScore != null) {
            applicationScores.add(event.applicationScore!);
          }
          break;
        case LearningEvidenceSourceKind.microLearning:
          microLearning++;
          break;
      }

      if (event.sourceKind == LearningEvidenceSourceKind.flashcard &&
          event.retentionScore != null) {
        retentionScores.add(event.retentionScore!);
        final unitId = event.evidenceUnitId?.trim() ?? '';
        if (unitId.isNotEmpty) retentionUnitIds.add(unitId);
        if ((event.spacingIntervalDays ?? 0) >= 1) spacedRetentionSamples++;
      }
      if (latest == null || event.occurredAt.isAfter(latest)) {
        latest = event.occurredAt;
      }
    }

    double? average(List<double> values) => values.isEmpty
        ? null
        : values.reduce((left, right) => left + right) / values.length;

    return ActivityEvidenceStats(
      totalEvents: deduplicated.length,
      strongEvents: strong,
      supportingEvents: supporting,
      contextEvents: context,
      zeroCreditEvents: zeroCredit,
      questionEvents: questions,
      flashcardEvents: flashcards,
      labEvents: labs,
      studyEvents: study,
      simulationEvents: simulations,
      microLearningEvents: microLearning,
      strongApplicationSamples: applicationScores.length,
      strongApplicationAccuracy: average(applicationScores),
      supportingRetentionSamples: retentionScores.length,
      supportingRetentionAccuracy: average(retentionScores),
      supportingRetentionDistinctUnits: retentionUnitIds.length,
      supportingRetentionSpacedSamples: spacedRetentionSamples,
      lastEvidenceAt: latest,
    );
  }
}

int _int(dynamic value) =>
    value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;

double? _nullableDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
