import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'lab_contracts.dart';
import 'lab_learner_catalogue.dart';
import 'lab_production_population_seed.dart';
import 'lab_scenario_population_manifest.dart';
import 'lab_snapshot_fingerprint.dart';
import 'lab_studio.dart';

const String kLspQ14ClosedSha =
    '5beee3db89a43267a4cc5b2956b117a344afe648';
const String kLspQ14ClosureValidationRunId = '35918656487';
const String kLabProductionManifestFingerprintSchema =
    'csp11.lab.population_manifest.sha256.v1';
const String kLabProductionReleaseFingerprintSchema =
    'csp11.lab.production_release.sha256.v1';

class LabProductionReleaseClosureException implements Exception {
  const LabProductionReleaseClosureException(this.message);

  final String message;

  @override
  String toString() => 'LabProductionReleaseClosureException: ' + message;
}

bool _isSha256Fingerprint(String value, String schema) {
  final prefix = schema + ':';
  if (!value.startsWith(prefix)) return false;
  final digest = value.substring(prefix.length);
  return RegExp(r'^[0-9a-f]{64}$').hasMatch(digest);
}

class LabProductionReleaseEntryEvidence {
  LabProductionReleaseEntryEvidence({
    required this.entryId,
    required this.labId,
    required this.versionId,
    required this.snapshotFingerprint,
    required this.publishedAtIso,
    required this.decisionCount,
  }) {
    LabIds.requireCanonical(entryId, 'Q15 release entry ID');
    LabIds.requireCanonical(labId, 'Q15 release LAB ID');
    LabIds.requireCanonical(versionId, 'Q15 release version ID');

    if (!_isSha256Fingerprint(
          snapshotFingerprint,
          LabSnapshotFingerprint.schema,
        ) ||
        DateTime.tryParse(publishedAtIso) == null ||
        decisionCount <= 0) {
      throw const LabProductionReleaseClosureException(
        'Q15 release entry evidence is incomplete or invalid.',
      );
    }
  }

  factory LabProductionReleaseEntryEvidence.fromJson(
    Map<String, Object?> json,
  ) {
    final decisionCount = json['decisionCount'];
    if (decisionCount is! int) {
      throw const LabProductionReleaseClosureException(
        'Q15 release entry decisionCount must be an integer.',
      );
    }

    return LabProductionReleaseEntryEvidence(
      entryId: json['entryId']?.toString() ?? '',
      labId: json['labId']?.toString() ?? '',
      versionId: json['versionId']?.toString() ?? '',
      snapshotFingerprint: json['snapshotFingerprint']?.toString() ?? '',
      publishedAtIso: json['publishedAtIso']?.toString() ?? '',
      decisionCount: decisionCount,
    );
  }

  final String entryId;
  final String labId;
  final String versionId;
  final String snapshotFingerprint;
  final String publishedAtIso;
  final int decisionCount;

  String get identityKey => labId + '@' + versionId;

  Map<String, Object?> toJson() => <String, Object?>{
    'entryId': entryId,
    'labId': labId,
    'versionId': versionId,
    'snapshotFingerprint': snapshotFingerprint,
    'publishedAtIso': publishedAtIso,
    'decisionCount': decisionCount,
  };
}

