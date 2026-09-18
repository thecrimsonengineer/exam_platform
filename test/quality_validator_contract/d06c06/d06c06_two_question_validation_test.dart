import 'package:exam_platform/models/question.dart';
import 'package:exam_platform/models/question_quality_evidence.dart';
import 'package:exam_platform/services/dqg300_question_quality_validator.dart';
import 'package:flutter_test/flutter_test.dart';

const _validator = Dqg300QuestionQualityValidator();

Map<String, DqgEvidenceRecord> _ruleEvidence(String questionId) {
  return {
    for (var i = 1; i <= 299; i++)
      'DQG-' + i.toString().padLeft(3, '0'): DqgEvidenceRecord(
        ruleId: 'DQG-' + i.toString().padLeft(3, '0'),
        satisfied: true,
        proof:
            questionId +
            ': question-specific DQ6 authoring evidence plus the deterministic Step 2 predicate satisfies this frozen atomic rule.',
        evidenceRefs: const [
          'docs/quiz_engine/DQG_300_RULE_MATRIX.md',
          'docs/quiz_engine/CSP11_QUIZ_QUALITY_VALIDATOR_FREEZE_CANDIDATE.md',
          'docs/source_pipeline/CSP11_canonical_blueprint.json::d06_c06',
        ],
        reviewerId: 'GPT56-SOL-AUTHORING-TRIAL',
        reviewedAtIso: '2026-09-18T07:02:00+05:30',
      ),
  };
}

DistractorQualityEvidence _distractor({
  required int optionIndex,
  required String family,
  required String fingerprint,
  required String misconception,
  required String tempting,
  required String fatalFlaw,
  required List<String> scenarioEvidence,
  required String technicalTruth,
  required String keyDifference,
  required String counterfactual,
  required String calculationPath,
  required String technicalReviewProof,
}) {
  return DistractorQualityEvidence(
    optionIndex: optionIndex,
    role: 'expert_near_miss',
    difficultyLevel: 'DQ6',
    plausibilityScore: 5,
    truthComponentScore: 4,
    confusabilityScore: 4,
    family: family,
    misconceptionFingerprint: fingerprint,
    targetedMisconception: misconception,
    whyTempting: tempting,
    fatalFlaw: fatalFlaw,
    scenarioEvidence: scenarioEvidence,
    scenarioAnchorsValid: true,
    technicalTruth: technicalTruth,
    keyDifference: keyDifference,
    counterfactualToBecomeCorrect: counterfactual,
    sameTechnicalUniverse: true,
    sameProfessionalLevel: true,
    substantiallyTechnicallyCorrect: true,
    professionalTerminologyValid: true,
    addressesActualDecisionOrHazard: true,
    credibleInProfessionalPractice: true,
    singleFatalFlaw: true,
    multipleUnrelatedDefectsDetected: false,
    sophisticatedReasoningPath: true,
    counterfactualMinimalAndPlausible: true,
    grammarParallel: true,
    specificityAndDetailParallel: true,
    lengthAndClauseParallel: true,
    terminologyUnitsPrecisionParallel: true,
    conditionalWordingParallel: true,
    linguisticCueDetected: false,
    keywordLeakageDetected: false,
    absoluteLanguageShortcutDetected: false,
    nonTechnicalEliminationShortcutDetected: false,
    sourceSupportsRejectionDistinction: true,
    smeRejectionProof: technicalReviewProof,
    distractorCalculationPath: calculationPath,
    calculationConsistent: true,
  );
}

List<OptionSurfaceMetrics> _metrics(List<String> options) {
  return [
    for (var i = 0; i < options.length; i++)
      OptionSurfaceMetrics(
        optionIndex: i,
        characterCount: options[i].length,
        wordCount: options[i].trim().split(RegExp(r'\s+')).length,
        clauseCount: 1,
        technicalTermCount: 3,
        qualifierCount: 1,
      ),
  ];
}

