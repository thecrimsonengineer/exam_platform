import 'package:exam_platform/features/exam_readiness/models/exam_study_plan.dart';
import 'package:flutter_test/flutter_test.dart';

ExamStudyPlan _plan({
  String id = 'plan-1',
  String userId = 'user-1',
  DateTime? examDate,
  Set<int> studyDays = const {1, 2, 3, 5, 6},
  int minutes = 60,
  Map<int, int> daySpecific = const {},
  Set<int> restDays = const {},
  int maxDailyMinutes = 240,
  int sessionLength = 30,
}) {
  return ExamStudyPlan.create(
    id: id,
    userId: userId,
    examDate: examDate ?? DateTime(2026, 12, 15, 18, 30),
    studyDaysOfWeek: studyDays,
    defaultMinutesPerStudyDay: minutes,
    daySpecificMinutes: daySpecific,
    preferredRestDays: restDays,
    maxDailyMinutes: maxDailyMinutes,
    preferredSessionLength: sessionLength,
    now: DateTime(2026, 9, 18, 10),
  );
}

void main() {
  group('M7A ExamStudyPlan', () {
    test('creates a valid plan with normalized exam date', () {
      final plan = _plan();

      expect(plan.examDate, DateTime(2026, 12, 15));
      expect(plan.active, isTrue);
      expect(plan.planVersion, 1);
      expect(plan.schemaVersion, ExamStudyPlan.currentSchemaVersion);
    });

    test('trims plan ID and user ID', () {
      final plan = _plan(id: '  plan-1  ', userId: '  user-1  ');

      expect(plan.id, 'plan-1');
      expect(plan.userId, 'user-1');
    });

    test('rejects empty plan ID', () {
      expect(() => _plan(id: '   '), throwsArgumentError);
    });

    test('rejects empty user ID', () {
      expect(() => _plan(userId: '   '), throwsArgumentError);
    });

    test('rejects empty study-day set', () {
      expect(() => _plan(studyDays: const {}), throwsArgumentError);
    });

    test('rejects weekday below Monday', () {
      expect(() => _plan(studyDays: const {0}), throwsArgumentError);
    });

    test('rejects weekday above Sunday', () {
      expect(() => _plan(studyDays: const {8}), throwsArgumentError);
    });

    test('rejects zero default minutes', () {
      expect(() => _plan(minutes: 0), throwsArgumentError);
    });

    test('rejects negative default minutes', () {
      expect(() => _plan(minutes: -10), throwsArgumentError);
    });

    test('rejects default minutes above daily maximum', () {
      expect(
        () => _plan(minutes: 300, maxDailyMinutes: 240),
        throwsArgumentError,
      );
    });

    test('rejects non-positive maximum daily minutes', () {
      expect(() => _plan(maxDailyMinutes: 0), throwsArgumentError);
    });

    test('rejects preferred session beyond daily maximum', () {
      expect(
        () => _plan(maxDailyMinutes: 60, sessionLength: 90),
        throwsArgumentError,
      );
    });

    test('rejects invalid day-specific weekday', () {
      expect(() => _plan(daySpecific: const {8: 45}), throwsArgumentError);
    });

    test('rejects non-positive day-specific minutes', () {
      expect(() => _plan(daySpecific: const {1: 0}), throwsArgumentError);
    });

    test('uses default minutes on selected study day', () {
      final plan = _plan();

      expect(plan.minutesForWeekday(DateTime.monday), 60);
    });

    test('uses day-specific minutes when configured', () {
      final plan = _plan(daySpecific: const {1: 90});

      expect(plan.minutesForWeekday(DateTime.monday), 90);
    });

    test('returns zero on non-study day', () {
      final plan = _plan();

      expect(plan.minutesForWeekday(DateTime.thursday), 0);
    });

    test('preferred rest day overrides selected study day', () {
      final plan = _plan(restDays: const {1});

      expect(plan.minutesForWeekday(DateTime.monday), 0);
    });

    test('minutesForWeekday rejects invalid weekday', () {
      final plan = _plan();

      expect(() => plan.minutesForWeekday(0), throwsArgumentError);
    });

    test('round trips through JSON without losing schedule', () {
      final original = _plan(
        daySpecific: const {1: 90, 6: 120},
        restDays: const {3},
      );

      final decoded = ExamStudyPlan.fromJson(original.toJson());

      expect(decoded.id, original.id);
      expect(decoded.userId, original.userId);
      expect(decoded.examDate, original.examDate);
      expect(decoded.studyDaysOfWeek, original.studyDaysOfWeek);
      expect(decoded.daySpecificMinutes, original.daySpecificMinutes);
      expect(decoded.preferredRestDays, original.preferredRestDays);
    });

    test('fromJson rejects invalid date payload', () {
      final json = _plan().toJson()..['examDate'] = 'not-a-date';

      expect(() => ExamStudyPlan.fromJson(json), throwsFormatException);
    });

    test('nextVersion increments version and updates timestamp', () {
      final plan = _plan();
      final updatedAt = DateTime(2026, 9, 19, 12);

      final next = plan.nextVersion(
        updatedAt: updatedAt,
        defaultMinutesPerStudyDay: 90,
      );

      expect(next.planVersion, 2);
      expect(next.updatedAt, updatedAt);
      expect(next.defaultMinutesPerStudyDay, 90);
      expect(next.createdAt, plan.createdAt);
    });

    test('copyWith can deactivate without changing ownership', () {
      final plan = _plan();

      final inactive = plan.copyWith(active: false);

      expect(inactive.active, isFalse);
      expect(inactive.userId, plan.userId);
      expect(inactive.id, plan.id);
    });

    test('dateOnly strips time components', () {
      final value = ExamStudyPlan.dateOnly(DateTime(2026, 9, 18, 23, 59, 59));

      expect(value, DateTime(2026, 9, 18));
    });
  });
}
