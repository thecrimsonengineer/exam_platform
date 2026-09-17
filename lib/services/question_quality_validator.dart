import '../models/question.dart';
import '../models/question_quality_evidence.dart';
import '../models/question_quality_validation_result.dart';

class QuestionQualityValidator {
  static const List<String> ruleIds = [
    'DQG-001', 'DQG-002', 'DQG-003', 'DQG-004', 'DQG-005', 'DQG-006', 'DQG-007', 'DQG-008',
    'DQG-009', 'DQG-010', 'DQG-011', 'DQG-012', 'DQG-013', 'DQG-014', 'DQG-015', 'DQG-016',
    'DQG-017', 'DQG-018', 'DQG-019', 'DQG-020', 'DQG-021', 'DQG-022', 'DQG-023', 'DQG-024',
    'DQG-025', 'DQG-026', 'DQG-027', 'DQG-028', 'DQG-029', 'DQG-030', 'DQG-031', 'DQG-032',
    'DQG-033', 'DQG-034', 'DQG-035', 'DQG-036', 'DQG-037', 'DQG-038', 'DQG-039', 'DQG-040',
    'DQG-041', 'DQG-042', 'DQG-043', 'DQG-044', 'DQG-045', 'DQG-046', 'DQG-047', 'DQG-048',
    'DQG-049', 'DQG-050', 'DQG-051', 'DQG-052', 'DQG-053', 'DQG-054', 'DQG-055', 'DQG-056',
    'DQG-057', 'DQG-058', 'DQG-059', 'DQG-060', 'DQG-061', 'DQG-062', 'DQG-063', 'DQG-064',
  ];

  static const Set<String> _standardFamilies = {
    'D-COND',
    'D-SCOPE',
    'D-PRIORITY',
    'D-HIER',
    'D-CAUSE',
    'D-TIME',
    'D-METHOD',
    'D-ASSUME',
    'D-PARTIAL',
    'D-OVER',
    'D-UNDER',
    'D-CLASS',
    'D-MEASURE',
    'D-DENOM',
    'D-COMP',
    'D-SEQ',
    'D-STANDARD',
    'D-DEVICE',
    'D-THRESHOLD',
    'D-EXPOSURE',
    'D-EFFECT',
    'D-RELIAB',
    'D-HUMAN',
    'D-BARRIER',
    'D-LOPA',
    'D-FTA',
    'D-ETA',
  };

  static const Set<String> _keyCompletenessDimensions = {
    'hazard',
    'scope',
    'timing',
    'priority',
    'mechanism',
    'technicalPrinciple',
    'scenarioConditions',
    'commandWord',
    'calculation',
    'assumptions',
  };

