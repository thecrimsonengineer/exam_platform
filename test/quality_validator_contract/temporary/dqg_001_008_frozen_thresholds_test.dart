import 'package:flutter_test/flutter_test.dart';

import '_support/dqg_contract_fixture.dart';

void main() {
  group('DQG-001..008 frozen thresholds', () {
    test('DQG-001 blocks any option count other than four', () {
      expectBlockedBy(
        'DQG-001',
        question: perfectQuestion(options: const ['A', 'B', 'C']),
      );
    });

    test('DQG-002 blocks an invalid BEST-answer key', () {
      expectBlockedBy('DQG-002', question: perfectQuestion(correctAnswer: 9));
    });

    test('DQG-003 blocks fewer than three distractor evidence records', () {
      final evidence = perfectEvidence().copyWith(
        distractors: [perfectDistractor(0), perfectDistractor(1)],
      );
      expectBlockedBy('DQG-003', evidence: evidence);
    });

    test('DQG-004 blocks any difficulty below exact DQ6', () {
      expectBlockedBy(
        'DQG-004',
        evidence: perfectEvidence().copyWith(difficultyLevel: 'DQ5'),
      );
    });

    test('DQG-005 blocks plausibility 4 even though it is close to 5', () {
      final d = perfectDistractor(0).copyWith(plausibilityScore: 4);
      expectBlockedBy(
        'DQG-005',
        evidence: replaceDistractor(perfectEvidence(), 0, d),
      );
    });

    test('DQG-006 blocks Truth Component Score 3', () {
      final d = perfectDistractor(0).copyWith(truthComponentScore: 3);
      expectBlockedBy(
        'DQG-006',
        evidence: replaceDistractor(perfectEvidence(), 0, d),
      );
    });

    test('DQG-007 blocks confusability below or above exact 4', () {
      var d = perfectDistractor(0).copyWith(confusabilityScore: 3);
      expectBlockedBy(
        'DQG-007',
        evidence: replaceDistractor(perfectEvidence(), 0, d),
      );
      d = perfectDistractor(0).copyWith(confusabilityScore: 5);
      expectBlockedBy(
        'DQG-007',
        evidence: replaceDistractor(perfectEvidence(), 0, d),
      );
    });

    test('DQG-008 blocks any computed DQS below 100', () {
      final evidence = perfectEvidence().copyWith(noMaterialLengthCue: false);
      expectBlockedBy('DQG-008', evidence: evidence);
    });
  });
}
