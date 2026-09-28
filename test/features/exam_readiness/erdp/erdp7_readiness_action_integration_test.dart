import 'package:exam_platform/features/exam_readiness/models/competency_readiness_profile.dart';
import 'package:exam_platform/features/exam_readiness/models/daily_study_plan.dart';
import 'package:exam_platform/features/exam_readiness/models/evidence_confidence.dart';
import 'package:exam_platform/features/exam_readiness/models/readiness_intelligence_snapshot.dart';
import 'package:exam_platform/features/exam_readiness/models/study_plan_block.dart';
import 'package:exam_platform/features/exam_readiness/models/study_plan_block_outcome.dart';
import 'package:exam_platform/features/exam_readiness/models/study_plan_execution_target.dart';
import 'package:exam_platform/features/exam_readiness/navigation/study_plan_block_launcher.dart';
import 'package:exam_platform/features/exam_readiness/services/learning_evidence_normalizer.dart';
import 'package:exam_platform/features/exam_readiness/services/phase_aware_daily_plan_service.dart';
import 'package:exam_platform/features/exam_readiness/services/readiness_action_integration_service.dart';
import 'package:exam_platform/features/exam_readiness/services/readiness_intelligence_service.dart';
import 'package:exam_platform/features/exam_readiness/services/today_plan_task_category_policy.dart';
import 'package:flutter_test/flutter_test.dart';

import '../m7d/_support/m7d_fixture.dart';

StudyPlanBlock _block({
  required String id,
  required StudyPlanBlockType type,
  String competencyId = 'd01_c01',
  List<String> reasons = const <String>['ERDP7_TEST'],
  StudyPlanBlockStatus status = StudyPlanBlockStatus.planned,
}) {
  final questionCount = switch (type) {
    StudyPlanBlockType.repair ||
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
    blockId: id,
    type: type,
    domainId: 'd01',
    competencyId: competencyId,
    subtopicId: '',
    topicId: '',
    plannedMinutes: 15,
    questionCount: questionCount,
    priorityScore: 0.9,
    priorityBreakdown: m7dPriority(competencyId: competencyId),
    reasonCodes: reasons,
    reasonText: 'ERDP-7 test task.',
    status: status,
    createdAt: DateTime.utc(2026, 9, 28, 8),
    startedAt: status == StudyPlanBlockStatus.started
        ? DateTime.utc(2026, 9, 28, 9)
        : null,
    manualChanges: const <StudyPlanManualChange>[],
  );
}

DailyStudyPlan _plan(List<StudyPlanBlock> blocks) => DailyStudyPlan(
  planId: 'erdp7-plan',
  userId: 'learner-1',
  date: DateTime.utc(2026, 9, 28),
  generatedAt: DateTime.utc(2026, 9, 28, 8),
  planVersion: 1,
  plannerAlgorithmVersion: DailyStudyPlan.currentAlgorithmVersion,
  availableMinutes: 180,
  allocatedMinutes: blocks.fold(0, (sum, block) => sum + block.plannedMinutes),
  generationReason: DailyStudyPlanGenerationReason.initial,
  sourceEvidenceVersion: 'e1',
  sourceReadinessVersion: 'r1',
  blocks: blocks,
  status: DailyStudyPlanStatus.active,
  schemaVersion: DailyStudyPlan.currentSchemaVersion,
);

ReadinessIntelligenceSnapshot _readiness(ReadinessNextAction action) =>
    ReadinessIntelligenceSnapshot(
      generatedAt: DateTime.utc(2026, 9, 28),
      state: ReadinessIntelligenceState.progressing,
      overallScore: 70,
      evidenceConfidence: EvidenceConfidence.high,
      knowledge: m7dProfile().knowledgeMastery,
      application: m7dProfile().applicationAbility,
      retention: m7dProfile().retention,
      blueprintCoverage: 0.8,
      difficultyCoverage: m7dProfile().difficultyPerformance.dimension,
      recency: m7dProfile().recentPerformance,
      confidenceCalibration: m7dProfile().confidenceCalibration,
      evidenceSufficiency: 0.9,
      strongCompetencyIds: const <String>[],
      weakCompetencyIds: <String>[action.competencyId],
      evidenceGapCompetencyIds: const <String>[],
      dueFlashcards: 0,
      nextBestAction: action,
      reasonCodes: const <String>['ERDP7_TEST'],
      algorithmVersion: ReadinessIntelligenceService.currentAlgorithmVersion,
    );

ReadinessNextAction _action(
  ReadinessNextActionKind kind, {
  String competencyId = 'd01_c01',
}) => ReadinessNextAction(
  kind: kind,
  competencyId: competencyId,
  minutes: 15,
  reasonCodes: const <String>['ERDP7_TEST'],
  reasonText: 'ERDP-7 test action.',
);

