class StudyPlanBlockOutcome {
  const StudyPlanBlockOutcome({
    required this.outcomeId,
    required this.planId,
    required this.planVersion,
    required this.blockId,
    required this.competencyId,
    required this.completedAt,
    required this.minutesSpent,
    required this.questionsAttempted,
    required this.questionsCorrect,
    required this.confidenceSamples,
    required this.contentCompleted,
    required this.abandoned,
    this.applicationAccuracy,
    this.analysisAccuracy,
    this.ultraHardAccuracy,
    this.learnerRating,
    this.schemaVersion = currentSchemaVersion,
  });

  static const int currentSchemaVersion = 1;

  final String outcomeId;
  final String planId;
  final int planVersion;
  final String blockId;
  final String competencyId;
  final DateTime completedAt;
  final int minutesSpent;
  final int questionsAttempted;
  final int questionsCorrect;
  final double? applicationAccuracy;
  final double? analysisAccuracy;
  final double? ultraHardAccuracy;
  final int confidenceSamples;
  final bool contentCompleted;
  final int? learnerRating;
  final bool abandoned;
  final int schemaVersion;

  double? get overallAccuracy =>
      questionsAttempted == 0 ? null : questionsCorrect / questionsAttempted;

  void validate() {
    if (outcomeId.trim().isEmpty ||
        planId.trim().isEmpty ||
        blockId.trim().isEmpty) {
      throw StateError('Study-plan outcome identifiers cannot be blank.');
    }
    if (!RegExp(r'^d\d{2}_c\d{2}$').hasMatch(competencyId)) {
      throw StateError('Study-plan outcome competency ID is not canonical.');
    }
    if (planVersion < 1 ||
        minutesSpent < 0 ||
        questionsAttempted < 0 ||
        questionsCorrect < 0 ||
        confidenceSamples < 0) {
      throw StateError('Study-plan outcome counts cannot be negative.');
    }
    if (questionsCorrect > questionsAttempted) {
      throw StateError('Correct questions cannot exceed attempted questions.');
    }
    for (final value in [
      applicationAccuracy,
      analysisAccuracy,
      ultraHardAccuracy,
    ]) {
      if (value != null && (value < 0 || value > 1)) {
        throw StateError('Outcome accuracy must be between zero and one.');
      }
    }
    if (learnerRating != null && (learnerRating! < 1 || learnerRating! > 5)) {
      throw StateError('Learner rating must be between 1 and 5.');
    }
  }

  Map<String, dynamic> toJson() {
    validate();
    return {
      'outcomeId': outcomeId,
      'planId': planId,
      'planVersion': planVersion,
      'blockId': blockId,
      'competencyId': competencyId,
      'completedAt': completedAt.toIso8601String(),
      'minutesSpent': minutesSpent,
      'questionsAttempted': questionsAttempted,
      'questionsCorrect': questionsCorrect,
      'applicationAccuracy': applicationAccuracy,
      'analysisAccuracy': analysisAccuracy,
      'ultraHardAccuracy': ultraHardAccuracy,
      'confidenceSamples': confidenceSamples,
      'contentCompleted': contentCompleted,
      'learnerRating': learnerRating,
      'abandoned': abandoned,
      'schemaVersion': schemaVersion,
    };
  }

  factory StudyPlanBlockOutcome.fromJson(Map<String, dynamic> json) {
    final completedAt = DateTime.tryParse(
      json['completedAt']?.toString() ?? '',
    );
    if (completedAt == null) {
      throw const FormatException('Invalid block-outcome timestamp.');
    }

    final outcome = StudyPlanBlockOutcome(
      outcomeId: json['outcomeId']?.toString() ?? '',
      planId: json['planId']?.toString() ?? '',
      planVersion: _int(json['planVersion'], 1),
      blockId: json['blockId']?.toString() ?? '',
      competencyId: json['competencyId']?.toString() ?? '',
      completedAt: completedAt,
      minutesSpent: _int(json['minutesSpent']),
      questionsAttempted: _int(json['questionsAttempted']),
      questionsCorrect: _int(json['questionsCorrect']),
      applicationAccuracy: _nullableDouble(json['applicationAccuracy']),
      analysisAccuracy: _nullableDouble(json['analysisAccuracy']),
      ultraHardAccuracy: _nullableDouble(json['ultraHardAccuracy']),
      confidenceSamples: _int(json['confidenceSamples']),
      contentCompleted: json['contentCompleted'] == true,
      learnerRating: _nullableInt(json['learnerRating']),
      abandoned: json['abandoned'] == true,
      schemaVersion: _int(json['schemaVersion'], currentSchemaVersion),
    );
    outcome.validate();
    return outcome;
  }
}

int _int(dynamic value, [int fallback = 0]) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

int? _nullableInt(dynamic value) {
  if (value == null) return null;
  return _int(value);
}

double? _nullableDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
