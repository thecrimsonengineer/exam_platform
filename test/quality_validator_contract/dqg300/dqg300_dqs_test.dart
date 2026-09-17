import 'package:flutter_test/flutter_test.dart';

import '_support/dqg300_fixture.dart';

void main() {
  test('DQS is derived from exactly ten fixed 10-point categories', () {
    final result = validatePerfect();

    expect(result.dqsCategories.keys.toList(), [
      'plausibility',
      'truthComponent',
      'dq6Compliance',
      'scenarioIntegration',
      'misconceptionTargeting',
      'singleFatalFlaw',
      'confusability',
      'parity',
      'eliminationResistance',
      'superiorityAmbiguity',
    ]);
    expect(result.dqsCategories.values, everyElement(10));
    expect(result.dqs, 100);
  });

  test('plausibility category cannot shave 5 to 4', () {
    final d = perfectDqg300Distractor(0).copyWith(plausibilityScore: 4);
    final result = validatePerfect(
      evidence: replaceDqg300Distractor(perfectDqg300Evidence(), 0, d),
    );
    expect(result.dqsCategories['plausibility'], 0);
    expect(result.dqs, lessThan(100));
    expect(result.rule('DQG-300').passed, isFalse);
  });

  test('truth category cannot shave 4 to 3', () {
    final d = perfectDqg300Distractor(0).copyWith(truthComponentScore: 3);
    final result = validatePerfect(
      evidence: replaceDqg300Distractor(perfectDqg300Evidence(), 0, d),
    );
    expect(result.dqsCategories['truthComponent'], 0);
    expect(result.dqs, lessThan(100));
  });

  test('DQ6 category cannot accept DQ5', () {
    final result = validatePerfect(
      evidence: perfectDqg300Evidence().copyWith(difficultyLevel: 'DQ5'),
    );
    expect(result.dqsCategories['dq6Compliance'], 0);
    expect(result.dqs, lessThan(100));
  });

  test('scenario integration category requires multiple facts', () {
    final result = validatePerfect(
      evidence: perfectDqg300Evidence().copyWith(
        decisiveScenarioFacts: const ['single fact'],
      ),
    );
    expect(result.dqsCategories['scenarioIntegration'], 0);
  });

  test('misconception category requires distinct fingerprints', () {
    final d = perfectDqg300Distractor(1).copyWith(
      misconceptionFingerprint:
          perfectDqg300Distractor(0).misconceptionFingerprint,
    );
    final result = validatePerfect(
      evidence: replaceDqg300Distractor(perfectDqg300Evidence(), 1, d),
    );
    expect(result.dqsCategories['misconceptionTargeting'], 0);
  });

  test('single fatal flaw category rejects multiple independent defects', () {
    final d = perfectDqg300Distractor(0).copyWith(
      singleFatalFlaw: false,
      multipleUnrelatedDefectsDetected: true,
    );
    final result = validatePerfect(
      evidence: replaceDqg300Distractor(perfectDqg300Evidence(), 0, d),
    );
    expect(result.dqsCategories['singleFatalFlaw'], 0);
  });

  test('confusability category rejects both 3 and 5', () {
    for (final score in [3, 5]) {
      final d = perfectDqg300Distractor(0).copyWith(confusabilityScore: score);
      final result = validatePerfect(
        evidence: replaceDqg300Distractor(perfectDqg300Evidence(), 0, d),
      );
      expect(result.dqsCategories['confusability'], 0);
      expect(result.rule('DQG-300').passed, isFalse);
    }
  });

  test('parity category blocks a material length cue', () {
    final result = validatePerfect(
      evidence: perfectDqg300Evidence().copyWith(noMaterialLengthCue: false),
    );
    expect(result.dqsCategories['parity'], 0);
  });

  test('elimination category blocks nontechnical shortcuts', () {
    final d = perfectDqg300Distractor(0).copyWith(
      nonTechnicalEliminationShortcutDetected: true,
    );
    final result = validatePerfect(
      evidence: replaceDqg300Distractor(perfectDqg300Evidence(), 0, d),
    );
    expect(result.dqsCategories['eliminationResistance'], 0);
  });

  test('superiority and ambiguity category blocks ambiguity', () {
    final result = validatePerfect(
      evidence: perfectDqg300Evidence().copyWith(ambiguityDetected: true),
    );
    expect(result.dqsCategories['superiorityAmbiguity'], 0);
  });
}
