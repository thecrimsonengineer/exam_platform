import 'package:exam_platform/features/exam_readiness/models/capacity_pressure_snapshot.dart';
import 'package:exam_platform/features/exam_readiness/models/exam_preparation_phase.dart';
import 'package:exam_platform/features/exam_readiness/models/readiness_gap.dart';
import 'package:exam_platform/features/exam_readiness/services/capacity_pressure_service.dart';
import 'package:exam_platform/features/exam_readiness/services/exam_preparation_phase_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../m7d/_support/m7d_fixture.dart';
import '_support/m7f_fixture.dart';

void main() {
  group('M7F exam preparation phase', () {
    const service = ExamPreparationPhaseService();

    test('61 days is foundation', () {
      expect(
        service.phaseForDaysRemaining(61),
        ExamPreparationPhase.foundation,
      );
    });

    test('60 days is integration', () {
      expect(
        service.phaseForDaysRemaining(60),
        ExamPreparationPhase.integration,
      );
    });

    test('31 days is integration', () {
      expect(
        service.phaseForDaysRemaining(31),
        ExamPreparationPhase.integration,
      );
    });

    test('30 days is readiness', () {
      expect(
        service.phaseForDaysRemaining(30),
        ExamPreparationPhase.readiness,
      );
    });

    test('15 days is readiness', () {
      expect(
        service.phaseForDaysRemaining(15),
        ExamPreparationPhase.readiness,
      );
    });

    test('14 days is consolidation', () {
      expect(
        service.phaseForDaysRemaining(14),
        ExamPreparationPhase.consolidation,
      );
    });

    test('exam day is consolidation classification', () {
      expect(
        service.phaseForDaysRemaining(0),
        ExamPreparationPhase.consolidation,
      );
    });

    test('past exam remains consolidation classification', () {
      expect(
        service.phaseForDaysRemaining(-3),
        ExamPreparationPhase.consolidation,
      );
    });

    test('date calculation ignores time of day', () {
      expect(
        service.phaseFor(
          currentDate: DateTime(2026, 9, 18, 23, 59),
          examDate: DateTime(2026, 10, 18, 1),
        ),
        ExamPreparationPhase.readiness,
      );
    });

    test('foundation allocation matches frozen initial direction', () {
      final allocation = service.allocationForDaysRemaining(90);
      expect(allocation.learning, 0.55);
      expect(allocation.practice, 0.20);
      expect(allocation.review, 0.15);
      expect(allocation.diagnostics, 0.10);
      expect(allocation.total, closeTo(1, 0.000001));
    });

    test('every default phase allocation totals one', () {
      const config = ExamPreparationPhaseConfiguration();
      for (final phase in ExamPreparationPhase.values) {
        expect(config.allocationFor(phase).total, closeTo(1, 0.000001));
      }
    });

    test('invalid phase threshold ordering is rejected', () {
      const config = ExamPreparationPhaseConfiguration(
        foundationMinimumDays: 30,
        integrationMinimumDays: 31,
      );
      expect(config.validate, throwsStateError);
    });

    test('invalid allocation total is rejected', () {
      const allocation = PhaseAllocationProfile(
        learning: 0.5,
        practice: 0.5,
        review: 0.5,
        diagnostics: 0,
      );
      expect(allocation.validate, throwsStateError);
    });

    test('phase configuration remains versioned', () {
      const config = ExamPreparationPhaseConfiguration();
      expect(config.version, 'm7f-phase-v1');
    });
  });

  group('M7F capacity pressure', () {
    const service = CapacityPressureService();

    test('no gaps produces low pressure and zero workload', () {
      final snapshot = service.calculate(
        capacity: m7fCapacity(minutes: 600),
        phase: ExamPreparationPhase.integration,
        profiles: [m7dProfile(gaps: const [])],
      );
      expect(snapshot.state, CapacityPressureState.low);
      expect(snapshot.estimatedPriorityWorkloadMinMinutes, 0);
      expect(snapshot.estimatedPriorityWorkloadMaxMinutes, 0);
    });

    test('one high observed gap creates workload range', () {
      final snapshot = service.calculate(
        capacity: m7fCapacity(minutes: 600),
        phase: ExamPreparationPhase.integration,
        profiles: [
          m7dProfile(gaps: [m7dGap(severity: ReadinessGapSeverity.high)]),
        ],
      );
      expect(snapshot.highGapCount, 1);
      expect(snapshot.criticalGapCount, 0);
      expect(snapshot.estimatedPriorityWorkloadMinMinutes, 40);
      expect(snapshot.estimatedPriorityWorkloadMaxMinutes, 60);
    });

    test('one critical observed gap uses critical range', () {
      final snapshot = service.calculate(
        capacity: m7fCapacity(minutes: 600),
        phase: ExamPreparationPhase.integration,
        profiles: [
          m7dProfile(
            gaps: [m7dGap(severity: ReadinessGapSeverity.critical)],
          ),
        ],
      );
      expect(snapshot.criticalGapCount, 1);
      expect(snapshot.estimatedPriorityWorkloadMinMinutes, 60);
      expect(snapshot.estimatedPriorityWorkloadMaxMinutes, 90);
    });

    test('evidence blind spot is kept separate from observed weakness', () {
      final snapshot = service.calculate(
        capacity: m7fCapacity(minutes: 600),
        phase: ExamPreparationPhase.integration,
        profiles: [
          m7dProfile(
            gaps: [
              m7dGap(
                type: ReadinessGapType.evidenceGap,
                severity: ReadinessGapSeverity.critical,
                evidenceLimited: true,
              ),
            ],
          ),
        ],
      );
      expect(snapshot.criticalGapCount, 0);
      expect(snapshot.highGapCount, 0);
      expect(snapshot.evidenceBlindSpotCount, 1);
      expect(snapshot.estimatedPriorityWorkloadMinMinutes, 15);
      expect(snapshot.estimatedPriorityWorkloadMaxMinutes, 25);
    });

    test('evidence limited gap is not counted as observed poor performance', () {
      final snapshot = service.calculate(
        capacity: m7fCapacity(minutes: 600),
        phase: ExamPreparationPhase.integration,
        profiles: [
          m7dProfile(
            gaps: [
              m7dGap(
                severity: ReadinessGapSeverity.high,
                evidenceLimited: true,
              ),
            ],
          ),
        ],
      );
      expect(snapshot.highGapCount, 0);
      expect(snapshot.criticalGapCount, 0);
    });

    test('scheduled review debt is added to both workload bounds', () {
      final snapshot = service.calculate(
        capacity: m7fCapacity(minutes: 600),
        phase: ExamPreparationPhase.integration,
        profiles: [m7dProfile(gaps: const [])],
        scheduledReviewDebtMinutes: 45,
      );
      expect(snapshot.estimatedPriorityWorkloadMinMinutes, 45);
      expect(snapshot.estimatedPriorityWorkloadMaxMinutes, 45);
      expect(snapshot.reasonCodes, contains('SCHEDULED_REVIEW_DEBT'));
    });

    test('foundation phase applies reduced initial workload multiplier', () {
      final snapshot = service.calculate(
        capacity: m7fCapacity(minutes: 600),
        phase: ExamPreparationPhase.foundation,
        profiles: [
          m7dProfile(gaps: [m7dGap(severity: ReadinessGapSeverity.high)]),
        ],
      );
      expect(snapshot.estimatedPriorityWorkloadMinMinutes, 36);
      expect(snapshot.estimatedPriorityWorkloadMaxMinutes, 54);
    });

    test('readiness phase increases initial workload emphasis', () {
      final snapshot = service.calculate(
        capacity: m7fCapacity(minutes: 600),
        phase: ExamPreparationPhase.readiness,
        profiles: [
          m7dProfile(gaps: [m7dGap(severity: ReadinessGapSeverity.high)]),
        ],
      );
      expect(snapshot.estimatedPriorityWorkloadMinMinutes, 44);
      expect(snapshot.estimatedPriorityWorkloadMaxMinutes, 66);
    });

    test('zero capacity with workload is critical', () {
      final snapshot = service.calculate(
        capacity: m7fCapacity(minutes: 0),
        phase: ExamPreparationPhase.integration,
        profiles: [
          m7dProfile(gaps: [m7dGap(severity: ReadinessGapSeverity.high)]),
        ],
      );
      expect(snapshot.state, CapacityPressureState.critical);
    });

    test('workload below 75 percent capacity is low', () {
      final snapshot = service.calculate(
        capacity: m7fCapacity(minutes: 100),
        phase: ExamPreparationPhase.integration,
        profiles: [
          m7dProfile(gaps: [m7dGap(severity: ReadinessGapSeverity.high)]),
        ],
      );
      expect(snapshot.state, CapacityPressureState.low);
    });

    test('workload at capacity is manageable', () {
      final snapshot = service.calculate(
        capacity: m7fCapacity(minutes: 60),
        phase: ExamPreparationPhase.integration,
        profiles: [
          m7dProfile(gaps: [m7dGap(severity: ReadinessGapSeverity.high)]),
        ],
      );
      expect(snapshot.state, CapacityPressureState.manageable);
    });

    test('workload above capacity can become elevated', () {
      final snapshot = service.calculate(
        capacity: m7fCapacity(minutes: 50),
        phase: ExamPreparationPhase.integration,
        profiles: [
          m7dProfile(gaps: [m7dGap(severity: ReadinessGapSeverity.high)]),
        ],
      );
      expect(snapshot.state, CapacityPressureState.elevated);
    });

    test('larger overload can become high', () {
      final snapshot = service.calculate(
        capacity: m7fCapacity(minutes: 45),
        phase: ExamPreparationPhase.integration,
        profiles: [
          m7dProfile(gaps: [m7dGap(severity: ReadinessGapSeverity.high)]),
        ],
      );
      expect(snapshot.state, CapacityPressureState.high);
    });

    test('severe overload becomes critical', () {
      final snapshot = service.calculate(
        capacity: m7fCapacity(minutes: 30),
        phase: ExamPreparationPhase.integration,
        profiles: [
          m7dProfile(gaps: [m7dGap(severity: ReadinessGapSeverity.high)]),
        ],
      );
      expect(snapshot.state, CapacityPressureState.critical);
    });

    test('minimum workload exceeding capacity is explicit', () {
      final snapshot = service.calculate(
        capacity: m7fCapacity(minutes: 30),
        phase: ExamPreparationPhase.integration,
        profiles: [
          m7dProfile(
            gaps: [m7dGap(severity: ReadinessGapSeverity.critical)],
          ),
        ],
      );
      expect(snapshot.demandExceedsCapacity, isTrue);
      expect(
        snapshot.reasonCodes,
        contains('PRIORITY_WORKLOAD_EXCEEDS_CAPACITY'),
      );
    });

    test('capacity pressure output is algorithm versioned', () {
      final snapshot = service.calculate(
        capacity: m7fCapacity(),
        phase: ExamPreparationPhase.integration,
        profiles: [m7dProfile(gaps: const [])],
      );
      expect(snapshot.algorithmVersion, 'm7f-capacity-pressure-v1');
    });

    test('capacity pressure round trips through JSON', () {
      final snapshot = service.calculate(
        capacity: m7fCapacity(minutes: 100),
        phase: ExamPreparationPhase.integration,
        profiles: [
          m7dProfile(gaps: [m7dGap(severity: ReadinessGapSeverity.high)]),
        ],
      );
      final restored = CapacityPressureSnapshot.fromJson(snapshot.toJson());
      expect(restored.state, snapshot.state);
      expect(restored.availableMinutes, snapshot.availableMinutes);
      expect(
        restored.estimatedPriorityWorkloadMaxMinutes,
        snapshot.estimatedPriorityWorkloadMaxMinutes,
      );
    });
  });
}