class LabProductionReleaseEvidence {
  LabProductionReleaseEvidence._({
    required this.releaseId,
    required this.manifestId,
    required this.manifestFingerprint,
    required this.q14ClosureSha,
    required this.q14ValidationRunId,
    required this.environmentId,
    required this.executedBy,
    required this.executedAtIso,
    required this.labCount,
    required this.totalDecisionCount,
    required Iterable<String> catalogueIdentityKeys,
    required Iterable<LabProductionReleaseEntryEvidence> entries,
    required this.evidenceFingerprint,
  }) : catalogueIdentityKeys = List<String>.unmodifiable(
         catalogueIdentityKeys.toList()..sort(),
       ),
       entries = List<LabProductionReleaseEntryEvidence>.unmodifiable(
         entries.toList()
           ..sort((left, right) => left.identityKey.compareTo(right.identityKey)),
       ) {
    LabIds.requireCanonical(releaseId, 'Q15 production release ID');
    LabIds.requireCanonical(manifestId, 'Q15 production manifest ID');

    if (q14ClosureSha != kLspQ14ClosedSha ||
        q14ValidationRunId != kLspQ14ClosureValidationRunId) {
      throw const LabProductionReleaseClosureException(
        'Q15 closure evidence must be pinned to the frozen Q14 closure.',
      );
    }

    if (!_isSha256Fingerprint(
          manifestFingerprint,
          kLabProductionManifestFingerprintSchema,
        ) ||
        environmentId.trim().isEmpty ||
        executedBy.trim().isEmpty ||
        DateTime.tryParse(executedAtIso) == null ||
        labCount <= 0 ||
        totalDecisionCount <= 0 ||
        this.entries.length != labCount ||
        this.catalogueIdentityKeys.length != labCount ||
        this.entries.map((item) => item.identityKey).toSet().length !=
            labCount ||
        this.catalogueIdentityKeys.toSet().length != labCount ||
        this.entries.fold<int>(
              0,
              (total, item) => total + item.decisionCount,
            ) !=
            totalDecisionCount ||
        !this
            .entries
            .map((item) => item.identityKey)
            .toSet()
            .containsAll(this.catalogueIdentityKeys) ||
        !this
            .catalogueIdentityKeys
            .toSet()
            .containsAll(this.entries.map((item) => item.identityKey))) {
      throw const LabProductionReleaseClosureException(
        'Q15 closure evidence does not form a complete release set.',
      );
    }

    final expected = _computeFingerprint(
      releaseId: releaseId,
      manifestId: manifestId,
      manifestFingerprint: manifestFingerprint,
      q14ClosureSha: q14ClosureSha,
      q14ValidationRunId: q14ValidationRunId,
      environmentId: environmentId,
      executedBy: executedBy,
      executedAtIso: executedAtIso,
      labCount: labCount,
      totalDecisionCount: totalDecisionCount,
      catalogueIdentityKeys: this.catalogueIdentityKeys,
      entries: this.entries,
    );
    if (evidenceFingerprint != expected) {
      throw const LabProductionReleaseClosureException(
        'Q15 production release evidence fingerprint mismatch.',
      );
    }
  }

  factory LabProductionReleaseEvidence.issue({
    required String releaseId,
    required String manifestId,
    required String manifestFingerprint,
    required String environmentId,
    required String executedBy,
    required DateTime executedAt,
    required Iterable<String> catalogueIdentityKeys,
    required Iterable<LabProductionReleaseEntryEvidence> entries,
  }) {
    final normalizedEntries = entries.toList()
      ..sort((left, right) => left.identityKey.compareTo(right.identityKey));
    final normalizedKeys = catalogueIdentityKeys.toList()..sort();
    final executedAtIso = executedAt.toUtc().toIso8601String();
    final totalDecisionCount = normalizedEntries.fold<int>(
      0,
      (total, item) => total + item.decisionCount,
    );

    final fingerprint = _computeFingerprint(
      releaseId: releaseId,
      manifestId: manifestId,
      manifestFingerprint: manifestFingerprint,
      q14ClosureSha: kLspQ14ClosedSha,
      q14ValidationRunId: kLspQ14ClosureValidationRunId,
      environmentId: environmentId.trim(),
      executedBy: executedBy.trim(),
      executedAtIso: executedAtIso,
      labCount: normalizedEntries.length,
      totalDecisionCount: totalDecisionCount,
      catalogueIdentityKeys: normalizedKeys,
      entries: normalizedEntries,
    );

    return LabProductionReleaseEvidence._(
      releaseId: releaseId,
      manifestId: manifestId,
      manifestFingerprint: manifestFingerprint,
      q14ClosureSha: kLspQ14ClosedSha,
      q14ValidationRunId: kLspQ14ClosureValidationRunId,
      environmentId: environmentId.trim(),
      executedBy: executedBy.trim(),
      executedAtIso: executedAtIso,
      labCount: normalizedEntries.length,
      totalDecisionCount: totalDecisionCount,
      catalogueIdentityKeys: normalizedKeys,
      entries: normalizedEntries,
      evidenceFingerprint: fingerprint,
    );
  }

