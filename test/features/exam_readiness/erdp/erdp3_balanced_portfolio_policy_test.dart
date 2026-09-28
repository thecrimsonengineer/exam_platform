import 'package:exam_platform/features/exam_readiness/models/today_plan_task_category.dart';
import 'package:exam_platform/features/exam_readiness/services/balanced_plan_portfolio_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const policy = BalancedPlanPortfolioPolicy();

  group('ERDP-3 balanced portfolio reservation', () {
    test('60-minute day protects Learn Practice and Remember floors', () {
      final reservation = policy.reservationFor(availableMinutes: 60);

      expect(reservation.isActive, isTrue);
      expect(reservation.learnMinutes, 15);
      expect(reservation.practiceMinutes, 5);
      expect(reservation.rememberMinutes, 5);
      expect(reservation.totalMinutes, 25);
    });

    test('already represented Learn only reserves missing families', () {
      final reservation = policy.reservationFor(
        availableMinutes: 60,
        committedMinutes: 50,
        representedCategories: const <TodayPlanTaskCategory>{
          TodayPlanTaskCategory.learn,
        },
      );

      expect(reservation.learnMinutes, 0);
      expect(reservation.practiceMinutes, 5);
      expect(reservation.rememberMinutes, 5);
      expect(reservation.totalMinutes, 10);
    });

    test('insufficient capacity does not force an impossible portfolio', () {
      final reservation = policy.reservationFor(availableMinutes: 20);

      expect(reservation.isActive, isFalse);
      expect(reservation.totalMinutes, 0);
    });

    test('fully represented portfolio requires no further reservation', () {
      final reservation = policy.reservationFor(
        availableMinutes: 60,
        representedCategories: TodayPlanTaskCategory.values.toSet(),
      );

      expect(reservation.isActive, isFalse);
      expect(reservation.totalMinutes, 0);
    });

    test('negative capacity normalizes safely to zero', () {
      final reservation = policy.reservationFor(availableMinutes: -10);

      expect(reservation.totalMinutes, 0);
    });
  });
}
