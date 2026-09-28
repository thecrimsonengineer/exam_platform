import 'package:exam_platform/features/exam_readiness/services/planner_constraints.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ERDP-3 daily portfolio constraints', () {
    test('default day protects assessment capacity inside six-block ceiling', () {
      const constraints = DailyPlannerConstraints();

      expect(constraints.maxCompetenciesPerDay, 2);
      expect(constraints.maxBlocksPerDay, 6);
    });

    test('custom competency breadth remains configurable', () {
      const constraints = DailyPlannerConstraints(maxCompetenciesPerDay: 3);

      expect(constraints.maxCompetenciesPerDay, 3);
      expect(() => constraints.validate(), returnsNormally);
    });
  });
}
