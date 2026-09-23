import '../../services/questions/canonical_question_parser.dart';
import 'lab_contracts.dart';
import 'lab_decision_question_adapter.dart';
import 'lab_dqg300.dart';

class LabCanonicalDecisionParseResult {
  const LabCanonicalDecisionParseResult({
    required this.nodeId,
    required this.decisionIndex,
    this.draft,
    this.failure,
  });

  final String nodeId;
  final int decisionIndex;
  final CanonicalQuestionDraft? draft;
  final String? failure;

  bool get isParsed => draft != null && failure == null;
}

class LabCanonicalDecisionBatchReport {
  const LabCanonicalDecisionBatchReport({
    required this.labId,
    required this.versionId,
    required this.decisionCount,
    required this.decisionResults,
    required this.missingEvidenceNodeIds,
    required this.staleEvidenceNodeIds,
    required this.unexpectedEvidenceNodeIds,
    required this.pinnedVersionMatches,
  });

  final String labId;
  final String versionId;
  final int decisionCount;
  final List<LabCanonicalDecisionParseResult> decisionResults;
  final Set<String> missingEvidenceNodeIds;
  final Set<String> staleEvidenceNodeIds;
  final Set<String> unexpectedEvidenceNodeIds;
  final bool pinnedVersionMatches;

  bool get isValid =>
      decisionCount > 0 &&
      decisionResults.length == decisionCount &&
      pinnedVersionMatches &&
      missingEvidenceNodeIds.isEmpty &&
      staleEvidenceNodeIds.isEmpty &&
      unexpectedEvidenceNodeIds.isEmpty &&
      decisionResults.every((item) => item.isParsed);

  int get parsedDecisionCount =>
      decisionResults.where((item) => item.isParsed).length;

  int get blockedDecisionCount => decisionCount - parsedDecisionCount;

  List<CanonicalQuestionDraft> get parsedDrafts =>
      List<CanonicalQuestionDraft>.unmodifiable(
        decisionResults
            .where((item) => item.isParsed)
            .map((item) => item.draft!),
      );
}

/// LSP-Q4 batch boundary.
///
/// Runs every authored LAB Decision through the canonical CSP11 parser using
/// the same signature-pinned DQG300 evidence required by LSP-Q3. This layer is
/// parse-only: it does not execute H0.3, DQG300 scoring, LAB1000 publication
/// gates, persistence, or learner runtime behavior.
class LabCanonicalDecisionBatchParser {
  const LabCanonicalDecisionBatchParser({
    this.questionAdapter = const LabDecisionQuestionAdapter(),
  });

  final LabDecisionQuestionAdapter questionAdapter;

  LabCanonicalDecisionBatchReport parse({
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
    final results = <LabCanonicalDecisionParseResult>[];

    for (var index = 0; index < decisionNodes.length; index++) {
      final node = decisionNodes[index];

      if (!pinnedVersionMatches) {
        results.add(
          LabCanonicalDecisionParseResult(
            nodeId: node.id,
            decisionIndex: index,
            failure:
                'Pinned DQG300 evidence bundle does not match LAB '
                '${package.metadata.id}/${package.metadata.versionId}.',
          ),
        );
        continue;
      }

      final decisionEvidence = evidenceBundle.decisions[node.id];
      if (decisionEvidence == null) {
        results.add(
          LabCanonicalDecisionParseResult(
            nodeId: node.id,
            decisionIndex: index,
            failure: 'Missing pinned DQG300 evidence for Decision ${node.id}.',
          ),
        );
        continue;
      }

      if (decisionEvidence.decisionSignature !=
          LabDqg300Validator.decisionSignature(node)) {
        stale.add(node.id);
        results.add(
          LabCanonicalDecisionParseResult(
            nodeId: node.id,
            decisionIndex: index,
            failure: 'Stale pinned DQG300 evidence for Decision ${node.id}.',
          ),
        );
        continue;
      }

      try {
        results.add(
          LabCanonicalDecisionParseResult(
            nodeId: node.id,
            decisionIndex: index,
            draft: questionAdapter.toCanonicalDraft(
              package: package,
              node: node,
              evidence: decisionEvidence.evidence,
            ),
          ),
        );
      } catch (error) {
        results.add(
          LabCanonicalDecisionParseResult(
            nodeId: node.id,
            decisionIndex: index,
            failure: error.toString(),
          ),
        );
      }
    }

    return LabCanonicalDecisionBatchReport(
      labId: package.metadata.id,
      versionId: package.metadata.versionId,
      decisionCount: decisionNodes.length,
      decisionResults: List<LabCanonicalDecisionParseResult>.unmodifiable(
        results,
      ),
      missingEvidenceNodeIds: Set<String>.unmodifiable(missing),
      staleEvidenceNodeIds: Set<String>.unmodifiable(stale),
      unexpectedEvidenceNodeIds: Set<String>.unmodifiable(unexpected),
      pinnedVersionMatches: pinnedVersionMatches,
    );
  }
}
