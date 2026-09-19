import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/study_content.dart';
import '../performance/firestore_read_audit.dart';

/// Firebase-backed repository for CSP11 study-content versions.
///
/// Firebase stores draft and published copies independently.
/// The lifecycle status of a published copy is always stored as
/// PUBLISHED when the publish operation succeeds.
class CloudContentRepository {
  CloudContentRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('contentVersions');

  String _draftId(String contentId) => 'draft_$contentId';

  String _publishedId(String contentId) => 'published_$contentId';

  Future<List<StudyContent>> loadDrafts() async {
    final snapshot = await _collection
        .where('copyType', isEqualTo: 'draft')
        .get();
    FirestoreReadAudit.recordQuery(
      operation: 'content.loadDrafts',
      collection: 'contentVersions',
      scope: 'copyType=draft',
      returnedDocuments: snapshot.docs.length,
    );

    return snapshot.docs
        .map(_fromQueryDocument)
        .whereType<StudyContent>()
        .toList();
  }

  Future<StudyContent?> loadDraft(String contentId) async {
    final documentId = _draftId(contentId);
    final doc = await _collection.doc(documentId).get();
    FirestoreReadAudit.recordDocument(
      operation: 'content.loadDraft',
      collection: 'contentVersions',
      documentId: documentId,
      exists: doc.exists,
    );

    return _fromDocument(doc);
  }

  Future<void> saveDraft(StudyContent content) async {
    await _collection
        .doc(_draftId(content.id))
        .set(_toDocument(content, copyType: 'draft'));
  }

