import 'package:exam_platform/features/exam_readiness/models/exam_study_plan.dart';
import 'package:exam_platform/features/exam_readiness/models/study_capacity_snapshot.dart';
import 'package:exam_platform/features/exam_readiness/models/study_schedule_exception.dart';
import 'package:exam_platform/features/exam_readiness/services/exam_study_capacity_service.dart';
import 'package:flutter_test/flutter_test.dart';

const service = ExamStudyCapacityService();

ExamStudyPlan _plan({
  DateTime? examDate,
  Set<int> days = const {1, 2, 3, 4, 5},
  int minutes = 60,
  Map<int, int> daySpecific = const {},
  Set<int> restDays = const {},
  int maxDaily = 240,
}) {
  return ExamStudyPlan.create(
    id: 'plan',
    userId: 'user',
    examDate: examDate ?? DateTime(2026, 9, 28),
    studyDaysOfWeek: days,
    defaultMinutesPerStudyDay: minutes,
    daySpecificMinutes: daySpecific,
    preferredRestDays: restDays,
    maxDailyMinutes: maxDaily,
    now: DateTime(2026, 9, 21, 9),
  );
}

StudyScheduleException _exception(
  DateTime date,
  StudyScheduleExceptionType type, {
  int? minutes,
}) {
  if (type == StudyScheduleExceptionType.overrideMinutes ||
      type == StudyScheduleExceptionType.extraStudyDay) {
    return StudyScheduleException.create(
      date: date,
      type: type,
      overrideMinutes: minutes ?? 60,
    );
  }
  return StudyScheduleException.create(
    date: date,
    type: type,
    overrideMinutes: minutes,
  );
}

