import 'package:exam_platform/features/exam_readiness/models/daily_study_plan.dart';
import 'package:exam_platform/features/exam_readiness/models/learning_priority_score.dart';
import 'package:exam_platform/features/exam_readiness/models/study_plan_block.dart';
import 'package:flutter_test/flutter_test.dart';

import '_support/m7d_fixture.dart';

StudyPlanBlock block({
  String id = 'b1',
  int minutes = 15,
  StudyPlanBlockType type = StudyPlanBlockType.standardPractice,
  StudyPlanBlockStatus status = StudyPlanBlockStatus.planned,
  List<String> reasons = const ['HIGH_BLUEPRINT_PRIORITY'],
  DateTime? startedAt,
  DateTime? completedAt,
}) {
  return StudyPlanBlock(
    blockId: id,
    type: type,
    domainId: 'd03',
    competencyId: 'd03_c02',
    subtopicId: '',
    topicId: '',
    plannedMinutes: minutes,
    questionCount: 5,
    priorityScore: 0.75,
    priorityBreakdown: m7dPriority(),
    reasonCodes: reasons,
    reasonText: 'D03 C02 is scheduled for a clear reason.',
    status: status,
    createdAt: DateTime(2026, 9, 18, 8),
    startedAt: startedAt,
    completedAt: completedAt,
    manualChanges: const [],
  );
}

DailyStudyPlan plan({
  int available = 60,
  int? allocated,
  int version = 1,
  List<StudyPlanBlock>? blocks,
}) {
  final values = blocks ?? [block(minutes: 15), block(id: 'b2', minutes: 10)];
  final minutes =
      allocated ?? values.fold<int>(0, (sum, item) => sum + item.plannedMinutes);
  return DailyStudyPlan(
    planId: 'm7d-u1-20260918',
    userId: 'u1',
    date: DateTime(2026, 9, 18),
    generatedAt: DateTime(2026, 9, 18, 8),
    planVersion: version,
    plannerAlgorithmVersion: DailyStudyPlan.currentAlgorithmVersion,
    availableMinutes: available,
    allocatedMinutes: minutes,
    generationReason: DailyStudyPlanGenerationReason.initial,
    sourceEvidenceVersion: 'ev1',
    sourceReadinessVersion: 'm7c-v1',
    blocks: values,
    status: DailyStudyPlanStatus.active,
    schemaVersion: DailyStudyPlan.currentSchemaVersion,
  );
}

