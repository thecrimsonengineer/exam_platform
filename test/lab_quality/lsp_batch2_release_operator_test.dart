import 'dart:convert';
import 'dart:io';

import 'package:exam_platform/features/lab/lab_batch2_release.dart';
import 'package:exam_platform/features/lab/lab_batch2_release_operator.dart';
import 'package:exam_platform/features/lab/lab_dqg300_evidence_store.dart';
import 'package:exam_platform/features/lab/lab_firestore_repositories.dart';
import 'package:exam_platform/features/lab/lab_learner_presentation.dart';
import 'package:exam_platform/features/lab/lab_production_population_seed.dart';
import 'package:exam_platform/features/lab/lab_production_release_closure.dart';
import 'package:exam_platform/features/lab/lab_scenario_population_manifest.dart';
import 'package:exam_platform/features/lab/lab_snapshot_fingerprint.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, Object?> _readObject(String path) {
  final decoded = jsonDecode(File(path).readAsStringSync());
  if (decoded is! Map) {
    throw StateError('Expected JSON object at ' + path + '.');
  }
  return decoded.cast<String, Object?>();
}

class _FileBatch2Source implements LabBatch2PopulationSource {
  const _FileBatch2Source();

  @override
  Future<LabScenarioPopulationManifest> loadManifest() async {
    return LabScenarioPopulationManifest.fromJson(
      _readObject('content/lab_population_batch2/manifest.json'),
    );
  }

  @override
  Future<List<LabProductionPopulationSeedCandidate>> loadCandidates(
    LabScenarioPopulationManifest manifest,
  ) async {
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
}

LabBatch2ReleaseOperatorService _operator(FakeFirebaseFirestore firestore) {
  return LabBatch2ReleaseOperatorService(
    populationSource: const _FileBatch2Source(),
    publishedRepository: FirestoreLabPublishedRepository(firestore: firestore),
    catalogueRepository: FirestoreLabLearnerCatalogueRepository(
      firestore: firestore,
    ),
    evidenceRepository: FirestoreLabProductionReleaseEvidenceRepository(
      firestore: firestore,
    ),
    atomicRepository: FirestoreLabBatch2AtomicReleaseRepository(
      firestore: firestore,
    ),
    environmentId: 'firebase_project:csp11-exam-platform',
  );
}

Future<void> _seedInitialRelease(FakeFirebaseFirestore firestore) async {
  final manifest = LabScenarioPopulationManifest.fromJson(
    _readObject('content/lab_population/manifest.json'),
  );
  final fingerprint =
      LabSnapshotFingerprint.schema + ':' + List.filled(64, 'a').join();
  final entries = manifest.entries.map(
    (entry) => LabProductionReleaseEntryEvidence(
      entryId: entry.entryId,
      labId: entry.labId,
      versionId: entry.versionId,
      snapshotFingerprint: fingerprint,
      publishedAtIso: DateTime.utc(2026, 9, 23, 12).toIso8601String(),
      decisionCount: 5,
    ),
  );
  final evidence = LabProductionReleaseEvidence.issue(
    releaseId: LabProductionReleaseClosureService.releaseIdFor(manifest),
    manifestId: manifest.manifestId,
    manifestFingerprint:
        LabProductionReleaseClosureService.manifestFingerprintFor(manifest),
    environmentId: 'firebase_project:csp11-exam-platform',
    executedBy: 'initial_release_test_admin',
    executedAt: DateTime.utc(2026, 9, 23, 13),
    catalogueIdentityKeys: manifest.entries.map((entry) => entry.identityKey),
    entries: entries,
  );
  await FirestoreLabProductionReleaseEvidenceRepository(
    firestore: firestore,
  ).saveImmutable(evidence);
}

void main() {
  test('Batch 2 operator blocks until original production release is closed', () async {
    final firestore = FakeFirebaseFirestore();
    final inspection = await _operator(firestore).inspect();

    expect(inspection.state, LabBatch2OperatorState.blockedOriginalRelease);
    expect(inspection.originalReleaseClosed, isFalse);
    expect(inspection.canPublish, isFalse);
    expect(inspection.publishedCount, 0);
    expect(inspection.catalogueCount, 0);
  });

  test('Batch 2 operator is READY after original release and before Batch 2', () async {
    final firestore = FakeFirebaseFirestore();
    await _seedInitialRelease(firestore);

    final inspection = await _operator(firestore).inspect();

    expect(inspection.state, LabBatch2OperatorState.ready);
    expect(inspection.originalReleaseClosed, isTrue);
    expect(inspection.canPublish, isTrue);
    expect(inspection.expectedLabCount, 10);
    expect(inspection.publishedCount, 0);
    expect(inspection.catalogueCount, 0);
  });

  test('Batch 2 operator rejects an incorrect publication phrase', () async {
    final firestore = FakeFirebaseFirestore();
    await _seedInitialRelease(firestore);

    await expectLater(
      _operator(firestore).publish(
        executedBy: 'batch2_test_admin',
        confirmationPhrase: 'RELEASE 10 LABS',
      ),
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

  test('Batch 2 operator atomically publishes and closes all ten LABs', () async {
    final firestore = FakeFirebaseFirestore();
    await _seedInitialRelease(firestore);
    final operator = _operator(firestore);

    final evidence = await operator.publish(
      executedBy: 'batch2_test_admin',
      confirmationPhrase: kBatch2ReleaseConfirmationPhrase,
      executedAt: DateTime.utc(2026, 9, 24, 17),
    );
    final inspection = await operator.inspect();

    expect(evidence.manifestId, kBatch2LabProductionManifestId);
    expect(evidence.labCount, 10);
    expect(evidence.totalDecisionCount, 50);
    expect(inspection.state, LabBatch2OperatorState.closed);
    expect(inspection.isClosed, isTrue);
    expect(inspection.publishedCount, 10);
    expect(inspection.catalogueCount, 10);
    expect(
      inspection.evidence?.evidenceFingerprint,
      evidence.evidenceFingerprint,
    );
  });

  test('Batch 2 operator refuses a second publication attempt', () async {
    final firestore = FakeFirebaseFirestore();
    await _seedInitialRelease(firestore);
    final operator = _operator(firestore);

    await operator.publish(
      executedBy: 'batch2_test_admin',
      confirmationPhrase: kBatch2ReleaseConfirmationPhrase,
      executedAt: DateTime.utc(2026, 9, 24, 17),
    );

    await expectLater(
      operator.publish(
        executedBy: 'batch2_test_admin',
        confirmationPhrase: kBatch2ReleaseConfirmationPhrase,
        executedAt: DateTime.utc(2026, 9, 24, 17, 5),
      ),
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
}
