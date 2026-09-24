import 'dart:convert';
import 'dart:io';

import 'package:exam_platform/features/lab/lab_contracts.dart';
import 'package:exam_platform/features/lab/lab_dqg300_evidence_store.dart';
import 'package:exam_platform/features/lab/lab_learner_catalogue.dart';
import 'package:exam_platform/features/lab/lab_learner_presentation.dart';
import 'package:exam_platform/features/lab/lab_scenario_population_manifest.dart';
import 'package:exam_platform/features/lab/lab_scenario_population_publication.dart';
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

Future<void> _publishEntry({
  required LabScenarioPopulationManifest manifest,
  required LabScenarioPopulationManifestEntry entry,
  required LabPublishedRepository publishedRepository,
}) async {
  final gate = LabScenarioPopulationPublicationGate(
    studio: Lab1000StudioService(repository: publishedRepository),
  );
  await gate.admit(
    manifest: manifest,
    entryId: entry.entryId,
    technicalRoot: _readObject(entry.technicalLabPath),
    dqg300Evidence: const LabDqg300EvidenceCodec().decode(
      File(entry.dqg300EvidencePath).readAsStringSync(),
    ),
    presentationPackage: LabLearnerPresentationPackage.fromJson(
      _readObject(entry.learnerPresentationPath),
    ),
    validatedAt: DateTime.utc(2026, 9, 24, 0),
    publishedAt: DateTime.utc(2026, 9, 24, 0, 1),
  );
}