void main() {
  group('M7A ExamStudyCapacityService', () {
    test('exam today has zero remaining capacity', () {
      final snapshot = service.calculate(
        plan: _plan(examDate: DateTime(2026, 9, 21)),
        now: DateTime(2026, 9, 21, 18),
      );

      expect(snapshot.calendarDaysRemaining, 0);
      expect(snapshot.plannedStudyDaysRemaining, 0);
      expect(snapshot.plannedMinutesRemaining, 0);
      expect(snapshot.examTimeHorizon, ExamTimeHorizon.examDayOrPast);
    });

    test('past exam date has zero remaining capacity', () {
      final snapshot = service.calculate(
        plan: _plan(examDate: DateTime(2026, 9, 20)),
        now: DateTime(2026, 9, 21),
      );

      expect(snapshot.calendarDaysRemaining, 0);
      expect(snapshot.hasRemainingCapacity, isFalse);
    });

    test('tomorrow exam counts today but excludes exam day', () {
      final snapshot = service.calculate(
        plan: _plan(
          examDate: DateTime(2026, 9, 22),
          days: const {DateTime.monday, DateTime.tuesday},
        ),
        now: DateTime(2026, 9, 21),
      );

      expect(snapshot.calendarDaysRemaining, 1);
      expect(snapshot.plannedStudyDaysRemaining, 1);
      expect(snapshot.plannedMinutesRemaining, 60);
    });

    test('five weekday schedule counts five days in a seven-day window', () {
      final snapshot = service.calculate(
        plan: _plan(examDate: DateTime(2026, 9, 28)),
        now: DateTime(2026, 9, 21),
      );

      expect(snapshot.calendarDaysRemaining, 7);
      expect(snapshot.plannedStudyDaysRemaining, 5);
      expect(snapshot.plannedMinutesRemaining, 300);
    });

    test('seven-day schedule counts all seven days', () {
      final snapshot = service.calculate(
        plan: _plan(
          examDate: DateTime(2026, 9, 28),
          days: const {1, 2, 3, 4, 5, 6, 7},
        ),
        now: DateTime(2026, 9, 21),
      );

      expect(snapshot.plannedStudyDaysRemaining, 7);
      expect(snapshot.plannedMinutesRemaining, 420);
    });

    test('one-day weekly schedule counts only matching weekday', () {
      final snapshot = service.calculate(
        plan: _plan(
          examDate: DateTime(2026, 10, 5),
          days: const {DateTime.monday},
        ),
        now: DateTime(2026, 9, 21),
      );

      expect(snapshot.plannedStudyDaysRemaining, 2);
      expect(snapshot.plannedMinutesRemaining, 120);
    });

    test('day-specific minutes override default minutes', () {
      final snapshot = service.calculate(
        plan: _plan(
          examDate: DateTime(2026, 9, 23),
          days: const {1, 2},
          daySpecific: const {1: 90},
        ),
        now: DateTime(2026, 9, 21),
      );

      expect(snapshot.plannedStudyDaysRemaining, 2);
      expect(snapshot.plannedMinutesRemaining, 150);
    });

    test('preferred rest day removes selected study day', () {
      final snapshot = service.calculate(
        plan: _plan(
          examDate: DateTime(2026, 9, 23),
          days: const {1, 2},
          restDays: const {1},
        ),
        now: DateTime(2026, 9, 21),
      );

      expect(snapshot.plannedStudyDaysRemaining, 1);
      expect(snapshot.plannedMinutesRemaining, 60);
    });

    test('unavailable exception removes planned study day', () {
      final snapshot = service.calculate(
        plan: _plan(examDate: DateTime(2026, 9, 23)),
        now: DateTime(2026, 9, 21),
        exceptions: [
          _exception(
            DateTime(2026, 9, 21),
            StudyScheduleExceptionType.unavailable,
          ),
        ],
      );

      expect(snapshot.plannedStudyDaysRemaining, 1);
      expect(snapshot.plannedMinutesRemaining, 60);
    });

    test('travel exception removes planned study day', () {
      final minutes = service.minutesForDate(
        plan: _plan(),
        date: DateTime(2026, 9, 21),
        exceptions: [
          _exception(DateTime(2026, 9, 21), StudyScheduleExceptionType.travel),
        ],
      );

      expect(minutes, 0);
    });

    test('leave exception removes planned study day', () {
      final minutes = service.minutesForDate(
        plan: _plan(),
        date: DateTime(2026, 9, 21),
        exceptions: [
          _exception(DateTime(2026, 9, 21), StudyScheduleExceptionType.leave),
        ],
      );

      expect(minutes, 0);
    });

    test('holiday exception removes planned study day', () {
      final minutes = service.minutesForDate(
        plan: _plan(),
        date: DateTime(2026, 9, 21),
        exceptions: [
          _exception(DateTime(2026, 9, 21), StudyScheduleExceptionType.holiday),
        ],
      );

      expect(minutes, 0);
    });

    test('extra study day adds capacity on unscheduled day', () {
      final minutes = service.minutesForDate(
        plan: _plan(days: const {DateTime.monday}),
        date: DateTime(2026, 9, 22),
        exceptions: [
          _exception(
            DateTime(2026, 9, 22),
            StudyScheduleExceptionType.extraStudyDay,
            minutes: 75,
          ),
        ],
      );

      expect(minutes, 75);
    });

    test('override minutes replaces scheduled amount', () {
      final minutes = service.minutesForDate(
        plan: _plan(),
        date: DateTime(2026, 9, 21),
        exceptions: [
          _exception(
            DateTime(2026, 9, 21),
            StudyScheduleExceptionType.overrideMinutes,
            minutes: 105,
          ),
        ],
      );

      expect(minutes, 105);
    });

    test('intensive revision defaults to maximum daily minutes', () {
      final minutes = service.minutesForDate(
        plan: _plan(days: const {DateTime.monday}, maxDaily: 180),
        date: DateTime(2026, 9, 22),
        exceptions: [
          _exception(
            DateTime(2026, 9, 22),
            StudyScheduleExceptionType.intensiveRevisionDay,
          ),
        ],
      );

      expect(minutes, 180);
    });

    test('intensive revision accepts explicit minutes', () {
      final minutes = service.minutesForDate(
        plan: _plan(maxDaily: 180),
        date: DateTime(2026, 9, 21),
        exceptions: [
          StudyScheduleException(
            date: DateTime(2026, 9, 21),
            type: StudyScheduleExceptionType.intensiveRevisionDay,
            overrideMinutes: 150,
          ),
        ],
      );

      expect(minutes, 150);
    });

    test('removal exception wins over minute override', () {
      final minutes = service.minutesForDate(
        plan: _plan(),
        date: DateTime(2026, 9, 21),
        exceptions: [
          _exception(
            DateTime(2026, 9, 21),
            StudyScheduleExceptionType.overrideMinutes,
            minutes: 120,
          ),
          _exception(
            DateTime(2026, 9, 21),
            StudyScheduleExceptionType.unavailable,
          ),
        ],
      );

      expect(minutes, 0);
    });

    test('exception minutes are clamped to daily maximum', () {
      final minutes = service.minutesForDate(
        plan: _plan(maxDaily: 120),
        date: DateTime(2026, 9, 21),
        exceptions: [
          StudyScheduleException(
            date: DateTime(2026, 9, 21),
            type: StudyScheduleExceptionType.overrideMinutes,
            overrideMinutes: 300,
          ),
        ],
      );

      expect(minutes, 120);
    });

    test('current-week capacity stops at Sunday', () {
      final snapshot = service.calculate(
        plan: _plan(
          examDate: DateTime(2026, 10, 5),
          days: const {1, 2, 3, 4, 5, 6, 7},
        ),
        now: DateTime(2026, 9, 21),
      );

      expect(snapshot.studyDaysThisWeek, 7);
      expect(snapshot.minutesThisWeek, 420);
    });

    test('current-week capacity respects an exam before Sunday', () {
      final snapshot = service.calculate(
        plan: _plan(
          examDate: DateTime(2026, 9, 24),
          days: const {1, 2, 3, 4, 5, 6, 7},
        ),
        now: DateTime(2026, 9, 21),
      );

      expect(snapshot.studyDaysThisWeek, 3);
      expect(snapshot.minutesThisWeek, 180);
    });

    test('average minutes divides by actual planned study days', () {
      final snapshot = service.calculate(
        plan: _plan(
          examDate: DateTime(2026, 9, 23),
          days: const {1, 2},
          daySpecific: const {1: 90, 2: 60},
        ),
        now: DateTime(2026, 9, 21),
      );

      expect(snapshot.averageMinutesPerStudyDay, 75);
    });

    test('planned hours are derived from minutes', () {
      final snapshot = service.calculate(
        plan: _plan(examDate: DateTime(2026, 9, 28)),
        now: DateTime(2026, 9, 21),
      );

      expect(snapshot.plannedHoursRemaining, 5);
    });

    test('weeks remaining are derived from calendar days', () {
      final snapshot = service.calculate(
        plan: _plan(examDate: DateTime(2026, 10, 5)),
        now: DateTime(2026, 9, 21),
      );

      expect(snapshot.calendarDaysRemaining, 14);
      expect(snapshot.weeksRemaining, 2);
    });

    test('14 days maps to imminent horizon', () {
      final snapshot = service.calculate(
        plan: _plan(examDate: DateTime(2026, 10, 5)),
        now: DateTime(2026, 9, 21),
      );

      expect(snapshot.examTimeHorizon, ExamTimeHorizon.imminent);
    });

    test('15 days maps to near-term horizon', () {
      final snapshot = service.calculate(
        plan: _plan(examDate: DateTime(2026, 10, 6)),
        now: DateTime(2026, 9, 21),
      );

      expect(snapshot.examTimeHorizon, ExamTimeHorizon.nearTerm);
    });

    test('30 days maps to near-term horizon', () {
      final snapshot = service.calculate(
        plan: _plan(examDate: DateTime(2026, 10, 21)),
        now: DateTime(2026, 9, 21),
      );

      expect(snapshot.examTimeHorizon, ExamTimeHorizon.nearTerm);
    });

    test('31 days maps to medium-term horizon', () {
      final snapshot = service.calculate(
        plan: _plan(examDate: DateTime(2026, 10, 22)),
        now: DateTime(2026, 9, 21),
      );

      expect(snapshot.examTimeHorizon, ExamTimeHorizon.mediumTerm);
    });

    test('60 days maps to medium-term horizon', () {
      final snapshot = service.calculate(
        plan: _plan(examDate: DateTime(2026, 11, 20)),
        now: DateTime(2026, 9, 21),
      );

      expect(snapshot.examTimeHorizon, ExamTimeHorizon.mediumTerm);
    });

    test('61 days maps to long-range horizon', () {
      final snapshot = service.calculate(
        plan: _plan(examDate: DateTime(2026, 11, 21)),
        now: DateTime(2026, 9, 21),
      );

      expect(snapshot.examTimeHorizon, ExamTimeHorizon.longRange);
    });

    test('time of day does not change date-based capacity', () {
      final morning = service.calculate(
        plan: _plan(examDate: DateTime(2026, 9, 28)),
        now: DateTime(2026, 9, 21, 1),
      );
      final evening = service.calculate(
        plan: _plan(examDate: DateTime(2026, 9, 28)),
        now: DateTime(2026, 9, 21, 23, 59),
      );

      expect(evening.calendarDaysRemaining, morning.calendarDaysRemaining);
      expect(evening.plannedMinutesRemaining, morning.plannedMinutesRemaining);
    });

    test('snapshot round trips through JSON', () {
      final snapshot = service.calculate(
        plan: _plan(examDate: DateTime(2026, 9, 28)),
        now: DateTime(2026, 9, 21),
      );

      final decoded = StudyCapacitySnapshot.fromJson(snapshot.toJson());

      expect(decoded.calendarDaysRemaining, snapshot.calendarDaysRemaining);
      expect(decoded.plannedMinutesRemaining, snapshot.plannedMinutesRemaining);
      expect(decoded.examTimeHorizon, snapshot.examTimeHorizon);
    });
  });
}
