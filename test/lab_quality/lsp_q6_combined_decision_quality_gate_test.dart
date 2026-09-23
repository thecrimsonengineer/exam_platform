import 'dart:convert';
import 'dart:io';

import 'package:exam_platform/features/lab/lab_contracts.dart';
import 'package:exam_platform/features/lab/lab_decision_quality_gate.dart';
import 'package:exam_platform/features/lab/lab_dqg300.dart';
import 'package:exam_platform/models/question_quality_evidence.dart';
import 'package:flutter_test/flutter_test.dart';

import '../quality_validator_contract/dqg300/_support/dqg300_fixture.dart';

String _source() =>
    File('test/fixtures/lab/l2_valid_lab.json').readAsStringSync();

LabPackage _package({bool strongPrompts = true}) {
  final decoded = jsonDecode(_source()) as Map;
  final root = decoded.cast<String, Object?>();
  final nodes = root['nodes'] as List;

  if (strongPrompts) {
    for (var index = 0; index < nodes.length; index++) {
      final node = (nodes[index] as Map).cast<String, Object?>();
      if (node['type'] != 'DECISION') {
        continue;
      }

      node['prompt'] =
          'During a complex high-risk operation, changing conditions create '
          'competing safety priorities and require a defensible professional '
          'decision. Which action should the safety professional select first '
          'for Decision ${index + 1} to control the stated risk effectively?';
      nodes[index] = node;
    }
  }

  root['nodes'] = nodes;
  return LabPackage.fromJson(root);
}

List<LabDecisionNode> _decisions(LabPackage package) =>
    package.nodes.whereType<LabDecisionNode>().toList(growable: false);

LabDqg300EvidenceBundle _bundleFor(
  LabPackage package, {
  QuestionQualityEvidence? firstEvidence,
  bool omitLastDecision = false,
}) {
  final decisions = _decisions(package);

  return LabDqg300EvidenceBundle(
    labId: package.metadata.id,
    versionId: package.metadata.versionId,
    decisions: [
      for (var index = 0; index < decisions.length; index++)
        if (!(omitLastDecision && index == decisions.length - 1))
          LabDqg300DecisionEvidence(
            nodeId: decisions[index].id,
            decisionSignature: LabDqg300Validator.decisionSignature(
              decisions[index],
            ),
            evidence: index == 0 && firstEvidence != null
                ? firstEvidence
                : perfectDqg300Evidence(),
          ),
    ],
  );
}

