import 'package:exam_platform/features/exam_readiness/models/learner_assessment_attempt.dart';
import 'package:exam_platform/features/exam_readiness/models/learning_priority_score.dart';
import 'package:exam_platform/features/exam_readiness/models/study_plan_block.dart';
import 'package:exam_platform/features/exam_readiness/services/study_plan_completion_evidence_service.dart';
import 'package:exam_platform/models/student_learning_progress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = StudyPlanCompletionEvidenceService();
  final startedAt = DateTime(2026, 9, 22, 10);

  group('HOME-R7 completion evidence', () {
    test('planned practice requires block-scoped quiz evidence', () {
      final block = _block(
        StudyPlanBlockType.standardPractice,
        questionCount: 2,
        startedAt: startedAt,
      );
      final session =
          StudyPlanCompletionEvidenceService.sessionKindForBlock(block.blockId);

      final blocked = service.evaluate(
        block: block,
        source: StudyPlanCompletionEvidenceSource.plannedPracticeSession,
        attempts: <LearnerAssessmentAttempt>[
          _attempt(
            id: 'generic',
            questionId: 1,
            answeredAt: startedAt.add(const Duration(minutes: 2)),
            sessionKind: 'practice',
          ),
          _attempt(
            id: 'planned-1',
            questionId: 2,
            answeredAt: startedAt.add(const Duration(minutes: 3)),
            sessionKind: session,
          ),
        ],
        studyProgress: const <StudentSubtopicProgress>[],
        completedAt: startedAt.add(const Duration(minutes: 10)),
      );
      expect(blocked.eligible, isFalse);

      final allowed = service.evaluate(
        block: block,
        source: StudyPlanCompletionEvidenceSource.plannedPracticeSession,
        attempts: <LearnerAssessmentAttempt>[
          _attempt(
            id: 'planned-1',
            questionId: 1,
            answeredAt: startedAt.add(const Duration(minutes: 2)),
            sessionKind: session,
          ),
          _attempt(
            id: 'planned-2',
            questionId: 2,
            answeredAt: startedAt.add(const Duration(minutes: 3)),
            sessionKind: session,
          ),
        ],
        studyProgress: const <StudentSubtopicProgress>[],
        completedAt: startedAt.add(const Duration(minutes: 10)),
      );
      expect(allowed.eligible, isTrue);
    });

    test('duplicate question attempts do not inflate practice completion', () {
      final block = _block(
        StudyPlanBlockType.standardPractice,
        questionCount: 2,
        startedAt: startedAt,
      );
      final session =
          StudyPlanCompletionEvidenceService.sessionKindForBlock(block.blockId);

      final decision = service.evaluate(
        block: block,
        source: StudyPlanCompletionEvidenceSource.plannedPracticeSession,
        attempts: <LearnerAssessmentAttempt>[
          _attempt(
            id: 'a1',
            questionId: 1,
            answeredAt: startedAt.add(const Duration(minutes: 1)),
            sessionKind: session,
          ),
          _attempt(
            id: 'a2',
            questionId: 1,
            answeredAt: startedAt.add(const Duration(minutes: 2)),
            sessionKind: session,
          ),
        ],
        studyProgress: const <StudentSubtopicProgress>[],
        completedAt: startedAt.add(const Duration(minutes: 5)),
      );
      expect(decision.eligible, isFalse);
    });

    test('Remember requires new post-start study completion evidence', () {
      final block = _block(
        StudyPlanBlockType.spacedReview,
        startedAt: startedAt,
        reasonCodes: const <String>['RETENTION_DUE'],
      );

      final oldDecision = service.evaluate(
        block: block,
        source: StudyPlanCompletionEvidenceSource.studyContent,
        attempts: const <LearnerAssessmentAttempt>[],
        studyProgress: <StudentSubtopicProgress>[
          _progress(
            completedAt: startedAt.subtract(const Duration(minutes: 1)),
          ),
        ],
        completedAt: startedAt.add(const Duration(minutes: 10)),
      );
      expect(oldDecision.eligible, isFalse);

      final newDecision = service.evaluate(
        block: block,
        source: StudyPlanCompletionEvidenceSource.studyContent,
        attempts: const <LearnerAssessmentAttempt>[],
        studyProgress: <StudentSubtopicProgress>[
          _progress(completedAt: startedAt.add(const Duration(minutes: 5))),
        ],
        completedAt: startedAt.add(const Duration(minutes: 10)),
      );
      expect(newDecision.eligible, isTrue);
    });

    test('Remember can use a later explicit re-completion of old content', () {
      final block = _block(
        StudyPlanBlockType.spacedReview,
        startedAt: startedAt,
        reasonCodes: const <String>['RETENTION_DUE'],
      );

      final progress = StudentSubtopicProgress(
        domainId: 'd04',
        domainNumber: 4,
        domainTitle: 'Emergency Management',
        competencyId: 'd04_c01',
        competencyTitle: 'Emergency response planning',
        subtopicId: 'd04_c01_t01_s01',
        subtopicTitle: 'Review subtopic',
        studyContentId: 'content-d04-c01',
        studyContentVersion: 1,
        state: StudentLearningState.completed,
        lastOpenedAt: startedAt.add(const Duration(minutes: 4)),
        completedAt: startedAt.subtract(const Duration(days: 20)),
        lastCompletedAt: startedAt.add(const Duration(minutes: 4)),
      );

      final decision = service.evaluate(
        block: block,
        source: StudyPlanCompletionEvidenceSource.studyContent,
        attempts: const <LearnerAssessmentAttempt>[],
        studyProgress: <StudentSubtopicProgress>[progress],
        completedAt: startedAt.add(const Duration(minutes: 10)),
      );

      expect(decision.eligible, isTrue);
    });

    test('exact Remember target rejects another subtopic', () {
      final block = _block(
        StudyPlanBlockType.spacedReview,
        startedAt: startedAt,
        subtopicId: 'd04_c01_t01_s02',
        reasonCodes: const <String>['RETENTION_DUE'],
      );

      final decision = service.evaluate(
        block: block,
        source: StudyPlanCompletionEvidenceSource.studyContent,
        attempts: const <LearnerAssessmentAttempt>[],
        studyProgress: <StudentSubtopicProgress>[
          _progress(
            subtopicId: 'd04_c01_t01_s01',
            completedAt: startedAt.add(const Duration(minutes: 5)),
          ),
        ],
        completedAt: startedAt.add(const Duration(minutes: 10)),
      );
      expect(decision.eligible, isFalse);
    });

    test('explicit learner finish is allowed for Learn only', () {
      final learn = service.evaluate(
        block: _block(StudyPlanBlockType.learn, startedAt: startedAt),
        source: StudyPlanCompletionEvidenceSource.explicitLearnerFinish,
        attempts: const <LearnerAssessmentAttempt>[],
        studyProgress: const <StudentSubtopicProgress>[],
        completedAt: startedAt.add(const Duration(minutes: 10)),
      );
      expect(learn.eligible, isTrue);

      final practice = service.evaluate(
        block: _block(
          StudyPlanBlockType.standardPractice,
          questionCount: 5,
          startedAt: startedAt,
        ),
        source: StudyPlanCompletionEvidenceSource.explicitLearnerFinish,
        attempts: const <LearnerAssessmentAttempt>[],
        studyProgress: const <StudentSubtopicProgress>[],
        completedAt: startedAt.add(const Duration(minutes: 10)),
      );
      expect(practice.eligible, isFalse);
    });

    test('route-open without evidence cannot complete Remember', () {
      final decision = service.evaluate(
        block: _block(
          StudyPlanBlockType.spacedReview,
          startedAt: startedAt,
          reasonCodes: const <String>['RETENTION_DUE'],
        ),
        source: StudyPlanCompletionEvidenceSource.studyContent,
        attempts: const <LearnerAssessmentAttempt>[],
        studyProgress: const <StudentSubtopicProgress>[],
        completedAt: startedAt.add(const Duration(minutes: 3)),
      );
      expect(decision.eligible, isFalse);
    });
  });
}

