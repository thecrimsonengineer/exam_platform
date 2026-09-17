import 'package:flutter_test/flutter_test.dart';

import '_support/dqg_contract_fixture.dart';

void main() {
  group('DQG-025..032 required distractor evidence', () {
    test('DQG-025 requires targeted misconception', () {
      final d = perfectDistractor(0).copyWith(targetedMisconception: '');
      expectBlockedBy('DQG-025', evidence: replaceDistractor(perfectEvidence(), 0, d));
    });

    test('DQG-026 requires whyTempting rationale', () {
      final d = perfectDistractor(0).copyWith(whyTempting: '');
      expectBlockedBy('DQG-026', evidence: replaceDistractor(perfectEvidence(), 0, d));
    });

    test('DQG-027 requires specific fatalFlaw explanation', () {
      final d = perfectDistractor(0).copyWith(fatalFlaw: '');
      expectBlockedBy('DQG-027', evidence: replaceDistractor(perfectEvidence(), 0, d));
    });

    test('DQG-028 requires scenario evidence and validated anchors', () {
      final d = perfectDistractor(0).copyWith(scenarioEvidence: const []);
      expectBlockedBy('DQG-028', evidence: replaceDistractor(perfectEvidence(), 0, d));
    });

    test('DQG-029 requires technicalTruth', () {
      final d = perfectDistractor(0).copyWith(technicalTruth: '');
      expectBlockedBy('DQG-029', evidence: replaceDistractor(perfectEvidence(), 0, d));
    });

    test('DQG-030 requires decisive keyDifference', () {
      final d = perfectDistractor(0).copyWith(keyDifference: '');
      expectBlockedBy('DQG-030', evidence: replaceDistractor(perfectEvidence(), 0, d));
    });

    test('DQG-031 requires counterfactualToBecomeCorrect', () {
      final d = perfectDistractor(0).copyWith(counterfactualToBecomeCorrect: '');
      expectBlockedBy('DQG-031', evidence: replaceDistractor(perfectEvidence(), 0, d));
    });

    test('DQG-032 blocks unknown family without technical justification', () {
      final d = perfectDistractor(0).copyWith(family: 'D-CUSTOM', familyJustification: '');
      expectBlockedBy('DQG-032', evidence: replaceDistractor(perfectEvidence(), 0, d));
    });
  });
}
