import 'package:exam_platform/features/exam_readiness/models/competency_readiness_profile.dart';
import 'package:exam_platform/features/exam_readiness/models/evidence_confidence.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('M7C ReadinessDimension', () {
    test('null value is unavailable', () {
      const item = ReadinessDimension(
        code: 'K',
        value: null,
        evidenceConfidence: EvidenceConfidence.low,
      );
      expect(item.isAvailable, isFalse);
      expect(item.percent, isNull);
    });

    test('available dimension exposes rounded percent', () {
      const item = ReadinessDimension(
        code: 'K',
        value: 0.714,
        evidenceConfidence: EvidenceConfidence.high,
      );
      expect(item.isAvailable, isTrue);
      expect(item.percent, 71);
    });

    test('percent clamps above one', () {
      const item = ReadinessDimension(
        code: 'K',
        value: 1.4,
        evidenceConfidence: EvidenceConfidence.high,
      );
      expect(item.percent, 100);
    });

    test('percent clamps below zero', () {
      const item = ReadinessDimension(
        code: 'K',
        value: -0.4,
        evidenceConfidence: EvidenceConfidence.high,
      );
      expect(item.percent, 0);
    });

    test('dimension round trips through JSON', () {
      const original = ReadinessDimension(
        code: 'APPLICATION',
        value: 0.66,
        evidenceConfidence: EvidenceConfidence.moderate,
        reasonCodes: ['A', 'B'],
      );
      final decoded = ReadinessDimension.fromJson(original.toJson());
      expect(decoded.code, original.code);
      expect(decoded.value, original.value);
      expect(decoded.evidenceConfidence, original.evidenceConfidence);
      expect(decoded.reasonCodes, original.reasonCodes);
    });

    test('dimension JSON clamps invalid high value', () {
      final decoded = ReadinessDimension.fromJson({
        'code': 'K',
        'value': 2.0,
        'evidenceConfidence': 'high',
      });
      expect(decoded.value, 1);
    });

    test('dimension JSON clamps invalid low value', () {
      final decoded = ReadinessDimension.fromJson({
        'code': 'K',
        'value': -2.0,
        'evidenceConfidence': 'high',
      });
      expect(decoded.value, 0);
    });

    test('unknown evidence confidence falls back to none', () {
      final decoded = ReadinessDimension.fromJson({
        'code': 'K',
        'value': 0.5,
        'evidenceConfidence': 'mystery',
      });
      expect(decoded.evidenceConfidence, EvidenceConfidence.none);
    });
  });

  group('M7C ReadinessGap', () {
    test('gap round trips through JSON', () {
      const gap = ReadinessGap(
        type: ReadinessGapType.applicationGap,
        severity: ReadinessGapSeverity.high,
        competencyId: 'd03_c02',
        reasonCode: 'APPLICATION_GAP',
        explanation: 'Weak application.',
        evidenceLimited: false,
      );
      final decoded = ReadinessGap.fromJson(gap.toJson());
      expect(decoded.type, gap.type);
      expect(decoded.severity, gap.severity);
      expect(decoded.competencyId, gap.competencyId);
      expect(decoded.reasonCode, gap.reasonCode);
      expect(decoded.evidenceLimited, isFalse);
    });

    test('unknown gap type falls back to evidence gap', () {
      final decoded = ReadinessGap.fromJson({
        'type': 'mystery',
        'severity': 'low',
      });
      expect(decoded.type, ReadinessGapType.evidenceGap);
    });

    test('unknown severity falls back to low', () {
      final decoded = ReadinessGap.fromJson({
        'type': 'masteryGap',
        'severity': 'mystery',
      });
      expect(decoded.severity, ReadinessGapSeverity.low);
    });
  });

  group('M7C DifficultyReadinessProfile', () {
    test('difficulty profile round trips', () {
      const original = DifficultyReadinessProfile(
        standardAccuracy: 0.8,
        hardAccuracy: 0.7,
        ultraHardAccuracy: 0.5,
        dimension: ReadinessDimension(
          code: 'DIFFICULTY',
          value: 0.63,
          evidenceConfidence: EvidenceConfidence.high,
        ),
        state: DifficultyReadinessState.developing,
      );
      final decoded = DifficultyReadinessProfile.fromJson(original.toJson());
      expect(decoded.standardAccuracy, 0.8);
      expect(decoded.hardAccuracy, 0.7);
      expect(decoded.ultraHardAccuracy, 0.5);
      expect(decoded.state, DifficultyReadinessState.developing);
    });

    test('unknown difficulty state falls back unavailable', () {
      final decoded = DifficultyReadinessProfile.fromJson({
        'dimension': {
          'code': 'D',
          'value': null,
          'evidenceConfidence': 'none',
        },
        'state': 'mystery',
      });
      expect(decoded.state, DifficultyReadinessState.unavailable);
    });
  });

  group('M7C BlueprintCoverageSummary', () {
    test('subtopic denominator has priority', () {
      const summary = BlueprintCoverageSummary(
        competenciesTotal: 47,
        competenciesAssessed: 40,
        topicsTotal: 100,
        topicsAssessed: 80,
        subtopicsTotal: 200,
        subtopicsAssessed: 100,
      );
      expect(summary.ratio, 0.5);
      expect(summary.percent, 50);
    });

    test('topic denominator is fallback when no subtopics', () {
      const summary = BlueprintCoverageSummary(
        competenciesTotal: 47,
        competenciesAssessed: 40,
        topicsTotal: 100,
        topicsAssessed: 80,
        subtopicsTotal: 0,
        subtopicsAssessed: 0,
      );
      expect(summary.ratio, 0.8);
    });

    test('competency denominator is final fallback', () {
      const summary = BlueprintCoverageSummary(
        competenciesTotal: 10,
        competenciesAssessed: 4,
        topicsTotal: 0,
        topicsAssessed: 0,
        subtopicsTotal: 0,
        subtopicsAssessed: 0,
      );
      expect(summary.ratio, 0.4);
    });

    test('zero denominators return zero', () {
      const summary = BlueprintCoverageSummary(
        competenciesTotal: 0,
        competenciesAssessed: 0,
        topicsTotal: 0,
        topicsAssessed: 0,
        subtopicsTotal: 0,
        subtopicsAssessed: 0,
      );
      expect(summary.ratio, 0);
    });

    test('coverage ratio clamps above one', () {
      const summary = BlueprintCoverageSummary(
        competenciesTotal: 2,
        competenciesAssessed: 8,
        topicsTotal: 0,
        topicsAssessed: 0,
        subtopicsTotal: 0,
        subtopicsAssessed: 0,
      );
      expect(summary.ratio, 1);
    });
  });

  group('M7C CompetencyReadinessProfile', () {
    CompetencyReadinessProfile profile() {
      return CompetencyReadinessProfile(
        competencyId: 'd03_c02',
        generatedAt: DateTime(2026, 9, 18),
        readinessAlgorithmVersion:
            CompetencyReadinessProfile.currentAlgorithmVersion,
        knowledgeMastery: const ReadinessDimension(
          code: 'K',
          value: 0.7,
          evidenceConfidence: EvidenceConfidence.high,
        ),
        applicationAbility: const ReadinessDimension(
          code: 'A',
          value: 0.6,
          evidenceConfidence: EvidenceConfidence.high,
        ),
        retention: const ReadinessDimension(
          code: 'R',
          value: 0.8,
          evidenceConfidence: EvidenceConfidence.moderate,
        ),
        difficultyPerformance: const DifficultyReadinessProfile(
          standardAccuracy: 0.8,
          hardAccuracy: 0.7,
          ultraHardAccuracy: 0.5,
          dimension: ReadinessDimension(
            code: 'D',
            value: 0.63,
            evidenceConfidence: EvidenceConfidence.high,
          ),
          state: DifficultyReadinessState.developing,
        ),
        blueprintCoverage: const ReadinessDimension(
          code: 'C',
          value: 0.75,
          evidenceConfidence: EvidenceConfidence.high,
        ),
        confidenceCalibration: const ReadinessDimension(
          code: 'CC',
          value: 0.85,
          evidenceConfidence: EvidenceConfidence.moderate,
        ),
        recentPerformance: const ReadinessDimension(
          code: 'RP',
          value: 0.7,
          evidenceConfidence: EvidenceConfidence.moderate,
        ),
        stability: const ReadinessDimension(
          code: 'S',
          value: 0.8,
          evidenceConfidence: EvidenceConfidence.moderate,
        ),
        evidenceConfidence: EvidenceConfidence.high,
        readinessState: ReadinessState.developing,
        gaps: const [],
        limitingFactors: const [],
        explanationCodes: const ['X'],
      );
    }

    test('profile round trips through JSON', () {
      final original = profile();
      final decoded = CompetencyReadinessProfile.fromJson(original.toJson());
      expect(decoded.competencyId, original.competencyId);
      expect(decoded.readinessState, original.readinessState);
      expect(decoded.knowledgeMastery.value, 0.7);
      expect(decoded.difficultyPerformance.ultraHardAccuracy, 0.5);
    });

    test('profile rejects invalid generated timestamp', () {
      final json = profile().toJson()..['generatedAt'] = 'broken';
      expect(
        () => CompetencyReadinessProfile.fromJson(json),
        throwsFormatException,
      );
    });

    test('profile hasCriticalGap detects critical gap', () {
      final base = profile();
      final json = base.toJson();
      json['gaps'] = [
        const ReadinessGap(
          type: ReadinessGapType.masteryGap,
          severity: ReadinessGapSeverity.critical,
          competencyId: 'd03_c02',
          reasonCode: 'X',
          explanation: 'X',
          evidenceLimited: false,
        ).toJson(),
      ];
      final decoded = CompetencyReadinessProfile.fromJson(json);
      expect(decoded.hasCriticalGap, isTrue);
    });

    test('profile hasEvidenceGap detects evidence gap', () {
      final base = profile();
      final json = base.toJson();
      json['gaps'] = [
        const ReadinessGap(
          type: ReadinessGapType.evidenceGap,
          severity: ReadinessGapSeverity.moderate,
          competencyId: 'd03_c02',
          reasonCode: 'X',
          explanation: 'X',
          evidenceLimited: true,
        ).toJson(),
      ];
      final decoded = CompetencyReadinessProfile.fromJson(json);
      expect(decoded.hasEvidenceGap, isTrue);
    });

    test('profile current algorithm version is nonempty', () {
      expect(CompetencyReadinessProfile.currentAlgorithmVersion, isNotEmpty);
    });
  });

  group('M7C dashboard contract', () {
    test('dashboard explicitly has no composite readiness index', () {
      final dashboard = ExamReadinessDashboard(
        generatedAt: DateTime(2026, 9, 18),
        algorithmVersion: 'm7c-v1',
        evidenceConfidence: EvidenceConfidence.moderate,
        knowledgeMastery: const ReadinessDimension(
          code: 'K',
          value: null,
          evidenceConfidence: EvidenceConfidence.moderate,
        ),
        applicationAbility: const ReadinessDimension(
          code: 'A',
          value: null,
          evidenceConfidence: EvidenceConfidence.moderate,
        ),
        retention: const ReadinessDimension(
          code: 'R',
          value: null,
          evidenceConfidence: EvidenceConfidence.moderate,
        ),
        blueprintCoverage: const BlueprintCoverageSummary(
          competenciesTotal: 47,
          competenciesAssessed: 0,
          topicsTotal: 0,
          topicsAssessed: 0,
          subtopicsTotal: 0,
          subtopicsAssessed: 0,
        ),
        difficultyPerformance: const ReadinessDimension(
          code: 'D',
          value: null,
          evidenceConfidence: EvidenceConfidence.moderate,
        ),
        confidenceCalibration: const ReadinessDimension(
          code: 'CC',
          value: null,
          evidenceConfidence: EvidenceConfidence.moderate,
        ),
        criticalGapCount: 0,
        weakCompetencyCount: 0,
        evidenceGapCount: 0,
        staleCompetencyCount: 0,
        profiles: const {},
        domainCoverage: const {},
      );
      expect(dashboard.hasCompositeReadinessIndex, isFalse);
    });
  });
}
