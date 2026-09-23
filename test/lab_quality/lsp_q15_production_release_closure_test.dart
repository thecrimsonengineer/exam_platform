import 'dart:convert';
import 'dart:io';

import 'package:exam_platform/features/lab/lab_dqg300_evidence_store.dart';
import 'package:exam_platform/features/lab/lab_firestore_repositories.dart';
import 'package:exam_platform/features/lab/lab_learner_catalogue.dart';
import 'package:exam_platform/features/lab/lab_learner_presentation.dart';
import 'package:exam_platform/features/lab/lab_production_population_seed.dart';
import 'package:exam_platform/features/lab/lab_production_release_closure.dart';
import 'package:exam_platform/features/lab/lab_scenario_population_manifest.dart';
import 'package:exam_platform/features/lab/lab_snapshot_fingerprint.dart';
import 'package:exam_platform/features/lab/lab_studio.dart';
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
      _readObject('content/lab_population/manifest.json'),
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
  }).toList();
}

LabProductionReleaseEvidence _syntheticEvidence() {
  return LabProductionReleaseEvidence.issue(
    releaseId: 'synthetic_q15_release_v1',
    manifestId: 'phase_l_population_v1',
    manifestFingerprint:
        kLabProductionManifestFingerprintSchema + ':' +
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
    environmentId: 'production_test',
    executedBy: 'q15_test_admin',
    executedAt: DateTime.utc(2026, 9, 24, 6),
    catalogueIdentityKeys: const <String>['synthetic_lab@v1'],
    entries: <LabProductionReleaseEntryEvidence>[
      LabProductionReleaseEntryEvidence(
        entryId: 'synthetic_lab_v1',
        labId: 'synthetic_lab',
        versionId: 'v1',
        snapshotFingerprint:
            LabSnapshotFingerprint.schema + ':' +
            'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
        publishedAtIso: DateTime.utc(2026, 9, 24, 5).toIso8601String(),
        decisionCount: 5,
      ),
    ],
  );
}

void main() {
  test(
    'Q15 executes Q14 seed then closes the exact ten-LAB learner release',
    () async {
      final manifest = _manifest();
      final published = InMemoryLabPublishedRepository();
      final catalogue = InMemoryLabLearnerCatalogueRepository();
      final evidenceRepository =
          InMemoryLabProductionReleaseEvidenceRepository();
      final seedService = LabProductionPopulationSeedService(
        publishedRepository: published,
        catalogueRepository: catalogue,
      );
      final closureService = LabProductionReleaseClosureService(
        publishedRepository: published,
        catalogueRepository: catalogue,
        evidenceRepository: evidenceRepository,
      );
      final executor = LabProductionReleaseExecutionService(
        seedService: seedService,
        closureService: closureService,
      );

      final evidence = await executor.executeInitialRelease(
        manifest: manifest,
        candidates: _candidates(manifest),
        environmentId: 'production_test',
        executedBy: 'q15_test_admin',
        validatedAt: DateTime.utc(2026, 9, 24, 6),
        publishedAt: DateTime.utc(2026, 9, 24, 6, 10),
        executedAt: DateTime.utc(2026, 9, 24, 6, 20),
      );

      expect(evidence.releaseId, 'phase_l_population_v1_q15_release_v1');
      expect(evidence.manifestId, 'phase_l_population_v1');
      expect(evidence.q14ClosureSha, kLspQ14ClosedSha);
      expect(evidence.q14ValidationRunId, kLspQ14ClosureValidationRunId);
      expect(
        evidence.manifestFingerprint,
        LabProductionReleaseClosureService.manifestFingerprintFor(manifest),
      );
      expect(evidence.labCount, 10);
      expect(evidence.totalDecisionCount, 50);
      expect(evidence.entries, hasLength(10));
      expect(evidence.catalogueIdentityKeys, hasLength(10));
      expect(
        evidence.entries.every(
          (entry) => entry.snapshotFingerprint.startsWith(
            LabSnapshotFingerprint.schema + ':',
          ),
        ),
        isTrue,
      );
      expect(
        evidence.evidenceFingerprint,
        startsWith(kLabProductionReleaseFingerprintSchema + ':'),
      );

      final verified = await closureService.verifyClosedRelease(
        manifest: manifest,
      );
      expect(verified.evidenceFingerprint, evidence.evidenceFingerprint);

      await expectLater(
        closureService.closeRelease(
          manifest: manifest,
          environmentId: 'production_test',
          executedBy: 'q15_test_admin',
          executedAt: DateTime.utc(2026, 9, 24, 7),
        ),
        throwsA(isA<LabProductionReleaseClosureException>()),
      );
    },
  );

  test('Q15 refuses closure when Q14 learner release does not exist', () async {
    final manifest = _manifest();
    final service = LabProductionReleaseClosureService(
      publishedRepository: InMemoryLabPublishedRepository(),
      catalogueRepository: InMemoryLabLearnerCatalogueRepository(),
      evidenceRepository: InMemoryLabProductionReleaseEvidenceRepository(),
    );

    await expectLater(
      service.closeRelease(
        manifest: manifest,
        environmentId: 'production_test',
        executedBy: 'q15_test_admin',
        executedAt: DateTime.utc(2026, 9, 24, 8),
      ),
      throwsA(isA<LabProductionPopulationSeedException>()),
    );
  });

  test('Q15 evidence fingerprint rejects tampering', () {
    final root = _syntheticEvidence().toJson();
    root['environmentId'] = 'tampered_environment';

    expect(
      () => LabProductionReleaseEvidence.fromJson(root),
      throwsA(isA<LabProductionReleaseClosureException>()),
    );
  });

  test('Q15 Firestore evidence repository is create-once and round-trips',
      () async {
    final firestore = FakeFirebaseFirestore();
    final repository = FirestoreLabProductionReleaseEvidenceRepository(
      firestore: firestore,
    );
    final evidence = _syntheticEvidence();

    await repository.saveImmutable(evidence);
    final loaded = await repository.load(evidence.releaseId);

    expect(loaded, isNotNull);
    expect(loaded!.evidenceFingerprint, evidence.evidenceFingerprint);
    expect(loaded.q14ClosureSha, kLspQ14ClosedSha);

    await expectLater(
      repository.saveImmutable(evidence),
      throwsA(isA<LabProductionReleaseClosureException>()),
    );
  });

  test('Q15 Firestore rules keep release evidence admin-only and immutable', () {
    final rules = File('firestore.rules').readAsStringSync();

    expect(
      rules,
      contains('match /labProductionReleaseEvidence/{releaseId}'),
    );
    expect(rules, contains('allow get, list: if isAdmin();'));
    expect(
      rules,
      contains(
        'allow create: if isAdmin() && validLabProductionRelease(releaseId);',
      ),
    );
    expect(rules, contains('allow update, delete: if false;'));
    expect(rules, contains(kLspQ14ClosedSha));
    expect(rules, contains(kLspQ14ClosureValidationRunId));
    expect(rules, contains("request.resource.data.labCount == 10"));
    expect(rules, contains("request.resource.data.totalDecisionCount == 50"));
  });
}
