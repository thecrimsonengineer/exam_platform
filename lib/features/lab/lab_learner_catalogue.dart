import 'lab_contracts.dart';
import 'lab_dqg300.dart';
import 'lab_dqg300_certificate.dart';
import 'lab_l4l_certificate.dart';
import 'lab_l4n_certificate.dart';
import 'lab_learner_loader.dart';
import 'lab_learner_presentation.dart';
import 'lab_scenario_population_manifest.dart';
import 'lab_snapshot_fingerprint.dart';
import 'lab_studio.dart';

class LabLearnerCatalogueException implements Exception {
  const LabLearnerCatalogueException(this.message);

  final String message;

  @override
  String toString() => 'LabLearnerCatalogueException: ' + message;
}

class LabLearnerCatalogueEntry {
  LabLearnerCatalogueEntry.persistence({
    required this.manifestEntryId,
    required this.labId,
    required this.versionId,
    required this.title,
    required this.summary,
    required Iterable<String> focusTags,
    required this.estimatedTime,
    required this.decisionCountLabel,
    required this.decisionCount,
    required Set<LabMode> supportedModes,
    required this.presentation,
  }) : focusTags = List<String>.unmodifiable(focusTags),
       supportedModes = Set<LabMode>.unmodifiable(supportedModes) {
    LabIds.requireCanonical(manifestEntryId, 'learner catalogue manifest entry ID');
    LabIds.requireCanonical(labId, 'learner catalogue LAB ID');
    LabIds.requireCanonical(versionId, 'learner catalogue version ID');

    if (title.trim().isEmpty ||
        summary.trim().isEmpty ||
        estimatedTime.trim().isEmpty ||
        decisionCountLabel.trim().isEmpty ||
        this.focusTags.isEmpty ||
        this.focusTags.any((item) => item.trim().isEmpty) ||
        decisionCount <= 0 ||
        this.supportedModes.isEmpty) {
      throw const LabLearnerCatalogueException(
        'Learner catalogue entry requires complete learner-safe metadata.',
      );
    }

    if (presentation.labId != labId || presentation.versionId != versionId) {
      throw const LabLearnerCatalogueException(
        'Learner catalogue presentation identity must match the catalogue entry.',
      );
    }
  }

  final String manifestEntryId;
  final String labId;
  final String versionId;
  final String title;
  final String summary;
  final List<String> focusTags;
  final String estimatedTime;
  final String decisionCountLabel;
  final int decisionCount;
  final Set<LabMode> supportedModes;
  final LabLearnerPresentationPackage presentation;

  String get identityKey => labId + '@' + versionId;
}

abstract class LabLearnerCatalogueRepository {
  Future<void> saveImmutable(LabLearnerCatalogueEntry entry);

  Future<LabLearnerCatalogueEntry?> load(String labId, String versionId);

  Future<List<LabLearnerCatalogueEntry>> listAvailable();
}

class InMemoryLabLearnerCatalogueRepository
    implements LabLearnerCatalogueRepository {
  final Map<String, LabLearnerCatalogueEntry> _entries =
      <String, LabLearnerCatalogueEntry>{};

  String _key(String labId, String versionId) => labId + '::' + versionId;

  @override
  Future<void> saveImmutable(LabLearnerCatalogueEntry entry) async {
    final key = _key(entry.labId, entry.versionId);
    if (_entries.containsKey(key)) {
      throw const LabLearnerCatalogueException(
        'Learner catalogue entries are immutable and cannot be overwritten.',
      );
    }
    _entries[key] = entry;
  }

  @override
  Future<LabLearnerCatalogueEntry?> load(
    String labId,
    String versionId,
  ) async => _entries[_key(labId, versionId)];

  @override
  Future<List<LabLearnerCatalogueEntry>> listAvailable() async =>
      List<LabLearnerCatalogueEntry>.unmodifiable(_entries.values);
}

