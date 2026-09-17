import 'package:flutter_test/flutter_test.dart';

import '_support/dqg_contract_fixture.dart';

void main() {
  group('DQG-017..024 expert near-miss construction', () {
    test('DQG-017 requires expert_near_miss role', () {
      final d = perfectDistractor(0).copyWith(role: 'generic_wrong_answer');
      expectBlockedBy('DQG-017', evidence: replaceDistractor(perfectEvidence(), 0, d));
    });

    test('DQG-018 requires same technical universe and professional level', () {
      final d = perfectDistractor(0).copyWith(sameTechnicalUniverse: false);
      expectBlockedBy('DQG-018', evidence: replaceDistractor(perfectEvidence(), 0, d));
    });

    test('DQG-019 requires substantial technical correctness and relevance', () {
      final d = perfectDistractor(0).copyWith(substantiallyTechnicallyCorrect: false);
      expectBlockedBy('DQG-019', evidence: replaceDistractor(perfectEvidence(), 0, d));
    });

    test('DQG-020 requires one dominant fatal flaw', () {
      final d = perfectDistractor(0).copyWith(singleFatalFlaw: false);
      expectBlockedBy('DQG-020', evidence: replaceDistractor(perfectEvidence(), 0, d));
    });

    test('DQG-021 blocks multiple unrelated defects', () {
      final d = perfectDistractor(0).copyWith(multipleUnrelatedDefectsDetected: true);
      expectBlockedBy('DQG-021', evidence: replaceDistractor(perfectEvidence(), 0, d));
    });

    test('DQG-022 requires three distinct failure families', () {
      final d = perfectDistractor(1).copyWith(family: perfectDistractor(0).family);
      expectBlockedBy('DQG-022', evidence: replaceDistractor(perfectEvidence(), 1, d));
    });

    test('DQG-023 requires unique misconception fingerprints', () {
      final d = perfectDistractor(1).copyWith(
        misconceptionFingerprint: perfectDistractor(0).misconceptionFingerprint,
      );
      expectBlockedBy('DQG-023', evidence: replaceDistractor(perfectEvidence(), 1, d));
    });

    test('DQG-024 requires sophisticated professionally credible reasoning', () {
      final d = perfectDistractor(0).copyWith(sophisticatedReasoningPath: false);
      expectBlockedBy('DQG-024', evidence: replaceDistractor(perfectEvidence(), 0, d));
    });
  });
}
