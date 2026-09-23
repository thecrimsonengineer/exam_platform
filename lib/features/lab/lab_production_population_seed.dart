import 'lab_contracts.dart';
import 'lab_dqg300.dart';
import 'lab_learner_catalogue.dart';
import 'lab_learner_presentation.dart';
import 'lab_scenario_population_manifest.dart';
import 'lab_scenario_population_publication.dart';
import 'lab_studio.dart';

class LabProductionPopulationSeedException implements Exception {
  const LabProductionPopulationSeedException(this.message);

  final String message;

  @override
  String toString() => 'LabProductionPopulationSeedException: ' + message;
}

class LabProductionPopulationSeedCandidate {
  LabProductionPopulationSeedCandidate({
    required this.entryId,
    required Map<String, Object?> technicalRoot,
    required this.dqg300Evidence,
    required this.presentationPackage,
  }) : technicalRoot = Map<String, Object?>.unmodifiable(technicalRoot);

  final String entryId;
  final Map<String, Object?> technicalRoot;
  final LabDqg300EvidenceBundle dqg300Evidence;
  final LabLearnerPresentationPackage presentationPackage;
}

class LabProductionSeedEntryReceipt {
  const LabProductionSeedEntryReceipt({
    required this.entryId,
    required this.labId,
    required this.versionId,
    required this.snapshotFingerprint,
    required this.decisionCount,
  });

  final String entryId;
  final String labId;
  final String versionId;
  final String snapshotFingerprint;
  final int decisionCount;

  String get identityKey => labId + '@' + versionId;
}

class LabProductionReleaseVerification {
  LabProductionReleaseVerification({
    required this.manifestId,
    required Iterable<String> catalogueIdentityKeys,
    required this.totalDecisionCount,
  }) : catalogueIdentityKeys = List<String>.unmodifiable(
         catalogueIdentityKeys,
       );

  final String manifestId;
  final List<String> catalogueIdentityKeys;
  final int totalDecisionCount;
}

class LabProductionPopulationSeedReceipt {
  LabProductionPopulationSeedReceipt({
    required this.manifestId,
    required Iterable<LabProductionSeedEntryReceipt> entries,
    required this.verification,
  }) : entries = List<LabProductionSeedEntryReceipt>.unmodifiable(entries);

  final String manifestId;
  final List<LabProductionSeedEntryReceipt> entries;
  final LabProductionReleaseVerification verification;
}

/// LSP-Q14 controlled initial production population seed.
///
/// The seed is deliberately one-shot:
/// - every manifest candidate is fully preflighted in memory before live writes;
/// - the learner catalogue must be empty before the initial seed;
/// - target published/catalogue identities must not already exist;
/// - Q11 immutable publication and Q12 learner admission are reused unchanged;
/// - every admitted version is reloaded through controlled learner delivery;
/// - final learner release must exactly equal the manifest population.
///
/// CI and unit tests use in-memory repositories. A production caller supplies
/// the persistent Q13 repositories explicitly.
class LabProductionPopulationSeedService {
  const LabProductionPopulationSeedService({
    required this.publishedRepository,
    required this.catalogueRepository,
  });

  final LabPublishedRepository publishedRepository;
  final LabLearnerCatalogueRepository catalogueRepository;