  factory LabProductionReleaseEvidence.fromJson(Map<String, Object?> json) {
    final rawKeys = json['catalogueIdentityKeys'];
    final rawEntries = json['entries'];
    final labCount = json['labCount'];
    final totalDecisionCount = json['totalDecisionCount'];

    if (rawKeys is! Iterable ||
        rawEntries is! Iterable ||
        labCount is! int ||
        totalDecisionCount is! int) {
      throw const LabProductionReleaseClosureException(
        'Q15 production release evidence has invalid field types.',
      );
    }

    return LabProductionReleaseEvidence._(
      releaseId: json['releaseId']?.toString() ?? '',
      manifestId: json['manifestId']?.toString() ?? '',
      manifestFingerprint: json['manifestFingerprint']?.toString() ?? '',
      q14ClosureSha: json['q14ClosureSha']?.toString() ?? '',
      q14ValidationRunId: json['q14ValidationRunId']?.toString() ?? '',
      environmentId: json['environmentId']?.toString() ?? '',
      executedBy: json['executedBy']?.toString() ?? '',
      executedAtIso: json['executedAtIso']?.toString() ?? '',
      labCount: labCount,
      totalDecisionCount: totalDecisionCount,
      catalogueIdentityKeys: rawKeys.map((item) => item.toString()),
      entries: rawEntries.map((item) {
        if (item is! Map) {
          throw const LabProductionReleaseClosureException(
            'Q15 production release entry must be an object.',
          );
        }
        return LabProductionReleaseEntryEvidence.fromJson(
          item.cast<String, Object?>(),
        );
      }),
      evidenceFingerprint: json['evidenceFingerprint']?.toString() ?? '',
    );
  }

  static const String schemaVersion = 'csp11.lab.production_release.v1';

  final String releaseId;
  final String manifestId;
  final String manifestFingerprint;
  final String q14ClosureSha;
  final String q14ValidationRunId;
  final String environmentId;
  final String executedBy;
  final String executedAtIso;
  final int labCount;
  final int totalDecisionCount;
  final List<String> catalogueIdentityKeys;
  final List<LabProductionReleaseEntryEvidence> entries;
  final String evidenceFingerprint;

  Map<String, Object?> toJson() => <String, Object?>{
    'schemaVersion': schemaVersion,
    'releaseId': releaseId,
    'manifestId': manifestId,
    'manifestFingerprint': manifestFingerprint,
    'q14ClosureSha': q14ClosureSha,
    'q14ValidationRunId': q14ValidationRunId,
    'environmentId': environmentId,
    'executedBy': executedBy,
    'executedAtIso': executedAtIso,
    'labCount': labCount,
    'totalDecisionCount': totalDecisionCount,
    'catalogueIdentityKeys': catalogueIdentityKeys,
    'entries': entries.map((item) => item.toJson()).toList(growable: false),
    'evidenceFingerprint': evidenceFingerprint,
  };

  String encode() => jsonEncode(toJson());

  static LabProductionReleaseEvidence decode(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw const LabProductionReleaseClosureException(
        'Q15 production release evidence root must be an object.',
      );
    }
    return LabProductionReleaseEvidence.fromJson(
      decoded.cast<String, Object?>(),
    );
  }

  static String _computeFingerprint({
    required String releaseId,
    required String manifestId,
    required String manifestFingerprint,
    required String q14ClosureSha,
    required String q14ValidationRunId,
    required String environmentId,
    required String executedBy,
    required String executedAtIso,
    required int labCount,
    required int totalDecisionCount,
    required Iterable<String> catalogueIdentityKeys,
    required Iterable<LabProductionReleaseEntryEvidence> entries,
  }) {
    final keys = catalogueIdentityKeys.toList()..sort();
    final sortedEntries = entries.toList()
      ..sort((left, right) => left.identityKey.compareTo(right.identityKey));

    final payload = <String, Object?>{
      'schemaVersion': schemaVersion,
      'releaseId': releaseId,
      'manifestId': manifestId,
      'manifestFingerprint': manifestFingerprint,
      'q14ClosureSha': q14ClosureSha,
      'q14ValidationRunId': q14ValidationRunId,
      'environmentId': environmentId,
      'executedBy': executedBy,
      'executedAtIso': executedAtIso,
      'labCount': labCount,
      'totalDecisionCount': totalDecisionCount,
      'catalogueIdentityKeys': keys,
      'entries': sortedEntries
          .map((item) => item.toJson())
          .toList(growable: false),
    };
    final digest = sha256.convert(utf8.encode(jsonEncode(payload)));
    return kLabProductionReleaseFingerprintSchema + ':' + digest.toString();
  }
}

abstract class LabProductionReleaseEvidenceRepository {
  Future<void> saveImmutable(LabProductionReleaseEvidence evidence);

