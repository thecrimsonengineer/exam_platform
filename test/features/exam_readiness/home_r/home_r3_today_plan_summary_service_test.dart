import 'package:exam_platform/features/exam_readiness/models/daily_study_plan.dart';
import 'package:exam_platform/features/exam_readiness/models/learning_priority_score.dart';
import 'package:exam_platform/features/exam_readiness/models/study_plan_block.dart';
import 'package:exam_platform/features/exam_readiness/services/today_plan_summary_service.dart';
import 'package:exam_platform/features/exam_readiness/services/today_plan_task_category_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = TodayPlanSummaryService();

  group('HOME-R3 TodayPlanSummaryService', () {
    test('empty plan returns stable empty summaries for all categories', () {
      final plan = _plan(const <StudyPlanBlock>[]);

      final summary = service.summarize(plan);

      expect(summary.planId, plan.planId);
      expect(summary.planVersion, plan.planVersion);
      expect(summary.date, plan.date);
      expect(summary.planStatus, plan.status);
      expect(summary.availableMinutes, 60);
      expect(summary.allocatedMinutes, 0);
      expect(summary.taskCount, 0);
      expect(summary.completedTaskCount, 0);
      expect(summary.completedMinutes, 0);
      expect(summary.questionCount, 0);
      expect(summary.completedQuestionCount, 0);
      expect(summary.isEmpty, isTrue);
      expect(summary.isComplete, isFalse);
      expect(summary.categories.keys.toSet(), TodayPlanTaskCategory.values.toSet());

      for (final category in TodayPlanTaskCategory.values) {
        final item = summary.category(category);
        expect(item.category, category);
        expect(item.isEmpty, isTrue);
        expect(item.isComplete, isFalse);
        expect(item.nextBlockId, isNull);
        expect(item.nextCompetencyId, isNull);
      }
    });

    test('aggregates Learn Practice and Remember through the R2 policy', () {
      final plan = _plan(<StudyPlanBlock>[
        _block(
          id: 'learn-complete',
          type: StudyPlanBlockType.learn,
          competencyId: 'd01_c01',
          minutes: 20,
          status: StudyPlanBlockStatus.completed,
        ),
        _block(
          id: 'learn-next',
          type: StudyPlanBlockType.repair,
          competencyId: 'd02_c01',
          minutes: 15,
          status: StudyPlanBlockStatus.planned,
        ),
        _block(
          id: 'practice-complete',
          type: StudyPlanBlockType.diagnostic,
          competencyId: 'd03_c01',
          minutes: 10,
          questions: 5,
          status: StudyPlanBlockStatus.completed,
        ),
        _block(
          id: 'practice-next',
          type: StudyPlanBlockType.mixedRetrieval,
          competencyId: 'd04_c01',
          minutes: 10,
          questions: 4,
          status: StudyPlanBlockStatus.started,
        ),
        _block(
          id: 'remember-next',
          type: StudyPlanBlockType.spacedReview,
          competencyId: 'd05_c01',
          minutes: 5,
          status: StudyPlanBlockStatus.planned,
          reasonCodes: const <String>['RETENTION_DUE'],
        ),
      ]);

      final summary = service.summarize(plan);
      final learn = summary.category(TodayPlanTaskCategory.learn);
      final practice = summary.category(TodayPlanTaskCategory.practice);
      final remember = summary.category(TodayPlanTaskCategory.remember);

      expect(summary.taskCount, 5);
      expect(summary.completedTaskCount, 2);
      expect(summary.remainingTaskCount, 3);
      expect(summary.allocatedMinutes, 60);
      expect(summary.completedMinutes, 30);
      expect(summary.remainingMinutes, 30);
      expect(summary.questionCount, 9);
      expect(summary.completedQuestionCount, 5);
      expect(summary.remainingQuestionCount, 4);
      expect(summary.isComplete, isFalse);

      expect(learn.taskCount, 2);
      expect(learn.completedTaskCount, 1);
      expect(learn.plannedMinutes, 35);
      expect(learn.completedMinutes, 20);
      expect(learn.remainingMinutes, 15);
      expect(learn.nextBlockId, 'learn-next');
      expect(learn.nextCompetencyId, 'd02_c01');

      expect(practice.taskCount, 2);
      expect(practice.completedTaskCount, 1);
      expect(practice.questionCount, 9);
      expect(practice.completedQuestionCount, 5);
      expect(practice.remainingQuestionCount, 4);
      expect(practice.nextBlockId, 'practice-next');
      expect(practice.nextCompetencyId, 'd04_c01');

      expect(remember.taskCount, 1);
      expect(remember.completedTaskCount, 0);
      expect(remember.plannedMinutes, 5);
      expect(remember.nextBlockId, 'remember-next');
      expect(remember.nextCompetencyId, 'd05_c01');
    });

    test('completed state uses only explicit completed block status', () {
      final plan = _plan(<StudyPlanBlock>[
        _block(
          id: 'planned',
          type: StudyPlanBlockType.standardPractice,
          competencyId: 'd01_c01',
          minutes: 10,
          questions: 5,
          status: StudyPlanBlockStatus.planned,
        ),
        _block(
          id: 'started',
          type: StudyPlanBlockType.standardPractice,
          competencyId: 'd01_c02',
          minutes: 10,
          questions: 5,
          status: StudyPlanBlockStatus.started,
        ),
        _block(
          id: 'skipped',
          type: StudyPlanBlockType.standardPractice,
          competencyId: 'd01_c03',
          minutes: 10,
          questions: 5,
          status: StudyPlanBlockStatus.skipped,
        ),
        _block(
          id: 'moved',
          type: StudyPlanBlockType.standardPractice,
          competencyId: 'd01_c04',
          minutes: 10,
          questions: 5,
          status: StudyPlanBlockStatus.movedToTomorrow,
        ),
        _block(
          id: 'shortened',
          type: StudyPlanBlockType.standardPractice,
          competencyId: 'd01_c05',
          minutes: 5,
          questions: 3,
          status: StudyPlanBlockStatus.shortened,
        ),
        _block(
          id: 'unavailable',
          type: StudyPlanBlockType.standardPractice,
          competencyId: 'd01_c06',
          minutes: 10,
          questions: 5,
          status: StudyPlanBlockStatus.unavailable,
        ),
        _block(
          id: 'completed',
          type: StudyPlanBlockType.standardPractice,
          competencyId: 'd01_c07',
          minutes: 10,
          questions: 5,
          status: StudyPlanBlockStatus.completed,
        ),
      ]);

      final summary = service.summarize(plan);
      final practice = summary.category(TodayPlanTaskCategory.practice);

      expect(summary.completedTaskCount, 1);
      expect(summary.completedMinutes, 10);
      expect(summary.completedQuestionCount, 5);
      expect(practice.completedTaskCount, 1);
      expect(practice.isComplete, isFalse);
      expect(practice.nextBlockId, 'planned');
      expect(practice.nextCompetencyId, 'd01_c01');
    });

    test('all completed category is complete and has no next task', () {
      final plan = _plan(<StudyPlanBlock>[
        _block(
          id: 'review-1',
          type: StudyPlanBlockType.spacedReview,
          competencyId: 'd06_c01',
          minutes: 10,
          status: StudyPlanBlockStatus.completed,
          reasonCodes: const <String>['RETENTION_DUE'],
        ),
        _block(
          id: 'review-2',
          type: StudyPlanBlockType.spacedReview,
          competencyId: 'd06_c02',
          minutes: 10,
          status: StudyPlanBlockStatus.completed,
          reasonCodes: const <String>['RETENTION_DUE'],
        ),
      ]);

      final summary = service.summarize(plan);
      final remember = summary.category(TodayPlanTaskCategory.remember);

      expect(summary.isComplete, isTrue);
      expect(remember.isComplete, isTrue);
      expect(remember.remainingTaskCount, 0);
      expect(remember.remainingMinutes, 0);
      expect(remember.nextBlockId, isNull);
      expect(remember.nextCompetencyId, isNull);
    });

    test('review-oriented recovery is summarized under Remember', () {
      final plan = _plan(<StudyPlanBlock>[
        _block(
          id: 'recovery-review',
          type: StudyPlanBlockType.recovery,
          competencyId: 'd07_c01',
          minutes: 10,
          status: StudyPlanBlockStatus.planned,
          reasonCodes: const <String>['RETENTION_DUE'],
        ),
      ]);

      final summary = service.summarize(plan);

      expect(
        summary.category(TodayPlanTaskCategory.remember).taskCount,
        1,
      );
    });

    test('ambiguous recovery fails closed instead of being silently counted', () {
      final plan = _plan(<StudyPlanBlock>[
        _block(
          id: 'ambiguous-recovery',
          type: StudyPlanBlockType.recovery,
          competencyId: 'd07_c02',
          minutes: 10,
          status: StudyPlanBlockStatus.planned,
          reasonCodes: const <String>['ASSESSMENT_BALANCE'],
        ),
      ]);

      expect(() => service.summarize(plan), throwsStateError);
    });

    test('summary creation does not mutate the authoritative plan', () {
      final plan = _plan(<StudyPlanBlock>[
        _block(
          id: 'immutable-source',
          type: StudyPlanBlockType.standardPractice,
          competencyId: 'd01_c01',
          minutes: 15,
          questions: 6,
          status: StudyPlanBlockStatus.started,
        ),
      ]);
      final before = plan.toJson();

      service.summarize(plan);

      expect(plan.toJson(), before);
    });
  });
}

