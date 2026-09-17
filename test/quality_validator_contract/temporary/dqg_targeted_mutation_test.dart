import 'package:flutter_test/flutter_test.dart';

import '_support/dqg_contract_fixture.dart';

void main() {
  group('targeted mutations never escape the aggregate gate', () {
    test('near-pass plausibility 4 is still a hard block', () {
      final d = perfectDistractor(0).copyWith(plausibilityScore: 4);
      expectBlockedBy('DQG-005', evidence: replaceDistractor(perfectEvidence(), 0, d));
    });

    test('near-pass Truth Component 3 is still a hard block', () {
      final d = perfectDistractor(1).copyWith(truthComponentScore: 3);
      expectBlockedBy('DQG-006', evidence: replaceDistractor(perfectEvidence(), 1, d));
    });

    test('confusability 5 blocks because equivalence is ambiguity', () {
      final d = perfectDistractor(2).copyWith(confusabilityScore: 5);
      expectBlockedBy('DQG-007', evidence: replaceDistractor(perfectEvidence(), 2, d));
    });

    test('one missing SME proof is enough to block', () {
      final d = perfectDistractor(1).copyWith(smeRejectionProof: '');
      expectBlockedBy('DQG-056', evidence: replaceDistractor(perfectEvidence(), 1, d));
    });

    test('one source-rejection gap is enough to block', () {
      final d = perfectDistractor(2).copyWith(sourceSupportsRejectionDistinction: false);
      expectBlockedBy('DQG-053', evidence: replaceDistractor(perfectEvidence(), 2, d));
    });

    test('one elimination shortcut is enough to block', () {
      final d = perfectDistractor(0).copyWith(nonTechnicalEliminationShortcutDetected: true);
      expectBlockedBy('DQG-048', evidence: replaceDistractor(perfectEvidence(), 0, d));
    });
  });
}
