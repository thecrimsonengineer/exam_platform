import 'dart:convert';
import 'dart:io';

import 'package:exam_platform/features/lab/lab_contracts.dart';
import 'package:exam_platform/features/lab/lab_dqg300_evidence_store.dart';
import 'package:exam_platform/features/lab/lab_learner_loader.dart';
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

void main() {
  test(
    'Q11 admits all ten Q10 entries through the immutable publication chain',
    () async {
      final manifest = _manifest();
      final repository = InMemoryLabPublishedRepository();
      final studio = Lab1000StudioService(repository: repository);
      final gate = LabScenarioPopulationPublicationGate(studio: studio);
      final loader = LabLearnerPackageLoader(repository: repository);

      var admittedCount = 0;
      var admittedDecisionCount = 0;

      for (var index = 0; index < manifest.entries.length; index++) {
        final entry = manifest.entries[index];
        final technicalRoot = _readObject(entry.technicalLabPath);
        final evidence = const LabDqg300EvidenceCodec().decode(
          File(entry.dqg300EvidencePath).readAsStringSync(),
        );
        final presentation = LabLearnerPresentationPackage.fromJson(
          _readObject(entry.learnerPresentationPath),
        );

        final result = await gate.admit(
          manifest: manifest,
          entryId: entry.entryId,
          technicalRoot: technicalRoot,
          dqg300Evidence: evidence,
          presentationPackage: presentation,
          validatedAt: DateTime.utc(2026, 9, 23, 16, index),
          publishedAt: DateTime.utc(2026, 9, 23, 17, index),
        );

        expect(
          result.isAdmitted,
          isTrue,
          reason: 'Q11 admission failed for ' + entry.identityKey + '.',
        );
        expect(result.manifestId, 'phase_l_population_v1');
        expect(result.bindingReport.isValid, isTrue);
        expect(result.decisionQualityReport.isValid, isTrue);
        expect(result.lifecycleResult.gateReport.isPublishable, isTrue);
        expect(result.publishedVersion.validationAuthority,
            'LSP-Q11-POPULATION-AUTO');
        expect(result.publishedVersion.qualityEvidenceJson, isNotNull);
        expect(result.publishedVersion.exhaustiveRouteEvidenceJson, isNotNull);
        expect(result.publishedVersion.publishEvidenceJson, isNotNull);
        expect(result.publishedVersion.snapshotFingerprint, isNotNull);

        final stored = await repository.load(entry.labId, entry.versionId);
        expect(stored, isNotNull);

        final publishedPackage = LabPackage.decode(stored!.publishedJson);
        expect(publishedPackage.metadata.lifecycle, LabLifecycleStatus.published);
        expect(publishedPackage.metadata.id, entry.labId);
        expect(publishedPackage.metadata.versionId, entry.versionId);

        final explicitlyLoaded = await loader.loadPublished(
          labId: entry.labId,
          versionId: entry.versionId,
        );
        expect(explicitlyLoaded.metadata.id, entry.labId);

        admittedCount++;
        admittedDecisionCount +=
            publishedPackage.nodes.whereType<LabDecisionNode>().length;
      }

      expect(admittedCount, 10);
      expect(admittedDecisionCount, 50);
    },
  );

  test('Q11 refuses an entry that is not in the population manifest', () async {
    final manifest = _manifest();
    final repository = InMemoryLabPublishedRepository();
    final gate = LabScenarioPopulationPublicationGate(
      studio: Lab1000StudioService(repository: repository),
    );
    final entry = manifest.entries.first;

    await expectLater(
      gate.admit(
        manifest: manifest,
        entryId: 'not_in_population',
        technicalRoot: _readObject(entry.technicalLabPath),
        dqg300Evidence: const LabDqg300EvidenceCodec().decode(
          File(entry.dqg300EvidencePath).readAsStringSync(),
        ),
        presentationPackage: LabLearnerPresentationPackage.fromJson(
          _readObject(entry.learnerPresentationPath),
        ),
      ),
      throwsA(isA<LabScenarioPopulationManifestException>()),
    );

    expect(await repository.load(entry.labId, entry.versionId), isNull);
  });

  test('Q11 blocks presentation identity drift before repository admission',
      () async {
    final manifest = _manifest();
    final entry = manifest.entries.first;
    final repository = InMemoryLabPublishedRepository();
    final gate = LabScenarioPopulationPublicationGate(
      studio: Lab1000StudioService(repository: repository),
    );
    final presentationRoot = _readObject(entry.learnerPresentationPath);
    presentationRoot['versionId'] = 'v2';

    await expectLater(
      gate.admit(
        manifest: manifest,
        entryId: entry.entryId,
        technicalRoot: _readObject(entry.technicalLabPath),
        dqg300Evidence: const LabDqg300EvidenceCodec().decode(
          File(entry.dqg300EvidencePath).readAsStringSync(),
        ),
        presentationPackage: LabLearnerPresentationPackage.fromJson(
          presentationRoot,
        ),
      ),
      throwsA(isA<LabStudioException>()),
    );

    expect(await repository.load(entry.labId, entry.versionId), isNull);
  });

  test('Q11 admits only DRAFT manifest-backed source packages', () async {
    final manifest = _manifest();
    final entry = manifest.entries.first;
    final repository = InMemoryLabPublishedRepository();
    final gate = LabScenarioPopulationPublicationGate(
      studio: Lab1000StudioService(repository: repository),
    );
    final technicalRoot = _readObject(entry.technicalLabPath);
    final lab = (technicalRoot['lab'] as Map).cast<String, Object?>();
    lab['lifecycle'] = 'PUBLISHED';

    await expectLater(
      gate.admit(
        manifest: manifest,
        entryId: entry.entryId,
        technicalRoot: technicalRoot,
        dqg300Evidence: const LabDqg300EvidenceCodec().decode(
          File(entry.dqg300EvidencePath).readAsStringSync(),
        ),
        presentationPackage: LabLearnerPresentationPackage.fromJson(
          _readObject(entry.learnerPresentationPath),
        ),
      ),
      throwsA(isA<LabStudioException>()),
    );

    expect(await repository.load(entry.labId, entry.versionId), isNull);
  });

  test('Q11 immutable repository admission cannot overwrite a version',
      () async {
    final manifest = _manifest();
    final entry = manifest.entries.first;
    final repository = InMemoryLabPublishedRepository();
    final gate = LabScenarioPopulationPublicationGate(
      studio: Lab1000StudioService(repository: repository),
    );
    final technicalRoot = _readObject(entry.technicalLabPath);
    final evidence = const LabDqg300EvidenceCodec().decode(
      File(entry.dqg300EvidencePath).readAsStringSync(),
    );
    final presentation = LabLearnerPresentationPackage.fromJson(
      _readObject(entry.learnerPresentationPath),
    );

    final first = await gate.admit(
      manifest: manifest,
      entryId: entry.entryId,
      technicalRoot: technicalRoot,
      dqg300Evidence: evidence,
      presentationPackage: presentation,
      validatedAt: DateTime.utc(2026, 9, 23, 18),
      publishedAt: DateTime.utc(2026, 9, 23, 18, 1),
    );
    final original = await repository.load(entry.labId, entry.versionId);

    await expectLater(
      gate.admit(
        manifest: manifest,
        entryId: entry.entryId,
        technicalRoot: technicalRoot,
        dqg300Evidence: evidence,
        presentationPackage: presentation,
      ),
      throwsA(isA<LabStudioException>()),
    );

    final stored = await repository.load(entry.labId, entry.versionId);
    expect(first.isAdmitted, isTrue);
    expect(stored!.publishedJson, original!.publishedJson);
    expect(stored.snapshotFingerprint, original.snapshotFingerprint);
  });
}
