import 'package:exam_platform/features/exam_readiness/models/learning_priority_score.dart';
import 'package:exam_platform/features/exam_readiness/models/study_plan_block.dart';
import 'package:exam_platform/features/exam_readiness/navigation/study_plan_block_launcher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const launcher = StudyPlanBlockLauncher();

  group('HOME-R6 StudyPlanBlockLauncher', () {
    test('Learn resolves to structured Study Content with exact IDs', () {
      final target = launcher.resolve(
        _block(
          StudyPlanBlockType.learn,
          topicId: 'd04_c01_t02',
          subtopicId: 'd04_c01_t02_s03',
        ),
      );

      expect(target.kind, StudyPlanExecutionTargetKind.studyContent);
      expect(target.domainId, 'd04');
      expect(target.domainNumber, 4);
      expect(target.competencyId, 'd04_c01');
      expect(target.topicId, 'd04_c01_t02');
      expect(target.subtopicId, 'd04_c01_t02_s03');
      expect(target.plannedMinutes, 15);
    });

    test('missing optional hierarchy IDs are not invented', () {
      final target = launcher.resolve(_block(StudyPlanBlockType.repair));

      expect(target.kind, StudyPlanExecutionTargetKind.studyContent);
      expect(target.topicId, isNull);
      expect(target.subtopicId, isNull);
    });

    test('Practice preserves planned question count and duration', () {
      final target = launcher.resolve(
        _block(
          StudyPlanBlockType.standardPractice,
          questionCount: 7,
          plannedMinutes: 18,
        ),
      );

      expect(target.kind, StudyPlanExecutionTargetKind.practiceSession);
      expect(target.questionCount, 7);
      expect(target.plannedMinutes, 18);
      expect(target.competencyId, 'd04_c01');
    });

    test('Exam simulation receives its own execution target family', () {
      final target = launcher.resolve(
        _block(StudyPlanBlockType.examSimulation, questionCount: 10),
      );

      expect(target.kind, StudyPlanExecutionTargetKind.examSimulation);
    });

    test('Remember resolves to real review content and not Flashcards', () {
      final target = launcher.resolve(
        _block(
          StudyPlanBlockType.spacedReview,
          reasonCodes: const <String>['RETENTION_DUE'],
        ),
      );

      expect(target.kind, StudyPlanExecutionTargetKind.review);
      expect(target.competencyId, 'd04_c01');
    });

    test('review-oriented recovery follows shared category policy', () {
      final target = launcher.resolve(
        _block(
          StudyPlanBlockType.recovery,
          reasonCodes: const <String>['RETENTION_DUE'],
        ),
      );

      expect(target.kind, StudyPlanExecutionTargetKind.review);
    });

    test('ambiguous recovery fails closed', () {
      expect(
        () => launcher.resolve(
          _block(
            StudyPlanBlockType.recovery,
            reasonCodes: const <String>['ASSESSMENT_BALANCE'],
          ),
        ),
        throwsStateError,
      );
    });

    test('invalid curriculum targets fail closed', () {
      expect(
        () => launcher.resolve(
          _block(
            StudyPlanBlockType.learn,
            domainId: 'd99',
            competencyId: 'd99_c01',
          ),
        ),
        throwsStateError,
      );
    });

    test('practice without question count fails closed', () {
      expect(
        () => launcher.resolve(
          _block(StudyPlanBlockType.standardPractice, questionCount: 0),
        ),
        throwsStateError,
      );
    });
  });
}

StudyPlanBlock _block(
  StudyPlanBlockType type, {
  String domainId = 'd04',
  String competencyId = 'd04_c01',
  String topicId = '',
  String subtopicId = '',
  int plannedMinutes = 15,
  int? questionCount,
  List<String> reasonCodes = const <String>['TEST_REASON'],
}) {
  final resolvedQuestionCount = questionCount ??
      switch (type) {
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
    blockId: 'home-r6-${type.name}',
    type: type,
    domainId: domainId,
    competencyId: competencyId,
    subtopicId: subtopicId,
    topicId: topicId,
    plannedMinutes: plannedMinutes,
    questionCount: resolvedQuestionCount,
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
    reasonText: 'HOME-R6 launcher test block.',
    status: StudyPlanBlockStatus.planned,
    createdAt: DateTime(2026, 9, 22),
    manualChanges: const <StudyPlanManualChange>[],
  );
}
