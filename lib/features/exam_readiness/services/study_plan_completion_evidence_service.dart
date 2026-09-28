import '../../../models/student_learning_progress.dart';
import '../../flashcards/learning/flashcard_recall_event.dart';
import '../models/learner_assessment_attempt.dart';
import '../models/study_plan_block.dart';
import '../models/today_plan_task_category.dart';
import 'today_plan_task_category_policy.dart';

enum StudyPlanCompletionEvidenceSource {
  plannedPracticeSession,
  flashcardReviewSession,
  labScenarioCompleted,
  studyContent,
  explicitLearnerFinish,
}

class StudyPlanCompletionDecision {
  const StudyPlanCompletionDecision._({
    required this.eligible,
    required this.message,
  });

  const StudyPlanCompletionDecision.allowed({
    String message = 'Completion evidence is sufficient.',
  }) : this._(eligible: true, message: message);

  const StudyPlanCompletionDecision.blocked(String message)
    : this._(eligible: false, message: message);

  final bool eligible;
  final String message;
}

class StudyPlanCompletionEvidenceService {
  const StudyPlanCompletionEvidenceService({
    this.categoryPolicy = const TodayPlanTaskCategoryPolicy(),
  });

  final TodayPlanTaskCategoryPolicy categoryPolicy;

  static String sessionKindForBlock(String blockId) =>
      'study_plan:${blockId.trim()}';

  bool allowsExplicitLearnerFinish(StudyPlanBlock block) =>
      categoryPolicy.categoryFor(block) == TodayPlanTaskCategory.learn;

  String startedTaskHint(StudyPlanBlock block) {
    final category = categoryPolicy.categoryFor(block);
    switch (category) {
      case TodayPlanTaskCategory.learn:
        return 'Complete study content or finish this planned learning task.';
      case TodayPlanTaskCategory.practice:
        final applicationLab =
            block.type == StudyPlanBlockType.repair &&
            block.reasonCodes.any(
              (reason) => reason.trim().toUpperCase() == 'APPLICATION_GAP',
            );
        return applicationLab
            ? 'Completes automatically when the planned LAB scenario finishes.'
            : 'Completes automatically when the planned quiz finishes.';
      case TodayPlanTaskCategory.remember:
        return 'Rate the assigned Flashcards to finish this Remember task.';
    }
  }

  StudyPlanCompletionDecision evaluate({
    required StudyPlanBlock block,
    required StudyPlanCompletionEvidenceSource source,
    required Iterable<LearnerAssessmentAttempt> attempts,
    required Iterable<StudentSubtopicProgress> studyProgress,
    Iterable<FlashcardRecallEvent> flashcardRecallEvents =
        const <FlashcardRecallEvent>[],
    required DateTime completedAt,
  }) {
    final startedAt = block.startedAt;
    if (block.status != StudyPlanBlockStatus.started || startedAt == null) {
      return const StudyPlanCompletionDecision.blocked(
        'The planned task must be started before it can be completed.',
      );
    }

    if (completedAt.isBefore(startedAt)) {
      return const StudyPlanCompletionDecision.blocked(
        'Completion evidence cannot precede the task start time.',
      );
    }

    final category = categoryPolicy.categoryFor(block);

    switch (source) {
      case StudyPlanCompletionEvidenceSource.explicitLearnerFinish:
        if (category != TodayPlanTaskCategory.learn) {
          return const StudyPlanCompletionDecision.blocked(
            'Manual completion is available only for planned learning tasks.',
          );
        }
        return const StudyPlanCompletionDecision.allowed(
          message: 'Learner explicitly finished the planned learning task.',
        );

      case StudyPlanCompletionEvidenceSource.flashcardReviewSession:
        if (category != TodayPlanTaskCategory.remember) {
          return const StudyPlanCompletionDecision.blocked(
            'Flashcard review evidence can complete only a Remember task.',
          );
        }
        return _flashcardDecision(
          block: block,
          recallEvents: flashcardRecallEvents,
          startedAt: startedAt,
          completedAt: completedAt,
        );

      case StudyPlanCompletionEvidenceSource.labScenarioCompleted:
        final applicationGap = block.reasonCodes.any(
          (reason) => reason.trim().toUpperCase() == 'APPLICATION_GAP',
        );
        if (block.type != StudyPlanBlockType.repair || !applicationGap) {
          return const StudyPlanCompletionDecision.blocked(
            'LAB completion can complete only an application-gap repair task.',
          );
        }
        return const StudyPlanCompletionDecision.allowed(
          message: 'A terminal LAB scenario provides completion evidence.',
        );

      case StudyPlanCompletionEvidenceSource.plannedPracticeSession:
        if (category != TodayPlanTaskCategory.practice) {
          return const StudyPlanCompletionDecision.blocked(
            'Quiz evidence cannot complete a non-practice task.',
          );
        }
        return _practiceDecision(
          block: block,
          attempts: attempts,
          startedAt: startedAt,
          completedAt: completedAt,
        );

      case StudyPlanCompletionEvidenceSource.studyContent:
        if (category == TodayPlanTaskCategory.practice) {
          return const StudyPlanCompletionDecision.blocked(
            'Study-content evidence cannot complete a practice task.',
          );
        }
        return _studyDecision(
          block: block,
          studyProgress: studyProgress,
          startedAt: startedAt,
          completedAt: completedAt,
          category: category,
        );
    }
  }

