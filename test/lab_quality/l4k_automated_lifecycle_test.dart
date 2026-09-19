import 'dart:io';

import 'package:exam_platform/features/lab/lab_automated_lifecycle.dart';
import 'package:exam_platform/features/lab/lab_contracts.dart';
import 'package:exam_platform/features/lab/lab_dqg300.dart';
import 'package:exam_platform/features/lab/lab_dqg300_certificate.dart';
import 'package:exam_platform/features/lab/lab_studio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../quality_validator_contract/dqg300/_support/dqg300_fixture.dart';

String _source() =>
    File('test/fixtures/lab/l2_valid_lab.json').readAsStringSync();

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
  test(
    'L4K automated lifecycle publishes DRAFT without human approval',
    () async {
      final repository = InMemoryLabPublishedRepository();
      final studio = Lab1000StudioService(repository: repository);
      final draft = studio.importJson(_source());
      final service = LabAutomatedLifecycleService(studio: studio);

      final result = await service.validateAndPublish(
        workspace: draft,
        dqg300Evidence: _passingEvidence(draft.package),
        validatedAt: DateTime.utc(2026, 9, 19, 5),
        publishedAt: DateTime.utc(2026, 9, 19, 5, 1),
      );

      expect(result.workspace.lifecycle, LabLifecycleStatus.published);
      expect(result.workspace.reviewerId, 'DQG300-LAB-AUTO');
      expect(result.gateReport.isPublishable, isTrue);
      expect(result.certificate.isPass, isTrue);

      final stored = await repository.load('l2_lab', 'v1');
      expect(stored, isNotNull);
      expect(stored!.validationAuthority, 'DQG300-LAB-AUTO');
      expect(stored.qualityEvidenceJson, isNotNull);
    },
  );

  test('persisted DQG300-LAB certificate round-trips exactly', () async {
    final repository = InMemoryLabPublishedRepository();
    final studio = Lab1000StudioService(repository: repository);
    final draft = studio.importJson(_source());

    final result = await LabAutomatedLifecycleService(studio: studio)
        .validateAndPublish(
          workspace: draft,
          dqg300Evidence: _passingEvidence(draft.package),
          validatedAt: DateTime.utc(2026, 9, 19, 5),
        );

    final encoded = result.certificate.encode();
    final restored = LabDqg300EvidenceCertificate.decode(encoded);

    expect(restored.labId, draft.package.metadata.id);
    expect(restored.versionId, draft.package.metadata.versionId);
    expect(restored.validationAuthority, 'DQG300-LAB-AUTO');
    expect(restored.decisions, hasLength(2));
    expect(restored.isPass, isTrue);
    expect(restored.encode(), encoded);
  });

  test(
    'automated lifecycle fails closed without complete DQG300 evidence',
    () async {
      final repository = InMemoryLabPublishedRepository();
      final studio = Lab1000StudioService(repository: repository);
      final draft = studio.importJson(_source());
      final first = draft.package.nodes.whereType<LabDecisionNode>().first;
      final incomplete = LabDqg300EvidenceBundle(
        labId: draft.package.metadata.id,
        versionId: draft.package.metadata.versionId,
        decisions: <LabDqg300DecisionEvidence>[
          LabDqg300DecisionEvidence(
            nodeId: first.id,
            decisionSignature: LabDqg300Validator.decisionSignature(first),
            evidence: perfectDqg300Evidence(),
          ),
        ],
      );

      await expectLater(
        LabAutomatedLifecycleService(
          studio: studio,
        ).validateAndPublish(workspace: draft, dqg300Evidence: incomplete),
        throwsA(isA<LabStudioException>()),
      );

      expect(await repository.load('l2_lab', 'v1'), isNull);
    },
  );

  test('legacy human-review publish API remains available', () async {
    final repository = InMemoryLabPublishedRepository();
    final studio = Lab1000StudioService(repository: repository);
    final draft = studio.importJson(_source());
    final review = studio.requestReview(draft);
    final validated = studio.approveReview(
      review,
      reviewerId: 'legacy-reviewer',
    );
    final published = await studio.publish(validated);

    expect(published.lifecycle, LabLifecycleStatus.published);
    expect(published.reviewerId, 'legacy-reviewer');
    expect(published.publishedVersion!.validationAuthority, isNull);
    expect(published.publishedVersion!.qualityEvidenceJson, isNull);
  });
}