  QuestionQualityValidationResult validate({
    required Question question,
    required QuestionQualityEvidence evidence,
  }) {
    final rules = <DqgRuleResult>[];

    void add(String id, bool passed, String message) {
      rules.add(DqgRuleResult(id: id, passed: passed, message: message));
    }

    final keyValid = question.correctAnswer >= 0 && question.correctAnswer < question.options.length;
    final expectedDistractorIndexes = keyValid
        ? <int>{for (var i = 0; i < question.options.length; i++) if (i != question.correctAnswer) i}
        : <int>{};
    final actualDistractorIndexes = evidence.distractors.map((d) => d.optionIndex).toSet();
    final sortedDistractors = [...evidence.distractors]
      ..sort((a, b) => a.optionIndex.compareTo(b.optionIndex));

    final dq6Pass = evidence.difficultyLevel == 'DQ6' &&
        evidence.distractors.every((d) => d.difficultyLevel == 'DQ6');
    final plausibilityPass = evidence.distractors.length == 3 &&
        evidence.distractors.every((d) => d.plausibilityScore == 5);
    final truthPass = evidence.distractors.length == 3 &&
        evidence.distractors.every((d) => d.truthComponentScore == 4);
    final confusabilityPass = evidence.distractors.length == 3 &&
        evidence.distractors.every((d) => d.confusabilityScore == 4);

    final dqsCategories = _computeDqsCategories(
      question: question,
      evidence: evidence,
    );
    final dqs = dqsCategories.values.fold<int>(0, (sum, value) => sum + value);

    add('DQG-001', question.options.length == 4, 'Exactly four answer options are required.');
    add('DQG-002', question.options.length == 4 && keyValid, 'Exactly one valid BEST-answer key is required.');
    add(
      'DQG-003',
      evidence.distractors.length == 3 &&
          actualDistractorIndexes.length == 3 &&
          actualDistractorIndexes.length == expectedDistractorIndexes.length &&
          actualDistractorIndexes.containsAll(expectedDistractorIndexes),
      'Exactly three distractors must map to the three non-key options.',
    );
    add('DQG-004', dq6Pass, 'DQ6 is mandatory for the question and every distractor.');
    add('DQG-005', plausibilityPass, 'Every distractor must score exactly 5/5 for plausibility.');
    add('DQG-006', truthPass, 'Every distractor must score exactly 4/4 for truth component.');
    add('DQG-007', confusabilityPass, 'Each KEY-to-distractor confusability score must be exactly 4/5.');
    add('DQG-008', dqs == 100, 'Computed DQS must equal exactly 100/100.');
    add('DQG-009', evidence.unresolvedBlockCount == 0, 'Unresolved block count must be zero.');
    add('DQG-010', evidence.unresolvedFailCount == 0, 'Unresolved fail count must be zero.');
    add('DQG-011', evidence.unresolvedWarningCount == 0, 'Unresolved warning count must be zero.');
    add('DQG-012', !evidence.manualOverrideRequested, 'Publication overrides are prohibited.');
    add('DQG-013', evidence.defensibleBestAnswerCount == 1, 'Exactly one answer may be defensible as BEST.');
    add('DQG-014', evidence.reviewComplete, 'The required review must be complete.');
    add('DQG-015', _mandatoryEvidenceComplete(question, evidence), 'All mandatory structured quality evidence must be present.');
    add(
      'DQG-016',
      dq6Pass && plausibilityPass && truthPass && confusabilityPass && dqs == 100,
      'Frozen thresholds are exact; no rounding or tolerance is permitted.',
    );
    add(
      'DQG-017',
      evidence.distractors.length == 3 && evidence.distractors.every((d) => d.role == 'expert_near_miss'),
      'Every distractor must be explicitly classified as expert_near_miss.',
    );
    add(
      'DQG-018',
      evidence.distractors.length == 3 &&
          evidence.distractors.every((d) => d.sameTechnicalUniverse && d.sameProfessionalLevel),
      'All distractors must occupy the same technical answer universe and professional level as the KEY.',
    );
    add(
      'DQG-019',
      evidence.distractors.length == 3 &&
          evidence.distractors.every(
            (d) => d.substantiallyTechnicallyCorrect &&
                d.professionalTerminologyValid &&
                d.addressesActualDecisionOrHazard,
          ),
      'Every distractor must be substantially technically correct, terminology-valid, and relevant.',
    );
    add(
      'DQG-020',
      evidence.distractors.length == 3 &&
          evidence.distractors.every((d) => d.singleFatalFlaw && _nonBlank(d.fatalFlaw)),
      'Every distractor must contain one dominant, documented fatal flaw.',
    );
    add(
      'DQG-021',
      evidence.distractors.length == 3 &&
          evidence.distractors.every((d) => !d.multipleUnrelatedDefectsDetected),
      'Distractors with multiple unrelated defects are prohibited.',
    );
    add(
      'DQG-022',
      evidence.distractors.length == 3 &&
          evidence.distractors.map((d) => d.family.trim()).toSet().length == 3,
      'The three distractors must use meaningfully distinct failure mechanisms/families.',
    );
    add(
      'DQG-023',
      evidence.distractors.length == 3 &&
          evidence.distractors.every((d) => _nonBlank(d.misconceptionFingerprint)) &&
          evidence.distractors.map((d) => d.misconceptionFingerprint.trim()).toSet().length == 3,
      'Misconception fingerprints must be present and unique.',
    );
    add(
      'DQG-024',
      evidence.distractors.length == 3 &&
          evidence.distractors.every((d) => d.sophisticatedReasoningPath && d.credibleInProfessionalPractice),
      'Every distractor must represent a sophisticated, professionally credible reasoning pathway.',
    );
    add('DQG-025', _allText(evidence.distractors, (d) => d.targetedMisconception), 'Each distractor requires a targeted misconception.');
    add('DQG-026', _allText(evidence.distractors, (d) => d.whyTempting), 'Each distractor requires a whyTempting rationale.');
    add('DQG-027', _allText(evidence.distractors, (d) => d.fatalFlaw), 'Each distractor requires a specific fatal-flaw explanation.');
    add(
      'DQG-028',
      evidence.distractors.length == 3 &&
          evidence.distractors.every(
            (d) => d.scenarioEvidence.isNotEmpty &&
                d.scenarioEvidence.every(_nonBlank) &&
                d.scenarioAnchorsValid,
          ),
      'Every distractor requires non-empty validated scenario anchors.',
    );
    add('DQG-029', _allText(evidence.distractors, (d) => d.technicalTruth), 'Each distractor must document its technical truth.');
    add('DQG-030', _allText(evidence.distractors, (d) => d.keyDifference), 'Each distractor must document its decisive difference from the KEY.');
    add('DQG-031', _allText(evidence.distractors, (d) => d.counterfactualToBecomeCorrect), 'Each distractor must document a counterfactual that would make it correct or defensible.');
    add(
      'DQG-032',
      evidence.distractors.length == 3 &&
          evidence.distractors.every(
            (d) => _standardFamilies.contains(d.family) || _nonBlank(d.familyJustification),
          ),
      'Every distractor family must be recognized or explicitly technically justified.',
    );
    add(
      'DQG-033',
      evidence.decisiveScenarioFacts.length >= 2 && evidence.decisiveScenarioFacts.every(_nonBlank),
      'DQ6 requires integration of at least two decisive scenario facts or technical conditions.',
    );
    add('DQG-034', _criterionMatrixComplete(evidence), 'The criterion matrix must be complete.');
    add('DQG-035', _keyComplete(evidence), 'The KEY must satisfy every material criterion and completeness dimension.');
    add('DQG-036', _distractorsFailDecisiveCriteria(evidence), 'Each distractor must fail at least one decisive material criterion.');
    add('DQG-037', _superiorityProofPresent(sortedDistractors, evidence, 0), 'Specific KEY>D1 superiority proof is required.');
    add('DQG-038', _superiorityProofPresent(sortedDistractors, evidence, 1), 'Specific KEY>D2 superiority proof is required.');
    add('DQG-039', _superiorityProofPresent(sortedDistractors, evidence, 2), 'Specific KEY>D3 superiority proof is required.');
    add(
      'DQG-040',
      evidence.distractors.length == 3 && evidence.distractors.every((d) => d.counterfactualMinimalAndPlausible),
      'Every distractor counterfactual must be minimal and plausible.',
    );
    add(
      'DQG-041',
      evidence.distractors.length == 3 &&
          evidence.distractors.every((d) => d.grammarParallel && d.sameProfessionalLevel),
      'Grammar, answer type, and professional-level parity are required.',
    );
    add(
      'DQG-042',
      evidence.distractors.length == 3 && evidence.distractors.every((d) => d.specificityAndDetailParallel),
      'Specificity and detail parity are required.',
    );
    add('DQG-043', _surfaceMetricsComplete(question, evidence), 'Surface metrics must be complete and no material length/clause cue may exist.');
    add(
      'DQG-044',
      evidence.distractors.length == 3 &&
          evidence.distractors.every((d) => d.terminologyUnitsPrecisionParallel && d.conditionalWordingParallel),
      'Terminology, units, numerical precision, and conditional wording must be parallel.',
    );
    add(
      'DQG-045',
      !evidence.answerPositionCueDetected &&
          evidence.distractors.length == 3 &&
          evidence.distractors.every((d) => !d.linguisticCueDetected),
      'Linguistic, formatting, and answer-position cues are prohibited.',
    );
    add('DQG-046', evidence.distractors.length == 3 && evidence.distractors.every((d) => !d.keywordLeakageDetected), 'KEY-specific keyword leakage is prohibited.');
    add('DQG-047', evidence.distractors.length == 3 && evidence.distractors.every((d) => !d.absoluteLanguageShortcutDetected), 'Certainty-language elimination shortcuts are prohibited.');
    add('DQG-048', evidence.distractors.length == 3 && evidence.distractors.every((d) => !d.nonTechnicalEliminationShortcutDetected), 'Every elimination must require subject knowledge or scenario reasoning.');
    add('DQG-049', evidence.keyRequiresNoUnstatedAssumption, 'The KEY may not require an unstated assumption.');
    add('DQG-050', _assumptionsControlled(evidence), 'Assumptions must be explicitly documented and KEY assumptions must be supported.');
    add('DQG-051', evidence.noEquivalenceFromUnstatedAssumption, 'Unstated assumptions may not make KEY and distractor equivalent.');
    add(
      'DQG-052',
      question.reference.trim().isNotEmpty &&
          evidence.authoritativeSources.isNotEmpty &&
          evidence.authoritativeSources.every(_nonBlank) &&
          evidence.sourceAuthorityVerified &&
          evidence.sourceSupportsKey,
      'At least one verified authoritative source must support the KEY.',
    );
    add('DQG-053', evidence.distractors.length == 3 && evidence.distractors.every((d) => d.sourceSupportsRejectionDistinction), 'Sources must support every distractor-rejection distinction.');
    add('DQG-054', evidence.noUnsupportedMicroscopicDistinction, 'Unsupported microscopic distinctions are prohibited.');
    add('DQG-055', !evidence.ambiguityDetected, 'No distractor may be equally defensible from the stated stem.');
    add('DQG-056', _allText(evidence.distractors, (d) => d.smeRejectionProof), 'Qualified-SME exact rejection proof is required for all distractors.');
    add('DQG-057', _optionsDistinct(question, evidence), 'Duplicate or semantically equivalent options are prohibited.');
    add('DQG-058', _numericProvenanceValid(evidence), 'Numerical distractors require valid reasoning provenance and consistent calculations.');
    add('DQG-059', evidence.answerKeyVerified && keyValid, 'The answer key must be independently verified and valid.');
    add('DQG-060', evidence.stemSufficient && question.question.trim().isNotEmpty, 'The stem must contain all information needed for the decision.');
    add('DQG-061', evidence.testsIntendedCompetency, 'The item must test the intended competency rather than trivia.');
    add(
      'DQG-062',
      !evidence.wrongLevelCorrectnessApplicable || evidence.wrongLevelDistinctionDocumented,
      'Wrong-level correctness requires a documented, technically defensible level distinction.',
    );
    add(
      'DQG-063',
      !evidence.sophisticationParityApplicable ||
          (evidence.sophisticationParitySatisfied && evidence.advancedDistractorPresentWhenApplicable),
      'Sophistication parity and an advanced-sounding distractor are required when applicable.',
    );

    final allPrecedingPass = rules.length == 63 && rules.every((rule) => rule.passed);
    final aggregatePass = allPrecedingPass && dqs == 100;
    add(
      'DQG-064',
      aggregatePass,
      'Publication is allowed only when DQG-001..063 all pass and computed DQS is exactly 100.',
    );

    final blockCount = rules.take(63).where((rule) => !rule.passed).length;

    return QuestionQualityValidationResult(
      status: aggregatePass ? QuestionQualityStatus.pass : QuestionQualityStatus.block,
      dqs: dqs,
      dqsCategories: dqsCategories,
      rules: List.unmodifiable(rules),
      blockCount: blockCount,
      failCount: evidence.unresolvedFailCount,
      warningCount: evidence.unresolvedWarningCount,
    );
  }

