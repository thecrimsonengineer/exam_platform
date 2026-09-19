import 'dart:convert';
import 'dart:io';

import 'package:exam_platform/features/lab/lab_automated_lifecycle.dart';
import 'package:exam_platform/features/lab/lab_contracts.dart';
import 'package:exam_platform/features/lab/lab_dqg300.dart';
import 'package:exam_platform/features/lab/lab_studio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../quality_validator_contract/dqg300/_support/dqg300_fixture.dart';

String _draftSource() =>
    File('test/fixtures/lab/l2_valid_lab.json').readAsStringSync();

String _publishedSource() {
  final decoded = jsonDecode(_draftSource()) as Map;
  final root = decoded.cast<String, Object?>();
  final lab = (root['lab'] as Map).cast<String, Object?>();
  lab['lifecycle'] = 'PUBLISHED';
  return jsonEncode(root);
}

LabPublishedVersion _manualVersion({
  String? labId,
  String? versionId,
  String? publishedJson,
  String reviewerId = 'manual-reviewer',
  String? validationAuthority,
  String? qualityEvidenceJson,
  String? exhaustiveRouteEvidenceJson,
  String? publishEvidenceJson,
}) {
  return LabPublishedVersion(
    labId: labId ?? 'l2_lab',
    versionId: versionId ?? 'v1',
    publishedJson: publishedJson ?? _publishedSource(),
    publishedAt: DateTime.utc(2026, 9, 19, 9),
    reviewerId: reviewerId,
    validationAuthority: validationAuthority,
    qualityEvidenceJson: qualityEvidenceJson,
    exhaustiveRouteEvidenceJson: exhaustiveRouteEvidenceJson,
    publishEvidenceJson: publishEvidenceJson,
  );
}

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

Future<LabPublishedVersion> _automatedVersion() async {
  final repository = InMemoryLabPublishedRepository();
  final studio = Lab1000StudioService(repository: repository);
  final draft = studio.importJson(_draftSource());

  await LabAutomatedLifecycleService(studio: studio).validateAndPublish(
    workspace: draft,
    dqg300Evidence: _passingEvidence(draft.package),
    validatedAt: DateTime.utc(2026, 9, 19, 9),
    publishedAt: DateTime.utc(2026, 9, 19, 9, 1),
  );

  return (await repository.load('l2_lab', 'v1'))!;
}

