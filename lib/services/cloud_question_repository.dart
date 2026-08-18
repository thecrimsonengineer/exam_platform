import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/question.dart';

/// Firebase-backed repository for CSP11 managed questions.
///
/// Questions are stored as individual documents so the Admin Studio can
/// create, validate, publish, and delete questions across devices.
///
/// The question lifecycle is stored directly on the question:
/// draft -> review -> validated -> published.
///
/// Student-side local quiz consumption remains backed by
/// LocalQuestionRepository until the Phase I Firebase student integration.
class CloudQuestionRepository {
  CloudQuestionRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('questions');

  String _documentId(int questionId) => 'question_$questionId';

  Future<List<Question>> loadAll() async {
    final snapshot = await _collection.get();

    final questions = snapshot.docs
        .map((doc) => _decode(doc.data()))
        .whereType<Question>()
        .toList();

    questions.sort((a, b) => a.id.compareTo(b.id));
    return questions;
  }

  Future<Question?> load(int questionId) async {
    final doc = await _collection.doc(_documentId(questionId)).get();

    if (!doc.exists) {
      return null;
    }

    return _decode(doc.data());
  }

  Future<void> save(Question question) async {
    await _collection.doc(_documentId(question.id)).set({
      ...question.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> delete(int questionId) async {
    await _collection.doc(_documentId(questionId)).delete();
  }

  Future<void> clear() async {
    final snapshot = await _collection.get();
    final batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  Question? _decode(Map<String, dynamic>? data) {
    if (data == null) {
      return null;
    }

    try {
      final json = Map<String, dynamic>.from(data)
        ..remove('updatedAt')
        ..remove('createdAt');

      return Question.fromJson(json);
    } catch (_) {
      return null;
    }
  }
}
