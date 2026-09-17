class AssumptionEvidence {
  final String subject;
  final String assumptionUsed;
  final String scenarioSupport;
  final bool supported;
  final bool intentionalDistractorTrap;

  const AssumptionEvidence({
    required this.subject,
    required this.assumptionUsed,
    required this.scenarioSupport,
    required this.supported,
    required this.intentionalDistractorTrap,
  });
}

class OptionSurfaceMetrics {
  final int optionIndex;
  final int characterCount;
  final int wordCount;
  final int clauseCount;
  final int technicalTermCount;
  final int qualifierCount;

  const OptionSurfaceMetrics({
    required this.optionIndex,
    required this.characterCount,
    required this.wordCount,
    required this.clauseCount,
    required this.technicalTermCount,
    required this.qualifierCount,
  });
}

class DistractorQualityEvidence {
  final int optionIndex;
  final String role;
  final String difficultyLevel;
  final int plausibilityScore;
  final int truthComponentScore;
  final int confusabilityScore;
  final String family;
  final String familyJustification;
  final String misconceptionFingerprint;
  final String targetedMisconception;
  final String whyTempting;
  final String fatalFlaw;
  final List<String> scenarioEvidence;
  final bool scenarioAnchorsValid;
  final String technicalTruth;
  final String keyDifference;
  final String counterfactualToBecomeCorrect;
  final bool sameTechnicalUniverse;
  final bool sameProfessionalLevel;
  final bool substantiallyTechnicallyCorrect;
  final bool professionalTerminologyValid;
  final bool addressesActualDecisionOrHazard;
  final bool credibleInProfessionalPractice;
  final bool singleFatalFlaw;
  final bool multipleUnrelatedDefectsDetected;
  final bool sophisticatedReasoningPath;
  final bool counterfactualMinimalAndPlausible;
  final bool grammarParallel;
  final bool specificityAndDetailParallel;
  final bool lengthAndClauseParallel;
  final bool terminologyUnitsPrecisionParallel;
  final bool conditionalWordingParallel;
  final bool linguisticCueDetected;
  final bool keywordLeakageDetected;
  final bool absoluteLanguageShortcutDetected;
  final bool nonTechnicalEliminationShortcutDetected;
  final bool sourceSupportsRejectionDistinction;
  final String smeRejectionProof;
  final String distractorCalculationPath;
  final bool calculationConsistent;

  const DistractorQualityEvidence({
    required this.optionIndex,
    required this.role,
    required this.difficultyLevel,
    required this.plausibilityScore,
    required this.truthComponentScore,
    required this.confusabilityScore,
    required this.family,
    this.familyJustification = '',
    required this.misconceptionFingerprint,
    required this.targetedMisconception,
    required this.whyTempting,
    required this.fatalFlaw,
    required this.scenarioEvidence,
    required this.scenarioAnchorsValid,
    required this.technicalTruth,
    required this.keyDifference,
    required this.counterfactualToBecomeCorrect,
    required this.sameTechnicalUniverse,
    required this.sameProfessionalLevel,
    required this.substantiallyTechnicallyCorrect,
    required this.professionalTerminologyValid,
    required this.addressesActualDecisionOrHazard,
    required this.credibleInProfessionalPractice,
    required this.singleFatalFlaw,
    required this.multipleUnrelatedDefectsDetected,
    required this.sophisticatedReasoningPath,
    required this.counterfactualMinimalAndPlausible,
    required this.grammarParallel,
    required this.specificityAndDetailParallel,
    required this.lengthAndClauseParallel,
    required this.terminologyUnitsPrecisionParallel,
    required this.conditionalWordingParallel,
    required this.linguisticCueDetected,
    required this.keywordLeakageDetected,
    required this.absoluteLanguageShortcutDetected,
    required this.nonTechnicalEliminationShortcutDetected,
    required this.sourceSupportsRejectionDistinction,
    required this.smeRejectionProof,
    this.distractorCalculationPath = '',
    required this.calculationConsistent,
  });

