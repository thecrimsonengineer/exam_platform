import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

import 'lab_dqg300_evidence_store.dart';
import 'lab_firestore_repositories.dart';
import 'lab_learner_catalogue.dart';
import 'lab_learner_presentation.dart';
import 'lab_production_population_seed.dart';
import 'lab_production_release_closure.dart';
import 'lab_scenario_population_manifest.dart';
import 'lab_studio.dart';

const String kLspQ15ClosedSha = 'ff4aa9c2a04b668549bb7af8a5f03806c31d6644';
const String kLspQ15ClosureValidationRunId = '35946294148';
const String kLabPopulationManifestAsset =
    'content/lab_population/manifest.json';
const String kQ16SeedConfirmationPhrase = 'RELEASE 10 LABS';
const String kQ16CloseConfirmationPhrase = 'CLOSE 10 LABS';

enum LabProductionOperatorState {
  pristine,
  completeUnclosed,
  closed,
  blockedPartial,
}

class LabProductionOperatorInspection {
  const LabProductionOperatorInspection({
    required this.state,
    required this.manifestId,
    required this.manifestFingerprint,
    required this.environmentId,
    required this.expectedLabCount,
    required this.publishedCount,
    required this.catalogueCount,
    required this.catalogueIdentityCount,
    this.evidence,
    this.blockingReason,
  });

  final LabProductionOperatorState state;
  final String manifestId;
  final String manifestFingerprint;
  final String environmentId;
  final int expectedLabCount;
  final int publishedCount;
  final int catalogueCount;
  final int catalogueIdentityCount;
  final LabProductionReleaseEvidence? evidence;
  final String? blockingReason;

  bool get canExecuteSeed => state == LabProductionOperatorState.pristine;

  bool get canCloseExisting =>
      state == LabProductionOperatorState.completeUnclosed;

  bool get isClosed => state == LabProductionOperatorState.closed;

  String get stateLabel {
    switch (state) {
      case LabProductionOperatorState.pristine:
        return 'PRISTINE';
      case LabProductionOperatorState.completeUnclosed:
        return 'COMPLETE_UNCLOSED';
      case LabProductionOperatorState.closed:
        return 'CLOSED';
      case LabProductionOperatorState.blockedPartial:
        return 'BLOCKED_PARTIAL';
    }
  }

  String? get requiredConfirmationPhrase {
    if (canExecuteSeed) return kQ16SeedConfirmationPhrase;
    if (canCloseExisting) return kQ16CloseConfirmationPhrase;
    return null;
  }
}

abstract class LabProductionPopulationSource {
  Future<LabScenarioPopulationManifest> loadManifest();

  Future<List<LabProductionPopulationSeedCandidate>> loadCandidates(
    LabScenarioPopulationManifest manifest,
  );
}

class BundledLabProductionPopulationSource
    implements LabProductionPopulationSource {
  const BundledLabProductionPopulationSource({required this.bundle});

  final AssetBundle bundle;

  Future<Map<String, Object?>> _readObject(String path) async {
    final source = await bundle.loadString(path);
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw LabProductionReleaseClosureException(
        'Q16 expected a JSON object at ' + path + '.',
      );
    }
    return decoded.cast<String, Object?>();
  }

  @override
  Future<LabScenarioPopulationManifest> loadManifest() async {
    return LabScenarioPopulationManifest.fromJson(
      await _readObject(kLabPopulationManifestAsset),
    );
  }

  @override
  Future<List<LabProductionPopulationSeedCandidate>> loadCandidates(
    LabScenarioPopulationManifest manifest,
  ) async {
    final candidates = <LabProductionPopulationSeedCandidate>[];

    for (final entry in manifest.entries) {
      candidates.add(
        LabProductionPopulationSeedCandidate(
          entryId: entry.entryId,
          technicalRoot: await _readObject(entry.technicalLabPath),
          dqg300Evidence: const LabDqg300EvidenceCodec().decode(
            await bundle.loadString(entry.dqg300EvidencePath),
          ),
          presentationPackage: LabLearnerPresentationPackage.fromJson(
            await _readObject(entry.learnerPresentationPath),
          ),
        ),
      );
    }

    return List<LabProductionPopulationSeedCandidate>.unmodifiable(candidates);
  }
}

abstract class LabProductionReleaseOperator {
  Future<LabProductionOperatorInspection> inspect();

  Future<LabProductionReleaseEvidence> executeInitialRelease({
    required String executedBy,
    required String confirmationPhrase,
    DateTime? executedAt,
  });

