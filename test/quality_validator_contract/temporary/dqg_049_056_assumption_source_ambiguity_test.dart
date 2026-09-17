import 'package:flutter_test/flutter_test.dart';

import '_support/dqg_contract_fixture.dart';

void main() {
  group('DQG-049..056 assumptions, sources and ambiguity', () {
    test('DQG-049 blocks unstated KEY assumptions', () {
      expectBlockedBy(
        'DQG-049',
        evidence: perfectEvidence().copyWith(keyRequiresNoUnstatedAssumption: false),
      );
    });

    test('DQG-050 requires assumption documentation and KEY support', () {
      expectBlockedBy(
        'DQG-050',
        evidence: perfectEvidence().copyWith(assumptionsDocumented: false),
      );
    });

    test('DQG-051 blocks assumption-created KEY/distractor equivalence', () {
      expectBlockedBy(
        'DQG-051',
        evidence: perfectEvidence().copyWith(noEquivalenceFromUnstatedAssumption: false),
      );
    });

    test('DQG-052 requires authoritative source support for KEY', () {
      expectBlockedBy(
        'DQG-052',
        evidence: perfectEvidence().copyWith(sourceAuthorityVerified: false),
      );
    });

    test('DQG-053 requires source support for each rejection distinction', () {
      final d = perfectDistractor(0).copyWith(sourceSupportsRejectionDistinction: false);
      expectBlockedBy('DQG-053', evidence: replaceDistractor(perfectEvidence(), 0, d));
    });

    test('DQG-054 blocks unsupported microscopic distinctions', () {
      expectBlockedBy(
        'DQG-054',
        evidence: perfectEvidence().copyWith(noUnsupportedMicroscopicDistinction: false),
      );
    });

    test('DQG-055 ambiguity firewall blocks equally defensible distractor', () {
      expectBlockedBy(
        'DQG-055',
        evidence: perfectEvidence().copyWith(ambiguityDetected: true),
      );
    });

    test('DQG-056 requires exact SME rejection proof for all distractors', () {
      final d = perfectDistractor(0).copyWith(smeRejectionProof: '');
      expectBlockedBy('DQG-056', evidence: replaceDistractor(perfectEvidence(), 0, d));
    });
  });
}
