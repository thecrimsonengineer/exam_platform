import 'package:exam_platform/features/exam_readiness/models/competency_dependency.dart';
import 'package:exam_platform/features/exam_readiness/models/evidence_confidence.dart';
import 'package:exam_platform/features/exam_readiness/models/readiness_gap.dart';
import 'package:exam_platform/features/exam_readiness/models/readiness_trajectory_point.dart';
import 'package:exam_platform/features/exam_readiness/services/readiness_trajectory_service.dart';
import 'package:exam_platform/features/exam_readiness/services/root_gap_reasoning_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../m7d/_support/m7d_fixture.dart';
import '_support/m7f_fixture.dart';

ReadinessTrajectoryPoint point({
  required DateTime date,
  double? value = 0.7,
  EvidenceConfidence confidence = EvidenceConfidence.high,
}) {
  return ReadinessTrajectoryPoint(
    date: date,
    knowledge: value,
    application: value,
    retention: value,
    coverage: value,
    difficulty: value,
    evidenceConfidence: confidence,
    algorithmVersion: 'm7f-trajectory-v1',
  );
}

CompetencyDependency dependency({
  String prerequisite = 'd03_c01',
  String dependent = 'd03_c02',
  double strength = 0.8,
}) {
  return CompetencyDependency(
    prerequisiteCompetencyId: prerequisite,
    dependentCompetencyId: dependent,
    strength: strength,
    rationale: 'Curated CSP11 dependency.',
    source: 'CSP11 curated dependency map',
    version: 'm7f-dependency-v1',
  );
}

