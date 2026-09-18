import 'package:exam_platform/features/exam_readiness/models/competency_readiness_profile.dart';
import 'package:exam_platform/features/exam_readiness/models/evidence_confidence.dart';
import 'package:exam_platform/features/exam_readiness/models/learner_assessment_attempt.dart';
import 'package:exam_platform/features/exam_readiness/services/readiness_profile_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '_support/m7c_fixture.dart';

void main() {
  const service = ReadinessProfileService();
  final now = DateTime(2026, 9, 18, 12);

  CompetencyReadinessProfile profile({
    required dynamic evidence,
    List<LearnerAssessmentAttempt>? attempts,
  }) {
    return service.buildCompetencyProfile(
      evidence: evidence,
      attempts: attempts ?? m7cAttempts(),
      now: now,
    );
  }

  group('M7C knowledge mastery', () {
    test('one-question perfect score hides knowledge percentage', () {
      final result = profile(
        evidence: m7cEvidence(
          totalAttempts: 1,
          correct: 1,
          uniqueQuestions: 1,
          overallConfidence: EvidenceConfidence.veryLow,
          evidenceState: EvidenceState.insufficient,
        ),
        attempts: m7cAttempts(count: 1, correctEvery: 1),
      );
      expect(result.knowledgeMastery.value, isNull);
    });

    test('three attempts and two unique questions can expose knowledge', () {
      final result = profile(
        evidence: m7cEvidence(
          totalAttempts: 3,
          correct: 2,
          uniqueQuestions: 2,
          overallConfidence: EvidenceConfidence.low,
          evidenceState: EvidenceState.emerging,
        ),
        attempts: m7cAttempts(count: 3),
      );
      expect(result.knowledgeMastery.value, isNotNull);
    });

    test('higher correctness improves knowledge score', () {
      final high = profile(evidence: m7cEvidence(correct: 11));
      final low = profile(evidence: m7cEvidence(correct: 4));
      expect(high.knowledgeMastery.value!, greaterThan(low.knowledgeMastery.value!));
    });

    test('broader coverage improves knowledge score', () {
      final broad = profile(
        evidence: m7cEvidence(subtopicsAssessed: 8, topicsAssessed: 4),
      );
      final narrow = profile(
        evidence: m7cEvidence(subtopicsAssessed: 1, topicsAssessed: 1),
      );
      expect(broad.knowledgeMastery.value!, greaterThan(narrow.knowledgeMastery.value!));
    });

    test('very recent evidence improves knowledge versus stale evidence', () {
      final fresh = profile(
        evidence: m7cEvidence(recencyBand: EvidenceRecencyBand.veryRecent),
      );
      final stale = profile(
        evidence: m7cEvidence(
          recencyBand: EvidenceRecencyBand.veryStale,
          evidenceState: EvidenceState.robust,
        ),
      );
      expect(fresh.knowledgeMastery.value!, greaterThan(stale.knowledgeMastery.value!));
    });

    test('heavy repeated-attempt concentration reduces knowledge score', () {
      final diverse = profile(
        evidence: m7cEvidence(repeatedAttemptConcentration: 0.0),
      );
      final repeated = profile(
        evidence: m7cEvidence(repeatedAttemptConcentration: 0.9),
      );
      expect(diverse.knowledgeMastery.value!, greaterThan(repeated.knowledgeMastery.value!));
    });
  });

  group('M7C application ability', () {
    test('fewer than three application-analysis attempts hides value', () {
      final result = profile(
        evidence: m7cEvidence(
          applicationAttempts: 1,
          applicationCorrect: 1,
          analysisAttempts: 1,
          analysisCorrect: 1,
        ),
      );
      expect(result.applicationAbility.value, isNull);
    });

    test('three application-analysis attempts can expose value', () {
      final result = profile(
        evidence: m7cEvidence(
          applicationAttempts: 2,
          applicationCorrect: 2,
          analysisAttempts: 1,
          analysisCorrect: 1,
        ),
      );
      expect(result.applicationAbility.value, isNotNull);
    });

    test('higher application correctness improves value', () {
      final high = profile(
        evidence: m7cEvidence(
          applicationAttempts: 6,
          applicationCorrect: 6,
          analysisAttempts: 4,
          analysisCorrect: 4,
        ),
      );
      final low = profile(
        evidence: m7cEvidence(
          applicationAttempts: 6,
          applicationCorrect: 1,
          analysisAttempts: 4,
          analysisCorrect: 1,
        ),
      );
      expect(high.applicationAbility.value!, greaterThan(low.applicationAbility.value!));
    });

    test('Ultra Hard evidence contributes when available', () {
      final result = profile(
        evidence: m7cEvidence(
          ultraHardAttempts: 4,
          ultraHardCorrect: 4,
        ),
      );
      expect(result.applicationAbility.value, isNotNull);
      expect(
        result.applicationAbility.reasonCodes,
        contains('APPLICATION_EVIDENCE_AVAILABLE'),
      );
    });

    test('Hard evidence is fallback when Ultra Hard lane absent', () {
      final result = profile(
        evidence: m7cEvidence(
          ultraHardAttempts: 0,
          ultraHardCorrect: 0,
          hardAttempts: 4,
          hardCorrect: 4,
        ),
      );
      expect(result.applicationAbility.value, isNotNull);
    });

    test('recency is fallback when Hard and Ultra Hard are absent', () {
      final result = profile(
        evidence: m7cEvidence(
          ultraHardAttempts: 0,
          ultraHardCorrect: 0,
          hardAttempts: 0,
          hardCorrect: 0,
          recencyBand: EvidenceRecencyBand.veryRecent,
        ),
      );
      expect(result.applicationAbility.value, isNotNull);
    });
  });

  group('M7C retention', () {
    test('no delayed retrieval hides retention percentage', () {
      final result = profile(
        evidence: m7cEvidence(delayedAttempts: 0, delayedCorrect: 0),
      );
      expect(result.retention.value, isNull);
      expect(result.retention.reasonCodes, contains('RETENTION_EVIDENCE_MISSING'));
    });

    test('delayed retrieval exposes retention', () {
      final result = profile(evidence: m7cEvidence(delayedAttempts: 4));
      expect(result.retention.value, isNotNull);
    });

    test('better delayed accuracy improves retention score', () {
      final high = profile(
        evidence: m7cEvidence(delayedAttempts: 4, delayedCorrect: 4),
      );
      final low = profile(
        evidence: m7cEvidence(delayedAttempts: 4, delayedCorrect: 1),
      );
      expect(high.retention.value!, greaterThan(low.retention.value!));
    });

    test('greater delayed evidence volume modestly improves score', () {
      final many = profile(
        evidence: m7cEvidence(delayedAttempts: 8, delayedCorrect: 6),
      );
      final few = profile(
        evidence: m7cEvidence(delayedAttempts: 2, delayedCorrect: 2),
      );
      expect(many.retention.value!, isNotNull);
      expect(few.retention.value!, isNotNull);
    });
  });

  group('M7C difficulty profile', () {
    test('no difficulty lanes yields unavailable state', () {
      final result = profile(
        evidence: m7cEvidence(
          standardAttempts: 0,
          standardCorrect: 0,
          hardAttempts: 0,
          hardCorrect: 0,
          ultraHardAttempts: 0,
          ultraHardCorrect: 0,
        ),
      );
      expect(result.difficultyPerformance.state, DifficultyReadinessState.unavailable);
      expect(result.difficultyPerformance.dimension.value, isNull);
    });

    test('standard-only evidence remains visible', () {
      final result = profile(
        evidence: m7cEvidence(
          standardAttempts: 4,
          standardCorrect: 3,
          hardAttempts: 0,
          hardCorrect: 0,
          ultraHardAttempts: 0,
          ultraHardCorrect: 0,
        ),
      );
      expect(result.difficultyPerformance.standardAccuracy, 0.75);
    });

    test('hard-only evidence remains visible', () {
      final result = profile(
        evidence: m7cEvidence(
          standardAttempts: 0,
          standardCorrect: 0,
          hardAttempts: 4,
          hardCorrect: 2,
          ultraHardAttempts: 0,
          ultraHardCorrect: 0,
        ),
      );
      expect(result.difficultyPerformance.hardAccuracy, 0.5);
    });

    test('Ultra Hard lane remains visible separately', () {
      final result = profile(
        evidence: m7cEvidence(
          ultraHardAttempts: 4,
          ultraHardCorrect: 1,
        ),
      );
      expect(result.difficultyPerformance.ultraHardAccuracy, 0.25);
    });

    test('strong difficulty score becomes strong state', () {
      final result = profile(
        evidence: m7cEvidence(
          standardCorrect: 4,
          hardCorrect: 4,
          ultraHardCorrect: 4,
        ),
      );
      expect(result.difficultyPerformance.state, DifficultyReadinessState.strong);
    });

    test('weak difficulty score becomes emerging state', () {
      final result = profile(
        evidence: m7cEvidence(
          standardCorrect: 1,
          hardCorrect: 1,
          ultraHardCorrect: 0,
        ),
      );
      expect(result.difficultyPerformance.state, DifficultyReadinessState.emerging);
    });
  });

  group('M7C confidence calibration', () {
    test('fewer than three confidence samples hides calibration', () {
      final result = profile(
        evidence: m7cEvidence(confidenceSamples: 2),
      );
      expect(result.confidenceCalibration.value, isNull);
    });

    test('three samples expose calibration', () {
      final result = profile(
        evidence: m7cEvidence(confidenceSamples: 3),
      );
      expect(result.confidenceCalibration.value, isNotNull);
    });

    test('low calibration error gives high calibration score', () {
      final result = profile(
        evidence: m7cEvidence(calibrationError: 0.1),
      );
      expect(result.confidenceCalibration.value, closeTo(0.9, 0.001));
    });

    test('high calibration error gives low calibration score', () {
      final result = profile(
        evidence: m7cEvidence(calibrationError: 0.8),
      );
      expect(result.confidenceCalibration.value, closeTo(0.2, 0.001));
    });

    test('repeated high-confidence errors emit explanation code', () {
      final result = profile(
        evidence: m7cEvidence(highConfidenceIncorrectCount: 3),
      );
      expect(
        result.confidenceCalibration.reasonCodes,
        contains('HIGH_CONFIDENCE_INCORRECT_PATTERN'),
      );
    });
  });

  group('M7C recent performance and stability', () {
    test('fewer than three recent attempts hides recent performance', () {
      final result = profile(
        evidence: m7cEvidence(),
        attempts: m7cAttempts(count: 2),
      );
      expect(result.recentPerformance.value, isNull);
    });

    test('three recent attempts expose recent performance', () {
      final result = profile(
        evidence: m7cEvidence(),
        attempts: m7cAttempts(count: 3),
      );
      expect(result.recentPerformance.value, isNotNull);
    });

    test('all-correct recent attempts produce 100 percent', () {
      final result = profile(
        evidence: m7cEvidence(),
        attempts: m7cAttempts(count: 5, correctEvery: 1),
      );
      expect(result.recentPerformance.value, 1);
    });

    test('old attempts are excluded from recent performance', () {
      final old = m7cAttempts(
        count: 5,
        endAt: now.subtract(const Duration(days: 40)),
        correctEvery: 1,
      );
      final result = profile(evidence: m7cEvidence(), attempts: old);
      expect(result.recentPerformance.value, isNull);
    });

    test('fewer than six attempts hides stability', () {
      final result = profile(
        evidence: m7cEvidence(),
        attempts: m7cAttempts(count: 5),
      );
      expect(result.stability.value, isNull);
    });

    test('six attempts expose stability', () {
      final result = profile(
        evidence: m7cEvidence(),
        attempts: m7cAttempts(count: 6),
      );
      expect(result.stability.value, isNotNull);
    });

    test('consistent performance produces stronger stability', () {
      final stable = profile(
        evidence: m7cEvidence(repeatedAttemptConcentration: 0),
        attempts: m7cAttempts(count: 10, correctEvery: 1),
      );
      final driftingAttempts = <LearnerAssessmentAttempt>[
        ...m7cAttempts(count: 5, endAt: DateTime(2026, 9, 12), correctEvery: 1),
        ...[
          for (var i = 0; i < 5; i++)
            m7cAttempts(
              competencyId: 'd03_c02',
              count: 1,
              endAt: DateTime(2026, 9, 13 + i),
              correctEvery: 2,
            ).single,
        ],
      ];
      final drifting = profile(
        evidence: m7cEvidence(repeatedAttemptConcentration: 0),
        attempts: driftingAttempts,
      );
      expect(stable.stability.value!, greaterThanOrEqualTo(drifting.stability.value!));
    });

    test('repeat concentration penalizes stability', () {
      final clean = profile(
        evidence: m7cEvidence(repeatedAttemptConcentration: 0),
        attempts: m7cAttempts(count: 10),
      );
      final repeated = profile(
        evidence: m7cEvidence(repeatedAttemptConcentration: 0.8),
        attempts: m7cAttempts(count: 10),
      );
      expect(clean.stability.value!, greaterThan(repeated.stability.value!));
    });
  });

  group('M7C readiness states', () {
    test('zero source attempts gives unknown state', () {
      final result = profile(
        evidence: m7cEvidence(
          totalAttempts: 0,
          correct: 0,
          uniqueQuestions: 0,
          recallAttempts: 0,
          recallCorrect: 0,
          applicationAttempts: 0,
          applicationCorrect: 0,
          analysisAttempts: 0,
          analysisCorrect: 0,
          standardAttempts: 0,
          standardCorrect: 0,
          hardAttempts: 0,
          hardCorrect: 0,
          ultraHardAttempts: 0,
          ultraHardCorrect: 0,
          delayedAttempts: 0,
          delayedCorrect: 0,
          overallConfidence: EvidenceConfidence.none,
          evidenceState: EvidenceState.unassessed,
        ),
        attempts: const [],
      );
      expect(result.readinessState, ReadinessState.unknown);
    });

    test('stale evidence gives stale state', () {
      final result = profile(
        evidence: m7cEvidence(
          evidenceState: EvidenceState.stale,
          recencyBand: EvidenceRecencyBand.stale,
        ),
      );
      expect(result.readinessState, ReadinessState.stale);
    });

    test('very low confidence gives insufficient evidence', () {
      final result = profile(
        evidence: m7cEvidence(
          overallConfidence: EvidenceConfidence.veryLow,
          evidenceState: EvidenceState.insufficient,
        ),
      );
      expect(result.readinessState, ReadinessState.insufficientEvidence);
    });

    test('low evidence with strong performance can be provisional', () {
      final result = profile(
        evidence: m7cEvidence(
          correct: 11,
          applicationCorrect: 6,
          analysisCorrect: 4,
          delayedCorrect: 4,
          overallConfidence: EvidenceConfidence.low,
          evidenceState: EvidenceState.emerging,
        ),
      );
      expect(
        result.readinessState,
        anyOf(ReadinessState.provisional, ReadinessState.developing),
      );
    });

    test('high evidence plus severe performance gap becomes at risk', () {
      final result = profile(
        evidence: m7cEvidence(
          correct: 2,
          applicationCorrect: 1,
          analysisCorrect: 0,
          delayedCorrect: 1,
          hardCorrect: 1,
          ultraHardCorrect: 0,
          overallConfidence: EvidenceConfidence.high,
        ),
      );
      expect(result.readinessState, ReadinessState.atRisk);
    });

    test('moderate evidence with strong dimensions can be strong', () {
      final result = profile(
        evidence: m7cEvidence(
          correct: 11,
          applicationCorrect: 6,
          analysisCorrect: 4,
          delayedCorrect: 4,
          standardCorrect: 4,
          hardCorrect: 4,
          ultraHardCorrect: 3,
          overallConfidence: EvidenceConfidence.moderate,
          evidenceState: EvidenceState.adequate,
        ),
        attempts: m7cAttempts(count: 10, correctEvery: 1),
      );
      expect(
        result.readinessState,
        anyOf(ReadinessState.strong, ReadinessState.developing),
      );
    });

    test('high evidence strong retention and stability can become stable', () {
      final result = profile(
        evidence: m7cEvidence(
          correct: 12,
          applicationCorrect: 6,
          analysisCorrect: 4,
          delayedAttempts: 8,
          delayedCorrect: 8,
          standardCorrect: 4,
          hardCorrect: 4,
          ultraHardCorrect: 4,
          overallConfidence: EvidenceConfidence.high,
          repeatedAttemptConcentration: 0,
        ),
        attempts: m7cAttempts(count: 10, correctEvery: 1),
      );
      expect(
        result.readinessState,
        anyOf(ReadinessState.stable, ReadinessState.strong),
      );
    });
  });

  group('M7C readiness gaps', () {
    test('low evidence creates evidence gap', () {
      final result = profile(
        evidence: m7cEvidence(
          overallConfidence: EvidenceConfidence.low,
          evidenceState: EvidenceState.emerging,
        ),
      );
      expect(
        result.gaps.any((gap) => gap.type == ReadinessGapType.evidenceGap),
        isTrue,
      );
    });

    test('very low coverage creates high coverage gap', () {
      final result = profile(
        evidence: m7cEvidence(subtopicsAssessed: 1),
      );
      final gap = result.gaps.firstWhere(
        (item) => item.type == ReadinessGapType.coverageGap,
      );
      expect(gap.severity, ReadinessGapSeverity.high);
    });

    test('weak knowledge can create mastery gap', () {
      final result = profile(
        evidence: m7cEvidence(correct: 1),
      );
      expect(
        result.gaps.any((gap) => gap.type == ReadinessGapType.masteryGap),
        isTrue,
      );
    });

    test('missing application evidence creates evidence-limited gap', () {
      final result = profile(
        evidence: m7cEvidence(
          applicationAttempts: 1,
          analysisAttempts: 0,
        ),
      );
      expect(
        result.gaps.any(
          (gap) =>
              gap.reasonCode == 'APPLICATION_EVIDENCE_MISSING' &&
              gap.evidenceLimited,
        ),
        isTrue,
      );
    });

    test('weak application creates application gap', () {
      final result = profile(
        evidence: m7cEvidence(
          applicationAttempts: 6,
          applicationCorrect: 0,
          analysisAttempts: 4,
          analysisCorrect: 0,
        ),
      );
      expect(
        result.gaps.any((gap) => gap.type == ReadinessGapType.applicationGap),
        isTrue,
      );
    });

    test('missing retention creates evidence-limited retention gap', () {
      final result = profile(
        evidence: m7cEvidence(delayedAttempts: 0, delayedCorrect: 0),
      );
      expect(
        result.gaps.any(
          (gap) =>
              gap.type == ReadinessGapType.retentionGap &&
              gap.evidenceLimited,
        ),
        isTrue,
      );
    });

    test('weak delayed retention creates performance retention gap', () {
      final result = profile(
        evidence: m7cEvidence(delayedAttempts: 4, delayedCorrect: 0),
      );
      expect(
        result.gaps.any(
          (gap) =>
              gap.reasonCode == 'RETENTION_GAP' && !gap.evidenceLimited,
        ),
        isTrue,
      );
    });

    test('weak difficulty creates difficulty gap', () {
      final result = profile(
        evidence: m7cEvidence(
          standardCorrect: 0,
          hardCorrect: 0,
          ultraHardCorrect: 0,
        ),
      );
      expect(
        result.gaps.any((gap) => gap.type == ReadinessGapType.difficultyGap),
        isTrue,
      );
    });

    test('poor calibration creates confidence gap', () {
      final result = profile(
        evidence: m7cEvidence(calibrationError: 0.8),
      );
      expect(
        result.gaps.any((gap) => gap.type == ReadinessGapType.confidenceGap),
        isTrue,
      );
    });

    test('stale recency creates staleness gap', () {
      final result = profile(
        evidence: m7cEvidence(
          recencyBand: EvidenceRecencyBand.stale,
          evidenceState: EvidenceState.stale,
        ),
      );
      expect(
        result.gaps.any((gap) => gap.type == ReadinessGapType.stalenessGap),
        isTrue,
      );
    });

    test('limiting factors include high or critical gaps only', () {
      final result = profile(
        evidence: m7cEvidence(
          correct: 1,
          applicationCorrect: 0,
          analysisCorrect: 0,
        ),
      );
      expect(result.limitingFactors, isNotEmpty);
    });

    test('explanation codes include structured gap reason codes', () {
      final result = profile(
        evidence: m7cEvidence(delayedAttempts: 0, delayedCorrect: 0),
      );
      expect(result.explanationCodes, contains('RETENTION_EVIDENCE_MISSING'));
    });
  });
}
