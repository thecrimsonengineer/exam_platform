import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

import 'lab_batch2_release.dart';
import 'lab_dqg300_evidence_store.dart';
import 'lab_firestore_repositories.dart';
import 'lab_learner_catalogue.dart';
import 'lab_learner_presentation.dart';
import 'lab_production_population_seed.dart';
import 'lab_production_release_closure.dart';
import 'lab_scenario_population_manifest.dart';
import 'lab_studio.dart';

const String kBatch2PopulationManifestAsset =
    'content/lab_population_batch2/manifest.json';

enum LabBatch2OperatorState {
  blockedOriginalRelease,
  ready,
  closed,
  blockedPartial,
}

class LabBatch2OperatorInspection {
  const LabBatch2OperatorInspection({
    required this.state,
    required this.manifestId,
    required this.manifestFingerprint,
    required this.environmentId,
    required this.expectedLabCount,
    required this.publishedCount,
    required this.catalogueCount,
    required this.originalReleaseClosed,
    this.evidence,
    this.blockingReason,
  });

  final LabBatch2OperatorState state;
  final String manifestId;
  final String manifestFingerprint;
  final String environmentId;
  final int expectedLabCount;
  final int publishedCount;
  final int catalogueCount;
  final bool originalReleaseClosed;
  final LabProductionReleaseEvidence? evidence;
  final String? blockingReason;

  bool get canPublish => state == LabBatch2OperatorState.ready;
  bool get isClosed => state == LabBatch2OperatorState.closed;

  bool get isPermissionBlocked {
    final reason = blockingReason?.toLowerCase() ?? '';
    return reason.contains('permission-denied') ||
        reason.contains('missing or insufficient permissions') ||
        reason.contains('missing or insufficient permission');
  }

  String get stateLabel {
    if (isPermissionBlocked) return 'ACCESS_BLOCKED';
    switch (state) {
      case LabBatch2OperatorState.blockedOriginalRelease:
        return 'ORIGINAL_RELEASE_REQUIRED';
      case LabBatch2OperatorState.ready:
        return 'READY';
      case LabBatch2OperatorState.closed:
        return 'CLOSED';
      case LabBatch2OperatorState.blockedPartial:
        return 'BLOCKED_PARTIAL';
    }
  }
}

abstract class LabBatch2PopulationSource {
  Future<LabScenarioPopulationManifest> loadManifest();

  Future<List<LabProductionPopulationSeedCandidate>> loadCandidates(
    LabScenarioPopulationManifest manifest,
  );
}

class BundledLabBatch2PopulationSource implements LabBatch2PopulationSource {
  const BundledLabBatch2PopulationSource({required this.bundle});

  final AssetBundle bundle;