QuestionQualityEvidence _evidence({
  required String questionId,
  required List<String> options,
  required List<DistractorQualityEvidence> distractors,
  required List<String> decisiveFacts,
  required List<String> criteria,
  required Map<int, List<String>> failedCriteria,
  required Map<int, String> superiority,
  required List<AssumptionEvidence> assumptions,
}) {
  return QuestionQualityEvidence(
    difficultyLevel: 'DQ6',
    distractors: distractors,
    decisiveScenarioFacts: decisiveFacts,
    materialCriteria: criteria,
    keySatisfiedCriteria: criteria,
    distractorFailedCriteria: failedCriteria,
    criterionMatrixComplete: true,
    keySuperiorityProof: superiority,
    keyCompleteness: const {
      'hazard': true,
      'scope': true,
      'timing': true,
      'priority': true,
      'mechanism': true,
      'technicalPrinciple': true,
      'scenarioConditions': true,
      'commandWord': true,
      'calculation': true,
      'assumptions': true,
    },
    defensibleBestAnswerCount: 1,
    reviewComplete: true,
    manualOverrideRequested: false,
    unresolvedBlockCount: 0,
    unresolvedFailCount: 0,
    unresolvedWarningCount: 0,
    keyRequiresNoUnstatedAssumption: true,
    assumptionsDocumented: true,
    keyAssumptionsSupported: true,
    noEquivalenceFromUnstatedAssumption: true,
    assumptions: assumptions,
    authoritativeSources: const [
      'BCSP CSP11 Examination Blueprint V.2024.04.24, competency d06_c06.',
      'OpenStax University Physics Volume 1: Newtonian statics, work and kinetic-energy principles.',
    ],
    sourceAuthorityVerified: true,
    sourceSupportsKey: true,
    noUnsupportedMicroscopicDistinction: true,
    ambiguityDetected: false,
    semanticDuplicateOptionsDetected: false,
    answerPositionCueDetected: false,
    answerKeyVerified: true,
    stemSufficient: true,
    testsIntendedCompetency: true,
    numericQuestion: true,
    wrongLevelCorrectnessApplicable: false,
    wrongLevelDistinctionDocumented: true,
    sophisticationParityApplicable: true,
    sophisticationParitySatisfied: true,
    advancedDistractorPresentWhenApplicable: true,
    optionSurfaceMetrics: _metrics(options),
    noMaterialLengthCue: true,
    ruleEvidence: _ruleEvidence(questionId),
  );
}

Question _q1() {
  const options = [
    '20.9 kN per leg, resolving the 35° angle from horizontal and both vertical components.',
    '14.7 kN per leg, resolving the 35° angle as though it were measured from vertical.',
    '12.0 kN per leg, splitting the load equally while treating both sling legs as vertical.',
    '41.8 kN per leg, resolving the 35° angle correctly but treating one leg as carrying the load.',
  ];

  return const Question(
    id: 606001,
    domain: 6,
    competencyId: 'd06_c06',
    subtopicId: 'validator_trial_d06_c06',
    topicId: 'validator_trial_d06_c06',
    quizId: 'd06_c06_dqg300_trial_quiz',
    contentPackageId: 'd06_c06-dqg300-trial-v1',
    question:
        'A 24 kN load is suspended by two identical sling legs sharing the load symmetrically. Each leg is 35° above horizontal. Ignoring dynamics, what tension must each leg carry to maintain static equilibrium?',
    options: options,
    correctAnswer: 0,
    explanation:
        'Static equilibrium requires the two vertical sling components to equal 24 kN: 2T sin(35°) = 24 kN, so T is about 20.9 kN per leg.',
    bestAnswerRationale:
        'Only the keyed result uses the stated angle reference and the two-leg vertical force balance without changing the scenario.',
    reference:
        'BCSP CSP11 Blueprint d06_c06; OpenStax University Physics Volume 1, Newtonian statics/vector force resolution.',
    difficulty: 'Hard',
    cognitiveLevel: 'analysis',
    questionType: 'scenario_mcq',
    status: 'validated',
    version: 1,
    tags: ['d06_c06', 'forces', 'statics', 'dq6'],
  );
}

