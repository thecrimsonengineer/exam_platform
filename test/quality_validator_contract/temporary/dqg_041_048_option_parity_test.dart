import 'package:flutter_test/flutter_test.dart';

import '_support/dqg_contract_fixture.dart';

void main() {
  group('DQG-041..048 option parity and elimination resistance', () {
    test('DQG-041 requires grammar/type/professional-level parity', () {
      final d = perfectDistractor(0).copyWith(grammarParallel: false);
      expectBlockedBy('DQG-041', evidence: replaceDistractor(perfectEvidence(), 0, d));
    });

    test('DQG-042 requires specificity/detail parity', () {
      final d = perfectDistractor(0).copyWith(specificityAndDetailParallel: false);
      expectBlockedBy('DQG-042', evidence: replaceDistractor(perfectEvidence(), 0, d));
    });

    test('DQG-043 requires metrics and no material length cue', () {
      expectBlockedBy(
        'DQG-043',
        evidence: perfectEvidence().copyWith(noMaterialLengthCue: false),
      );
    });

    test('DQG-044 requires terminology/units/precision/condition parity', () {
      final d = perfectDistractor(0).copyWith(terminologyUnitsPrecisionParallel: false);
      expectBlockedBy('DQG-044', evidence: replaceDistractor(perfectEvidence(), 0, d));
    });

    test('DQG-045 blocks linguistic or answer-position cues', () {
      final d = perfectDistractor(0).copyWith(linguisticCueDetected: true);
      expectBlockedBy('DQG-045', evidence: replaceDistractor(perfectEvidence(), 0, d));
    });

    test('DQG-046 blocks keyword leakage', () {
      final d = perfectDistractor(0).copyWith(keywordLeakageDetected: true);
      expectBlockedBy('DQG-046', evidence: replaceDistractor(perfectEvidence(), 0, d));
    });

    test('DQG-047 blocks certainty-language elimination shortcuts', () {
      final d = perfectDistractor(0).copyWith(absoluteLanguageShortcutDetected: true);
      expectBlockedBy('DQG-047', evidence: replaceDistractor(perfectEvidence(), 0, d));
    });

    test('DQG-048 blocks any nontechnical elimination shortcut', () {
      final d = perfectDistractor(0).copyWith(nonTechnicalEliminationShortcutDetected: true);
      expectBlockedBy('DQG-048', evidence: replaceDistractor(perfectEvidence(), 0, d));
    });
  });
}