void main() {
  const gate = LabDecisionQualityGate();

  test('Q6 passes only when parse, strict H0.3, DQG300 and DQS all pass', () {
    final package = _package();

    final report = gate.evaluate(
      package: package,
      evidenceBundle: _bundleFor(package),
    );

    expect(report.isValid, isTrue);
    expect(report.decisionCount, _decisions(package).length);
    expect(report.passedDecisionCount, report.decisionCount);
    expect(report.blockedDecisionCount, 0);
    expect(report.h03Report.isValid, isTrue);
    expect(report.dqg300Report.isValid, isTrue);

    for (final item in report.decisionResults) {
      expect(item.canonicalParsePass, isTrue);
      expect(item.strictH03Pass, isTrue);
      expect(item.dqg300Pass, isTrue);
      expect(item.dqs, 100);
      expect(item.dqg300Result!.result.rule('DQG-300').passed, isTrue);
      expect(item.isPass, isTrue);
    }
  });

  test('Q6 blocks a Decision when strict H0.3 warns but DQG300 passes', () {
    final package = _package(strongPrompts: false);

    final report = gate.evaluate(
      package: package,
      evidenceBundle: _bundleFor(package),
    );

    expect(report.isValid, isFalse);
    expect(report.h03Report.isValid, isFalse);
    expect(report.dqg300Report.isValid, isTrue);

    for (final item in report.decisionResults) {
      expect(item.canonicalParsePass, isTrue);
      expect(item.strictH03Pass, isFalse);
      expect(item.h03WarningCount, greaterThan(0));
      expect(item.dqg300Pass, isTrue);
      expect(item.dqs, 100);
      expect(item.isPass, isFalse);
    }
  });

  test('Q6 blocks a Decision when DQG300 fails despite strict H0.3 pass', () {
    final package = _package();
    final failedEvidence = failRuleProof(perfectDqg300Evidence(), 'DQG-001');

    final report = gate.evaluate(
      package: package,
      evidenceBundle: _bundleFor(package, firstEvidence: failedEvidence),
    );

    final first = report.decisionResults.first;

    expect(report.isValid, isFalse);
    expect(report.h03Report.isValid, isTrue);
    expect(first.canonicalParsePass, isTrue);
    expect(first.strictH03Pass, isTrue);
    expect(first.dqg300Pass, isFalse);
    expect(first.dqs, 100);
    expect(first.dqg300Result!.result.rule('DQG-001').passed, isFalse);
    expect(first.dqg300Result!.result.rule('DQG-300').passed, isFalse);
    expect(first.isPass, isFalse);
  });

  test('Q6 explicitly blocks DQS below 100', () {
    final package = _package();
    final evidence = perfectDqg300Evidence();
    final weakenedDistractor = evidence.distractors.first.copyWith(
      plausibilityScore: 4,
    );
    final lowDqsEvidence = replaceDqg300Distractor(
      evidence,
      0,
      weakenedDistractor,
    );

    final report = gate.evaluate(
      package: package,
      evidenceBundle: _bundleFor(package, firstEvidence: lowDqsEvidence),
    );

    final first = report.decisionResults.first;

    expect(first.canonicalParsePass, isTrue);
    expect(first.strictH03Pass, isTrue);
    expect(first.dqs, lessThan(100));
    expect(first.dqg300Pass, isFalse);
    expect(first.isPass, isFalse);
    expect(report.isValid, isFalse);
  });

  test('Q6 keeps one combined result per Decision when Q4 parse fails', () {
    final package = _package();
    final bundle = _bundleFor(package, omitLastDecision: true);

    final report = gate.evaluate(package: package, evidenceBundle: bundle);

    expect(report.h03Report.parseReport.isValid, isFalse);
    expect(report.h03Report.decisionResults, isEmpty);
    expect(report.dqg300Report.decisionResults, isEmpty);
    expect(report.decisionResults, hasLength(_decisions(package).length));
    expect(report.passedDecisionCount, 0);
    expect(report.blockedDecisionCount, report.decisionCount);
    expect(report.decisionResults.every((item) => !item.isPass), isTrue);
    expect(report.isValid, isFalse);
  });

  test('Q6 preserves authored Decision order in the combined report', () {
    final package = _package();
    final decisions = _decisions(package);

    final report = gate.evaluate(
      package: package,
      evidenceBundle: _bundleFor(package),
    );

    expect(
      report.decisionResults.map((item) => item.nodeId),
      decisions.map((node) => node.id),
    );
    expect(
      report.decisionResults.map((item) => item.decisionIndex),
      List<int>.generate(decisions.length, (index) => index),
    );
  });

  test('Q6 combined Decision-quality result is deterministic', () {
    final package = _package();
    final bundle = _bundleFor(package);

    final first = gate.evaluate(package: package, evidenceBundle: bundle);
    final second = gate.evaluate(package: package, evidenceBundle: bundle);

    expect(first.isValid, second.isValid);
    expect(first.passedDecisionCount, second.passedDecisionCount);
    expect(first.blockedDecisionCount, second.blockedDecisionCount);
    expect(
      first.decisionResults
          .map(
            (item) => <Object?>[
              item.nodeId,
              item.canonicalParsePass,
              item.strictH03Pass,
              item.dqg300Pass,
              item.dqs,
              item.isPass,
            ],
          )
          .toList(),
      second.decisionResults
          .map(
            (item) => <Object?>[
              item.nodeId,
              item.canonicalParsePass,
              item.strictH03Pass,
              item.dqg300Pass,
              item.dqs,
              item.isPass,
            ],
          )
          .toList(),
    );
  });
}
