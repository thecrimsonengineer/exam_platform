import 'package:exam_platform/features/exam_readiness/services/retention_evidence_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '_support/m7b_fixture.dart';

void main() {
  const service = RetentionEvidenceService();

  group('M7B RetentionEvidenceService delay classification', () {
    test('negative gap is initial', () {
      expect(
        service.classifyDelay(const Duration(hours: -1)),
        RetentionDelayBand.initial,
      );
    });

    test('zero gap is immediate', () {
      expect(
        service.classifyDelay(Duration.zero),
        RetentionDelayBand.immediate,
      );
    });

    test('23 hours is immediate', () {
      expect(
        service.classifyDelay(const Duration(hours: 23)),
        RetentionDelayBand.immediate,
      );
    });

    test('24 hours is short delay', () {
      expect(
        service.classifyDelay(const Duration(hours: 24)),
        RetentionDelayBand.shortDelay,
      );
    });

    test('7 days is short delay', () {
      expect(
        service.classifyDelay(const Duration(days: 7)),
        RetentionDelayBand.shortDelay,
      );
    });

    test('8 days is medium delay', () {
      expect(
        service.classifyDelay(const Duration(days: 8)),
        RetentionDelayBand.mediumDelay,
      );
    });

    test('30 days is medium delay', () {
      expect(
        service.classifyDelay(const Duration(days: 30)),
        RetentionDelayBand.mediumDelay,
      );
    });

    test('31 days is long delay', () {
      expect(
        service.classifyDelay(const Duration(days: 31)),
        RetentionDelayBand.longDelay,
      );
    });

    test('365 days is long delay', () {
      expect(
        service.classifyDelay(const Duration(days: 365)),
        RetentionDelayBand.longDelay,
      );
    });
  });

  group('M7B RetentionEvidenceService aggregation', () {
    final now = DateTime(2026, 9, 18, 12);

    test('no attempts means no retention evidence', () {
      final result = service.build(attempts: const [], now: now);

      expect(result.delayedAttempts, 0);
      expect(result.delayedAccuracy, isNull);
      expect(result.lastReviewedAt, isNull);
    });

    test('one attempt is not delayed evidence', () {
      final result = service.build(attempts: [m7bAttempt()], now: now);

      expect(result.delayedAttempts, 0);
      expect(result.delayedAccuracy, isNull);
      expect(result.lastReviewedAt, DateTime(2026, 9, 18, 10));
    });

    test('same question within 23 hours counts immediate only', () {
      final result = service.build(
        attempts: [
          m7bAttempt(attemptId: 'a1', answeredAt: DateTime(2026, 9, 17, 12)),
          m7bAttempt(attemptId: 'a2', answeredAt: DateTime(2026, 9, 18, 11)),
        ],
        now: now,
      );

      expect(result.immediateAttempts, 1);
      expect(result.delayedAttempts, 0);
    });

    test('same question after one day counts short delay', () {
      final result = service.build(
        attempts: [
          m7bAttempt(attemptId: 'a1', answeredAt: DateTime(2026, 9, 16, 10)),
          m7bAttempt(attemptId: 'a2', answeredAt: DateTime(2026, 9, 17, 10)),
        ],
        now: now,
      );

      expect(result.shortDelayAttempts, 1);
      expect(result.delayedAttempts, 1);
    });

    test('eight-day retrieval counts medium delay', () {
      final result = service.build(
        attempts: [
          m7bAttempt(attemptId: 'a1', answeredAt: DateTime(2026, 9, 1)),
          m7bAttempt(attemptId: 'a2', answeredAt: DateTime(2026, 9, 9)),
        ],
        now: now,
      );

      expect(result.mediumDelayAttempts, 1);
      expect(result.delayedAttempts, 1);
    });

    test('31-day retrieval counts long delay', () {
      final result = service.build(
        attempts: [
          m7bAttempt(attemptId: 'a1', answeredAt: DateTime(2026, 7, 1)),
          m7bAttempt(attemptId: 'a2', answeredAt: DateTime(2026, 8, 1)),
        ],
        now: now,
      );

      expect(result.longDelayAttempts, 1);
      expect(result.delayedAttempts, 1);
    });

    test('correct delayed retrieval contributes delayed accuracy', () {
      final result = service.build(
        attempts: [
          m7bAttempt(
            attemptId: 'a1',
            correct: false,
            answeredAt: DateTime(2026, 9, 1),
          ),
          m7bAttempt(
            attemptId: 'a2',
            correct: true,
            answeredAt: DateTime(2026, 9, 9),
          ),
        ],
        now: now,
      );

      expect(result.delayedCorrect, 1);
      expect(result.delayedAccuracy, 1);
    });

    test('incorrect delayed retrieval produces zero accuracy', () {
      final result = service.build(
        attempts: [
          m7bAttempt(
            attemptId: 'a1',
            correct: true,
            answeredAt: DateTime(2026, 9, 1),
          ),
          m7bAttempt(
            attemptId: 'a2',
            correct: false,
            answeredAt: DateTime(2026, 9, 9),
          ),
        ],
        now: now,
      );

      expect(result.delayedCorrect, 0);
      expect(result.delayedAccuracy, 0);
    });

    test('different questions do not create delayed retrieval', () {
      final result = service.build(
        attempts: [
          m7bAttempt(
            attemptId: 'a1',
            questionId: 1,
            answeredAt: DateTime(2026, 9, 1),
          ),
          m7bAttempt(
            attemptId: 'a2',
            questionId: 2,
            answeredAt: DateTime(2026, 9, 10),
          ),
        ],
        now: now,
      );

      expect(result.delayedAttempts, 0);
    });

    test('unpublished attempts are excluded from retention evidence', () {
      final result = service.build(
        attempts: [
          m7bAttempt(attemptId: 'a1', answeredAt: DateTime(2026, 9, 1)),
          m7bAttempt(
            attemptId: 'a2',
            publishedAtAttempt: false,
            answeredAt: DateTime(2026, 9, 10),
          ),
        ],
        now: now,
      );

      expect(result.delayedAttempts, 0);
    });

    test('invalid question IDs are excluded', () {
      final result = service.build(
        attempts: [
          m7bAttempt(
            attemptId: 'a1',
            questionId: 0,
            answeredAt: DateTime(2026, 9, 1),
          ),
          m7bAttempt(
            attemptId: 'a2',
            questionId: 0,
            answeredAt: DateTime(2026, 9, 10),
          ),
        ],
        now: now,
      );

      expect(result.delayedAttempts, 0);
      expect(result.lastReviewedAt, isNull);
    });

    test('attempts are sorted before delay calculation', () {
      final result = service.build(
        attempts: [
          m7bAttempt(attemptId: 'later', answeredAt: DateTime(2026, 9, 10)),
          m7bAttempt(attemptId: 'earlier', answeredAt: DateTime(2026, 9, 1)),
        ],
        now: now,
      );

      expect(result.mediumDelayAttempts, 1);
    });

    test('last reviewed is latest eligible attempt', () {
      final result = service.build(
        attempts: [
          m7bAttempt(attemptId: 'a1', answeredAt: DateTime(2026, 9, 1)),
          m7bAttempt(
            attemptId: 'a2',
            questionId: 2,
            answeredAt: DateTime(2026, 9, 17),
          ),
        ],
        now: now,
      );

      expect(result.lastReviewedAt, DateTime(2026, 9, 17));
    });

    test('days since review uses latest attempt date', () {
      final result = service.build(
        attempts: [
          m7bAttempt(attemptId: 'a1', answeredAt: DateTime(2026, 9, 10, 12)),
        ],
        now: now,
      );

      expect(result.daysSinceReview, 8);
    });

    test('future timestamp does not create negative days since review', () {
      final result = service.build(
        attempts: [
          m7bAttempt(attemptId: 'a1', answeredAt: DateTime(2026, 9, 19)),
        ],
        now: now,
      );

      expect(result.daysSinceReview, 0);
    });

    test('mixed delay windows remain separately traceable', () {
      final result = service.build(
        attempts: [
          m7bAttempt(attemptId: 'a1', answeredAt: DateTime(2026, 6, 1)),
          m7bAttempt(attemptId: 'a2', answeredAt: DateTime(2026, 7, 5)),
          m7bAttempt(attemptId: 'a3', answeredAt: DateTime(2026, 7, 15)),
          m7bAttempt(attemptId: 'a4', answeredAt: DateTime(2026, 7, 16)),
        ],
        now: now,
      );

      expect(result.longDelayAttempts, 1);
      expect(result.mediumDelayAttempts, 1);
      expect(result.shortDelayAttempts, 1);
      expect(result.delayedAttempts, 3);
    });

    test('immediate retrieval never enters delayed denominator', () {
      final result = service.build(
        attempts: [
          m7bAttempt(attemptId: 'a1', answeredAt: DateTime(2026, 9, 18, 8)),
          m7bAttempt(attemptId: 'a2', answeredAt: DateTime(2026, 9, 18, 10)),
        ],
        now: now,
      );

      expect(result.immediateAttempts, 1);
      expect(result.delayedAttempts, 0);
      expect(result.delayedAccuracy, isNull);
    });

    test('multiple questions aggregate delayed evidence independently', () {
      final result = service.build(
        attempts: [
          m7bAttempt(
            attemptId: 'q1a',
            questionId: 1,
            answeredAt: DateTime(2026, 9, 1),
          ),
          m7bAttempt(
            attemptId: 'q1b',
            questionId: 1,
            answeredAt: DateTime(2026, 9, 9),
          ),
          m7bAttempt(
            attemptId: 'q2a',
            questionId: 2,
            answeredAt: DateTime(2026, 9, 2),
          ),
          m7bAttempt(
            attemptId: 'q2b',
            questionId: 2,
            answeredAt: DateTime(2026, 9, 12),
          ),
        ],
        now: now,
      );

      expect(result.delayedAttempts, 2);
      expect(result.mediumDelayAttempts, 2);
    });

    test('retention accuracy can be fifty percent', () {
      final result = service.build(
        attempts: [
          m7bAttempt(
            attemptId: 'q1a',
            questionId: 1,
            answeredAt: DateTime(2026, 9, 1),
          ),
          m7bAttempt(
            attemptId: 'q1b',
            questionId: 1,
            correct: true,
            answeredAt: DateTime(2026, 9, 9),
          ),
          m7bAttempt(
            attemptId: 'q2a',
            questionId: 2,
            answeredAt: DateTime(2026, 9, 1),
          ),
          m7bAttempt(
            attemptId: 'q2b',
            questionId: 2,
            correct: false,
            answeredAt: DateTime(2026, 9, 9),
          ),
        ],
        now: now,
      );

      expect(result.delayedAccuracy, 0.5);
    });

    test(
      'source question removal does not erase historical attempt snapshot',
      () {
        final result = service.build(
          attempts: [
            m7bAttempt(attemptId: 'old', answeredAt: DateTime(2026, 9, 1)),
            m7bAttempt(attemptId: 'later', answeredAt: DateTime(2026, 9, 10)),
          ],
          now: now,
        );

        expect(result.delayedAttempts, 1);
        expect(result.lastReviewedAt, DateTime(2026, 9, 10));
      },
    );
  });
}
