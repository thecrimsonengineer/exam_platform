import 'package:exam_platform/data/csp11_blueprint.dart';
import 'package:exam_platform/features/exam_readiness/models/competency_readiness_profile.dart';
import 'package:exam_platform/features/exam_readiness/models/evidence_confidence.dart';
import 'package:exam_platform/features/exam_readiness/services/readiness_profile_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '_support/m7c_fixture.dart';

void main() {
  const service = ReadinessProfileService();
  final now = DateTime(2026, 9, 18, 12);

  group('M7C dashboard aggregation', () {
    test('empty evidence produces no competency profiles', () {
      final dashboard = service.buildDashboard(
        evidenceByCompetency: const {},
        now: now,
      );
      expect(dashboard.profiles, isEmpty);
    });

    test('empty evidence produces NONE evidence confidence', () {
      final dashboard = service.buildDashboard(
        evidenceByCompetency: const {},
        now: now,
      );
      expect(dashboard.evidenceConfidence, EvidenceConfidence.none);
    });

    test('empty evidence exposes no composite readiness index', () {
      final dashboard = service.buildDashboard(
        evidenceByCompetency: const {},
        now: now,
      );
      expect(dashboard.hasCompositeReadinessIndex, isFalse);
    });

    test('noncanonical competency evidence is ignored', () {
      final dashboard = service.buildDashboard(
        evidenceByCompetency: {'bad': m7cEvidence(competencyId: 'bad')},
        now: now,
      );
      expect(dashboard.profiles, isEmpty);
    });

    test('canonical competency evidence creates profile', () {
      final dashboard = service.buildDashboard(
        evidenceByCompetency: {
          'd03_c02': m7cEvidence(),
        },
        now: now,
      );
      expect(dashboard.profiles.containsKey('d03_c02'), isTrue);
    });

    test('canonical blueprint contains forty-seven competencies', () {
      final dashboard = service.buildDashboard(
        evidenceByCompetency: const {},
        now: now,
      );
      expect(dashboard.blueprintCoverage.competenciesTotal, 47);
    });

    test('assessed competency count uses source attempt count', () {
      final dashboard = service.buildDashboard(
        evidenceByCompetency: {
          'd03_c02': m7cEvidence(),
        },
        now: now,
      );
      expect(dashboard.blueprintCoverage.competenciesAssessed, 1);
    });

    test('zero-attempt snapshot does not count as assessed competency', () {
      final dashboard = service.buildDashboard(
        evidenceByCompetency: {
          'd03_c02': m7cEvidence(
            totalAttempts: 0,
            correct: 0,
            uniqueQuestions: 0,
          ),
        },
        now: now,
      );
      expect(dashboard.blueprintCoverage.competenciesAssessed, 0);
    });

    test('topic totals aggregate from evidence snapshots', () {
      final dashboard = service.buildDashboard(
        evidenceByCompetency: {
          'd03_c02': m7cEvidence(topicsAvailable: 4, topicsAssessed: 3),
          'd03_c01': m7cEvidence(
            competencyId: 'd03_c01',
            topicsAvailable: 5,
            topicsAssessed: 2,
          ),
        },
        now: now,
      );
      expect(dashboard.blueprintCoverage.topicsTotal, 9);
      expect(dashboard.blueprintCoverage.topicsAssessed, 5);
    });

    test('subtopic totals aggregate from evidence snapshots', () {
      final dashboard = service.buildDashboard(
        evidenceByCompetency: {
          'd03_c02': m7cEvidence(subtopicsAvailable: 8, subtopicsAssessed: 6),
          'd03_c01': m7cEvidence(
            competencyId: 'd03_c01',
            subtopicsAvailable: 4,
            subtopicsAssessed: 2,
          ),
        },
        now: now,
      );
      expect(dashboard.blueprintCoverage.subtopicsTotal, 12);
      expect(dashboard.blueprintCoverage.subtopicsAssessed, 8);
    });

    test('dashboard always exposes seven domain coverage entries', () {
      final dashboard = service.buildDashboard(
        evidenceByCompetency: const {},
        now: now,
      );
      expect(dashboard.domainCoverage, hasLength(7));
    });

    test('Domain 1 coverage total uses seven competencies', () {
      final dashboard = service.buildDashboard(
        evidenceByCompetency: const {},
        now: now,
      );
      expect(dashboard.domainCoverage['d01']?.competenciesTotal, 7);
    });

    test('Domain 2 coverage total uses fourteen competencies', () {
      final dashboard = service.buildDashboard(
        evidenceByCompetency: const {},
        now: now,
      );
      expect(dashboard.domainCoverage['d02']?.competenciesTotal, 14);
    });

    test('Domain 6 coverage counts one assessed competency', () {
      final dashboard = service.buildDashboard(
        evidenceByCompetency: {
          'd06_c06': m7cEvidence(competencyId: 'd06_c06'),
        },
        now: now,
      );
      expect(dashboard.domainCoverage['d06']?.competenciesAssessed, 1);
    });

    test('fewer than three competency values hides aggregate knowledge', () {
      final dashboard = service.buildDashboard(
        evidenceByCompetency: {
          'd03_c01': m7cEvidence(competencyId: 'd03_c01'),
          'd03_c02': m7cEvidence(),
        },
        now: now,
      );
      expect(dashboard.knowledgeMastery.value, isNull);
    });

    test('three competency values can expose aggregate knowledge', () {
      final dashboard = service.buildDashboard(
        evidenceByCompetency: {
          'd03_c01': m7cEvidence(competencyId: 'd03_c01'),
          'd03_c02': m7cEvidence(),
          'd03_c03': m7cEvidence(competencyId: 'd03_c03'),
        },
        now: now,
      );
      expect(dashboard.knowledgeMastery.value, isNotNull);
    });

    test('three competency values can expose aggregate application', () {
      final dashboard = service.buildDashboard(
        evidenceByCompetency: {
          'd03_c01': m7cEvidence(competencyId: 'd03_c01'),
          'd03_c02': m7cEvidence(),
          'd03_c03': m7cEvidence(competencyId: 'd03_c03'),
        },
        now: now,
      );
      expect(dashboard.applicationAbility.value, isNotNull);
    });

    test('three competency values can expose aggregate retention', () {
      final dashboard = service.buildDashboard(
        evidenceByCompetency: {
          'd03_c01': m7cEvidence(competencyId: 'd03_c01'),
          'd03_c02': m7cEvidence(),
          'd03_c03': m7cEvidence(competencyId: 'd03_c03'),
        },
        now: now,
      );
      expect(dashboard.retention.value, isNotNull);
    });

    test('three competency values can expose difficulty aggregate', () {
      final dashboard = service.buildDashboard(
        evidenceByCompetency: {
          'd03_c01': m7cEvidence(competencyId: 'd03_c01'),
          'd03_c02': m7cEvidence(),
          'd03_c03': m7cEvidence(competencyId: 'd03_c03'),
        },
        now: now,
      );
      expect(dashboard.difficultyPerformance.value, isNotNull);
    });

    test('three calibrated competencies expose calibration aggregate', () {
      final dashboard = service.buildDashboard(
        evidenceByCompetency: {
          'd03_c01': m7cEvidence(competencyId: 'd03_c01'),
          'd03_c02': m7cEvidence(),
          'd03_c03': m7cEvidence(competencyId: 'd03_c03'),
        },
        now: now,
      );
      expect(dashboard.confidenceCalibration.value, isNotNull);
    });

    test('small blueprint representation caps overall evidence confidence', () {
      final dashboard = service.buildDashboard(
        evidenceByCompetency: {
          'd03_c01': m7cEvidence(
            competencyId: 'd03_c01',
            overallConfidence: EvidenceConfidence.veryHigh,
          ),
          'd03_c02': m7cEvidence(
            overallConfidence: EvidenceConfidence.veryHigh,
          ),
          'd03_c03': m7cEvidence(
            competencyId: 'd03_c03',
            overallConfidence: EvidenceConfidence.veryHigh,
          ),
        },
        now: now,
      );
      expect(
        dashboard.evidenceConfidence.rank,
        lessThanOrEqualTo(EvidenceConfidence.low.rank),
      );
    });

    test('ten high-evidence competencies escape low-representation cap', () {
      final ids = [
        for (final domain in csp11Domains)
          for (final competency in domain.competencies) competency.id,
      ].take(10).toList();
      final evidence = {
        for (final id in ids)
          id: m7cEvidence(
            competencyId: id,
            overallConfidence: EvidenceConfidence.high,
          ),
      };
      final dashboard = service.buildDashboard(
        evidenceByCompetency: evidence,
        now: now,
      );
      expect(
        dashboard.evidenceConfidence.rank,
        greaterThan(EvidenceConfidence.low.rank),
      );
    });

    test('critical gap count reflects competency gaps', () {
      final dashboard = service.buildDashboard(
        evidenceByCompetency: {
          'd03_c02': m7cEvidence(
            correct: 1,
            applicationCorrect: 0,
            analysisCorrect: 0,
          ),
        },
        now: now,
      );
      expect(dashboard.criticalGapCount, greaterThan(0));
    });

    test('weak competency count includes at-risk profile', () {
      final dashboard = service.buildDashboard(
        evidenceByCompetency: {
          'd03_c02': m7cEvidence(
            correct: 1,
            applicationCorrect: 0,
            analysisCorrect: 0,
            delayedCorrect: 0,
            overallConfidence: EvidenceConfidence.high,
          ),
        },
        now: now,
      );
      expect(dashboard.weakCompetencyCount, 1);
    });

    test('evidence gap count counts structured evidence gaps', () {
      final dashboard = service.buildDashboard(
        evidenceByCompetency: {
          'd03_c02': m7cEvidence(
            overallConfidence: EvidenceConfidence.low,
            applicationAttempts: 1,
            analysisAttempts: 0,
          ),
        },
        now: now,
      );
      expect(dashboard.evidenceGapCount, greaterThan(0));
    });

    test('stale competency count counts stale profiles', () {
      final dashboard = service.buildDashboard(
        evidenceByCompetency: {
          'd03_c02': m7cEvidence(
            evidenceState: EvidenceState.stale,
            recencyBand: EvidenceRecencyBand.stale,
          ),
        },
        now: now,
      );
      expect(dashboard.staleCompetencyCount, 1);
    });

    test('dashboard algorithm version matches competency profile version', () {
      final dashboard = service.buildDashboard(
        evidenceByCompetency: const {},
        now: now,
      );
      expect(
        dashboard.algorithmVersion,
        CompetencyReadinessProfile.currentAlgorithmVersion,
      );
    });

    test('dashboard generatedAt uses supplied clock', () {
      final dashboard = service.buildDashboard(
        evidenceByCompetency: const {},
        now: now,
      );
      expect(dashboard.generatedAt, now);
    });
  });
}
