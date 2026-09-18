import 'package:exam_platform/features/exam_readiness/models/competency_readiness_profile.dart';
import 'package:exam_platform/features/exam_readiness/models/evidence_confidence.dart';
import 'package:exam_platform/features/exam_readiness/models/readiness_gap.dart';
import 'package:exam_platform/features/exam_readiness/services/readiness_gap_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '_support/m7c_fixture.dart';

void main() {
  const service = ReadinessGapService();

  ReadinessDimension d(String code, double? value) => ReadinessDimension(
    code: code,
    value: value,
    evidenceConfidence: m7cEvidence().evidenceQuality.confidenceLevel,
  );

  DifficultyReadinessProfile difficulty(double? value) =>
      DifficultyReadinessProfile(
        standardAccuracy: value,
        hardAccuracy: value,
        ultraHardAccuracy: value,
        dimension: d('DIFFICULTY', value),
        state: value == null
            ? DifficultyReadinessState.unavailable
            : DifficultyReadinessState.developing,
      );

  List<ReadinessGap> build({
    double? knowledge = 0.8,
    double? application = 0.8,
    double? retention = 0.8,
    double coverage = 0.8,
    double? difficultyValue = 0.8,
    double? calibration = 0.8,
    dynamic evidence,
  }) {
    return service.build(
      evidence: evidence ?? m7cEvidence(),
      knowledge: d('K', knowledge),
      application: d('A', application),
      retention: d('R', retention),
      coverage: d('C', coverage),
      difficulty: difficulty(difficultyValue),
      calibration: d('CC', calibration),
    );
  }

  group('M7C ReadinessGapService', () {
    test('strong profile can have no performance gaps', () {
      final gaps = build();
      expect(
        gaps.where((gap) => !gap.evidenceLimited),
        isEmpty,
      );
    });

    test('low evidence creates assessment evidence gap', () {
      final gaps = build(
        evidence: m7cEvidence(
          overallConfidence: EvidenceConfidence.low,
          evidenceState: EvidenceState.emerging,
        ),
      );
      expect(
        gaps.any(
          (gap) => gap.reasonCode == 'INSUFFICIENT_ASSESSMENT_EVIDENCE',
        ),
        isTrue,
      );
    });

    test('very low coverage creates coverage gap', () {
      final gaps = build(coverage: 0.1);
      expect(
        gaps.any((gap) => gap.type == ReadinessGapType.coverageGap),
        isTrue,
      );
    });

    test('critical knowledge creates critical mastery gap', () {
      final gap = build(knowledge: 0.2).firstWhere(
        (gap) => gap.type == ReadinessGapType.masteryGap,
      );
      expect(gap.severity, ReadinessGapSeverity.critical);
    });

    test('moderately weak knowledge creates high mastery gap', () {
      final gap = build(knowledge: 0.5).firstWhere(
        (gap) => gap.type == ReadinessGapType.masteryGap,
      );
      expect(gap.severity, ReadinessGapSeverity.high);
    });

    test('missing application creates evidence-limited gap', () {
      final gap = build(application: null).firstWhere(
        (gap) => gap.reasonCode == 'APPLICATION_EVIDENCE_MISSING',
      );
      expect(gap.evidenceLimited, isTrue);
    });

    test('weak application creates performance gap', () {
      final gap = build(application: 0.3).firstWhere(
        (gap) => gap.type == ReadinessGapType.applicationGap,
      );
      expect(gap.evidenceLimited, isFalse);
    });

    test('missing retention creates evidence-limited retention gap', () {
      final gap = build(retention: null).firstWhere(
        (gap) => gap.type == ReadinessGapType.retentionGap,
      );
      expect(gap.evidenceLimited, isTrue);
    });

    test('weak retention creates performance retention gap', () {
      final gap = build(retention: 0.3).firstWhere(
        (gap) => gap.reasonCode == 'RETENTION_GAP',
      );
      expect(gap.evidenceLimited, isFalse);
    });

    test('weak difficulty creates difficulty gap', () {
      expect(
        build(difficultyValue: 0.3).any(
          (gap) => gap.type == ReadinessGapType.difficultyGap,
        ),
        isTrue,
      );
    });

    test('poor calibration creates confidence gap', () {
      expect(
        build(calibration: 0.3).any(
          (gap) => gap.type == ReadinessGapType.confidenceGap,
        ),
        isTrue,
      );
    });

    test('stale evidence creates staleness gap', () {
      final gaps = build(
        evidence: m7cEvidence(
          recencyBand: EvidenceRecencyBand.stale,
          evidenceState: EvidenceState.stale,
        ),
      );
      expect(
        gaps.any((gap) => gap.type == ReadinessGapType.stalenessGap),
        isTrue,
      );
    });

    test('gap collection is unmodifiable', () {
      final gaps = build(knowledge: 0.2);
      expect(
        () => gaps.add(gaps.first),
        throwsUnsupportedError,
      );
    });
  });
}
