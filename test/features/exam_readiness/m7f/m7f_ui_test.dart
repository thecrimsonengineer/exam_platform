import 'package:exam_platform/features/exam_readiness/models/advanced_readiness_snapshot.dart';
import 'package:exam_platform/features/exam_readiness/models/capacity_pressure_snapshot.dart';
import 'package:exam_platform/features/exam_readiness/models/coverage_projection.dart';
import 'package:exam_platform/features/exam_readiness/models/evidence_confidence.dart';
import 'package:exam_platform/features/exam_readiness/models/exam_preparation_phase.dart';
import 'package:exam_platform/features/exam_readiness/models/readiness_index_snapshot.dart';
import 'package:exam_platform/features/exam_readiness/models/readiness_trajectory_point.dart';
import 'package:exam_platform/features/exam_readiness/models/recovery_protection_snapshot.dart';
import 'package:exam_platform/features/exam_readiness/screens/advanced_readiness_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

AdvancedReadinessSnapshot _snapshot({bool indexAvailable = false}) {
  const unavailableTrend = ReadinessDimensionTrend(
    startValue: null,
    endValue: null,
    delta: null,
    direction: ReadinessTrendDirection.unavailable,
  );

  return AdvancedReadinessSnapshot(
    generatedAt: DateTime(2026, 9, 18),
    daysUntilExam: 27,
    phase: ExamPreparationPhase.readiness,
    capacityPressure: CapacityPressureSnapshot(
      generatedAt: DateTime(2026, 9, 18),
      phase: ExamPreparationPhase.readiness,
      availableMinutes: 1410,
      estimatedPriorityWorkloadMinMinutes: 1860,
      estimatedPriorityWorkloadMaxMinutes: 2280,
      state: CapacityPressureState.high,
      criticalGapCount: 2,
      highGapCount: 3,
      evidenceBlindSpotCount: 1,
      scheduledReviewDebtMinutes: 0,
      reasonCodes: const ['PRIORITY_WORKLOAD_EXCEEDS_CAPACITY'],
      algorithmVersion: 'm7f-capacity-pressure-v1',
      schemaVersion: CapacityPressureSnapshot.currentSchemaVersion,
    ),
    readinessIndex: ReadinessIndexSnapshot(
      generatedAt: DateTime(2026, 9, 18),
      availability: indexAvailable
          ? ReadinessIndexAvailability.available
          : ReadinessIndexAvailability.insufficientEvidence,
      score: indexAvailable ? 72 : null,
      evidenceConfidence: EvidenceConfidence.high,
      components: indexAvailable
          ? const {'knowledgeMastery': 0.72}
          : const {},
      reasonCodes: indexAvailable
          ? const ['READINESS_INDEX_EVIDENCE_GATE_PASSED']
          : const ['INSUFFICIENT_TOTAL_EVIDENCE'],
      weightConfigurationVersion: 'weights-v1',
      gateConfigurationVersion: 'gate-v1',
      algorithmVersion: 'index-v1',
    ),
    trajectory: const ReadinessTrajectorySummary(
      startDate: null,
      endDate: null,
      windowDays: 0,
      knowledge: unavailableTrend,
      application: unavailableTrend,
      retention: unavailableTrend,
      coverage: unavailableTrend,
      difficulty: unavailableTrend,
      latestEvidenceConfidence: EvidenceConfidence.high,
      algorithmVersion: 'trajectory-v1',
    ),
    latestTrajectoryPoint: ReadinessTrajectoryPoint(
      date: DateTime(2026, 9, 18),
      knowledge: 0.7,
      application: 0.7,
      retention: null,
      coverage: 0.8,
      difficulty: 0.7,
      evidenceConfidence: EvidenceConfidence.high,
      algorithmVersion: 'trajectory-v1',
    ),
    coverageProjection: const CoverageProjection(
      projectedCoverage: null,
      currentCoverage: 0.8,
      windowDays: 0,
      daysToExam: 27,
      reasonCodes: ['COVERAGE_PROJECTION_INSUFFICIENT_HISTORY'],
      algorithmVersion: 'projection-v1',
    ),
    nextCheckpoint: null,
    recoveryProtection: const RecoveryProtectionSnapshot(
      state: RecoveryProtectionState.none,
      consecutiveMissedStudyDays: 0,
      declaredMinutes: 60,
      suggestedMinutes: 60,
      reasonCodes: ['RECOVERY_PROTECTION_NOT_REQUIRED'],
      algorithmVersion: 'recovery-v1',
    ),
    evidenceConfidence: EvidenceConfidence.high,
    strongCompetencies: 31,
    developingCompetencies: 8,
    criticalGaps: 2,
    insufficientEvidenceCompetencies: 3,
    todayPlanMinutes: 60,
    todayBlockCount: 4,
    planChangeExplanation: 'Plan changed because current evidence changed.',
    rootGapCandidates: const [],
    reasonCodes: const ['EXAM_PHASE_READINESS'],
    algorithmVersion: 'm7f-advanced-readiness-v1',
  );
}

Widget _app(Widget child, {bool dark = false}) => MaterialApp(
  theme: dark ? ThemeData.dark() : ThemeData.light(),
  home: Scaffold(body: child),
);

void main() {
  testWidgets('advanced summary renders core M7F cards', (tester) async {
    await tester.pumpWidget(
      _app(AdvancedReadinessSummaryView(snapshot: _snapshot())),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('m7f-phase-hero')), findsOneWidget);
    expect(find.byKey(const ValueKey('m7f-readiness-index')), findsOneWidget);
    expect(find.byKey(const ValueKey('m7f-capacity-pressure')), findsOneWidget);
    expect(find.byKey(const ValueKey('m7f-readiness-counts')), findsOneWidget);
  });

  testWidgets('insufficient evidence displays no numeric index', (tester) async {
    await tester.pumpWidget(
      _app(AdvancedReadinessSummaryView(snapshot: _snapshot())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Not yet available'), findsOneWidget);
    expect(
      find.textContaining('More evidence is required'),
      findsOneWidget,
    );
  });

  testWidgets('available index remains separate from evidence confidence', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(AdvancedReadinessSummaryView(snapshot: _snapshot(indexAvailable: true))),
    );
    await tester.pumpAndSettle();

    expect(find.text('72 / 100'), findsOneWidget);
    expect(find.text('Evidence confidence: HIGH'), findsWidgets);
    expect(find.textContaining('not an exam outcome prediction'), findsOneWidget);
  });

  testWidgets('capacity pressure uses a workload range', (tester) async {
    await tester.pumpWidget(
      _app(AdvancedReadinessSummaryView(snapshot: _snapshot())),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('31.0-38.0 hours'), findsOneWidget);
    expect(find.textContaining('23.5 hours'), findsOneWidget);
  });

  testWidgets('advanced summary renders in dark theme', (tester) async {
    await tester.pumpWidget(
      _app(
        AdvancedReadinessSummaryView(snapshot: _snapshot()),
        dark: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('m7f-advanced-readiness-summary')),
      findsOneWidget,
    );
  });

  testWidgets('advanced summary never uses pass probability wording', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(AdvancedReadinessSummaryView(snapshot: _snapshot(indexAvailable: true))),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('pass probability'), findsNothing);
  });
}