  DistractorQualityEvidence copyWith({
    int? optionIndex,
    String? role,
    String? difficultyLevel,
    int? plausibilityScore,
    int? truthComponentScore,
    int? confusabilityScore,
    String? family,
    String? familyJustification,
    String? misconceptionFingerprint,
    String? targetedMisconception,
    String? whyTempting,
    String? fatalFlaw,
    List<String>? scenarioEvidence,
    bool? scenarioAnchorsValid,
    String? technicalTruth,
    String? keyDifference,
    String? counterfactualToBecomeCorrect,
    bool? sameTechnicalUniverse,
    bool? sameProfessionalLevel,
    bool? substantiallyTechnicallyCorrect,
    bool? professionalTerminologyValid,
    bool? addressesActualDecisionOrHazard,
    bool? credibleInProfessionalPractice,
    bool? singleFatalFlaw,
    bool? multipleUnrelatedDefectsDetected,
    bool? sophisticatedReasoningPath,
    bool? counterfactualMinimalAndPlausible,
    bool? grammarParallel,
    bool? specificityAndDetailParallel,
    bool? lengthAndClauseParallel,
    bool? terminologyUnitsPrecisionParallel,
    bool? conditionalWordingParallel,
    bool? linguisticCueDetected,
    bool? keywordLeakageDetected,
    bool? absoluteLanguageShortcutDetected,
    bool? nonTechnicalEliminationShortcutDetected,
    bool? sourceSupportsRejectionDistinction,
    String? smeRejectionProof,
    String? distractorCalculationPath,
    bool? calculationConsistent,
  }) {
    return DistractorQualityEvidence(
      optionIndex: optionIndex ?? this.optionIndex,
      role: role ?? this.role,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      plausibilityScore: plausibilityScore ?? this.plausibilityScore,
      truthComponentScore: truthComponentScore ?? this.truthComponentScore,
      confusabilityScore: confusabilityScore ?? this.confusabilityScore,
      family: family ?? this.family,
      familyJustification: familyJustification ?? this.familyJustification,
      misconceptionFingerprint: misconceptionFingerprint ?? this.misconceptionFingerprint,
      targetedMisconception: targetedMisconception ?? this.targetedMisconception,
      whyTempting: whyTempting ?? this.whyTempting,
      fatalFlaw: fatalFlaw ?? this.fatalFlaw,
      scenarioEvidence: scenarioEvidence ?? this.scenarioEvidence,
      scenarioAnchorsValid: scenarioAnchorsValid ?? this.scenarioAnchorsValid,
      technicalTruth: technicalTruth ?? this.technicalTruth,
      keyDifference: keyDifference ?? this.keyDifference,
      counterfactualToBecomeCorrect: counterfactualToBecomeCorrect ?? this.counterfactualToBecomeCorrect,
      sameTechnicalUniverse: sameTechnicalUniverse ?? this.sameTechnicalUniverse,
      sameProfessionalLevel: sameProfessionalLevel ?? this.sameProfessionalLevel,
      substantiallyTechnicallyCorrect: substantiallyTechnicallyCorrect ?? this.substantiallyTechnicallyCorrect,
      professionalTerminologyValid: professionalTerminologyValid ?? this.professionalTerminologyValid,
      addressesActualDecisionOrHazard: addressesActualDecisionOrHazard ?? this.addressesActualDecisionOrHazard,
      credibleInProfessionalPractice: credibleInProfessionalPractice ?? this.credibleInProfessionalPractice,
      singleFatalFlaw: singleFatalFlaw ?? this.singleFatalFlaw,
      multipleUnrelatedDefectsDetected: multipleUnrelatedDefectsDetected ?? this.multipleUnrelatedDefectsDetected,
      sophisticatedReasoningPath: sophisticatedReasoningPath ?? this.sophisticatedReasoningPath,
      counterfactualMinimalAndPlausible: counterfactualMinimalAndPlausible ?? this.counterfactualMinimalAndPlausible,
      grammarParallel: grammarParallel ?? this.grammarParallel,
      specificityAndDetailParallel: specificityAndDetailParallel ?? this.specificityAndDetailParallel,
      lengthAndClauseParallel: lengthAndClauseParallel ?? this.lengthAndClauseParallel,
      terminologyUnitsPrecisionParallel: terminologyUnitsPrecisionParallel ?? this.terminologyUnitsPrecisionParallel,
      conditionalWordingParallel: conditionalWordingParallel ?? this.conditionalWordingParallel,
      linguisticCueDetected: linguisticCueDetected ?? this.linguisticCueDetected,
      keywordLeakageDetected: keywordLeakageDetected ?? this.keywordLeakageDetected,
      absoluteLanguageShortcutDetected: absoluteLanguageShortcutDetected ?? this.absoluteLanguageShortcutDetected,
      nonTechnicalEliminationShortcutDetected: nonTechnicalEliminationShortcutDetected ?? this.nonTechnicalEliminationShortcutDetected,
      sourceSupportsRejectionDistinction: sourceSupportsRejectionDistinction ?? this.sourceSupportsRejectionDistinction,
      smeRejectionProof: smeRejectionProof ?? this.smeRejectionProof,
      distractorCalculationPath: distractorCalculationPath ?? this.distractorCalculationPath,
      calculationConsistent: calculationConsistent ?? this.calculationConsistent,
    );
  }
}