StudyPlanBlock _block(
  StudyPlanBlockType type, {
  required DateTime startedAt,
  int questionCount = 0,
  String subtopicId = '',
  List<String> reasonCodes = const <String>['TEST_REASON'],
}) {
  return StudyPlanBlock(
    blockId: 'home-r7-${type.name}',
    type: type,
    domainId: 'd04',
    competencyId: 'd04_c01',
    subtopicId: subtopicId,
    topicId: '',
    plannedMinutes: 15,
    questionCount: questionCount,
    priorityScore: 0.5,
    priorityBreakdown: LearningPriorityScore(
      competencyId: 'd04_c01',
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
    reasonText: 'HOME-R7 completion test block.',
    status: StudyPlanBlockStatus.started,
    createdAt: startedAt.subtract(const Duration(hours: 1)),
    startedAt: startedAt,
    manualChanges: const <StudyPlanManualChange>[],
  );
}

LearnerAssessmentAttempt _attempt({
  required String id,
  required int questionId,
  required DateTime answeredAt,
  required String sessionKind,
}) {
  return LearnerAssessmentAttempt(
    attemptId: id,
    questionId: questionId,
    domainNumber: 4,
    competencyId: 'd04_c01',
    topicId: '',
    subtopicId: '',
    correct: true,
    answeredAt: answeredAt,
    cognitiveLevel: 'application',
    questionType: 'scenario_mcq',
    difficultyLane: AttemptDifficultyLane.hard,
    publishedAtAttempt: true,
    questionVersion: 1,
    sessionKind: sessionKind,
  );
}

StudentSubtopicProgress _progress({
  String subtopicId = 'd04_c01_t01_s01',
  required DateTime completedAt,
}) {
  return StudentSubtopicProgress(
    domainId: 'd04',
    domainNumber: 4,
    domainTitle: 'Emergency Management',
    competencyId: 'd04_c01',
    competencyTitle: 'Emergency response planning',
    subtopicId: subtopicId,
    subtopicTitle: 'Review subtopic',
    studyContentId: 'content-d04-c01',
    studyContentVersion: 1,
    state: StudentLearningState.completed,
    lastOpenedAt: completedAt,
    completedAt: completedAt,
    lastCompletedAt: completedAt,
  );
}
