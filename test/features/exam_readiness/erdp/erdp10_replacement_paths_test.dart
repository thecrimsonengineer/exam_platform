import 'package:exam_platform/features/exam_readiness/models/daily_study_plan.dart';
import 'package:exam_platform/features/exam_readiness/models/study_plan_block.dart';
import 'package:exam_platform/features/exam_readiness/models/study_plan_execution_target.dart';
import 'package:exam_platform/features/exam_readiness/repositories/daily_study_plan_repository.dart';
import 'package:exam_platform/features/exam_readiness/services/executable_daily_plan_action_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../m7d/_support/m7d_fixture.dart';

StudyPlanBlock _block(StudyPlanBlockType type) {
  final questionCount = switch (type) {
    StudyPlanBlockType.diagnostic ||
    StudyPlanBlockType.standardPractice ||
    StudyPlanBlockType.ultraHardPractice ||
    StudyPlanBlockType.mixedRetrieval ||
    StudyPlanBlockType.competencyRecheck ||
    StudyPlanBlockType.confidenceCalibration ||
    StudyPlanBlockType.examSimulation => 5,
    _ => 0,
  };

  return StudyPlanBlock(
    blockId: 'erdp10-replacement-${type.name}',
    type: type,
    domainId: 'd01',
    competencyId: 'd01_c01',
    subtopicId: '',
    topicId: '',
    plannedMinutes: 10,
    questionCount: questionCount,
    priorityScore: 0.8,
    priorityBreakdown: m7dPriority(competencyId: 'd01_c01'),
    reasonCodes: const <String>['ERDP10_REPLACEMENT_MATRIX'],
    reasonText: 'Validate replacement method choice.',
    status: StudyPlanBlockStatus.planned,
    createdAt: DateTime.utc(2026, 9, 28, 8),
    manualChanges: const <StudyPlanManualChange>[],
  );
}

DailyStudyPlan _plan(StudyPlanBlock block) => DailyStudyPlan(
  planId: 'erdp10-replacement-plan',
  userId: 'learner-1',
  date: DateTime.utc(2026, 9, 28),
  generatedAt: DateTime.utc(2026, 9, 28, 8),
  planVersion: 1,
  plannerAlgorithmVersion: DailyStudyPlan.currentAlgorithmVersion,
  availableMinutes: 60,
  allocatedMinutes: block.plannedMinutes,
  generationReason: DailyStudyPlanGenerationReason.initial,
  sourceEvidenceVersion: 'e1',
  sourceReadinessVersion: 'r1',
  blocks: <StudyPlanBlock>[block],
  status: DailyStudyPlanStatus.active,
  schemaVersion: DailyStudyPlan.currentSchemaVersion,
);