void main() {
  group('M7D LearningPriorityScore model', () {
    test('components include blueprint importance', () {
      expect(m7dPriority().components['blueprintImportance'], 0.6);
    });

    test('components include recent study penalty', () {
      expect(m7dPriority().components, contains('recentStudyPenalty'));
    });

    test('priority score round trips through JSON', () {
      final original = m7dPriority(totalScore: 0.81);
      final decoded = LearningPriorityScore.fromJson(original.toJson());
      expect(decoded.competencyId, original.competencyId);
      expect(decoded.totalScore, original.totalScore);
      expect(decoded.reasonCodes, original.reasonCodes);
    });

    test('priority total clamps high values from JSON', () {
      final json = m7dPriority().toJson()..['totalScore'] = 4;
      expect(LearningPriorityScore.fromJson(json).totalScore, 1);
    });

    test('priority total clamps negative values from JSON', () {
      final json = m7dPriority().toJson()..['totalScore'] = -2;
      expect(LearningPriorityScore.fromJson(json).totalScore, 0);
    });

    test('unknown evidence debt level falls back to none', () {
      final json = m7dPriority().toJson()..['evidenceDebtLevel'] = 'mystery';
      expect(
        LearningPriorityScore.fromJson(json).evidenceDebtLevel,
        EvidenceDebtLevel.none,
      );
    });

    test('evidence debt assessment round trips', () {
      const original = EvidenceDebtAssessment(
        level: EvidenceDebtLevel.high,
        score: 0.8,
        reasonCodes: ['EVIDENCE_DEBT'],
      );
      final decoded = EvidenceDebtAssessment.fromJson(original.toJson());
      expect(decoded.level, EvidenceDebtLevel.high);
      expect(decoded.score, 0.8);
      expect(decoded.reasonCodes, ['EVIDENCE_DEBT']);
    });
  });

  group('M7D StudyPlanBlock model', () {
    test('planned block is not locked', () {
      expect(block().isLocked, isFalse);
    });

    test('started block is locked', () {
      expect(
        block(status: StudyPlanBlockStatus.started).isLocked,
        isTrue,
      );
    });

    test('completed block is locked', () {
      expect(
        block(status: StudyPlanBlockStatus.completed).isLocked,
        isTrue,
      );
    });

    test('skipped block remains editable history state', () {
      expect(
        block(status: StudyPlanBlockStatus.skipped).isFutureEditable,
        isTrue,
      );
    });

    test('block round trips through JSON', () {
      final original = block();
      final decoded = StudyPlanBlock.fromJson(original.toJson());
      expect(decoded.blockId, original.blockId);
      expect(decoded.type, original.type);
      expect(decoded.plannedMinutes, original.plannedMinutes);
      expect(decoded.reasonCodes, original.reasonCodes);
    });

    test('block preserves started timestamp through JSON', () {
      final at = DateTime(2026, 9, 18, 9);
      final decoded = StudyPlanBlock.fromJson(
        block(
          status: StudyPlanBlockStatus.started,
          startedAt: at,
        ).toJson(),
      );
      expect(decoded.startedAt, at);
    });

    test('block preserves completed timestamp through JSON', () {
      final at = DateTime(2026, 9, 18, 10);
      final decoded = StudyPlanBlock.fromJson(
        block(
          status: StudyPlanBlockStatus.completed,
          completedAt: at,
        ).toJson(),
      );
      expect(decoded.completedAt, at);
    });

    test('unknown block type falls back to recovery', () {
      final json = block().toJson()..['type'] = 'mystery';
      expect(
        StudyPlanBlock.fromJson(json).type,
        StudyPlanBlockType.recovery,
      );
    });

    test('unknown block status falls back to planned', () {
      final json = block().toJson()..['status'] = 'mystery';
      expect(
        StudyPlanBlock.fromJson(json).status,
        StudyPlanBlockStatus.planned,
      );
    });

    test('invalid createdAt is rejected', () {
      final json = block().toJson()..['createdAt'] = 'broken';
      expect(() => StudyPlanBlock.fromJson(json), throwsFormatException);
    });

    test('copyWith can shorten minutes', () {
      expect(block(minutes: 20).copyWith(plannedMinutes: 10).plannedMinutes, 10);
    });

    test('copyWith can add manual changes', () {
      final changed = block().copyWith(
        manualChanges: [
          StudyPlanManualChange(
            action: StudyPlanManualAction.skip,
            changedAt: DateTime(2026, 9, 18),
            note: 'skip',
          ),
        ],
      );
      expect(changed.manualChanges, hasLength(1));
    });

    test('manual change round trips', () {
      final original = StudyPlanManualChange(
        action: StudyPlanManualAction.shorten,
        changedAt: DateTime(2026, 9, 18),
        note: 'shortened',
        previousMinutes: 20,
        newMinutes: 10,
      );
      final decoded = StudyPlanManualChange.fromJson(original.toJson());
      expect(decoded.action, StudyPlanManualAction.shorten);
      expect(decoded.previousMinutes, 20);
      expect(decoded.newMinutes, 10);
    });

    test('invalid manual change timestamp is rejected', () {
      expect(
        () => StudyPlanManualChange.fromJson({
          'action': 'skip',
          'changedAt': 'bad',
        }),
        throwsFormatException,
      );
    });
  });

  group('M7D DailyStudyPlan model', () {
    test('valid plan validates', () {
      expect(() => plan().validate(), returnsNormally);
    });

    test('allocated minutes cannot exceed available minutes', () {
      expect(
        () => plan(available: 20, allocated: 25).validate(),
        throwsStateError,
      );
    });

    test('negative available minutes are rejected', () {
      expect(
        () => plan(available: -1).validate(),
        throwsStateError,
      );
    });

    test('duplicate block IDs are rejected', () {
      final duplicate = [block(id: 'same'), block(id: 'same')];
      expect(
        () => plan(blocks: duplicate).validate(),
        throwsStateError,
      );
    });

    test('empty reason codes are rejected', () {
      expect(
        () => plan(blocks: [block(reasons: const [])]).validate(),
        throwsStateError,
      );
    });

    test('zero-minute block is rejected', () {
      expect(
        () => plan(blocks: [block(minutes: 0)]).validate(),
        throwsStateError,
      );
    });

    test('allocated sum mismatch is rejected', () {
      expect(
        () => plan(allocated: 50).validate(),
        throwsStateError,
      );
    });

    test('plan round trips through JSON', () {
      final original = plan();
      final decoded = DailyStudyPlan.fromJson(original.toJson());
      expect(decoded.planId, original.planId);
      expect(decoded.planVersion, original.planVersion);
      expect(decoded.blocks, hasLength(2));
    });

    test('invalid plan date is rejected', () {
      final json = plan().toJson()..['date'] = 'bad';
      expect(() => DailyStudyPlan.fromJson(json), throwsFormatException);
    });

    test('invalid generated timestamp is rejected', () {
      final json = plan().toJson()..['generatedAt'] = 'bad';
      expect(() => DailyStudyPlan.fromJson(json), throwsFormatException);
    });

    test('unknown generation reason falls back to initial', () {
      final json = plan().toJson()..['generationReason'] = 'mystery';
      expect(
        DailyStudyPlan.fromJson(json).generationReason,
        DailyStudyPlanGenerationReason.initial,
      );
    });

    test('unknown plan status falls back to active', () {
      final json = plan().toJson()..['status'] = 'mystery';
      expect(DailyStudyPlan.fromJson(json).status, DailyStudyPlanStatus.active);
    });

    test('hasStartedBlock detects started block', () {
      expect(
        plan(
          blocks: [
            block(
              status: StudyPlanBlockStatus.started,
              startedAt: DateTime(2026, 9, 18, 9),
            ),
          ],
        ).hasStartedBlock,
        isTrue,
      );
    });

    test('hasStartedBlock false for planned blocks', () {
      expect(plan().hasStartedBlock, isFalse);
    });

    test('nextVersion increments version', () {
      final original = plan(version: 3);
      final next = original.nextVersion(
        generatedAt: DateTime(2026, 9, 18, 9),
        blocks: original.blocks,
        availableMinutes: original.availableMinutes,
        generationReason: DailyStudyPlanGenerationReason.manualRequest,
        sourceEvidenceVersion: 'ev2',
        sourceReadinessVersion: 'm7c-v1',
      );
      expect(next.planVersion, 4);
    });

    test('nextVersion recalculates allocated minutes', () {
      final original = plan(version: 1);
      final next = original.nextVersion(
        generatedAt: DateTime(2026, 9, 18, 9),
        blocks: [block(minutes: 5)],
        availableMinutes: 60,
        generationReason: DailyStudyPlanGenerationReason.manualRequest,
        sourceEvidenceVersion: 'ev2',
        sourceReadinessVersion: 'm7c-v1',
      );
      expect(next.allocatedMinutes, 5);
    });

    test('current planner algorithm is versioned', () {
      expect(DailyStudyPlan.currentAlgorithmVersion, isNotEmpty);
    });

    test('current plan schema is versioned', () {
      expect(DailyStudyPlan.currentSchemaVersion, greaterThan(0));
    });
  });
}
