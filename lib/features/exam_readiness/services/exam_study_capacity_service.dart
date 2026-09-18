import '../models/exam_study_plan.dart';
import '../models/study_capacity_snapshot.dart';
import '../models/study_schedule_exception.dart';

class ExamStudyCapacityService {
  const ExamStudyCapacityService();

  StudyCapacitySnapshot calculate({
    required ExamStudyPlan plan,
    DateTime? now,
    Iterable<StudyScheduleException> exceptions = const [],
  }) {
    final generatedAt = now ?? DateTime.now();
    final today = ExamStudyPlan.dateOnly(generatedAt);
    final examDate = ExamStudyPlan.dateOnly(plan.examDate);
    final daysRemaining = examDate.difference(today).inDays;

    if (daysRemaining <= 0) {
      return StudyCapacitySnapshot(
        generatedAt: generatedAt,
        examDate: examDate,
        calendarDaysRemaining: 0,
        plannedStudyDaysRemaining: 0,
        plannedMinutesRemaining: 0,
        studyDaysThisWeek: 0,
        minutesThisWeek: 0,
        averageMinutesPerStudyDay: 0,
        weeksRemaining: 0,
        examTimeHorizon: ExamTimeHorizon.examDayOrPast,
        schemaVersion: StudyCapacitySnapshot.currentSchemaVersion,
      );
    }

    final exceptionsByDate = <String, List<StudyScheduleException>>{};
    for (final exception in exceptions) {
      exceptionsByDate
          .putIfAbsent(_dateKey(exception.date), () => [])
          .add(exception);
    }

    var studyDays = 0;
    var totalMinutes = 0;
    var studyDaysThisWeek = 0;
    var minutesThisWeek = 0;

    final endOfCurrentWeek = today.add(
      Duration(days: DateTime.sunday - today.weekday),
    );

    for (
      var cursor = today;
      cursor.isBefore(examDate);
      cursor = cursor.add(const Duration(days: 1))
    ) {
      final minutes = minutesForDate(
        plan: plan,
        date: cursor,
        exceptions: exceptionsByDate[_dateKey(cursor)] ?? const [],
      );

      if (minutes <= 0) {
        continue;
      }

      studyDays++;
      totalMinutes += minutes;

      if (!cursor.isAfter(endOfCurrentWeek)) {
        studyDaysThisWeek++;
        minutesThisWeek += minutes;
      }
    }

    return StudyCapacitySnapshot(
      generatedAt: generatedAt,
      examDate: examDate,
      calendarDaysRemaining: daysRemaining,
      plannedStudyDaysRemaining: studyDays,
      plannedMinutesRemaining: totalMinutes,
      studyDaysThisWeek: studyDaysThisWeek,
      minutesThisWeek: minutesThisWeek,
      averageMinutesPerStudyDay: studyDays == 0 ? 0 : totalMinutes / studyDays,
      weeksRemaining: daysRemaining / 7,
      examTimeHorizon: _horizon(daysRemaining),
      schemaVersion: StudyCapacitySnapshot.currentSchemaVersion,
    );
  }

  int minutesForDate({
    required ExamStudyPlan plan,
    required DateTime date,
    Iterable<StudyScheduleException> exceptions = const [],
  }) {
    final day = ExamStudyPlan.dateOnly(date);
    final dailyExceptions = exceptions
        .where((exception) => _dateKey(exception.date) == _dateKey(day))
        .toList(growable: false);

    if (dailyExceptions.any((exception) => exception.removesStudy)) {
      return 0;
    }

    final explicitOverride = dailyExceptions
        .where(
          (exception) =>
              exception.type == StudyScheduleExceptionType.overrideMinutes ||
              exception.type == StudyScheduleExceptionType.extraStudyDay,
        )
        .toList(growable: false);

    if (explicitOverride.isNotEmpty) {
      return _clampMinutes(
        explicitOverride.last.overrideMinutes ?? 0,
        plan.maxDailyMinutes,
      );
    }

    final intensive = dailyExceptions
        .where(
          (exception) =>
              exception.type == StudyScheduleExceptionType.intensiveRevisionDay,
        )
        .toList(growable: false);

    if (intensive.isNotEmpty) {
      return _clampMinutes(
        intensive.last.overrideMinutes ?? plan.maxDailyMinutes,
        plan.maxDailyMinutes,
      );
    }

    return _clampMinutes(
      plan.minutesForWeekday(day.weekday),
      plan.maxDailyMinutes,
    );
  }

  ExamTimeHorizon _horizon(int daysRemaining) {
    if (daysRemaining <= 0) {
      return ExamTimeHorizon.examDayOrPast;
    }
    if (daysRemaining <= 14) {
      return ExamTimeHorizon.imminent;
    }
    if (daysRemaining <= 30) {
      return ExamTimeHorizon.nearTerm;
    }
    if (daysRemaining <= 60) {
      return ExamTimeHorizon.mediumTerm;
    }
    return ExamTimeHorizon.longRange;
  }

  int _clampMinutes(int value, int maxDailyMinutes) {
    if (value <= 0) return 0;
    if (value > maxDailyMinutes) return maxDailyMinutes;
    return value;
  }

  String _dateKey(DateTime value) {
    final date = ExamStudyPlan.dateOnly(value);
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
