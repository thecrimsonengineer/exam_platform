import 'dart:io';

import 'package:exam_platform/features/lab/lab_canonical_decision_batch_parser.dart';
import 'package:exam_platform/features/lab/lab_contracts.dart';
import 'package:exam_platform/features/lab/lab_dqg300.dart';
import 'package:flutter_test/flutter_test.dart';

import '../quality_validator_contract/dqg300/_support/dqg300_fixture.dart';

String _source() =>
    File('test/fixtures/lab/l2_valid_lab.json').readAsStringSync();

LabPackage _package() => LabPackage.decode(_source());

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
  const parser = LabCanonicalDecisionBatchParser();

  test('Q4 runs every authored Decision through the canonical parser', () {
    final package = _package();
    final decisions = _decisions(package);

    final report = parser.parse(
      package: package,
      evidenceBundle: _bundleFor(package),
    );

    expect(report.isValid, isTrue);
    expect(report.decisionCount, decisions.length);
    expect(report.parsedDecisionCount, decisions.length);
    expect(report.blockedDecisionCount, 0);
    expect(
      report.decisionResults.map((item) => item.nodeId),
      decisions.map((node) => node.id),
    );

    for (final item in report.decisionResults) {
      final node = decisions[item.decisionIndex];
      expect(item.isParsed, isTrue);
      expect(item.draft, isNotNull);
      expect(item.draft!.question, node.prompt);
      expect(item.draft!.options, node.options.map((option) => option.text));
      expect(item.draft!.questionType, 'scenario_mcq');
      expect(item.draft!.difficulty, 'Hard');
      expect(item.draft!.explanation, isNotEmpty);
      expect(item.draft!.bestAnswerRationale, isNotEmpty);
    }
  });

  test('Q4 reports missing evidence and blocks only that Decision', () {
    final package = _package();
    final decisions = _decisions(package);
    final first = decisions.first;

    final bundle = LabDqg300EvidenceBundle(
      labId: package.metadata.id,
      versionId: package.metadata.versionId,
      decisions: [
        for (final node in decisions.skip(1))
          LabDqg300DecisionEvidence(
            nodeId: node.id,
            decisionSignature: LabDqg300Validator.decisionSignature(node),
            evidence: perfectDqg300Evidence(),
          ),
      ],
    );

    final report = parser.parse(package: package, evidenceBundle: bundle);

    expect(report.isValid, isFalse);
    expect(report.missingEvidenceNodeIds, contains(first.id));
    expect(report.blockedDecisionCount, 1);
    expect(report.decisionResults.first.isParsed, isFalse);
  });

  test('Q4 rejects stale Decision evidence before canonical parsing', () {
    final package = _package();
    final decisions = _decisions(package);
    final first = decisions.first;

    final bundle = LabDqg300EvidenceBundle(
      labId: package.metadata.id,
      versionId: package.metadata.versionId,
      decisions: [
        for (var index = 0; index < decisions.length; index++)
          LabDqg300DecisionEvidence(
            nodeId: decisions[index].id,
            decisionSignature: index == 0
                ? 'stale-signature'
                : LabDqg300Validator.decisionSignature(decisions[index]),
            evidence: perfectDqg300Evidence(),
          ),
      ],
    );

    final report = parser.parse(package: package, evidenceBundle: bundle);

    expect(report.isValid, isFalse);
    expect(report.staleEvidenceNodeIds, contains(first.id));
    expect(report.blockedDecisionCount, 1);
    expect(report.decisionResults.first.failure, contains('Stale'));
  });

  test('Q4 blocks the complete batch when the evidence version is unpinned', () {
    final package = _package();
    final valid = _bundleFor(package);

    final mismatched = LabDqg300EvidenceBundle(
      labId: package.metadata.id,
      versionId: 'v2',
      decisions: valid.decisions.values,
    );

    final report = parser.parse(package: package, evidenceBundle: mismatched);

    expect(report.isValid, isFalse);
    expect(report.pinnedVersionMatches, isFalse);
    expect(report.parsedDecisionCount, 0);
    expect(report.blockedDecisionCount, report.decisionCount);
  });

  test('Q4 captures canonical conversion failure per Decision', () {
    final package = _package();
    final decisions = _decisions(package);

    final bundle = LabDqg300EvidenceBundle(
      labId: package.metadata.id,
      versionId: package.metadata.versionId,
      decisions: [
        for (var index = 0; index < decisions.length; index++)
          LabDqg300DecisionEvidence(
            nodeId: decisions[index].id,
            decisionSignature: LabDqg300Validator.decisionSignature(
              decisions[index],
            ),
            evidence: index == 0
                ? perfectDqg300Evidence().copyWith(
                    decisiveScenarioFacts: const <String>[],
                  )
                : perfectDqg300Evidence(),
          ),
      ],
    );

    final report = parser.parse(package: package, evidenceBundle: bundle);

    expect(report.isValid, isFalse);
    expect(report.blockedDecisionCount, 1);
    expect(
      report.decisionResults.first.failure,
      contains('decisiveScenarioFacts'),
    );
  });

  test('Q4 reports unexpected evidence IDs without silently accepting them', () {
    final package = _package();
    final valid = _bundleFor(package);

    final bundle = LabDqg300EvidenceBundle(
      labId: package.metadata.id,
      versionId: package.metadata.versionId,
      decisions: [
        ...valid.decisions.values,
        LabDqg300DecisionEvidence(
          nodeId: 'unexpected_decision',
          decisionSignature: 'unexpected-signature',
          evidence: perfectDqg300Evidence(),
        ),
      ],
    );

    final report = parser.parse(package: package, evidenceBundle: bundle);

    expect(report.isValid, isFalse);
    expect(report.unexpectedEvidenceNodeIds, contains('unexpected_decision'));
    expect(report.parsedDecisionCount, report.decisionCount);
  });
}
