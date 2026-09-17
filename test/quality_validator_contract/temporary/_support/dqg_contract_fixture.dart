import 'package:exam_platform/models/question.dart';
import 'package:exam_platform/models/question_quality_evidence.dart';
import 'package:exam_platform/models/question_quality_validation_result.dart';
import 'package:exam_platform/services/question_quality_validator.dart';
import 'package:flutter_test/flutter_test.dart';

final contractValidator = QuestionQualityValidator();

Question perfectQuestion({
  List<String>? options,
  int? correctAnswer,
  String? stem,
}) {
  return Question(
    id: 700101,
    domain: 7,
    competencyId: 'd07_c01',
    subtopicId: 'd07_c01_s01',
    topicId: 'd07_c01_s01_t01',
    quizId: 'd07_c01-v1_d07_c01_01_quiz',
    contentPackageId: 'd07_c01-v1',
    question: stem ??
        'During dry sanding of a solvent-containing coating, particulate and residual organic-vapour exposure remain after engineering controls. Which respiratory-protection configuration BEST addresses the complete residual hazard profile?',
    options: options ??
        const [
          'Use a combination particulate and organic-vapour filter selected for the measured residual exposure.',
          'Use a particulate filter selected for the measured aerosol loading while retaining the existing facepiece.',
          'Use an organic-vapour cartridge with a shorter change schedule based on the measured vapour exposure.',
          'Use a higher-APF powered respirator while retaining organic-vapour-only filtration for the residual exposure.',
        ],
    correctAnswer: correctAnswer ?? 0,
    explanation: 'Both residual contaminant classes must be addressed by the selected respiratory-protection configuration.',
    bestAnswerRationale: 'The BEST option is the only one that covers both simultaneous residual contaminant classes without relying on an unsupported substitution.',
    reference: 'Authoritative respiratory-protection source verified by SME review.',
    difficulty: 'Hard',
    cognitiveLevel: 'analysis',
    questionType: 'scenario_mcq',
    status: 'validated',
    version: 1,
    tags: const ['respiratory-protection', 'hazard-control', 'dq6'],
  );
}

DistractorQualityEvidence perfectDistractor(int index) {
  switch (index) {
    case 0:
      return const DistractorQualityEvidence(
        optionIndex: 1,
        role: 'expert_near_miss',
        difficultyLevel: 'DQ6',
        plausibilityScore: 5,
        truthComponentScore: 4,
        confusabilityScore: 4,
        family: 'D-PARTIAL',
        familyJustification: '',
        misconceptionFingerprint: 'PARTICULATE_ONLY_INTEGRATION',
        targetedMisconception: 'Correctly identifies sanding aerosol but fails to integrate simultaneous residual vapour exposure.',
        whyTempting: 'Dry sanding strongly cues particulate filtration and the existing facepiece remains a plausible platform.',
        fatalFlaw: 'The filtration omits the simultaneously stated residual organic-vapour hazard.',
        scenarioEvidence: ['dry sanding creates particulate', 'residual organic vapour remains'],
        scenarioAnchorsValid: true,
        technicalTruth: 'A suitable particulate filter is a legitimate component of respiratory protection for sanding aerosol.',
        keyDifference: 'The KEY covers both stated contaminant classes whereas this option covers particulate only.',
        counterfactualToBecomeCorrect: 'It becomes defensible if verified assessment shows no residual organic-vapour exposure.',
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
        smeRejectionProof: 'SME confirms particulate suitability is true but incomplete because simultaneous vapour exposure remains.',
        calculationConsistent: true,
      );
    case 1:
      return const DistractorQualityEvidence(
        optionIndex: 2,
        role: 'expert_near_miss',
        difficultyLevel: 'DQ6',
        plausibilityScore: 5,
        truthComponentScore: 4,
        confusabilityScore: 4,
        family: 'D-PRIORITY',
        familyJustification: '',
        misconceptionFingerprint: 'VAPOUR_CHANGE_SCHEDULE_OVER_COVERAGE',
        targetedMisconception: 'Optimises cartridge management before confirming complete contaminant coverage.',
        whyTempting: 'A change schedule is a legitimate vapour-cartridge management requirement and appears technically rigorous.',
        fatalFlaw: 'A more rigorous vapour-cartridge schedule does not provide particulate filtration.',
        scenarioEvidence: ['residual organic vapour remains', 'dry sanding creates particulate'],
        scenarioAnchorsValid: true,
        technicalTruth: 'Organic-vapour cartridges may require an exposure-informed change schedule.',
        keyDifference: 'The KEY addresses hazard coverage first; this option optimises one valid component while leaving the second contaminant unaddressed.',
        counterfactualToBecomeCorrect: 'It becomes defensible if particulate exposure is eliminated and vapour-cartridge service life is the remaining selection issue.',
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
        smeRejectionProof: 'SME confirms change schedules are valid for vapour cartridges but cannot substitute for particulate protection.',
        calculationConsistent: true,
      );
    default:
      return const DistractorQualityEvidence(
        optionIndex: 3,
        role: 'expert_near_miss',
        difficultyLevel: 'DQ6',
        plausibilityScore: 5,
        truthComponentScore: 4,
        confusabilityScore: 4,
        family: 'D-ASSUME',
        familyJustification: '',
        misconceptionFingerprint: 'APF_COMPENSATES_FOR_FILTER_MISMATCH',
        targetedMisconception: 'Assumes a higher protection factor can compensate for filtration that does not address every contaminant class.',
        whyTempting: 'A powered respirator and higher APF sound more protective and are legitimate selection considerations.',
        fatalFlaw: 'Higher APF does not make organic-vapour-only filtration suitable for the stated particulate exposure.',
        scenarioEvidence: ['simultaneous particulate and vapour exposure', 'respiratory protection remains necessary'],
        scenarioAnchorsValid: true,
        technicalTruth: 'APF is a legitimate respiratory-protection selection parameter and powered respirators may provide higher protection.',
        keyDifference: 'The KEY first provides suitable filtration for both contaminants; this option increases protection factor while retaining a filter mismatch.',
        counterfactualToBecomeCorrect: 'It becomes defensible if filtration already covers both contaminants and inadequate APF is the remaining limitation.',
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
        smeRejectionProof: 'SME confirms APF is relevant but cannot cure an unsuitable filtration class.',
        calculationConsistent: true,
      );
  }
}

