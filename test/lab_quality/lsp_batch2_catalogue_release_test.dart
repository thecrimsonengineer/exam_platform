import 'dart:convert';
import 'dart:io';

import 'package:exam_platform/features/lab/lab_batch2_release.dart';
import 'package:exam_platform/features/lab/lab_dqg300_evidence_store.dart';
import 'package:exam_platform/features/lab/lab_firestore_repositories.dart';
import 'package:exam_platform/features/lab/lab_learner_presentation.dart';
import 'package:exam_platform/features/lab/lab_production_population_seed.dart';
import 'package:exam_platform/features/lab/lab_production_release_closure.dart';
import 'package:exam_platform/features/lab/lab_scenario_population_manifest.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, Object?> _readObject(String path) {
  final decoded = jsonDecode(File(path).readAsStringSync());
  if (decoded is! Map) {
    throw StateError('Expected JSON object at ' + path + '.');
  }
  return decoded.cast<String, Object?>();
}

LabScenarioPopulationManifest _manifest() =>
    LabScenarioPopulationManifest.fromJson(
      _readObject('content/lab_population_batch2/manifest.json'),
    );

List<LabProductionPopulationSeedCandidate> _candidates(
  LabScenarioPopulationManifest manifest,
) {
  return manifest.entries.map((entry) {
    return LabProductionPopulationSeedCandidate(
      entryId: entry.entryId,
      technicalRoot: _readObject(entry.technicalLabPath),
      dqg300Evidence: const LabDqg300EvidenceCodec().decode(
        File(entry.dqg300EvidencePath).readAsStringSync(),
      ),
      presentationPackage: LabLearnerPresentationPackage.fromJson(
        _readObject(entry.learnerPresentationPath),
      ),
    );
  }).toList(growable: false);
}

Future<LabBatch2ReleaseBundle>? _cachedBundle;

Future<LabBatch2ReleaseBundle> _bundle() =>
    _cachedBundle ??= _buildBundle();

Future<LabBatch2ReleaseBundle> _buildBundle() {
  final manifest = _manifest();
  return const LabBatch2ReleaseService().prepare(
    manifest: manifest,
    candidates: _candidates(manifest),
    environmentId: 'firebase_project:csp11-exam-platform',
    executedBy: 'batch2_test_admin',
    validatedAt: DateTime.utc(2026, 9, 24, 16),
    publishedAt: DateTime.utc(2026, 9, 24, 16, 10),
    executedAt: DateTime.utc(2026, 9, 24, 16, 20),
  );
}

Future<void> _seedInitialReleaseMarker(FakeFirebaseFirestore firestore) async {
  await firestore
      .collection('labProductionReleaseEvidence')
      .doc(kInitialLabProductionReleaseId)
      .set(<String, Object?>{
        'schemaVersion': LabProductionReleaseEvidence.schemaVersion,
        'releaseId': kInitialLabProductionReleaseId,
        'manifestId': 'phase_l_population_v1',
        'evidenceFingerprint': 'legacy_release_marker',
      });
  await firestore
      .collection('labLearnerReleaseState')
      .doc(kInitialLabProductionReleaseId)
      .set(<String, Object?>{
        'schemaVersion': kLabLearnerReleaseStateFirestoreSchemaVersion,
        'releaseId': kInitialLabProductionReleaseId,
        'manifestId': 'phase_l_population_v1',
        'released': true,
        'labCount': 10,
        'totalDecisionCount': 50,
        'evidenceFingerprint': 'legacy_release_marker',
      });
}