void main() {
  test('Q12 admits a Q11-published LAB to the learner catalogue', () async {
    final manifest = _manifest();
    final entry = manifest.entries.first;
    final publishedRepository = InMemoryLabPublishedRepository();
    final catalogueRepository = InMemoryLabLearnerCatalogueRepository();

    await _publishEntry(
      manifest: manifest,
      entry: entry,
      publishedRepository: publishedRepository,
    );

    final admitted =
        await LabLearnerCatalogueAdmissionService(
          publishedRepository: publishedRepository,
          catalogueRepository: catalogueRepository,
        ).admit(
          manifest: manifest,
          entryId: entry.entryId,
          presentation: LabLearnerPresentationPackage.fromJson(
            _readObject(entry.learnerPresentationPath),
          ),
        );

    expect(admitted.manifestEntryId, entry.entryId);
    expect(admitted.labId, entry.labId);
    expect(admitted.versionId, entry.versionId);
    expect(admitted.title, isNotEmpty);
    expect(admitted.summary, isNotEmpty);
    expect(admitted.focusTags, isNotEmpty);
    expect(admitted.estimatedTime, isNotEmpty);
    expect(admitted.decisionCountLabel, isNotEmpty);
    expect(admitted.decisionCount, 5);
    expect(admitted.supportedModes, containsAll(LabMode.values));
    expect((await catalogueRepository.listAvailable()), hasLength(1));
  });

  test(
    'Q12 controlled delivery loads exact immutable version and presentation',
    () async {
      final manifest = _manifest();
      final entry = manifest.entries.first;
      final publishedRepository = InMemoryLabPublishedRepository();
      final catalogueRepository = InMemoryLabLearnerCatalogueRepository();

      await _publishEntry(
        manifest: manifest,
        entry: entry,
        publishedRepository: publishedRepository,
      );
      await LabLearnerCatalogueAdmissionService(
        publishedRepository: publishedRepository,
        catalogueRepository: catalogueRepository,
      ).admit(
        manifest: manifest,
        entryId: entry.entryId,
        presentation: LabLearnerPresentationPackage.fromJson(
          _readObject(entry.learnerPresentationPath),
        ),
      );

      final delivery = await LabLearnerControlledDeliveryService(
        publishedRepository: publishedRepository,
        catalogueRepository: catalogueRepository,
      ).load(labId: entry.labId, versionId: entry.versionId);

      expect(delivery.package.metadata.lifecycle, LabLifecycleStatus.published);
      expect(delivery.package.metadata.id, entry.labId);
      expect(delivery.package.metadata.versionId, entry.versionId);
      expect(delivery.presentation.labId, entry.labId);
      expect(delivery.presentation.versionId, entry.versionId);
      expect(delivery.catalogueEntry.decisionCount, 5);
    },
  );

  test('Q12 refuses unpublished population entries', () async {
    final manifest = _manifest();
    final entry = manifest.entries.first;
    final publishedRepository = InMemoryLabPublishedRepository();
    final catalogueRepository = InMemoryLabLearnerCatalogueRepository();

    await expectLater(
      LabLearnerCatalogueAdmissionService(
        publishedRepository: publishedRepository,
        catalogueRepository: catalogueRepository,
      ).admit(
        manifest: manifest,
        entryId: entry.entryId,
        presentation: LabLearnerPresentationPackage.fromJson(
          _readObject(entry.learnerPresentationPath),
        ),
      ),
      throwsA(isA<LabLearnerCatalogueException>()),
    );

    expect(await catalogueRepository.listAvailable(), isEmpty);
  });

  test('Q12 refuses presentation drift before catalogue admission', () async {
    final manifest = _manifest();
    final entry = manifest.entries.first;
    final publishedRepository = InMemoryLabPublishedRepository();
    final catalogueRepository = InMemoryLabLearnerCatalogueRepository();

    await _publishEntry(
      manifest: manifest,
      entry: entry,
      publishedRepository: publishedRepository,
    );

    final presentationRoot = _readObject(entry.learnerPresentationPath);
    presentationRoot['versionId'] = 'v2';

    await expectLater(
      LabLearnerCatalogueAdmissionService(
        publishedRepository: publishedRepository,
        catalogueRepository: catalogueRepository,
      ).admit(
        manifest: manifest,
        entryId: entry.entryId,
        presentation: LabLearnerPresentationPackage.fromJson(presentationRoot),
      ),
      throwsA(isA<LabLearnerCatalogueException>()),
    );

    expect(await catalogueRepository.listAvailable(), isEmpty);
  });

  test(
    'Q12 learner catalogue entries cannot overwrite an admitted version',
    () async {
      final manifest = _manifest();
      final entry = manifest.entries.first;
      final publishedRepository = InMemoryLabPublishedRepository();
      final catalogueRepository = InMemoryLabLearnerCatalogueRepository();
      final presentation = LabLearnerPresentationPackage.fromJson(
        _readObject(entry.learnerPresentationPath),
      );

      await _publishEntry(
        manifest: manifest,
        entry: entry,
        publishedRepository: publishedRepository,
      );

      final admission = LabLearnerCatalogueAdmissionService(
        publishedRepository: publishedRepository,
        catalogueRepository: catalogueRepository,
      );
      await admission.admit(
        manifest: manifest,
        entryId: entry.entryId,
        presentation: presentation,
      );

      await expectLater(
        admission.admit(
          manifest: manifest,
          entryId: entry.entryId,
          presentation: presentation,
        ),
        throwsA(isA<LabLearnerCatalogueException>()),
      );

      expect(await catalogueRepository.listAvailable(), hasLength(1));
    },
  );

  test(
    'Q12 delivery is fail-closed for a version not in the catalogue',
    () async {
      final manifest = _manifest();
      final entry = manifest.entries.first;
      final publishedRepository = InMemoryLabPublishedRepository();
      final catalogueRepository = InMemoryLabLearnerCatalogueRepository();

      await _publishEntry(
        manifest: manifest,
        entry: entry,
        publishedRepository: publishedRepository,
      );

      await expectLater(
        LabLearnerControlledDeliveryService(
          publishedRepository: publishedRepository,
          catalogueRepository: catalogueRepository,
        ).load(labId: entry.labId, versionId: entry.versionId),
        throwsA(isA<LabLearnerCatalogueException>()),
      );
    },
  );

  test(
    'Q12 manifest contains ten candidates but catalogue admits explicitly',
    () async {
      final manifest = _manifest();
      final publishedRepository = InMemoryLabPublishedRepository();
      final catalogueRepository = InMemoryLabLearnerCatalogueRepository();

      expect(manifest.entries, hasLength(10));
      expect(await catalogueRepository.listAvailable(), isEmpty);

      final first = manifest.entries.first;
      await _publishEntry(
        manifest: manifest,
        entry: first,
        publishedRepository: publishedRepository,
      );
      await LabLearnerCatalogueAdmissionService(
        publishedRepository: publishedRepository,
        catalogueRepository: catalogueRepository,
      ).admit(
        manifest: manifest,
        entryId: first.entryId,
        presentation: LabLearnerPresentationPackage.fromJson(
          _readObject(first.learnerPresentationPath),
        ),
      );

      final available = await catalogueRepository.listAvailable();
      expect(available, hasLength(1));
      expect(available.single.identityKey, first.identityKey);
    },
  );
}