StudyPlanExecutionTarget _target(StudyPlanBlock block) {
  final kind = switch (block.type) {
    StudyPlanBlockType.spacedReview ||
    StudyPlanBlockType.recovery => StudyPlanExecutionTargetKind.flashcardReview,
    StudyPlanBlockType.diagnostic ||
    StudyPlanBlockType.standardPractice ||
    StudyPlanBlockType.ultraHardPractice ||
    StudyPlanBlockType.mixedRetrieval ||
    StudyPlanBlockType.competencyRecheck ||
    StudyPlanBlockType.confidenceCalibration =>
      StudyPlanExecutionTargetKind.practiceSession,
    StudyPlanBlockType.examSimulation =>
      StudyPlanExecutionTargetKind.examSimulation,
    _ => StudyPlanExecutionTargetKind.studyContent,
  };

  return StudyPlanExecutionTarget(
    kind: kind,
    blockId: block.blockId,
    blockType: block.type,
    domainId: block.domainId,
    domainNumber: 1,
    domainTitle: 'Advanced Sciences and Math',
    competencyId: block.competencyId,
    competencyTitle: 'Replacement matrix competency',
    plannedMinutes: block.plannedMinutes,
    questionCount: block.questionCount,
    dueOnly: kind == StudyPlanExecutionTargetKind.flashcardReview,
    reviewReason: kind == StudyPlanExecutionTargetKind.flashcardReview
        ? block.reasonText
        : null,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final cases =
      <
        ({
          String name,
          StudyPlanBlockType source,
          StudyPlanBlockType alternative,
          StudyPlanExecutionTargetKind targetKind,
        })
      >[
        (
          name: 'Learn to Practice',
          source: StudyPlanBlockType.learn,
          alternative: StudyPlanBlockType.standardPractice,
          targetKind: StudyPlanExecutionTargetKind.practiceSession,
        ),
        (
          name: 'Learn to Flashcards',
          source: StudyPlanBlockType.learn,
          alternative: StudyPlanBlockType.spacedReview,
          targetKind: StudyPlanExecutionTargetKind.flashcardReview,
        ),
        (
          name: 'Practice to Learn',
          source: StudyPlanBlockType.standardPractice,
          alternative: StudyPlanBlockType.continueLearning,
          targetKind: StudyPlanExecutionTargetKind.studyContent,
        ),
        (
          name: 'Practice to Flashcards',
          source: StudyPlanBlockType.standardPractice,
          alternative: StudyPlanBlockType.spacedReview,
          targetKind: StudyPlanExecutionTargetKind.flashcardReview,
        ),
        (
          name: 'Flashcards to Learn',
          source: StudyPlanBlockType.spacedReview,
          alternative: StudyPlanBlockType.continueLearning,
          targetKind: StudyPlanExecutionTargetKind.studyContent,
        ),
        (
          name: 'Flashcards to Practice',
          source: StudyPlanBlockType.spacedReview,
          alternative: StudyPlanBlockType.standardPractice,
          targetKind: StudyPlanExecutionTargetKind.practiceSession,
        ),
      ];

  for (final replacementCase in cases) {
    test(replacementCase.name, () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final sourceBlock = _block(replacementCase.source);
      final sourcePlan = _plan(sourceBlock);
      final repository = DailyStudyPlanRepository(userIdOverride: 'learner-1');
      await repository.savePlan(sourcePlan, syncRemote: false);
      final actions = ExecutableDailyPlanActionService(
        repository: repository,
        resolveTarget: _target,
      );

      expect(
        actions.replacementOptionsFor(sourceBlock),
        contains(replacementCase.alternative),
      );

      final result = await actions.replace(
        sourcePlan: sourcePlan,
        blockId: sourceBlock.blockId,
        alternativeType: replacementCase.alternative,
        at: DateTime.utc(2026, 9, 28, 9),
      );

      final original = result.plan.blocks.firstWhere(
        (block) => block.blockId == sourceBlock.blockId,
      );
      final replacement = result.replacementBlock!;

      expect(original.status, StudyPlanBlockStatus.replaced);
      expect(original.replacedByBlockId, replacement.blockId);
      expect(replacement.replacesBlockId, original.blockId);
      expect(replacement.competencyId, sourceBlock.competencyId);
      expect(replacement.type, replacementCase.alternative);
      expect(_target(replacement).kind, replacementCase.targetKind);
    });
  }

  test(
    'unsupported replacement method is rejected before persistence',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final sourceBlock = _block(StudyPlanBlockType.learn);
      final sourcePlan = _plan(sourceBlock);
      final repository = DailyStudyPlanRepository(userIdOverride: 'learner-1');
      await repository.savePlan(sourcePlan, syncRemote: false);
      final actions = ExecutableDailyPlanActionService(
        repository: repository,
        resolveTarget: _target,
      );

      await expectLater(
        actions.replace(
          sourcePlan: sourcePlan,
          blockId: sourceBlock.blockId,
          alternativeType: StudyPlanBlockType.examSimulation,
          at: DateTime.utc(2026, 9, 28, 9),
        ),
        throwsStateError,
      );

      final latest = await repository.loadLatestForDate(sourcePlan.date);
      expect(latest!.planVersion, sourcePlan.planVersion);
      expect(latest.blocks.single.status, StudyPlanBlockStatus.planned);
    },
  );
}