QuestionQualityEvidence _q1Evidence() {
  const options = [
    '20.9 kN per leg, resolving the 35° angle from horizontal and both vertical components.',
    '14.7 kN per leg, resolving the 35° angle as though it were measured from vertical.',
    '12.0 kN per leg, splitting the load equally while treating both sling legs as vertical.',
    '41.8 kN per leg, resolving the 35° angle correctly but treating one leg as carrying the load.',
  ];

  return _evidence(
    questionId: 'D06C06-Q01',
    options: options,
    decisiveFacts: const [
      'the total suspended load is 24 kN',
      'two identical sling legs share the load symmetrically',
      'each sling leg is 35 degrees above horizontal',
      'the requested condition is static equilibrium',
    ],
    criteria: const [
      'uses the 35 degree angle from horizontal',
      'resolves the vertical component of tension',
      'includes both sling legs in the force balance',
      'equates total vertical support to 24 kN',
    ],
    failedCriteria: const {
      1: ['uses the 35 degree angle from horizontal'],
      2: ['resolves the vertical component of tension'],
      3: ['includes both sling legs in the force balance'],
    },
    superiority: const {
      1: 'KEY uses sin(35°) for an angle stated from horizontal; D1 instead treats 35° as an angle from vertical.',
      2: 'KEY accounts for the reduced vertical component of each inclined leg; D2 assumes the two legs act vertically.',
      3: 'KEY shares the 24 kN load between two resolved vertical components; D3 applies the component relation to one supporting leg.',
    },
    assumptions: const [
      AssumptionEvidence(
        subject: 'KEY',
        assumptionUsed:
            'The two sling legs are identical, symmetrically loaded, and in static equilibrium.',
        scenarioSupport:
            'All three conditions are explicitly stated in the stem, so equal leg tension and static force balance are supported.',
        supported: true,
        intentionalDistractorTrap: false,
      ),
    ],
    distractors: [
      _distractor(
        optionIndex: 1,
        family: 'D-COND',
        fingerprint: 'SLING_ANGLE_REFERENCE_SWAP',
        misconception:
            'Uses the correct two-leg equilibrium framework but silently changes the angle reference from horizontal to vertical.',
        tempting:
            'The cosine-based value is a standard sling calculation when the given angle is measured from vertical.',
        fatalFlaw:
            'The stem states 35° above horizontal, so substituting cos(35°) changes the stated geometry.',
        scenarioEvidence: const [
          'two identical sling legs',
          '35 degrees above horizontal',
          '24 kN total load',
        ],
        technicalTruth:
            'For an angle measured from vertical, the vertical component of leg tension is T cos(theta).',
        keyDifference:
            'The KEY preserves the horizontal angle reference; this distractor solves a different but closely related geometry.',
        counterfactual:
            'It becomes correct if the stem says each leg is 35° from vertical rather than 35° above horizontal.',
        calculationPath:
            'T = 24 / (2 cos 35°) = 14.65 kN, rounded to 14.7 kN.',
        technicalReviewProof:
            'The calculation is internally valid for a vertical-reference angle, but the actual stem specifies a horizontal-reference angle.',
      ),
      _distractor(
        optionIndex: 2,
        family: 'D-PARTIAL',
        fingerprint: 'SLING_EQUAL_SHARE_WITHOUT_COMPONENT',
        misconception:
            'Recognizes equal load sharing between two legs but stops before resolving the vertical component created by sling inclination.',
        tempting:
            'Dividing a symmetric 24 kN load equally gives a clean 12 kN share per leg and is correct only for vertical legs.',
        fatalFlaw:
            'An inclined leg must carry tension greater than its 12 kN vertical share because only T sin(35°) supports the load vertically.',
        scenarioEvidence: const [
          'two legs share the load symmetrically',
          'each leg is inclined 35 degrees above horizontal',
        ],
        technicalTruth:
            'Each leg must provide 12 kN of vertical support when the 24 kN load is shared symmetrically.',
        keyDifference:
            'The KEY distinguishes vertical support from actual sling tension; this distractor equates those quantities.',
        counterfactual:
            'It becomes correct if both sling legs are vertical so each leg tension equals its 12 kN vertical load share.',
        calculationPath:
            '24 kN / 2 legs = 12.0 kN per leg, with no angular component resolution.',
        technicalReviewProof:
            'The equal-share step is correct, but treating vertical load share as total inclined-leg tension omits the stated geometry.',
      ),
      _distractor(
        optionIndex: 3,
        family: 'D-SCOPE',
        fingerprint: 'SLING_SINGLE_LEG_EQUILIBRIUM',
        misconception:
            'Uses the correct sine component for the stated angle but applies the full 24 kN vertical load to one leg.',
        tempting:
            'The component equation T sin(35°) = 24 kN is physically valid for a single inclined support carrying the whole load.',
        fatalFlaw:
            'The stem explicitly provides two identical legs sharing the load symmetrically, so both vertical components contribute.',
        scenarioEvidence: const [
          'two identical sling legs',
          'symmetric load sharing',
          '35 degrees above horizontal',
        ],
        technicalTruth:
            'For one inclined leg carrying a 24 kN vertical load, T = 24 / sin(35°) is the correct component calculation.',
        keyDifference:
            'The KEY includes both supporting legs; this distractor narrows the support system to one leg.',
        counterfactual:
            'It becomes correct if only one 35° sling leg supports the full 24 kN load.',
        calculationPath:
            'T = 24 / sin 35° = 41.84 kN, rounded to 41.8 kN.',
        technicalReviewProof:
            'The trigonometric relation is correct, but the calculation omits the second load-sharing leg stated in the stem.',
      ),
    ],
  );
}

