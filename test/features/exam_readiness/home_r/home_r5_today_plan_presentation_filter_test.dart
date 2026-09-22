import 'package:exam_platform/features/exam_readiness/models/learning_priority_score.dart';
import 'package:exam_platform/features/exam_readiness/models/study_plan_block.dart';
import 'package:exam_platform/features/exam_readiness/models/today_plan_task_category.dart';
import 'package:exam_platform/features/exam_readiness/services/today_plan_presentation_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const filter = TodayPlanPresentationFilter();

  group('HOME-R5 TodayPlanPresentationFilter', () {
    final blocks = <StudyPlanBlock>[
      _block('learn', StudyPlanBlockType.learn),
      _block('practice', StudyPlanBlockType.standardPractice),
      _block(
        'remember',
        StudyPlanBlockType.spacedReview,
        reasonCodes: const <String>['RETENTION_DUE'],
      ),
    ];

    test('null category preserves the full authoritative block order', () {
      final visible = filter.apply(blocks: blocks);

      expect(visible.map((block) => block.blockId), <String>[
        'learn',
        'practice',
        'remember',
      ]);
      expect(identical(visible[0], blocks[0]), isTrue);
      expect(() => visible.add(blocks[0]), throwsUnsupportedError);
    });

    test('filters Learn without copying or changing block identity', () {
      final visible = filter.apply(
        blocks: blocks,
        category: TodayPlanTaskCategory.learn,
      );

      expect(visible.map((block) => block.blockId), <String>['learn']);
      expect(identical(visible.single, blocks.first), isTrue);
    });

    test('filters Practice and Remember through the shared R2 policy', () {
      expect(
        filter
            .apply(blocks: blocks, category: TodayPlanTaskCategory.practice)
            .map((block) => block.blockId),
        <String>['practice'],
      );
      expect(
        filter
            .apply(blocks: blocks, category: TodayPlanTaskCategory.remember)
            .map((block) => block.blockId),
        <String>['remember'],
      );
    });

    test('category with no matching block returns an empty projection', () {
      final visible = filter.apply(
        blocks: <StudyPlanBlock>[
          _block('learn-only', StudyPlanBlockType.learn),
        ],
        category: TodayPlanTaskCategory.practice,
      );

      expect(visible, isEmpty);
    });

    test(
      'ambiguous recovery fails closed only when classification is needed',
      () {
        final recovery = _block(
          'recovery',
          StudyPlanBlockType.recovery,
          reasonCodes: const <String>['ASSESSMENT_BALANCE'],
        );

        expect(filter.apply(blocks: <StudyPlanBlock>[recovery]), hasLength(1));
        expect(
          () => filter.apply(
            blocks: <StudyPlanBlock>[recovery],
            category: TodayPlanTaskCategory.remember,
          ),
          throwsStateError,
        );
      },
    );
  });
}

StudyPlanBlock _block(
  String id,
  StudyPlanBlockType type, {
  List<String> reasonCodes = const <String>['TEST_REASON'],
}) {
  return StudyPlanBlock(
    blockId: id,
    type: type,
    domainId: 'd01',
    competencyId: 'd01_c01',
    subtopicId: 'd01_c01_s01',
    topicId: 'd01_c01_t01',
    plannedMinutes: 15,
    questionCount: 0,
    priorityScore: 0.5,
    priorityBreakdown: LearningPriorityScore(
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
      reasonCodes: reasonCodes,
    ),
    reasonCodes: reasonCodes,
    reasonText: 'HOME-R5 filter test block.',
    status: StudyPlanBlockStatus.planned,
    createdAt: DateTime(2026, 9, 22),
    manualChanges: const <StudyPlanManualChange>[],
  );
}