void main() {
  test('L4O accepts a valid immutable manual published snapshot', () async {
    final repository = InMemoryLabPublishedRepository();
    final version = _manualVersion();

    await repository.saveImmutable(version);

    final stored = await repository.load('l2_lab', 'v1');
    expect(stored, same(version));
    expect(LabPackage.decode(stored!.publishedJson).metadata.lifecycle,
        LabLifecycleStatus.published);
  });

  test('L4O rejects a snapshot whose JSON is not PUBLISHED', () async {
    final repository = InMemoryLabPublishedRepository();

    await expectLater(
      repository.saveImmutable(_manualVersion(publishedJson: _draftSource())),
      throwsA(isA<LabStudioException>()),
    );
    expect(await repository.load('l2_lab', 'v1'), isNull);
  });

  test('L4O rejects repository identity that disagrees with published JSON',
      () async {
    final repository = InMemoryLabPublishedRepository();

    await expectLater(
      repository.saveImmutable(_manualVersion(versionId: 'v2')),
      throwsA(isA<LabStudioException>()),
    );
    expect(await repository.load('l2_lab', 'v2'), isNull);
  });

  test('L4O rejects a blank published reviewer', () async {
    final repository = InMemoryLabPublishedRepository();

    await expectLater(
      repository.saveImmutable(_manualVersion(reviewerId: '   ')),
      throwsA(isA<LabStudioException>()),
    );
  });

  test('L4O rejects automated publication with an incomplete certificate set',
      () async {
    final repository = InMemoryLabPublishedRepository();

    await expectLater(
      repository.saveImmutable(
        _manualVersion(
          reviewerId: 'DQG300-LAB-AUTO',
          validationAuthority: 'DQG300-LAB-AUTO',
        ),
      ),
      throwsA(isA<LabStudioException>()),
    );
  });

  test('L4O accepts the complete automated certificate chain', () async {
    final source = await _automatedVersion();
    final repository = InMemoryLabPublishedRepository();

    await repository.saveImmutable(source);

    final stored = await repository.load(source.labId, source.versionId);
    expect(stored, isNotNull);
    expect(stored!.qualityEvidenceJson, isNotNull);
    expect(stored.exhaustiveRouteEvidenceJson, isNotNull);
    expect(stored.publishEvidenceJson, isNotNull);
  });

  test('L4O rejects certificates after Decision Node content is changed',
      () async {
    final source = await _automatedVersion();
    final decoded = jsonDecode(source.publishedJson) as Map;
    final root = decoded.cast<String, Object?>();
    final nodes = root['nodes'] as List;
    final firstNode = (nodes.first as Map).cast<String, Object?>();
    final options = firstNode['options'] as List;
    final firstOption = (options.first as Map).cast<String, Object?>();
    firstOption['text'] = 'Runtime-significant text changed after validation.';

    final tampered = LabPublishedVersion(
      labId: source.labId,
      versionId: source.versionId,
      publishedJson: jsonEncode(root),
      publishedAt: source.publishedAt,
      reviewerId: source.reviewerId,
      validationAuthority: source.validationAuthority,
      qualityEvidenceJson: source.qualityEvidenceJson,
      exhaustiveRouteEvidenceJson: source.exhaustiveRouteEvidenceJson,
      publishEvidenceJson: source.publishEvidenceJson,
    );

    final repository = InMemoryLabPublishedRepository();
    await expectLater(
      repository.saveImmutable(tampered),
      throwsA(isA<LabStudioException>()),
    );
    expect(await repository.load(source.labId, source.versionId), isNull);
  });

  test('L4O refuses revision creation from imported PUBLISHED-looking JSON', () {
    final service = Lab1000StudioService(
      repository: InMemoryLabPublishedRepository(),
    );
    final imported = service.importJson(_publishedSource());

    expect(imported.lifecycle, LabLifecycleStatus.published);
    expect(imported.publishedVersion, isNull);
    expect(
      () => service.createRevision(imported, newVersionId: 'v2'),
      throwsA(isA<LabStudioException>()),
    );
  });


  test('L4O rejects revision creation after nested published root mutation',
      () async {
    final repository = InMemoryLabPublishedRepository();
    final service = Lab1000StudioService(repository: repository);
    final draft = service.importJson(_draftSource());
    final review = service.requestReview(draft);
    final validated =
        service.approveReview(review, reviewerId: 'manual-reviewer');
    final published = await service.publish(validated);
    final lab = (published.root['lab'] as Map).cast<String, Object?>();
    lab['title'] = 'Mutated after immutable publication';

    expect(
      () => service.createRevision(published, newVersionId: 'v2'),
      throwsA(isA<LabStudioException>()),
    );

    final stored = await repository.load('l2_lab', 'v1');
    expect(
      LabPackage.decode(stored!.publishedJson).metadata.title,
      'L2 deterministic validation LAB',
    );
  });

  test('L4O legitimate revision preserves the immutable original snapshot',
      () async {
    final repository = InMemoryLabPublishedRepository();
    final service = Lab1000StudioService(repository: repository);
    final draft = service.importJson(_draftSource());
    final review = service.requestReview(draft);
    final validated =
        service.approveReview(review, reviewerId: 'manual-reviewer');
    final published = await service.publish(
      validated,
      publishedAt: DateTime.utc(2026, 9, 19, 9),
    );
    final original = (await repository.load('l2_lab', 'v1'))!;

    final revision = service.createRevision(published, newVersionId: 'v2');
    final mutable = jsonDecode(revision.sourceJson) as Map;
    final root = mutable.cast<String, Object?>();
    final lab = (root['lab'] as Map).cast<String, Object?>();
    lab['title'] = 'Revision-only title';
    final editedRevision = service.editRoot(revision, root);
    final reloaded = (await repository.load('l2_lab', 'v1'))!;

    expect(revision.lifecycle, LabLifecycleStatus.draft);
    expect(revision.package.metadata.versionId, 'v2');
    expect(revision.reviewerId, isNull);
    expect(revision.publishedVersion, isNull);
    expect(editedRevision.package.metadata.title, 'Revision-only title');
    expect(reloaded.publishedJson, original.publishedJson);
    expect(reloaded.versionId, 'v1');
  });

  test('L4O duplicate version writes remain impossible', () async {
    final repository = InMemoryLabPublishedRepository();
    final version = _manualVersion();
    await repository.saveImmutable(version);

    await expectLater(
      repository.saveImmutable(
        _manualVersion(publishedJson: '{"invalid":"replacement"}'),
      ),
      throwsA(isA<LabStudioException>()),
    );

    final stored = await repository.load('l2_lab', 'v1');
    expect(stored!.publishedJson, version.publishedJson);
  });
}
