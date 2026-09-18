import 'package:exam_platform/features/exam_readiness/models/competency_readiness_profile.dart';
import 'package:exam_platform/features/exam_readiness/models/evidence_confidence.dart';
import 'package:exam_platform/features/exam_readiness/models/learning_priority_score.dart';
import 'package:exam_platform/features/exam_readiness/models/readiness_gap.dart';
import 'package:exam_platform/features/exam_readiness/services/evidence_debt_service.dart';
import 'package:exam_platform/features/exam_readiness/services/learning_priority_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import '_support/m7d_fixture.dart';

void main() {
  const debtService = EvidenceDebtService();
  const engine = LearningPriorityEngine();

  group('M7D EvidenceDebtService', () {
    test('no profile creates critical evidence debt', () {
      final result = debtService.assess(profile: null);
      expect(result.level, EvidenceDebtLevel.critical);
      expect(result.score, 1);
      expect(result.reasonCodes, contains('NO_ASSESSMENT_EVIDENCE'));
    });

    test('very low confidence creates critical debt', () {
      final result = debtService.assess(
        profile: m7dProfile(evidenceConfidence: EvidenceConfidence.veryLow),
      );
      expect(result.level, EvidenceDebtLevel.critical);
    });

    test('low confidence creates high debt', () {
      final result = debtService.assess(
        profile: m7dProfile(evidenceConfidence: EvidenceConfidence.low),
      );
      expect(
        result.level,
        anyOf(EvidenceDebtLevel.high, EvidenceDebtLevel.critical),
      );
      expect(result.reasonCodes, contains('LOW_EVIDENCE_CONFIDENCE'));
    });

    test('missing application evidence creates strong debt signal', () {
      final result = debtService.assess(profile: m7dProfile(application: null));
      expect(result.score, greaterThanOrEqualTo(0.9));
      expect(result.reasonCodes, contains('NO_APPLICATION_EVIDENCE'));
    });

    test('missing retention evidence creates retention debt reason', () {
      final result = debtService.assess(profile: m7dProfile(retention: null));
      expect(result.reasonCodes, contains('NO_DELAYED_RETENTION_EVIDENCE'));
    });

    test('missing hard evidence creates hard debt reason', () {
      final result = debtService.assess(
        profile: m7dProfile(hardAccuracy: null),
      );
      expect(result.reasonCodes, contains('NO_HARD_EVIDENCE'));
    });

    test('missing Ultra Hard evidence is ignored when not required', () {
      final result = debtService.assess(
        profile: m7dProfile(ultraHardAccuracy: null),
        requireUltraHardEvidence: false,
      );
      expect(result.reasonCodes, isNot(contains('NO_ULTRA_HARD_EVIDENCE')));
    });

    test('missing Ultra Hard evidence is debt when required', () {
      final result = debtService.assess(
        profile: m7dProfile(ultraHardAccuracy: null),
        requireUltraHardEvidence: true,
      );
      expect(result.reasonCodes, contains('NO_ULTRA_HARD_EVIDENCE'));
    });

    test('stale profile creates stale debt reason', () {
      final result = debtService.assess(
        profile: m7dProfile(readinessState: ReadinessState.stale),
      );
      expect(result.reasonCodes, contains('STALE_EVIDENCE'));
    });

    test('low blueprint breadth creates breadth debt reason', () {
      final result = debtService.assess(profile: m7dProfile(coverage: 0.2));
      expect(result.reasonCodes, contains('INADEQUATE_BLUEPRINT_BREADTH'));
    });

    test('strong complete evidence can have no debt', () {
      final result = debtService.assess(
        profile: m7dProfile(
          evidenceConfidence: EvidenceConfidence.veryHigh,
          coverage: 0.95,
          application: 0.85,
          retention: 0.85,
          hardAccuracy: 0.85,
          ultraHardAccuracy: 0.8,
        ),
        requireUltraHardEvidence: true,
      );
      expect(result.level, EvidenceDebtLevel.none);
      expect(result.score, 0);
    });

    test('evidence debt is about unknown evidence not poor score', () {
      final result = debtService.assess(
        profile: m7dProfile(
          evidenceConfidence: EvidenceConfidence.high,
          knowledge: 0.2,
          application: 0.2,
          retention: 0.2,
          coverage: 0.9,
          hardAccuracy: 0.2,
          ultraHardAccuracy: 0.2,
        ),
        requireUltraHardEvidence: true,
      );
      expect(
        result.reasonCodes,
        isNot(contains('INSUFFICIENT_ASSESSMENT_EVIDENCE')),
      );
    });
  });

  group('M7D LearningPriorityEngine', () {
    test('higher blueprint weight increases priority', () {
      final high = engine.score(
        competencyId: 'd01_c01',
        domainWeightPercent: 25,
        daysUntilExam: 60,
        profile: m7dProfile(competencyId: 'd01_c01'),
        ultraHardAvailable: false,
      );
      final low = engine.score(
        competencyId: 'd05_c01',
        domainWeightPercent: 6,
        daysUntilExam: 60,
        profile: m7dProfile(competencyId: 'd05_c01'),
        ultraHardAvailable: false,
      );
      expect(high.blueprintImportance, greaterThan(low.blueprintImportance));
      expect(high.totalScore, greaterThan(low.totalScore));
    });

    test('knowledge weakness contributes mastery gap', () {
      final score = engine.score(
        competencyId: 'd03_c02',
        domainWeightPercent: 15,
        daysUntilExam: 60,
        profile: m7dProfile(knowledge: 0.2),
        ultraHardAvailable: false,
      );
      expect(score.masteryGap, closeTo(0.8, 0.001));
      expect(score.reasonCodes, contains('MASTERY_GAP'));
    });

    test('application weakness contributes application gap', () {
      final score = engine.score(
        competencyId: 'd03_c02',
        domainWeightPercent: 15,
        daysUntilExam: 60,
        profile: m7dProfile(application: 0.2),
        ultraHardAvailable: false,
      );
      expect(score.applicationGap, closeTo(0.8, 0.001));
      expect(score.reasonCodes, contains('APPLICATION_GAP'));
    });

    test('retention weakness contributes retention risk', () {
      final score = engine.score(
        competencyId: 'd03_c02',
        domainWeightPercent: 15,
        daysUntilExam: 60,
        profile: m7dProfile(retention: 0.2),
        ultraHardAvailable: false,
      );
      expect(score.retentionRisk, closeTo(0.8, 0.001));
      expect(score.reasonCodes, contains('RETENTION_DUE'));
    });

    test('coverage weakness contributes coverage gap', () {
      final score = engine.score(
        competencyId: 'd03_c02',
        domainWeightPercent: 15,
        daysUntilExam: 60,
        profile: m7dProfile(coverage: 0.2),
        ultraHardAvailable: false,
      );
      expect(score.coverageGap, closeTo(0.8, 0.001));
      expect(score.reasonCodes, contains('COVERAGE_GAP'));
    });

    test(
      'missing profile contributes evidence debt without fake performance gap',
      () {
        final score = engine.score(
          competencyId: 'd03_c02',
          domainWeightPercent: 15,
          daysUntilExam: 60,
          profile: null,
          ultraHardAvailable: false,
        );
        expect(score.evidenceDebt, 1);
        expect(score.masteryGap, 0);
        expect(score.applicationGap, 0);
        expect(score.retentionRisk, 0);
      },
    );

    test('stale state contributes staleness', () {
      final score = engine.score(
        competencyId: 'd03_c02',
        domainWeightPercent: 15,
        daysUntilExam: 60,
        profile: m7dProfile(readinessState: ReadinessState.stale),
        ultraHardAvailable: false,
      );
      expect(score.staleness, 1);
      expect(score.reasonCodes, contains('STALE_EVIDENCE'));
    });

    test('staleness gap also contributes staleness', () {
      final score = engine.score(
        competencyId: 'd03_c02',
        domainWeightPercent: 15,
        daysUntilExam: 60,
        profile: m7dProfile(
          gaps: [
            m7dGap(
              type: ReadinessGapType.stalenessGap,
              reasonCode: 'STALE_EVIDENCE',
              evidenceLimited: true,
            ),
          ],
        ),
        ultraHardAvailable: false,
      );
      expect(score.staleness, greaterThan(0));
    });

    test('difficulty weakness contributes difficulty signal', () {
      final score = engine.score(
        competencyId: 'd03_c02',
        domainWeightPercent: 15,
        daysUntilExam: 60,
        profile: m7dProfile(difficulty: 0.2),
        ultraHardAvailable: false,
      );
      expect(score.difficultyWeakness, closeTo(0.8, 0.001));
      expect(score.reasonCodes, contains('DIFFICULTY_GAP'));
    });

    test('exam tomorrow has high exam proximity', () {
      final score = engine.score(
        competencyId: 'd03_c02',
        domainWeightPercent: 15,
        daysUntilExam: 1,
        profile: m7dProfile(),
        ultraHardAvailable: false,
      );
      expect(score.examProximity, greaterThan(0.95));
      expect(score.reasonCodes, contains('EXAM_PROXIMITY'));
    });

    test('exam 90 days away has zero urgency component', () {
      final score = engine.score(
        competencyId: 'd03_c02',
        domainWeightPercent: 15,
        daysUntilExam: 90,
        profile: m7dProfile(),
        ultraHardAvailable: false,
      );
      expect(score.examProximity, 0);
    });

    test('recent study applies penalty', () {
      final recent = engine.score(
        competencyId: 'd03_c02',
        domainWeightPercent: 15,
        daysUntilExam: 60,
        profile: m7dProfile(),
        ultraHardAvailable: false,
        recentlyStudied: true,
      );
      final notRecent = engine.score(
        competencyId: 'd03_c02',
        domainWeightPercent: 15,
        daysUntilExam: 60,
        profile: m7dProfile(),
        ultraHardAvailable: false,
      );
      expect(recent.recentStudyPenalty, greaterThan(0));
      expect(recent.totalScore, lessThan(notRecent.totalScore));
    });

    test('prerequisite importance is preserved', () {
      final score = engine.score(
        competencyId: 'd03_c02',
        domainWeightPercent: 15,
        daysUntilExam: 60,
        profile: m7dProfile(),
        ultraHardAvailable: false,
        prerequisiteImportance: 0.8,
      );
      expect(score.prerequisiteImportance, 0.8);
    });

    test(
      'Ultra Hard bank plus missing Ultra evidence creates Ultra Hard gap reason',
      () {
        final score = engine.score(
          competencyId: 'd03_c02',
          domainWeightPercent: 15,
          daysUntilExam: 60,
          profile: m7dProfile(ultraHardAccuracy: null),
          ultraHardAvailable: true,
        );
        expect(score.reasonCodes, contains('ULTRA_HARD_GAP'));
      },
    );

    test('no Ultra Hard bank does not create Ultra Hard gap reason', () {
      final score = engine.score(
        competencyId: 'd03_c02',
        domainWeightPercent: 15,
        daysUntilExam: 60,
        profile: m7dProfile(ultraHardAccuracy: null),
        ultraHardAvailable: false,
      );
      expect(score.reasonCodes, isNot(contains('ULTRA_HARD_GAP')));
    });

    test('poor calibration creates confidence reason', () {
      final score = engine.score(
        competencyId: 'd03_c02',
        domainWeightPercent: 15,
        daysUntilExam: 60,
        profile: m7dProfile(calibration: 0.3),
        ultraHardAvailable: false,
      );
      expect(score.reasonCodes, contains('CONFIDENCE_MISALIGNMENT'));
    });

    test('priority total remains within unit interval', () {
      final score = engine.score(
        competencyId: 'd03_c02',
        domainWeightPercent: 25,
        daysUntilExam: 0,
        profile: m7dProfile(
          knowledge: 0,
          application: 0,
          retention: 0,
          coverage: 0,
          difficulty: 0,
          calibration: 0,
          readinessState: ReadinessState.stale,
        ),
        ultraHardAvailable: true,
        prerequisiteImportance: 1,
      );
      expect(score.totalScore, inInclusiveRange(0, 1));
    });

    test('priority output always has reason codes', () {
      final score = engine.score(
        competencyId: 'd03_c02',
        domainWeightPercent: 6,
        daysUntilExam: 90,
        profile: m7dProfile(
          knowledge: 1,
          application: 1,
          retention: 1,
          coverage: 1,
          difficulty: 1,
          calibration: 1,
          evidenceConfidence: EvidenceConfidence.veryHigh,
          readinessState: ReadinessState.stable,
          hardAccuracy: 1,
          ultraHardAccuracy: 1,
        ),
        ultraHardAvailable: false,
      );
      expect(score.reasonCodes, isNotEmpty);
    });

    test('priority output retains competency ID', () {
      final score = engine.score(
        competencyId: 'd06_c05',
        domainWeightPercent: 8,
        daysUntilExam: 30,
        profile: m7dProfile(competencyId: 'd06_c05'),
        ultraHardAvailable: false,
      );
      expect(score.competencyId, 'd06_c05');
    });
  });
}
