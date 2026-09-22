import '../models/daily_study_plan.dart';
import '../models/learner_assessment_attempt.dart';
import '../models/study_plan_block.dart';
import '../models/study_plan_block_outcome.dart';

class StudyPlanOutcomeService {
  const StudyPlanOutcomeService();

  StudyPlanBlockOutcome build({
    required DailyStudyPlan plan,
    required StudyPlanBlock block,
    required Iterable<LearnerAssessmentAttempt> attempts,
    required DateTime completedAt,
    String? assessmentSessionKind,
    int? learnerRating,
    bool abandoned = false,
  }) {
    final startedAt = block.startedAt;
    if (startedAt == null) {
      throw StateError(
        'A study-plan block must be started before outcome capture.',
      );
    }
    if (completedAt.isBefore(startedAt)) {
      throw StateError('Block completion cannot precede its start time.');
    }

    final competencyId = block.competencyId.trim().toLowerCase();
    final relevant = attempts
        .where(
          (attempt) =>
              attempt.publishedAtAttempt &&
              attempt.competencyId.trim().toLowerCase() == competencyId &&
              (assessmentSessionKind == null ||
                  attempt.sessionKind == assessmentSessionKind) &&
              !attempt.answeredAt.isBefore(startedAt) &&
              !attempt.answeredAt.isAfter(completedAt),
        )
        .toList(growable: false);

    final application = relevant.where(_isApplication).toList(growable: false);
    final analysis = relevant.where(_isAnalysis).toList(growable: false);
    final ultraHard = relevant
        .where(
          (attempt) =>
              attempt.difficultyLane == AttemptDifficultyLane.ultraHard,
        )
        .toList(growable: false);

    final elapsed = completedAt.difference(startedAt).inMinutes;
    final minutesSpent = elapsed < 0 ? 0 : elapsed;

    return StudyPlanBlockOutcome(
      outcomeId: 'm7e-${plan.planId}-v${plan.planVersion}-${block.blockId}',
      planId: plan.planId,
      planVersion: plan.planVersion,
      blockId: block.blockId,
      competencyId: competencyId,
      completedAt: completedAt,
      minutesSpent: minutesSpent,
      questionsAttempted: relevant.length,
      questionsCorrect: relevant.where((attempt) => attempt.correct).length,
      applicationAccuracy: _accuracy(application),
      analysisAccuracy: _accuracy(analysis),
      ultraHardAccuracy: _accuracy(ultraHard),
      confidenceSamples: relevant
          .where((attempt) => attempt.confidence != null)
          .length,
      contentCompleted: !abandoned,
      learnerRating: learnerRating,
      abandoned: abandoned,
    );
  }

  bool _isApplication(LearnerAssessmentAttempt attempt) {
    final level = attempt.cognitiveLevel.trim().toLowerCase();
    return level.contains('application') ||
        level.contains('apply') ||
        level.contains('scenario');
  }

  bool _isAnalysis(LearnerAssessmentAttempt attempt) {
    final level = attempt.cognitiveLevel.trim().toLowerCase();
    return level.contains('analysis') || level.contains('analy');
  }

  double? _accuracy(List<LearnerAssessmentAttempt> attempts) {
    if (attempts.isEmpty) return null;
    return attempts.where((attempt) => attempt.correct).length /
        attempts.length;
  }
}