  Future<LabProductionPopulationSeedReceipt> seedAndVerify({
    required LabScenarioPopulationManifest manifest,
    required Iterable<LabProductionPopulationSeedCandidate> candidates,
    DateTime? validatedAt,
    DateTime? publishedAt,
  }) async {
    final candidateByEntry = _validateCandidateSet(manifest, candidates);
    final validatedBase = (validatedAt ?? DateTime.now().toUtc()).toUtc();
    final publishedBase =
        (publishedAt ?? validatedBase.add(const Duration(minutes: 1))).toUtc();

    await _requirePristineInitialRelease(manifest);

    final preflightPublishedRepository = InMemoryLabPublishedRepository();
    final preflightCatalogueRepository =
        InMemoryLabLearnerCatalogueRepository();
    final entries = await _populate(
      manifest: manifest,
      candidateByEntry: candidateByEntry,
      publishedRepository: preflightPublishedRepository,
      catalogueRepository: preflightCatalogueRepository,
      validatedBase: validatedBase,
      publishedBase: publishedBase,
    );

    final productionDelivery = LabLearnerControlledDeliveryService(
      publishedRepository: publishedRepository,
      catalogueRepository: catalogueRepository,
    );

    for (final manifestEntry in manifest.entries) {
      final preflightVersion = await preflightPublishedRepository.load(
        manifestEntry.labId,
        manifestEntry.versionId,
      );
      final preflightCatalogue = await preflightCatalogueRepository.load(
        manifestEntry.labId,
        manifestEntry.versionId,
      );
      if (preflightVersion == null || preflightCatalogue == null) {
        throw LabProductionPopulationSeedException(
          'Q14 preflight artifacts are incomplete for ' +
              manifestEntry.identityKey +
              '.',
        );
      }

      await publishedRepository.saveImmutable(preflightVersion);
      await catalogueRepository.saveImmutable(preflightCatalogue);

      final controlled = await productionDelivery.load(
        labId: manifestEntry.labId,
        versionId: manifestEntry.versionId,
      );
      final receipt = entries.firstWhere(
        (item) => item.identityKey == manifestEntry.identityKey,
      );
      final decisionCount = controlled.package.nodes
          .whereType<LabDecisionNode>()
          .length;
      if (controlled.package.metadata.id != manifestEntry.labId ||
          controlled.package.metadata.versionId != manifestEntry.versionId ||
          controlled.catalogueEntry.manifestEntryId != manifestEntry.entryId ||
          decisionCount != receipt.decisionCount) {
        throw LabProductionPopulationSeedException(
          'Q14 production persistence verification failed for ' +
              manifestEntry.identityKey +
              '.',
        );
      }
    }

    final verification = await verifyRelease(manifest: manifest);
    return LabProductionPopulationSeedReceipt(
      manifestId: manifest.manifestId,
      entries: entries,
      verification: verification,
    );
  }

  Future<LabProductionReleaseVerification> verifyRelease({
    required LabScenarioPopulationManifest manifest,
  }) async {
    final available = await catalogueRepository.listAvailable();
    final expected = manifest.entries.map((entry) => entry.identityKey).toSet();
    final actual = available.map((entry) => entry.identityKey).toSet();

    if (available.length != manifest.entries.length ||
        actual.length != expected.length ||
        !actual.containsAll(expected) ||
        !expected.containsAll(actual)) {
      throw const LabProductionPopulationSeedException(
        'Q14 learner release catalogue does not exactly match the population manifest.',
      );
    }

    final delivery = LabLearnerControlledDeliveryService(
      publishedRepository: publishedRepository,
      catalogueRepository: catalogueRepository,
    );
    var totalDecisionCount = 0;

    for (final manifestEntry in manifest.entries) {
      final catalogueEntry = await catalogueRepository.load(
        manifestEntry.labId,
        manifestEntry.versionId,
      );
      if (catalogueEntry == null ||
          catalogueEntry.manifestEntryId != manifestEntry.entryId) {
        throw LabProductionPopulationSeedException(
          'Q14 learner catalogue binding is invalid for ' +
              manifestEntry.identityKey +
              '.',
        );
      }

      final controlled = await delivery.load(
        labId: manifestEntry.labId,
        versionId: manifestEntry.versionId,
      );
      if (controlled.package.metadata.id != manifestEntry.labId ||
          controlled.package.metadata.versionId != manifestEntry.versionId ||
          controlled.presentation.labId != manifestEntry.labId ||
          controlled.presentation.versionId != manifestEntry.versionId) {
        throw LabProductionPopulationSeedException(
          'Q14 controlled learner delivery drifted for ' +
              manifestEntry.identityKey +
              '.',
        );
      }

      totalDecisionCount += controlled.package.nodes
          .whereType<LabDecisionNode>()
          .length;
    }

    final sortedKeys = actual.toList()..sort();
    return LabProductionReleaseVerification(
      manifestId: manifest.manifestId,
      catalogueIdentityKeys: sortedKeys,
      totalDecisionCount: totalDecisionCount,
    );
  }

  Map<String, LabProductionPopulationSeedCandidate> _validateCandidateSet(
    LabScenarioPopulationManifest manifest,
    Iterable<LabProductionPopulationSeedCandidate> candidates,
  ) {
    final candidateList = candidates.toList(growable: false);
    final byEntry = <String, LabProductionPopulationSeedCandidate>{};

    for (final candidate in candidateList) {
      if (byEntry.containsKey(candidate.entryId)) {
        throw LabProductionPopulationSeedException(
          'Q14 seed contains duplicate candidate ' + candidate.entryId + '.',
        );
      }
      byEntry[candidate.entryId] = candidate;
    }

    final expectedIds = manifest.entries.map((entry) => entry.entryId).toSet();
    if (candidateList.length != manifest.entries.length ||
        byEntry.length != expectedIds.length ||
        byEntry.keys.any((entryId) => !expectedIds.contains(entryId)) ||
        expectedIds.any((entryId) => !byEntry.containsKey(entryId))) {
      throw const LabProductionPopulationSeedException(
        'Q14 seed candidates must exactly match the population manifest.',
      );
    }

    return Map<String, LabProductionPopulationSeedCandidate>.unmodifiable(
      byEntry,
    );
  }

