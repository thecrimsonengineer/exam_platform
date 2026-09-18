import 'package:exam_platform/data/csp11_blueprint.dart';
import 'package:exam_platform/features/exam_readiness/models/competency_evidence_snapshot.dart';
import 'package:exam_platform/features/exam_readiness/models/evidence_confidence.dart';
import 'package:exam_platform/features/exam_readiness/models/readiness_index_snapshot.dart';
import 'package:exam_platform/features/exam_readiness/models/readiness_trajectory_point.dart';
import 'package:exam_platform/features/exam_readiness/services/advanced_readiness_service.dart';
import 'package:exam_platform/features/exam_readiness/services/readiness_trajectory_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../m7c/_support/m7c_fixture.dart';
import '../m7e/_support/m7e_fixture.dart';
import '_support/m7f_fixture.dart';

Map<String, CompetencyEvidenceSnapshot> _richEvidence({int count = 30}) {
  final ids = [
    for (final domain in csp11Domains)
      for (final competency in domain.competencies) competency.id,
  ];

  return {
    for (final id in ids.take(count))
      id: m7cEvidence(
        competencyId: id,
        totalAttempts: 5,
        correct: 4,
        uniqueQuestions: 5,
        applicationAttempts: 3,
        applicationCorrect: 2,
        analysisAttempts: 2,
        analysisCorrect: 2,
        delayedAttempts: 2,
        delayedCorrect: 2,
        overallConfidence: EvidenceConfidence.high,
      ),
  };
}

ReadinessTrajectoryPoint _historyPoint(DateTime date, double coverage) {
  return ReadinessTrajectoryPoint(
    date: date,
    knowledge: 0.70,
    application: 0.65,
    retention: 0.70,
    coverage: coverage,
    difficulty: 0.65,
    evidenceConfidence: EvidenceConfidence.high,
    algorithmVersion: ReadinessTrajectoryService.currentAlgorithmVersion,
  );
}