  Future<LabProductionReleaseEvidence?> load(String releaseId);
}

class InMemoryLabProductionReleaseEvidenceRepository
    implements LabProductionReleaseEvidenceRepository {
  final Map<String, LabProductionReleaseEvidence> _evidence =
      <String, LabProductionReleaseEvidence>{};

  @override
  Future<void> saveImmutable(LabProductionReleaseEvidence evidence) async {
    if (_evidence.containsKey(evidence.releaseId)) {
      throw const LabProductionReleaseClosureException(
        'Q15 production release evidence is immutable and already exists.',
      );
    }
    _evidence[evidence.releaseId] = evidence;
  }

  @override
  Future<LabProductionReleaseEvidence?> load(String releaseId) async =>
      _evidence[releaseId];
}

class LabProductionReleaseClosureService {
  const LabProductionReleaseClosureService({
    required this.publishedRepository,
    required this.catalogueRepository,
    required this.evidenceRepository,
  });

  final LabPublishedRepository publishedRepository;
  final LabLearnerCatalogueRepository catalogueRepository;
  final LabProductionReleaseEvidenceRepository evidenceRepository;

  static String releaseIdFor(LabScenarioPopulationManifest manifest) =>
      manifest.manifestId + '_q15_release_v1';

  static String manifestFingerprintFor(
    LabScenarioPopulationManifest manifest,
  ) {
    final entries = manifest.entries
        .map(
          (entry) => <String, Object?>{
            'entryId': entry.entryId,
            'labId': entry.labId,
            'versionId': entry.versionId,
            'technicalLabPath': entry.technicalLabPath,
            'dqg300EvidencePath': entry.dqg300EvidencePath,
            'learnerPresentationPath': entry.learnerPresentationPath,
          },
        )
        .toList()
      ..sort(
        (left, right) =>
            left['entryId'].toString().compareTo(right['entryId'].toString()),
      );

    final payload = <String, Object?>{
      'schemaVersion': manifest.schemaVersion,
      'manifestId': manifest.manifestId,
      'entries': entries,
    };
    final digest = sha256.convert(utf8.encode(jsonEncode(payload)));
    return kLabProductionManifestFingerprintSchema + ':' + digest.toString();
  }

  Future<LabProductionReleaseEvidence> closeRelease({
    required LabScenarioPopulationManifest manifest,
    required String environmentId,
    required String executedBy,
    DateTime? executedAt,
  }) async {
    final releaseId = releaseIdFor(manifest);
    if (await evidenceRepository.load(releaseId) != null) {
      throw const LabProductionReleaseClosureException(
        'Q15 production release is already closed.',
      );
    }

    final q14Verification = await LabProductionPopulationSeedService(
      publishedRepository: publishedRepository,
      catalogueRepository: catalogueRepository,
    ).verifyRelease(manifest: manifest);

    final entries = await _collectEntryEvidence(manifest);
    if (q14Verification.totalDecisionCount !=
            entries.fold<int>(
              0,
              (total, item) => total + item.decisionCount,
            ) ||
        q14Verification.catalogueIdentityKeys.length != entries.length) {
      throw const LabProductionReleaseClosureException(
        'Q15 live release reconstruction does not match Q14 verification.',
      );
    }

    final evidence = LabProductionReleaseEvidence.issue(
      releaseId: releaseId,
      manifestId: manifest.manifestId,
      manifestFingerprint: manifestFingerprintFor(manifest),
      environmentId: environmentId,
      executedBy: executedBy,
      executedAt: executedAt ?? DateTime.now().toUtc(),
      catalogueIdentityKeys: q14Verification.catalogueIdentityKeys,
      entries: entries,
    );

    await evidenceRepository.saveImmutable(evidence);
    return verifyClosedRelease(manifest: manifest);
  }

