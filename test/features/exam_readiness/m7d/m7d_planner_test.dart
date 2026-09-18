import 'package:exam_platform/data/csp11_blueprint.dart';
import 'package:exam_platform/features/exam_readiness/models/competency_readiness_profile.dart';
import 'package:exam_platform/features/exam_readiness/models/daily_study_plan.dart';
import 'package:exam_platform/features/exam_readiness/models/evidence_confidence.dart';
import 'package:exam_platform/features/exam_readiness/models/readiness_gap.dart';
import 'package:exam_platform/features/exam_readiness/models/study_plan_block.dart';
import 'package:exam_platform/features/exam_readiness/services/daily_study_plan_service.dart';
import 'package:exam_platform/features/exam_readiness/services/planner_constraints.dart';
import 'package:flutter_test/flutter_test.dart';

import '_support/m7d_fixture.dart';

Map<String, CompetencyReadinessProfile> stableProfiles({
  String? overrideId,
  CompetencyReadinessProfile? overrideProfile,
}) {
  final result = <String, CompetencyReadinessProfile>{};
  for (final domain in csp11Domains) {
    for (final competency in domain.competencies) {
      result[competency.id] = m7dProfile(
        competencyId: competency.id,
        evidenceConfidence: EvidenceConfidence.veryHigh,
        readinessState: ReadinessState.stable,
        knowledge: 0.92,
        application: 0.90,
        retention: 0.90,
        coverage: 0.95,
        difficulty: 0.88,
        calibration: 0.92,
        hardAccuracy: 0.88,
        ultraHardAccuracy: 0.82,
      );
    }
  }
  if (overrideId != null && overrideProfile != null) {
    result[overrideId] = overrideProfile;
  }
  return result;
}

DailyStudyPlan generate({
  int minutes = 60,
  int daysToExam = 60,
  Map<String, CompetencyReadinessProfile>? profiles,
  Set<String> ultra = const <String>{},
  Set<String> recent = const <String>{},
  DailyStudyPlan? existing,
  DailyStudyPlanService service = const DailyStudyPlanService(),
}) {
  final date = DateTime(2026, 9, 18);
  return service.generate(
    userId: 'u1',
    date: date,
    generatedAt: DateTime(2026, 9, 18, 8),
    examDate: date.add(Duration(days: daysToExam)),
    availableMinutes: minutes,
    readinessProfiles: profiles ?? stableProfiles(),
    ultraHardAvailableCompetencyIds: ultra,
    recentlyStudiedCompetencyIds: recent,
    existingPlan: existing,
    generationReason: existing == null
        ? DailyStudyPlanGenerationReason.initial
        : DailyStudyPlanGenerationReason.manualRequest,
  );
}