  StudyPlanCompletionDecision _flashcardDecision({
    required StudyPlanBlock block,
    required Iterable<FlashcardRecallEvent> recallEvents,
    required DateTime startedAt,
    required DateTime completedAt,
  }) {
    final competency = block.competencyId.trim().toLowerCase();
    final reviewedCards = <String>{};
    for (final event in recallEvents) {
      if (event.source != FlashcardReviewSource.dailyPlan ||
          event.blockId != block.blockId ||
          event.competencyId != competency ||
          event.sameSessionRepeat ||
          event.attemptSequence != 1 ||
          event.occurredAt.isBefore(startedAt) ||
          event.occurredAt.isAfter(completedAt)) {
        continue;
      }
      reviewedCards.add(event.cardId);
    }

    final requiredCards = (block.plannedMinutes ~/ 3).clamp(3, 8).toInt();
    if (reviewedCards.length < requiredCards) {
      return StudyPlanCompletionDecision.blocked(
        'Rate at least $requiredCards assigned Flashcards first. '
        '${reviewedCards.length} qualifying cards are recorded.',
      );
    }

    return StudyPlanCompletionDecision.allowed(
      message:
          '${reviewedCards.length} distinct Flashcard ratings provide completion evidence.',
    );
  }

  StudyPlanCompletionDecision _practiceDecision({
    required StudyPlanBlock block,
    required Iterable<LearnerAssessmentAttempt> attempts,
    required DateTime startedAt,
    required DateTime completedAt,
  }) {
    if (block.questionCount <= 0) {
      return const StudyPlanCompletionDecision.blocked(
        'The planned practice task has no valid question requirement.',
      );
    }

    final expectedSession = sessionKindForBlock(block.blockId);
    final questionIds = <int>{};

    for (final attempt in attempts) {
      if (!attempt.publishedAtAttempt ||
          attempt.sessionKind != expectedSession ||
          attempt.competencyId.trim().toLowerCase() !=
              block.competencyId.trim().toLowerCase() ||
          attempt.answeredAt.isBefore(startedAt) ||
          attempt.answeredAt.isAfter(completedAt)) {
        continue;
      }
      questionIds.add(attempt.questionId);
    }

    if (questionIds.length < block.questionCount) {
      return StudyPlanCompletionDecision.blocked(
        'Complete all ${block.questionCount} planned quiz questions first. '
        '${questionIds.length} qualifying answers are recorded.',
      );
    }

    return StudyPlanCompletionDecision.allowed(
      message:
          '${questionIds.length} planned quiz answers provide completion evidence.',
    );
  }

  StudyPlanCompletionDecision _studyDecision({
    required StudyPlanBlock block,
    required Iterable<StudentSubtopicProgress> studyProgress,
    required DateTime startedAt,
    required DateTime completedAt,
    required TodayPlanTaskCategory category,
  }) {
    final targetSubtopic = block.subtopicId.trim();
    final competency = block.competencyId.trim().toLowerCase();

    for (final progress in studyProgress) {
      final evidenceAt = progress.lastCompletedAt ?? progress.completedAt;
      if (progress.state != StudentLearningState.completed ||
          evidenceAt == null ||
          evidenceAt.isBefore(startedAt) ||
          evidenceAt.isAfter(completedAt) ||
          progress.competencyId.trim().toLowerCase() != competency) {
        continue;
      }

      if (targetSubtopic.isNotEmpty &&
          progress.subtopicId.trim() != targetSubtopic) {
        continue;
      }

      return StudyPlanCompletionDecision.allowed(
        message:
            'Completed subtopic ${progress.subtopicId} provides study evidence.',
      );
    }

    if (category == TodayPlanTaskCategory.remember) {
      return const StudyPlanCompletionDecision.blocked(
        'Complete a reviewed subtopic after starting this Remember task.',
      );
    }

    return const StudyPlanCompletionDecision.blocked(
      'No new completed study subtopic is recorded for this planned task yet.',
    );
  }
}