  Future<LabProductionReleaseEvidence> verifyClosedRelease({
    required LabScenarioPopulationManifest manifest,
  }) async {
    final releaseId = releaseIdFor(manifest);
    final evidence = await evidenceRepository.load(releaseId);
    if (evidence == null) {
      throw const LabProductionReleaseClosureException(
        'Q15 production release closure evidence does not exist.',
      );
    }

    if (evidence.releaseId != releaseId ||
        evidence.manifestId != manifest.manifestId ||
        evidence.manifestFingerprint != manifestFingerprintFor(manifest) ||
        evidence.q14ClosureSha != kLspQ14ClosedSha ||
        evidence.q14ValidationRunId != kLspQ14ClosureValidationRunId) {
      throw const LabProductionReleaseClosureException(
        'Q15 production release closure is not bound to the frozen release.',
      );
    }

    final q14Verification = await LabProductionPopulationSeedService(
      publishedRepository: publishedRepository,
      catalogueRepository: catalogueRepository,
    ).verifyRelease(manifest: manifest);
    final currentEntries = await _collectEntryEvidence(manifest);

    if (evidence.labCount != manifest.entries.length ||
        evidence.totalDecisionCount != q14Verification.totalDecisionCount ||
        evidence.catalogueIdentityKeys.join('|') !=
            q14Verification.catalogueIdentityKeys.join('|') ||
        jsonEncode(evidence.entries.map((item) => item.toJson()).toList()) !=
            jsonEncode(currentEntries.map((item) => item.toJson()).toList())) {
      throw const LabProductionReleaseClosureException(
        'Q15 persisted closure evidence no longer matches the live release.',
      );
    }

    return evidence;
  }

  Future<List<LabProductionReleaseEntryEvidence>> _collectEntryEvidence(
    LabScenarioPopulationManifest manifest,
  ) async {
    final entries = <LabProductionReleaseEntryEvidence>[];

    for (final manifestEntry in manifest.entries) {
      final version = await publishedRepository.load(
        manifestEntry.labId,
        manifestEntry.versionId,
      );
      final catalogueEntry = await catalogueRepository.load(
        manifestEntry.labId,
        manifestEntry.versionId,
      );
      final snapshotFingerprint = version?.snapshotFingerprint;

      if (version == null ||
          catalogueEntry == null ||
          snapshotFingerprint == null ||
          version.validationAuthority != 'LSP-Q11-POPULATION-AUTO' ||
          version.reviewerId != 'LSP-Q11-POPULATION-AUTO' ||
          !LabSnapshotFingerprint.matches(
            publishedJson: version.publishedJson,
            fingerprint: snapshotFingerprint,
          ) ||
          catalogueEntry.manifestEntryId != manifestEntry.entryId) {
        throw LabProductionReleaseClosureException(
          'Q15 cannot certify release identity ' +
              manifestEntry.identityKey +
              '.',
        );
      }

      final package = LabPackage.decode(version.publishedJson);
      final decisionCount = package.nodes.whereType<LabDecisionNode>().length;
      if (package.metadata.lifecycle != LabLifecycleStatus.published ||
          package.metadata.id != manifestEntry.labId ||
          package.metadata.versionId != manifestEntry.versionId ||
          decisionCount != catalogueEntry.decisionCount) {
        throw LabProductionReleaseClosureException(
          'Q15 live release metadata drifted for ' +
              manifestEntry.identityKey +
              '.',
        );
      }

      entries.add(
        LabProductionReleaseEntryEvidence(
          entryId: manifestEntry.entryId,
          labId: manifestEntry.labId,
          versionId: manifestEntry.versionId,
          snapshotFingerprint: snapshotFingerprint,
          publishedAtIso: version.publishedAt.toUtc().toIso8601String(),
          decisionCount: decisionCount,
        ),
      );
    }

    entries.sort(
      (left, right) => left.identityKey.compareTo(right.identityKey),
    );
    return List<LabProductionReleaseEntryEvidence>.unmodifiable(entries);
  }
}

class LabProductionReleaseExecutionService {
  const LabProductionReleaseExecutionService({
    required this.seedService,
    required this.closureService,
  });

  final LabProductionPopulationSeedService seedService;
  final LabProductionReleaseClosureService closureService;

  Future<LabProductionReleaseEvidence> executeInitialRelease({
    required LabScenarioPopulationManifest manifest,
    required Iterable<LabProductionPopulationSeedCandidate> candidates,
    required String environmentId,
    required String executedBy,
    DateTime? validatedAt,
    DateTime? publishedAt,
    DateTime? executedAt,
  }) async {
    await seedService.seedAndVerify(
      manifest: manifest,
      candidates: candidates,
      validatedAt: validatedAt,
      publishedAt: publishedAt,
    );

    return closureService.closeRelease(
      manifest: manifest,
      environmentId: environmentId,
      executedBy: executedBy,
      executedAt: executedAt,
    );
  }
}
