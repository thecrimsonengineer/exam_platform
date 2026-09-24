import '../../models/question_validation_report.dart';
import '../../services/question_quality_validator.dart';
import 'lab_canonical_decision_batch_parser.dart';
import 'lab_contracts.dart';
import 'lab_decision_question_adapter.dart';
import 'lab_dqg300.dart';

class LabH03StrictDecisionResult {
  const LabH03StrictDecisionResult({
    required this.nodeId,
    required this.decisionIndex,
    this.report,
    this.failure,
  });

  final String nodeId;
  final int decisionIndex;
  final QuestionValidationReport? report;
  final String? failure;

  bool get isStrictPass =>
      failure == null &&
      report != null &&
      report!.errorCount == 0 &&
      report!.warningCount == 0;
}

class LabH03StrictReport {
  const LabH03StrictReport({
    required this.parseReport,
    required this.decisionResults,
  });

  final LabCanonicalDecisionBatchReport parseReport;
  final List<LabH03StrictDecisionResult> decisionResults;

  bool get isValid =>
      parseReport.isValid &&
      decisionResults.length == parseReport.decisionCount &&
      decisionResults.every((item) => item.isStrictPass);

  int get h03ErrorCount => decisionResults.fold(
    0,
    (total, item) => total + (item.report?.errorCount ?? 0),
  );

  int get h03WarningCount => decisionResults.fold(
    0,
    (total, item) => total + (item.report?.warningCount ?? 0),
  );

  int get blockedDecisionCount {
    if (!parseReport.isValid) {
      return parseReport.decisionCount;
    }

    return decisionResults.where((item) => !item.isStrictPass).length;
  }
}

/// LSP-Q5 strict LAB interpretation of the frozen H0.3 validator.
///
/// Normal CSP11 authoring keeps the original H0.3 behavior where warnings are
/// advisory and do not block. LAB publication quality is stricter: any H0.3
/// error or warning blocks the Decision.
///
/// This gate runs only after the LSP-Q4 canonical batch parse succeeds.
class LabH03StrictGate {
  const LabH03StrictGate({
    this.batchParser = const LabCanonicalDecisionBatchParser(),
    this.questionAdapter = const LabDecisionQuestionAdapter(),
  });

  final LabCanonicalDecisionBatchParser batchParser;
  final LabDecisionQuestionAdapter questionAdapter;

  static const QuestionQualityValidator _questionValidator =
      QuestionQualityValidator();

  LabH03StrictReport evaluate({
    required LabPackage package,
    required LabDqg300EvidenceBundle evidenceBundle,
  }) {
    final parseReport = batchParser.parse(
      package: package,
      evidenceBundle: evidenceBundle,
    );

    if (!parseReport.isValid) {
      return LabH03StrictReport(
        parseReport: parseReport,
        decisionResults: const <LabH03StrictDecisionResult>[],
      );
    }

    final decisions = package.nodes.whereType<LabDecisionNode>().toList();
    final results = <LabH03StrictDecisionResult>[];

    for (final parsed in parseReport.decisionResults) {
      final node = decisions[parsed.decisionIndex];
      final decisionEvidence = evidenceBundle.decisions[node.id];

      if (decisionEvidence == null) {
        results.add(
          LabH03StrictDecisionResult(
            nodeId: node.id,
            decisionIndex: parsed.decisionIndex,
            failure: 'Missing pinned DQG300 evidence for Decision ${node.id}.',
          ),
        );
        continue;
      }

      try {
        final question = questionAdapter.toQuestion(
          package: package,
          node: node,
          evidence: decisionEvidence.evidence,
          decisionIndex: parsed.decisionIndex,
        );
        final report = _questionValidator.validateReport(question);

        results.add(
          LabH03StrictDecisionResult(
            nodeId: node.id,
            decisionIndex: parsed.decisionIndex,
            report: report,
          ),
        );
      } catch (error) {
        results.add(
          LabH03StrictDecisionResult(
            nodeId: node.id,
            decisionIndex: parsed.decisionIndex,
            failure: error.toString(),
          ),
        );
      }
    }

    return LabH03StrictReport(
      parseReport: parseReport,
      decisionResults: List<LabH03StrictDecisionResult>.unmodifiable(results),
    );
  }
}