  Future<LabProductionReleaseEvidence> closeExistingRelease({
    required String executedBy,
    required String confirmationPhrase,
    DateTime? executedAt,
  });
}

class LabProductionReleaseOperatorService
    implements LabProductionReleaseOperator {
  const LabProductionReleaseOperatorService({
    required this.populationSource,
    required this.publishedRepository,
    required this.catalogueRepository,
    required this.evidenceRepository,
    required this.environmentId,
  });

  factory LabProductionReleaseOperatorService.firestore({
    FirebaseFirestore? firestore,
    AssetBundle? bundle,
  }) {
    final instance = firestore ?? FirebaseFirestore.instance;
    return LabProductionReleaseOperatorService(
      populationSource: BundledLabProductionPopulationSource(
        bundle: bundle ?? rootBundle,
      ),
      publishedRepository: FirestoreLabPublishedRepository(firestore: instance),
      catalogueRepository: FirestoreLabLearnerCatalogueRepository(
        firestore: instance,
      ),
      evidenceRepository: FirestoreLabProductionReleaseEvidenceRepository(
        firestore: instance,
      ),
      environmentId:
          'firebase_project:' + instance.app.options.projectId.trim(),
    );
  }

  final LabProductionPopulationSource populationSource;
  final LabPublishedRepository publishedRepository;
  final LabLearnerCatalogueRepository catalogueRepository;
  final LabProductionReleaseEvidenceRepository evidenceRepository;
  final String environmentId;

  @override
  Future<LabProductionOperatorInspection> inspect() async {
    final manifest = await populationSource.loadManifest();
    final fingerprint =
        LabProductionReleaseClosureService.manifestFingerprintFor(manifest);
    var publishedCount = 0;
    var catalogueCount = 0;
    var catalogueIdentityCount = 0;

    try {
      final available = await catalogueRepository.listAvailable();
      catalogueIdentityCount = available
          .map((entry) => entry.identityKey)
          .toSet()
          .length;

      for (final entry in manifest.entries) {
        if (await publishedRepository.load(entry.labId, entry.versionId) !=
            null) {
          publishedCount++;
        }
        if (await catalogueRepository.load(entry.labId, entry.versionId) !=
            null) {
          catalogueCount++;
        }
      }

      final releaseId = LabProductionReleaseClosureService.releaseIdFor(
        manifest,
      );
      final evidence = await evidenceRepository.load(releaseId);
      final releaseMarkerPresent = await evidenceRepository.isReleased(
        releaseId,
      );

      if (evidence != null) {
        final verified = await _closureService().verifyClosedRelease(
          manifest: manifest,
        );
        return LabProductionOperatorInspection(
          state: LabProductionOperatorState.closed,
          manifestId: manifest.manifestId,
          manifestFingerprint: fingerprint,
          environmentId: environmentId,
          expectedLabCount: manifest.entries.length,
          publishedCount: publishedCount,
          catalogueCount: catalogueCount,
          catalogueIdentityCount: catalogueIdentityCount,
          evidence: verified,
        );
      }

      if (releaseMarkerPresent) {
        return _blocked(
          manifest: manifest,
          fingerprint: fingerprint,
          publishedCount: publishedCount,
          catalogueCount: catalogueCount,
          catalogueIdentityCount: catalogueIdentityCount,
          reason: 'Release-state marker exists without immutable Q15 evidence.',
        );
      }

      if (publishedCount == 0 &&
          catalogueCount == 0 &&
          catalogueIdentityCount == 0) {
        return LabProductionOperatorInspection(
          state: LabProductionOperatorState.pristine,
          manifestId: manifest.manifestId,
          manifestFingerprint: fingerprint,
          environmentId: environmentId,
          expectedLabCount: manifest.entries.length,
          publishedCount: 0,
          catalogueCount: 0,
          catalogueIdentityCount: 0,
        );
      }

      if (publishedCount == manifest.entries.length &&
          catalogueCount == manifest.entries.length &&
          catalogueIdentityCount == manifest.entries.length) {
        await LabProductionPopulationSeedService(
          publishedRepository: publishedRepository,
          catalogueRepository: catalogueRepository,
        ).verifyRelease(manifest: manifest);

        return LabProductionOperatorInspection(
          state: LabProductionOperatorState.completeUnclosed,
          manifestId: manifest.manifestId,
          manifestFingerprint: fingerprint,
          environmentId: environmentId,
          expectedLabCount: manifest.entries.length,
          publishedCount: publishedCount,
          catalogueCount: catalogueCount,
          catalogueIdentityCount: catalogueIdentityCount,
        );
      }

      return _blocked(
        manifest: manifest,
        fingerprint: fingerprint,
        publishedCount: publishedCount,
        catalogueCount: catalogueCount,
        catalogueIdentityCount: catalogueIdentityCount,
        reason:
            'Production LAB repositories contain a partial population. Automatic repair is forbidden.',
      );
    } catch (error) {
      return _blocked(
        manifest: manifest,
        fingerprint: fingerprint,
        publishedCount: publishedCount,
        catalogueCount: catalogueCount,
        catalogueIdentityCount: catalogueIdentityCount,
        reason: error.toString(),
      );
    }
  }

  @override
  Future<LabProductionReleaseEvidence> executeInitialRelease({
    required String executedBy,
    required String confirmationPhrase,
    DateTime? executedAt,
  }) async {
    _requireActor(executedBy);
    if (confirmationPhrase != kQ16SeedConfirmationPhrase) {
      throw const LabProductionReleaseClosureException(
        'Q16 initial release requires the exact confirmation phrase.',
      );
    }

    final before = await inspect();
    if (!before.canExecuteSeed) {
      throw LabProductionReleaseClosureException(
        'Q16 seed is not permitted from state ' + before.stateLabel + '.',
      );
    }

    final manifest = await populationSource.loadManifest();
    final candidates = await populationSource.loadCandidates(manifest);
    final evidence =
        await LabProductionReleaseExecutionService(
          seedService: LabProductionPopulationSeedService(
            publishedRepository: publishedRepository,
            catalogueRepository: catalogueRepository,
          ),
          closureService: _closureService(),
        ).executeInitialRelease(
          manifest: manifest,
          candidates: candidates,
          environmentId: environmentId,
          executedBy: executedBy.trim(),
          executedAt: executedAt,
        );

    return _requireClosedAfterAction(evidence);
  }

  @override
  Future<LabProductionReleaseEvidence> closeExistingRelease({
    required String executedBy,
    required String confirmationPhrase,
    DateTime? executedAt,
  }) async {
    _requireActor(executedBy);
    if (confirmationPhrase != kQ16CloseConfirmationPhrase) {
      throw const LabProductionReleaseClosureException(
        'Q16 closure recovery requires the exact confirmation phrase.',
      );
    }

    final before = await inspect();
    if (!before.canCloseExisting) {
      throw LabProductionReleaseClosureException(
        'Q16 closure recovery is not permitted from state ' +
            before.stateLabel +
            '.',
      );
    }

    final manifest = await populationSource.loadManifest();
    final evidence = await _closureService().closeRelease(
      manifest: manifest,
      environmentId: environmentId,
      executedBy: executedBy.trim(),
      executedAt: executedAt,
    );

    return _requireClosedAfterAction(evidence);
  }

  LabProductionReleaseClosureService _closureService() {
    return LabProductionReleaseClosureService(
      publishedRepository: publishedRepository,
      catalogueRepository: catalogueRepository,
      evidenceRepository: evidenceRepository,
    );
  }

  Future<LabProductionReleaseEvidence> _requireClosedAfterAction(
    LabProductionReleaseEvidence expected,
  ) async {
    final after = await inspect();
    final stored = after.evidence;
    if (!after.isClosed ||
        stored == null ||
        stored.evidenceFingerprint != expected.evidenceFingerprint) {
      throw const LabProductionReleaseClosureException(
        'Q16 action completed without a verified CLOSED release state.',
      );
    }
    return stored;
  }

  LabProductionOperatorInspection _blocked({
    required LabScenarioPopulationManifest manifest,
    required String fingerprint,
    required int publishedCount,
    required int catalogueCount,
    required int catalogueIdentityCount,
    required String reason,
  }) {
    return LabProductionOperatorInspection(
      state: LabProductionOperatorState.blockedPartial,
      manifestId: manifest.manifestId,
      manifestFingerprint: fingerprint,
      environmentId: environmentId,
      expectedLabCount: manifest.entries.length,
      publishedCount: publishedCount,
      catalogueCount: catalogueCount,
      catalogueIdentityCount: catalogueIdentityCount,
      blockingReason: reason,
    );
  }

  void _requireActor(String executedBy) {
    if (executedBy.trim().isEmpty) {
      throw const LabProductionReleaseClosureException(
        'Q16 requires an authenticated admin execution actor.',
      );
    }
  }
}
