import 'package:cloud_firestore/cloud_firestore.dart';

import 'lab_contracts.dart';
import 'lab_learner_catalogue.dart';
import 'lab_learner_presentation.dart';
import 'lab_production_release_closure.dart';
import 'lab_published_payload_chunks.dart';
import 'lab_studio.dart';

const String kLabPublishedFirestoreSchemaVersion =
    'csp11.lab.published_repository.v1';
const String kLabLearnerCatalogueFirestoreSchemaVersion =
    'csp11.lab.learner_catalogue.v1';
const String kLabProductionReleaseFirestoreSchemaVersion =
    LabProductionReleaseEvidence.schemaVersion;
const String kLabLearnerReleaseStateFirestoreSchemaVersion =
    'csp11.lab.learner_release_state.v1';

class FirestoreLabPublishedRepository implements LabPublishedRepository {
  FirestoreLabPublishedRepository({
    FirebaseFirestore? firestore,
    this.payloadCodec = const LabPublishedPayloadChunkCodec(),
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final LabPublishedPayloadChunkCodec payloadCodec;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('labPublishedVersions');

  String _documentId(String labId, String versionId) =>
      labId + '__' + versionId;

  @override
  Future<void> saveImmutable(LabPublishedVersion version) async {
    await _validatePublishedVersion(version);

    final versionKey = _documentId(version.labId, version.versionId);
    final reference = _collection.doc(versionKey);
    final payload = payloadCodec.encode(<String, String>{
      'publishedJson': version.publishedJson,
      'qualityEvidenceJson': version.qualityEvidenceJson!,
      'exhaustiveRouteEvidenceJson': version.exhaustiveRouteEvidenceJson!,
      'publishEvidenceJson': version.publishEvidenceJson!,
    });

    await _firestore.runTransaction((transaction) async {
      final existing = await transaction.get(reference);
      if (existing.exists) {
        throw const LabStudioException(
          'Published LAB versions are immutable and cannot be overwritten.',
        );
      }

      for (final chunk in payload.chunks) {
        transaction.set(
          reference.collection('payloadChunks').doc(chunk.documentId),
          <String, dynamic>{
            ...chunk.toJson(),
            'versionKey': versionKey,
            'serverCreatedAt': FieldValue.serverTimestamp(),
          },
        );
      }

      transaction.set(reference, <String, dynamic>{
        'schemaVersion': kLabPublishedChunkedFirestoreSchemaVersion,
        'labId': version.labId,
        'versionId': version.versionId,
        'lifecycle': 'published',
        'publishedAt': Timestamp.fromDate(version.publishedAt.toUtc()),
        'reviewerId': version.reviewerId,
        'validationAuthority': version.validationAuthority,
        'snapshotFingerprint': version.snapshotFingerprint,
        'payloadSchemaVersion': kLabPublishedPayloadSchemaVersion,
        'payloadManifest': payload.manifestJson,
        'payloadChunkCount': payload.chunks.length,
        'serverCreatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Future<LabPublishedVersion?> load(String labId, String versionId) async {
    final versionKey = _documentId(labId, versionId);
    final reference = _collection.doc(versionKey);
    final snapshot = await reference.get();
    if (!snapshot.exists) return null;

    final data = snapshot.data();
    if (data == null) {
      throw const LabStudioException(
        'Published LAB Firestore document is empty.',
      );
    }

    late final LabPublishedVersion version;
    if (data['schemaVersion'] == kLabPublishedFirestoreSchemaVersion) {
      version = _decodeLegacyPublishedVersion(data);
    } else if (data['schemaVersion'] ==
        kLabPublishedChunkedFirestoreSchemaVersion) {
      final rawManifest = data['payloadManifest'];
      final expectedChunkCount = data['payloadChunkCount'];
      if (data['payloadSchemaVersion'] != kLabPublishedPayloadSchemaVersion ||
          rawManifest is! Map ||
          expectedChunkCount is! int ||
          expectedChunkCount <= 0 ||
          expectedChunkCount > kLabPublishedPayloadMaxChunksPerVersion) {
        throw const LabStudioException(
          'Chunked published LAB manifest is invalid.',
        );
      }

      final chunkSnapshot = await reference.collection('payloadChunks').get();
      if (chunkSnapshot.docs.length != expectedChunkCount) {
        throw const LabStudioException(
          'Chunked published LAB payload is incomplete.',
        );
      }
      final payload = payloadCodec.decode(
        manifestJson: rawManifest.cast<String, Object?>(),
        chunkJson: chunkSnapshot.docs.map(
          (document) => Map<String, Object?>.from(document.data()),
        ),
      );
      version = _decodeChunkedPublishedVersion(data, payload);
    } else {
      throw const LabStudioException(
        'Unsupported published LAB Firestore schema.',
      );
    }

    if (version.labId != labId || version.versionId != versionId) {
      throw const LabStudioException(
        'Published LAB Firestore identity does not match its document key.',
      );
    }

    await _validatePublishedVersion(version);
    return version;
  }

  Future<void> _validatePublishedVersion(LabPublishedVersion version) async {
    if (version.validationAuthority == null ||
        version.qualityEvidenceJson == null ||
        version.exhaustiveRouteEvidenceJson == null ||
        version.publishEvidenceJson == null ||
        version.snapshotFingerprint == null) {
      throw const LabStudioException(
        'Persistent published LABs require the complete automated evidence chain.',
      );
    }

    await InMemoryLabPublishedRepository().saveImmutable(version);
  }

  LabPublishedVersion _decodeLegacyPublishedVersion(Map<String, dynamic> data) {
    if (data['schemaVersion'] != kLabPublishedFirestoreSchemaVersion ||
        data['lifecycle'] != 'published') {
      throw const LabStudioException(
        'Unsupported or non-published LAB Firestore document.',
      );
    }

    final publishedAt = data['publishedAt'];
    if (publishedAt is! Timestamp) {
      throw const LabStudioException(
        'Published LAB Firestore document requires a timestamp.',
      );
    }

    String requiredText(String key) {
      final value = data[key]?.toString().trim() ?? '';
      if (value.isEmpty) {
        throw LabStudioException(
          'Published LAB Firestore document requires ' + key + '.',
        );
      }
      return value;
    }

    return LabPublishedVersion(
      labId: requiredText('labId'),
      versionId: requiredText('versionId'),
      publishedJson: requiredText('publishedJson'),
      publishedAt: publishedAt.toDate().toUtc(),
      reviewerId: requiredText('reviewerId'),
      validationAuthority: requiredText('validationAuthority'),
      qualityEvidenceJson: requiredText('qualityEvidenceJson'),
      exhaustiveRouteEvidenceJson: requiredText('exhaustiveRouteEvidenceJson'),
      publishEvidenceJson: requiredText('publishEvidenceJson'),
      snapshotFingerprint: requiredText('snapshotFingerprint'),
    );
  }

  LabPublishedVersion _decodeChunkedPublishedVersion(
    Map<String, dynamic> data,
    Map<String, String> payload,
  ) {
    if (data['schemaVersion'] != kLabPublishedChunkedFirestoreSchemaVersion ||
        data['lifecycle'] != 'published') {
      throw const LabStudioException(
        'Unsupported or non-published chunked LAB Firestore document.',
      );
    }

    final publishedAt = data['publishedAt'];
    if (publishedAt is! Timestamp) {
      throw const LabStudioException(
        'Chunked published LAB Firestore document requires a timestamp.',
      );
    }

    String requiredText(String key) {
      final value = data[key]?.toString().trim() ?? '';
      if (value.isEmpty) {
        throw LabStudioException(
          'Chunked published LAB Firestore document requires ' + key + '.',
        );
      }
      return value;
    }

    String payloadText(String key) {
      final value = payload[key]?.trim() ?? '';
      if (value.isEmpty) {
        throw LabStudioException(
          'Chunked published LAB payload requires ' + key + '.',
        );
      }
      return value;
    }

    return LabPublishedVersion(
      labId: requiredText('labId'),
      versionId: requiredText('versionId'),
      publishedJson: payloadText('publishedJson'),
      publishedAt: publishedAt.toDate().toUtc(),
      reviewerId: requiredText('reviewerId'),
      validationAuthority: requiredText('validationAuthority'),
      qualityEvidenceJson: payloadText('qualityEvidenceJson'),
      exhaustiveRouteEvidenceJson: payloadText('exhaustiveRouteEvidenceJson'),
      publishEvidenceJson: payloadText('publishEvidenceJson'),
      snapshotFingerprint: requiredText('snapshotFingerprint'),
    );
  }
}

class FirestoreLabLearnerCatalogueRepository
    implements LabLearnerCatalogueRepository {
  FirestoreLabLearnerCatalogueRepository({
    FirebaseFirestore? firestore,
    String? visibleReleaseId,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _visibleReleaseId = visibleReleaseId?.trim().isEmpty == true
           ? null
           : visibleReleaseId?.trim();

  final FirebaseFirestore _firestore;
  final String? _visibleReleaseId;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('labLearnerCatalogue');

  String _documentId(String labId, String versionId) =>
      labId + '__' + versionId;

  @override
  Future<void> saveImmutable(LabLearnerCatalogueEntry entry) async {
    final reference = _collection.doc(
      _documentId(entry.labId, entry.versionId),
    );

    await _firestore.runTransaction((transaction) async {
      final existing = await transaction.get(reference);
      if (existing.exists) {
        throw const LabLearnerCatalogueException(
          'Learner catalogue entries are immutable and cannot be overwritten.',
        );
      }

      transaction.set(reference, <String, dynamic>{
        'schemaVersion': kLabLearnerCatalogueFirestoreSchemaVersion,
        'available': true,
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
        'presentation': _encodePresentation(entry.presentation),
        'serverCreatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Future<LabLearnerCatalogueEntry?> load(String labId, String versionId) async {
    final snapshot = await _collection.doc(_documentId(labId, versionId)).get();
    if (!snapshot.exists) return null;
    final data = snapshot.data();
    if (data == null || data['available'] != true) return null;
    final visibleReleaseId = _visibleReleaseId;
    if (visibleReleaseId != null && data['releaseId'] != visibleReleaseId) {
      return null;
    }

    final entry = _decodeCatalogueEntry(data);
    if (entry.labId != labId || entry.versionId != versionId) {
      throw const LabLearnerCatalogueException(
        'Learner catalogue Firestore identity does not match its document key.',
      );
    }
    return entry;
  }

  @override
  Future<List<LabLearnerCatalogueEntry>> listAvailable() async {
    Query<Map<String, dynamic>> query = _collection
        .where(
          'schemaVersion',
          isEqualTo: kLabLearnerCatalogueFirestoreSchemaVersion,
        )
        .where('available', isEqualTo: true);
    final visibleReleaseId = _visibleReleaseId;
    if (visibleReleaseId != null) {
      query = query.where('releaseId', isEqualTo: visibleReleaseId);
    }
    final snapshot = await query.get();

    final entries =
        snapshot.docs
            .map((document) => _decodeCatalogueEntry(document.data()))
            .toList(growable: false)
          ..sort((left, right) {
            final title = left.title.compareTo(right.title);
            return title != 0
                ? title
                : left.identityKey.compareTo(right.identityKey);
          });

    return List<LabLearnerCatalogueEntry>.unmodifiable(entries);
  }

  LabLearnerCatalogueEntry _decodeCatalogueEntry(Map<String, dynamic> data) {
    if (data['schemaVersion'] != kLabLearnerCatalogueFirestoreSchemaVersion ||
        data['available'] != true) {
      throw const LabLearnerCatalogueException(
        'Unsupported or unavailable learner catalogue document.',
      );
    }

    String requiredText(String key) {
      final value = data[key]?.toString().trim() ?? '';
      if (value.isEmpty) {
        throw LabLearnerCatalogueException(
          'Learner catalogue Firestore document requires ' + key + '.',
        );
      }
      return value;
    }

    final rawTags = data['focusTags'];
    final rawModes = data['supportedModes'];
    final rawPresentation = data['presentation'];
    final decisionCount = data['decisionCount'];

    if (rawTags is! Iterable ||
        rawModes is! Iterable ||
        rawPresentation is! Map ||
        decisionCount is! int) {
      throw const LabLearnerCatalogueException(
        'Learner catalogue Firestore document has invalid field types.',
      );
    }

    return LabLearnerCatalogueEntry.persistence(
      manifestEntryId: requiredText('manifestEntryId'),
      labId: requiredText('labId'),
      versionId: requiredText('versionId'),
      title: requiredText('title'),
      summary: requiredText('summary'),
      focusTags: rawTags.map((item) => item.toString()),
      estimatedTime: requiredText('estimatedTime'),
      decisionCountLabel: requiredText('decisionCountLabel'),
      decisionCount: decisionCount,
      supportedModes: rawModes.map(parseLabMode).toSet(),
      presentation: LabLearnerPresentationPackage.fromJson(
        rawPresentation.cast<String, Object?>(),
      ),
    );
  }

  Map<String, Object?> _encodePresentation(
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
}

class FirestoreLabProductionReleaseEvidenceRepository
    implements LabProductionReleaseEvidenceRepository {
  FirestoreLabProductionReleaseEvidenceRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('labProductionReleaseEvidence');

  CollectionReference<Map<String, dynamic>> get _releaseStateCollection =>
      _firestore.collection('labLearnerReleaseState');

  @override
  Future<void> saveImmutable(LabProductionReleaseEvidence evidence) async {
    final reference = _collection.doc(evidence.releaseId);
    final releaseStateReference = _releaseStateCollection.doc(
      evidence.releaseId,
    );

    await _firestore.runTransaction((transaction) async {
      final existing = await transaction.get(reference);
      final existingReleaseState = await transaction.get(releaseStateReference);
      if (existing.exists || existingReleaseState.exists) {
        throw const LabProductionReleaseClosureException(
          'Q15 production release evidence is immutable and already exists.',
        );
      }

      transaction.set(reference, <String, dynamic>{
        ...evidence.toJson(),
        'serverCreatedAt': FieldValue.serverTimestamp(),
      });
      transaction.set(releaseStateReference, <String, dynamic>{
        'schemaVersion': kLabLearnerReleaseStateFirestoreSchemaVersion,
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

  @override
  Future<LabProductionReleaseEvidence?> load(String releaseId) async {
    final snapshot = await _collection.doc(releaseId).get();
    if (!snapshot.exists) return null;

    final data = snapshot.data();
    if (data == null ||
        data['schemaVersion'] != kLabProductionReleaseFirestoreSchemaVersion) {
      throw const LabProductionReleaseClosureException(
        'Unsupported or empty Q15 production release evidence document.',
      );
    }

    final payload = Map<String, Object?>.from(data)..remove('serverCreatedAt');
    final evidence = LabProductionReleaseEvidence.fromJson(payload);
    if (evidence.releaseId != releaseId) {
      throw const LabProductionReleaseClosureException(
        'Q15 Firestore release evidence identity does not match its document key.',
      );
    }
    return evidence;
  }

  @override
  Future<bool> isReleased(String releaseId) async {
    final snapshot = await _releaseStateCollection.doc(releaseId).get();
    if (!snapshot.exists) return false;

    final data = snapshot.data();
    return data != null &&
        data['schemaVersion'] ==
            kLabLearnerReleaseStateFirestoreSchemaVersion &&
        data['releaseId'] == releaseId &&
        data['released'] == true &&
        data['labCount'] is int &&
        (data['labCount'] as int) > 0 &&
        data['totalDecisionCount'] is int &&
        (data['totalDecisionCount'] as int) > 0 &&
        data['evidenceFingerprint'] is String &&
        (data['evidenceFingerprint'] as String).isNotEmpty;
  }
}
