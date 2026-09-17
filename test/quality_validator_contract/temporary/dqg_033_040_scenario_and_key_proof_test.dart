import 'package:flutter_test/flutter_test.dart';

import '_support/dqg_contract_fixture.dart';

void main() {
  group('DQG-033..040 scenario integration and KEY proof', () {
    test('DQG-033 requires at least two decisive scenario facts', () {
      expectBlockedBy(
        'DQG-033',
        evidence: perfectEvidence().copyWith(decisiveScenarioFacts: const ['one fact']),
      );
    });

    test('DQG-034 requires complete criterion matrix', () {
      expectBlockedBy(
        'DQG-034',
        evidence: perfectEvidence().copyWith(criterionMatrixComplete: false),
      );
    });

    test('DQG-035 requires KEY to satisfy all material criteria', () {
      expectBlockedBy(
        'DQG-035',
        evidence: perfectEvidence().copyWith(
          keySatisfiedCriteria: const ['addresses particulate'],
        ),
      );
    });

    test('DQG-036 requires every distractor to fail a decisive criterion', () {
      final failures = Map<int, List<String>>.from(perfectEvidence().distractorFailedCriteria);
      failures[1] = const [];
      expectBlockedBy(
        'DQG-036',
        evidence: perfectEvidence().copyWith(distractorFailedCriteria: failures),
      );
    });

    test('DQG-037 requires specific KEY>D1 proof', () {
      final proof = Map<int, String>.from(perfectEvidence().keySuperiorityProof)..[1] = '';
      expectBlockedBy('DQG-037', evidence: perfectEvidence().copyWith(keySuperiorityProof: proof));
    });

    test('DQG-038 requires specific KEY>D2 proof', () {
      final proof = Map<int, String>.from(perfectEvidence().keySuperiorityProof)..[2] = '';
      expectBlockedBy('DQG-038', evidence: perfectEvidence().copyWith(keySuperiorityProof: proof));
    });

    test('DQG-039 requires specific KEY>D3 proof', () {
      final proof = Map<int, String>.from(perfectEvidence().keySuperiorityProof)..[3] = '';
      expectBlockedBy('DQG-039', evidence: perfectEvidence().copyWith(keySuperiorityProof: proof));
    });

    test('DQG-040 requires minimal plausible counterfactuals', () {
      final d = perfectDistractor(0).copyWith(counterfactualMinimalAndPlausible: false);
      expectBlockedBy('DQG-040', evidence: replaceDistractor(perfectEvidence(), 0, d));
    });
  });
}
