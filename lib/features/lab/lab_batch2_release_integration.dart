import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';

import 'lab_contracts.dart';
import 'lab_dqg300_evidence_store.dart';
import 'lab_firestore_repositories.dart';
import 'lab_learner_catalogue.dart';
import 'lab_learner_presentation.dart';
import 'lab_production_deployment_acceptance.dart';
import 'lab_production_population_seed.dart';
import 'lab_production_release_closure.dart';
import 'lab_scenario_population_manifest.dart';
import 'lab_scenario_population_publication.dart';
import 'lab_studio.dart';

const String kBatch2ManifestAsset = 'content/lab_population_batch2/manifest.json';
const String kBatch2PreCatalogueClosedSha =
    '8a3ee7a5e27ec4b63793dddbb3982e3f0f42c429';
const String kBatch2PreCatalogueValidationRunId = '36015831093';
const String kBatch2ReleaseId = kLearnerVisibleLabReleaseId;
const String kBatch2ReleaseConfirmationPhrase = 'RELEASE BATCH 2 LABS';
const String kBatch2CloseConfirmationPhrase = 'CLOSE BATCH 2 RELEASE';
const String kBatch2AcceptanceConfirmationPhrase =
    'ACCEPT BATCH 2 LIVE RELEASE';
const String kBatch2StagingSchemaVersion =
    'csp11.lab.production_catalogue_staging.v1';
const String kBatch2EvidenceSchemaVersion =
    'csp11.lab.production_extension_release.v1';
const String kBatch2EvidenceFingerprintSchema =
    'csp11.lab.production_extension_release.sha256.v1';
const String kBatch2AcceptanceSchemaVersion =
    'csp11.lab.production_extension_acceptance.v1';
const String kBatch2AcceptanceFingerprintSchema =
    'csp11.lab.production_extension_acceptance.sha256.v1';

class LabBatch2ReleaseException implements Exception {
  const LabBatch2ReleaseException(this.message);

  final String message;

  @override
  String toString() => 'LabBatch2ReleaseException: ' + message;
}

bool _batch2Sha256(String value, String schema) {
  final prefix = schema + ':';
  if (!value.startsWith(prefix)) return false;
  return RegExp(r'^[0-9a-f]{64}$').hasMatch(value.substring(prefix.length));
}

String _batch2Hash(String schema, Map<String, Object?> payload) =>
    schema + ':' + sha256.convert(utf8.encode(jsonEncode(payload))).toString();

class BundledLabBatch2PopulationSource implements LabProductionPopulationSource {
  const BundledLabBatch2PopulationSource({required this.bundle});

  final AssetBundle bundle;

  Future<Map<String, Object?>> _readObject(String path) async {
    final decoded = jsonDecode(await bundle.loadString(path));
    if (decoded is! Map) {
      throw LabBatch2ReleaseException(
        'Batch 2 expected a JSON object at ' + path + '.',
      );
    }
    return decoded.cast<String, Object?>();
  }

  @override
  Future<LabScenarioPopulationManifest> loadManifest() async =>
      LabScenarioPopulationManifest.fromJson(
        await _readObject(kBatch2ManifestAsset),
      );

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

class LabBatch2StagedCatalogueDocument {
  const LabBatch2StagedCatalogueDocument({
    required this.releaseId,
    required this.entry,
  });

  final String releaseId;
  final LabLearnerCatalogueEntry entry;

  String get identityKey => entry.identityKey;
}

abstract class LabBatch2CatalogueStagingRepository {
  Future<void> saveImmutable(LabBatch2StagedCatalogueDocument document);

  Future<LabBatch2StagedCatalogueDocument?> load(
    String releaseId,
    String labId,
    String versionId,
  );