  Map<String, int> _computeDqsCategories({
    required Question question,
    required QuestionQualityEvidence evidence,
  }) {
    final categories = <String, bool>{
      'plausibility': evidence.distractors.length == 3 && evidence.distractors.every((d) => d.plausibilityScore == 5),
      'truth_component': evidence.distractors.length == 3 && evidence.distractors.every((d) => d.truthComponentScore == 4),
      'dq6_expert_near_miss': evidence.difficultyLevel == 'DQ6' && evidence.distractors.length == 3 && evidence.distractors.every((d) => d.difficultyLevel == 'DQ6' && d.role == 'expert_near_miss'),
      'scenario_integration': evidence.decisiveScenarioFacts.length >= 2 && _criterionMatrixComplete(evidence) && _keyComplete(evidence),
      'misconception_diversity': evidence.distractors.length == 3 && evidence.distractors.map((d) => d.family.trim()).toSet().length == 3 && evidence.distractors.map((d) => d.misconceptionFingerprint.trim()).toSet().length == 3,
      'single_fatal_flaw': evidence.distractors.length == 3 && evidence.distractors.every((d) => d.singleFatalFlaw && !d.multipleUnrelatedDefectsDetected && _nonBlank(d.fatalFlaw) && d.substantiallyTechnicallyCorrect),
      'pairwise_confusability': evidence.distractors.length == 3 && evidence.distractors.every((d) => d.confusabilityScore == 4),
      'surface_parity': evidence.distractors.length == 3 && evidence.distractors.every((d) => d.grammarParallel && d.specificityAndDetailParallel && d.lengthAndClauseParallel && d.terminologyUnitsPrecisionParallel && d.conditionalWordingParallel) && _surfaceMetricsComplete(question, evidence),
      'elimination_resistance': !evidence.answerPositionCueDetected && evidence.distractors.length == 3 && evidence.distractors.every((d) => !d.linguisticCueDetected && !d.keywordLeakageDetected && !d.absoluteLanguageShortcutDetected && !d.nonTechnicalEliminationShortcutDetected),
      'key_superiority_ambiguity': evidence.defensibleBestAnswerCount == 1 && !evidence.ambiguityDetected && evidence.distractors.length == 3 && evidence.distractors.every((d) => _nonBlank(evidence.keySuperiorityProof[d.optionIndex] ?? '') && _nonBlank(d.smeRejectionProof)),
    };

    return {
      for (final entry in categories.entries) entry.key: entry.value ? 10 : 0,
    };
  }

