import 'package:exam_platform/features/exam_readiness/models/evidence_confidence.dart';
import 'package:exam_platform/features/exam_readiness/models/learner_assessment_attempt.dart';
import 'package:exam_platform/features/exam_readiness/services/learner_evidence_aggregation_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '_support/m7b_fixture.dart';

void main() {
  const service = LearnerEvidenceAggregationService();
  final now = DateTime(2026, 9, 18, 12);

  group('M7B aggregation filtering and attempt statistics', () {
    test('no attempts remains unassessed rather than zero mastery', () {
      final snapshot = service.buildSnapshot(
        competencyId: 'd03_c02',
        attempts: const [],
        scope: m7bScope(),
        now: now,
      );
      expect(snapshot.sourceAttemptCount, 0);
      expect(snapshot.attempts.accuracy, isNull);
      expect(snapshot.evidenceQuality.state, EvidenceState.unassessed);
    });

    test('one eligible attempt is counted', () {
      final snapshot = service.buildSnapshot(
        competencyId: 'd03_c02',
        attempts: [m7bAttempt()],
        scope: m7bScope(),
        now: now,
      );
      expect(snapshot.attempts.total, 1);
      expect(snapshot.attempts.uniqueQuestions, 1);
    });

    test('correct and incorrect counts reconcile to total', () {
      final snapshot = service.buildSnapshot(
        competencyId: 'd03_c02',
        attempts: [
          m7bAttempt(attemptId: 'a1', correct: true),
          m7bAttempt(attemptId: 'a2', questionId: 2, correct: false),
        ],
        scope: m7bScope(),
        now: now,
      );
      expect(snapshot.attempts.correct, 1);
      expect(snapshot.attempts.incorrect, 1);
      expect(snapshot.attempts.total, 2);
    });

    test('duplicate attempt event ID is counted once', () {
      final snapshot = service.buildSnapshot(
        competencyId: 'd03_c02',
        attempts: [
          m7bAttempt(attemptId: 'dup', questionId: 1),
          m7bAttempt(attemptId: 'dup', questionId: 2),
        ],
        scope: m7bScope(),
        now: now,
      );
      expect(snapshot.attempts.total, 1);
    });

    test('same question with distinct events counts repeated attempt', () {
      final snapshot = service.buildSnapshot(
        competencyId: 'd03_c02',
        attempts: [
          m7bAttempt(attemptId: 'a1', questionId: 1),
          m7bAttempt(attemptId: 'a2', questionId: 1),
        ],
        scope: m7bScope(),
        now: now,
      );
      expect(snapshot.attempts.total, 2);
      expect(snapshot.attempts.uniqueQuestions, 1);
      expect(snapshot.attempts.repeatedAttempts, 1);
    });

    test('unpublished question attempt is excluded', () {
      final snapshot = service.buildSnapshot(
        competencyId: 'd03_c02',
        attempts: [m7bAttempt(publishedAtAttempt: false)],
        scope: m7bScope(),
        now: now,
      );
      expect(snapshot.attempts.total, 0);
    });

    test('malformed competency attempt is excluded', () {
      final snapshot = service.buildSnapshot(
        competencyId: 'd03_c02',
        attempts: [m7bAttempt(competencyId: 'D3-C2')],
        scope: m7bScope(),
        now: now,
      );
      expect(snapshot.attempts.total, 0);
    });

    test('attempt from another canonical competency is excluded', () {
      final snapshot = service.buildSnapshot(
        competencyId: 'd03_c02',
        attempts: [m7bAttempt(competencyId: 'd03_c01')],
        scope: m7bScope(),
        now: now,
      );
      expect(snapshot.attempts.total, 0);
    });

    test('invalid question ID is excluded', () {
      final snapshot = service.buildSnapshot(
        competencyId: 'd03_c02',
        attempts: [m7bAttempt(questionId: 0)],
        scope: m7bScope(),
        now: now,
      );
      expect(snapshot.attempts.total, 0);
    });

    test('blank attempt ID is excluded', () {
      final snapshot = service.buildSnapshot(
        competencyId: 'd03_c02',
        attempts: [m7bAttempt(attemptId: ' ')],
        scope: m7bScope(),
        now: now,
      );
      expect(snapshot.attempts.total, 0);
    });

    test(
      'source question can disappear after attempt without losing evidence',
      () {
        final snapshot = service.buildSnapshot(
          competencyId: 'd03_c02',
          attempts: [m7bAttempt(questionId: 9999)],
          scope: m7bScope(),
          now: now,
        );
        expect(snapshot.attempts.total, 1);
        expect(snapshot.attempts.uniqueQuestions, 1);
      },
    );
  });

  group('M7B coverage and breadth', () {
    test('coverage starts at zero with no evidence', () {
      final snapshot = service.buildSnapshot(
        competencyId: 'd03_c02',
        attempts: const [],
        scope: m7bScope(topics: 4, subtopics: 8),
        now: now,
      );
      expect(snapshot.coverage.coverageRatio, 0);
    });

    test('one of eight subtopics gives 12.5 percent coverage', () {
      final snapshot = service.buildSnapshot(
        competencyId: 'd03_c02',
        attempts: [m7bAttempt(subtopicId: 's1')],
        scope: m7bScope(subtopics: 8),
        now: now,
      );
      expect(snapshot.coverage.coverageRatio, 0.125);
    });

    test('duplicate subtopic attempts do not inflate breadth', () {
      final snapshot = service.buildSnapshot(
        competencyId: 'd03_c02',
        attempts: [
          m7bAttempt(attemptId: 'a1', questionId: 1, subtopicId: 's1'),
          m7bAttempt(attemptId: 'a2', questionId: 2, subtopicId: 's1'),
        ],
        scope: m7bScope(subtopics: 8),
        now: now,
      );
      expect(snapshot.coverage.subtopicsAssessed, 1);
    });

    test('broad subtopic evidence counts distinct subtopics', () {
      final snapshot = service.buildSnapshot(
        competencyId: 'd03_c02',
        attempts: [
          m7bAttempt(attemptId: 'a1', questionId: 1, subtopicId: 's1'),
          m7bAttempt(attemptId: 'a2', questionId: 2, subtopicId: 's2'),
          m7bAttempt(attemptId: 'a3', questionId: 3, subtopicId: 's3'),
          m7bAttempt(attemptId: 'a4', questionId: 4, subtopicId: 's4'),
        ],
        scope: m7bScope(subtopics: 8),
        now: now,
      );
      expect(snapshot.coverage.subtopicsAssessed, 4);
      expect(snapshot.coverage.coverageRatio, 0.5);
    });

    test('unknown subtopic outside canonical scope does not count', () {
      final snapshot = service.buildSnapshot(
        competencyId: 'd03_c02',
        attempts: [m7bAttempt(subtopicId: 's99')],
        scope: m7bScope(subtopics: 8),
        now: now,
      );
      expect(snapshot.coverage.subtopicsAssessed, 0);
    });

    test('unknown topic outside canonical scope does not count', () {
      final snapshot = service.buildSnapshot(
        competencyId: 'd03_c02',
        attempts: [m7bAttempt(topicId: 't99')],
        scope: m7bScope(topics: 4),
        now: now,
      );
      expect(snapshot.coverage.topicsAssessed, 0);
    });

    test('coverage cannot exceed one hundred percent', () {
      final attempts = <LearnerAssessmentAttempt>[];
      for (var i = 1; i <= 20; i++) {
        attempts.add(
          m7bAttempt(
            attemptId: 'a${i}',
            questionId: i,
            subtopicId: 's${(i % 8) + 1}',
            topicId: 't${(i % 4) + 1}',
          ),
        );
      }

      final snapshot = service.buildSnapshot(
        competencyId: 'd03_c02',
        attempts: attempts,
        scope: m7bScope(topics: 4, subtopics: 8),
        now: now,
      );
      expect(snapshot.coverage.coverageRatio, lessThanOrEqualTo(1));
    });

    test('zero subtopic denominator falls back to topic coverage', () {
      final snapshot = service.buildSnapshot(
        competencyId: 'd03_c02',
        attempts: [m7bAttempt(topicId: 't1')],
        scope: m7bScope(topics: 4, subtopics: 0),
        now: now,
      );
      expect(snapshot.coverage.coverageRatio, 0.25);
    });

    test('zero denominators remain zero coverage', () {
      final snapshot = service.buildSnapshot(
        competencyId: 'd03_c02',
        attempts: [m7bAttempt()],
        scope: m7bScope(topics: 0, subtopics: 0),
        now: now,
      );
      expect(snapshot.coverage.coverageRatio, 0);
    });

    test('high evidence confidence cannot exist with zero breadth', () {
      final attempts = [
        for (var i = 1; i <= 30; i++)
          m7bAttempt(
            attemptId: 'a${i}',
            questionId: i,
            subtopicId: '',
            topicId: '',
          ),
      ];

      final snapshot = service.buildSnapshot(
        competencyId: 'd03_c02',
        attempts: attempts,
        scope: m7bScope(),
        now: now,
      );
      expect(
        snapshot.evidenceQuality.confidenceLevel.rank,
        lessThanOrEqualTo(EvidenceConfidence.low.rank),
      );
    });
  });

  group('M7B cognitive and difficulty lanes', () {
    test('application attempt enters application lane', () {
      final snapshot = service.buildSnapshot(
        competencyId: 'd03_c02',
        attempts: [m7bAttempt(cognitiveLevel: 'application')],
        scope: m7bScope(),
        now: now,
      );
      expect(snapshot.cognition.applicationAttempts, 1);
    });

    test('analysis attempt enters analysis lane', () {
      final snapshot = service.buildSnapshot(
        competencyId: 'd03_c02',
        attempts: [m7bAttempt(cognitiveLevel: 'analysis')],
        scope: m7bScope(),
        now: now,
      );
      expect(snapshot.cognition.analysisAttempts, 1);
    });

    test('evaluate wording enters analysis lane', () {
      final snapshot = service.buildSnapshot(
        competencyId: 'd03_c02',
        attempts: [m7bAttempt(cognitiveLevel: 'evaluate')],
        scope: m7bScope(),
        now: now,
      );
      expect(snapshot.cognition.analysisAttempts, 1);
    });

    test('unknown cognitive wording falls to recall lane', () {
      final snapshot = service.buildSnapshot(
        competencyId: 'd03_c02',
        attempts: [m7bAttempt(cognitiveLevel: 'remember')],
        scope: m7bScope(),
        now: now,
      );
      expect(snapshot.cognition.recallAttempts, 1);
    });

    test('application accuracy is null without application attempts', () {
      final snapshot = service.buildSnapshot(
        competencyId: 'd03_c02',
        attempts: [m7bAttempt(cognitiveLevel: 'analysis')],
        scope: m7bScope(),
        now: now,
      );
      expect(snapshot.cognition.applicationAccuracy, isNull);
    });

    test('analysis accuracy reflects correct proportion', () {
      final snapshot = service.buildSnapshot(
        competencyId: 'd03_c02',
        attempts: [
          m7bAttempt(
            attemptId: 'a1',
            questionId: 1,
            cognitiveLevel: 'analysis',
            correct: true,
          ),
          m7bAttempt(
            attemptId: 'a2',
            questionId: 2,
            cognitiveLevel: 'analysis',
            correct: false,
          ),
        ],
        scope: m7bScope(),
        now: now,
      );
      expect(snapshot.cognition.analysisAccuracy, 0.5);
    });

    test('standard lane remains separate', () {
      final snapshot = service.buildSnapshot(
        competencyId: 'd03_c02',
        attempts: [m7bAttempt(difficultyLane: AttemptDifficultyLane.standard)],
        scope: m7bScope(),
        now: now,
      );
      expect(snapshot.difficulty.standardAttempts, 1);
      expect(snapshot.difficulty.hardAttempts, 0);
      expect(snapshot.difficulty.ultraHardAttempts, 0);
    });

    test('hard lane remains separate', () {
      final snapshot = service.buildSnapshot(
        competencyId: 'd03_c02',
        attempts: [m7bAttempt(difficultyLane: AttemptDifficultyLane.hard)],
        scope: m7bScope(),
        now: now,
      );
      expect(snapshot.difficulty.hardAttempts, 1);
      expect(snapshot.difficulty.ultraHardAttempts, 0);
    });

    test('Ultra Hard lane remains distinct from Hard', () {
      final snapshot = service.buildSnapshot(
        competencyId: 'd03_c02',
        attempts: [m7bAttempt(difficultyLane: AttemptDifficultyLane.ultraHard)],
        scope: m7bScope(),
        now: now,
      );
      expect(snapshot.difficulty.ultraHardAttempts, 1);
      expect(snapshot.difficulty.hardAttempts, 0);
    });

    test('mixed difficulty preserves all three lane counts', () {
      final snapshot = service.buildSnapshot(
        competencyId: 'd03_c02',
        attempts: [
          m7bAttempt(
            attemptId: 's',
            questionId: 1,
            difficultyLane: AttemptDifficultyLane.standard,
          ),
          m7bAttempt(
            attemptId: 'h',
            questionId: 2,
            difficultyLane: AttemptDifficultyLane.hard,
          ),
          m7bAttempt(
            attemptId: 'u',
            questionId: 3,
            difficultyLane: AttemptDifficultyLane.ultraHard,
          ),
        ],
        scope: m7bScope(),
        now: now,
      );
      expect(snapshot.difficulty.activeLanes, 3);
      expect(snapshot.difficulty.standardAttempts, 1);
      expect(snapshot.difficulty.hardAttempts, 1);
      expect(snapshot.difficulty.ultraHardAttempts, 1);
    });

    test('Ultra Hard accuracy can differ from Hard accuracy', () {
      final snapshot = service.buildSnapshot(
        competencyId: 'd03_c02',
        attempts: [
          m7bAttempt(
            attemptId: 'h1',
            questionId: 1,
            difficultyLane: AttemptDifficultyLane.hard,
            correct: true,
          ),
          m7bAttempt(
            attemptId: 'u1',
            questionId: 2,
            difficultyLane: AttemptDifficultyLane.ultraHard,
            correct: false,
          ),
        ],
        scope: m7bScope(),
        now: now,
      );
      expect(snapshot.difficulty.hardAccuracy, 1);
      expect(snapshot.difficulty.ultraHardAccuracy, 0);
    });
  });

  group('M7B recency and evidence state', () {
    test('today is very recent', () {
      final snapshot = service.buildSnapshot(
        competencyId: 'd03_c02',
        attempts: [m7bAttempt(answeredAt: now)],
        scope: m7bScope(),
        now: now,
      );
      expect(snapshot.recency.band, EvidenceRecencyBand.veryRecent);
    });

    test('seven days is very recent', () {
      final snapshot = service.buildSnapshot(
        competencyId: 'd03_c02',
        attempts: [
          m7bAttempt(answeredAt: now.subtract(const Duration(days: 7))),
        ],
        scope: m7bScope(),
        now: now,
      );
      expect(snapshot.recency.band, EvidenceRecencyBand.veryRecent);
    });

    test('eight days is recent', () {
      final snapshot = service.buildSnapshot(
        competencyId: 'd03_c02',
        attempts: [
          m7bAttempt(answeredAt: now.subtract(const Duration(days: 8))),
        ],
        scope: m7bScope(),
        now: now,
      );
      expect(snapshot.recency.band, EvidenceRecencyBand.recent);
    });

    test('31 days is aging', () {
      final snapshot = service.buildSnapshot(
        competencyId: 'd03_c02',
        attempts: [
          m7bAttempt(answeredAt: now.subtract(const Duration(days: 31))),
        ],
        scope: m7bScope(),
        now: now,
      );
      expect(snapshot.recency.band, EvidenceRecencyBand.aging);
    });

    test('61 days is stale', () {
      final snapshot = service.buildSnapshot(
        competencyId: 'd03_c02',
        attempts: [
          m7bAttempt(answeredAt: now.subtract(const Duration(days: 61))),
        ],
        scope: m7bScope(),
        now: now,
      );
      expect(snapshot.recency.band, EvidenceRecencyBand.stale);
      expect(snapshot.evidenceQuality.state, EvidenceState.stale);
    });

    test('91 days is very stale', () {
      final snapshot = service.buildSnapshot(
        competencyId: 'd03_c02',
        attempts: [
          m7bAttempt(answeredAt: now.subtract(const Duration(days: 91))),
        ],
        scope: m7bScope(),
        now: now,
      );
      expect(snapshot.recency.band, EvidenceRecencyBand.veryStale);
      expect(snapshot.evidenceQuality.state, EvidenceState.stale);
    });

    test('attempts7d excludes older evidence', () {
      final snapshot = service.buildSnapshot(
        competencyId: 'd03_c02',
        attempts: [
          m7bAttempt(
            attemptId: 'new',
            questionId: 1,
            answeredAt: now.subtract(const Duration(days: 2)),
          ),
          m7bAttempt(
            attemptId: 'old',
            questionId: 2,
            answeredAt: now.subtract(const Duration(days: 8)),
          ),
        ],
        scope: m7bScope(),
        now: now,
      );
      expect(snapshot.recency.attempts7d, 1);
      expect(snapshot.recency.attempts30d, 2);
    });

    test('attempts30d excludes evidence older than thirty days', () {
      final snapshot = service.buildSnapshot(
        competencyId: 'd03_c02',
        attempts: [
          m7bAttempt(
            attemptId: 'new',
            questionId: 1,
            answeredAt: now.subtract(const Duration(days: 20)),
          ),
          m7bAttempt(
            attemptId: 'old',
            questionId: 2,
            answeredAt: now.subtract(const Duration(days: 31)),
          ),
        ],
        scope: m7bScope(),
        now: now,
      );
      expect(snapshot.recency.attempts30d, 1);
    });
  });

  group('M7B confidence calibration and quality', () {
    test('missing confidence data remains unavailable', () {
      final snapshot = service.buildSnapshot(
        competencyId: 'd03_c02',
        attempts: [m7bAttempt(confidence: null)],
        scope: m7bScope(),
        now: now,
      );
      expect(snapshot.confidence.confidenceSamples, 0);
      expect(snapshot.confidence.calibrationError, isNull);
    });

    test('high confidence incorrect is overconfidence signal', () {
      final snapshot = service.buildSnapshot(
        competencyId: 'd03_c02',
        attempts: [
          m7bAttempt(correct: false, confidence: LearnerConfidenceLevel.high),
        ],
        scope: m7bScope(),
        now: now,
      );
      expect(snapshot.confidence.highConfidenceIncorrectCount, 1);
      expect(snapshot.confidence.overconfidenceRate, 1);
    });

    test('low confidence correct is underconfidence signal', () {
      final snapshot = service.buildSnapshot(
        competencyId: 'd03_c02',
        attempts: [
          m7bAttempt(correct: true, confidence: LearnerConfidenceLevel.low),
        ],
        scope: m7bScope(),
        now: now,
      );
      expect(snapshot.confidence.underconfidenceRate, 1);
    });

    test('high confidence correct has low calibration error', () {
      final snapshot = service.buildSnapshot(
        competencyId: 'd03_c02',
        attempts: [
          m7bAttempt(correct: true, confidence: LearnerConfidenceLevel.high),
        ],
        scope: m7bScope(),
        now: now,
      );
      expect(snapshot.confidence.calibrationError, closeTo(0.15, 0.0001));
    });

    test('high confidence incorrect has high calibration error', () {
      final snapshot = service.buildSnapshot(
        competencyId: 'd03_c02',
        attempts: [
          m7bAttempt(correct: false, confidence: LearnerConfidenceLevel.high),
        ],
        scope: m7bScope(),
        now: now,
      );
      expect(snapshot.confidence.calibrationError, closeTo(0.85, 0.0001));
    });

    test('perfect performance with one question remains low evidence', () {
      final snapshot = service.buildSnapshot(
        competencyId: 'd03_c02',
        attempts: [m7bAttempt(correct: true)],
        scope: m7bScope(),
        now: now,
      );
      expect(snapshot.attempts.accuracy, 1);
      expect(
        snapshot.evidenceQuality.confidenceLevel.rank,
        lessThanOrEqualTo(EvidenceConfidence.low.rank),
      );
    });

    test('poor performance can coexist with broad strong evidence', () {
      final attempts = [
        for (var i = 1; i <= 16; i++)
          m7bAttempt(
            attemptId: 'a${i}',
            questionId: i,
            topicId: 't${(i % 4) + 1}',
            subtopicId: 's${(i % 8) + 1}',
            correct: false,
            cognitiveLevel: i.isEven ? 'application' : 'analysis',
            difficultyLane: i % 3 == 0
                ? AttemptDifficultyLane.ultraHard
                : i % 2 == 0
                ? AttemptDifficultyLane.hard
                : AttemptDifficultyLane.standard,
          ),
      ];

      final snapshot = service.buildSnapshot(
        competencyId: 'd03_c02',
        attempts: attempts,
        scope: m7bScope(),
        now: now,
      );
      expect(snapshot.attempts.accuracy, 0);
      expect(snapshot.coverage.coverageRatio, 1);
      expect(
        snapshot.evidenceQuality.confidenceLevel.rank,
        greaterThanOrEqualTo(EvidenceConfidence.moderate.rank),
      );
    });

    test('repeated same-question concentration is recorded', () {
      final attempts = [
        for (var i = 1; i <= 10; i++)
          m7bAttempt(attemptId: 'a${i}', questionId: 1),
      ];
      final snapshot = service.buildSnapshot(
        competencyId: 'd03_c02',
        attempts: attempts,
        scope: m7bScope(),
        now: now,
      );
      expect(
        snapshot.evidenceQuality.breakdown.repeatedAttemptConcentration,
        0.9,
      );
    });

    test('retention confidence is none without delayed retrieval', () {
      final snapshot = service.buildSnapshot(
        competencyId: 'd03_c02',
        attempts: [m7bAttempt()],
        scope: m7bScope(),
        now: now,
      );
      expect(
        snapshot.evidenceQuality.breakdown.retention,
        EvidenceConfidence.none,
      );
      expect(snapshot.retention.delayedAccuracy, isNull);
    });
  });

  group('M7B traceability and rebuild behavior', () {
    test('traceability reports eligible attempt volume', () {
      final snapshot = service.buildSnapshot(
        competencyId: 'd03_c02',
        attempts: [m7bAttempt()],
        scope: m7bScope(),
        now: now,
      );
      expect(
        snapshot.traceability.any((line) => line.contains('eligible attempts')),
        isTrue,
      );
    });

    test('traceability reports Ultra Hard count', () {
      final snapshot = service.buildSnapshot(
        competencyId: 'd03_c02',
        attempts: [m7bAttempt(difficultyLane: AttemptDifficultyLane.ultraHard)],
        scope: m7bScope(),
        now: now,
      );
      expect(
        snapshot.traceability.any((line) => line.contains('Ultra Hard')),
        isTrue,
      );
    });

    test('traceability reports missing delayed retrieval', () {
      final snapshot = service.buildSnapshot(
        competencyId: 'd03_c02',
        attempts: [m7bAttempt()],
        scope: m7bScope(),
        now: now,
      );
      expect(snapshot.traceability, contains('No delayed retrieval evidence'));
    });

    test('traceability reports missing confidence samples', () {
      final snapshot = service.buildSnapshot(
        competencyId: 'd03_c02',
        attempts: [m7bAttempt()],
        scope: m7bScope(),
        now: now,
      );
      expect(snapshot.traceability, contains('No learner-confidence samples'));
    });

    test('buildAllSnapshots emits every requested competency', () {
      final snapshots = service.buildAllSnapshots(
        attempts: [
          m7bAttempt(competencyId: 'd03_c02'),
          m7bAttempt(attemptId: 'd1', questionId: 2, competencyId: 'd01_c01'),
        ],
        scopes: [
          m7bScope(competencyId: 'd03_c02'),
          m7bScope(competencyId: 'd01_c01'),
        ],
        now: now,
      );
      expect(snapshots.keys, containsAll(['d03_c02', 'd01_c01']));
    });

    test('buildAllSnapshots still emits unassessed requested competency', () {
      final snapshots = service.buildAllSnapshots(
        attempts: const [],
        scopes: [m7bScope(competencyId: 'd03_c02')],
        now: now,
      );
      expect(
        snapshots['d03_c02']?.evidenceQuality.state,
        EvidenceState.unassessed,
      );
    });

    test('incremental update returns only targeted competency snapshot', () {
      final snapshot = service.updateCompetencySnapshot(
        competencyId: 'd03_c02',
        attemptsForCompetency: [
          m7bAttempt(),
          m7bAttempt(
            attemptId: 'other',
            questionId: 2,
            competencyId: 'd01_c01',
          ),
        ],
        scope: m7bScope(),
        now: now,
      );
      expect(snapshot.competencyId, 'd03_c02');
      expect(snapshot.attempts.total, 1);
    });

    test('snapshot records schema and algorithm versions', () {
      final snapshot = service.buildSnapshot(
        competencyId: 'd03_c02',
        attempts: [m7bAttempt()],
        scope: m7bScope(),
        now: now,
      );
      expect(snapshot.schemaVersion, greaterThan(0));
      expect(snapshot.algorithmVersion, isNotEmpty);
    });

    test('source attempt count matches eligible deduplicated evidence', () {
      final snapshot = service.buildSnapshot(
        competencyId: 'd03_c02',
        attempts: [
          m7bAttempt(attemptId: 'a1'),
          m7bAttempt(attemptId: 'a1'),
          m7bAttempt(attemptId: 'a2', questionId: 2),
          m7bAttempt(
            attemptId: 'draft',
            questionId: 3,
            publishedAtAttempt: false,
          ),
        ],
        scope: m7bScope(),
        now: now,
      );
      expect(snapshot.sourceAttemptCount, 2);
    });
  });
}
