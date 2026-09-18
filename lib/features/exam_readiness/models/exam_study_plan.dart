enum ExamPlanIntensity { light, standard, intensive }

enum PreferredStudyPeriod { flexible, morning, afternoon, evening }

class ExamStudyPlan {
  const ExamStudyPlan({
    required this.id,
    required this.userId,
    required this.examDate,
    required this.timezone,
    required this.createdAt,
    required this.updatedAt,
    required this.active,
    required this.planVersion,
    required this.studyDaysOfWeek,
    required this.defaultMinutesPerStudyDay,
    required this.daySpecificMinutes,
    required this.preferredRestDays,
    required this.allowWeekendExtension,
    required this.maxDailyMinutes,
    required this.intensity,
    required this.preferredSessionLength,
    required this.preferredStartPeriod,
    required this.adaptiveSchedulingEnabled,
    required this.source,
    required this.schemaVersion,
  });

  static const int currentSchemaVersion = 1;

  final String id;
  final String userId;
  final DateTime examDate;
  final String timezone;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool active;
  final int planVersion;
  final Set<int> studyDaysOfWeek;
  final int defaultMinutesPerStudyDay;
  final Map<int, int> daySpecificMinutes;
  final Set<int> preferredRestDays;
  final bool allowWeekendExtension;
  final int maxDailyMinutes;
  final ExamPlanIntensity intensity;
  final int preferredSessionLength;
  final PreferredStudyPeriod preferredStartPeriod;
  final bool adaptiveSchedulingEnabled;
  final String source;
  final int schemaVersion;

  factory ExamStudyPlan.create({
    required String id,
    required String userId,
    required DateTime examDate,
    required Set<int> studyDaysOfWeek,
    required int defaultMinutesPerStudyDay,
    String timezone = 'local',
    Map<int, int> daySpecificMinutes = const <int, int>{},
    Set<int> preferredRestDays = const <int>{},
    bool allowWeekendExtension = false,
    int maxDailyMinutes = 240,
    ExamPlanIntensity intensity = ExamPlanIntensity.standard,
    int preferredSessionLength = 30,
    PreferredStudyPeriod preferredStartPeriod = PreferredStudyPeriod.flexible,
    bool adaptiveSchedulingEnabled = true,
    String source = 'learner',
    DateTime? now,
  }) {
    final normalizedId = id.trim();
    final normalizedUserId = userId.trim();
    final normalizedTimezone = timezone.trim();
    final normalizedSource = source.trim();
    final created = now ?? DateTime.now();

    if (normalizedId.isEmpty) {
      throw ArgumentError.value(id, 'id', 'Plan ID cannot be empty.');
    }
    if (normalizedUserId.isEmpty) {
      throw ArgumentError.value(
        userId,
        'userId',
        'Learner user ID cannot be empty.',
      );
    }
    if (normalizedTimezone.isEmpty) {
      throw ArgumentError.value(
        timezone,
        'timezone',
        'Timezone cannot be empty.',
      );
    }
    if (studyDaysOfWeek.isEmpty) {
      throw ArgumentError.value(
        studyDaysOfWeek,
        'studyDaysOfWeek',
        'Select at least one study day.',
      );
    }
    _validateWeekdays(studyDaysOfWeek, 'studyDaysOfWeek');
    _validateWeekdays(preferredRestDays, 'preferredRestDays');

    if (defaultMinutesPerStudyDay <= 0) {
      throw ArgumentError.value(
        defaultMinutesPerStudyDay,
        'defaultMinutesPerStudyDay',
        'Daily study minutes must be positive.',
      );
    }
    if (maxDailyMinutes <= 0) {
      throw ArgumentError.value(
        maxDailyMinutes,
        'maxDailyMinutes',
        'Maximum daily minutes must be positive.',
      );
    }
    if (defaultMinutesPerStudyDay > maxDailyMinutes) {
      throw ArgumentError(
        'Default daily minutes cannot exceed maxDailyMinutes.',
      );
    }
    if (preferredSessionLength <= 0 ||
        preferredSessionLength > maxDailyMinutes) {
      throw ArgumentError.value(
        preferredSessionLength,
        'preferredSessionLength',
        'Preferred session length must be within the daily limit.',
      );
    }

    for (final entry in daySpecificMinutes.entries) {
      _validateWeekdays({entry.key}, 'daySpecificMinutes');
      if (entry.value <= 0 || entry.value > maxDailyMinutes) {
        throw ArgumentError.value(
          entry.value,
          'daySpecificMinutes',
          'Day-specific minutes must be positive and within maxDailyMinutes.',
        );
      }
    }

    if (normalizedSource.isEmpty) {
      throw ArgumentError.value(source, 'source', 'Source cannot be empty.');
    }

    return ExamStudyPlan(
      id: normalizedId,
      userId: normalizedUserId,
      examDate: dateOnly(examDate),
      timezone: normalizedTimezone,
      createdAt: created,
      updatedAt: created,
      active: true,
      planVersion: 1,
      studyDaysOfWeek: Set<int>.unmodifiable(studyDaysOfWeek),
      defaultMinutesPerStudyDay: defaultMinutesPerStudyDay,
      daySpecificMinutes: Map<int, int>.unmodifiable(daySpecificMinutes),
      preferredRestDays: Set<int>.unmodifiable(preferredRestDays),
      allowWeekendExtension: allowWeekendExtension,
      maxDailyMinutes: maxDailyMinutes,
      intensity: intensity,
      preferredSessionLength: preferredSessionLength,
      preferredStartPeriod: preferredStartPeriod,
      adaptiveSchedulingEnabled: adaptiveSchedulingEnabled,
      source: normalizedSource,
      schemaVersion: currentSchemaVersion,
    );
  }