  bool _mandatoryEvidenceComplete(Question question, QuestionQualityEvidence evidence) {
    if (evidence.distractors.length != 3 || evidence.decisiveScenarioFacts.isEmpty || evidence.materialCriteria.isEmpty) {
      return false;
    }
    if (evidence.authoritativeSources.isEmpty || evidence.optionSurfaceMetrics.length != question.options.length) {
      return false;
    }
    if (!_keyCompletenessDimensions.every(evidence.keyCompleteness.containsKey)) {
      return false;
    }
    return evidence.distractors.every(
      (d) => _nonBlank(d.role) &&
          _nonBlank(d.difficultyLevel) &&
          _nonBlank(d.family) &&
          _nonBlank(d.misconceptionFingerprint) &&
          _nonBlank(d.targetedMisconception) &&
          _nonBlank(d.whyTempting) &&
          _nonBlank(d.fatalFlaw) &&
          d.scenarioEvidence.isNotEmpty &&
          d.scenarioEvidence.every(_nonBlank) &&
          _nonBlank(d.technicalTruth) &&
          _nonBlank(d.keyDifference) &&
          _nonBlank(d.counterfactualToBecomeCorrect) &&
          _nonBlank(d.smeRejectionProof) &&
          _nonBlank(evidence.keySuperiorityProof[d.optionIndex] ?? ''),
    );
  }

