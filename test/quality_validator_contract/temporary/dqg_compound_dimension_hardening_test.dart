import 'package:flutter_test/flutter_test.dart';

import '_support/dqg_contract_fixture.dart';

void main() {
  group('Step 1 compound DQG dimension hardening', () {
    test('DQG-003 blocks duplicate or mismatched distractor option indexes', () {
      final d = perfectDistractor(0).copyWith(optionIndex: 3);
      expectBlockedBy(
        'DQG-003',
        evidence: replaceDistractor(perfectEvidence(), 0, d),
      );
    });

    test('DQG-004 requires every distractor to be exact DQ6', () {
      final d = perfectDistractor(0).copyWith(difficultyLevel: 'DQ5');
      expectBlockedBy(
        'DQG-004',
        evidence: replaceDistractor(perfectEvidence(), 0, d),
      );
    });

    test('DQG-018 blocks professional-level mismatch independently', () {
      final d = perfectDistractor(0).copyWith(sameProfessionalLevel: false);
      expectBlockedBy(
        'DQG-018',
        evidence: replaceDistractor(perfectEvidence(), 0, d),
      );
    });

    test('DQG-019 blocks invalid professional terminology independently', () {
      final d = perfectDistractor(0).copyWith(professionalTerminologyValid: false);
      expectBlockedBy(
        'DQG-019',
        evidence: replaceDistractor(perfectEvidence(), 0, d),
      );
    });

    test('DQG-019 blocks distractor that does not address the actual decision or hazard', () {
      final d = perfectDistractor(0).copyWith(addressesActualDecisionOrHazard: false);
      expectBlockedBy(
        'DQG-019',
        evidence: replaceDistractor(perfectEvidence(), 0, d),
      );
    });

    test('DQG-024 blocks reasoning that is not credible in professional practice', () {
      final d = perfectDistractor(0).copyWith(credibleInProfessionalPractice: false);
      expectBlockedBy(
        'DQG-024',
        evidence: replaceDistractor(perfectEvidence(), 0, d),
      );
    });

    test('DQG-028 blocks invalid scenario anchors even when anchor text exists', () {
      final d = perfectDistractor(0).copyWith(scenarioAnchorsValid: false);
      expectBlockedBy(
        'DQG-028',
        evidence: replaceDistractor(perfectEvidence(), 0, d),
      );
    });

    test('DQG-032 accepts a custom family only when technically justified', () {
      final d = perfectDistractor(0).copyWith(
        family: 'D-CUSTOM',
        familyJustification:
            'Custom family retained because the misconception is a documented cross-hazard integration failure not represented by the frozen named families.',
      );
      final result = validateContract(
        evidence: replaceDistractor(perfectEvidence(), 0, d),
      );

      expect(result.rule('DQG-032').passed, isTrue);
    });

    test('DQG-035 requires every BEST-answer completeness dimension', () {
      final completeness = Map<String, bool>.from(perfectEvidence().keyCompleteness)
        ..['technicalPrinciple'] = false;
      expectBlockedBy(
        'DQG-035',
        evidence: perfectEvidence().copyWith(keyCompleteness: completeness),
      );
    });

    test('DQG-043 blocks incomplete option surface metrics', () {
      expectBlockedBy(
        'DQG-043',
        evidence: perfectEvidence().copyWith(
          optionSurfaceMetrics: perfectEvidence().optionSurfaceMetrics.take(3).toList(),
        ),
      );
    });

    test('DQG-043 blocks a material length or clause parity failure', () {
      final d = perfectDistractor(0).copyWith(lengthAndClauseParallel: false);
      expectBlockedBy(
        'DQG-043',
        evidence: replaceDistractor(perfectEvidence(), 0, d),
      );
    });

    test('DQG-044 blocks conditional-wording mismatch independently', () {
      final d = perfectDistractor(0).copyWith(conditionalWordingParallel: false);
      expectBlockedBy(
        'DQG-044',
        evidence: replaceDistractor(perfectEvidence(), 0, d),
      );
    });

    test('DQG-045 blocks an answer-position cue independently', () {
      expectBlockedBy(
        'DQG-045',
        evidence: perfectEvidence().copyWith(answerPositionCueDetected: true),
      );
    });

    test('DQG-050 blocks unsupported KEY assumptions independently', () {
      expectBlockedBy(
        'DQG-050',
        evidence: perfectEvidence().copyWith(keyAssumptionsSupported: false),
      );
    });

    test('DQG-052 requires at least one authoritative source', () {
      expectBlockedBy(
        'DQG-052',
        evidence: perfectEvidence().copyWith(authoritativeSources: const []),
      );
    });

    test('DQG-052 requires the authoritative source to support the KEY', () {
      expectBlockedBy(
        'DQG-052',
        evidence: perfectEvidence().copyWith(sourceSupportsKey: false),
      );
    });

    test('DQG-057 blocks semantic equivalence even without literal duplicate text', () {
      expectBlockedBy(
        'DQG-057',
        evidence: perfectEvidence().copyWith(semanticDuplicateOptionsDetected: true),
      );
    });

    test('DQG-058 blocks an inconsistent numerical distractor calculation', () {
      final distractors = [
        perfectDistractor(0).copyWith(distractorCalculationPath: 'Calculation path D1'),
        perfectDistractor(1).copyWith(
          distractorCalculationPath: 'Calculation path D2',
          calculationConsistent: false,
        ),
        perfectDistractor(2).copyWith(distractorCalculationPath: 'Calculation path D3'),
      ];
      expectBlockedBy(
        'DQG-058',
        evidence: perfectEvidence().copyWith(
          numericQuestion: true,
          distractors: distractors,
        ),
      );
    });

    test('DQG-063 requires an advanced-sounding distractor when applicable', () {
      expectBlockedBy(
        'DQG-063',
        evidence: perfectEvidence().copyWith(
          sophisticationParityApplicable: true,
          advancedDistractorPresentWhenApplicable: false,
        ),
      );
    });
  });
}