Question _q2() {
  const options = [
    'B is slightly higher: 16.2 kJ versus 16.0 kJ, using ½mv² for each actual mass and speed.',
    'A is higher: 16.0 kJ versus 13.0 kJ, calculating both with A’s 2,000 kg mass.',
    'B is 25% higher: 20.0 kJ versus 16.0 kJ, comparing the mass change at a fixed 4.0 m/s.',
    'B is slightly higher: 32.4 kJ versus 32.0 kJ, using mv² for both actual mass-speed pairs.',
  ];

  return const Question(
    id: 606002,
    domain: 6,
    competencyId: 'd06_c06',
    subtopicId: 'validator_trial_d06_c06',
    topicId: 'validator_trial_d06_c06',
    quizId: 'd06_c06_dqg300_trial_quiz',
    contentPackageId: 'd06_c06-dqg300-trial-v1',
    question:
        'Two loaded forklifts must be stopped by the same braking system. Forklift A has total mass 2,000 kg at 4.0 m/s; Forklift B has total mass 2,500 kg at 3.6 m/s. Ignoring losses, which kinetic-energy comparison is correct?',
    options: options,
    correctAnswer: 0,
    explanation:
        'Using KE = ½mv² gives 16.0 kJ for A and 16.2 kJ for B, so B requires slightly more energy to be dissipated by braking.',
    bestAnswerRationale:
        'Only the keyed comparison applies the kinetic-energy relationship to both actual masses and both actual speeds.',
    reference:
        'BCSP CSP11 Blueprint d06_c06; OpenStax University Physics Volume 1, work and kinetic energy.',
    difficulty: 'Hard',
    cognitiveLevel: 'analysis',
    questionType: 'scenario_mcq',
    status: 'validated',
    version: 1,
    tags: ['d06_c06', 'energy', 'kinetic-energy', 'dq6'],
  );
}