  bool _criterionMatrixComplete(QuestionQualityEvidence evidence) {
    if (!evidence.criterionMatrixComplete || evidence.materialCriteria.isEmpty || evidence.keySatisfiedCriteria.isEmpty || evidence.distractors.length != 3) {
      return false;
    }
    return evidence.distractors.every((d) => evidence.distractorFailedCriteria.containsKey(d.optionIndex));
  }

  bool _keyComplete(QuestionQualityEvidence evidence) {
    final material = evidence.materialCriteria.map((e) => e.trim()).toSet();
    final satisfied = evidence.keySatisfiedCriteria.map((e) => e.trim()).toSet();
    if (material.isEmpty || material.length != satisfied.length || !material.containsAll(satisfied)) {
      return false;
    }
    if (!_keyCompletenessDimensions.every(evidence.keyCompleteness.containsKey)) {
      return false;
    }
    return _keyCompletenessDimensions.every((key) => evidence.keyCompleteness[key] == true);
  }

  bool _distractorsFailDecisiveCriteria(QuestionQualityEvidence evidence) {
    if (evidence.distractors.length != 3) return false;
    final material = evidence.materialCriteria.toSet();
    return evidence.distractors.every((d) {
      final failed = evidence.distractorFailedCriteria[d.optionIndex];
      return failed != null && failed.isNotEmpty && failed.every(material.contains);
    });
  }

