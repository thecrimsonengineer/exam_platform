import 'dart:convert';
import 'dart:io';

import 'package:exam_platform/features/lab/lab_contracts.dart';
import 'package:exam_platform/features/lab/lab_dqg300.dart';
import 'package:exam_platform/features/lab/lab_h0_3_strict_gate.dart';
import 'package:flutter_test/flutter_test.dart';

import '../quality_validator_contract/dqg300/_support/dqg300_fixture.dart';

String _source() =>
    File('test/fixtures/lab/l2_valid_lab.json').readAsStringSync();

LabPackage _package({
  bool strongPrompts = false,
  bool includeSources = true,
  bool firstBestLengthBias = false,
}) {
  final decoded = jsonDecode(_source()) as Map;
  final root = decoded.cast<String, Object?>();
  final nodes = root['nodes'] as List;

  for (var index = 0; index < nodes.length; index++) {
    final node = (nodes[index] as Map).cast<String, Object?>();
    if (node['type'] != 'DECISION') {
      continue;
    }

    if (strongPrompts) {
      node['prompt'] =
          'During a complex high-risk operation, changing conditions create '
          'competing safety priorities and require a defensible professional '
          'decision. Which action should the safety professional select first '
          'for Decision ${index + 1} to control the stated risk effectively?';
    }

    if (firstBestLengthBias && index == 0) {
      final options = node['options'] as List;
      final best = (options[0] as Map).cast<String, Object?>();
      best['text'] =
          'Implement the complete engineered isolation and verification '
          'sequence before allowing the high-risk task to continue under '
          'controlled operating conditions.';
      options[0] = best;
    }

    nodes[index] = node;
  }

  root['nodes'] = nodes;
  if (!includeSources) {
    root['sources'] = <String>[];
  }

  return LabPackage.fromJson(root);
}

List<LabDecisionNode> _decisions(LabPackage package) =>
    package.nodes.whereType<LabDecisionNode>().toList(growable: false);

LabDqg300EvidenceBundle _bundleFor(LabPackage package) {
  return LabDqg300EvidenceBundle(
    labId: package.metadata.id,
    versionId: package.metadata.versionId,
    decisions: [
      for (final node in _decisions(package))
        LabDqg300DecisionEvidence(
          nodeId: node.id,
          decisionSignature: LabDqg300Validator.decisionSignature(node),
          evidence: perfectDqg300Evidence(),
        ),
    ],
  );
}

void main() {
  const gate = LabH03StrictGate();

  test('Q5 passes only when every Decision has zero H0.3 issues', () {
    final package = _package(strongPrompts: true);

    final report = gate.evaluate(
      package: package,
      evidenceBundle: _bundleFor(package),
    );

    expect(report.parseReport.isValid, isTrue);
    expect(report.isValid, isTrue);
    expect(report.h03ErrorCount, 0);
    expect(report.h03WarningCount, 0);
    expect(report.blockedDecisionCount, 0);
    expect(report.decisionResults, hasLength(_decisions(package).length));
    expect(report.decisionResults.every((item) => item.isStrictPass), isTrue);
  });

  test('Q5 blocks H0.3 warnings even when normal H0.3 says PASSED', () {
    final package = _package();

    final report = gate.evaluate(
      package: package,
      evidenceBundle: _bundleFor(package),
    );

    expect(report.parseReport.isValid, isTrue);
    expect(report.isValid, isFalse);
    expect(report.h03ErrorCount, 0);
    expect(report.h03WarningCount, greaterThan(0));
    expect(report.blockedDecisionCount, report.parseReport.decisionCount);

    for (final item in report.decisionResults) {
      expect(item.report, isNotNull);
      expect(item.report!.passed, isTrue);
      expect(item.report!.blocked, isFalse);
      expect(item.report!.warningCount, greaterThan(0));
      expect(item.isStrictPass, isFalse);
    }
  });

  test('Q5 blocks normal H0.3 errors', () {
    final package = _package(strongPrompts: true, includeSources: false);

    final report = gate.evaluate(
      package: package,
      evidenceBundle: _bundleFor(package),
    );

    expect(report.parseReport.isValid, isTrue);
    expect(report.isValid, isFalse);
    expect(report.h03ErrorCount, greaterThan(0));
    expect(
      report.decisionResults.first.report!.issues.map((issue) => issue.code),
      contains('missing_reference'),
    );
    expect(report.decisionResults.first.isStrictPass, isFalse);
  });

  test('Q5 treats answer-length warnings as publication blockers', () {
    final package = _package(strongPrompts: true, firstBestLengthBias: true);

    final report = gate.evaluate(
      package: package,
      evidenceBundle: _bundleFor(package),
    );

    final first = report.decisionResults.first;
    final codes = first.report!.issues.map((issue) => issue.code).toSet();

    expect(report.parseReport.isValid, isTrue);
    expect(report.isValid, isFalse);
    expect(first.report!.passed, isTrue);
    expect(codes, contains('best_answer_length_bias'));
    expect(first.isStrictPass, isFalse);
  });

  test('Q5 does not run H0.3 when the Q4 parse prerequisite fails', () {
    final package = _package(strongPrompts: true);
    final valid = _bundleFor(package);
    final mismatched = LabDqg300EvidenceBundle(
      labId: package.metadata.id,
      versionId: 'v2',
      decisions: valid.decisions.values,
    );

    final report = gate.evaluate(package: package, evidenceBundle: mismatched);

    expect(report.parseReport.isValid, isFalse);
    expect(report.decisionResults, isEmpty);
    expect(report.isValid, isFalse);
    expect(report.blockedDecisionCount, report.parseReport.decisionCount);
  });

  test('Q5 is deterministic across repeated strict validation', () {
    final package = _package(strongPrompts: true, firstBestLengthBias: true);
    final bundle = _bundleFor(package);

    final first = gate.evaluate(package: package, evidenceBundle: bundle);
    final second = gate.evaluate(package: package, evidenceBundle: bundle);

    expect(first.isValid, second.isValid);
    expect(first.h03ErrorCount, second.h03ErrorCount);
    expect(first.h03WarningCount, second.h03WarningCount);
    expect(first.blockedDecisionCount, second.blockedDecisionCount);
    expect(
      first.decisionResults
          .map(
            (item) => item.report?.issues.map((issue) => issue.code).toList(),
          )
          .toList(),
      second.decisionResults
          .map(
            (item) => item.report?.issues.map((issue) => issue.code).toList(),
          )
          .toList(),
    );
  });
}
