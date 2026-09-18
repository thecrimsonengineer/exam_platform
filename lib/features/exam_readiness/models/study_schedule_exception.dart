enum StudyScheduleExceptionType {
  unavailable,
  extraStudyDay,
  overrideMinutes,
  travel,
  leave,
  holiday,
  intensiveRevisionDay,
}

class StudyScheduleException {
  const StudyScheduleException({
    required this.date,
    required this.type,
    this.overrideMinutes,
    this.reason = '',
  });

  final DateTime date;
  final StudyScheduleExceptionType type;
  final int? overrideMinutes;
  final String reason;

  factory StudyScheduleException.create({
    required DateTime date,
    required StudyScheduleExceptionType type,
    int? overrideMinutes,
    String reason = '',
  }) {
    if (overrideMinutes != null && overrideMinutes <= 0) {
      throw ArgumentError.value(
        overrideMinutes,
        'overrideMinutes',
        'Override minutes must be positive.',
      );
    }

    if ((type == StudyScheduleExceptionType.overrideMinutes ||
            type == StudyScheduleExceptionType.extraStudyDay) &&
        overrideMinutes == null) {
      throw ArgumentError('${type.name} requires overrideMinutes.');
    }

    return StudyScheduleException(
      date: DateTime(date.year, date.month, date.day),
      type: type,
      overrideMinutes: overrideMinutes,
      reason: reason.trim(),
    );
  }

  bool get removesStudy =>
      type == StudyScheduleExceptionType.unavailable ||
      type == StudyScheduleExceptionType.travel ||
      type == StudyScheduleExceptionType.leave ||
      type == StudyScheduleExceptionType.holiday;

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'type': type.name,
      'overrideMinutes': overrideMinutes,
      'reason': reason,
    };
  }

  factory StudyScheduleException.fromJson(Map<String, dynamic> json) {
    final date = DateTime.tryParse(json['date']?.toString() ?? '');
    if (date == null) {
      throw const FormatException(
        'Study schedule exception contains an invalid date.',
      );
    }

    final rawType = json['type']?.toString();
    StudyScheduleExceptionType? type;
    for (final candidate in StudyScheduleExceptionType.values) {
      if (candidate.name == rawType) {
        type = candidate;
        break;
      }
    }

    if (type == null) {
      throw FormatException('Unknown study schedule exception type: $rawType');
    }

    final rawOverride = json['overrideMinutes'];
    final overrideMinutes = rawOverride is num
        ? rawOverride.toInt()
        : int.tryParse(rawOverride?.toString() ?? '');

    return StudyScheduleException.create(
      date: date,
      type: type,
      overrideMinutes: overrideMinutes,
      reason: json['reason']?.toString() ?? '',
    );
  }
}
