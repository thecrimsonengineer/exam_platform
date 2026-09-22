import 'package:exam_platform/features/exam_readiness/models/daily_study_plan.dart';
import 'package:exam_platform/features/exam_readiness/models/learning_priority_score.dart';
import 'package:exam_platform/features/exam_readiness/models/study_plan_block.dart';
import 'package:exam_platform/screens/startup/startup_personalization_service.dart';
import 'package:exam_platform/services/student_learning_position_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StartupPersonalizationService', () {
    test('combines resume position and local daily-plan summary', () async {
      final now = DateTime(2026, 9, 22, 17, 30);
      String? positionUserId;
      String? planUserId;
      DateTime? requestedDate;

      final service = StartupPersonalizationService(
        positionLoader: (userId) async {
          positionUserId = userId;
          return StudentLearningPosition(
            domainId: 'd04',
            domainNumber: 4,
            domainTitle: 'Advanced Sciences and Math',
            competencyId: 'd04_c01',
            competencyTitle: 'Engineering and quantitative foundations',
            subtopicId: 'd04_c01_s01',
            subtopicTitle: 'Reliability and probability foundations',
            lastOpenedAt: now.subtract(const Duration(minutes: 12)),
          );
        },
        planLoader: (userId, date) async {
          planUserId = userId;
          requestedDate = date;
          return _plan(
            userId: userId,
            date: date,
            statuses: const <StudyPlanBlockStatus>[
              StudyPlanBlockStatus.planned,
              StudyPlanBlockStatus.started,
              StudyPlanBlockStatus.completed,
              StudyPlanBlockStatus.skipped,
            ],
            minutes: const <int>[20, 15, 10, 5],
          );
        },
      );

      final snapshot = await service.loadForUser(
        'learner-1',
        now: now,
      );

      expect(positionUserId, 'learner-1');
      expect(planUserId, 'learner-1');
      expect(requestedDate, now);
      expect(snapshot.resumeCode, 'D04 · C01');
      expect(
        snapshot.resumeTitle,
        'Reliability and probability foundations',
      );
      expect(snapshot.todayRemainingActivities, 2);
      expect(snapshot.todayRemainingMinutes, 35);
      expect(snapshot.todayCompletedActivities, 1);
      expect(snapshot.todayTotalActivities, 4);
      expect(snapshot.todaySummary, '2 activities · 35 min remaining');
      expect(snapshot.hasAnyData, isTrue);
    });

    test('reports a completed cached plan without inventing work', () async {
      final service = StartupPersonalizationService(
        positionLoader: (_) async => null,
        planLoader: (userId, date) async => _plan(
          userId: userId,
          date: date,
          statuses: const <StudyPlanBlockStatus>[
            StudyPlanBlockStatus.completed,
            StudyPlanBlockStatus.completed,
          ],
          minutes: const <int>[15, 20],
        ),
      );

      final snapshot = await service.loadForUser(
        'learner-2',
        now: DateTime(2026, 9, 22),
      );

      expect(snapshot.hasResume, isFalse);
      expect(snapshot.hasTodayPlan, isTrue);
      expect(snapshot.todayRemainingActivities, 0);
      expect(snapshot.todayRemainingMinutes, 0);
      expect(snapshot.todayCompletedActivities, 2);
      expect(snapshot.todaySummary, 'Today\'s plan complete');
    });

    test('fails soft when local personalization sources are unavailable', () async {
      final service = StartupPersonalizationService(
        positionLoader: (_) async => throw StateError('position unavailable'),
        planLoader: (_, _) async => throw StateError('plan unavailable'),
      );

      final snapshot = await service.loadForUser('learner-3');

      expect(snapshot.hasAnyData, isFalse);
      expect(snapshot.resumeCode, isNull);
      expect(snapshot.todaySummary, isNull);
    });

    test('does not load any source for a blank learner id', () async {
      var positionCalls = 0;
      var planCalls = 0;

      final service = StartupPersonalizationService(
        positionLoader: (_) async {
          positionCalls += 1;
          return null;
        },
        planLoader: (_, _) async {
          planCalls += 1;
          return null;
        },
      );

      final snapshot = await service.loadForUser('   ');

      expect(snapshot.hasAnyData, isFalse);
      expect(positionCalls, 0);
      expect(planCalls, 0);
    });
  });
}

DailyStudyPlan _plan({
  required String userId,
  required DateTime date,
  required List<StudyPlanBlockStatus> statuses,
  required List<int> minutes,
}) {
  final blocks = <StudyPlanBlock>[
    for (var index = 0; index < statuses.length; index++)
      StudyPlanBlock(
        blockId: 'block-$index',
        type: StudyPlanBlockType.standardPractice,
        domainId: 'd04',
        competencyId: 'd04_c01',
        subtopicId: 'd04_c01_s01',
        topicId: 'd04_c01_s01_t01',
        plannedMinutes: minutes[index],
        questionCount: 5,
        priorityScore: 0.5,
        priorityBreakdown: _priorityScore,
        reasonCodes: const <String>['TEST'],
        reasonText: 'Test plan block',
        status: statuses[index],
        createdAt: date,
        manualChanges: const <StudyPlanManualChange>[],
      ),
  ];

  return DailyStudyPlan(
    planId: 'plan-1',
    userId: userId,
    date: date,
    generatedAt: date,
    planVersion: 1,
    plannerAlgorithmVersion: DailyStudyPlan.currentAlgorithmVersion,
    availableMinutes: minutes.fold<int>(0, (sum, value) => sum + value),
    allocatedMinutes: minutes.fold<int>(0, (sum, value) => sum + value),
    generationReason: DailyStudyPlanGenerationReason.initial,
    sourceEvidenceVersion: 'e1',
    sourceReadinessVersion: 'r1',
    blocks: blocks,
    status: DailyStudyPlanStatus.active,
    schemaVersion: DailyStudyPlan.currentSchemaVersion,
  );
}

const _priorityScore = LearningPriorityScore(
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
  recentStudyPenalty: 0,
  evidenceDebtLevel: EvidenceDebtLevel.none,
  totalScore: 0.5,
  reasonCodes: <String>['TEST'],
);
