import 'lab_canonical_decision_batch_parser.dart';
import 'lab_contracts.dart';
import 'lab_dqg300.dart';
import 'lab_h0_3_strict_gate.dart';

class LabDecisionQualityResult {
  const LabDecisionQualityResult({
    required this.nodeId,
    required this.decisionIndex,
    required this.parseResult,
    this.h03Result,
    this.dqg300Result,
  });

  final String nodeId;
  final int decisionIndex;
  final LabCanonicalDecisionParseResult parseResult;
  final LabH03StrictDecisionResult? h03Result;
  final LabDqg300DecisionResult? dqg300Result;

  bool get canonicalParsePass => parseResult.isParsed;

  bool get strictH03Pass => h03Result?.isStrictPass == true;

  bool get dqg300Pass {
    final result = dqg300Result?.result;
    if (result == null) {
      return false;
    }

    return result.isPublishable &&
        result.dqs == 100 &&
        result.rule('DQG-300').passed;
  }

  int? get dqs => dqg300Result?.result.dqs;

  int get h03ErrorCount => h03Result?.report?.errorCount ?? 0;

  int get h03WarningCount => h03Result?.report?.warningCount ?? 0;

  bool get isPass => canonicalParsePass && strictH03Pass && dqg300Pass;
}

class LabDecisionQualityReport {
  const LabDecisionQualityReport({
    required this.h03Report,
    required this.dqg300Report,
    required this.decisionResults,
  });

  final LabH03StrictReport h03Report;
  final LabDqg300Report dqg300Report;
  final List<LabDecisionQualityResult> decisionResults;

  int get decisionCount => h03Report.parseReport.decisionCount;

  int get passedDecisionCount =>
      decisionResults.where((item) => item.isPass).length;

  int get blockedDecisionCount => decisionCount - passedDecisionCount;

  bool get isValid =>
      h03Report.parseReport.isValid &&
      h03Report.isValid &&
      dqg300Report.isValid &&
      decisionResults.length == decisionCount &&
      decisionResults.every((item) => item.isPass);
}

/// LSP-Q6 combined LAB Decision-quality gate.
///
/// This orchestration layer preserves the Q4 canonical parse result, the Q5
/// strict H0.3 result, and the existing DQG300 result. It does not reimplement
/// or weaken any underlying rule.
///
/// DecisionQualityPass =
/// CanonicalParsePass &&
/// H0_3Errors == 0 &&
/// H0_3Warnings == 0 &&
/// DQG300Pass &&
/// DQS == 100.
class LabDecisionQualityGate {
  const LabDecisionQualityGate({
    this.h03Gate = const LabH03StrictGate(),
    this.dqg300Validator = const LabDqg300Validator(),
  });

  final LabH03StrictGate h03Gate;
  final LabDqg300Validator dqg300Validator;

  LabDecisionQualityReport evaluate({
    required LabPackage package,
    required LabDqg300EvidenceBundle evidenceBundle,
  }) {
    final h03Report = h03Gate.evaluate(
      package: package,
      evidenceBundle: evidenceBundle,
    );
    final parseReport = h03Report.parseReport;

    final dqg300Report = parseReport.isValid
        ? dqg300Validator.validate(
            package: package,
            evidenceBundle: evidenceBundle,
          )
        : LabDqg300Report(
            decisionResults: const <LabDqg300DecisionResult>[],
            missingEvidenceNodeIds: parseReport.missingEvidenceNodeIds,
            staleEvidenceNodeIds: parseReport.staleEvidenceNodeIds,
            unexpectedEvidenceNodeIds: parseReport.unexpectedEvidenceNodeIds,
            pinnedVersionMatches: parseReport.pinnedVersionMatches,
          );

    final h03ByNode = <String, LabH03StrictDecisionResult>{
      for (final item in h03Report.decisionResults) item.nodeId: item,
    };
    final dqgByNode = <String, LabDqg300DecisionResult>{
      for (final item in dqg300Report.decisionResults) item.nodeId: item,
    };

    final results = <LabDecisionQualityResult>[
      for (final parsed in parseReport.decisionResults)
        LabDecisionQualityResult(
          nodeId: parsed.nodeId,
          decisionIndex: parsed.decisionIndex,
          parseResult: parsed,
          h03Result: h03ByNode[parsed.nodeId],
          dqg300Result: dqgByNode[parsed.nodeId],
        ),
    ];

    return LabDecisionQualityReport(
      h03Report: h03Report,
      dqg300Report: dqg300Report,
      decisionResults: List<LabDecisionQualityResult>.unmodifiable(results),
    );
  }
}
