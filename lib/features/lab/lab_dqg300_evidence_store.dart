import 'dart:convert';

import '../../models/question_quality_evidence.dart';
import 'lab_contracts.dart';
import 'lab_dqg300.dart';

class LabDqg300EvidenceCodec {
  const LabDqg300EvidenceCodec();

  static const String schemaVersion = 'csp11.lab.dqg300.evidence.v1';

  String encode(LabDqg300EvidenceBundle bundle) {
    return jsonEncode(<String, Object?>{
      'schemaVersion': schemaVersion,
      'labId': bundle.labId,
      'versionId': bundle.versionId,
      'decisions': bundle.decisions.values
          .map(
            (item) => <String, Object?>{
              'nodeId': item.nodeId,
              'decisionSignature': item.decisionSignature,
              'evidence': _evidenceToJson(item.evidence),
            },
          )
          .toList(),
    });
  }

  LabDqg300EvidenceBundle decode(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw const LabContractException(
        'DQG300-LAB evidence root must be an object.',
      );
    }
    final root = decoded.cast<String, Object?>();
    if (root['schemaVersion'] != schemaVersion) {
      throw const LabContractException(
        'Unsupported DQG300-LAB evidence schema.',
      );
    }
    final decisions = root['decisions'];
    if (decisions is! Iterable) {
      throw const LabContractException(
        'DQG300-LAB evidence decisions must be an array.',
      );
    }

