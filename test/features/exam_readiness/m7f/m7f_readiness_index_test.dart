import 'package:exam_platform/features/exam_readiness/models/evidence_confidence.dart';
import 'package:exam_platform/features/exam_readiness/models/readiness_index_snapshot.dart';
import 'package:exam_platform/features/exam_readiness/models/readiness_weight_configuration.dart';
import 'package:exam_platform/features/exam_readiness/services/readiness_index_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '_support/m7f_fixture.dart';

const goodEvidence = ReadinessIndexEvidenceSummary(
  totalCompetencies: 10,
  assessedCompetencies: 8,
  totalAttempts: 150,
  applicationEvidenceCompetencies: 7,
  retentionEvidenceCompetencies: 5,
  criticalEvidenceBlindSpots: 0,
);

void main() {
  group('M7F Readiness Index weights', () {
    test('default experimental weights total one', () {
      const weights = ReadinessWeightConfiguration();
      expect(weights.total, closeTo(1, 0.000001));
    });

    test('default knowledge weight is twenty percent', () {
      const weights = ReadinessWeightConfiguration();
      expect(weights.knowledgeMastery, 0.20);
    });

    test('default application weight is twenty percent', () {
      const weights = ReadinessWeightConfiguration();
      expect(weights.applicationAbility, 0.20);
    });

    test('default retention and coverage are fifteen percent each', () {
      const weights = ReadinessWeightConfiguration();
      expect(weights.retention, 0.15);
      expect(weights.blueprintCoverage, 0.15);
    });

    test('default configuration is versioned', () {
      const weights = ReadinessWeightConfiguration();
      expect(weights.version, 'm7f-readiness-weights-v1');
    });

    test('weight total above one is rejected', () {
      const weights = ReadinessWeightConfiguration(knowledgeMastery: 0.30);
      expect(weights.validate, throwsStateError);
    });

    test('negative weight is rejected', () {
      const weights = ReadinessWeightConfiguration(
        knowledgeMastery: -0.1,
        applicationAbility: 0.3,
      );
      expect(weights.validate, throwsStateError);
    });
  });

  group('M7F Readiness Index evidence gate', () {
    const service = ReadinessIndexService();

    test('good evidence produces available index', () {
      final result = service.evaluate(
        dashboard: m7fDashboard(),
        evidence: goodEvidence,
      );
      expect(result.isAvailable, isTrue);
      expect(result.score, 80);
    });

    test('evidence confidence stays separate from score', () {
      final moderate = service.evaluate(
        dashboard: m7fDashboard(
          evidenceConfidence: EvidenceConfidence.moderate,
        ),
        evidence: goodEvidence,
      );
      final high = service.evaluate(
        dashboard: m7fDashboard(
          evidenceConfidence: EvidenceConfidence.veryHigh,
        ),
        evidence: goodEvidence,
      );
      expect(moderate.score, high.score);
      expect(moderate.evidenceConfidence, EvidenceConfidence.moderate);
      expect(high.evidenceConfidence, EvidenceConfidence.veryHigh);
    });

    test('low competency coverage withholds index', () {
      final result = service.evaluate(
        dashboard: m7fDashboard(),
        evidence: const ReadinessIndexEvidenceSummary(
          totalCompetencies: 10,
          assessedCompetencies: 5,
          totalAttempts: 150,
          applicationEvidenceCompetencies: 7,
          retentionEvidenceCompetencies: 5,
          criticalEvidenceBlindSpots: 0,
        ),
      );
      expect(result.score, isNull);
      expect(result.reasonCodes, contains('INSUFFICIENT_COMPETENCY_COVERAGE'));
    });

    test('low total attempts withholds index', () {
      final result = service.evaluate(
        dashboard: m7fDashboard(),
        evidence: const ReadinessIndexEvidenceSummary(
          totalCompetencies: 10,
          assessedCompetencies: 8,
          totalAttempts: 99,
          applicationEvidenceCompetencies: 7,
          retentionEvidenceCompetencies: 5,
          criticalEvidenceBlindSpots: 0,
        ),
      );
      expect(result.score, isNull);
      expect(result.reasonCodes, contains('INSUFFICIENT_TOTAL_EVIDENCE'));
    });

    test('low application breadth withholds index', () {
      final result = service.evaluate(
        dashboard: m7fDashboard(),
        evidence: const ReadinessIndexEvidenceSummary(
          totalCompetencies: 10,
          assessedCompetencies: 8,
          totalAttempts: 150,
          applicationEvidenceCompetencies: 3,
          retentionEvidenceCompetencies: 5,
          criticalEvidenceBlindSpots: 0,
        ),
      );
      expect(result.score, isNull);
      expect(result.reasonCodes, contains('INSUFFICIENT_APPLICATION_EVIDENCE'));
    });

    test('low retention breadth withholds index', () {
      final result = service.evaluate(
        dashboard: m7fDashboard(),
        evidence: const ReadinessIndexEvidenceSummary(
          totalCompetencies: 10,
          assessedCompetencies: 8,
          totalAttempts: 150,
          applicationEvidenceCompetencies: 7,
          retentionEvidenceCompetencies: 1,
          criticalEvidenceBlindSpots: 0,
        ),
      );
      expect(result.score, isNull);
      expect(result.reasonCodes, contains('INSUFFICIENT_RETENTION_EVIDENCE'));
    });

    test('critical evidence blind spots can withhold index', () {
      final result = service.evaluate(
        dashboard: m7fDashboard(),
        evidence: const ReadinessIndexEvidenceSummary(
          totalCompetencies: 10,
          assessedCompetencies: 8,
          totalAttempts: 150,
          applicationEvidenceCompetencies: 7,
          retentionEvidenceCompetencies: 5,
          criticalEvidenceBlindSpots: 2,
        ),
      );
      expect(result.score, isNull);
      expect(result.reasonCodes, contains('CRITICAL_EVIDENCE_BLIND_SPOTS'));
    });

    test('low overall evidence confidence withholds index', () {
      final result = service.evaluate(
        dashboard: m7fDashboard(evidenceConfidence: EvidenceConfidence.low),
        evidence: goodEvidence,
      );
      expect(result.score, isNull);
      expect(
        result.reasonCodes,
        contains('OVERALL_EVIDENCE_CONFIDENCE_TOO_LOW'),
      );
    });

    test('multiple evidence failures are all reported', () {
      final result = service.evaluate(
        dashboard: m7fDashboard(evidenceConfidence: EvidenceConfidence.low),
        evidence: const ReadinessIndexEvidenceSummary(
          totalCompetencies: 10,
          assessedCompetencies: 2,
          totalAttempts: 20,
          applicationEvidenceCompetencies: 1,
          retentionEvidenceCompetencies: 0,
          criticalEvidenceBlindSpots: 3,
        ),
      );
      expect(result.score, isNull);
      expect(result.reasonCodes.length, greaterThanOrEqualTo(5));
    });

    test('missing knowledge never becomes zero score input', () {
      final result = service.evaluate(
        dashboard: m7fDashboard(knowledge: null),
        evidence: goodEvidence,
      );
      expect(result.score, isNull);
      expect(result.reasonCodes, contains('READINESS_DIMENSIONS_INCOMPLETE'));
      expect(result.reasonCodes, contains('MISSING_KNOWLEDGEMASTERY'));
    });

    test('missing application never becomes zero score input', () {
      final result = service.evaluate(
        dashboard: m7fDashboard(application: null),
        evidence: goodEvidence,
      );
      expect(result.score, isNull);
      expect(result.reasonCodes, contains('MISSING_APPLICATIONABILITY'));
    });

    test('missing retention never becomes zero score input', () {
      final result = service.evaluate(
        dashboard: m7fDashboard(retention: null),
        evidence: goodEvidence,
      );
      expect(result.score, isNull);
      expect(result.reasonCodes, contains('MISSING_RETENTION'));
    });

    test('missing difficulty never becomes zero score input', () {
      final result = service.evaluate(
        dashboard: m7fDashboard(difficulty: null),
        evidence: goodEvidence,
      );
      expect(result.score, isNull);
      expect(result.reasonCodes, contains('MISSING_DIFFICULTYPERFORMANCE'));
    });

    test('missing confidence calibration never becomes zero score input', () {
      final result = service.evaluate(
        dashboard: m7fDashboard(calibration: null),
        evidence: goodEvidence,
      );
      expect(result.score, isNull);
      expect(result.reasonCodes, contains('MISSING_CONFIDENCECALIBRATION'));
    });

    test('missing recent performance across profiles withholds index', () {
      final dashboard = m7fDashboard(recentPerformance: null);
      final result = service.evaluate(
        dashboard: dashboard,
        evidence: goodEvidence,
      );
      expect(result.score, isNull);
      expect(result.reasonCodes, contains('MISSING_RECENTPERFORMANCE'));
    });

    test('available result exposes all weighted components', () {
      final result = service.evaluate(
        dashboard: m7fDashboard(),
        evidence: goodEvidence,
      );
      expect(result.components.length, 8);
      expect(result.components['competencyBreadth'], 0.8);
    });

    test('available score stays inside zero to one hundred', () {
      final result = service.evaluate(
        dashboard: m7fDashboard(
          knowledge: 1,
          application: 1,
          retention: 1,
          difficulty: 1,
          calibration: 1,
          recentPerformance: 1,
          competenciesTotal: 10,
          competenciesAssessed: 10,
        ),
        evidence: const ReadinessIndexEvidenceSummary(
          totalCompetencies: 10,
          assessedCompetencies: 10,
          totalAttempts: 300,
          applicationEvidenceCompetencies: 10,
          retentionEvidenceCompetencies: 10,
          criticalEvidenceBlindSpots: 0,
        ),
      );
      expect(result.score, inInclusiveRange(0, 100));
    });

    test('unavailable snapshot rejects a numeric score', () {
      final snapshot = ReadinessIndexSnapshot(
        generatedAt: DateTime(2026, 9, 18),
        availability: ReadinessIndexAvailability.insufficientEvidence,
        score: 50,
        evidenceConfidence: EvidenceConfidence.low,
        components: const {},
        reasonCodes: const ['INSUFFICIENT_TOTAL_EVIDENCE'],
        weightConfigurationVersion: 'weights',
        gateConfigurationVersion: 'gate',
        algorithmVersion: 'algorithm',
      );
      expect(snapshot.validate, throwsStateError);
    });

    test('available snapshot requires a numeric score', () {
      final snapshot = ReadinessIndexSnapshot(
        generatedAt: DateTime(2026, 9, 18),
        availability: ReadinessIndexAvailability.available,
        score: null,
        evidenceConfidence: EvidenceConfidence.high,
        components: const {},
        reasonCodes: const ['READINESS_INDEX_EVIDENCE_GATE_PASSED'],
        weightConfigurationVersion: 'weights',
        gateConfigurationVersion: 'gate',
        algorithmVersion: 'algorithm',
      );
      expect(snapshot.validate, throwsStateError);
    });

    test('invalid evidence summary is rejected', () {
      const evidence = ReadinessIndexEvidenceSummary(
        totalCompetencies: 10,
        assessedCompetencies: 11,
        totalAttempts: 150,
        applicationEvidenceCompetencies: 7,
        retentionEvidenceCompetencies: 5,
        criticalEvidenceBlindSpots: 0,
      );
      expect(evidence.validate, throwsStateError);
    });

    test('gate and algorithm versions are recorded', () {
      final result = service.evaluate(
        dashboard: m7fDashboard(),
        evidence: goodEvidence,
      );
      expect(result.gateConfigurationVersion, 'm7f-readiness-index-gate-v1');
      expect(result.algorithmVersion, 'm7f-readiness-index-v1');
    });

    test('available result carries gate-passed explanation code', () {
      final result = service.evaluate(
        dashboard: m7fDashboard(),
        evidence: goodEvidence,
      );
      expect(
        result.reasonCodes,
        contains('READINESS_INDEX_EVIDENCE_GATE_PASSED'),
      );
    });
  });
}
