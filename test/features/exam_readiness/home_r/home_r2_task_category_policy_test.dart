import 'package:exam_platform/features/exam_readiness/models/learning_priority_score.dart';
import 'package:exam_platform/features/exam_readiness/models/study_plan_block.dart';
import 'package:exam_platform/features/exam_readiness/models/today_plan_task_category.dart';
import 'package:exam_platform/features/exam_readiness/services/today_plan_task_category_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const policy = TodayPlanTaskCategoryPolicy();

  group('HOME-R2 TodayPlanTaskCategoryPolicy', () {
    final expected = <StudyPlanBlockType, TodayPlanTaskCategory>{
      StudyPlanBlockType.learn: TodayPlanTaskCategory.learn,
      StudyPlanBlockType.continueLearning: TodayPlanTaskCategory.learn,
      StudyPlanBlockType.repair: TodayPlanTaskCategory.learn,
      StudyPlanBlockType.diagnostic: TodayPlanTaskCategory.practice,
      StudyPlanBlockType.standardPractice: TodayPlanTaskCategory.practice,
      StudyPlanBlockType.ultraHardPractice: TodayPlanTaskCategory.practice,
      StudyPlanBlockType.mixedRetrieval: TodayPlanTaskCategory.practice,
      StudyPlanBlockType.competencyRecheck: TodayPlanTaskCategory.practice,
      StudyPlanBlockType.confidenceCalibration: TodayPlanTaskCategory.practice,
      StudyPlanBlockType.examSimulation: TodayPlanTaskCategory.practice,
      StudyPlanBlockType.spacedReview: TodayPlanTaskCategory.remember,
    };

    test('maps every unambiguous block type to the frozen category', () {
      for (final entry in expected.entries) {
        expect(
          policy.categoryFor(_block(entry.key)),
          entry.value,
          reason: '${entry.key.name} must keep its frozen HOME-R category',
        );
      }
    });

    test('test matrix remains exhaustive when StudyPlanBlockType changes', () {
      expect(
        <StudyPlanBlockType>{...expected.keys, StudyPlanBlockType.recovery},
        StudyPlanBlockType.values.toSet(),
      );
    });

    test('review-oriented recovery maps to Remember', () {
      final block = _block(
        StudyPlanBlockType.recovery,
        reasonCodes: const <String>['RETENTION_DUE'],
      );

      expect(policy.categoryFor(block), TodayPlanTaskCategory.remember);
    });

    test('review recovery reason matching is normalized', () {
      final block = _block(
        StudyPlanBlockType.recovery,
        reasonCodes: const <String>['  retention_due  '],
      );

      expect(policy.categoryFor(block), TodayPlanTaskCategory.remember);
    });

    test('ambiguous recovery fails closed', () {
      final block = _block(
        StudyPlanBlockType.recovery,
        reasonCodes: const <String>['ASSESSMENT_BALANCE'],
      );

      expect(
        () => policy.categoryFor(block),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains(block.blockId),
          ),
        ),
      );
    });

    test('recovery without reasons fails closed', () {
      final block = _block(
        StudyPlanBlockType.recovery,
        reasonCodes: const <String>[],
      );

      expect(() => policy.categoryFor(block), throwsStateError);
    });
  });
}

StudyPlanBlock _block(
  StudyPlanBlockType type, {
  List<String> reasonCodes = const <String>['TEST_REASON'],
}) {
  return StudyPlanBlock(
    blockId: 'home-r2-${type.name}',
    type: type,
    domainId: 'd01',
    competencyId: 'd01_c01',
    subtopicId: 'd01_c01_s01',
    topicId: 'd01_c01_t01',
    plannedMinutes: 15,
    questionCount: 0,
    priorityScore: 0.5,
    priorityBreakdown: const LearningPriorityScore(
      competencyId: 'd01_c01',
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
      reasonCodes: <String>['TEST_REASON'],
    ),
    reasonCodes: reasonCodes,
    reasonText: 'HOME-R2 category policy test block.',
    status: StudyPlanBlockStatus.planned,
    createdAt: DateTime.utc(2026, 9, 22),
    manualChanges: const <StudyPlanManualChange>[],
  );
}