  Future<Map<String, Object?>> _readObject(String path) async {
    final source = await bundle.loadString(path);
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw LabBatch2ReleaseException(
        'Batch 2 expected a JSON object at ' + path + '.',
      );
    }
    return decoded.cast<String, Object?>();
  }

  @override
  Future<LabScenarioPopulationManifest> loadManifest() async {
    return LabScenarioPopulationManifest.fromJson(
      await _readObject(kBatch2PopulationManifestAsset),
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

abstract class LabBatch2ReleaseOperator {
  Future<LabBatch2OperatorInspection> inspect();

  Future<LabProductionReleaseEvidence> publish({
    required String executedBy,
    required String confirmationPhrase,
    DateTime? executedAt,
  });
}

class LabBatch2ReleaseOperatorService implements LabBatch2ReleaseOperator {
  const LabBatch2ReleaseOperatorService({
    required this.populationSource,
    required this.publishedRepository,
    required this.catalogueRepository,
    required this.evidenceRepository,
    required this.atomicRepository,
    required this.environmentId,
  });

  factory LabBatch2ReleaseOperatorService.firestore({
    FirebaseFirestore? firestore,
    AssetBundle? bundle,
  }) {
    final instance = firestore ?? FirebaseFirestore.instance;
    return LabBatch2ReleaseOperatorService(
      populationSource: BundledLabBatch2PopulationSource(
        bundle: bundle ?? rootBundle,
      ),
      publishedRepository: FirestoreLabPublishedRepository(firestore: instance),
      catalogueRepository: FirestoreLabLearnerCatalogueRepository(
        firestore: instance,
      ),
      evidenceRepository: FirestoreLabProductionReleaseEvidenceRepository(
        firestore: instance,
      ),
      atomicRepository: FirestoreLabBatch2AtomicReleaseRepository(
        firestore: instance,
      ),
      environmentId:
          'firebase_project:' + instance.app.options.projectId.trim(),
    );
  }

  final LabBatch2PopulationSource populationSource;
  final LabPublishedRepository publishedRepository;
  final LabLearnerCatalogueRepository catalogueRepository;
  final LabProductionReleaseEvidenceRepository evidenceRepository;
  final FirestoreLabBatch2AtomicReleaseRepository atomicRepository;
  final String environmentId;

  @override
  Future<LabBatch2OperatorInspection> inspect() async {
    final manifest = await populationSource.loadManifest();
    final fingerprint =
        LabProductionReleaseClosureService.manifestFingerprintFor(manifest);
    var publishedCount = 0;
    var catalogueCount = 0;

    try {
      final originalEvidence = await evidenceRepository.load(
        kInitialLabProductionReleaseId,
      );
      final originalReleased = await evidenceRepository.isReleased(
        kInitialLabProductionReleaseId,
      );
      final originalClosed =
          originalEvidence != null &&
          originalReleased &&
          originalEvidence.manifestId == 'phase_l_population_v1';

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
      final released = await evidenceRepository.isReleased(releaseId);

      if (!originalClosed) {
        return _inspection(
          state: LabBatch2OperatorState.blockedOriginalRelease,
          manifest: manifest,
          fingerprint: fingerprint,
          publishedCount: publishedCount,
          catalogueCount: catalogueCount,
          originalReleaseClosed: false,
          evidence: evidence,
          reason:
              'The original 10-LAB production release must be CLOSED before Batch 2 can publish.',
        );
      }

      if (evidence != null && released) {
        if (publishedCount != manifest.entries.length ||
            catalogueCount != manifest.entries.length ||
            evidence.manifestId != manifest.manifestId ||
            evidence.labCount != manifest.entries.length ||
            evidence.totalDecisionCount != 50) {
          return _inspection(
            state: LabBatch2OperatorState.blockedPartial,
            manifest: manifest,
            fingerprint: fingerprint,
            publishedCount: publishedCount,
            catalogueCount: catalogueCount,
            originalReleaseClosed: true,
            evidence: evidence,
            reason:
                'Batch 2 release evidence exists but the production population is incomplete or inconsistent.',
          );
        }

        return _inspection(
          state: LabBatch2OperatorState.closed,
          manifest: manifest,
          fingerprint: fingerprint,
          publishedCount: publishedCount,
          catalogueCount: catalogueCount,
          originalReleaseClosed: true,
          evidence: evidence,
        );
      }

      if (evidence != null || released) {
        return _inspection(
          state: LabBatch2OperatorState.blockedPartial,
          manifest: manifest,
          fingerprint: fingerprint,
          publishedCount: publishedCount,
          catalogueCount: catalogueCount,
          originalReleaseClosed: true,
          evidence: evidence,
          reason:
              'Batch 2 release state and immutable evidence do not agree. Automatic repair is forbidden.',
        );
      }

      if (publishedCount == 0 && catalogueCount == 0) {
        return _inspection(
          state: LabBatch2OperatorState.ready,
          manifest: manifest,
          fingerprint: fingerprint,
          publishedCount: 0,
          catalogueCount: 0,
          originalReleaseClosed: true,
        );
      }

      return _inspection(
        state: LabBatch2OperatorState.blockedPartial,
        manifest: manifest,
        fingerprint: fingerprint,
        publishedCount: publishedCount,
        catalogueCount: catalogueCount,
        originalReleaseClosed: true,
        reason:
            'Batch 2 repositories contain a partial population. Automatic overwrite or repair is forbidden.',
      );
    } catch (error) {
      return _inspection(
        state: LabBatch2OperatorState.blockedPartial,
        manifest: manifest,
        fingerprint: fingerprint,
        publishedCount: publishedCount,
        catalogueCount: catalogueCount,
        originalReleaseClosed: false,
        reason: error.toString(),
      );
    }
  }

  @override
  Future<LabProductionReleaseEvidence> publish({
    required String executedBy,
    required String confirmationPhrase,
    DateTime? executedAt,
  }) async {
    if (executedBy.trim().isEmpty) {
      throw const LabBatch2ReleaseException(
        'Batch 2 publication requires an authenticated admin actor.',
      );
    }
    if (confirmationPhrase != kBatch2ReleaseConfirmationPhrase) {
      throw const LabBatch2ReleaseException(
        'Batch 2 publication requires the exact confirmation phrase.',
      );
    }

    final before = await inspect();
    if (!before.canPublish) {
      throw LabBatch2ReleaseException(
        'Batch 2 publication is not permitted from state ' +
            before.stateLabel +
            '.',
      );
    }

    final manifest = await populationSource.loadManifest();
    final candidates = await populationSource.loadCandidates(manifest);
    final bundle = await const LabBatch2ReleaseService().prepare(
      manifest: manifest,
      candidates: candidates,
      environmentId: environmentId,
      executedBy: executedBy.trim(),
      executedAt: executedAt,
    );

    await atomicRepository.commit(bundle);
    await atomicRepository.verify(bundle);

    final after = await inspect();
    final stored = after.evidence;
    if (!after.isClosed ||
        stored == null ||
        stored.evidenceFingerprint != bundle.evidence.evidenceFingerprint) {
      throw const LabBatch2ReleaseException(
        'Batch 2 publication completed without a verified CLOSED release state.',
      );
    }

    return stored;
  }

  LabBatch2OperatorInspection _inspection({
    required LabBatch2OperatorState state,
    required LabScenarioPopulationManifest manifest,
    required String fingerprint,
    required int publishedCount,
    required int catalogueCount,
    required bool originalReleaseClosed,
    LabProductionReleaseEvidence? evidence,
    String? reason,
  }) {
    return LabBatch2OperatorInspection(
      state: state,
      manifestId: manifest.manifestId,
      manifestFingerprint: fingerprint,
      environmentId: environmentId,
      expectedLabCount: manifest.entries.length,
      publishedCount: publishedCount,
      catalogueCount: catalogueCount,
      originalReleaseClosed: originalReleaseClosed,
      evidence: evidence,
      blockingReason: reason,
    );
  }
}