  Future<void> updateDraftStatus(String contentId, String status) async {
    await _collection.doc(_draftId(contentId)).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteDraft(String contentId) async {
    await _collection.doc(_draftId(contentId)).delete();
  }

  Future<void> clearDrafts() async {
    final snapshot = await _collection
        .where('copyType', isEqualTo: 'draft')
        .get();
    FirestoreReadAudit.recordQuery(
      operation: 'content.clearDrafts.readBeforeDelete',
      collection: 'contentVersions',
      scope: 'copyType=draft',
      returnedDocuments: snapshot.docs.length,
    );

    final batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  Future<List<StudyContent>> loadPublished() async {
    final snapshot = await _collection
        .where('copyType', isEqualTo: 'published')
        .where('status', isEqualTo: 'published')
        .get();
    FirestoreReadAudit.recordQuery(
      operation: 'content.loadPublished',
      collection: 'contentVersions',
      scope: 'copyType=published,status=published',
      returnedDocuments: snapshot.docs.length,
    );

    return snapshot.docs
        .map(_fromQueryDocument)
        .whereType<StudyContent>()
        .toList();
  }

  Future<StudyContent?> loadPublishedContent(String contentId) async {
    final documentId = _publishedId(contentId);
    final doc = await _collection.doc(documentId).get();
    FirestoreReadAudit.recordDocument(
      operation: 'content.loadPublishedContent',
      collection: 'contentVersions',
      documentId: documentId,
      exists: doc.exists,
    );

    return _fromDocument(doc);
  }

  /// Loads only documents belonging to one competency.
  ///
  /// The learner query is scoped to domain, competency, published copy,
  /// and published lifecycle status so it satisfies the Firestore read
  /// boundary before documents are returned.

  /// Loads the latest published version of every competency in one domain.
  ///
  /// The learner query includes the published-copy lifecycle predicates
  /// required by Firestore security rules. Local checks remain as
  /// defense-in-depth after the query returns.
  Future<List<StudyContent>> loadPublishedDomain(String domainId) async {
    final snapshot = await _collection
        .where('domainId', isEqualTo: domainId)
        .where('copyType', isEqualTo: 'published')
        .where('status', isEqualTo: 'published')
        .get();
    FirestoreReadAudit.recordQuery(
      operation: 'content.loadPublishedDomain',
      collection: 'contentVersions',
      scope: 'domainId=$domainId,copyType=published,status=published',
      returnedDocuments: snapshot.docs.length,
    );

    final latestByCompetency = <String, StudyContent>{};

    for (final doc in snapshot.docs) {
      final data = doc.data();

      if (data['copyType']?.toString().toLowerCase() != 'published' ||
          data['status']?.toString().toLowerCase() != 'published' ||
          data['domainId']?.toString() != domainId) {
        continue;
      }

      final content = _fromQueryDocument(doc);

      if (content == null ||
          content.domainId != domainId ||
          content.status.toLowerCase() != 'published') {
        continue;
      }

      final existing = latestByCompetency[content.competencyId];

      if (existing == null || content.version > existing.version) {
        latestByCompetency[content.competencyId] = content;
      }
    }

    final contents = latestByCompetency.values.toList()
      ..sort((a, b) => a.competencyNumber.compareTo(b.competencyNumber));

    return contents;
  }

  Future<StudyContent?> loadPublishedCompetency({
    required String domainId,
    required String competencyId,
  }) async {
    final snapshot = await _collection
        .where('domainId', isEqualTo: domainId)
        .where('competencyId', isEqualTo: competencyId)
        .where('copyType', isEqualTo: 'published')
        .where('status', isEqualTo: 'published')
        .get();
    FirestoreReadAudit.recordQuery(
      operation: 'content.loadPublishedCompetency',
      collection: 'contentVersions',
      scope:
          'domainId=$domainId,competencyId=$competencyId,'
          'copyType=published,status=published',
      returnedDocuments: snapshot.docs.length,
    );

    StudyContent? latest;

    for (final doc in snapshot.docs) {
      final source = doc.data();

      if (source['copyType']?.toString().toLowerCase() != 'published' ||
          source['status']?.toString().toLowerCase() != 'published' ||
          source['domainId']?.toString() != domainId ||
          source['competencyId']?.toString() != competencyId) {
        continue;
      }

      final content = _fromQueryDocument(doc);

      if (content == null) {
        continue;
      }

      if (latest == null || content.version > latest.version) {
        latest = content;
      }
    }

    return latest;
  }

  /// Creates an independent published copy.
  ///
  /// The published repository has its own lifecycle. Therefore the copy
  /// is explicitly stored as PUBLISHED regardless of the status of the
  /// source object.
  Future<void> publish(StudyContent content) async {
    final json = Map<String, dynamic>.from(content.toJson())
      ..['status'] = 'published';

    final publishedContent = StudyContent.fromJson(json);

    await _collection
        .doc(_publishedId(content.id))
        .set(_toDocument(publishedContent, copyType: 'published'));
  }

  Future<void> updatePublishedStatus(String contentId, String status) async {
    await _collection.doc(_publishedId(contentId)).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deletePublished(String contentId) async {
    await _collection.doc(_publishedId(contentId)).delete();
  }

  Future<void> clearPublished() async {
    final snapshot = await _collection
        .where('copyType', isEqualTo: 'published')
        .get();
    FirestoreReadAudit.recordQuery(
      operation: 'content.clearPublished.readBeforeDelete',
      collection: 'contentVersions',
      scope: 'copyType=published',
      returnedDocuments: snapshot.docs.length,
    );

    final batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  Map<String, dynamic> _toDocument(
    StudyContent content, {
    required String copyType,
  }) {
    final encoded = _encodeFirestoreSafe(content.toJson());

    return {
      ...Map<String, dynamic>.from(encoded as Map),
      'copyType': copyType,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Firestore does not allow an array to directly contain another array.
  ///
  /// StudyContent can legitimately contain structures such as table rows:
  /// rows: [[cell, cell], [cell, cell]].
  ///
  /// Encode only nested arrays into a reversible marker map.
  /// Arrays of maps and arrays of scalar values remain normal
  /// Firestore arrays.
  dynamic _encodeFirestoreSafe(dynamic value) {
    if (value is Map) {
      return value.map(
        (key, nestedValue) =>
            MapEntry(key.toString(), _encodeFirestoreSafe(nestedValue)),
      );
    }

    if (value is List) {
      final encodedItems = value
          .map(_encodeFirestoreSafe)
          .toList(growable: false);

      if (value.any((item) => item is List)) {
        return {
          'csp11FirestoreNestedListV1': true,
          'items': <String, dynamic>{
            for (var i = 0; i < encodedItems.length; i++) '$i': encodedItems[i],
          },
        };
      }

      return encodedItems;
    }

    return value;
  }

  dynamic _decodeFirestoreSafe(dynamic value) {
    if (value is Map) {
      final marker = value['csp11FirestoreNestedListV1'];
      final items = value['items'];

      if (marker == true && items is Map) {
        final entries = items.entries.toList()
          ..sort((a, b) {
            final ai = int.tryParse(a.key.toString()) ?? 0;
            final bi = int.tryParse(b.key.toString()) ?? 0;

            return ai.compareTo(bi);
          });

        return entries
            .map((entry) => _decodeFirestoreSafe(entry.value))
            .toList();
      }

      return value.map(
        (key, nestedValue) =>
            MapEntry(key.toString(), _decodeFirestoreSafe(nestedValue)),
      );
    }

    if (value is List) {
      return value.map(_decodeFirestoreSafe).toList();
    }

    return value;
  }

  StudyContent? _fromQueryDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return _decode(doc.data());
  }

  StudyContent? _fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    if (!doc.exists) {
      return null;
    }

    final data = doc.data();

    if (data == null) {
      return null;
    }

    return _decode(data);
  }

  StudyContent? _decode(Map<String, dynamic> source) {
    try {
      final decoded = _decodeFirestoreSafe(source);

      final data = Map<String, dynamic>.from(decoded as Map)
        ..remove('copyType')
        ..remove('updatedAt')
        ..remove('createdAt');

      return StudyContent.fromJson(data);
    } catch (_) {
      return null;
    }
  }
}
