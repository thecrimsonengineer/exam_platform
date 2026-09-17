import 'package:flutter_test/flutter_test.dart';

import '_support/dqg300_fixture.dart';

void main() {
  test('exactly four options is machine-enforced', () {
    final result = validatePerfect(
      question: perfectDqg300Question(options: const ['A', 'B', 'C']),
    );
    expect(result.rule('DQG-001').passed, isFalse);
    expect(result.rule('DQG-260').passed, isFalse);
    expect(result.rule('DQG-300').passed, isFalse);
  });

  test('answer key validity is machine-enforced', () {
    final result = validatePerfect(
      question: perfectDqg300Question(correctAnswer: 9),
    );
    expect(result.rule('DQG-002').passed, isFalse);
    expect(result.rule('DQG-261').passed, isFalse);
  });

  test('distractor evidence must match exactly three non-key indexes', () {
    final broken = [
      perfectDqg300Distractor(0).copyWith(optionIndex: 3),
      perfectDqg300Distractor(1),
      perfectDqg300Distractor(2),
    ];
    final result = validatePerfect(
      evidence: perfectDqg300Evidence(distractors: broken),
    );
    expect(result.rule('DQG-003').passed, isFalse);
    expect(result.rule('DQG-262').passed, isFalse);
  });

  test('filler answer text cannot pass through semantic proof', () {
    final result = validatePerfect(
      question: perfectDqg300Question(
        options: const [
          'Use combination particulate and organic-vapour filtration.',
          '',
          'Use an organic-vapour cartridge with a shorter change schedule.',
          'Use a higher-APF powered respirator with vapour-only filtration.',
        ],
      ),
    );
    expect(result.rule('DQG-004').passed, isFalse);
  });

  test('missing structured rule evidence fails closed', () {
    final evidence = perfectDqg300Evidence().withoutRuleEvidence('DQG-125');
    final result = validatePerfect(evidence: evidence);
    expect(result.rule('DQG-125').passed, isFalse);
    expect(result.rule('DQG-298').passed, isFalse);
    expect(result.rule('DQG-300').passed, isFalse);
  });

  test('manual override request is a block, never a route to PASS', () {
    final result = validatePerfect(
      evidence: perfectDqg300Evidence().copyWith(manualOverrideRequested: true),
    );
    expect(result.rule('DQG-022').passed, isFalse);
    expect(result.rule('DQG-299').passed, isFalse);
    expect(result.rule('DQG-300').passed, isFalse);
  });

  test('unresolved warning blocks final publication', () {
    final result = validatePerfect(
      evidence: perfectDqg300Evidence().copyWith(unresolvedWarningCount: 1),
    );
    expect(result.rule('DQG-255').passed, isFalse);
    expect(result.rule('DQG-258').passed, isFalse);
    expect(result.rule('DQG-300').passed, isFalse);
  });

  test('literal duplicate options block despite positive review records', () {
    final result = validatePerfect(
      question: perfectDqg300Question(
        options: const [
          'Use combination filtration.',
          'Use particulate filtration.',
          'Use particulate filtration.',
          'Use higher APF vapour-only filtration.',
        ],
      ),
    );
    expect(result.rule('DQG-021').passed, isFalse);
    expect(result.rule('DQG-232').passed, isFalse);
  });

  test('semantic equivalence blocks without literal duplicate text', () {
    final result = validatePerfect(
      evidence: perfectDqg300Evidence().copyWith(
        semanticDuplicateOptionsDetected: true,
      ),
    );
    expect(result.rule('DQG-021').passed, isFalse);
    expect(result.rule('DQG-232').passed, isFalse);
  });

  test('source support covers KEY and every rejection distinction', () {
    final d = perfectDqg300Distractor(0).copyWith(
      sourceSupportsRejectionDistinction: false,
    );
    final result = validatePerfect(
      evidence: replaceDqg300Distractor(
        perfectDqg300Evidence().copyWith(sourceSupportsKey: false),
        0,
        d,
      ),
    );
    expect(result.rule('DQG-020').passed, isFalse);
    expect(result.rule('DQG-189').passed, isFalse);
    expect(result.rule('DQG-190').passed, isFalse);
    expect(result.rule('DQG-274').passed, isFalse);
  });

  test('generic KEY superiority wording is rejected', () {
    final proof = Map<int, String>.from(
      perfectDqg300Evidence().keySuperiorityProof,
    )..[1] = 'D1 is less appropriate.';
    final result = validatePerfect(
      evidence: perfectDqg300Evidence().copyWith(keySuperiorityProof: proof),
    );
    expect(result.rule('DQG-100').passed, isFalse);
    expect(result.rule('DQG-104').passed, isFalse);
  });

  test('custom family needs explicit technical justification', () {
    final bad = perfectDqg300Distractor(0).copyWith(
      family: 'D-CUSTOM',
      familyJustification: '',
    );
    var result = validatePerfect(
      evidence: replaceDqg300Distractor(perfectDqg300Evidence(), 0, bad),
    );
    expect(result.rule('DQG-086').passed, isFalse);

    final good = bad.copyWith(
      familyJustification:
          'Cross-hazard integration failure is documented and not represented by a named frozen family.',
    );
    result = validatePerfect(
      evidence: replaceDqg300Distractor(perfectDqg300Evidence(), 0, good),
    );
    expect(result.rule('DQG-086').passed, isTrue);
  });

  test('numeric question requires provenance for every distractor', () {
    var result = validatePerfect(
      evidence: perfectDqg300Evidence().copyWith(numericQuestion: true),
    );
    expect(result.rule('DQG-167').passed, isFalse);
    expect(result.rule('DQG-168').passed, isFalse);
    expect(result.rule('DQG-246').passed, isFalse);

    final numeric = [
      for (var i = 0; i < 3; i++)
        perfectDqg300Distractor(i).copyWith(
          distractorCalculationPath: 'Validated calculation path ${i + 1}',
        ),
    ];
    result = validatePerfect(
      evidence: perfectDqg300Evidence(distractors: numeric).copyWith(
        numericQuestion: true,
      ),
    );
    expect(result.rule('DQG-167').passed, isTrue);
    expect(result.rule('DQG-168').passed, isTrue);
  });

  test('incomplete option metrics cannot be papered over by proof records', () {
    final result = validatePerfect(
      evidence: perfectDqg300Evidence().copyWith(
        optionSurfaceMetrics:
            perfectDqg300Evidence().optionSurfaceMetrics.take(3).toList(),
      ),
    );
    for (final id in ['DQG-125', 'DQG-126', 'DQG-127', 'DQG-128', 'DQG-129']) {
      expect(result.rule(id).passed, isFalse);
    }
  });

  test('answer-key review must agree with stored key', () {
    final result = validatePerfect(
      evidence: perfectDqg300Evidence().copyWith(answerKeyVerified: false),
    );
    expect(result.rule('DQG-248').passed, isFalse);
  });

  test('missing stem information blocks rather than being guessed', () {
    final result = validatePerfect(
      evidence: perfectDqg300Evidence().copyWith(stemSufficient: false),
    );
    expect(result.rule('DQG-250').passed, isFalse);
    expect(result.rule('DQG-300').passed, isFalse);
  });

  test('trivia substitution for competency assessment blocks', () {
    final result = validatePerfect(
      evidence: perfectDqg300Evidence().copyWith(testsIntendedCompetency: false),
    );
    expect(result.rule('DQG-249').passed, isFalse);
  });
}
