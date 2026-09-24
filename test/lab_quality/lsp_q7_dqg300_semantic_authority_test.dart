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

LabPackage _package() {
  final decoded = jsonDecode(_source()) as Map;
  final root = decoded.cast<String, Object?>();
  final nodes = root['nodes'] as List;

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

  root['nodes'] = nodes;
  return LabPackage.fromJson(root);
}

List<LabDecisionNode> _decisions(LabPackage package) =>
    package.nodes.whereType<LabDecisionNode>().toList(growable: false);

LabDqg300EvidenceBundle _bundleFor(
  LabPackage package, {
  QuestionQualityEvidence? firstEvidence,
}) {
  final decisions = _decisions(package);

  return LabDqg300EvidenceBundle(
    labId: package.metadata.id,
    versionId: package.metadata.versionId,
    decisions: [
      for (var index = 0; index < decisions.length; index++)
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

void _expectSemanticBlock({
  required LabDecisionQualityReport report,
  required String expectedFailedRule,
}) {
  final first = report.decisionResults.first;

  expect(first.canonicalParsePass, isTrue);
  expect(first.strictH03Pass, isTrue);
  expect(first.h03ErrorCount, 0);
  expect(first.h03WarningCount, 0);

  expect(first.dqg300SemanticPass, isFalse);
  expect(first.dqg300Pass, isFalse);
  expect(first.dqg300AtomicRulesPass, isFalse);
  expect(first.dqg300DerivedPass, isFalse);
  expect(first.dqg300FailedRuleCount, greaterThan(0));
  expect(first.dqg300Result!.result.rule(expectedFailedRule).passed, isFalse);

  expect(first.isPass, isFalse);
  expect(report.isValid, isFalse);
}

void main() {
  const gate = LabDecisionQualityGate();

  test('Q7 exposes a complete 300/300 DQG semantic witness on PASS', () {
    final package = _package();

    final report = gate.evaluate(
      package: package,
      evidenceBundle: _bundleFor(package),
    );

    expect(report.isValid, isTrue);

    for (final item in report.decisionResults) {
      expect(item.strictH03Pass, isTrue);
      expect(item.dqg300AtomicRulesPass, isTrue);
      expect(item.dqg300DerivedPass, isTrue);
      expect(item.dqg300DqsPerfect, isTrue);
      expect(item.dqg300SemanticPass, isTrue);
      expect(item.dqg300PassedRuleCount, 300);
      expect(item.dqg300FailedRuleCount, 0);
      expect(item.dqs, 100);
      expect(item.isPass, isTrue);
    }
  });

  test('Q7 manual override cannot bypass DQG300 through H0.3', () {
    final package = _package();
    final evidence = perfectDqg300Evidence().copyWith(
      manualOverrideRequested: true,
    );

    final report = gate.evaluate(
      package: package,
      evidenceBundle: _bundleFor(package, firstEvidence: evidence),
    );

    _expectSemanticBlock(report: report, expectedFailedRule: 'DQG-299');
  });

  test('Q7 unresolved semantic warning cannot be treated as H0.3 warning', () {
    final package = _package();
    final evidence = perfectDqg300Evidence().copyWith(
      unresolvedWarningCount: 1,
    );

    final report = gate.evaluate(
      package: package,
      evidenceBundle: _bundleFor(package, firstEvidence: evidence),
    );

    _expectSemanticBlock(report: report, expectedFailedRule: 'DQG-255');
  });

  test('Q7 unverified source authority remains a DQG semantic blocker', () {
    final package = _package();
    final evidence = perfectDqg300Evidence().copyWith(
      sourceAuthorityVerified: false,
    );

    final report = gate.evaluate(
      package: package,
      evidenceBundle: _bundleFor(package, firstEvidence: evidence),
    );

    _expectSemanticBlock(report: report, expectedFailedRule: 'DQG-187');
  });

  test('Q7 ambiguity remains blocking after canonical and H0.3 PASS', () {
    final package = _package();
    final evidence = perfectDqg300Evidence().copyWith(ambiguityDetected: true);

    final report = gate.evaluate(
      package: package,
      evidenceBundle: _bundleFor(package, firstEvidence: evidence),
    );

    _expectSemanticBlock(report: report, expectedFailedRule: 'DQG-019');
  });

  test('Q7 unsupported key assumption remains a DQG semantic blocker', () {
    final package = _package();
    final evidence = perfectDqg300Evidence().copyWith(
      keyRequiresNoUnstatedAssumption: false,
    );

    final report = gate.evaluate(
      package: package,
      evidenceBundle: _bundleFor(package, firstEvidence: evidence),
    );

    _expectSemanticBlock(report: report, expectedFailedRule: 'DQG-180');
  });

  test(
    'Q7 semantic option duplication is not diluted to literal H0.3 checks',
    () {
      final package = _package();
      final evidence = perfectDqg300Evidence().copyWith(
        semanticDuplicateOptionsDetected: true,
      );

      final report = gate.evaluate(
        package: package,
        evidenceBundle: _bundleFor(package, firstEvidence: evidence),
      );

      _expectSemanticBlock(report: report, expectedFailedRule: 'DQG-021');
    },
  );

  test('Q7 DQG semantic authority remains deterministic', () {
    final package = _package();
    final evidence = perfectDqg300Evidence().copyWith(
      sourceAuthorityVerified: false,
      ambiguityDetected: true,
      unresolvedWarningCount: 1,
    );
    final bundle = _bundleFor(package, firstEvidence: evidence);

    final first = gate.evaluate(package: package, evidenceBundle: bundle);
    final second = gate.evaluate(package: package, evidenceBundle: bundle);

    expect(
      first.decisionResults
          .map(
            (item) => <Object?>[
              item.nodeId,
              item.strictH03Pass,
              item.dqg300AtomicRulesPass,
              item.dqg300DerivedPass,
              item.dqg300DqsPerfect,
              item.dqg300SemanticPass,
              item.dqg300PassedRuleCount,
              item.dqg300FailedRuleCount,
              item.isPass,
            ],
          )
          .toList(),
      second.decisionResults
          .map(
            (item) => <Object?>[
              item.nodeId,
              item.strictH03Pass,
              item.dqg300AtomicRulesPass,
              item.dqg300DerivedPass,
              item.dqg300DqsPerfect,
              item.dqg300SemanticPass,
              item.dqg300PassedRuleCount,
              item.dqg300FailedRuleCount,
              item.isPass,
            ],
          )
          .toList(),
    );
  });
}