class QuestionQualityEvidence {
  final String difficultyLevel;
  final List<DistractorQualityEvidence> distractors;
  final List<String> decisiveScenarioFacts;
  final List<String> materialCriteria;
  final List<String> keySatisfiedCriteria;
  final Map<int, List<String>> distractorFailedCriteria;
  final bool criterionMatrixComplete;
  final Map<int, String> keySuperiorityProof;
  final Map<String, bool> keyCompleteness;
  final int defensibleBestAnswerCount;
  final bool reviewComplete;
  final bool manualOverrideRequested;
  final int unresolvedBlockCount;
  final int unresolvedFailCount;
  final int unresolvedWarningCount;
  final bool keyRequiresNoUnstatedAssumption;
  final bool assumptionsDocumented;
  final bool keyAssumptionsSupported;
  final bool noEquivalenceFromUnstatedAssumption;
  final List<AssumptionEvidence> assumptions;
  final List<String> authoritativeSources;
  final bool sourceAuthorityVerified;
  final bool sourceSupportsKey;
  final bool noUnsupportedMicroscopicDistinction;
  final bool ambiguityDetected;
  final bool semanticDuplicateOptionsDetected;
  final bool answerPositionCueDetected;
  final bool answerKeyVerified;
  final bool stemSufficient;
  final bool testsIntendedCompetency;
  final bool numericQuestion;
  final bool wrongLevelCorrectnessApplicable;
  final bool wrongLevelDistinctionDocumented;
  final bool sophisticationParityApplicable;
  final bool sophisticationParitySatisfied;
  final bool advancedDistractorPresentWhenApplicable;
  final List<OptionSurfaceMetrics> optionSurfaceMetrics;
  final bool noMaterialLengthCue;

  const QuestionQualityEvidence({
    required this.difficultyLevel,
    required this.distractors,
    required this.decisiveScenarioFacts,
    required this.materialCriteria,
    required this.keySatisfiedCriteria,
    required this.distractorFailedCriteria,
    required this.criterionMatrixComplete,
    required this.keySuperiorityProof,
    required this.keyCompleteness,
    required this.defensibleBestAnswerCount,
    required this.reviewComplete,
    required this.manualOverrideRequested,
    required this.unresolvedBlockCount,
    required this.unresolvedFailCount,
    required this.unresolvedWarningCount,
    required this.keyRequiresNoUnstatedAssumption,
    required this.assumptionsDocumented,
    required this.keyAssumptionsSupported,
    required this.noEquivalenceFromUnstatedAssumption,
    required this.assumptions,
    required this.authoritativeSources,
    required this.sourceAuthorityVerified,
    required this.sourceSupportsKey,
    required this.noUnsupportedMicroscopicDistinction,
    required this.ambiguityDetected,
    required this.semanticDuplicateOptionsDetected,
    required this.answerPositionCueDetected,
    required this.answerKeyVerified,
    required this.stemSufficient,
    required this.testsIntendedCompetency,
    required this.numericQuestion,
    required this.wrongLevelCorrectnessApplicable,
    required this.wrongLevelDistinctionDocumented,
    required this.sophisticationParityApplicable,
    required this.sophisticationParitySatisfied,
    required this.advancedDistractorPresentWhenApplicable,
    required this.optionSurfaceMetrics,
    required this.noMaterialLengthCue,
  });

