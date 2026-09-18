enum ExamTimeHorizon {
  examDayOrPast,
  imminent,
  nearTerm,
  mediumTerm,
  longRange,
}

class StudyCapacitySnapshot {
  const StudyCapacitySnapshot({
    required this.generatedAt,
    required this.examDate,
    required this.calendarDaysRemaining,
    required this.plannedStudyDaysRemaining,
    required this.plannedMinutesRemaining,
    required this.studyDaysThisWeek,
    required this.minutesThisWeek,
    required this.averageMinutesPerStudyDay,
    required this.weeksRemaining,
    required this.examTimeHorizon,
    required this.schemaVersion,
  });

  static const int currentSchemaVersion = 1;

  final DateTime generatedAt;
  final DateTime examDate;
  final int calendarDaysRemaining;
  final int plannedStudyDaysRemaining;
  final int plannedMinutesRemaining;
  final int studyDaysThisWeek;
  final int minutesThisWeek;
  final double averageMinutesPerStudyDay;
  final double weeksRemaining;
  final ExamTimeHorizon examTimeHorizon;
  final int schemaVersion;

  double get plannedHoursRemaining => plannedMinutesRemaining / 60;

  bool get hasRemainingCapacity =>
      calendarDaysRemaining > 0 && plannedMinutesRemaining > 0;

  Map<String, dynamic> toJson() {
    return {
      'generatedAt': generatedAt.toIso8601String(),
      'examDate': examDate.toIso8601String(),
      'calendarDaysRemaining': calendarDaysRemaining,
      'plannedStudyDaysRemaining': plannedStudyDaysRemaining,
      'plannedMinutesRemaining': plannedMinutesRemaining,
      'plannedHoursRemaining': plannedHoursRemaining,
      'studyDaysThisWeek': studyDaysThisWeek,
      'minutesThisWeek': minutesThisWeek,
      'averageMinutesPerStudyDay': averageMinutesPerStudyDay,
      'weeksRemaining': weeksRemaining,
      'examTimeHorizon': examTimeHorizon.name,
      'schemaVersion': schemaVersion,
    };
  }

  factory StudyCapacitySnapshot.fromJson(Map<String, dynamic> json) {
    final generatedAt = DateTime.tryParse(
      json['generatedAt']?.toString() ?? '',
    );
    final examDate = DateTime.tryParse(json['examDate']?.toString() ?? '');

    if (generatedAt == null || examDate == null) {
      throw const FormatException('Capacity snapshot contains invalid dates.');
    }

    final rawHorizon = json['examTimeHorizon']?.toString();
    var horizon = ExamTimeHorizon.longRange;
    for (final candidate in ExamTimeHorizon.values) {
      if (candidate.name == rawHorizon) {
        horizon = candidate;
        break;
      }
    }

    return StudyCapacitySnapshot(
      generatedAt: generatedAt,
      examDate: DateTime(examDate.year, examDate.month, examDate.day),
      calendarDaysRemaining: _asInt(json['calendarDaysRemaining']),
      plannedStudyDaysRemaining: _asInt(json['plannedStudyDaysRemaining']),
      plannedMinutesRemaining: _asInt(json['plannedMinutesRemaining']),
      studyDaysThisWeek: _asInt(json['studyDaysThisWeek']),
      minutesThisWeek: _asInt(json['minutesThisWeek']),
      averageMinutesPerStudyDay: _asDouble(
        json['averageMinutesPerStudyDay'],
      ),
      weeksRemaining: _asDouble(json['weeksRemaining']),
      examTimeHorizon: horizon,
      schemaVersion: _asInt(
        json['schemaVersion'],
        fallback: currentSchemaVersion,
      ),
    );
  }
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double _asDouble(dynamic value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}