  Future<List<LabBatch2StagedCatalogueDocument>> listForRelease(
    String releaseId,
  );
}

class InMemoryLabBatch2CatalogueStagingRepository
    implements LabBatch2CatalogueStagingRepository {
  final Map<String, LabBatch2StagedCatalogueDocument> _documents =
      <String, LabBatch2StagedCatalogueDocument>{};

  String _key(String releaseId, String labId, String versionId) =>
      releaseId + '::' + labId + '::' + versionId;

  @override
  Future<void> saveImmutable(LabBatch2StagedCatalogueDocument document) async {
    final key = _key(
      document.releaseId,
      document.entry.labId,
      document.entry.versionId,
    );
    if (_documents.containsKey(key)) {
      throw const LabBatch2ReleaseException(
        'Batch 2 staged catalogue entry is immutable and already exists.',
      );
    }
    _documents[key] = document;
  }

  @override
  Future<LabBatch2StagedCatalogueDocument?> load(
    String releaseId,
    String labId,
    String versionId,
  ) async => _documents[_key(releaseId, labId, versionId)];

  @override
  Future<List<LabBatch2StagedCatalogueDocument>> listForRelease(
    String releaseId,
  ) async =>
      List<LabBatch2StagedCatalogueDocument>.unmodifiable(
        _documents.values.where((item) => item.releaseId == releaseId),
      );
}

Map<String, Object?> _batch2EncodePresentation(
  LabLearnerPresentationPackage package,
) {
  final overview = package.presentation;
  return <String, Object?>{
    'schemaVersion': package.schemaVersion,
    'labId': package.labId,
    'versionId': package.versionId,
    'presentation': <String, Object?>{
      'summary': overview.summary,
      'estimatedTime': overview.estimatedTime,
      'decisionCountLabel': overview.decisionCountLabel,
      'role': overview.role,
      'situation': overview.situation,
      'objective': overview.objective,
      'peopleInvolved': overview.peopleInvolved,
      'knownFacts': overview.knownFacts,
      'focusTags': overview.focusTags,
    },
    'evidencePresentation': <String, Object?>{
      for (final item in package.evidencePresentation.entries)
        item.key: <String, Object?>{
          'title': item.value.title,
          'summary': item.value.summary,
          'details': item.value.details,
        },
    },
    'decisionPresentation': <String, Object?>{
      for (final item in package.decisionPresentation.entries)
        item.key: <String, Object?>{'title': item.value.title},
    },
    'consequencePresentation': <String, Object?>{
      for (final item in package.consequencePresentation.entries)
        item.key: <String, Object?>{
          'observable': item.value.observable,
          'guidedInsight': item.value.guidedInsight,
        },
    },
    'endingPresentation': <String, Object?>{
      for (final item in package.endingPresentation.entries)
        item.key: <String, Object?>{
          'title': item.value.title,
          'narrative': item.value.narrative,
          'keyTurningPoint': item.value.keyTurningPoint,
        },
    },
  };
}

Map<String, Object?> _batch2CatalogueFields(
  LabLearnerCatalogueEntry entry, {
  required String releaseId,
}) => <String, Object?>{
  'releaseId': releaseId,
  'manifestEntryId': entry.manifestEntryId,
  'labId': entry.labId,
  'versionId': entry.versionId,
  'title': entry.title,
  'summary': entry.summary,
  'focusTags': entry.focusTags,
  'estimatedTime': entry.estimatedTime,
  'decisionCountLabel': entry.decisionCountLabel,
  'decisionCount': entry.decisionCount,
  'supportedModes': entry.supportedModes
      .map((mode) => mode.name.toUpperCase())
      .toList(growable: false),
  'presentation': _batch2EncodePresentation(entry.presentation),
};

LabLearnerCatalogueEntry _batch2DecodeCatalogue(
  Map<String, dynamic> data,
) {
  String text(String key) {
    final value = data[key]?.toString().trim() ?? '';
    if (value.isEmpty) {
      throw LabBatch2ReleaseException(
        'Batch 2 staged catalogue document requires ' + key + '.',
      );
    }
    return value;
  }

  final tags = data['focusTags'];
  final modes = data['supportedModes'];
  final presentation = data['presentation'];
  final decisionCount = data['decisionCount'];
  if (tags is! Iterable ||
      modes is! Iterable ||
      presentation is! Map ||
      decisionCount is! int) {
    throw const LabBatch2ReleaseException(
      'Batch 2 staged catalogue document has invalid field types.',
    );
  }

  return LabLearnerCatalogueEntry.persistence(
    manifestEntryId: text('manifestEntryId'),
    labId: text('labId'),
    versionId: text('versionId'),
    title: text('title'),
    summary: text('summary'),
    focusTags: tags.map((item) => item.toString()),
    estimatedTime: text('estimatedTime'),
    decisionCountLabel: text('decisionCountLabel'),
    decisionCount: decisionCount,
    supportedModes: modes.map(parseLabMode).toSet(),
    presentation: LabLearnerPresentationPackage.fromJson(
      presentation.cast<String, Object?>(),
    ),
  );
}

class FirestoreLabBatch2CatalogueStagingRepository
    implements LabBatch2CatalogueStagingRepository {
  FirestoreLabBatch2CatalogueStagingRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('labProductionCatalogueStaging');

  String _documentId(String releaseId, String labId, String versionId) =>
      releaseId + '__' + labId + '__' + versionId;

  @override
  Future<void> saveImmutable(LabBatch2StagedCatalogueDocument document) async {
    final reference = _collection.doc(
      _documentId(
        document.releaseId,
        document.entry.labId,
        document.entry.versionId,
      ),
    );
    await _firestore.runTransaction((transaction) async {
      final existing = await transaction.get(reference);
      if (existing.exists) {
        throw const LabBatch2ReleaseException(
          'Batch 2 staged catalogue entry is immutable and already exists.',
        );
      }
      transaction.set(reference, <String, dynamic>{
        'schemaVersion': kBatch2StagingSchemaVersion,
        ..._batch2CatalogueFields(
          document.entry,
          releaseId: document.releaseId,
        ),
        'serverCreatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Future<LabBatch2StagedCatalogueDocument?> load(
    String releaseId,
    String labId,
    String versionId,
  ) async {
    final snapshot = await _collection
        .doc(_documentId(releaseId, labId, versionId))
        .get();
    if (!snapshot.exists) return null;
    final data = snapshot.data();
    if (data == null ||
        data['schemaVersion'] != kBatch2StagingSchemaVersion ||
        data['releaseId'] != releaseId) {
      throw const LabBatch2ReleaseException(
        'Unsupported Batch 2 staged catalogue document.',
      );
    }
    return LabBatch2StagedCatalogueDocument(
      releaseId: releaseId,
      entry: _batch2DecodeCatalogue(data),
    );
  }

  @override
  Future<List<LabBatch2StagedCatalogueDocument>> listForRelease(
    String releaseId,
  ) async {
    final snapshot = await _collection
        .where('releaseId', isEqualTo: releaseId)
        .get();
    final documents = snapshot.docs.map((item) {
      final data = item.data();
      if (data['schemaVersion'] != kBatch2StagingSchemaVersion) {
        throw const LabBatch2ReleaseException(
          'Unsupported Batch 2 staged catalogue document.',
        );
      }
      return LabBatch2StagedCatalogueDocument(
        releaseId: releaseId,
        entry: _batch2DecodeCatalogue(data),
      );
    }).toList(growable: false);
    return List<LabBatch2StagedCatalogueDocument>.unmodifiable(documents);
  }
}

class LabBatch2ReleaseEvidence {
  LabBatch2ReleaseEvidence._({
    required this.releaseId,
    required this.manifestId,
    required this.manifestFingerprint,
    required this.preCatalogueClosedSha,
    required this.preCatalogueValidationRunId,
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
    if (releaseId != kBatch2ReleaseId ||
        preCatalogueClosedSha != kBatch2PreCatalogueClosedSha ||
        preCatalogueValidationRunId != kBatch2PreCatalogueValidationRunId ||
        environmentId != kExpectedLabProductionEnvironmentId ||
        !_batch2Sha256(
          manifestFingerprint,
          kLabProductionManifestFingerprintSchema,
        ) ||
        labCount != 10 ||
        totalDecisionCount != 50 ||
        this.entries.length != 10 ||
        this.catalogueIdentityKeys.length != 10 ||
        executedBy.trim().isEmpty ||
        DateTime.tryParse(executedAtIso) == null) {
      throw const LabBatch2ReleaseException(
        'Batch 2 Q16 release evidence is outside the frozen extension boundary.',
      );
    }

    final expected = _fingerprint(
      releaseId: releaseId,
      manifestId: manifestId,
      manifestFingerprint: manifestFingerprint,
      environmentId: environmentId,
      executedBy: executedBy,
      executedAtIso: executedAtIso,
      catalogueIdentityKeys: this.catalogueIdentityKeys,
      entries: this.entries,
    );
    if (expected != evidenceFingerprint) {
      throw const LabBatch2ReleaseException(
        'Batch 2 Q16 release evidence fingerprint mismatch.',
      );
    }
  }

  factory LabBatch2ReleaseEvidence.issue({
    required LabScenarioPopulationManifest manifest,
    required String environmentId,
    required String executedBy,
    required DateTime executedAt,
    required Iterable<String> catalogueIdentityKeys,
    required Iterable<LabProductionReleaseEntryEvidence> entries,
  }) {
    final sortedEntries = entries.toList()
      ..sort((left, right) => left.identityKey.compareTo(right.identityKey));
    final keys = catalogueIdentityKeys.toList()..sort();
    final executedAtIso = executedAt.toUtc().toIso8601String();
    final manifestFingerprint =
        LabProductionReleaseClosureService.manifestFingerprintFor(manifest);
    final evidenceFingerprint = _fingerprint(
      releaseId: kBatch2ReleaseId,
      manifestId: manifest.manifestId,
      manifestFingerprint: manifestFingerprint,
      environmentId: environmentId,
      executedBy: executedBy.trim(),
      executedAtIso: executedAtIso,
      catalogueIdentityKeys: keys,
      entries: sortedEntries,
    );
    return LabBatch2ReleaseEvidence._(
      releaseId: kBatch2ReleaseId,
      manifestId: manifest.manifestId,
      manifestFingerprint: manifestFingerprint,
      preCatalogueClosedSha: kBatch2PreCatalogueClosedSha,
      preCatalogueValidationRunId: kBatch2PreCatalogueValidationRunId,
      environmentId: environmentId,
      executedBy: executedBy.trim(),
      executedAtIso: executedAtIso,
      labCount: sortedEntries.length,
      totalDecisionCount: sortedEntries.fold<int>(
        0,
        (sum, item) => sum + item.decisionCount,
      ),
      catalogueIdentityKeys: keys,
      entries: sortedEntries,
      evidenceFingerprint: evidenceFingerprint,
    );
  }

  factory LabBatch2ReleaseEvidence.fromJson(Map<String, Object?> json) {
    final rawEntries = json['entries'];
    final rawKeys = json['catalogueIdentityKeys'];
    final labCount = json['labCount'];
    final totalDecisionCount = json['totalDecisionCount'];
    if (rawEntries is! Iterable ||
        rawKeys is! Iterable ||
        labCount is! int ||
        totalDecisionCount is! int) {
      throw const LabBatch2ReleaseException(
        'Batch 2 Q16 evidence has invalid field types.',
      );
    }
    return LabBatch2ReleaseEvidence._(
      releaseId: json['releaseId']?.toString() ?? '',
      manifestId: json['manifestId']?.toString() ?? '',
      manifestFingerprint: json['manifestFingerprint']?.toString() ?? '',
      preCatalogueClosedSha: json['preCatalogueClosedSha']?.toString() ?? '',
      preCatalogueValidationRunId:
          json['preCatalogueValidationRunId']?.toString() ?? '',
      environmentId: json['environmentId']?.toString() ?? '',
      executedBy: json['executedBy']?.toString() ?? '',
      executedAtIso: json['executedAtIso']?.toString() ?? '',
      labCount: labCount,
      totalDecisionCount: totalDecisionCount,
      catalogueIdentityKeys: rawKeys.map((item) => item.toString()),
      entries: rawEntries.map((item) {
        if (item is! Map) {
          throw const LabBatch2ReleaseException(
            'Batch 2 Q16 evidence entry must be an object.',
          );
        }
        return LabProductionReleaseEntryEvidence.fromJson(
          item.cast<String, Object?>(),
        );
      }),
      evidenceFingerprint: json['evidenceFingerprint']?.toString() ?? '',
    );
  }

  static String _fingerprint({
    required String releaseId,
    required String manifestId,
    required String manifestFingerprint,
    required String environmentId,
    required String executedBy,
    required String executedAtIso,
    required Iterable<String> catalogueIdentityKeys,
    required Iterable<LabProductionReleaseEntryEvidence> entries,
  }) {
    final keys = catalogueIdentityKeys.toList()..sort();
    final orderedEntries = entries.toList()
      ..sort((left, right) => left.identityKey.compareTo(right.identityKey));
    return _batch2Hash(kBatch2EvidenceFingerprintSchema, <String, Object?>{
      'schemaVersion': kBatch2EvidenceSchemaVersion,
      'releaseId': releaseId,
      'manifestId': manifestId,
      'manifestFingerprint': manifestFingerprint,
      'preCatalogueClosedSha': kBatch2PreCatalogueClosedSha,
      'preCatalogueValidationRunId': kBatch2PreCatalogueValidationRunId,
      'environmentId': environmentId,
      'executedBy': executedBy,
      'executedAtIso': executedAtIso,
      'labCount': orderedEntries.length,
      'totalDecisionCount': orderedEntries.fold<int>(
        0,
        (sum, item) => sum + item.decisionCount,
      ),
      'catalogueIdentityKeys': keys,
      'entries': orderedEntries.map((item) => item.toJson()).toList(),
    });
  }

  final String releaseId;
  final String manifestId;
  final String manifestFingerprint;
  final String preCatalogueClosedSha;
  final String preCatalogueValidationRunId;
  final String environmentId;
  final String executedBy;
  final String executedAtIso;
  final int labCount;
  final int totalDecisionCount;
  final List<String> catalogueIdentityKeys;
  final List<LabProductionReleaseEntryEvidence> entries;
  final String evidenceFingerprint;

  Map<String, Object?> toJson() => <String, Object?>{
    'schemaVersion': kBatch2EvidenceSchemaVersion,
    'releaseId': releaseId,
    'manifestId': manifestId,
    'manifestFingerprint': manifestFingerprint,
    'preCatalogueClosedSha': preCatalogueClosedSha,
    'preCatalogueValidationRunId': preCatalogueValidationRunId,
    'environmentId': environmentId,
    'executedBy': executedBy,
    'executedAtIso': executedAtIso,
    'labCount': labCount,
    'totalDecisionCount': totalDecisionCount,
    'catalogueIdentityKeys': catalogueIdentityKeys,
    'entries': entries.map((item) => item.toJson()).toList(growable: false),
    'evidenceFingerprint': evidenceFingerprint,
  };
}

abstract class LabBatch2ReleaseEvidenceRepository {
  Future<LabBatch2ReleaseEvidence?> load(String releaseId);

  Future<bool> isReleased(String releaseId);

  Future<void> saveImmutable(LabBatch2ReleaseEvidence evidence);
}

class InMemoryLabBatch2ReleaseEvidenceRepository
    implements LabBatch2ReleaseEvidenceRepository {
  final Map<String, LabBatch2ReleaseEvidence> _records =
      <String, LabBatch2ReleaseEvidence>{};

  @override
  Future<LabBatch2ReleaseEvidence?> load(String releaseId) async =>
      _records[releaseId];

  @override
  Future<bool> isReleased(String releaseId) async =>
      _records.containsKey(releaseId);

  @override
  Future<void> saveImmutable(LabBatch2ReleaseEvidence evidence) async {
    if (_records.containsKey(evidence.releaseId)) {
      throw const LabBatch2ReleaseException(
        'Batch 2 Q16 release evidence is immutable and already exists.',
      );
    }
    _records[evidence.releaseId] = evidence;
  }
}

class FirestoreLabBatch2ReleaseEvidenceRepository
    implements LabBatch2ReleaseEvidenceRepository {
  FirestoreLabBatch2ReleaseEvidenceRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _evidence =>
      _firestore.collection('labProductionReleaseExtensionEvidence');

  CollectionReference<Map<String, dynamic>> get _state =>
      _firestore.collection('labLearnerReleaseExtensionState');

  @override
  Future<LabBatch2ReleaseEvidence?> load(String releaseId) async {
    final snapshot = await _evidence.doc(releaseId).get();
    if (!snapshot.exists) return null;
    final data = snapshot.data();
    if (data == null || data['schemaVersion'] != kBatch2EvidenceSchemaVersion) {
      throw const LabBatch2ReleaseException(
        'Unsupported Batch 2 Q16 evidence document.',
      );
    }
    final payload = Map<String, Object?>.from(data)..remove('serverCreatedAt');
    return LabBatch2ReleaseEvidence.fromJson(payload);
  }

  @override
  Future<bool> isReleased(String releaseId) async {
    final snapshot = await _state.doc(releaseId).get();
    final data = snapshot.data();
    return snapshot.exists &&
        data != null &&
        data['schemaVersion'] ==
            'csp11.lab.production_extension_release_state.v1' &&
        data['releaseId'] == releaseId &&
        data['released'] == true;
  }

  @override
  Future<void> saveImmutable(LabBatch2ReleaseEvidence evidence) async {
    final evidenceRef = _evidence.doc(evidence.releaseId);
    final stateRef = _state.doc(evidence.releaseId);
    await _firestore.runTransaction((transaction) async {
      final existingEvidence = await transaction.get(evidenceRef);
      final existingState = await transaction.get(stateRef);
      if (existingEvidence.exists || existingState.exists) {
        throw const LabBatch2ReleaseException(
          'Batch 2 Q16 release evidence is immutable and already exists.',
        );
      }
      transaction.set(evidenceRef, <String, dynamic>{
        ...evidence.toJson(),
        'serverCreatedAt': FieldValue.serverTimestamp(),
      });
      transaction.set(stateRef, <String, dynamic>{
        'schemaVersion': 'csp11.lab.production_extension_release_state.v1',
        'releaseId': evidence.releaseId,
        'manifestId': evidence.manifestId,
        'released': true,
        'labCount': evidence.labCount,
        'totalDecisionCount': evidence.totalDecisionCount,
        'evidenceFingerprint': evidence.evidenceFingerprint,
        'serverCreatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}

enum LabBatch2ReleaseState { blocked, pristine, completeUnclosed, closed }

class LabBatch2ReleaseInspection {
  const LabBatch2ReleaseInspection({
    required this.state,
    required this.environmentId,
    required this.manifestId,
    required this.manifestFingerprint,
    required this.expectedLabCount,
    required this.publishedCount,
    required this.stagedCount,
    this.evidence,
    this.blockingReason,
  });

  final LabBatch2ReleaseState state;
  final String environmentId;
  final String manifestId;
  final String manifestFingerprint;
  final int expectedLabCount;
  final int publishedCount;
  final int stagedCount;
  final LabBatch2ReleaseEvidence? evidence;
  final String? blockingReason;

  bool get canRelease => state == LabBatch2ReleaseState.pristine;
  bool get canClose => state == LabBatch2ReleaseState.completeUnclosed;
  bool get isClosed => state == LabBatch2ReleaseState.closed;

  String get stateLabel {
    switch (state) {
      case LabBatch2ReleaseState.blocked:
        return 'BLOCKED';
      case LabBatch2ReleaseState.pristine:
        return 'PRISTINE';
      case LabBatch2ReleaseState.completeUnclosed:
        return 'COMPLETE_UNCLOSED';
      case LabBatch2ReleaseState.closed:
        return 'CLOSED';
    }
  }

  String? get requiredConfirmationPhrase {
    if (canRelease) return kBatch2ReleaseConfirmationPhrase;
    if (canClose) return kBatch2CloseConfirmationPhrase;
    return null;
  }
}

abstract class LabBatch2ReleaseOperator {
  Future<LabBatch2ReleaseInspection> inspect();

  Future<LabBatch2ReleaseEvidence> executeRelease({
    required String executedBy,
    required String confirmationPhrase,
    DateTime? executedAt,
  });

  Future<LabBatch2ReleaseEvidence> closeExisting({
    required String executedBy,
    required String confirmationPhrase,
    DateTime? executedAt,
  });
}

class LabBatch2ReleaseOperatorService implements LabBatch2ReleaseOperator {
  const LabBatch2ReleaseOperatorService({
    required this.populationSource,
    required this.publishedRepository,
    required this.stagingRepository,
    required this.evidenceRepository,
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
      publishedRepository: FirestoreLabPublishedRepository(
        firestore: instance,
      ),
      stagingRepository: FirestoreLabBatch2CatalogueStagingRepository(
        firestore: instance,
      ),
      evidenceRepository: FirestoreLabBatch2ReleaseEvidenceRepository(
        firestore: instance,
      ),
      environmentId:
          'firebase_project:' + instance.app.options.projectId.trim(),
    );
  }

  final LabProductionPopulationSource populationSource;
  final LabPublishedRepository publishedRepository;
  final LabBatch2CatalogueStagingRepository stagingRepository;
  final LabBatch2ReleaseEvidenceRepository evidenceRepository;
  final String environmentId;

  @override
  Future<LabBatch2ReleaseInspection> inspect() async {
    final manifest = await populationSource.loadManifest();
    final fingerprint =
        LabProductionReleaseClosureService.manifestFingerprintFor(manifest);
    var publishedCount = 0;
    var stagedCount = 0;

    LabBatch2ReleaseInspection blocked(String reason) =>
        LabBatch2ReleaseInspection(
          state: LabBatch2ReleaseState.blocked,
          environmentId: environmentId,
          manifestId: manifest.manifestId,
          manifestFingerprint: fingerprint,
          expectedLabCount: manifest.entries.length,
          publishedCount: publishedCount,
          stagedCount: stagedCount,
          blockingReason: reason,
        );

    try {
      if (environmentId != kExpectedLabProductionEnvironmentId) {
        return blocked(
          'Batch 2 Q16 is blocked outside the frozen production Firebase project.',
        );
      }

      for (final entry in manifest.entries) {
        if (await publishedRepository.load(entry.labId, entry.versionId) !=
            null) {
          publishedCount++;
        }
      }

      final staged = await stagingRepository.listForRelease(kBatch2ReleaseId);
      final stagedKeys = staged.map((item) => item.identityKey).toSet();
      final expectedKeys = manifest.entries
          .map((item) => item.identityKey)
          .toSet();
      stagedCount = stagedKeys.intersection(expectedKeys).length;

      final evidence = await evidenceRepository.load(kBatch2ReleaseId);
      final marker = await evidenceRepository.isReleased(kBatch2ReleaseId);
      if (evidence != null) {
        if (!marker ||
            evidence.manifestId != manifest.manifestId ||
            evidence.manifestFingerprint != fingerprint ||
            publishedCount != manifest.entries.length ||
            stagedCount != manifest.entries.length) {
          return blocked(
            'Batch 2 Q16 persisted evidence no longer matches the staged release.',
          );
        }
        return LabBatch2ReleaseInspection(
          state: LabBatch2ReleaseState.closed,
          environmentId: environmentId,
          manifestId: manifest.manifestId,
          manifestFingerprint: fingerprint,
          expectedLabCount: manifest.entries.length,
          publishedCount: publishedCount,
          stagedCount: stagedCount,
          evidence: evidence,
        );
      }
      if (marker) {
        return blocked(
          'Batch 2 release-state marker exists without immutable Q16 evidence.',
        );
      }

      if (publishedCount == 0 && stagedCount == 0) {
        return LabBatch2ReleaseInspection(
          state: LabBatch2ReleaseState.pristine,
          environmentId: environmentId,
          manifestId: manifest.manifestId,
          manifestFingerprint: fingerprint,
          expectedLabCount: manifest.entries.length,
          publishedCount: 0,
          stagedCount: 0,
        );
      }

      if (publishedCount == manifest.entries.length &&
          stagedCount == manifest.entries.length &&
          stagedKeys.length == manifest.entries.length &&
          stagedKeys.containsAll(expectedKeys)) {
        return LabBatch2ReleaseInspection(
          state: LabBatch2ReleaseState.completeUnclosed,
          environmentId: environmentId,
          manifestId: manifest.manifestId,
          manifestFingerprint: fingerprint,
          expectedLabCount: manifest.entries.length,
          publishedCount: publishedCount,
          stagedCount: stagedCount,
        );
      }

      return blocked(
        'Batch 2 production repositories contain a partial extension. Automatic repair is forbidden.',
      );
    } catch (error) {
      return blocked(error.toString());
    }
  }

  Future<List<LabBatch2StagedCatalogueDocument>> _preflight() async {
    final manifest = await populationSource.loadManifest();
    final candidates = await populationSource.loadCandidates(manifest);
    final byEntry = <String, LabProductionPopulationSeedCandidate>{
      for (final item in candidates) item.entryId: item,
    };
    if (byEntry.length != manifest.entries.length) {
      throw const LabBatch2ReleaseException(
        'Batch 2 candidate set does not exactly match its manifest.',
      );
    }

    final preflightPublished = InMemoryLabPublishedRepository();
    final preflightCatalogue = InMemoryLabLearnerCatalogueRepository();
    final publication = LabScenarioPopulationPublicationGate(
      studio: Lab1000StudioService(repository: preflightPublished),
    );
    final admission = LabLearnerCatalogueAdmissionService(
      publishedRepository: preflightPublished,
      catalogueRepository: preflightCatalogue,
    );
    final staged = <LabBatch2StagedCatalogueDocument>[];

    for (var index = 0; index < manifest.entries.length; index++) {
      final entry = manifest.entries[index];
      final candidate = byEntry[entry.entryId];
      if (candidate == null) {
        throw LabBatch2ReleaseException(
          'Missing Batch 2 candidate ' + entry.entryId + '.',
        );
      }
      final result = await publication.admit(
        manifest: manifest,
        entryId: entry.entryId,
        technicalRoot: candidate.technicalRoot,
        dqg300Evidence: candidate.dqg300Evidence,
        presentationPackage: candidate.presentationPackage,
        validatedAt: DateTime.utc(2026, 9, 25, 0, 0, index),
        publishedAt: DateTime.utc(2026, 9, 25, 0, 1, index),
      );
      if (!result.isAdmitted) {
        throw LabBatch2ReleaseException(
          'Batch 2 publication preflight failed for ' + entry.identityKey + '.',
        );
      }
      final catalogueEntry = await admission.admit(
        manifest: manifest,
        entryId: entry.entryId,
        presentation: candidate.presentationPackage,
      );
      staged.add(
        LabBatch2StagedCatalogueDocument(
          releaseId: kBatch2ReleaseId,
          entry: catalogueEntry,
        ),
      );
    }

    return List<LabBatch2StagedCatalogueDocument>.unmodifiable(staged);
  }

  Future<LabBatch2ReleaseEvidence> _close({
    required String executedBy,
    required DateTime executedAt,
  }) async {
    final manifest = await populationSource.loadManifest();
    final entries = <LabProductionReleaseEntryEvidence>[];
    final catalogueKeys = <String>[];
    for (final manifestEntry in manifest.entries) {
      final version = await publishedRepository.load(
        manifestEntry.labId,
        manifestEntry.versionId,
      );
      final staged = await stagingRepository.load(
        kBatch2ReleaseId,
        manifestEntry.labId,
        manifestEntry.versionId,
      );
      final fingerprint = version?.snapshotFingerprint;
      if (version == null ||
          staged == null ||
          fingerprint == null ||
          staged.entry.manifestEntryId != manifestEntry.entryId) {
        throw LabBatch2ReleaseException(
          'Batch 2 Q16 closure is incomplete for ' +
              manifestEntry.identityKey +
              '.',
        );
      }
      entries.add(
        LabProductionReleaseEntryEvidence(
          entryId: manifestEntry.entryId,
          labId: manifestEntry.labId,
          versionId: manifestEntry.versionId,
          snapshotFingerprint: fingerprint,
          publishedAtIso: version.publishedAt.toUtc().toIso8601String(),
          decisionCount: staged.entry.decisionCount,
        ),
      );
      catalogueKeys.add(manifestEntry.identityKey);
    }

    final evidence = LabBatch2ReleaseEvidence.issue(
      manifest: manifest,
      environmentId: environmentId,
      executedBy: executedBy,
      executedAt: executedAt,
      catalogueIdentityKeys: catalogueKeys,
      entries: entries,
    );
    await evidenceRepository.saveImmutable(evidence);

    final after = await inspect();
    if (!after.isClosed ||
        after.evidence?.evidenceFingerprint != evidence.evidenceFingerprint) {
      throw const LabBatch2ReleaseException(
        'Batch 2 Q16 evidence write did not produce a verified CLOSED state.',
      );
    }
    return after.evidence!;
  }

  @override
  Future<LabBatch2ReleaseEvidence> executeRelease({
    required String executedBy,
    required String confirmationPhrase,
    DateTime? executedAt,
  }) async {
    if (executedBy.trim().isEmpty ||
        confirmationPhrase != kBatch2ReleaseConfirmationPhrase) {
      throw const LabBatch2ReleaseException(
        'Batch 2 Q16 requires an admin actor and the exact release phrase.',
      );
    }
    final before = await inspect();
    if (!before.canRelease) {
      throw LabBatch2ReleaseException(
        'Batch 2 Q16 release is not permitted from ' +
            before.stateLabel +
            '.',
      );
    }

    final staged = await _preflight();
    final manifest = await populationSource.loadManifest();
    final preflightPublished = InMemoryLabPublishedRepository();
    final candidates = await populationSource.loadCandidates(manifest);
    final publication = LabScenarioPopulationPublicationGate(
      studio: Lab1000StudioService(repository: preflightPublished),
    );
    final byEntry = <String, LabProductionPopulationSeedCandidate>{
      for (final item in candidates) item.entryId: item,
    };

    for (var index = 0; index < manifest.entries.length; index++) {
      final entry = manifest.entries[index];
      final candidate = byEntry[entry.entryId]!;
      await publication.admit(
        manifest: manifest,
        entryId: entry.entryId,
        technicalRoot: candidate.technicalRoot,
        dqg300Evidence: candidate.dqg300Evidence,
        presentationPackage: candidate.presentationPackage,
        validatedAt: DateTime.utc(2026, 9, 25, 0, 0, index),
        publishedAt: DateTime.utc(2026, 9, 25, 0, 1, index),
      );
      final version = await preflightPublished.load(entry.labId, entry.versionId);
      if (version == null) {
        throw LabBatch2ReleaseException(
          'Batch 2 preflight did not produce ' + entry.identityKey + '.',
        );
      }
      await publishedRepository.saveImmutable(version);
      await stagingRepository.saveImmutable(staged[index]);
    }

    return _close(
      executedBy: executedBy.trim(),
      executedAt: executedAt ?? DateTime.now().toUtc(),
    );
  }

  @override
  Future<LabBatch2ReleaseEvidence> closeExisting({
    required String executedBy,
    required String confirmationPhrase,
    DateTime? executedAt,
  }) async {
    if (executedBy.trim().isEmpty ||
        confirmationPhrase != kBatch2CloseConfirmationPhrase) {
      throw const LabBatch2ReleaseException(
        'Batch 2 Q16 closure recovery requires the exact confirmation phrase.',
      );
    }
    final before = await inspect();
    if (!before.canClose) {
      throw LabBatch2ReleaseException(
        'Batch 2 Q16 closure is not permitted from ' + before.stateLabel + '.',
      );
    }
    return _close(
      executedBy: executedBy.trim(),
      executedAt: executedAt ?? DateTime.now().toUtc(),
    );
  }
}

class LabBatch2ReleaseAcceptance {
  LabBatch2ReleaseAcceptance._({
    required this.releaseId,
    required this.evidenceFingerprint,
    required this.environmentId,
    required this.labCount,
    required this.totalDecisionCount,
    required this.acceptedBy,
    required this.acceptedAtIso,
    required this.acceptanceFingerprint,
  }) {
    if (releaseId != kBatch2ReleaseId ||
        environmentId != kExpectedLabProductionEnvironmentId ||
        labCount != 10 ||
        totalDecisionCount != 50 ||
        !_batch2Sha256(
          evidenceFingerprint,
          kBatch2EvidenceFingerprintSchema,
        ) ||
        acceptedBy.trim().isEmpty ||
        DateTime.tryParse(acceptedAtIso) == null) {
      throw const LabBatch2ReleaseException(
        'Batch 2 Q17 acceptance is outside the frozen extension boundary.',
      );
    }

    final expected = _fingerprint(
      releaseId: releaseId,
      evidenceFingerprint: evidenceFingerprint,
      environmentId: environmentId,
      acceptedBy: acceptedBy,
      acceptedAtIso: acceptedAtIso,
    );
    if (expected != acceptanceFingerprint) {
      throw const LabBatch2ReleaseException(
        'Batch 2 Q17 acceptance fingerprint mismatch.',
      );
    }
  }

  factory LabBatch2ReleaseAcceptance.issue({
    required LabBatch2ReleaseEvidence evidence,
    required String acceptedBy,
    required DateTime acceptedAt,
  }) {
    final acceptedAtIso = acceptedAt.toUtc().toIso8601String();
    final fingerprint = _fingerprint(
      releaseId: evidence.releaseId,
      evidenceFingerprint: evidence.evidenceFingerprint,
      environmentId: evidence.environmentId,
      acceptedBy: acceptedBy.trim(),
      acceptedAtIso: acceptedAtIso,
    );
    return LabBatch2ReleaseAcceptance._(
      releaseId: evidence.releaseId,
      evidenceFingerprint: evidence.evidenceFingerprint,
      environmentId: evidence.environmentId,
      labCount: evidence.labCount,
      totalDecisionCount: evidence.totalDecisionCount,
      acceptedBy: acceptedBy.trim(),
      acceptedAtIso: acceptedAtIso,
      acceptanceFingerprint: fingerprint,
    );
  }

  factory LabBatch2ReleaseAcceptance.fromJson(Map<String, Object?> json) {
    final labCount = json['labCount'];
    final totalDecisionCount = json['totalDecisionCount'];
    if (labCount is! int || totalDecisionCount is! int) {
      throw const LabBatch2ReleaseException(
        'Batch 2 Q17 acceptance counts must be integers.',
      );
    }
    return LabBatch2ReleaseAcceptance._(
      releaseId: json['releaseId']?.toString() ?? '',
      evidenceFingerprint: json['evidenceFingerprint']?.toString() ?? '',
      environmentId: json['environmentId']?.toString() ?? '',
      labCount: labCount,
      totalDecisionCount: totalDecisionCount,
      acceptedBy: json['acceptedBy']?.toString() ?? '',
      acceptedAtIso: json['acceptedAtIso']?.toString() ?? '',
      acceptanceFingerprint: json['acceptanceFingerprint']?.toString() ?? '',
    );
  }

  static String _fingerprint({
    required String releaseId,
    required String evidenceFingerprint,
    required String environmentId,
    required String acceptedBy,
    required String acceptedAtIso,
  }) => _batch2Hash(kBatch2AcceptanceFingerprintSchema, <String, Object?>{
    'schemaVersion': kBatch2AcceptanceSchemaVersion,
    'releaseId': releaseId,
    'evidenceFingerprint': evidenceFingerprint,
    'environmentId': environmentId,
    'labCount': 10,
    'totalDecisionCount': 50,
    'acceptedBy': acceptedBy,
    'acceptedAtIso': acceptedAtIso,
  });

  final String releaseId;
  final String evidenceFingerprint;
  final String environmentId;
  final int labCount;
  final int totalDecisionCount;
  final String acceptedBy;
  final String acceptedAtIso;
  final String acceptanceFingerprint;

  Map<String, Object?> toJson() => <String, Object?>{
    'schemaVersion': kBatch2AcceptanceSchemaVersion,
    'releaseId': releaseId,
    'evidenceFingerprint': evidenceFingerprint,
    'environmentId': environmentId,
    'labCount': labCount,
    'totalDecisionCount': totalDecisionCount,
    'acceptedBy': acceptedBy,
    'acceptedAtIso': acceptedAtIso,
    'acceptanceFingerprint': acceptanceFingerprint,
  };
}

abstract class LabBatch2ReleaseAcceptanceRepository {
  Future<LabBatch2ReleaseAcceptance?> load(String releaseId);

  Future<void> saveAndActivate({
    required LabBatch2ReleaseAcceptance acceptance,
    required LabScenarioPopulationManifest manifest,
  });

  Future<int> activatedCount({
    required String releaseId,
    required LabScenarioPopulationManifest manifest,
  });
}

class InMemoryLabBatch2ReleaseAcceptanceRepository
    implements LabBatch2ReleaseAcceptanceRepository {
  InMemoryLabBatch2ReleaseAcceptanceRepository({
    required this.stagingRepository,
    required this.catalogueRepository,
  });

  final LabBatch2CatalogueStagingRepository stagingRepository;
  final LabLearnerCatalogueRepository catalogueRepository;
  final Map<String, LabBatch2ReleaseAcceptance> _records =
      <String, LabBatch2ReleaseAcceptance>{};

  @override
  Future<LabBatch2ReleaseAcceptance?> load(String releaseId) async =>
      _records[releaseId];

  @override
  Future<void> saveAndActivate({
    required LabBatch2ReleaseAcceptance acceptance,
    required LabScenarioPopulationManifest manifest,
  }) async {
    if (_records.containsKey(acceptance.releaseId)) {
      throw const LabBatch2ReleaseException(
        'Batch 2 Q17 acceptance is immutable and already exists.',
      );
    }
    final staged = <LabBatch2StagedCatalogueDocument>[];
    for (final entry in manifest.entries) {
      final item = await stagingRepository.load(
        acceptance.releaseId,
        entry.labId,
        entry.versionId,
      );
      if (item == null) {
        throw LabBatch2ReleaseException(
          'Batch 2 Q17 cannot activate missing staged entry ' +
              entry.identityKey +
              '.',
        );
      }
      staged.add(item);
    }
    for (final item in staged) {
      await catalogueRepository.saveImmutable(item.entry);
    }
    _records[acceptance.releaseId] = acceptance;
  }

  @override
  Future<int> activatedCount({
    required String releaseId,
    required LabScenarioPopulationManifest manifest,
  }) async {
    var count = 0;
    for (final entry in manifest.entries) {
      if (await catalogueRepository.load(entry.labId, entry.versionId) != null) {
        count++;
      }
    }
    return count;
  }
}

class FirestoreLabBatch2ReleaseAcceptanceRepository
    implements LabBatch2ReleaseAcceptanceRepository {
  FirestoreLabBatch2ReleaseAcceptanceRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _acceptance =>
      _firestore.collection('labProductionReleaseExtensionAcceptance');
  CollectionReference<Map<String, dynamic>> get _staging =>
      _firestore.collection('labProductionCatalogueStaging');
  CollectionReference<Map<String, dynamic>> get _catalogue =>
      _firestore.collection('labLearnerCatalogue');

  String _stageId(String releaseId, String labId, String versionId) =>
      releaseId + '__' + labId + '__' + versionId;

  String _catalogueId(String labId, String versionId) =>
      labId + '__' + versionId;

  @override
  Future<LabBatch2ReleaseAcceptance?> load(String releaseId) async {
    final snapshot = await _acceptance.doc(releaseId).get();
    if (!snapshot.exists) return null;
    final data = snapshot.data();
    if (data == null ||
        data['schemaVersion'] != kBatch2AcceptanceSchemaVersion) {
      throw const LabBatch2ReleaseException(
        'Unsupported Batch 2 Q17 acceptance document.',
      );
    }
    final payload = Map<String, Object?>.from(data)..remove('serverCreatedAt');
    return LabBatch2ReleaseAcceptance.fromJson(payload);
  }

  @override
  Future<void> saveAndActivate({
    required LabBatch2ReleaseAcceptance acceptance,
    required LabScenarioPopulationManifest manifest,
  }) async {
    final acceptanceRef = _acceptance.doc(acceptance.releaseId);
    await _firestore.runTransaction((transaction) async {
      final existingAcceptance = await transaction.get(acceptanceRef);
      if (existingAcceptance.exists) {
        throw const LabBatch2ReleaseException(
          'Batch 2 Q17 acceptance is immutable and already exists.',
        );
      }

      final stagedSnapshots = <DocumentSnapshot<Map<String, dynamic>>>[];
      final targetRefs = <DocumentReference<Map<String, dynamic>>>[];
      for (final entry in manifest.entries) {
        final stageRef = _staging.doc(
          _stageId(acceptance.releaseId, entry.labId, entry.versionId),
        );
        final targetRef = _catalogue.doc(
          _catalogueId(entry.labId, entry.versionId),
        );
        final staged = await transaction.get(stageRef);
        final target = await transaction.get(targetRef);
        if (!staged.exists || target.exists) {
          throw LabBatch2ReleaseException(
            'Batch 2 Q17 activation precondition failed for ' +
                entry.identityKey +
                '.',
          );
        }
        stagedSnapshots.add(staged);
        targetRefs.add(targetRef);
      }

      transaction.set(acceptanceRef, <String, dynamic>{
        ...acceptance.toJson(),
        'serverCreatedAt': FieldValue.serverTimestamp(),
      });

      for (var index = 0; index < stagedSnapshots.length; index++) {
        final staged = stagedSnapshots[index].data();
        if (staged == null) {
          throw const LabBatch2ReleaseException(
            'Batch 2 staged catalogue payload is empty.',
          );
        }
        final payload = Map<String, dynamic>.from(staged)
          ..remove('serverCreatedAt')
          ..['schemaVersion'] = kLabLearnerCatalogueFirestoreSchemaVersion
          ..['available'] = true;
        transaction.set(targetRefs[index], <String, dynamic>{
          ...payload,
          'serverCreatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  @override
  Future<int> activatedCount({
    required String releaseId,
    required LabScenarioPopulationManifest manifest,
  }) async {
    var count = 0;
    for (final entry in manifest.entries) {
      final snapshot = await _catalogue
          .doc(_catalogueId(entry.labId, entry.versionId))
          .get();
      final data = snapshot.data();
      if (snapshot.exists &&
          data != null &&
          data['available'] == true &&
          data['releaseId'] == releaseId) {
        count++;
      }
    }
    return count;
  }
}

enum LabBatch2AcceptanceState { blocked, ready, accepted }

class LabBatch2AcceptanceInspection {
  const LabBatch2AcceptanceInspection({
    required this.state,
    required this.release,
    required this.activatedCount,
    this.acceptance,
    this.blockingReason,
  });

  final LabBatch2AcceptanceState state;
  final LabBatch2ReleaseInspection release;
  final int activatedCount;
  final LabBatch2ReleaseAcceptance? acceptance;
  final String? blockingReason;

  bool get canAccept => state == LabBatch2AcceptanceState.ready;

  String get stateLabel {
    switch (state) {
      case LabBatch2AcceptanceState.blocked:
        return 'BLOCKED';
      case LabBatch2AcceptanceState.ready:
        return 'READY';
      case LabBatch2AcceptanceState.accepted:
        return 'ACCEPTED';
    }
  }
}

class LabBatch2AcceptanceService {
  const LabBatch2AcceptanceService({
    required this.releaseOperator,
    required this.populationSource,
    required this.acceptanceRepository,
  });

  factory LabBatch2AcceptanceService.firestore({
    FirebaseFirestore? firestore,
    AssetBundle? bundle,
  }) {
    final instance = firestore ?? FirebaseFirestore.instance;
    final source = BundledLabBatch2PopulationSource(
      bundle: bundle ?? rootBundle,
    );
    return LabBatch2AcceptanceService(
      releaseOperator: LabBatch2ReleaseOperatorService.firestore(
        firestore: instance,
        bundle: bundle,
      ),
      populationSource: source,
      acceptanceRepository:
          FirestoreLabBatch2ReleaseAcceptanceRepository(
            firestore: instance,
          ),
    );
  }

  final LabBatch2ReleaseOperator releaseOperator;
  final LabProductionPopulationSource populationSource;
  final LabBatch2ReleaseAcceptanceRepository acceptanceRepository;

  Future<LabBatch2AcceptanceInspection> inspect() async {
    final release = await releaseOperator.inspect();
    final manifest = await populationSource.loadManifest();
    final activated = await acceptanceRepository.activatedCount(
      releaseId: kBatch2ReleaseId,
      manifest: manifest,
    );

    LabBatch2AcceptanceInspection blocked(String reason) =>
        LabBatch2AcceptanceInspection(
          state: LabBatch2AcceptanceState.blocked,
          release: release,
          activatedCount: activated,
          blockingReason: reason,
        );

    if (!release.isClosed || release.evidence == null) {
      return blocked(
        'Batch 2 Q17 requires a verified CLOSED Batch 2 Q16 release first.',
      );
    }

    final acceptance = await acceptanceRepository.load(kBatch2ReleaseId);
    if (acceptance == null) {
      if (activated != 0) {
        return blocked(
          'Batch 2 learner catalogue activated before Q17 acceptance.',
        );
      }
      return LabBatch2AcceptanceInspection(
        state: LabBatch2AcceptanceState.ready,
        release: release,
        activatedCount: 0,
      );
    }

    if (acceptance.evidenceFingerprint !=
            release.evidence!.evidenceFingerprint ||
        activated != manifest.entries.length) {
      return blocked(
        'Batch 2 Q17 persisted acceptance does not match the active catalogue.',
      );
    }

    return LabBatch2AcceptanceInspection(
      state: LabBatch2AcceptanceState.accepted,
      release: release,
      activatedCount: activated,
      acceptance: acceptance,
    );
  }

  Future<LabBatch2ReleaseAcceptance> acceptLiveRelease({
    required String acceptedBy,
    required String confirmationPhrase,
    DateTime? acceptedAt,
  }) async {
    if (acceptedBy.trim().isEmpty ||
        confirmationPhrase != kBatch2AcceptanceConfirmationPhrase) {
      throw const LabBatch2ReleaseException(
        'Batch 2 Q17 requires an admin actor and the exact acceptance phrase.',
      );
    }
    final before = await inspect();
    final evidence = before.release.evidence;
    if (!before.canAccept || evidence == null) {
      throw LabBatch2ReleaseException(
        'Batch 2 Q17 acceptance is not permitted from ' +
            before.stateLabel +
            '.',
      );
    }

    final acceptance = LabBatch2ReleaseAcceptance.issue(
      evidence: evidence,
      acceptedBy: acceptedBy.trim(),
      acceptedAt: acceptedAt ?? DateTime.now().toUtc(),
    );
    final manifest = await populationSource.loadManifest();
    await acceptanceRepository.saveAndActivate(
      acceptance: acceptance,
      manifest: manifest,
    );

    final after = await inspect();
    if (after.state != LabBatch2AcceptanceState.accepted ||
        after.acceptance?.acceptanceFingerprint !=
            acceptance.acceptanceFingerprint) {
      throw const LabBatch2ReleaseException(
        'Batch 2 Q17 activation completed without verified ACCEPTED state.',
      );
    }
    return after.acceptance!;
  }
}
