import '../models/question.dart';
import '../models/question_quality_evidence.dart';
import '../models/question_quality_validation_result.dart';

/// Strict CSP11 DQG300 validator.
///
/// Semantic requirements are supplied as structured rule evidence. Deterministic
/// requirements are checked again from the question/evidence fields. A review
/// record can never override a failed deterministic predicate.
class Dqg300QuestionQualityValidator {
  const Dqg300QuestionQualityValidator();

  static const String contractVersion = 'DQG300-STEP1-CLOSED';
  static const String pinnedSourceSpecificationBlob =
      '68b4fe0a132c8cc7ebd095aa7340a6ee4bb29b4b';
  static const String pinnedRuleMatrixBlob =
      '2927a23e24e6fc274629851a15110ba602d927a0';
  static const bool publicationOverrideSupported = false;

  static final RegExp _genericSuperiority = RegExp(
    r'^(less appropriate|not the best answer|incorrect)\.?$',
    caseSensitive: false,
  );

  QuestionQualityValidationResult validate({
    required Question question,
    required QuestionQualityEvidence evidence,
  }) {
    final e = evidence;
    final options = question.options.map((value) => value.trim()).toList();
    final options4 = options.length == 4;
    final keyValid =
        options4 && question.correctAnswer >= 0 && question.correctAnswer < 4;

    final nonKeyIndexes = <int>{};
    if (keyValid) {
      nonKeyIndexes.addAll(const {0, 1, 2, 3});
      nonKeyIndexes.remove(question.correctAnswer);
    }

    final distractorIndexes = e.distractors.map((d) => d.optionIndex).toSet();
    final distractorsMatch =
        e.distractors.length == 3 &&
        distractorIndexes.length == 3 &&
        distractorIndexes.difference(nonKeyIndexes).isEmpty &&
        nonKeyIndexes.difference(distractorIndexes).isEmpty;

    bool allD(bool Function(DistractorQualityEvidence d) predicate) =>
        e.distractors.length == 3 && e.distractors.every(predicate);

    final allExpertNearMiss = allD((d) => d.role == 'expert_near_miss');
    final allCredible = allD(
      (d) =>
          d.credibleInProfessionalPractice &&
          d.substantiallyTechnicallyCorrect &&
          d.sophisticatedReasoningPath,
    );
    final oneDefensible = e.defensibleBestAnswerCount == 1;
    final dq6 =
        e.difficultyLevel == 'DQ6' &&
        allD((d) => d.difficultyLevel == 'DQ6');
    final multiFact =
        e.decisiveScenarioFacts.where((x) => x.trim().isNotEmpty).length >= 2;
    final literalOptionsUnique =
        options.map(_normalize).toSet().length == options.length;
    final noFiller =
        options4 &&
        options.every((value) => value.isNotEmpty) &&
        allD(
          (d) =>
              d.whyTempting.trim().isNotEmpty &&
              d.technicalTruth.trim().isNotEmpty,
        );
    final noShortcut =
        e.stemSufficient &&
        !e.ambiguityDetected &&
        !e.answerPositionCueDetected &&
        allD(
          (d) =>
              !d.linguisticCueDetected &&
              !d.keywordLeakageDetected &&
              !d.absoluteLanguageShortcutDetected &&
              !d.nonTechnicalEliminationShortcutDetected,
        );
    final distinctFamilies =
        e.distractors.map((d) => d.family.trim()).toSet().length == 3;
    final distinctFingerprints =
        e.distractors
                .map((d) => d.misconceptionFingerprint.trim())
                .where((x) => x.isNotEmpty)
                .toSet()
                .length ==
            3;
    final familiesValid = allD(_familyValid);
    final metadataComplete = allD(
      (d) =>
          d.role == 'expert_near_miss' &&
          d.difficultyLevel == 'DQ6' &&
          d.plausibilityScore == 5 &&
          d.truthComponentScore == 4 &&
          d.family.trim().isNotEmpty &&
          d.targetedMisconception.trim().isNotEmpty &&
          d.whyTempting.trim().isNotEmpty &&
          d.fatalFlaw.trim().isNotEmpty &&
          d.scenarioEvidence.isNotEmpty &&
          d.technicalTruth.trim().isNotEmpty &&
          d.keyDifference.trim().isNotEmpty &&
          d.counterfactualToBecomeCorrect.trim().isNotEmpty &&
          d.misconceptionFingerprint.trim().isNotEmpty,
    );
    final keyAllCriteria =
        e.materialCriteria.isNotEmpty &&
        e.keySatisfiedCriteria.toSet().containsAll(e.materialCriteria) &&
        e.keyCompleteness.isNotEmpty &&
        e.keyCompleteness.values.every((value) => value);
    final distractorCriteriaComplete =
        distractorsMatch &&
        nonKeyIndexes.every(
          (index) => e.distractorFailedCriteria[index]?.isNotEmpty == true,
        );

    bool proofFor(int optionIndex) {
      final value = e.keySuperiorityProof[optionIndex]?.trim() ?? '';
      return value.isNotEmpty && !_genericSuperiority.hasMatch(value);
    }

    final superiorityComplete = distractorsMatch && nonKeyIndexes.every(proofFor);
    final superioritySpecific =
        superiorityComplete &&
        e.keySuperiorityProof.values.every(
          (value) => value.trim().split(RegExp(r'\s+')).length >= 5,
        );

    final metricIndexes = e.optionSurfaceMetrics.map((m) => m.optionIndex).toSet();
    final metricsComplete =
        e.optionSurfaceMetrics.length == 4 &&
        metricIndexes.length == 4 &&
        metricIndexes.containsAll(const {0, 1, 2, 3});

    final sourceSupportComplete =
        e.authoritativeSources.any((x) => x.trim().isNotEmpty) &&
        e.sourceAuthorityVerified &&
        e.sourceSupportsKey &&
        e.noUnsupportedMicroscopicDistinction &&
        allD((d) => d.sourceSupportsRejectionDistinction);

    final expectedLedgerIds = {
      for (var i = 1; i <= 299; i++) 'DQG-${i.toString().padLeft(3, '0')}',
    };
    final ledgerExact =
        e.ruleEvidence.length == 299 &&
        e.ruleEvidence.keys.toSet().difference(expectedLedgerIds).isEmpty &&
        expectedLedgerIds.difference(e.ruleEvidence.keys.toSet()).isEmpty &&
        e.ruleEvidence.entries.every(
          (entry) => entry.value.ruleId == entry.key && entry.value.isComplete,
        );

    final dqsCategories = <String, int>{
      'plausibility':
          allD(
            (d) =>
                d.plausibilityScore == 5 &&
                d.sameTechnicalUniverse &&
                d.credibleInProfessionalPractice,
          )
          ? 10
          : 0,
      'truthComponent':
          allD(
            (d) =>
                d.truthComponentScore == 4 &&
                d.substantiallyTechnicallyCorrect,
          )
          ? 10
          : 0,
      'dq6Compliance':
          dq6 && allD((d) => d.sophisticatedReasoningPath) ? 10 : 0,
      'scenarioIntegration':
          multiFact && allD((d) => d.scenarioAnchorsValid) ? 10 : 0,
      'misconceptionTargeting':
          distinctFingerprints &&
                  distinctFamilies &&
                  allD((d) => d.targetedMisconception.trim().isNotEmpty)
              ? 10
              : 0,
      'singleFatalFlaw':
          allD(
            (d) =>
                d.singleFatalFlaw &&
                !d.multipleUnrelatedDefectsDetected &&
                d.fatalFlaw.trim().isNotEmpty,
          )
          ? 10
          : 0,
      'confusability': allD((d) => d.confusabilityScore == 4) ? 10 : 0,
      'parity':
          e.noMaterialLengthCue &&
                  allD(
                    (d) =>
                        d.grammarParallel &&
                        d.specificityAndDetailParallel &&
                        d.lengthAndClauseParallel &&
                        d.terminologyUnitsPrecisionParallel &&
                        d.conditionalWordingParallel &&
                        !d.linguisticCueDetected,
                  )
              ? 10
              : 0,
      'eliminationResistance':
          allD(
            (d) =>
                !d.keywordLeakageDetected &&
                !d.absoluteLanguageShortcutDetected &&
                !d.nonTechnicalEliminationShortcutDetected,
          )
          ? 10
          : 0,
      'superiorityAmbiguity':
          oneDefensible &&
                  superiorityComplete &&
                  !e.ambiguityDetected &&
                  keyAllCriteria
              ? 10
              : 0,
    };
    final dqs = dqsCategories.values.fold<int>(0, (sum, value) => sum + value);

    final machineConjunction =
        options4 &&
        keyValid &&
        distractorsMatch &&
        dq6 &&
        allD((d) => d.plausibilityScore == 5) &&
        allD((d) => d.truthComponentScore == 4) &&
        allD((d) => d.confusabilityScore == 4) &&
        allD((d) => d.singleFatalFlaw) &&
        distinctFingerprints &&
        allD((d) => d.scenarioAnchorsValid) &&
        allD((d) => d.counterfactualMinimalAndPlausible) &&
        superiorityComplete &&
        !e.ambiguityDetected &&
        allD((d) => !d.nonTechnicalEliminationShortcutDetected) &&
        sourceSupportComplete &&
        dqs == 100 &&
        e.unresolvedBlockCount == 0 &&
        e.unresolvedFailCount == 0 &&
        e.unresolvedWarningCount == 0 &&
        !e.manualOverrideRequested;

    final context = _RuleContext(
      evidence: e,
      options4: options4,
      keyValid: keyValid,
      distractorsMatch: distractorsMatch,
      noFiller: noFiller,
      allExpertNearMiss: allExpertNearMiss,
      allCredible: allCredible,
      oneDefensible: oneDefensible,
      dq6: dq6,
      multiFact: multiFact,
      literalOptionsUnique: literalOptionsUnique,
      noShortcut: noShortcut,
      distinctFamilies: distinctFamilies,
      distinctFingerprints: distinctFingerprints,
      familiesValid: familiesValid,
      metadataComplete: metadataComplete,
      keyAllCriteria: keyAllCriteria,
      distractorCriteriaComplete: distractorCriteriaComplete,
      superiorityComplete: superiorityComplete,
      superioritySpecific: superioritySpecific,
      metricsComplete: metricsComplete,
      sourceSupportComplete: sourceSupportComplete,
      ledgerExact: ledgerExact,
      dqsCategories: dqsCategories,
      dqs: dqs,
      machineConjunction: machineConjunction,
    );

    final atomic = <QuestionQualityRuleResult>[];
    for (var number = 1; number <= 299; number++) {
      final id = 'DQG-${number.toString().padLeft(3, '0')}';
      final record = e.ruleEvidence[id];
      final proofPass = record != null && record.isComplete && record.satisfied;
      final machinePass = _machineCondition(number, context);
      final passed = proofPass && machinePass;
      atomic.add(
        QuestionQualityRuleResult(
          ruleId: id,
          passed: passed,
          message: passed
              ? '$id PASS'
              : '$id BLOCK: structured proof or deterministic predicate failed.',
        ),
      );
    }

    return QuestionQualityValidationResult.fromAtomicRules(
      atomicRules: atomic,
      dqsCategories: dqsCategories,
    );
  }