void main() {
  group('ERDP-7 application LAB route', () {
    test('application-gap repair is Practice and resolves to LAB', () {
      final block = _block(
        id: 'lab-repair',
        type: StudyPlanBlockType.repair,
        reasons: const <String>['APPLICATION_GAP'],
      );

      expect(
        const TodayPlanTaskCategoryPolicy().categoryFor(block).name,
        'practice',
      );
      expect(
        const StudyPlanBlockLauncher().resolve(block).kind,
        StudyPlanExecutionTargetKind.lab,
      );
    });

    test('terminal LAB outcome normalizes to strong applied evidence', () {
      final block = _block(
        id: 'lab-evidence',
        type: StudyPlanBlockType.repair,
        reasons: const <String>['APPLICATION_GAP'],
        status: StudyPlanBlockStatus.started,
      );
      final outcome = StudyPlanBlockOutcome(
        outcomeId: 'lab-outcome',
        planId: 'erdp7-plan',
        planVersion: 1,
        blockId: block.blockId,
        competencyId: block.competencyId,
        completedAt: DateTime.utc(2026, 9, 28, 9, 20),
        minutesSpent: 20,
        questionsAttempted: 0,
        questionsCorrect: 0,
        applicationAccuracy: 0.75,
        confidenceSamples: 0,
        contentCompleted: true,
        abandoned: false,
      );

      final event = const LearningEvidenceNormalizer().fromStudyPlanOutcome(
        block: block,
        outcome: outcome,
      );

      expect(event.sourceKind.name, 'lab');
      expect(event.strength.name, 'strong');
      expect(event.applicationScore, 0.75);
    });
  });

  group('ERDP-7 one-plan action binding', () {
    test(
      'all readiness action families bind only to compatible DailyPlan blocks',
      () {
        final blocks = <StudyPlanBlock>[
          _block(id: 'diagnostic', type: StudyPlanBlockType.diagnostic),
          _block(id: 'practice', type: StudyPlanBlockType.standardPractice),
          _block(id: 'flashcards', type: StudyPlanBlockType.spacedReview),
          _block(id: 'study', type: StudyPlanBlockType.learn),
          _block(
            id: 'lab',
            type: StudyPlanBlockType.repair,
            reasons: const <String>['APPLICATION_GAP'],
          ),
          _block(
            id: 'confidence',
            type: StudyPlanBlockType.confidenceCalibration,
          ),
          _block(id: 'simulation', type: StudyPlanBlockType.examSimulation),
        ];
        final plan = _plan(blocks);
        const service = ReadinessActionIntegrationService();
        final expected = <ReadinessNextActionKind, String>{
          ReadinessNextActionKind.diagnostic: 'diagnostic',
          ReadinessNextActionKind.targetedPractice: 'practice',
          ReadinessNextActionKind.flashcardReview: 'flashcards',
          ReadinessNextActionKind.studyReview: 'study',
          ReadinessNextActionKind.lab: 'lab',
          ReadinessNextActionKind.confidenceCalibration: 'confidence',
          ReadinessNextActionKind.simulation: 'simulation',
        };

        for (final entry in expected.entries) {
          final binding = service.bind(
            readiness: _readiness(_action(entry.key)),
            plan: plan,
          );
          expect(binding.requiresReplan, isFalse, reason: entry.key.name);
          expect(binding.block?.blockId, entry.value, reason: entry.key.name);
        }
      },
    );

    test('missing action target requests authoritative replanning', () {
      const service = ReadinessActionIntegrationService();
      final binding = service.bind(
        readiness: _readiness(_action(ReadinessNextActionKind.lab)),
        plan: _plan(<StudyPlanBlock>[
          _block(id: 'study-only', type: StudyPlanBlockType.learn),
        ]),
      );

      expect(binding.block, isNull);
      expect(binding.requiresReplan, isTrue);
      expect(binding.reasonCode, 'ERDP7_AUTHORITATIVE_PLAN_REPLAN_REQUIRED');
    });

    test(
      'started compatible block wins so readiness resumes rather than duplicates',
      () {
        const service = ReadinessActionIntegrationService();
        final binding = service.bind(
          readiness: _readiness(
            _action(ReadinessNextActionKind.targetedPractice),
          ),
          plan: _plan(<StudyPlanBlock>[
            _block(id: 'planned', type: StudyPlanBlockType.standardPractice),
            _block(
              id: 'started',
              type: StudyPlanBlockType.mixedRetrieval,
              status: StudyPlanBlockStatus.started,
            ),
          ]),
        );

        expect(binding.block?.blockId, 'started');
        expect(binding.reasonCode, 'ERDP7_RESUME_AUTHORITATIVE_PLAN_BLOCK');
      },
    );
  });

  test('near-exam phase turns assessment-balance practice into Simulation', () {
    final profiles = <String, CompetencyReadinessProfile>{};
    for (var domain = 1; domain <= 7; domain++) {
      for (var competency = 1; competency <= 20; competency++) {
        final id =
            'd${domain.toString().padLeft(2, '0')}_c${competency.toString().padLeft(2, '0')}';
        profiles[id] = m7dProfile(
          competencyId: id,
          readinessState: ReadinessState.stable,
          evidenceConfidence: EvidenceConfidence.veryHigh,
          knowledge: 0.9,
          application: 0.9,
          retention: 0.9,
          coverage: 0.95,
          difficulty: 0.85,
          calibration: 0.9,
        );
      }
    }

    final date = DateTime(2026, 9, 28);
    final plan = const PhaseAwareDailyPlanService().generate(
      userId: 'erdp7-user',
      date: date,
      generatedAt: date,
      examDate: DateTime(2026, 10, 5),
      availableMinutes: 120,
      readinessProfiles: profiles,
    );

    expect(
      plan.blocks.any(
        (block) => block.type == StudyPlanBlockType.examSimulation,
      ),
      isTrue,
    );
  });
}