  int minutesForWeekday(int weekday) {
    if (weekday < DateTime.monday || weekday > DateTime.sunday) {
      throw ArgumentError.value(
        weekday,
        'weekday',
        'Weekday must be DateTime.monday through DateTime.sunday.',
      );
    }

    if (!studyDaysOfWeek.contains(weekday) ||
        preferredRestDays.contains(weekday)) {
      return 0;
    }

    final minutes = daySpecificMinutes[weekday] ?? defaultMinutesPerStudyDay;
    return minutes.clamp(0, maxDailyMinutes);
  }

  ExamStudyPlan copyWith({
    String? id,
    String? userId,
    DateTime? examDate,
    String? timezone,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? active,
    int? planVersion,
    Set<int>? studyDaysOfWeek,
    int? defaultMinutesPerStudyDay,
    Map<int, int>? daySpecificMinutes,
    Set<int>? preferredRestDays,
    bool? allowWeekendExtension,
    int? maxDailyMinutes,
    ExamPlanIntensity? intensity,
    int? preferredSessionLength,
    PreferredStudyPeriod? preferredStartPeriod,
    bool? adaptiveSchedulingEnabled,
    String? source,
    int? schemaVersion,
  }) {
    return ExamStudyPlan(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      examDate: examDate == null ? this.examDate : dateOnly(examDate),
      timezone: timezone ?? this.timezone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      active: active ?? this.active,
      planVersion: planVersion ?? this.planVersion,
      studyDaysOfWeek: Set<int>.unmodifiable(
        studyDaysOfWeek ?? this.studyDaysOfWeek,
      ),
      defaultMinutesPerStudyDay:
          defaultMinutesPerStudyDay ?? this.defaultMinutesPerStudyDay,
      daySpecificMinutes: Map<int, int>.unmodifiable(
        daySpecificMinutes ?? this.daySpecificMinutes,
      ),
      preferredRestDays: Set<int>.unmodifiable(
        preferredRestDays ?? this.preferredRestDays,
      ),
      allowWeekendExtension:
          allowWeekendExtension ?? this.allowWeekendExtension,
      maxDailyMinutes: maxDailyMinutes ?? this.maxDailyMinutes,
      intensity: intensity ?? this.intensity,
      preferredSessionLength:
          preferredSessionLength ?? this.preferredSessionLength,
      preferredStartPeriod:
          preferredStartPeriod ?? this.preferredStartPeriod,
      adaptiveSchedulingEnabled:
          adaptiveSchedulingEnabled ?? this.adaptiveSchedulingEnabled,
      source: source ?? this.source,
      schemaVersion: schemaVersion ?? this.schemaVersion,
    );
  }