  bool _machineCondition(int n, _RuleContext c) {
    final e = c.evidence;
    final d = e.distractors;

    bool allD(bool Function(DistractorQualityEvidence value) test) =>
        d.length == 3 && d.every(test);

    bool proofFor(int index) {
      final value = e.keySuperiorityProof[index]?.trim() ?? '';
      return value.isNotEmpty && !_genericSuperiority.hasMatch(value);
    }

    switch (n) {
      case 1:
      case 260:
        return c.options4;
      case 2:
      case 261:
        return c.keyValid;
      case 3:
      case 262:
        return c.distractorsMatch;
      case 4:
        return c.noFiller;
      case 5:
      case 64:
      case 279:
        return c.allExpertNearMiss;
      case 6:
      case 24:
      case 42:
      case 98:
      case 214:
      case 237:
        return c.allCredible;
      case 7:
      case 33:
      case 166:
      case 177:
      case 193:
      case 227:
      case 252:
      case 278:
      case 296:
        return c.oneDefensible;
      case 8:
      case 27:
      case 29:
      case 31:
        return c.noShortcut;
      case 9:
      case 207:
      case 230:
      case 263:
      case 291:
        return c.dq6;
      case 10:
        return d.length > 0 && d[0].plausibilityScore == 5;
      case 11:
        return d.length > 1 && d[1].plausibilityScore == 5;
      case 12:
        return d.length > 2 && d[2].plausibilityScore == 5;
      case 13:
        return d.length > 0 && d[0].truthComponentScore == 4;
      case 14:
        return d.length > 1 && d[1].truthComponentScore == 4;
      case 15:
        return d.length > 2 && d[2].truthComponentScore == 4;
      case 16:
      case 226:
      case 231:
      case 259:
      case 275:
      case 294:
        return c.dqs == 100;
      case 17:
      case 256:
        return e.unresolvedBlockCount == 0;
      case 18:
      case 257:
        return e.unresolvedFailCount == 0;
      case 19:
      case 179:
      case 194:
      case 251:
      case 272:
        return !e.ambiguityDetected;
      case 20:
      case 186:
      case 189:
      case 190:
      case 192:
      case 241:
      case 274:
        return c.sourceSupportComplete;
      case 21:
      case 232:
        return c.literalOptionsUnique && !e.semanticDuplicateOptionsDetected;
      case 22:
        return c.superiorityComplete && !e.manualOverrideRequested;
      case 23:
      case 36:
      case 116:
      case 234:
        return allD((x) => x.sameTechnicalUniverse);
      case 25:
      case 44:
      case 48:
      case 280:
        return allD((x) => x.substantiallyTechnicallyCorrect);
      case 26:
      case 87:
      case 88:
        return c.multiFact;
      case 28:
      case 37:
      case 54:
        return allD((x) => x.professionalTerminologyValid);
      case 30:
      case 120:
      case 130:
      case 131:
      case 158:
      case 245:
        return e.noMaterialLengthCue && allD((x) => x.lengthAndClauseParallel);
      case 32:
      case 40:
      case 56:
        return allD((x) => x.sophisticatedReasoningPath);
      case 34:
        return allD((x) => x.smeRejectionProof.trim().isNotEmpty);
      case 35:
      case 66:
      case 208:
      case 228:
      case 264:
      case 292:
        return allD((x) => x.plausibilityScore == 5);
      case 38:
      case 55:
        return allD((x) => x.addressesActualDecisionOrHazard);
      case 39:
      case 50:
        return allD(
          (x) =>
              x.substantiallyTechnicallyCorrect &&
              x.technicalTruth.trim().isNotEmpty,
        );
      case 41:
      case 45:
      case 51:
      case 58:
      case 211:
      case 235:
      case 267:
        return allD((x) => x.singleFatalFlaw);
      case 43:
      case 67:
      case 209:
      case 229:
      case 265:
      case 293:
        return allD((x) => x.truthComponentScore == 4);
      case 46:
      case 47:
      case 57:
      case 236:
        return allD(
          (x) => x.singleFatalFlaw && !x.multipleUnrelatedDefectsDetected,
        );
      case 49:
      case 155:
        return allD(
          (x) =>
              x.credibleInProfessionalPractice &&
              !x.nonTechnicalEliminationShortcutDetected,
        );
      case 59:
      case 63:
        return c.distinctFamilies;
      case 60:
      case 61:
      case 62:
      case 212:
      case 233:
      case 268:
        return c.distinctFingerprints;
      case 65:
        return allD((x) => x.difficultyLevel == 'DQ6');
      case 68:
        return allD((x) => x.family.trim().isNotEmpty);
      case 69:
        return allD((x) => x.targetedMisconception.trim().isNotEmpty);
      case 70:
      case 239:
        return allD((x) => x.whyTempting.trim().isNotEmpty);
      case 71:
        return allD((x) => x.fatalFlaw.trim().isNotEmpty);
      case 72:
      case 238:
        return allD(
          (x) =>
              x.scenarioEvidence.isNotEmpty &&
              x.scenarioEvidence.every((v) => v.trim().isNotEmpty),
        );
      case 73:
        return allD((x) => x.technicalTruth.trim().isNotEmpty);
      case 74:
        return allD((x) => x.keyDifference.trim().isNotEmpty);
      case 75:
      case 106:
      case 240:
        return allD((x) => x.counterfactualToBecomeCorrect.trim().isNotEmpty);
      case 76:
        return allD((x) => x.misconceptionFingerprint.trim().isNotEmpty);
      case 77:
        return c.metadataComplete;
      case 86:
        return c.familiesValid;
      case 89:
      case 213:
      case 269:
        return allD((x) => x.scenarioAnchorsValid);
      case 90:
      case 92:
      case 96:
      case 103:
      case 105:
      case 271:
        return c.superiorityComplete && c.keyAllCriteria;
      case 91:
        return allD((x) => x.sophisticatedReasoningPath);
      case 93:
        return e.criterionMatrixComplete;
      case 94:
      case 99:
        return e.criterionMatrixComplete && e.distractorFailedCriteria.length == 3;
      case 95:
        return e.materialCriteria.isNotEmpty;
      case 97:
        return c.distractorCriteriaComplete;
      case 100:
        return proofFor(1);
      case 101:
        return proofFor(2);
      case 102:
        return proofFor(3);
      case 104:
        return c.superioritySpecific;
      case 107:
      case 108:
      case 109:
      case 270:
        return allD((x) => x.counterfactualMinimalAndPlausible);
      case 110:
        return d.length > 0 && d[0].confusabilityScore == 4;
      case 111:
        return d.length > 1 && d[1].confusabilityScore == 4;
      case 112:
        return d.length > 2 && d[2].confusabilityScore == 4;
      case 113:
        return allD((x) => x.confusabilityScore >= 4);
      case 114:
        return allD((x) => x.confusabilityScore != 5);
      case 115:
      case 210:
      case 266:
        return allD((x) => x.confusabilityScore == 4);
      case 117:
        return allD((x) => x.sameProfessionalLevel);
      case 118:
      case 138:
      case 142:
      case 157:
        return allD((x) => x.grammarParallel && !x.linguisticCueDetected);
      case 119:
      case 122:
      case 132:
      case 133:
      case 134:
      case 135:
      case 136:
      case 137:
      case 244:
        return allD((x) => x.specificityAndDetailParallel);
      case 121:
      case 123:
        return allD((x) => x.terminologyUnitsPrecisionParallel);
      case 124:
        return allD((x) => x.conditionalWordingParallel);
      case 125:
        return c.metricsComplete &&
            e.optionSurfaceMetrics.every((x) => x.characterCount > 0);
      case 126:
        return c.metricsComplete &&
            e.optionSurfaceMetrics.every((x) => x.wordCount > 0);
      case 127:
        return c.metricsComplete &&
            e.optionSurfaceMetrics.every((x) => x.clauseCount > 0);
      case 128:
        return c.metricsComplete &&
            e.optionSurfaceMetrics.every((x) => x.technicalTermCount >= 0);
      case 129:
        return c.metricsComplete &&
            e.optionSurfaceMetrics.every((x) => x.qualifierCount >= 0);
      case 139:
      case 140:
      case 143:
      case 145:
      case 243:
        return allD((x) => !x.linguisticCueDetected) &&
            !e.answerPositionCueDetected;
      case 141:
      case 147:
      case 148:
      case 150:
        return allD((x) => !x.keywordLeakageDetected);
      case 144:
        return allD(
          (x) =>
              !x.linguisticCueDetected &&
              x.terminologyUnitsPrecisionParallel,
        );
      case 146:
        return !e.answerPositionCueDetected;
      case 149:
        return allD(
          (x) => !x.keywordLeakageDetected || x.terminologyUnitsPrecisionParallel,
        );
      case 151:
      case 152:
      case 153:
      case 154:
        return allD((x) => !x.absoluteLanguageShortcutDetected);
      case 156:
      case 159:
        return allD(
          (x) =>
              !x.nonTechnicalEliminationShortcutDetected &&
              x.sameTechnicalUniverse,
        );
      case 160:
      case 161:
      case 162:
      case 163:
      case 273:
        return allD((x) => !x.nonTechnicalEliminationShortcutDetected);
      case 164:
      case 165:
        return !e.sophisticationParityApplicable ||
            (e.sophisticationParitySatisfied &&
                e.advancedDistractorPresentWhenApplicable);
      case 167:
      case 174:
      case 246:
      case 247:
        return !e.numericQuestion ||
            allD(
              (x) =>
                  x.distractorCalculationPath.trim().isNotEmpty &&
                  x.calculationConsistent,
            );
      case 168:
      case 169:
      case 170:
      case 171:
      case 172:
      case 173:
        return !e.numericQuestion ||
            allD((x) => x.distractorCalculationPath.trim().isNotEmpty);
      case 175:
      case 176:
      case 178:
        return !e.wrongLevelCorrectnessApplicable ||
            e.wrongLevelDistinctionDocumented;
      case 180:
        return e.keyRequiresNoUnstatedAssumption;
      case 181:
        return e.assumptions.every(
          (a) => a.supported || a.intentionalDistractorTrap,
        );
      case 182:
        return e.assumptionsDocumented;
      case 183:
        return e.assumptions.every((a) => a.assumptionUsed.trim().isNotEmpty);
      case 184:
        return e.assumptions.every((a) => a.scenarioSupport.trim().isNotEmpty);
      case 185:
      case 242:
        return e.noEquivalenceFromUnstatedAssumption && e.keyAssumptionsSupported;
      case 187:
      case 188:
        return e.sourceAuthorityVerified && e.authoritativeSources.isNotEmpty;
      case 191:
        return e.noUnsupportedMicroscopicDistinction;
      case 195:
      case 250:
        return e.stemSufficient;
      case 196:
        return e.reviewComplete && !e.ambiguityDetected;
      case 197:
        return e.keyCompleteness['hazard'] == true;
      case 198:
        return e.keyCompleteness['scope'] == true;
      case 199:
        return e.keyCompleteness['timing'] == true;
      case 200:
        return e.keyCompleteness['priority'] == true;
      case 201:
        return e.keyCompleteness['mechanism'] == true;
      case 202:
        return e.keyCompleteness['technicalPrinciple'] == true;
      case 203:
        return e.keyCompleteness['scenarioConditions'] == true;
      case 204:
        return e.keyCompleteness['commandWord'] == true;
      case 205:
        return e.keyCompleteness['calculation'] == true;
      case 206:
        return e.keyCompleteness['assumptions'] == true;
      case 215:
        return c.dqsCategories.length == 10 &&
            c.dqsCategories.values.every((x) => x == 0 || x == 10);
      case 216:
        return c.dqsCategories['plausibility'] == 10;
      case 217:
        return c.dqsCategories['truthComponent'] == 10;
      case 218:
        return c.dqsCategories['dq6Compliance'] == 10;
      case 219:
        return c.dqsCategories['scenarioIntegration'] == 10;
      case 220:
        return c.dqsCategories['misconceptionTargeting'] == 10;
      case 221:
        return c.dqsCategories['singleFatalFlaw'] == 10;
      case 222:
        return c.dqsCategories['confusability'] == 10;
      case 223:
        return c.dqsCategories['parity'] == 10;
      case 224:
        return c.dqsCategories['eliminationResistance'] == 10;
      case 225:
        return c.dqsCategories['superiorityAmbiguity'] == 10;
      case 248:
        return c.keyValid && e.answerKeyVerified;
      case 249:
        return e.testsIntendedCompetency;
      case 253:
      case 254:
        return true;
      case 255:
      case 258:
      case 295:
        return e.unresolvedWarningCount == 0;
      case 276:
        return e.unresolvedBlockCount == 0 &&
            e.unresolvedFailCount == 0 &&
            e.unresolvedWarningCount == 0;
      case 277:
      case 285:
        return c.machineConjunction;
      case 281:
        return allD(
          (x) => x.plausibilityScore == 5 && x.truthComponentScore == 4,
        );
      case 282:
        return allD((x) => x.confusabilityScore == 4 && x.singleFatalFlaw);
      case 283:
        return c.distinctFingerprints &&
            allD(
              (x) =>
                  x.sophisticatedReasoningPath &&
                  !x.nonTechnicalEliminationShortcutDetected,
            );
      case 284:
        return c.dqs == 100 &&
            !e.ambiguityDetected &&
            c.sourceSupportComplete &&
            c.superiorityComplete;
      case 286:
      case 288:
      case 289:
      case 290:
      case 297:
        return true;
      case 287:
        return pinnedSourceSpecificationBlob ==
            '68b4fe0a132c8cc7ebd095aa7340a6ee4bb29b4b';
      case 298:
        return c.ledgerExact;
      case 299:
        return !e.manualOverrideRequested && !publicationOverrideSupported;
      default:
        // Semantic-only atomic rules still require a complete positive
        // DqgEvidenceRecord. Returning true here never bypasses that proof.
        return true;
    }
  }