class LabLearnerCatalogueAdmissionService {
  const LabLearnerCatalogueAdmissionService({
    required this.publishedRepository,
    required this.catalogueRepository,
    this.presentationValidator = const LabLearnerPresentationValidator(),
    this.expectedValidationAuthority = 'LSP-Q11-POPULATION-AUTO',
  });

  final LabPublishedRepository publishedRepository;
  final LabLearnerCatalogueRepository catalogueRepository;
  final LabLearnerPresentationValidator presentationValidator;
  final String expectedValidationAuthority;

  Future<LabLearnerCatalogueEntry> admit({
    required LabScenarioPopulationManifest manifest,
    required String entryId,
    required LabLearnerPresentationPackage presentation,
  }) async {
    final manifestEntry = manifest.requireEntry(entryId);
    final verified = await _verifyPublishedVersion(
      manifestEntry: manifestEntry,
    );

    final presentationReport = presentationValidator.validate(
      technicalPackage: verified.package,
      presentationPackage: presentation,
    );
    if (!presentationReport.isValid) {
      throw LabLearnerCatalogueException(
        'Q12 learner presentation validation blocked ' +
            manifestEntry.identityKey +
            '.',
      );
    }

    final overview = presentation.presentation;
    final catalogueEntry = LabLearnerCatalogueEntry.persistence(
      manifestEntryId: manifestEntry.entryId,
      labId: manifestEntry.labId,
      versionId: manifestEntry.versionId,
      title: verified.package.metadata.title,
      summary: overview.summary,
      focusTags: List<String>.unmodifiable(overview.focusTags),
      estimatedTime: overview.estimatedTime,
      decisionCountLabel: overview.decisionCountLabel,
      decisionCount: verified.package.nodes.whereType<LabDecisionNode>().length,
      supportedModes: verified.package.metadata.supportedModes,
      presentation: presentation,
    );

    await catalogueRepository.saveImmutable(catalogueEntry);
    return catalogueEntry;
  }

  Future<_VerifiedPublishedLab> _verifyPublishedVersion({
    required LabScenarioPopulationManifestEntry manifestEntry,
  }) async {
    final version = await publishedRepository.load(
      manifestEntry.labId,
      manifestEntry.versionId,
    );
    if (version == null) {
      throw LabLearnerCatalogueException(
        'Q12 cannot catalogue an unpublished LAB version: ' +
            manifestEntry.identityKey +
            '.',
      );
    }

    final package = LabPackage.decode(version.publishedJson);
    if (package.metadata.lifecycle != LabLifecycleStatus.published ||
        package.metadata.id != manifestEntry.labId ||
        package.metadata.versionId != manifestEntry.versionId) {
      throw LabLearnerCatalogueException(
        'Q12 published LAB identity or lifecycle is invalid for ' +
            manifestEntry.identityKey +
            '.',
      );
    }

    final authority = expectedValidationAuthority.trim();
    if (authority.isEmpty ||
        version.validationAuthority != authority ||
        version.reviewerId != authority) {
      throw LabLearnerCatalogueException(
        'Q12 requires Q11 automated publication authority for ' +
            manifestEntry.identityKey +
            '.',
      );
    }

    final dqgSource = version.qualityEvidenceJson;
    final l4lSource = version.exhaustiveRouteEvidenceJson;
    final l4nSource = version.publishEvidenceJson;
    final fingerprint = version.snapshotFingerprint;
    if (dqgSource == null ||
        l4lSource == null ||
        l4nSource == null ||
        fingerprint == null ||
        !LabSnapshotFingerprint.matches(
          publishedJson: version.publishedJson,
          fingerprint: fingerprint,
        )) {
      throw LabLearnerCatalogueException(
        'Q12 requires a complete immutable publication certificate chain for ' +
            manifestEntry.identityKey +
            '.',
      );
    }

    final dqg = LabDqg300EvidenceCertificate.decode(dqgSource);
    final l4l = LabL4lEvidenceCertificate.decode(l4lSource);
    final l4n = LabL4nPublishEvidenceCertificate.decode(l4nSource);

    bool pinned(String labId, String versionId, String certAuthority) =>
        labId == manifestEntry.labId &&
        versionId == manifestEntry.versionId &&
        certAuthority == authority;

    if (!pinned(dqg.labId, dqg.versionId, dqg.validationAuthority) ||
        !pinned(l4l.labId, l4l.versionId, l4l.validationAuthority) ||
        !pinned(l4n.labId, l4n.versionId, l4n.validationAuthority) ||
        !dqg.isPass ||
        !l4l.isPass ||
        !l4n.isPass ||
        dqg.validatedAtIso != l4l.validatedAtIso ||
        dqg.validatedAtIso != l4n.validatedAtIso) {
      throw LabLearnerCatalogueException(
        'Q12 publication certificates are not valid for ' +
            manifestEntry.identityKey +
            '.',
      );
    }

    final decisionCertificates = <String, LabDqg300DecisionCertificate>{
      for (final item in dqg.decisions) item.nodeId: item,
    };
    final decisions = package.nodes.whereType<LabDecisionNode>().toList();
    if (decisionCertificates.length != decisions.length ||
        decisions.any((node) {
          final certificate = decisionCertificates[node.id];
          return certificate == null ||
              certificate.decisionSignature !=
                  LabDqg300Validator.decisionSignature(node);
        })) {
      throw LabLearnerCatalogueException(
        'Q12 DQG300 certificates do not match the published Decisions for ' +
            manifestEntry.identityKey +
            '.',
      );
    }

    if (l4n.routeExplorationEvidence['exhaustiveProofFingerprint'] !=
        l4l.routeEvidence['fingerprint']) {
      throw LabLearnerCatalogueException(
        'Q12 route evidence is not bound to the published exhaustive proof for ' +
            manifestEntry.identityKey +
            '.',
      );
    }

    return _VerifiedPublishedLab(version: version, package: package);
  }
}

