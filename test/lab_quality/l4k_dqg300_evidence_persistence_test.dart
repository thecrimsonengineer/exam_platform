import 'dart:io';

import 'package:exam_platform/features/lab/lab_automated_lifecycle.dart';
import 'package:exam_platform/features/lab/lab_contracts.dart';
import 'package:exam_platform/features/lab/lab_dqg300.dart';
import 'package:exam_platform/features/lab/lab_dqg300_evidence_store.dart';
import 'package:exam_platform/features/lab/lab_studio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../quality_validator_contract/dqg300/_support/dqg300_fixture.dart';

String _source() =>
    File('test/fixtures/lab/l2_valid_lab.json').readAsStringSync();

LabDqg300EvidenceBundle _bundle(LabPackage package) {
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
  test('full DQG300-LAB evidence bundle round-trips and revalidates', () {
    final package = LabPackage.decode(_source());
    final bundle = _bundle(package);
    const codec = LabDqg300EvidenceCodec();

    final encoded = codec.encode(bundle);
    final restored = codec.decode(encoded);
    final result = const LabDqg300Validator().validate(
      package: package,
      evidenceBundle: restored,
    );

    expect(restored.labId, bundle.labId);
    expect(restored.versionId, bundle.versionId);
    expect(restored.decisions.keys, bundle.decisions.keys);
    expect(result.isValid, isTrue);
    expect(
      result.decisionResults.every((item) => item.result.dqs == 100),
      isTrue,
    );
  });

  test('persisted DQG300-LAB evidence can drive automated publish', () async {
    final publishedRepository = InMemoryLabPublishedRepository();
    final evidenceRepository = InMemoryLabDqg300EvidenceRepository();
    final studio = Lab1000StudioService(repository: publishedRepository);
    final draft = studio.importJson(_source());

    await evidenceRepository.save(_bundle(draft.package));

    final result =
        await LabAutomatedLifecycleService(
          studio: studio,
          evidenceRepository: evidenceRepository,
        ).validateAndPublishStored(
          workspace: draft,
          validatedAt: DateTime.utc(2026, 9, 19, 6),
        );

    expect(result.workspace.lifecycle, LabLifecycleStatus.published);
    expect(result.gateReport.dqg300Report.isValid, isTrue);
    expect(result.gateReport.exhaustiveRouteReport.isValid, isTrue);
    expect(result.certificate.isPass, isTrue);
  });

  test(
    'stored evidence becomes stale when decision signature changes',
    () async {
      final package = LabPackage.decode(_source());
      final repository = InMemoryLabDqg300EvidenceRepository();
      final bundle = _bundle(package);
      await repository.save(bundle);

      final restored = await repository.load(
        package.metadata.id,
        package.metadata.versionId,
      );
      expect(restored, isNotNull);

      final first = package.nodes.whereType<LabDecisionNode>().first;
      final staleDecisions = restored!.decisions.values.map((item) {
        if (item.nodeId != first.id) return item;
        return LabDqg300DecisionEvidence(
          nodeId: item.nodeId,
          decisionSignature: 'changed-authoring-content',
          evidence: item.evidence,
        );
      });

      final stale = LabDqg300EvidenceBundle(
        labId: restored.labId,
        versionId: restored.versionId,
        decisions: staleDecisions,
      );
      final report = const LabDqg300Validator().validate(
        package: package,
        evidenceBundle: stale,
      );

      expect(report.isValid, isFalse);
      expect(report.staleEvidenceNodeIds, contains(first.id));
    },
  );
}
