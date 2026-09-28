import 'package:exam_platform/data/csp11_blueprint.dart';
import 'package:exam_platform/features/exam_readiness/models/competency_readiness_profile.dart';
import 'package:exam_platform/features/exam_readiness/models/daily_study_plan.dart';
import 'package:exam_platform/features/exam_readiness/models/evidence_confidence.dart';
import 'package:exam_platform/features/exam_readiness/models/study_plan_block.dart';
import 'package:exam_platform/features/exam_readiness/models/today_plan_task_category.dart';
import 'package:exam_platform/features/exam_readiness/services/daily_study_plan_service.dart';
import 'package:exam_platform/features/exam_readiness/services/phase_aware_daily_plan_service.dart';
import 'package:exam_platform/features/exam_readiness/services/today_plan_task_category_policy.dart';
import 'package:flutter_test/flutter_test.dart';

import '../m7d/_support/m7d_fixture.dart';

Map<String, CompetencyReadinessProfile> _stableProfiles() {
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
  return result;
}

DailyStudyPlan _generate({
  required int minutes,
  DailyStudyPlan? existing,
}) {
  const service = DailyStudyPlanService();
  final date = DateTime(2026, 9, 28);
  return service.generate(
    userId: 'erdp3-user',
    date: date,
    generatedAt: DateTime(2026, 9, 28, 8),
    examDate: date.add(const Duration(days: 45)),
    availableMinutes: minutes,
    readinessProfiles: _stableProfiles(),
    existingPlan: existing,
    generationReason: existing == null
        ? DailyStudyPlanGenerationReason.initial
        : DailyStudyPlanGenerationReason.manualRequest,
  );
}

Set<TodayPlanTaskCategory> _categories(DailyStudyPlan plan) {
  const policy = TodayPlanTaskCategoryPolicy();
  return plan.blocks.map(policy.categoryFor).toSet();
}

void main() {
  group('ERDP-3 authoritative balanced planner', () {
    test('60-minute plan contains Learn Practice and Remember', () {
      final plan = _generate(minutes: 60);

      expect(
        _categories(plan),
        containsAll(<TodayPlanTaskCategory>{
          TodayPlanTaskCategory.learn,
          TodayPlanTaskCategory.practice,
          TodayPlanTaskCategory.remember,
        }),
      );
      expect(plan.allocatedMinutes, lessThanOrEqualTo(60));
    });

    test('balanced floor is visible in plan reasons', () {
      final plan = _generate(minutes: 60);

      expect(
        plan.blocks.where(
          (block) => block.reasonCodes.contains('BALANCED_PORTFOLIO'),
        ).length,
        greaterThanOrEqualTo(3),
      );
    });

    test('phase-aware readiness plan preserves all three categories', () {
      const service = PhaseAwareDailyPlanService();
      final date = DateTime(2026, 9, 28);
      final plan = service.generate(
        userId: 'erdp3-phase-user',
        date: date,
        generatedAt: DateTime(2026, 9, 28, 8),
        examDate: date.add(const Duration(days: 7)),
        availableMinutes: 60,
        readinessProfiles: _stableProfiles(),
      );

      expect(
        _categories(plan),
        containsAll(<TodayPlanTaskCategory>{
          TodayPlanTaskCategory.learn,
          TodayPlanTaskCategory.practice,
          TodayPlanTaskCategory.remember,
        }),
      );
      expect(
        plan.blocks.where(
          (block) => block.reasonCodes.contains('BALANCED_PORTFOLIO'),
        ).length,
        greaterThanOrEqualTo(3),
      );
    });

    test('small-capacity day is never over-allocated', () {
      final plan = _generate(minutes: 20);

      expect(plan.allocatedMinutes, lessThanOrEqualTo(20));
      expect(plan.blocks.length, lessThanOrEqualTo(6));
    });

    test('locked block is preserved exactly during balanced regeneration', () {
      const service = DailyStudyPlanService();
      final initial = _generate(minutes: 120);
      final started = service.startBlock(
        initial,
        initial.blocks.first.blockId,
        at: DateTime(2026, 9, 28, 9),
      );
      final regenerated = _generate(minutes: 120, existing: started);
      final retained = regenerated.blocks.firstWhere(
        (block) => block.blockId == started.blocks.first.blockId,
      );

      expect(retained.toJson(), started.blocks.first.toJson());
      expect(regenerated.allocatedMinutes, lessThanOrEqualTo(120));
    });

    test('balanced planner never creates more than six blocks', () {
      final plan = _generate(minutes: 500);

      expect(plan.blocks.length, lessThanOrEqualTo(6));
    });

    test('generated plan remains the authoritative DailyStudyPlan type', () {
      final plan = _generate(minutes: 60);

      expect(plan.status, DailyStudyPlanStatus.active);
      expect(
        plan.blocks.every((block) => block.status == StudyPlanBlockStatus.planned),
        isTrue,
      );
    });
  });
}
