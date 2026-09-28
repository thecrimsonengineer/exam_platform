import 'package:exam_platform/features/exam_readiness/models/competency_readiness_profile.dart';
import 'package:exam_platform/features/exam_readiness/models/readiness_intelligence_snapshot.dart';
import 'package:exam_platform/features/exam_readiness/services/advanced_readiness_service.dart';
import 'package:exam_platform/features/exam_readiness/services/readiness_intelligence_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../m7d/_support/m7d_fixture.dart';
import '../m7f/_support/m7f_fixture.dart';

void main() {
  const advancedService = AdvancedReadinessService();
  const service = ReadinessIntelligenceService();

  test('evidence-gap competency is not classified as weakness', () {
    final dashboard = m7fDashboard(
      profiles: {
        'd06_c01': m7dProfile(
          competencyId: 'd06_c01',
          readinessState: ReadinessState.insufficientEvidence,
        ),
      },
    );
    final advanced = advancedService.build(
      dashboard: dashboard,
      evidenceByCompetency: const {},
      capacity: m7fCapacity(),
      currentDate: DateTime(2026, 9, 28),
      examDate: DateTime(2026, 10, 28),
      trajectoryHistory: const [],
      dailyPlanHistory: const [],
    );

    final result = service.build(dashboard: dashboard, advanced: advanced);

    expect(result.evidenceGapCompetencyIds, contains('d06_c01'));
    expect(result.weakCompetencyIds, isNot(contains('d06_c01')));
    expect(result.nextBestAction?.kind, ReadinessNextActionKind.diagnostic);
  });

  test('genuine weakness produces targeted practice', () {
    final dashboard = m7fDashboard(
      profiles: {
        'd02_c03': m7dProfile(
          competencyId: 'd02_c03',
          readinessState: ReadinessState.developing,
          knowledge: 0.52,
          application: 0.50,
          retention: 0.51,
        ),
      },
    );
    final advanced = advancedService.build(
      dashboard: dashboard,
      evidenceByCompetency: const {},
      capacity: m7fCapacity(),
      currentDate: DateTime(2026, 9, 28),
      examDate: DateTime(2026, 10, 28),
      trajectoryHistory: const [],
      dailyPlanHistory: const [],
    );

    final result = service.build(dashboard: dashboard, advanced: advanced);

    expect(result.weakCompetencyIds, contains('d02_c03'));
    expect(result.evidenceGapCompetencyIds, isNot(contains('d02_c03')));
    expect(
      result.nextBestAction?.kind,
      ReadinessNextActionKind.targetedPractice,
    );
  });

  test('retention-limited weakness can recommend flashcard review', () {
    final dashboard = m7fDashboard(
      profiles: {
        'd03_c02': m7dProfile(
          competencyId: 'd03_c02',
          readinessState: ReadinessState.developing,
          knowledge: 0.82,
          application: 0.80,
          retention: 0.48,
        ),
      },
    );
    final advanced = advancedService.build(
      dashboard: dashboard,
      evidenceByCompetency: const {},
      capacity: m7fCapacity(),
      currentDate: DateTime(2026, 9, 28),
      examDate: DateTime(2026, 10, 28),
      trajectoryHistory: const [],
      dailyPlanHistory: const [],
    );

    final result = service.build(
      dashboard: dashboard,
      advanced: advanced,
      dueFlashcards: 12,
    );

    expect(result.dueFlashcards, 12);
    expect(result.nextBestAction?.kind, ReadinessNextActionKind.flashcardReview);
    expect(result.nextBestAction?.competencyId, 'd03_c02');
  });

  test('application-limited weakness can recommend applied LAB work', () {
    final dashboard = m7fDashboard(
      profiles: {
        'd04_c01': m7dProfile(
          competencyId: 'd04_c01',
          readinessState: ReadinessState.developing,
          knowledge: 0.82,
          application: 0.48,
          retention: 0.80,
        ),
      },
    );
    final advanced = advancedService.build(
      dashboard: dashboard,
      evidenceByCompetency: const {},
      capacity: m7fCapacity(),
      currentDate: DateTime(2026, 9, 28),
      examDate: DateTime(2026, 10, 28),
      trajectoryHistory: const [],
      dailyPlanHistory: const [],
    );

    final result = service.build(dashboard: dashboard, advanced: advanced);

    expect(result.nextBestAction?.kind, ReadinessNextActionKind.lab);
    expect(result.nextBestAction?.competencyId, 'd04_c01');
  });

  test('strong and evidence-gap competency sets remain distinct', () {
    final dashboard = m7fDashboard(
      profiles: {
        'd01_c01': m7dProfile(
          competencyId: 'd01_c01',
          readinessState: ReadinessState.strong,
          knowledge: 0.88,
          application: 0.84,
          retention: 0.86,
        ),
        'd06_c01': m7dProfile(
          competencyId: 'd06_c01',
          readinessState: ReadinessState.insufficientEvidence,
        ),
      },
    );
    final advanced = advancedService.build(
      dashboard: dashboard,
      evidenceByCompetency: const {},
      capacity: m7fCapacity(),
      currentDate: DateTime(2026, 9, 28),
      examDate: DateTime(2026, 10, 28),
      trajectoryHistory: const [],
      dailyPlanHistory: const [],
    );

    final result = service.build(dashboard: dashboard, advanced: advanced);

    expect(result.strongCompetencyIds, contains('d01_c01'));
    expect(result.evidenceGapCompetencyIds, contains('d06_c01'));
    expect(result.weakCompetencyIds, isEmpty);
    expect(result.evidenceSufficiency, closeTo(0.5, 0.0001));
  });

  test('negative due flashcard input is normalized to zero', () {
    final dashboard = m7fDashboard();
    final advanced = advancedService.build(
      dashboard: dashboard,
      evidenceByCompetency: const {},
      capacity: m7fCapacity(),
      currentDate: DateTime(2026, 9, 28),
      examDate: DateTime(2026, 10, 28),
      trajectoryHistory: const [],
      dailyPlanHistory: const [],
    );

    final result = service.build(
      dashboard: dashboard,
      advanced: advanced,
      dueFlashcards: -3,
    );

    expect(result.dueFlashcards, 0);
  });
}