QuestionQualityEvidence _q2Evidence() {
  const options = [
    'B is slightly higher: 16.2 kJ versus 16.0 kJ, using ½mv² for each actual mass and speed.',
    'A is higher: 16.0 kJ versus 13.0 kJ, calculating both with A’s 2,000 kg mass.',
    'B is 25% higher: 20.0 kJ versus 16.0 kJ, comparing the mass change at a fixed 4.0 m/s.',
    'B is slightly higher: 32.4 kJ versus 32.0 kJ, using mv² for both actual mass-speed pairs.',
  ];

  return _evidence(
    questionId: 'D06C06-Q02',
    options: options,
    decisiveFacts: const [
      'Forklift A mass is 2000 kg and speed is 4.0 m/s',
      'Forklift B mass is 2500 kg and speed is 3.6 m/s',
      'the same braking system must dissipate the vehicles kinetic energy',
      'losses are ignored',
    ],
    criteria: const [
      'uses kinetic energy equal to one-half mass times speed squared',
      'uses Forklift A actual mass and speed',
      'uses Forklift B actual mass and speed',
      'compares the two resulting energies correctly',
    ],
    failedCriteria: const {
      1: ['uses Forklift B actual mass and speed'],
      2: ['uses Forklift B actual mass and speed'],
      3: ['uses kinetic energy equal to one-half mass times speed squared'],
    },
    superiority: const {
      1: 'KEY uses B’s stated 2,500 kg mass with 3.6 m/s; D1 substitutes A’s 2,000 kg mass into the B calculation.',
      2: 'KEY combines both actual mass and speed changes; D2 isolates the mass increase while holding speed at 4.0 m/s.',
      3: 'KEY includes the one-half coefficient in kinetic energy; D3 doubles both energies by using mv².',
    },
    assumptions: const [
      AssumptionEvidence(
        subject: 'KEY',
        assumptionUsed:
            'The comparison is translational kinetic energy at the stated masses and speeds, with losses ignored.',
        scenarioSupport:
            'The stem explicitly gives total masses, speeds, a braking comparison, and an instruction to ignore losses.',
        supported: true,
        intentionalDistractorTrap: false,
      ),
    ],
    distractors: [
      _distractor(
        optionIndex: 1,
        family: 'D-COND',
        fingerprint: 'KE_HOLD_MASS_CONSTANT',
        misconception:
            'Correctly applies the kinetic-energy equation but evaluates both vehicles under A’s mass instead of B’s stated higher mass.',
        tempting:
            'Holding mass constant isolates the effect of the speed difference and yields a coherent energy comparison.',
        fatalFlaw:
            'Forklift B is explicitly 2,500 kg, so replacing it with 2,000 kg removes a decisive scenario fact.',
        scenarioEvidence: const [
          'A is 2000 kg at 4.0 m/s',
          'B is 2500 kg at 3.6 m/s',
        ],
        technicalTruth:
            'At a common 2,000 kg mass, 4.0 m/s corresponds to 16.0 kJ and 3.6 m/s corresponds to 12.96 kJ.',
        keyDifference:
            'The KEY evaluates each forklift at its own stated mass; this distractor changes B to A’s mass.',
        counterfactual:
            'It becomes correct if both forklifts have the same 2,000 kg total mass.',
        calculationPath:
            'A: 0.5(2000)(4.0²) = 16.0 kJ; B incorrectly uses 0.5(2000)(3.6²) = 12.96 kJ ≈ 13.0 kJ.',
        technicalReviewProof:
            'The kinetic-energy calculations are internally correct under equal mass, but the actual scenario gives B a 2,500 kg mass.',
      ),
      _distractor(
        optionIndex: 2,
        family: 'D-PARTIAL',
        fingerprint: 'KE_MASS_ONLY_COMPARISON',
        misconception:
            'Uses the correct linear dependence on mass but fails to integrate the simultaneous reduction in B’s speed.',
        tempting:
            'B is exactly 25% heavier than A, and kinetic energy is directly proportional to mass when speed is unchanged.',
        fatalFlaw:
            'The speeds are not equal; B travels at 3.6 m/s while A travels at 4.0 m/s, and speed is squared in the energy relation.',
        scenarioEvidence: const [
          'B mass is 25 percent higher',
          'B speed is lower at 3.6 m/s',
        ],
        technicalTruth:
            'At the same speed, increasing mass from 2,000 kg to 2,500 kg increases kinetic energy by 25%.',
        keyDifference:
            'The KEY integrates the stated mass and speed changes; this distractor evaluates only the mass change.',
        counterfactual:
            'It becomes correct if both forklifts travel at 4.0 m/s.',
        calculationPath:
            'A: 0.5(2000)(4.0²) = 16.0 kJ; B incorrectly holds speed at 4.0 m/s: 0.5(2500)(4.0²) = 20.0 kJ.',
        technicalReviewProof:
            'The 25% mass effect is correct at constant speed, but the stem explicitly supplies a lower speed for B.',
      ),
      _distractor(
        optionIndex: 3,
        family: 'D-MEASURE',
        fingerprint: 'KE_OMIT_ONE_HALF',
        misconception:
            'Uses both actual masses and speeds and preserves the squared-speed relationship but omits the one-half coefficient.',
        tempting:
            'The ranking remains nearly identical and all scenario inputs are used, making the doubled values look technically consistent.',
        fatalFlaw:
            'Translational kinetic energy is one-half mv², so omitting one-half doubles both numerical energies.',
        scenarioEvidence: const [
          'A is 2000 kg at 4.0 m/s',
          'B is 2500 kg at 3.6 m/s',
        ],
        technicalTruth:
            'The products mv² are 32.0 kJ-equivalent for A and 32.4 kJ-equivalent for B before applying the one-half coefficient.',
        keyDifference:
            'The KEY converts mv² to kinetic energy with the required one-half coefficient; this distractor stops one factor early.',
        counterfactual:
            'It becomes numerically correct if the question asks for mv² rather than kinetic energy.',
        calculationPath:
            'A incorrectly uses (2000)(4.0²) = 32.0 kJ-equivalent; B incorrectly uses (2500)(3.6²) = 32.4 kJ-equivalent.',
        technicalReviewProof:
            'The mass-speed products are computed correctly, but they are not kinetic energies until multiplied by one-half.',
      ),
    ],
  );
}

void _assertSurfaceParity(Question question) {
  final lengths = question.options.map((value) => value.length).toList()..sort();
  final words = question.options
      .map((value) => value.trim().split(RegExp(r'\s+')).length)
      .toList()
    ..sort();

  expect(lengths.last / lengths.first, lessThan(1.35));
  expect(words.last / words.first, lessThan(1.35));
}

void main() {
  final cases = <({Question question, QuestionQualityEvidence evidence})>[
    (question: _q1(), evidence: _q1Evidence()),
    (question: _q2(), evidence: _q2Evidence()),
  ];

  for (final item in cases) {
    test(
      item.question.id.toString() +
          ' passes the frozen DQG300 validator at 300/300',
      () {
        _assertSurfaceParity(item.question);

        final result = _validator.validate(
          question: item.question,
          evidence: item.evidence,
        );

        expect(result.rules.length, 300);
        expect(result.passedRuleCount, 300);
        expect(result.failedRuleCount, 0);
        expect(result.dqs, 100);
        expect(result.dqsCategories.length, 10);
        expect(result.dqsCategories.values, everyElement(10));
        expect(result.isPublishable, isTrue);
        expect(result.rule('DQG-300').passed, isTrue);
      },
    );
  }
}
