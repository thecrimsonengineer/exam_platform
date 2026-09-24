import 'lab_contracts.dart';
import 'lab_learner_catalogue.dart';
import 'lab_production_population_seed.dart';
import 'lab_production_release_closure.dart';
import 'lab_scenario_population_manifest.dart';
import 'lab_scenario_population_publication.dart';
import 'lab_snapshot_fingerprint.dart';
import 'lab_studio.dart';

const String kBatch2ReleaseConfirmationPhrase = 'RELEASE BATCH 2 10 LABS';
const String kBatch2ValidationAuthority = 'LSP-Q11-POPULATION-AUTO';

class LabBatch2ReleaseException implements Exception {
  const LabBatch2ReleaseException(this.message);

  final String message;

  @override
  String toString() => 'LabBatch2ReleaseException: ' + message;
}

class LabBatch2ReleaseBundle {
  LabBatch2ReleaseBundle({
    required this.manifest,
    required Iterable<LabPublishedVersion> publishedVersions,
    required Iterable<LabLearnerCatalogueEntry> catalogueEntries,
    required this.evidence,
  }) : publishedVersions = List<LabPublishedVersion>.unmodifiable(
         publishedVersions,
       ),
       catalogueEntries = List<LabLearnerCatalogueEntry>.unmodifiable(
         catalogueEntries,
       );

  final LabScenarioPopulationManifest manifest;
  final List<LabPublishedVersion> publishedVersions;
  final List<LabLearnerCatalogueEntry> catalogueEntries;
  final LabProductionReleaseEvidence evidence;
}

class LabBatch2ReleaseService {
  const LabBatch2ReleaseService();

  Future<LabBatch2ReleaseBundle> prepare({
    required LabScenarioPopulationManifest manifest,
    required Iterable<LabProductionPopulationSeedCandidate> candidates,
    required String environmentId,
    required String executedBy,
    DateTime? validatedAt,
    DateTime? publishedAt,
    DateTime? executedAt,
  }) async {
    if (manifest.manifestId != kBatch2LabProductionManifestId ||
        manifest.entries.length != 10) {
      throw const LabBatch2ReleaseException(
        'Batch 2 requires the frozen 10-LAB Batch 2 manifest.',
      );
    }
    if (environmentId.trim().isEmpty || executedBy.trim().isEmpty) {
      throw const LabBatch2ReleaseException(
        'Batch 2 release requires an environment and authenticated actor.',
      );
    }

    final candidateByEntry = <String, LabProductionPopulationSeedCandidate>{};
    for (final candidate in candidates) {
      if (candidateByEntry.containsKey(candidate.entryId)) {
        throw const LabBatch2ReleaseException(
          'Batch 2 candidates contain a duplicate entry ID.',
        );
      }
      candidateByEntry[candidate.entryId] = candidate;
    }
    final expectedIds = manifest.entries.map((item) => item.entryId).toSet();
    if (candidateByEntry.length != expectedIds.length ||
        !candidateByEntry.keys.toSet().containsAll(expectedIds) ||
        !expectedIds.containsAll(candidateByEntry.keys)) {
      throw const LabBatch2ReleaseException(
        'Batch 2 candidates must exactly match the frozen manifest.',
      );
    }

    final publishedRepository = InMemoryLabPublishedRepository();
    final catalogueRepository = InMemoryLabLearnerCatalogueRepository();
    final publicationGate = LabScenarioPopulationPublicationGate(
      studio: Lab1000StudioService(repository: publishedRepository),
      validationAuthority: kBatch2ValidationAuthority,
    );
    final admission = LabLearnerCatalogueAdmissionService(
      publishedRepository: publishedRepository,
      catalogueRepository: catalogueRepository,
      expectedValidationAuthority: kBatch2ValidationAuthority,
    );

    final validationBase = (validatedAt ?? DateTime.now().toUtc()).toUtc();
    final publicationBase =
        (publishedAt ?? validationBase.add(const Duration(minutes: 1))).toUtc();

    final versions = <LabPublishedVersion>[];
    final catalogue = <LabLearnerCatalogueEntry>[];
    final releaseEntries = <LabProductionReleaseEntryEvidence>[];

    for (var index = 0; index < manifest.entries.length; index++) {
      final entry = manifest.entries[index];
      final candidate = candidateByEntry[entry.entryId]!;
      final publication = await publicationGate.admit(
        manifest: manifest,
        entryId: entry.entryId,
        technicalRoot: candidate.technicalRoot,
        dqg300Evidence: candidate.dqg300Evidence,
        presentationPackage: candidate.presentationPackage,
        validatedAt: validationBase.add(Duration(seconds: index)),
        publishedAt: publicationBase.add(Duration(seconds: index)),
      );
      if (!publication.isAdmitted) {
        throw LabBatch2ReleaseException(
          'Batch 2 publication admission failed for ' + entry.identityKey + '.',
        );
      }

      final version = publication.publishedVersion;
      final fingerprint = version.snapshotFingerprint;
      if (fingerprint == null ||
          !LabSnapshotFingerprint.matches(
            publishedJson: version.publishedJson,
            fingerprint: fingerprint,
          )) {
        throw LabBatch2ReleaseException(
          'Batch 2 snapshot fingerprint failed for ' + entry.identityKey + '.',
        );
      }

      final catalogueEntry = await admission.admit(
        manifest: manifest,
        entryId: entry.entryId,
        presentation: candidate.presentationPackage,
      );
      final package = LabPackage.decode(version.publishedJson);
      final decisionCount = package.nodes.whereType<LabDecisionNode>().length;
      if (decisionCount != 5 ||
          catalogueEntry.decisionCount != 5 ||
          catalogueEntry.identityKey != entry.identityKey) {
        throw LabBatch2ReleaseException(
          'Batch 2 learner catalogue verification failed for ' +
              entry.identityKey +
              '.',
        );
      }

      versions.add(version);
      catalogue.add(catalogueEntry);
      releaseEntries.add(
        LabProductionReleaseEntryEvidence(
          entryId: entry.entryId,
          labId: entry.labId,
          versionId: entry.versionId,
          snapshotFingerprint: fingerprint,
          publishedAtIso: version.publishedAt.toUtc().toIso8601String(),
          decisionCount: decisionCount,
        ),
      );
    }

    final evidence = LabProductionReleaseEvidence.issueForProvenance(
      releaseId: LabProductionReleaseClosureService.releaseIdFor(manifest),
      manifestId: manifest.manifestId,
      manifestFingerprint:
          LabProductionReleaseClosureService.manifestFingerprintFor(manifest),
      closureSha: kLspBatch2PrecatalogueClosedSha,
      validationRunId: kLspBatch2PrecatalogueValidationRunId,
      environmentId: environmentId,
      executedBy: executedBy,
      executedAt: executedAt ?? DateTime.now().toUtc(),
      catalogueIdentityKeys: catalogue.map((item) => item.identityKey),
      entries: releaseEntries,
    );

    if (evidence.labCount != 10 || evidence.totalDecisionCount != 50) {
      throw const LabBatch2ReleaseException(
        'Batch 2 release evidence must certify 10 LABs and 50 Decisions.',
      );
    }

    return LabBatch2ReleaseBundle(
      manifest: manifest,
      publishedVersions: versions,
      catalogueEntries: catalogue,
      evidence: evidence,
    );
  }
}