void main() {
  const service = AdvancedReadinessService();

  test('sparse evidence withholds Readiness Index', () {
    final result = service.build(
      dashboard: m7fDashboard(),
      evidenceByCompetency: const {},
      capacity: m7fCapacity(minutes: 1200, daysRemaining: 27),
      currentDate: DateTime(2026, 9, 18),
      examDate: DateTime(2026, 10, 15),
      trajectoryHistory: const [],
      dailyPlanHistory: const [],
    );

    expect(
      result.readinessIndex.availability,
      ReadinessIndexAvailability.insufficientEvidence,
    );
    expect(result.readinessIndex.score, isNull);
  });

  test('rich evidence can unlock composite index', () {
    final result = service.build(
      dashboard: m7fDashboard(competenciesTotal: 42, competenciesAssessed: 30),
      evidenceByCompetency: _richEvidence(),
      capacity: m7fCapacity(minutes: 1200, daysRemaining: 27),
      currentDate: DateTime(2026, 9, 18),
      examDate: DateTime(2026, 10, 15),
      trajectoryHistory: const [],
      dailyPlanHistory: const [],
    );

    expect(result.readinessIndex.isAvailable, isTrue);
    expect(result.readinessIndex.score, isNotNull);
  });

  test('evidence confidence remains separate from index score', () {
    final result = service.build(
      dashboard: m7fDashboard(
        evidenceConfidence: EvidenceConfidence.high,
        competenciesTotal: 42,
        competenciesAssessed: 30,
      ),
      evidenceByCompetency: _richEvidence(),
      capacity: m7fCapacity(minutes: 1200, daysRemaining: 27),
      currentDate: DateTime(2026, 9, 18),
      examDate: DateTime(2026, 10, 15),
      trajectoryHistory: const [],
      dailyPlanHistory: const [],
    );

    expect(result.evidenceConfidence, EvidenceConfidence.high);
    expect(result.readinessIndex.evidenceConfidence, EvidenceConfidence.high);
  });

  test('advanced snapshot reports current exam phase', () {
    final result = service.build(
      dashboard: m7fDashboard(),
      evidenceByCompetency: const {},
      capacity: m7fCapacity(daysRemaining: 27),
      currentDate: DateTime(2026, 9, 18),
      examDate: DateTime(2026, 10, 15),
      trajectoryHistory: const [],
      dailyPlanHistory: const [],
    );

    expect(result.phase.name, 'readiness');
    expect(result.reasonCodes, contains('EXAM_PHASE_READINESS'));
  });

  test(
    'advanced snapshot exposes capacity range rather than false precision',
    () {
      final result = service.build(
        dashboard: m7fDashboard(),
        evidenceByCompetency: const {},
        capacity: m7fCapacity(minutes: 100, daysRemaining: 27),
        currentDate: DateTime(2026, 9, 18),
        examDate: DateTime(2026, 10, 15),
        trajectoryHistory: const [],
        dailyPlanHistory: const [],
      );

      expect(
        result.capacityPressure.estimatedPriorityWorkloadMaxMinutes,
        greaterThanOrEqualTo(
          result.capacityPressure.estimatedPriorityWorkloadMinMinutes,
        ),
      );
    },
  );

  test('today plan summary is traceable to block reason text', () {
    final plan = m7ePlan();
    final result = service.build(
      dashboard: m7fDashboard(),
      evidenceByCompetency: const {},
      capacity: m7fCapacity(daysRemaining: 27),
      currentDate: DateTime(2026, 9, 18),
      examDate: DateTime(2026, 10, 15),
      trajectoryHistory: const [],
      dailyPlanHistory: [plan],
      todayPlan: plan,
    );

    expect(result.todayBlockCount, 1);
    expect(result.todayPlanMinutes, 20);
    expect(result.planChangeExplanation, contains('Fixture priority reason.'));
  });

  test('trajectory becomes meaningful with fourteen day local history', () {
    final result = service.build(
      dashboard: m7fDashboard(),
      evidenceByCompetency: const {},
      capacity: m7fCapacity(daysRemaining: 27),
      currentDate: DateTime(2026, 9, 18),
      examDate: DateTime(2026, 10, 15),
      trajectoryHistory: [_historyPoint(DateTime(2026, 9, 4), 0.50)],
      dailyPlanHistory: const [],
    );

    expect(result.trajectory.hasMeaningfulWindow, isTrue);
    expect(result.trajectory.windowDays, 14);
  });

  test('safe projection remains unavailable without meaningful history', () {
    final result = service.build(
      dashboard: m7fDashboard(),
      evidenceByCompetency: const {},
      capacity: m7fCapacity(daysRemaining: 27),
      currentDate: DateTime(2026, 9, 18),
      examDate: DateTime(2026, 10, 15),
      trajectoryHistory: const [],
      dailyPlanHistory: const [],
    );

    expect(result.coverageProjection.isAvailable, isFalse);
  });

  test('safe projection can estimate blueprint coverage with history', () {
    final result = service.build(
      dashboard: m7fDashboard(competenciesTotal: 10, competenciesAssessed: 8),
      evidenceByCompetency: const {},
      capacity: m7fCapacity(daysRemaining: 27),
      currentDate: DateTime(2026, 9, 18),
      examDate: DateTime(2026, 10, 15),
      trajectoryHistory: [_historyPoint(DateTime(2026, 9, 4), 0.50)],
      dailyPlanHistory: const [],
    );

    expect(result.coverageProjection.isAvailable, isTrue);
    expect(
      result.coverageProjection.reasonCodes,
      contains('PROCESS_VARIABLE_NOT_EXAM_OUTCOME'),
    );
  });

  test('advanced snapshot schedules next configured checkpoint', () {
    final result = service.build(
      dashboard: m7fDashboard(),
      evidenceByCompetency: const {},
      capacity: m7fCapacity(daysRemaining: 27),
      currentDate: DateTime(2026, 9, 18),
      examDate: DateTime(2026, 10, 15),
      trajectoryHistory: const [],
      dailyPlanHistory: const [],
      ultraHardAvailable: true,
    );

    expect(result.nextCheckpoint?.milestoneDaysRemaining, 14);
  });

  test('no dependency map means no invented root gap', () {
    final result = service.build(
      dashboard: m7fDashboard(),
      evidenceByCompetency: const {},
      capacity: m7fCapacity(daysRemaining: 27),
      currentDate: DateTime(2026, 9, 18),
      examDate: DateTime(2026, 10, 15),
      trajectoryHistory: const [],
      dailyPlanHistory: const [],
    );

    expect(result.rootGapCandidates, isEmpty);
  });

  test('latest dashboard point is returned for local persistence', () {
    final result = service.build(
      dashboard: m7fDashboard(knowledge: 0.81),
      evidenceByCompetency: const {},
      capacity: m7fCapacity(daysRemaining: 27),
      currentDate: DateTime(2026, 9, 18),
      examDate: DateTime(2026, 10, 15),
      trajectoryHistory: const [],
      dailyPlanHistory: const [],
    );

    expect(result.latestTrajectoryPoint.knowledge, 0.81);
    expect(result.latestTrajectoryPoint.date, DateTime(2026, 9, 18));
  });

  test('advanced algorithm is versioned', () {
    final result = service.build(
      dashboard: m7fDashboard(),
      evidenceByCompetency: const {},
      capacity: m7fCapacity(daysRemaining: 27),
      currentDate: DateTime(2026, 9, 18),
      examDate: DateTime(2026, 10, 15),
      trajectoryHistory: const [],
      dailyPlanHistory: const [],
    );

    expect(
      result.algorithmVersion,
      AdvancedReadinessService.currentAlgorithmVersion,
    );
  });
}