void main() {
  group('M7F readiness trajectory', () {
    const service = ReadinessTrajectoryService();

    test('dashboard becomes trajectory point without invented values', () {
      final dashboard = m7fDashboard(
        knowledge: 0.81,
        application: 0.72,
        retention: 0.63,
        difficulty: 0.74,
      );
      final result = service.pointFromDashboard(dashboard);
      expect(result.knowledge, 0.81);
      expect(result.application, 0.72);
      expect(result.retention, 0.63);
      expect(result.difficulty, 0.74);
      expect(result.coverage, 0.8);
    });

    test('missing dashboard dimension remains null', () {
      final result = service.pointFromDashboard(
        m7fDashboard(retention: null),
      );
      expect(result.retention, isNull);
    });

    test('empty trajectory has unavailable trend', () {
      final result = service.summarize(const []);
      expect(result.hasMeaningfulWindow, isFalse);
      expect(
        result.application.direction,
        ReadinessTrendDirection.unavailable,
      );
    });

    test('one point cannot create a trend', () {
      final result = service.summarize([
        point(date: DateTime(2026, 9, 18)),
      ]);
      expect(result.hasMeaningfulWindow, isFalse);
    });

    test('short window is not treated as meaningful trend', () {
      final result = service.summarize([
        point(date: DateTime(2026, 9, 10), value: 0.6),
        point(date: DateTime(2026, 9, 18), value: 0.8),
      ]);
      expect(result.hasMeaningfulWindow, isFalse);
    });

    test('14 day window is eligible', () {
      final result = service.summarize([
        point(date: DateTime(2026, 9, 4), value: 0.6),
        point(date: DateTime(2026, 9, 18), value: 0.8),
      ]);
      expect(result.hasMeaningfulWindow, isTrue);
      expect(result.windowDays, 14);
    });

    test('positive meaningful delta is improving', () {
      final result = service.summarize([
        point(date: DateTime(2026, 9, 1), value: 0.6),
        point(date: DateTime(2026, 9, 18), value: 0.8),
      ]);
      expect(
        result.knowledge.direction,
        ReadinessTrendDirection.improving,
      );
      expect(result.knowledge.delta, closeTo(0.2, 0.000001));
    });

    test('negative meaningful delta is declining', () {
      final result = service.summarize([
        point(date: DateTime(2026, 9, 1), value: 0.8),
        point(date: DateTime(2026, 9, 18), value: 0.6),
      ]);
      expect(
        result.application.direction,
        ReadinessTrendDirection.declining,
      );
    });

    test('small delta is stable rather than noisy improvement', () {
      final result = service.summarize([
        point(date: DateTime(2026, 9, 1), value: 0.70),
        point(date: DateTime(2026, 9, 18), value: 0.72),
      ]);
      expect(result.retention.direction, ReadinessTrendDirection.stable);
    });

    test('missing start dimension produces unavailable dimension trend', () {
      final first = point(date: DateTime(2026, 9, 1), value: null);
      final second = point(date: DateTime(2026, 9, 18), value: 0.8);
      final result = service.summarize([first, second]);
      expect(
        result.difficulty.direction,
        ReadinessTrendDirection.unavailable,
      );
      expect(result.difficulty.delta, isNull);
    });

    test('latest evidence confidence is retained separately', () {
      final result = service.summarize([
        point(
          date: DateTime(2026, 9, 1),
          confidence: EvidenceConfidence.low,
        ),
        point(
          date: DateTime(2026, 9, 18),
          confidence: EvidenceConfidence.veryHigh,
        ),
      ]);
      expect(result.latestEvidenceConfidence, EvidenceConfidence.veryHigh);
    });

    test('trajectory point round trip preserves null dimension', () {
      final original = ReadinessTrajectoryPoint(
        date: DateTime(2026, 9, 18),
        knowledge: 0.8,
        application: 0.7,
        retention: null,
        coverage: 0.6,
        difficulty: 0.5,
        evidenceConfidence: EvidenceConfidence.moderate,
        algorithmVersion: 'm7f-trajectory-v1',
      );
      final restored = ReadinessTrajectoryPoint.fromJson(original.toJson());
      expect(restored.retention, isNull);
      expect(restored.application, 0.7);
      expect(restored.evidenceConfidence, EvidenceConfidence.moderate);
    });
  });

  group('M7F curated dependency and root gap reasoning', () {
    const service = RootGapReasoningService();

    test('canonical dependency validates', () {
      expect(dependency().validate, returnsNormally);
    });

    test('noncanonical dependency is rejected', () {
      expect(
        dependency(prerequisite: 'D3C1').validate,
        throwsStateError,
      );
    });

    test('self dependency is rejected', () {
      expect(
        dependency(prerequisite: 'd03_c01', dependent: 'd03_c01').validate,
        throwsStateError,
      );
    });

    test('dependency strength outside unit interval is rejected', () {
      expect(dependency(strength: 1.2).validate, throwsStateError);
    });

    test('dependency round trips through JSON', () {
      final original = dependency();
      final restored = CompetencyDependency.fromJson(original.toJson());
      expect(restored.prerequisiteCompetencyId, 'd03_c01');
      expect(restored.dependentCompetencyId, 'd03_c02');
      expect(restored.strength, 0.8);
    });

    test('root gap requires observed serious prerequisite gap', () {
      final result = service.identify(
        dependencies: [
          dependency(dependent: 'd03_c02'),
          dependency(dependent: 'd03_c03'),
        ],
        profiles: {
          'd03_c01': m7dProfile(
            competencyId: 'd03_c01',
            gaps: const [],
          ),
          'd03_c02': m7dProfile(
            competencyId: 'd03_c02',
            gaps: [m7dGap(competencyId: 'd03_c02')],
          ),
          'd03_c03': m7dProfile(
            competencyId: 'd03_c03',
            gaps: [m7dGap(competencyId: 'd03_c03')],
          ),
        },
      );
      expect(result, isEmpty);
    });

    test('root gap requires at least two weak dependents', () {
      final result = service.identify(
        dependencies: [
          dependency(dependent: 'd03_c02'),
          dependency(dependent: 'd03_c03'),
        ],
        profiles: {
          'd03_c01': m7dProfile(
            competencyId: 'd03_c01',
            gaps: [m7dGap(competencyId: 'd03_c01')],
          ),
          'd03_c02': m7dProfile(
            competencyId: 'd03_c02',
            gaps: [m7dGap(competencyId: 'd03_c02')],
          ),
          'd03_c03': m7dProfile(
            competencyId: 'd03_c03',
            gaps: const [],
          ),
        },
      );
      expect(result, isEmpty);
    });

    test('observed prerequisite plus two observed dependents creates root gap', () {
      final result = service.identify(
        dependencies: [
          dependency(dependent: 'd03_c02', strength: 0.8),
          dependency(dependent: 'd03_c03', strength: 0.6),
        ],
        profiles: {
          'd03_c01': m7dProfile(
            competencyId: 'd03_c01',
            gaps: [m7dGap(competencyId: 'd03_c01')],
          ),
          'd03_c02': m7dProfile(
            competencyId: 'd03_c02',
            gaps: [m7dGap(competencyId: 'd03_c02')],
          ),
          'd03_c03': m7dProfile(
            competencyId: 'd03_c03',
            gaps: [m7dGap(competencyId: 'd03_c03')],
          ),
        },
      );
      expect(result, hasLength(1));
      expect(result.single.prerequisiteCompetencyId, 'd03_c01');
      expect(result.single.dependentCompetencyIds, ['d03_c02', 'd03_c03']);
      expect(result.single.averageDependencyStrength, closeTo(0.7, 0.000001));
    });

    test('evidence-limited prerequisite is not treated as observed root gap', () {
      final result = service.identify(
        dependencies: [
          dependency(dependent: 'd03_c02'),
          dependency(dependent: 'd03_c03'),
        ],
        profiles: {
          'd03_c01': m7dProfile(
            competencyId: 'd03_c01',
            gaps: [
              m7dGap(
                competencyId: 'd03_c01',
                evidenceLimited: true,
                severity: ReadinessGapSeverity.critical,
              ),
            ],
          ),
          'd03_c02': m7dProfile(
            competencyId: 'd03_c02',
            gaps: [m7dGap(competencyId: 'd03_c02')],
          ),
          'd03_c03': m7dProfile(
            competencyId: 'd03_c03',
            gaps: [m7dGap(competencyId: 'd03_c03')],
          ),
        },
      );
      expect(result, isEmpty);
    });

    test('missing dependent profile is not invented as weakness', () {
      final result = service.identify(
        dependencies: [
          dependency(dependent: 'd03_c02'),
          dependency(dependent: 'd03_c03'),
        ],
        profiles: {
          'd03_c01': m7dProfile(
            competencyId: 'd03_c01',
            gaps: [m7dGap(competencyId: 'd03_c01')],
          ),
          'd03_c02': m7dProfile(
            competencyId: 'd03_c02',
            gaps: [m7dGap(competencyId: 'd03_c02')],
          ),
        },
      );
      expect(result, isEmpty);
    });

    test('root gap reason codes identify explicit dependency basis', () {
      final result = service.identify(
        dependencies: [
          dependency(dependent: 'd03_c02'),
          dependency(dependent: 'd03_c03'),
        ],
        profiles: {
          for (final id in ['d03_c01', 'd03_c02', 'd03_c03'])
            id: m7dProfile(
              competencyId: id,
              gaps: [m7dGap(competencyId: id)],
            ),
        },
      );
      expect(
        result.single.reasonCodes,
        contains('ROOT_GAP_EXPLICIT_DEPENDENCY'),
      );
    });
  });
}