  Future<void> _requirePristineInitialRelease(
    LabScenarioPopulationManifest manifest,
  ) async {
    final available = await catalogueRepository.listAvailable();
    if (available.isNotEmpty) {
      throw const LabProductionPopulationSeedException(
        'Q14 initial production seed requires an empty learner catalogue.',
      );
    }

    for (final entry in manifest.entries) {
      final published = await publishedRepository.load(
        entry.labId,
        entry.versionId,
      );
      final catalogued = await catalogueRepository.load(
        entry.labId,
        entry.versionId,
      );
      if (published != null || catalogued != null) {
        throw LabProductionPopulationSeedException(
          'Q14 refuses to overwrite existing production identity ' +
              entry.identityKey +
              '.',
        );
      }
    }
  }

  Future<List<LabProductionSeedEntryReceipt>> _populate({
    required LabScenarioPopulationManifest manifest,
    required Map<String, LabProductionPopulationSeedCandidate>
    candidateByEntry,
    required LabPublishedRepository publishedRepository,
    required LabLearnerCatalogueRepository catalogueRepository,
    required DateTime validatedBase,
    required DateTime publishedBase,
  }) async {
    final publicationGate = LabScenarioPopulationPublicationGate(
      studio: Lab1000StudioService(repository: publishedRepository),
    );
    final catalogueAdmission = LabLearnerCatalogueAdmissionService(
      publishedRepository: publishedRepository,
      catalogueRepository: catalogueRepository,
    );
    final controlledDelivery = LabLearnerControlledDeliveryService(
      publishedRepository: publishedRepository,
      catalogueRepository: catalogueRepository,
    );
    final receipts = <LabProductionSeedEntryReceipt>[];

    for (var index = 0; index < manifest.entries.length; index++) {
      final manifestEntry = manifest.entries[index];
      final candidate = candidateByEntry[manifestEntry.entryId]!;
      final validationTime = validatedBase.add(Duration(seconds: index));
      final publicationTime = publishedBase.add(Duration(seconds: index));

      final publication = await publicationGate.admit(
        manifest: manifest,
        entryId: manifestEntry.entryId,
        technicalRoot: candidate.technicalRoot,
        dqg300Evidence: candidate.dqg300Evidence,
        presentationPackage: candidate.presentationPackage,
        validatedAt: validationTime,
        publishedAt: publicationTime,
      );
      if (!publication.isAdmitted ||
          publication.publishedVersion.snapshotFingerprint == null) {
        throw LabProductionPopulationSeedException(
          'Q14 publication admission failed for ' +
              manifestEntry.identityKey +
              '.',
        );
      }

      final catalogueEntry = await catalogueAdmission.admit(
        manifest: manifest,
        entryId: manifestEntry.entryId,
        presentation: candidate.presentationPackage,
      );
      final controlled = await controlledDelivery.load(
        labId: manifestEntry.labId,
        versionId: manifestEntry.versionId,
      );

      final decisionCount = controlled.package.nodes
          .whereType<LabDecisionNode>()
          .length;
      if (catalogueEntry.identityKey != manifestEntry.identityKey ||
          controlled.package.metadata.id != manifestEntry.labId ||
          controlled.package.metadata.versionId != manifestEntry.versionId ||
          decisionCount != catalogueEntry.decisionCount) {
        throw LabProductionPopulationSeedException(
          'Q14 post-write learner verification failed for ' +
              manifestEntry.identityKey +
              '.',
        );
      }

      receipts.add(
        LabProductionSeedEntryReceipt(
          entryId: manifestEntry.entryId,
          labId: manifestEntry.labId,
          versionId: manifestEntry.versionId,
          snapshotFingerprint:
              publication.publishedVersion.snapshotFingerprint!,
          decisionCount: decisionCount,
        ),
      );
    }

    return List<LabProductionSeedEntryReceipt>.unmodifiable(receipts);
  }
}