QuestionQualityEvidence perfectEvidence({
  List<DistractorQualityEvidence>? distractors,
}) {
  return QuestionQualityEvidence(
    difficultyLevel: 'DQ6',
    distractors: distractors ??
        [perfectDistractor(0), perfectDistractor(1), perfectDistractor(2)],
    decisiveScenarioFacts: const [
      'dry sanding creates particulate',
      'residual organic vapour remains',
      'respiratory protection remains necessary',
    ],
    materialCriteria: const [
      'addresses particulate',
      'addresses organic vapour',
      'uses suitable respiratory-protection principle',
      'does not rely on unsupported substitution',
    ],
    keySatisfiedCriteria: const [
      'addresses particulate',
      'addresses organic vapour',
      'uses suitable respiratory-protection principle',
      'does not rely on unsupported substitution',
    ],
    distractorFailedCriteria: const {
      1: ['addresses organic vapour'],
      2: ['addresses particulate'],
      3: ['addresses particulate', 'does not rely on unsupported substitution'],
    },
    criterionMatrixComplete: true,
    keySuperiorityProof: const {
      1: 'KEY covers particulate and vapour; D1 omits residual vapour coverage.',
      2: 'KEY covers both contaminant classes; D2 optimises vapour cartridge management while omitting particulate filtration.',
      3: 'KEY provides suitable filtration; D3 increases APF without correcting the filtration mismatch.',
    },
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
    assumptions: const [
      AssumptionEvidence(
        subject: 'D3',
        assumptionUsed: 'Higher APF can compensate for a missing particulate-filtration function.',
        scenarioSupport: 'The scenario provides no support for that substitution and explicitly retains particulate exposure.',
        supported: false,
        intentionalDistractorTrap: true,
      ),
    ],
    authoritativeSources: const ['Authoritative respiratory-protection source verified by SME review.'],
    sourceAuthorityVerified: true,
    sourceSupportsKey: true,
    noUnsupportedMicroscopicDistinction: true,
    ambiguityDetected: false,
    semanticDuplicateOptionsDetected: false,
    answerPositionCueDetected: false,
    answerKeyVerified: true,
    stemSufficient: true,
    testsIntendedCompetency: true,
    numericQuestion: false,
    wrongLevelCorrectnessApplicable: false,
    wrongLevelDistinctionDocumented: true,
    sophisticationParityApplicable: true,
    sophisticationParitySatisfied: true,
    advancedDistractorPresentWhenApplicable: true,
    optionSurfaceMetrics: const [
      OptionSurfaceMetrics(optionIndex: 0, characterCount: 104, wordCount: 15, clauseCount: 1, technicalTermCount: 5, qualifierCount: 2),
      OptionSurfaceMetrics(optionIndex: 1, characterCount: 105, wordCount: 16, clauseCount: 1, technicalTermCount: 5, qualifierCount: 2),
      OptionSurfaceMetrics(optionIndex: 2, characterCount: 106, wordCount: 16, clauseCount: 1, technicalTermCount: 5, qualifierCount: 2),
      OptionSurfaceMetrics(optionIndex: 3, characterCount: 110, wordCount: 17, clauseCount: 1, technicalTermCount: 5, qualifierCount: 2),
    ],
    noMaterialLengthCue: true,
  );
}

QuestionQualityEvidence replaceDistractor(
  QuestionQualityEvidence evidence,
  int listIndex,
  DistractorQualityEvidence replacement,
) {
  final updated = [...evidence.distractors];
  updated[listIndex] = replacement;
  return evidence.copyWith(distractors: updated);
}

QuestionQualityValidationResult validateContract({
  Question? question,
  QuestionQualityEvidence? evidence,
}) {
  return contractValidator.validate(
    question: question ?? perfectQuestion(),
    evidence: evidence ?? perfectEvidence(),
  );
}

void expectBlockedBy(
  String ruleId, {
  Question? question,
  QuestionQualityEvidence? evidence,
}) {
  final result = validateContract(question: question, evidence: evidence);
  expect(result.rule(ruleId).passed, isFalse, reason: '$ruleId must block');
  expect(result.isPublishable, isFalse);
  expect(result.status, QuestionQualityStatus.block);
  expect(result.rule('DQG-064').passed, isFalse);
}