class LabLearnerControlledDelivery {
  const LabLearnerControlledDelivery({
    required this.catalogueEntry,
    required this.package,
  });

  final LabLearnerCatalogueEntry catalogueEntry;
  final LabPackage package;

  LabLearnerPresentationPackage get presentation => catalogueEntry.presentation;
}

class LabLearnerControlledDeliveryService {
  const LabLearnerControlledDeliveryService({
    required this.publishedRepository,
    required this.catalogueRepository,
    this.presentationValidator = const LabLearnerPresentationValidator(),
  });

  final LabPublishedRepository publishedRepository;
  final LabLearnerCatalogueRepository catalogueRepository;
  final LabLearnerPresentationValidator presentationValidator;

  Future<List<LabLearnerCatalogueEntry>> listAvailable() =>
      catalogueRepository.listAvailable();

  Future<LabLearnerControlledDelivery> load({
    required String labId,
    required String versionId,
  }) async {
    final catalogueEntry = await catalogueRepository.load(labId, versionId);
    if (catalogueEntry == null) {
      throw const LabLearnerCatalogueException(
        'Learner LAB is not admitted to the catalogue.',
      );
    }

    final package = await LabLearnerPackageLoader(
      repository: publishedRepository,
    ).loadPublished(labId: labId, versionId: versionId);

    final presentationReport = presentationValidator.validate(
      technicalPackage: package,
      presentationPackage: catalogueEntry.presentation,
    );
    if (!presentationReport.isValid) {
      throw const LabLearnerCatalogueException(
        'Learner LAB presentation no longer matches the published package.',
      );
    }

    if (package.metadata.title != catalogueEntry.title ||
        package.nodes.whereType<LabDecisionNode>().length !=
            catalogueEntry.decisionCount ||
        !package.metadata.supportedModes.containsAll(
          catalogueEntry.supportedModes,
        )) {
      throw const LabLearnerCatalogueException(
        'Learner catalogue metadata drifted from the published LAB.',
      );
    }

    return LabLearnerControlledDelivery(
      catalogueEntry: catalogueEntry,
      package: package,
    );
  }
}

class _VerifiedPublishedLab {
  const _VerifiedPublishedLab({required this.version, required this.package});

  final LabPublishedVersion version;
  final LabPackage package;
}