  ExamStudyPlan nextVersion({
    required DateTime updatedAt,
    DateTime? examDate,
    Set<int>? studyDaysOfWeek,
    int? defaultMinutesPerStudyDay,
    Map<int, int>? daySpecificMinutes,
    Set<int>? preferredRestDays,
  }) {
    return copyWith(
      examDate: examDate,
      studyDaysOfWeek: studyDaysOfWeek,
      defaultMinutesPerStudyDay: defaultMinutesPerStudyDay,
      daySpecificMinutes: daySpecificMinutes,
      preferredRestDays: preferredRestDays,
      updatedAt: updatedAt,
      planVersion: planVersion + 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'examDate': examDate.toIso8601String(),
      'timezone': timezone,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'active': active,
      'planVersion': planVersion,
      'studyDaysOfWeek': studyDaysOfWeek.toList()..sort(),
      'defaultMinutesPerStudyDay': defaultMinutesPerStudyDay,
      'daySpecificMinutes': daySpecificMinutes.map(
        (key, value) => MapEntry(key.toString(), value),
      ),
      'preferredRestDays': preferredRestDays.toList()..sort(),
      'allowWeekendExtension': allowWeekendExtension,
      'maxDailyMinutes': maxDailyMinutes,
      'intensity': intensity.name,
      'preferredSessionLength': preferredSessionLength,
      'preferredStartPeriod': preferredStartPeriod.name,
      'adaptiveSchedulingEnabled': adaptiveSchedulingEnabled,
      'source': source,
      'schemaVersion': schemaVersion,
    };
  }

  factory ExamStudyPlan.fromJson(Map<String, dynamic> json) {
    final examDate = DateTime.tryParse(json['examDate']?.toString() ?? '');
    final createdAt = DateTime.tryParse(json['createdAt']?.toString() ?? '');
    final updatedAt = DateTime.tryParse(json['updatedAt']?.toString() ?? '');

    if (examDate == null || createdAt == null || updatedAt == null) {
      throw const FormatException('Exam study plan contains invalid dates.');
    }

    final studyDays = _intSet(json['studyDaysOfWeek']);
    final restDays = _intSet(json['preferredRestDays']);
    _validateWeekdays(studyDays, 'studyDaysOfWeek');
    _validateWeekdays(restDays, 'preferredRestDays');

    final rawDaySpecific = json['daySpecificMinutes'];
    final daySpecific = <int, int>{};
    if (rawDaySpecific is Map) {
      for (final entry in rawDaySpecific.entries) {
        final weekday = int.tryParse(entry.key.toString());
        final minutes = _toInt(entry.value);
        if (weekday != null && minutes > 0) {
          daySpecific[weekday] = minutes;
        }
      }
    }

    return ExamStudyPlan(
      id: json['id']?.toString().trim() ?? '',
      userId: json['userId']?.toString().trim() ?? '',
      examDate: dateOnly(examDate),
      timezone: json['timezone']?.toString().trim() ?? 'local',
      createdAt: createdAt,
      updatedAt: updatedAt,
      active: json['active'] != false,
      planVersion: _toInt(json['planVersion'], fallback: 1),
      studyDaysOfWeek: Set<int>.unmodifiable(studyDays),
      defaultMinutesPerStudyDay: _toInt(
        json['defaultMinutesPerStudyDay'],
        fallback: 60,
      ),
      daySpecificMinutes: Map<int, int>.unmodifiable(daySpecific),
      preferredRestDays: Set<int>.unmodifiable(restDays),
      allowWeekendExtension: json['allowWeekendExtension'] == true,
      maxDailyMinutes: _toInt(json['maxDailyMinutes'], fallback: 240),
      intensity: _enumByName(
        ExamPlanIntensity.values,
        json['intensity']?.toString(),
        ExamPlanIntensity.standard,
      ),
      preferredSessionLength: _toInt(
        json['preferredSessionLength'],
        fallback: 30,
      ),
      preferredStartPeriod: _enumByName(
        PreferredStudyPeriod.values,
        json['preferredStartPeriod']?.toString(),
        PreferredStudyPeriod.flexible,
      ),
      adaptiveSchedulingEnabled: json['adaptiveSchedulingEnabled'] != false,
      source: json['source']?.toString().trim() ?? 'learner',
      schemaVersion: _toInt(
        json['schemaVersion'],
        fallback: currentSchemaVersion,
      ),
    );
  }

  static DateTime dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static void _validateWeekdays(Set<int> values, String name) {
    for (final weekday in values) {
      if (weekday < DateTime.monday || weekday > DateTime.sunday) {
        throw ArgumentError.value(
          weekday,
          name,
          'Weekday must be DateTime.monday through DateTime.sunday.',
        );
      }
    }
  }
}

Set<int> _intSet(dynamic value) {
  if (value is! Iterable) {
    return <int>{};
  }
  return value.map(_toInt).where((item) => item > 0).toSet();
}

int _toInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

T _enumByName<T extends Enum>(List<T> values, String? name, T fallback) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  return fallback;
}
