import '../models/competency_evidence_snapshot.dart';
import '../models/learner_assessment_attempt.dart';

enum RetentionDelayBand {
  initial,
  immediate,
  shortDelay,
  mediumDelay,
  longDelay,
}

class RetentionEvidenceService {
  const RetentionEvidenceService();

  RetentionEvidenceStats build({
    required Iterable<LearnerAssessmentAttempt> attempts,
    required DateTime now,
  }) {
    final grouped = <int, List<LearnerAssessmentAttempt>>{};

    for (final attempt in attempts) {
      if (attempt.questionId <= 0 || !attempt.publishedAtAttempt) {
        continue;
      }
      grouped
          .putIfAbsent(attempt.questionId, () => <LearnerAssessmentAttempt>[])
          .add(attempt);
    }

    var delayedAttempts = 0;
    var delayedCorrect = 0;
    var immediateAttempts = 0;
    var shortDelayAttempts = 0;
    var mediumDelayAttempts = 0;
    var longDelayAttempts = 0;
    DateTime? lastReviewedAt;

    for (final questionAttempts in grouped.values) {
      questionAttempts.sort(
        (left, right) => left.answeredAt.compareTo(right.answeredAt),
      );

      for (var index = 0; index < questionAttempts.length; index++) {
        final attempt = questionAttempts[index];

        if (lastReviewedAt == null || attempt.answeredAt.isAfter(lastReviewedAt)) {
          lastReviewedAt = attempt.answeredAt;
        }

        if (index == 0) {
          continue;
        }

        final previous = questionAttempts[index - 1];
        final gap = attempt.answeredAt.difference(previous.answeredAt);
        final band = classifyDelay(gap);

        switch (band) {
          case RetentionDelayBand.initial:
            break;
          case RetentionDelayBand.immediate:
            immediateAttempts++;
            break;
          case RetentionDelayBand.shortDelay:
            delayedAttempts++;
            shortDelayAttempts++;
            if (attempt.correct) delayedCorrect++;
            break;
          case RetentionDelayBand.mediumDelay:
            delayedAttempts++;
            mediumDelayAttempts++;
            if (attempt.correct) delayedCorrect++;
            break;
          case RetentionDelayBand.longDelay:
            delayedAttempts++;
            longDelayAttempts++;
            if (attempt.correct) delayedCorrect++;
            break;
        }
      }
    }

    final daysSinceReview = lastReviewedAt == null
        ? null
        : now.difference(lastReviewedAt).inDays.clamp(0, 1 << 30);

    return RetentionEvidenceStats(
      delayedAttempts: delayedAttempts,
      delayedCorrect: delayedCorrect,
      immediateAttempts: immediateAttempts,
      shortDelayAttempts: shortDelayAttempts,
      mediumDelayAttempts: mediumDelayAttempts,
      longDelayAttempts: longDelayAttempts,
      lastReviewedAt: lastReviewedAt,
      daysSinceReview: daysSinceReview,
    );
  }

  RetentionDelayBand classifyDelay(Duration gap) {
    if (gap.isNegative) {
      return RetentionDelayBand.initial;
    }
    if (gap < const Duration(hours: 24)) {
      return RetentionDelayBand.immediate;
    }
    if (gap <= const Duration(days: 7)) {
      return RetentionDelayBand.shortDelay;
    }
    if (gap <= const Duration(days: 30)) {
      return RetentionDelayBand.mediumDelay;
    }
    return RetentionDelayBand.longDelay;
  }
}
