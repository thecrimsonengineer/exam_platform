import 'package:flutter_test/flutter_test.dart';

import '_support/dqg_contract_fixture.dart';

void main() {
  group('DQG-057..064 integrity and aggregate publication', () {
    test('DQG-057 blocks duplicate or semantically equivalent options', () {
      final q = perfectQuestion(options: const [
        'Use combination filtration for both contaminants.',
        'Use particulate filtration only.',
        'Use particulate filtration only.',
        'Use higher APF with vapour-only filtration.',
      ]);
      expectBlockedBy('DQG-057', question: q);
    });

    test('DQG-058 requires numerical distractor provenance when numeric', () {
      expectBlockedBy(
        'DQG-058',
        evidence: perfectEvidence().copyWith(numericQuestion: true),
      );
    });

    test('DQG-059 requires independently verified answer key', () {
      expectBlockedBy(
        'DQG-059',
        evidence: perfectEvidence().copyWith(answerKeyVerified: false),
      );
    });

    test('DQG-060 requires sufficient stem information', () {
      expectBlockedBy(
        'DQG-060',
        evidence: perfectEvidence().copyWith(stemSufficient: false),
      );
    });

    test('DQG-061 requires intended competency rather than trivia', () {
      expectBlockedBy(
        'DQG-061',
        evidence: perfectEvidence().copyWith(testsIntendedCompetency: false),
      );
    });

    test('DQG-062 controls wrong-level correctness', () {
      expectBlockedBy(
        'DQG-062',
        evidence: perfectEvidence().copyWith(
          wrongLevelCorrectnessApplicable: true,
          wrongLevelDistinctionDocumented: false,
        ),
      );
    });

    test('DQG-063 requires sophistication parity when applicable', () {
      expectBlockedBy(
        'DQG-063',
        evidence: perfectEvidence().copyWith(sophisticationParitySatisfied: false),
      );
    });

    test('DQG-064 blocks if any preceding gate fails', () {
      expectBlockedBy(
        'DQG-064',
        evidence: perfectEvidence().copyWith(reviewComplete: false),
      );
    });
  });
}
