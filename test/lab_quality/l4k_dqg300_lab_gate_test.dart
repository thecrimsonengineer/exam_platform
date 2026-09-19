import 'dart:convert';
import 'dart:io';

import 'package:exam_platform/features/lab/lab_automated_publish_gate.dart';
import 'package:exam_platform/features/lab/lab_contracts.dart';
import 'package:exam_platform/features/lab/lab_dqg300.dart';
import 'package:flutter_test/flutter_test.dart';

import '../quality_validator_contract/dqg300/_support/dqg300_fixture.dart';

String _source() =>
    File('test/fixtures/lab/l2_valid_lab.json').readAsStringSync();

LabPackage _package() => LabPackage.decode(_source());

LabDqg300EvidenceBundle _passingEvidence(LabPackage package) {
  return LabDqg300EvidenceBundle(
    labId: package.metadata.id,
    versionId: package.metadata.versionId,
    decisions: package.nodes.whereType<LabDecisionNode>().map(
      (node) => LabDqg300DecisionEvidence(
        nodeId: node.id,
        decisionSignature: LabDqg300Validator.decisionSignature(node),
        evidence: perfectDqg300Evidence(),
      ),
    ),
  );
}

void main() {
  test('L4K runs the existing DQG300 gate for every LAB decision', () {
    final package = _package();
    final report = const LabDqg300Validator().validate(
      package: package,
      evidenceBundle: _passingEvidence(package),
    );

    expect(report.isValid, isTrue);
    expect(report.decisionResults, hasLength(2));
    for (final decision in report.decisionResults) {
      expect(decision.result.isPublishable, isTrue);
      expect(decision.result.passedRuleCount, 300);
      expect(decision.result.dqs, 100);
    }
  });

  test('L4K fails closed when a Decision Node lacks DQG300 evidence', () {
    final package = _package();
    final first = package.nodes.whereType<LabDecisionNode>().first;
    final bundle = LabDqg300EvidenceBundle(
      labId: package.metadata.id,
      versionId: package.metadata.versionId,
      decisions: <LabDqg300DecisionEvidence>[
        LabDqg300DecisionEvidence(
          nodeId: first.id,
          decisionSignature: LabDqg300Validator.decisionSignature(first),
          evidence: perfectDqg300Evidence(),
        ),
      ],
    );

    final report = const LabDqg300Validator().validate(
      package: package,
      evidenceBundle: bundle,
    );

    expect(report.isValid, isFalse);
    expect(report.missingEvidenceNodeIds, contains('decision_two'));
  });

  test('L4K invalidates evidence when authored decision content changes', () {
    final package = _package();
    final nodes = package.nodes.whereType<LabDecisionNode>().toList();
    final bundle = LabDqg300EvidenceBundle(
      labId: package.metadata.id,
      versionId: package.metadata.versionId,
      decisions: <LabDqg300DecisionEvidence>[
        LabDqg300DecisionEvidence(
          nodeId: nodes[0].id,
          decisionSignature: 'stale-decision-signature',
          evidence: perfectDqg300Evidence(),
        ),
        LabDqg300DecisionEvidence(
          nodeId: nodes[1].id,
          decisionSignature: LabDqg300Validator.decisionSignature(nodes[1]),
          evidence: perfectDqg300Evidence(),
        ),
      ],
    );

    final report = const LabDqg300Validator().validate(
      package: package,
      evidenceBundle: bundle,
    );

    expect(report.isValid, isFalse);
    expect(report.staleEvidenceNodeIds, contains(nodes[0].id));
  });

  test('L4K evidence is pinned to immutable LAB ID and version', () {
    final package = _package();
    final passing = _passingEvidence(package);
    final wrongVersion = LabDqg300EvidenceBundle(
      labId: passing.labId,
      versionId: 'v2',
      decisions: passing.decisions.values,
    );

    final report = const LabDqg300Validator().validate(
      package: package,
      evidenceBundle: wrongVersion,
    );

    expect(report.isValid, isFalse);
    expect(report.pinnedVersionMatches, isFalse);
  });

  test('automated publish eligibility requires simulation plus DQG300', () {
    final source = _source();
    final decoded = jsonDecode(source) as Map;
    final root = decoded.cast<String, Object?>();
    final package = LabPackage.fromJson(root);

    final report = const LabAutomatedPublishGate().evaluate(
      package: package,
      root: root,
      dqg300Evidence: _passingEvidence(package),
    );

    expect(report.structuralReport.isValid, isTrue);
    expect(report.structuralReport.deterministic, isTrue);
    expect(report.runtimeNodeCoverageComplete, isTrue);
    expect(report.runtimeEndingCoverageComplete, isTrue);
    expect(report.dqg300Report.isValid, isTrue);
    expect(report.exhaustiveRouteReport.isValid, isTrue);
    expect(report.exhaustiveRouteReport.completeConsequenceCoverage, isTrue);
    expect(report.exhaustiveRouteReport.completeGateCoverage, isTrue);
    expect(report.exhaustiveRouteReport.completeEndingCoverage, isTrue);
    expect(report.exhaustiveRouteReport.routeInvariantsHold, isTrue);
    expect(report.exhaustiveRouteReport.uncoveredConsequenceIds, isEmpty);
    expect(report.exhaustiveRouteReport.uncoveredGateIds, isEmpty);
    expect(report.routeExplorationReport.isValid, isTrue);
    expect(report.publishEvidenceReport.isValid, isTrue);
    expect(report.publishEvidenceReport.routeEvidenceValid, isTrue);
    expect(report.isPublishable, isTrue);
  });


  test('automated publish fails closed when L4N privacy evidence is invalid', () {
    final decoded = jsonDecode(_source()) as Map;
    final root = decoded.cast<String, Object?>();
    root['learningSignals'] = <String, Object?>{
      'privacy': 'full_session_state',
    };
    final package = LabPackage.fromJson(root);

    final report = const LabAutomatedPublishGate().evaluate(
      package: package,
      root: root,
      dqg300Evidence: _passingEvidence(package),
    );

    expect(report.structuralReport.isValid, isTrue);
    expect(report.dqg300Report.isValid, isTrue);
    expect(report.exhaustiveRouteReport.isValid, isTrue);
    expect(report.routeExplorationReport.isValid, isTrue);
    expect(report.publishEvidenceReport.privacyBoundaryValid, isFalse);
    expect(report.publishEvidenceReport.isValid, isFalse);
    expect(report.isPublishable, isFalse);
  });

  test('automated publish eligibility blocks incomplete DQG300 coverage', () {
    final source = _source();
    final decoded = jsonDecode(source) as Map;
    final root = decoded.cast<String, Object?>();
    final package = LabPackage.fromJson(root);
    final first = package.nodes.whereType<LabDecisionNode>().first;

    final incomplete = LabDqg300EvidenceBundle(
      labId: package.metadata.id,
      versionId: package.metadata.versionId,
      decisions: <LabDqg300DecisionEvidence>[
        LabDqg300DecisionEvidence(
          nodeId: first.id,
          decisionSignature: LabDqg300Validator.decisionSignature(first),
          evidence: perfectDqg300Evidence(),
        ),
      ],
    );

    final report = const LabAutomatedPublishGate().evaluate(
      package: package,
      root: root,
      dqg300Evidence: incomplete,
    );

    expect(report.structuralReport.isValid, isTrue);
    expect(report.dqg300Report.isValid, isFalse);
    expect(report.isPublishable, isFalse);
  });

  test(
    'automated publish blocks an authored Story Gate with no winning route',
    () {
      final decoded = jsonDecode(_source()) as Map;
      final root = decoded.cast<String, Object?>();
      final rawGates = root['gates'] as List;
      rawGates.add(<String, Object?>{
        'id': 'unreachable_publish_gate',
        'type': 'ROUTE',
        'priority': 50,
        'fromNodeId': 'decision_one',
        'targetNodeId': 'decision_two',
        'condition': <String, Object?>{
          'op': 'NUMERIC',
          'stateId': 'risk',
          'operator': 'GT',
          'value': 99,
        },
      });
      final package = LabPackage.fromJson(root);

      final report = const LabAutomatedPublishGate().evaluate(
        package: package,
        root: root,
        dqg300Evidence: _passingEvidence(package),
      );

      expect(report.structuralReport.isValid, isTrue);
      expect(report.dqg300Report.isValid, isTrue);
      expect(report.exhaustiveRouteReport.completeGateCoverage, isFalse);
      expect(
        report.exhaustiveRouteReport.uncoveredGateIds,
        contains('unreachable_publish_gate'),
      );
      expect(report.exhaustiveRouteReport.isValid, isFalse);
      expect(report.isPublishable, isFalse);
    },
  );

  test('automated publish blocks when exhaustive route proof is capped', () {
    final source = _source();
    final decoded = jsonDecode(source) as Map;
    final root = decoded.cast<String, Object?>();
    final package = LabPackage.fromJson(root);

    final report = const LabAutomatedPublishGate().evaluate(
      package: package,
      root: root,
      dqg300Evidence: _passingEvidence(package),
      exhaustiveRouteLimit: 1,
    );

    expect(report.dqg300Report.isValid, isTrue);
    expect(report.exhaustiveRouteReport.limitExceeded, isTrue);
    expect(report.exhaustiveRouteReport.isValid, isFalse);
    expect(report.isPublishable, isFalse);
  });
}
