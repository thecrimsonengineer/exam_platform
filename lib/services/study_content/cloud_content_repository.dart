import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/study_content.dart';

/// Firebase-backed repository for CSP11 study-content versions.
/// This remains separate from LocalStudyContentRepository during Phase D.
class CloudContentRepository {
  CloudContentRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('contentVersions');

  String _draftId(String contentId) => 'draft_$contentId';
  String _publishedId(String contentId) => 'published_$contentId';

  Future<List<StudyContent>> loadDrafts() async {
    final snapshot =
        await _collection.where('copyType', isEqualTo: 'draft').get();
    return snapshot.docs
        .map(_fromQueryDocument)
        .whereType<StudyContent>()
        .toList();
  }

  Future<StudyContent?> loadDraft(String contentId) async {
    final doc = await _collection.doc(_draftId(contentId)).get();
    return _fromDocument(doc);
  }

  Future<void> saveDraft(StudyContent content) async {
    await _collection.doc(_draftId(content.id)).set(
      _toDocument(content, copyType: 'draft'),
    );
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
    final snapshot =
        await _collection.where('copyType', isEqualTo: 'draft').get();
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<List<StudyContent>> loadPublished() async {
    final snapshot =
        await _collection.where('copyType', isEqualTo: 'published').get();
    return snapshot.docs
        .map(_fromQueryDocument)
        .whereType<StudyContent>()
        .toList();
  }

  Future<StudyContent?> loadPublishedContent(String contentId) async {
    final doc = await _collection.doc(_publishedId(contentId)).get();
    return _fromDocument(doc);
  }

  Future<void> publish(StudyContent content) async {
    await _collection.doc(_publishedId(content.id)).set(
      _toDocument(content, copyType: 'published'),
    );
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
    final snapshot =
        await _collection.where('copyType', isEqualTo: 'published').get();
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
    return {
      ...content.toJson(),
      'copyType': copyType,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  StudyContent? _fromQueryDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return _decode(doc.data());
  }

  StudyContent? _fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    if (!doc.exists) return null;
    final data = doc.data();
    if (data == null) return null;
    return _decode(data);
  }

  StudyContent? _decode(Map<String, dynamic> source) {
    try {
      final data = Map<String, dynamic>.from(source)
        ..remove('copyType')
        ..remove('updatedAt')
        ..remove('createdAt');
      return StudyContent.fromJson(data);
    } catch (_) {
      return null;
    }
  }
}
