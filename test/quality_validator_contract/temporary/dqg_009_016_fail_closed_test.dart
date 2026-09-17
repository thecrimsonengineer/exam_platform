import 'package:flutter_test/flutter_test.dart';

import '_support/dqg_contract_fixture.dart';

void main() {
  group('DQG-009..016 fail-closed governance', () {
    test('DQG-009 blocks unresolved external blocks', () {
      expectBlockedBy(
        'DQG-009',
        evidence: perfectEvidence().copyWith(unresolvedBlockCount: 1),
      );
    });

    test('DQG-010 blocks unresolved external failures', () {
      expectBlockedBy(
        'DQG-010',
        evidence: perfectEvidence().copyWith(unresolvedFailCount: 1),
      );
    });

    test('DQG-011 blocks unresolved warnings', () {
      expectBlockedBy(
        'DQG-011',
        evidence: perfectEvidence().copyWith(unresolvedWarningCount: 1),
      );
    });

    test('DQG-012 blocks any requested publication override', () {
      expectBlockedBy(
        'DQG-012',
        evidence: perfectEvidence().copyWith(manualOverrideRequested: true),
      );
    });

    test('DQG-013 blocks more than one defensible BEST answer', () {
      expectBlockedBy(
        'DQG-013',
        evidence: perfectEvidence().copyWith(defensibleBestAnswerCount: 2),
      );
    });

    test('DQG-014 blocks incomplete review', () {
      expectBlockedBy(
        'DQG-014',
        evidence: perfectEvidence().copyWith(reviewComplete: false),
      );
    });

    test('DQG-015 blocks missing mandatory structured evidence', () {
      final d = perfectDistractor(0).copyWith(targetedMisconception: '');
      expectBlockedBy(
        'DQG-015',
        evidence: replaceDistractor(perfectEvidence(), 0, d),
      );
    });

    test('DQG-016 enforces exact frozen thresholds without tolerance', () {
      final d = perfectDistractor(0).copyWith(plausibilityScore: 4);
      expectBlockedBy(
        'DQG-016',
        evidence: replaceDistractor(perfectEvidence(), 0, d),
      );
    });
  });
}
