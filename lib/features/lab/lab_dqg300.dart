import 'dart:convert';

import '../../models/question_quality_evidence.dart';
import '../../models/question_quality_validation_result.dart';
import '../../services/dqg300_question_quality_validator.dart';
import 'lab_contracts.dart';
import 'lab_decision_question_adapter.dart';

class LabDqg300DecisionEvidence {
  const LabDqg300DecisionEvidence({
    required this.nodeId,
    required this.decisionSignature,
    required this.evidence,
  });

  final String nodeId;
  final String decisionSignature;
  final QuestionQualityEvidence evidence;
}

class LabDqg300EvidenceBundle {
  LabDqg300EvidenceBundle({
    required this.labId,
    required this.versionId,
    required Iterable<LabDqg300DecisionEvidence> decisions,
  }) : decisions = Map<String, LabDqg300DecisionEvidence>.unmodifiable(
         _index(decisions),
       );

  final String labId;
  final String versionId;
  final Map<String, LabDqg300DecisionEvidence> decisions;

  static Map<String, LabDqg300DecisionEvidence> _index(
    Iterable<LabDqg300DecisionEvidence> values,
  ) {
    final output = <String, LabDqg300DecisionEvidence>{};
    for (final value in values) {
      if (value.nodeId.trim().isEmpty) {
        throw const LabContractException(
          'DQG300-LAB evidence requires a Decision Node ID.',
        );
      }
      if (output.containsKey(value.nodeId)) {
        throw LabContractException(
          'Duplicate DQG300-LAB evidence for ' + value.nodeId + '.',
        );
      }
      output[value.nodeId] = value;
    }
    return output;
  }
}

class LabDqg300DecisionResult {
  const LabDqg300DecisionResult({required this.nodeId, required this.result});

  final String nodeId;
  final QuestionQualityValidationResult result;
}

class LabDqg300Report {
  const LabDqg300Report({
    required this.decisionResults,
    required this.missingEvidenceNodeIds,
    required this.staleEvidenceNodeIds,
    required this.unexpectedEvidenceNodeIds,
    required this.pinnedVersionMatches,
  });

  final List<LabDqg300DecisionResult> decisionResults;
  final Set<String> missingEvidenceNodeIds;
  final Set<String> staleEvidenceNodeIds;
  final Set<String> unexpectedEvidenceNodeIds;
  final bool pinnedVersionMatches;

  bool get isValid =>
      pinnedVersionMatches &&
      missingEvidenceNodeIds.isEmpty &&
      staleEvidenceNodeIds.isEmpty &&
      unexpectedEvidenceNodeIds.isEmpty &&
      decisionResults.isNotEmpty &&
      decisionResults.every((item) => item.result.isPublishable);

  int get blockedDecisionCount =>
      decisionResults.where((item) => !item.result.isPublishable).length +
      missingEvidenceNodeIds.length +
      staleEvidenceNodeIds.length;
}

class LabDqg300Validator {
  const LabDqg300Validator({
    this.questionValidator = const Dqg300QuestionQualityValidator(),
    this.questionAdapter = const LabDecisionQuestionAdapter(),
  });

  final Dqg300QuestionQualityValidator questionValidator;
  final LabDecisionQuestionAdapter questionAdapter;

  LabDqg300Report validate({
    required LabPackage package,
    required LabDqg300EvidenceBundle evidenceBundle,
  }) {
    final decisionNodes = package.nodes.whereType<LabDecisionNode>().toList();
    final decisionIds = decisionNodes.map((node) => node.id).toSet();
    final evidenceIds = evidenceBundle.decisions.keys.toSet();

    final pinnedVersionMatches =
        evidenceBundle.labId == package.metadata.id &&
        evidenceBundle.versionId == package.metadata.versionId;
    final missing = decisionIds.difference(evidenceIds);
    final unexpected = evidenceIds.difference(decisionIds);
    final stale = <String>{};
    final results = <LabDqg300DecisionResult>[];

    if (pinnedVersionMatches) {
      for (var index = 0; index < decisionNodes.length; index++) {
        final node = decisionNodes[index];
        final decisionEvidence = evidenceBundle.decisions[node.id];
        if (decisionEvidence == null) continue;

        if (decisionEvidence.decisionSignature != decisionSignature(node)) {
          stale.add(node.id);
          continue;
        }

        final result = questionValidator.validate(
          question: questionAdapter.toQuestion(
            package: package,
            node: node,
            decisionIndex: index,
          ),
          evidence: decisionEvidence.evidence,
        );
        results.add(LabDqg300DecisionResult(nodeId: node.id, result: result));
      }
    }

    return LabDqg300Report(
      decisionResults: List<LabDqg300DecisionResult>.unmodifiable(results),
      missingEvidenceNodeIds: Set<String>.unmodifiable(missing),
      staleEvidenceNodeIds: Set<String>.unmodifiable(stale),
      unexpectedEvidenceNodeIds: Set<String>.unmodifiable(unexpected),
      pinnedVersionMatches: pinnedVersionMatches,
    );
  }

  static String decisionSignature(LabDecisionNode node) {
    return jsonEncode(<String, Object?>{
      'id': node.id,
      'prompt': node.prompt,
      'options': [
        for (final option in node.options)
          <String, Object?>{
            'id': option.id,
            'text': option.text,
            'isBest': option.isBest,
            'quality': option.quality.name,
          },
      ],
    });
  }

}