void main() {
  test('Batch 2 prepares exactly ten catalogue-ready immutable LABs', () async {
    final bundle = await _bundle();

    expect(bundle.manifest.manifestId, kBatch2LabProductionManifestId);
    expect(bundle.publishedVersions, hasLength(10));
    expect(bundle.catalogueEntries, hasLength(10));
    expect(bundle.evidence.labCount, 10);
    expect(bundle.evidence.totalDecisionCount, 50);
    expect(bundle.evidence.q14ClosureSha, kLspBatch2PrecatalogueClosedSha);
    expect(
      bundle.evidence.q14ValidationRunId,
      kLspBatch2PrecatalogueValidationRunId,
    );
    expect(
      bundle.publishedVersions
          .every((item) => item.validationAuthority == kBatch2ValidationAuthority),
      isTrue,
    );
    expect(
      bundle.catalogueEntries.map((item) => item.identityKey).toSet(),
      hasLength(10),
    );
  });

  test('Batch 2 refuses atomic release before original release exists', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = FirestoreLabBatch2AtomicReleaseRepository(
      firestore: firestore,
    );

    await expectLater(
      repository.commit(await _bundle()),
      throwsA(isA<LabBatch2ReleaseException>()),
    );

    expect(
      (await firestore.collection('labPublishedVersions').get()).docs,
      isEmpty,
    );
    expect(
      (await firestore.collection('labLearnerCatalogue').get()).docs,
      isEmpty,
    );
  });

  test('Batch 2 commits all ten catalogue identities and release marker', () async {
    final firestore = FakeFirebaseFirestore();
    await _seedInitialReleaseMarker(firestore);
    final bundle = await _bundle();
    final repository = FirestoreLabBatch2AtomicReleaseRepository(
      firestore: firestore,
    );

    await repository.commit(bundle);
    await repository.verify(bundle);

    final published =
        (await firestore.collection('labPublishedVersions').get()).docs;
    final catalogue =
        (await firestore.collection('labLearnerCatalogue').get()).docs;
    final releaseEvidence = await firestore
        .collection('labProductionReleaseEvidence')
        .doc(bundle.evidence.releaseId)
        .get();
    final releaseState = await firestore
        .collection('labLearnerReleaseState')
        .doc(bundle.evidence.releaseId)
        .get();

    expect(published, hasLength(10));
    expect(catalogue, hasLength(10));
    expect(
      published.every(
        (doc) => doc.data()['releaseId'] == bundle.evidence.releaseId,
      ),
      isTrue,
    );
    expect(
      catalogue.every(
        (doc) => doc.data()['releaseId'] == bundle.evidence.releaseId,
      ),
      isTrue,
    );
    expect(releaseEvidence.exists, isTrue);
    expect(releaseState.data()?['released'], isTrue);
    expect(releaseState.data()?['labCount'], 10);
    expect(releaseState.data()?['totalDecisionCount'], 50);
  });

  test('Batch 2 production release is immutable on retry', () async {
    final firestore = FakeFirebaseFirestore();
    await _seedInitialReleaseMarker(firestore);
    final bundle = await _bundle();
    final repository = FirestoreLabBatch2AtomicReleaseRepository(
      firestore: firestore,
    );

    await repository.commit(bundle);

    await expectLater(
      repository.commit(bundle),
      throwsA(isA<LabBatch2ReleaseException>()),
    );

    expect(
      (await firestore.collection('labPublishedVersions').get()).docs,
      hasLength(10),
    );
    expect(
      (await firestore.collection('labLearnerCatalogue').get()).docs,
      hasLength(10),
    );
  });

  test('Batch 2 Firestore rules gate new LABs on their release marker', () {
    final rules = File('firestore.rules').readAsStringSync();

    expect(
      rules,
      contains("'phase_l_population_batch2_v1_q15_release_v1'"),
    );
    expect(
      rules,
      contains("'4aa151a749b2324e9edd69a40781d7f8169a72c0'"),
    );
    expect(rules, contains("'36015831093'"));
    expect(rules, contains('labResourceReleased(resource.data)'));
    expect(rules, contains("!('releaseId' in request.resource.data)"));
    expect(rules, contains('existsAfter('));
    expect(rules, contains('getAfter('));
  });
}