  bool _familyValid(DistractorQualityEvidence d) {
    const known = <String>{
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
    if (known.contains(d.family)) return true;
    return d.family.startsWith('D-') && d.familyJustification.trim().isNotEmpty;
  }

  String _normalize(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}

class _RuleContext {
  final QuestionQualityEvidence evidence;
  final bool options4;
  final bool keyValid;
  final bool distractorsMatch;
  final bool noFiller;
  final bool allExpertNearMiss;
  final bool allCredible;
  final bool oneDefensible;
  final bool dq6;
  final bool multiFact;
  final bool literalOptionsUnique;
  final bool noShortcut;
  final bool distinctFamilies;
  final bool distinctFingerprints;
  final bool familiesValid;
  final bool metadataComplete;
  final bool keyAllCriteria;
  final bool distractorCriteriaComplete;
  final bool superiorityComplete;
  final bool superioritySpecific;
  final bool metricsComplete;
  final bool sourceSupportComplete;
  final bool ledgerExact;
  final Map<String, int> dqsCategories;
  final int dqs;
  final bool machineConjunction;

  const _RuleContext({
    required this.evidence,
    required this.options4,
    required this.keyValid,
    required this.distractorsMatch,
    required this.noFiller,
    required this.allExpertNearMiss,
    required this.allCredible,
    required this.oneDefensible,
    required this.dq6,
    required this.multiFact,
    required this.literalOptionsUnique,
    required this.noShortcut,
    required this.distinctFamilies,
    required this.distinctFingerprints,
    required this.familiesValid,
    required this.metadataComplete,
    required this.keyAllCriteria,
    required this.distractorCriteriaComplete,
    required this.superiorityComplete,
    required this.superioritySpecific,
    required this.metricsComplete,
    required this.sourceSupportComplete,
    required this.ledgerExact,
    required this.dqsCategories,
    required this.dqs,
    required this.machineConjunction,
  });
}