  bool _superiorityProofPresent(
    List<DistractorQualityEvidence> sorted,
    QuestionQualityEvidence evidence,
    int listIndex,
  ) {
    if (sorted.length != 3 || listIndex >= sorted.length) return false;
    return _nonBlank(evidence.keySuperiorityProof[sorted[listIndex].optionIndex] ?? '');
  }

  bool _surfaceMetricsComplete(Question question, QuestionQualityEvidence evidence) {
    if (!evidence.noMaterialLengthCue || evidence.optionSurfaceMetrics.length != question.options.length || question.options.length != 4) {
      return false;
    }
    final indexes = evidence.optionSurfaceMetrics.map((m) => m.optionIndex).toSet();
    if (indexes.length != 4 || !indexes.containsAll({0, 1, 2, 3})) return false;
    final metricsValid = evidence.optionSurfaceMetrics.every(
      (m) => m.characterCount > 0 &&
          m.wordCount > 0 &&
          m.clauseCount > 0 &&
          m.technicalTermCount >= 0 &&
          m.qualifierCount >= 0,
    );
    return metricsValid &&
        evidence.distractors.length == 3 &&
        evidence.distractors.every((d) => d.lengthAndClauseParallel);
  }

  bool _assumptionsControlled(QuestionQualityEvidence evidence) {
    if (!evidence.assumptionsDocumented || !evidence.keyAssumptionsSupported) return false;
    return evidence.assumptions.every((a) {
      if (!_nonBlank(a.subject) || !_nonBlank(a.assumptionUsed) || !_nonBlank(a.scenarioSupport)) {
        return false;
      }
      if (a.subject.trim().toLowerCase() == 'key' && !a.supported) return false;
      if (!a.supported && !a.intentionalDistractorTrap) return false;
      return true;
    });
  }

  bool _optionsDistinct(Question question, QuestionQualityEvidence evidence) {
    if (evidence.semanticDuplicateOptionsDetected) return false;
    final normalized = question.options
        .map((option) => option.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' '))
        .toList();
    return normalized.length == normalized.toSet().length;
  }

  bool _numericProvenanceValid(QuestionQualityEvidence evidence) {
    if (!evidence.numericQuestion) return true;
    return evidence.distractors.length == 3 &&
        evidence.distractors.every(
          (d) => _nonBlank(d.distractorCalculationPath) && d.calculationConsistent,
        );
  }

  bool _allText(
    List<DistractorQualityEvidence> distractors,
    String Function(DistractorQualityEvidence distractor) read,
  ) {
    return distractors.length == 3 && distractors.every((d) => _nonBlank(read(d)));
  }

  bool _nonBlank(String value) => value.trim().isNotEmpty;
}