    return LabDqg300EvidenceBundle(
      labId: root['labId']?.toString() ?? '',
      versionId: root['versionId']?.toString() ?? '',
      decisions: decisions.map((item) {
        if (item is! Map) {
          throw const LabContractException(
            'DQG300-LAB decision evidence must be an object.',
          );
        }
        final map = item.cast<String, Object?>();
        final rawEvidence = map['evidence'];
        if (rawEvidence is! Map) {
          throw const LabContractException(
            'DQG300-LAB decision evidence payload is missing.',
          );
        }
        return LabDqg300DecisionEvidence(
          nodeId: map['nodeId']?.toString() ?? '',
          decisionSignature: map['decisionSignature']?.toString() ?? '',
          evidence: _evidenceFromJson(rawEvidence.cast<String, Object?>()),
        );
      }),
    );
  }

  Map<String, Object?> _evidenceToJson(QuestionQualityEvidence value) {
    return <String, Object?>{
      'difficultyLevel': value.difficultyLevel,
      'distractors': value.distractors.map(_distractorToJson).toList(),
      'decisiveScenarioFacts': value.decisiveScenarioFacts,
      'materialCriteria': value.materialCriteria,
      'keySatisfiedCriteria': value.keySatisfiedCriteria,
      'distractorFailedCriteria': <String, Object?>{
        for (final entry in value.distractorFailedCriteria.entries)
          entry.key.toString(): entry.value,
      },
      'criterionMatrixComplete': value.criterionMatrixComplete,
      'keySuperiorityProof': <String, Object?>{
        for (final entry in value.keySuperiorityProof.entries)
          entry.key.toString(): entry.value,
      },
      'keyCompleteness': value.keyCompleteness,
      'defensibleBestAnswerCount': value.defensibleBestAnswerCount,
      'reviewComplete': value.reviewComplete,
      'manualOverrideRequested': value.manualOverrideRequested,
      'unresolvedBlockCount': value.unresolvedBlockCount,
      'unresolvedFailCount': value.unresolvedFailCount,
      'unresolvedWarningCount': value.unresolvedWarningCount,
      'keyRequiresNoUnstatedAssumption': value.keyRequiresNoUnstatedAssumption,
      'assumptionsDocumented': value.assumptionsDocumented,
      'keyAssumptionsSupported': value.keyAssumptionsSupported,
      'noEquivalenceFromUnstatedAssumption':
          value.noEquivalenceFromUnstatedAssumption,
      'assumptions': value.assumptions.map(_assumptionToJson).toList(),
      'authoritativeSources': value.authoritativeSources,
      'sourceAuthorityVerified': value.sourceAuthorityVerified,
      'sourceSupportsKey': value.sourceSupportsKey,
      'noUnsupportedMicroscopicDistinction':
          value.noUnsupportedMicroscopicDistinction,
      'ambiguityDetected': value.ambiguityDetected,
      'semanticDuplicateOptionsDetected':
          value.semanticDuplicateOptionsDetected,
      'answerPositionCueDetected': value.answerPositionCueDetected,
      'answerKeyVerified': value.answerKeyVerified,
      'stemSufficient': value.stemSufficient,
      'testsIntendedCompetency': value.testsIntendedCompetency,
      'numericQuestion': value.numericQuestion,
      'wrongLevelCorrectnessApplicable': value.wrongLevelCorrectnessApplicable,
      'wrongLevelDistinctionDocumented': value.wrongLevelDistinctionDocumented,
      'sophisticationParityApplicable': value.sophisticationParityApplicable,
      'sophisticationParitySatisfied': value.sophisticationParitySatisfied,
      'advancedDistractorPresentWhenApplicable':
          value.advancedDistractorPresentWhenApplicable,
      'optionSurfaceMetrics': value.optionSurfaceMetrics
          .map(_surfaceToJson)
          .toList(),
      'noMaterialLengthCue': value.noMaterialLengthCue,
      'ruleEvidence': <String, Object?>{
        for (final entry in value.ruleEvidence.entries)
          entry.key: _ruleToJson(entry.value),
      },
    };
  }

  QuestionQualityEvidence _evidenceFromJson(Map<String, Object?> json) {
    final distractors = _objects(json['distractors']);
    final assumptions = _objects(json['assumptions']);
    final surface = _objects(json['optionSurfaceMetrics']);
    final rawRuleEvidence = _object(json['ruleEvidence']);

    return QuestionQualityEvidence(
      difficultyLevel: _string(json, 'difficultyLevel'),
      distractors: distractors.map(_distractorFromJson).toList(growable: false),
      decisiveScenarioFacts: _strings(json['decisiveScenarioFacts']),
      materialCriteria: _strings(json['materialCriteria']),
      keySatisfiedCriteria: _strings(json['keySatisfiedCriteria']),
      distractorFailedCriteria: _intStringListMap(
        json['distractorFailedCriteria'],
      ),
      criterionMatrixComplete: _bool(json, 'criterionMatrixComplete'),
      keySuperiorityProof: _intStringMap(json['keySuperiorityProof']),
      keyCompleteness: _stringBoolMap(json['keyCompleteness']),
      defensibleBestAnswerCount: _int(json, 'defensibleBestAnswerCount'),
      reviewComplete: _bool(json, 'reviewComplete'),
      manualOverrideRequested: _bool(json, 'manualOverrideRequested'),
      unresolvedBlockCount: _int(json, 'unresolvedBlockCount'),
      unresolvedFailCount: _int(json, 'unresolvedFailCount'),
      unresolvedWarningCount: _int(json, 'unresolvedWarningCount'),
      keyRequiresNoUnstatedAssumption: _bool(
        json,
        'keyRequiresNoUnstatedAssumption',
      ),
      assumptionsDocumented: _bool(json, 'assumptionsDocumented'),
      keyAssumptionsSupported: _bool(json, 'keyAssumptionsSupported'),
      noEquivalenceFromUnstatedAssumption: _bool(
        json,
        'noEquivalenceFromUnstatedAssumption',
      ),
      assumptions: assumptions.map(_assumptionFromJson).toList(growable: false),
      authoritativeSources: _strings(json['authoritativeSources']),
      sourceAuthorityVerified: _bool(json, 'sourceAuthorityVerified'),
      sourceSupportsKey: _bool(json, 'sourceSupportsKey'),
      noUnsupportedMicroscopicDistinction: _bool(
        json,
        'noUnsupportedMicroscopicDistinction',
      ),
      ambiguityDetected: _bool(json, 'ambiguityDetected'),
      semanticDuplicateOptionsDetected: _bool(
        json,
        'semanticDuplicateOptionsDetected',
      ),
      answerPositionCueDetected: _bool(json, 'answerPositionCueDetected'),
      answerKeyVerified: _bool(json, 'answerKeyVerified'),
      stemSufficient: _bool(json, 'stemSufficient'),
      testsIntendedCompetency: _bool(json, 'testsIntendedCompetency'),
      numericQuestion: _bool(json, 'numericQuestion'),
      wrongLevelCorrectnessApplicable: _bool(
        json,
        'wrongLevelCorrectnessApplicable',
      ),
      wrongLevelDistinctionDocumented: _bool(
        json,
        'wrongLevelDistinctionDocumented',
      ),
      sophisticationParityApplicable: _bool(
        json,
        'sophisticationParityApplicable',
      ),
      sophisticationParitySatisfied: _bool(
        json,
        'sophisticationParitySatisfied',
      ),
      advancedDistractorPresentWhenApplicable: _bool(
        json,
        'advancedDistractorPresentWhenApplicable',
      ),
      optionSurfaceMetrics: surface
          .map(_surfaceFromJson)
          .toList(growable: false),
      noMaterialLengthCue: _bool(json, 'noMaterialLengthCue'),
      ruleEvidence: <String, DqgEvidenceRecord>{
        for (final entry in rawRuleEvidence.entries)
          entry.key: _ruleFromJson(_object(entry.value)),
      },
    );
  }

  Map<String, Object?> _distractorToJson(
    DistractorQualityEvidence value,
  ) => <String, Object?>{
    'optionIndex': value.optionIndex,
    'role': value.role,
    'difficultyLevel': value.difficultyLevel,
    'plausibilityScore': value.plausibilityScore,
    'truthComponentScore': value.truthComponentScore,
    'confusabilityScore': value.confusabilityScore,
    'family': value.family,
    'familyJustification': value.familyJustification,
    'misconceptionFingerprint': value.misconceptionFingerprint,
    'targetedMisconception': value.targetedMisconception,
    'whyTempting': value.whyTempting,
    'fatalFlaw': value.fatalFlaw,
    'scenarioEvidence': value.scenarioEvidence,
    'scenarioAnchorsValid': value.scenarioAnchorsValid,
    'technicalTruth': value.technicalTruth,
    'keyDifference': value.keyDifference,
    'counterfactualToBecomeCorrect': value.counterfactualToBecomeCorrect,
    'sameTechnicalUniverse': value.sameTechnicalUniverse,
    'sameProfessionalLevel': value.sameProfessionalLevel,
    'substantiallyTechnicallyCorrect': value.substantiallyTechnicallyCorrect,
    'professionalTerminologyValid': value.professionalTerminologyValid,
    'addressesActualDecisionOrHazard': value.addressesActualDecisionOrHazard,
    'credibleInProfessionalPractice': value.credibleInProfessionalPractice,
    'singleFatalFlaw': value.singleFatalFlaw,
    'multipleUnrelatedDefectsDetected': value.multipleUnrelatedDefectsDetected,
    'sophisticatedReasoningPath': value.sophisticatedReasoningPath,
    'counterfactualMinimalAndPlausible':
        value.counterfactualMinimalAndPlausible,
    'grammarParallel': value.grammarParallel,
    'specificityAndDetailParallel': value.specificityAndDetailParallel,
    'lengthAndClauseParallel': value.lengthAndClauseParallel,
    'terminologyUnitsPrecisionParallel':
        value.terminologyUnitsPrecisionParallel,
    'conditionalWordingParallel': value.conditionalWordingParallel,
    'linguisticCueDetected': value.linguisticCueDetected,
    'keywordLeakageDetected': value.keywordLeakageDetected,
    'absoluteLanguageShortcutDetected': value.absoluteLanguageShortcutDetected,
    'nonTechnicalEliminationShortcutDetected':
        value.nonTechnicalEliminationShortcutDetected,
    'sourceSupportsRejectionDistinction':
        value.sourceSupportsRejectionDistinction,
    'smeRejectionProof': value.smeRejectionProof,
    'distractorCalculationPath': value.distractorCalculationPath,
    'calculationConsistent': value.calculationConsistent,
  };

  DistractorQualityEvidence _distractorFromJson(
    Map<String, Object?> json,
  ) => DistractorQualityEvidence(
    optionIndex: _int(json, 'optionIndex'),
    role: _string(json, 'role'),
    difficultyLevel: _string(json, 'difficultyLevel'),
    plausibilityScore: _int(json, 'plausibilityScore'),
    truthComponentScore: _int(json, 'truthComponentScore'),
    confusabilityScore: _int(json, 'confusabilityScore'),
    family: _string(json, 'family'),
    familyJustification: _string(json, 'familyJustification'),
    misconceptionFingerprint: _string(json, 'misconceptionFingerprint'),
    targetedMisconception: _string(json, 'targetedMisconception'),
    whyTempting: _string(json, 'whyTempting'),
    fatalFlaw: _string(json, 'fatalFlaw'),
    scenarioEvidence: _strings(json['scenarioEvidence']),
    scenarioAnchorsValid: _bool(json, 'scenarioAnchorsValid'),
    technicalTruth: _string(json, 'technicalTruth'),
    keyDifference: _string(json, 'keyDifference'),
    counterfactualToBecomeCorrect: _string(
      json,
      'counterfactualToBecomeCorrect',
    ),
    sameTechnicalUniverse: _bool(json, 'sameTechnicalUniverse'),
    sameProfessionalLevel: _bool(json, 'sameProfessionalLevel'),
    substantiallyTechnicallyCorrect: _bool(
      json,
      'substantiallyTechnicallyCorrect',
    ),
    professionalTerminologyValid: _bool(json, 'professionalTerminologyValid'),
    addressesActualDecisionOrHazard: _bool(
      json,
      'addressesActualDecisionOrHazard',
    ),
    credibleInProfessionalPractice: _bool(
      json,
      'credibleInProfessionalPractice',
    ),
    singleFatalFlaw: _bool(json, 'singleFatalFlaw'),
    multipleUnrelatedDefectsDetected: _bool(
      json,
      'multipleUnrelatedDefectsDetected',
    ),
    sophisticatedReasoningPath: _bool(json, 'sophisticatedReasoningPath'),
    counterfactualMinimalAndPlausible: _bool(
      json,
      'counterfactualMinimalAndPlausible',
    ),
    grammarParallel: _bool(json, 'grammarParallel'),
    specificityAndDetailParallel: _bool(json, 'specificityAndDetailParallel'),
    lengthAndClauseParallel: _bool(json, 'lengthAndClauseParallel'),
    terminologyUnitsPrecisionParallel: _bool(
      json,
      'terminologyUnitsPrecisionParallel',
    ),
    conditionalWordingParallel: _bool(json, 'conditionalWordingParallel'),
    linguisticCueDetected: _bool(json, 'linguisticCueDetected'),
    keywordLeakageDetected: _bool(json, 'keywordLeakageDetected'),
    absoluteLanguageShortcutDetected: _bool(
      json,
      'absoluteLanguageShortcutDetected',
    ),
    nonTechnicalEliminationShortcutDetected: _bool(
      json,
      'nonTechnicalEliminationShortcutDetected',
    ),
    sourceSupportsRejectionDistinction: _bool(
      json,
      'sourceSupportsRejectionDistinction',
    ),
    smeRejectionProof: _string(json, 'smeRejectionProof'),
    distractorCalculationPath: _string(json, 'distractorCalculationPath'),
    calculationConsistent: _bool(json, 'calculationConsistent'),
  );

  Map<String, Object?> _assumptionToJson(AssumptionEvidence value) =>
      <String, Object?>{
        'subject': value.subject,
        'assumptionUsed': value.assumptionUsed,
        'scenarioSupport': value.scenarioSupport,
        'supported': value.supported,
        'intentionalDistractorTrap': value.intentionalDistractorTrap,
      };

  AssumptionEvidence _assumptionFromJson(Map<String, Object?> json) =>
      AssumptionEvidence(
        subject: _string(json, 'subject'),
        assumptionUsed: _string(json, 'assumptionUsed'),
        scenarioSupport: _string(json, 'scenarioSupport'),
        supported: _bool(json, 'supported'),
        intentionalDistractorTrap: _bool(json, 'intentionalDistractorTrap'),
      );

  Map<String, Object?> _surfaceToJson(OptionSurfaceMetrics value) =>
      <String, Object?>{
        'optionIndex': value.optionIndex,
        'characterCount': value.characterCount,
        'wordCount': value.wordCount,
        'clauseCount': value.clauseCount,
        'technicalTermCount': value.technicalTermCount,
        'qualifierCount': value.qualifierCount,
      };

  OptionSurfaceMetrics _surfaceFromJson(Map<String, Object?> json) =>
      OptionSurfaceMetrics(
        optionIndex: _int(json, 'optionIndex'),
        characterCount: _int(json, 'characterCount'),
        wordCount: _int(json, 'wordCount'),
        clauseCount: _int(json, 'clauseCount'),
        technicalTermCount: _int(json, 'technicalTermCount'),
        qualifierCount: _int(json, 'qualifierCount'),
      );

  Map<String, Object?> _ruleToJson(DqgEvidenceRecord value) =>
      <String, Object?>{
        'ruleId': value.ruleId,
        'satisfied': value.satisfied,
        'proof': value.proof,
        'evidenceRefs': value.evidenceRefs,
        'reviewerId': value.reviewerId,
        'reviewedAtIso': value.reviewedAtIso,
      };

  DqgEvidenceRecord _ruleFromJson(Map<String, Object?> json) =>
      DqgEvidenceRecord(
        ruleId: _string(json, 'ruleId'),
        satisfied: _bool(json, 'satisfied'),
        proof: _string(json, 'proof'),
        evidenceRefs: _strings(json['evidenceRefs']),
        reviewerId: _string(json, 'reviewerId'),
        reviewedAtIso: _string(json, 'reviewedAtIso'),
      );

  String _string(Map<String, Object?> json, String key) =>
      json[key]?.toString() ?? '';

  int _int(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    throw LabContractException('DQG300-LAB evidence $key must be an integer.');
  }

  bool _bool(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is bool) return value;
    throw LabContractException('DQG300-LAB evidence $key must be Boolean.');
  }

  List<String> _strings(Object? value) {
    if (value is! Iterable) return const <String>[];
    return value.map((item) => item.toString()).toList(growable: false);
  }

  List<Map<String, Object?>> _objects(Object? value) {
    if (value is! Iterable) return const <Map<String, Object?>>[];
    return value.map((item) => _object(item)).toList(growable: false);
  }

  Map<String, Object?> _object(Object? value) {
    if (value is! Map) {
      throw const LabContractException(
        'DQG300-LAB evidence object is malformed.',
      );
    }
    return value.cast<String, Object?>();
  }

  Map<int, List<String>> _intStringListMap(Object? value) {
    final map = _object(value);
    return <int, List<String>>{
      for (final entry in map.entries)
        int.parse(entry.key): _strings(entry.value),
    };
  }

  Map<int, String> _intStringMap(Object? value) {
    final map = _object(value);
    return <int, String>{
      for (final entry in map.entries)
        int.parse(entry.key): entry.value?.toString() ?? '',
    };
  }

  Map<String, bool> _stringBoolMap(Object? value) {
    final map = _object(value);
    return <String, bool>{
      for (final entry in map.entries) entry.key: entry.value == true,
    };
  }
}

abstract class LabDqg300EvidenceRepository {
  Future<void> save(LabDqg300EvidenceBundle bundle);

  Future<LabDqg300EvidenceBundle?> load(String labId, String versionId);
}

class InMemoryLabDqg300EvidenceRepository
    implements LabDqg300EvidenceRepository {
  InMemoryLabDqg300EvidenceRepository({
    this.codec = const LabDqg300EvidenceCodec(),
  });

  final LabDqg300EvidenceCodec codec;
  final Map<String, String> _records = <String, String>{};

  String _key(String labId, String versionId) => labId + '::' + versionId;

  @override
  Future<void> save(LabDqg300EvidenceBundle bundle) async {
    _records[_key(bundle.labId, bundle.versionId)] = codec.encode(bundle);
  }

  @override
  Future<LabDqg300EvidenceBundle?> load(String labId, String versionId) async {
    final source = _records[_key(labId, versionId)];
    return source == null ? null : codec.decode(source);
  }
}