  QuestionQualityEvidence copyWith({
    String? difficultyLevel,
    List<DistractorQualityEvidence>? distractors,
    List<String>? decisiveScenarioFacts,
    List<String>? materialCriteria,
    List<String>? keySatisfiedCriteria,
    Map<int, List<String>>? distractorFailedCriteria,
    bool? criterionMatrixComplete,
    Map<int, String>? keySuperiorityProof,
    Map<String, bool>? keyCompleteness,
    int? defensibleBestAnswerCount,
    bool? reviewComplete,
    bool? manualOverrideRequested,
    int? unresolvedBlockCount,
    int? unresolvedFailCount,
    int? unresolvedWarningCount,
    bool? keyRequiresNoUnstatedAssumption,
    bool? assumptionsDocumented,
    bool? keyAssumptionsSupported,
    bool? noEquivalenceFromUnstatedAssumption,
    List<AssumptionEvidence>? assumptions,
    List<String>? authoritativeSources,
    bool? sourceAuthorityVerified,
    bool? sourceSupportsKey,
    bool? noUnsupportedMicroscopicDistinction,
    bool? ambiguityDetected,
    bool? semanticDuplicateOptionsDetected,
    bool? answerPositionCueDetected,
    bool? answerKeyVerified,
    bool? stemSufficient,
    bool? testsIntendedCompetency,
    bool? numericQuestion,
    bool? wrongLevelCorrectnessApplicable,
    bool? wrongLevelDistinctionDocumented,
    bool? sophisticationParityApplicable,
    bool? sophisticationParitySatisfied,
    bool? advancedDistractorPresentWhenApplicable,
    List<OptionSurfaceMetrics>? optionSurfaceMetrics,
    bool? noMaterialLengthCue,
  }) {
    return QuestionQualityEvidence(
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      distractors: distractors ?? this.distractors,
      decisiveScenarioFacts: decisiveScenarioFacts ?? this.decisiveScenarioFacts,
      materialCriteria: materialCriteria ?? this.materialCriteria,
      keySatisfiedCriteria: keySatisfiedCriteria ?? this.keySatisfiedCriteria,
      distractorFailedCriteria: distractorFailedCriteria ?? this.distractorFailedCriteria,
      criterionMatrixComplete: criterionMatrixComplete ?? this.criterionMatrixComplete,
      keySuperiorityProof: keySuperiorityProof ?? this.keySuperiorityProof,
      keyCompleteness: keyCompleteness ?? this.keyCompleteness,
      defensibleBestAnswerCount: defensibleBestAnswerCount ?? this.defensibleBestAnswerCount,
      reviewComplete: reviewComplete ?? this.reviewComplete,
      manualOverrideRequested: manualOverrideRequested ?? this.manualOverrideRequested,
      unresolvedBlockCount: unresolvedBlockCount ?? this.unresolvedBlockCount,
      unresolvedFailCount: unresolvedFailCount ?? this.unresolvedFailCount,
      unresolvedWarningCount: unresolvedWarningCount ?? this.unresolvedWarningCount,
      keyRequiresNoUnstatedAssumption: keyRequiresNoUnstatedAssumption ?? this.keyRequiresNoUnstatedAssumption,
      assumptionsDocumented: assumptionsDocumented ?? this.assumptionsDocumented,
      keyAssumptionsSupported: keyAssumptionsSupported ?? this.keyAssumptionsSupported,
      noEquivalenceFromUnstatedAssumption: noEquivalenceFromUnstatedAssumption ?? this.noEquivalenceFromUnstatedAssumption,
      assumptions: assumptions ?? this.assumptions,
      authoritativeSources: authoritativeSources ?? this.authoritativeSources,
      sourceAuthorityVerified: sourceAuthorityVerified ?? this.sourceAuthorityVerified,
      sourceSupportsKey: sourceSupportsKey ?? this.sourceSupportsKey,
      noUnsupportedMicroscopicDistinction: noUnsupportedMicroscopicDistinction ?? this.noUnsupportedMicroscopicDistinction,
      ambiguityDetected: ambiguityDetected ?? this.ambiguityDetected,
      semanticDuplicateOptionsDetected: semanticDuplicateOptionsDetected ?? this.semanticDuplicateOptionsDetected,
      answerPositionCueDetected: answerPositionCueDetected ?? this.answerPositionCueDetected,
      answerKeyVerified: answerKeyVerified ?? this.answerKeyVerified,
      stemSufficient: stemSufficient ?? this.stemSufficient,
      testsIntendedCompetency: testsIntendedCompetency ?? this.testsIntendedCompetency,
      numericQuestion: numericQuestion ?? this.numericQuestion,
      wrongLevelCorrectnessApplicable: wrongLevelCorrectnessApplicable ?? this.wrongLevelCorrectnessApplicable,
      wrongLevelDistinctionDocumented: wrongLevelDistinctionDocumented ?? this.wrongLevelDistinctionDocumented,
      sophisticationParityApplicable: sophisticationParityApplicable ?? this.sophisticationParityApplicable,
      sophisticationParitySatisfied: sophisticationParitySatisfied ?? this.sophisticationParitySatisfied,
      advancedDistractorPresentWhenApplicable: advancedDistractorPresentWhenApplicable ?? this.advancedDistractorPresentWhenApplicable,
      optionSurfaceMetrics: optionSurfaceMetrics ?? this.optionSurfaceMetrics,
      noMaterialLengthCue: noMaterialLengthCue ?? this.noMaterialLengthCue,
    );
  }
}
