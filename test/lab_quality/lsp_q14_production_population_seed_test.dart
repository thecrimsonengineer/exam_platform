import 'dart:convert';
import 'dart:io';

import 'package:exam_platform/features/lab/lab_dqg300_evidence_store.dart';
import 'package:exam_platform/features/lab/lab_learner_catalogue.dart';
import 'package:exam_platform/features/lab/lab_learner_presentation.dart';
import 'package:exam_platform/features/lab/lab_production_population_seed.dart';
import 'package:exam_platform/features/lab/lab_scenario_population_manifest.dart';
import 'package:exam_platform/features/lab/lab_studio.dart';
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

void main() {
  test(
    'Q14 preflights, seeds all ten LABs and verifies exact learner release',
    () async {
      final manifest = _manifest();
      final published = InMemoryLabPublishedRepository();
      final catalogue = InMemoryLabLearnerCatalogueRepository();
      final service = LabProductionPopulationSeedService(
        publishedRepository: published,
        catalogueRepository: catalogue,
      );

      final receipt = await service.seedAndVerify(
        manifest: manifest,
        candidates: _candidates(manifest),
        validatedAt: DateTime.utc(2026, 9, 24, 1),
        publishedAt: DateTime.utc(2026, 9, 24, 1, 10),
      );

      expect(receipt.manifestId, 'phase_l_population_v1');
      expect(receipt.entries, hasLength(10));
      expect(receipt.entries.map((entry) => entry.identityKey).toSet(),
          manifest.entries.map((entry) => entry.identityKey).toSet());
      expect(receipt.entries.every((entry) => entry.snapshotFingerprint.isNotEmpty),
          isTrue);
      expect(receipt.verification.catalogueIdentityKeys, hasLength(10));
      expect(receipt.verification.totalDecisionCount, 50);
      expect(await catalogue.listAvailable(), hasLength(10));

      for (final entry in manifest.entries) {
        expect(await published.load(entry.labId, entry.versionId), isNotNull);
        expect(await catalogue.load(entry.labId, entry.versionId), isNotNull);
      }
    },
  );

  test(
    'Q14 invalid later candidate fails preflight before any production write',
    () async {
      final manifest = _manifest();
      final candidates = _candidates(manifest);
      final entry = manifest.entries.last;
      final presentationRoot = _readObject(entry.learnerPresentationPath);
      presentationRoot['versionId'] = 'v2';

      candidates[candidates.length - 1] = LabProductionPopulationSeedCandidate(
        entryId: entry.entryId,
        technicalRoot: _readObject(entry.technicalLabPath),
        dqg300Evidence: const LabDqg300EvidenceCodec().decode(
          File(entry.dqg300EvidencePath).readAsStringSync(),
        ),
        presentationPackage: LabLearnerPresentationPackage.fromJson(
          presentationRoot,
        ),
      );

      final published = InMemoryLabPublishedRepository();
      final catalogue = InMemoryLabLearnerCatalogueRepository();
      final service = LabProductionPopulationSeedService(
        publishedRepository: published,
        catalogueRepository: catalogue,
      );

      await expectLater(
        service.seedAndVerify(
          manifest: manifest,
          candidates: candidates,
          validatedAt: DateTime.utc(2026, 9, 24, 2),
          publishedAt: DateTime.utc(2026, 9, 24, 2, 10),
        ),
        throwsA(anyOf(
          isA<LabStudioException>(),
          isA<LabProductionPopulationSeedException>(),
        )),
      );

      expect(await catalogue.listAvailable(), isEmpty);
      for (final manifestEntry in manifest.entries) {
        expect(
          await published.load(manifestEntry.labId, manifestEntry.versionId),
          isNull,
        );
        expect(
          await catalogue.load(manifestEntry.labId, manifestEntry.versionId),
          isNull,
        );
      }
    },
  );

  test('Q14 initial seed is one-shot and never overwrites released versions',
      () async {
    final manifest = _manifest();
    final published = InMemoryLabPublishedRepository();
    final catalogue = InMemoryLabLearnerCatalogueRepository();
    final service = LabProductionPopulationSeedService(
      publishedRepository: published,
      catalogueRepository: catalogue,
    );
    final candidates = _candidates(manifest);

    final first = await service.seedAndVerify(
      manifest: manifest,
      candidates: candidates,
      validatedAt: DateTime.utc(2026, 9, 24, 3),
      publishedAt: DateTime.utc(2026, 9, 24, 3, 10),
    );
    final original = await published.load(
      manifest.entries.first.labId,
      manifest.entries.first.versionId,
    );

    await expectLater(
      service.seedAndVerify(
        manifest: manifest,
        candidates: candidates,
        validatedAt: DateTime.utc(2026, 9, 24, 4),
        publishedAt: DateTime.utc(2026, 9, 24, 4, 10),
      ),
      throwsA(isA<LabProductionPopulationSeedException>()),
    );

    final stored = await published.load(
      manifest.entries.first.labId,
      manifest.entries.first.versionId,
    );
    expect(first.entries, hasLength(10));
    expect(await catalogue.listAvailable(), hasLength(10));
    expect(stored!.publishedJson, original!.publishedJson);
    expect(stored.snapshotFingerprint, original.snapshotFingerprint);

    final verification = await service.verifyRelease(manifest: manifest);
    expect(verification.catalogueIdentityKeys, hasLength(10));
    expect(verification.totalDecisionCount, 50);
  });
}