void main() {
  group('M7D planner capacity invariants', () {
    test('30-minute day never exceeds capacity', () {
      final plan = generate(minutes: 30);
      expect(plan.allocatedMinutes, lessThanOrEqualTo(30));
    });

    test('60-minute day never exceeds capacity', () {
      final plan = generate(minutes: 60);
      expect(plan.allocatedMinutes, lessThanOrEqualTo(60));
    });

    test('120-minute day never exceeds capacity', () {
      final plan = generate(minutes: 120);
      expect(plan.allocatedMinutes, lessThanOrEqualTo(120));
    });

    test('zero-minute day creates zero allocation', () {
      final plan = generate(minutes: 0);
      expect(plan.allocatedMinutes, 0);
      expect(plan.blocks, isEmpty);
    });

    test('negative available minutes clamp to zero', () {
      final plan = generate(minutes: -20);
      expect(plan.availableMinutes, 0);
      expect(plan.blocks, isEmpty);
    });

    test('available minutes are capped at one day', () {
      final plan = generate(minutes: 2000);
      expect(plan.availableMinutes, 1440);
      expect(plan.allocatedMinutes, lessThanOrEqualTo(1440));
    });

    test('block minute sum equals allocated minutes', () {
      final plan = generate(minutes: 120);
      final sum = plan.blocks.fold<int>(
        0,
        (value, block) => value + block.plannedMinutes,
      );
      expect(sum, plan.allocatedMinutes);
    });

    test('every generated block has positive minutes', () {
      final plan = generate(minutes: 120);
      expect(plan.blocks.every((block) => block.plannedMinutes > 0), isTrue);
    });

    test('every generated block has reason codes', () {
      final plan = generate(minutes: 120);
      expect(plan.blocks.every((block) => block.reasonCodes.isNotEmpty), isTrue);
    });

    test('every generated block has reason text', () {
      final plan = generate(minutes: 120);
      expect(
        plan.blocks.every((block) => block.reasonText.trim().isNotEmpty),
        isTrue,
      );
    });

    test('generated block IDs are unique', () {
      final plan = generate(minutes: 120);
      expect(
        plan.blocks.map((block) => block.blockId).toSet().length,
        plan.blocks.length,
      );
    });

    test('planner respects maximum competencies per day', () {
      final plan = generate(minutes: 120);
      expect(
        plan.blocks.map((block) => block.competencyId).toSet().length,
        lessThanOrEqualTo(3),
      );
    });

    test('planner respects maximum blocks per day', () {
      final plan = generate(minutes: 500);
      expect(plan.blocks.length, lessThanOrEqualTo(6));
    });

    test('planner emits versioned source metadata', () {
      final plan = generate(minutes: 60);
      expect(plan.sourceReadinessVersion, contains('m7c-v1'));
      expect(plan.sourceEvidenceVersion, isNotEmpty);
    });

    test('planner algorithm version is M7D version', () {
      expect(generate().plannerAlgorithmVersion, 'm7d-v1');
    });
  });

  group('M7D diagnostic versus repair safety', () {
    test('new learner receives diagnostic not repair', () {
      final plan = generate(minutes: 60, profiles: const {});
      expect(
        plan.blocks.any((block) => block.type == StudyPlanBlockType.diagnostic),
        isTrue,
      );
      expect(
        plan.blocks.any((block) => block.type == StudyPlanBlockType.repair),
        isFalse,
      );
    });

    test('low evidence profile receives diagnostic', () {
      final weak = m7dProfile(
        competencyId: 'd01_c01',
        evidenceConfidence: EvidenceConfidence.low,
        readinessState: ReadinessState.insufficientEvidence,
        application: 0.2,
        gaps: [
          m7dGap(
            competencyId: 'd01_c01',
            type: ReadinessGapType.applicationGap,
            reasonCode: 'APPLICATION_GAP',
          ),
        ],
      );
      final plan = generate(
        minutes: 60,
        profiles: stableProfiles(
          overrideId: 'd01_c01',
          overrideProfile: weak,
        ),
      );
      final blocks = plan.blocks.where(
        (block) => block.competencyId == 'd01_c01',
      );
      expect(
        blocks.any((block) => block.type == StudyPlanBlockType.diagnostic),
        isTrue,
      );
      expect(
        blocks.any((block) => block.type == StudyPlanBlockType.repair),
        isFalse,
      );
    });

    test('high evidence performance gap can receive repair', () {
      final weak = m7dProfile(
        competencyId: 'd01_c01',
        evidenceConfidence: EvidenceConfidence.high,
        readinessState: ReadinessState.atRisk,
        application: 0.2,
        gaps: [
          m7dGap(
            competencyId: 'd01_c01',
            type: ReadinessGapType.applicationGap,
            reasonCode: 'APPLICATION_GAP',
            evidenceLimited: false,
          ),
        ],
      );
      final plan = generate(
        minutes: 60,
        profiles: stableProfiles(
          overrideId: 'd01_c01',
          overrideProfile: weak,
        ),
      );
      expect(
        plan.blocks.any(
          (block) =>
              block.competencyId == 'd01_c01' &&
              block.type == StudyPlanBlockType.repair,
        ),
        isTrue,
      );
    });

    test('evidence-limited gap does not force repair', () {
      final uncertain = m7dProfile(
        competencyId: 'd01_c01',
        evidenceConfidence: EvidenceConfidence.low,
        readinessState: ReadinessState.insufficientEvidence,
        gaps: [
          m7dGap(
            competencyId: 'd01_c01',
            type: ReadinessGapType.applicationGap,
            reasonCode: 'APPLICATION_EVIDENCE_MISSING',
            evidenceLimited: true,
          ),
        ],
      );
      final plan = generate(
        profiles: stableProfiles(
          overrideId: 'd01_c01',
          overrideProfile: uncertain,
        ),
      );
      expect(
        plan.blocks.where(
          (block) =>
              block.competencyId == 'd01_c01' &&
              block.type == StudyPlanBlockType.repair,
        ),
        isEmpty,
      );
    });

    test('stale profile receives competency recheck', () {
      final stale = m7dProfile(
        competencyId: 'd01_c01',
        readinessState: ReadinessState.stale,
        gaps: [
          m7dGap(
            competencyId: 'd01_c01',
            type: ReadinessGapType.stalenessGap,
            reasonCode: 'STALE_EVIDENCE',
            evidenceLimited: true,
          ),
        ],
      );
      final plan = generate(
        profiles: stableProfiles(
          overrideId: 'd01_c01',
          overrideProfile: stale,
        ),
      );
      expect(
        plan.blocks.any(
          (block) =>
              block.competencyId == 'd01_c01' &&
              block.type == StudyPlanBlockType.competencyRecheck,
        ),
        isTrue,
      );
    });

    test('coverage-limited profile can receive learn block', () {
      final coverage = m7dProfile(
        competencyId: 'd01_c01',
        coverage: 0.4,
        readinessState: ReadinessState.developing,
      );
      final plan = generate(
        profiles: stableProfiles(
          overrideId: 'd01_c01',
          overrideProfile: coverage,
        ),
      );
      expect(
        plan.blocks.any(
          (block) =>
              block.competencyId == 'd01_c01' &&
              block.type == StudyPlanBlockType.learn,
        ),
        isTrue,
      );
    });

    test('strong profile can receive continue-learning block', () {
      final plan = generate(minutes: 60, profiles: stableProfiles());
      expect(
        plan.blocks.any(
          (block) => block.type == StudyPlanBlockType.continueLearning,
        ),
        isTrue,
      );
    });
  });

  group('M7D retention and balance', () {
    test('retention-heavy learner receives spaced review', () {
      final profile = m7dProfile(
        competencyId: 'd01_c01',
        retention: 0.25,
        gaps: [
          m7dGap(
            competencyId: 'd01_c01',
            type: ReadinessGapType.retentionGap,
            reasonCode: 'RETENTION_GAP',
          ),
        ],
      );
      final plan = generate(
        minutes: 120,
        profiles: stableProfiles(
          overrideId: 'd01_c01',
          overrideProfile: profile,
        ),
      );
      expect(
        plan.blocks.any(
          (block) => block.type == StudyPlanBlockType.spacedReview,
        ),
        isTrue,
      );
    });

    test('spaced review carries retention reason', () {
      final profile = m7dProfile(
        competencyId: 'd01_c01',
        gaps: [
          m7dGap(
            competencyId: 'd01_c01',
            type: ReadinessGapType.retentionGap,
            reasonCode: 'RETENTION_GAP',
          ),
        ],
      );
      final plan = generate(
        minutes: 120,
        profiles: stableProfiles(
          overrideId: 'd01_c01',
          overrideProfile: profile,
        ),
      );
      final review = plan.blocks.firstWhere(
        (block) => block.type == StudyPlanBlockType.spacedReview,
      );
      expect(review.reasonCodes, contains('RETENTION_DUE'));
    });

    test('one weak competency does not monopolize normal 120-minute day', () {
      final weak = m7dProfile(
        competencyId: 'd01_c01',
        readinessState: ReadinessState.atRisk,
        application: 0.1,
        gaps: [
          m7dGap(
            competencyId: 'd01_c01',
            type: ReadinessGapType.applicationGap,
            severity: ReadinessGapSeverity.critical,
          ),
        ],
      );
      final plan = generate(
        minutes: 120,
        profiles: stableProfiles(
          overrideId: 'd01_c01',
          overrideProfile: weak,
        ),
      );
      expect(
        plan.blocks.map((block) => block.competencyId).toSet().length,
        greaterThan(1),
      );
    });

    test('recent-study penalty can move a competency down the plan', () {
      final normal = generate(
        minutes: 60,
        profiles: stableProfiles(),
      );
      final recent = generate(
        minutes: 60,
        profiles: stableProfiles(),
        recent: {normal.blocks.first.competencyId},
      );
      expect(
        recent.blocks.first.competencyId,
        isNot(normal.blocks.first.competencyId),
      );
    });
  });

  group('M7D exam proximity', () {
    test('exam tomorrow plan contains exam proximity reason', () {
      final plan = generate(minutes: 60, daysToExam: 1);
      expect(
        plan.blocks.any(
          (block) => block.reasonCodes.contains('EXAM_PROXIMITY'),
        ),
        isTrue,
      );
    });

    test('exam 90 days away does not force exam proximity reason', () {
      final plan = generate(minutes: 60, daysToExam: 90);
      expect(
        plan.blocks.every(
          (block) => !block.reasonCodes.contains('EXAM_PROXIMITY'),
        ),
        isTrue,
      );
    });
  });

  group('M7D Ultra Hard scheduling', () {
    test('Ultra Hard unavailable never creates Ultra Hard block', () {
      final profile = m7dProfile(
        competencyId: 'd01_c01',
        ultraHardAccuracy: null,
      );
      final plan = generate(
        minutes: 120,
        profiles: stableProfiles(
          overrideId: 'd01_c01',
          overrideProfile: profile,
        ),
        ultra: const {},
      );
      expect(
        plan.blocks.any(
          (block) => block.type == StudyPlanBlockType.ultraHardPractice,
        ),
        isFalse,
      );
    });

    test('available Ultra Hard can generate Ultra Hard block', () {
      final profile = m7dProfile(
        competencyId: 'd01_c01',
        ultraHardAccuracy: null,
        application: 0.65,
      );
      final plan = generate(
        minutes: 120,
        profiles: stableProfiles(
          overrideId: 'd01_c01',
          overrideProfile: profile,
        ),
        ultra: const {'d01_c01'},
      );
      expect(
        plan.blocks.any(
          (block) =>
              block.competencyId == 'd01_c01' &&
              block.type == StudyPlanBlockType.ultraHardPractice,
        ),
        isTrue,
      );
    });

    test('Ultra Hard block carries Ultra Hard gap reason', () {
      final profile = m7dProfile(
        competencyId: 'd01_c01',
        ultraHardAccuracy: null,
        application: 0.65,
      );
      final plan = generate(
        minutes: 120,
        profiles: stableProfiles(
          overrideId: 'd01_c01',
          overrideProfile: profile,
        ),
        ultra: const {'d01_c01'},
      );
      final block = plan.blocks.firstWhere(
        (item) => item.type == StudyPlanBlockType.ultraHardPractice,
      );
      expect(block.reasonCodes, contains('ULTRA_HARD_GAP'));
    });

    test('strong Ultra Hard performance need not schedule Ultra Hard block', () {
      final profile = m7dProfile(
        competencyId: 'd01_c01',
        ultraHardAccuracy: 0.95,
        application: 0.95,
      );
      final plan = generate(
        minutes: 120,
        profiles: stableProfiles(
          overrideId: 'd01_c01',
          overrideProfile: profile,
        ),
        ultra: const {'d01_c01'},
      );
      expect(
        plan.blocks.where(
          (block) =>
              block.competencyId == 'd01_c01' &&
              block.type == StudyPlanBlockType.ultraHardPractice,
        ),
        isEmpty,
      );
    });
  });

  group('M7D manual controls and locking', () {
    test('start records started status and new version', () {
      const service = DailyStudyPlanService();
      final initial = generate(service: service);
      final started = service.startBlock(
        initial,
        initial.blocks.first.blockId,
        at: DateTime(2026, 9, 18, 9),
      );
      expect(started.planVersion, initial.planVersion + 1);
      expect(started.blocks.first.status, StudyPlanBlockStatus.started);
      expect(started.blocks.first.startedAt, isNotNull);
    });

    test('start records manual change', () {
      const service = DailyStudyPlanService();
      final initial = generate(service: service);
      final started = service.startBlock(
        initial,
        initial.blocks.first.blockId,
        at: DateTime(2026, 9, 18, 9),
      );
      expect(
        started.blocks.first.manualChanges.last.action,
        StudyPlanManualAction.start,
      );
    });

    test('skip records skipped status', () {
      const service = DailyStudyPlanService();
      final initial = generate(service: service);
      final changed = service.skipBlock(
        initial,
        initial.blocks.first.blockId,
        at: DateTime(2026, 9, 18, 9),
      );
      expect(changed.blocks.first.status, StudyPlanBlockStatus.skipped);
    });

    test('move to tomorrow records state', () {
      const service = DailyStudyPlanService();
      final initial = generate(service: service);
      final changed = service.moveToTomorrow(
        initial,
        initial.blocks.first.blockId,
        at: DateTime(2026, 9, 18, 9),
      );
      expect(
        changed.blocks.first.status,
        StudyPlanBlockStatus.movedToTomorrow,
      );
    });

    test('mark unavailable records state', () {
      const service = DailyStudyPlanService();
      final initial = generate(service: service);
      final changed = service.markUnavailable(
        initial,
        initial.blocks.first.blockId,
        at: DateTime(2026, 9, 18, 9),
      );
      expect(changed.blocks.first.status, StudyPlanBlockStatus.unavailable);
    });

    test('shorten reduces minutes and plan allocation', () {
      const service = DailyStudyPlanService();
      final initial = generate(minutes: 60, service: service);
      final first = initial.blocks.first;
      final target = (first.plannedMinutes - 5).clamp(5, first.plannedMinutes);
      final changed = service.shortenBlock(
        initial,
        first.blockId,
        newMinutes: target.toInt(),
        at: DateTime(2026, 9, 18, 9),
      );
      expect(changed.allocatedMinutes, lessThan(initial.allocatedMinutes));
    });

    test('shorten cannot increase minutes', () {
      const service = DailyStudyPlanService();
      final initial = generate(service: service);
      final first = initial.blocks.first;
      expect(
        () => service.shortenBlock(
          initial,
          first.blockId,
          newMinutes: first.plannedMinutes + 5,
          at: DateTime(2026, 9, 18, 9),
        ),
        throwsStateError,
      );
    });

    test('shorten cannot go below five minutes', () {
      const service = DailyStudyPlanService();
      final initial = generate(service: service);
      expect(
        () => service.shortenBlock(
          initial,
          initial.blocks.first.blockId,
          newMinutes: 4,
          at: DateTime(2026, 9, 18, 9),
        ),
        throwsArgumentError,
      );
    });

    test('replace creates a new block ID', () {
      const service = DailyStudyPlanService();
      final initial = generate(service: service);
      final oldId = initial.blocks.first.blockId;
      final changed = service.replaceWithAlternative(
        initial,
        oldId,
        at: DateTime(2026, 9, 18, 9),
      );
      expect(changed.blocks.first.blockId, isNot(oldId));
    });

    test('replace records manual reason', () {
      const service = DailyStudyPlanService();
      final initial = generate(service: service);
      final changed = service.replaceWithAlternative(
        initial,
        initial.blocks.first.blockId,
        at: DateTime(2026, 9, 18, 9),
      );
      expect(changed.blocks.first.reasonCodes, contains('LEARNER_REPLACED'));
    });

    test('started block cannot be skipped', () {
      const service = DailyStudyPlanService();
      final initial = generate(service: service);
      final started = service.startBlock(
        initial,
        initial.blocks.first.blockId,
        at: DateTime(2026, 9, 18, 9),
      );
      expect(
        () => service.skipBlock(
          started,
          started.blocks.first.blockId,
          at: DateTime(2026, 9, 18, 10),
        ),
        throwsStateError,
      );
    });

    test('started block cannot be replaced', () {
      const service = DailyStudyPlanService();
      final initial = generate(service: service);
      final started = service.startBlock(
        initial,
        initial.blocks.first.blockId,
        at: DateTime(2026, 9, 18, 9),
      );
      expect(
        () => service.replaceWithAlternative(
          started,
          started.blocks.first.blockId,
          at: DateTime(2026, 9, 18, 10),
        ),
        throwsStateError,
      );
    });

    test('regeneration preserves started block exactly', () {
      const service = DailyStudyPlanService();
      final initial = generate(minutes: 120, service: service);
      final started = service.startBlock(
        initial,
        initial.blocks.first.blockId,
        at: DateTime(2026, 9, 18, 9),
      );
      final regenerated = generate(
        minutes: 120,
        profiles: stableProfiles(),
        existing: started,
        service: service,
      );
      final retained = regenerated.blocks.firstWhere(
        (block) => block.blockId == started.blocks.first.blockId,
      );
      expect(retained.toJson(), started.blocks.first.toJson());
    });

    test('regeneration increments plan version', () {
      const service = DailyStudyPlanService();
      final initial = generate(minutes: 120, service: service);
      final regenerated = generate(
        minutes: 120,
        existing: initial,
        service: service,
      );
      expect(regenerated.planVersion, initial.planVersion + 1);
    });

    test('locked minutes above new capacity block regeneration', () {
      const service = DailyStudyPlanService();
      final initial = generate(minutes: 120, service: service);
      final started = service.startBlock(
        initial,
        initial.blocks.first.blockId,
        at: DateTime(2026, 9, 18, 9),
      );
      expect(
        () => generate(
          minutes: 5,
          existing: started,
          service: service,
        ),
        throwsStateError,
      );
    });

    test('unknown block ID cannot be manually changed', () {
      const service = DailyStudyPlanService();
      final initial = generate(service: service);
      expect(
        () => service.skipBlock(
          initial,
          'missing',
          at: DateTime(2026, 9, 18, 9),
        ),
        throwsStateError,
      );
    });
  });

  group('M7D centralized constraints', () {
    test('default constraints validate', () {
      expect(
        () => const DailyPlannerConstraints().validate(),
        returnsNormally,
      );
    });

    test('invalid share sum is rejected', () {
      expect(
        () => const DailyPlannerConstraints(
          forwardLearningShare: 0.5,
        ).validate(),
        throwsStateError,
      );
    });

    test('invalid minimum over maximum is rejected', () {
      expect(
        () => const DailyPlannerConstraints(
          learnMinMinutes: 31,
          learnMaxMinutes: 30,
        ).validate(),
        throwsStateError,
      );
    });

    test('zero max competencies is rejected', () {
      expect(
        () => const DailyPlannerConstraints(
          maxCompetenciesPerDay: 0,
        ).validate(),
        throwsStateError,
      );
    });

    test('custom maximum competencies is honored', () {
      const service = DailyStudyPlanService(
        constraints: DailyPlannerConstraints(
          maxCompetenciesPerDay: 1,
        ),
      );
      final plan = generate(minutes: 60, service: service);
      expect(
        plan.blocks.map((block) => block.competencyId).toSet().length,
        1,
      );
    });
  });
}