DailyStudyPlan _plan(List<StudyPlanBlock> blocks) {
  final allocated = blocks.fold<int>(
    0,
    (sum, block) => sum + block.plannedMinutes,
  );

  return DailyStudyPlan(
    planId: 'home-r3-plan',
    userId: 'learner-1',
    date: DateTime(2026, 9, 22),
    generatedAt: DateTime(2026, 9, 22, 8),
    planVersion: 3,
    plannerAlgorithmVersion: DailyStudyPlan.currentAlgorithmVersion,
    availableMinutes: allocated > 60 ? allocated : 60,
    allocatedMinutes: allocated,
    generationReason: DailyStudyPlanGenerationReason.initial,
    sourceEvidenceVersion: 'e1',
    sourceReadinessVersion: 'r1',
    blocks: blocks,
    status: DailyStudyPlanStatus.active,
    schemaVersion: DailyStudyPlan.currentSchemaVersion,
  );
}

StudyPlanBlock _block({
  required String id,
  required StudyPlanBlockType type,
  required String competencyId,
  required int minutes,
  required StudyPlanBlockStatus status,
  int questions = 0,
  List<String> reasonCodes = const <String>['TEST_REASON'],
}) {
  return StudyPlanBlock(
    blockId: id,
    type: type,
    domainId: competencyId.substring(0, 3),
    competencyId: competencyId,
    subtopicId: '${competencyId}_s01',
    topicId: '${competencyId}_t01',
    plannedMinutes: minutes,
    questionCount: questions,
    priorityScore: 0.5,
    priorityBreakdown: LearningPriorityScore(
      competencyId: competencyId,
      blueprintImportance: 0.5,
      masteryGap: 0.5,
      applicationGap: 0.5,
      retentionRisk: 0.5,
      coverageGap: 0.5,
      evidenceDebt: 0.5,
      staleness: 0.5,
      difficultyWeakness: 0.5,
      examProximity: 0.5,
      prerequisiteImportance: 0.5,
      recentStudyPenalty: 0.5,
      evidenceDebtLevel: EvidenceDebtLevel.moderate,
      totalScore: 0.5,
      reasonCodes: reasonCodes,
    ),
    reasonCodes: reasonCodes,
    reasonText: 'HOME-R3 summary test block.',
    status: status,
    createdAt: DateTime(2026, 9, 22, 8),
    completedAt: status == StudyPlanBlockStatus.completed
        ? DateTime(2026, 9, 22, 9)
        : null,
    startedAt:
        status == StudyPlanBlockStatus.started ||
            status == StudyPlanBlockStatus.completed
        ? DateTime(2026, 9, 22, 8, 30)
        : null,
    manualChanges: const <StudyPlanManualChange>[],
  );
}
