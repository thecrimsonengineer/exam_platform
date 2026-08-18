import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/question.dart';

/// Local persistent question repository.
///
/// This is intentionally storage-backed but API-ready. The legacy static
/// question bank remains available through QuizService, while questions
/// created by the Admin Question Bank are stored here.
class LocalQuestionRepository {
  LocalQuestionRepository._();

  static final LocalQuestionRepository instance = LocalQuestionRepository._();

  static const String _storageKey = 'csp11.question_bank.v1';

  List<Question> _questions = <Question>[];
  bool _initialized = false;

  List<Question> get questions => List<Question>.unmodifiable(_questions);

  Future<void> initialize() async {
    if (_initialized) return;

    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_storageKey);

    if (raw != null && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          _questions = decoded
              .whereType<Map>()
              .map((item) {
                try {
                  return Question.fromJson(
                    Map<String, dynamic>.from(item),
                  );
                } catch (_) {
                  return null;
                }
              })
              .whereType<Question>()
              .toList();
        }
      } catch (_) {
        _questions = <Question>[];
      }
    }

    _initialized = true;
  }

  Future<void> save(Question question) async {
    await initialize();

    final updated = <Question>[];
    var replaced = false;

    for (final existing in _questions) {
      if (existing.id == question.id) {
        updated.add(question);
        replaced = true;
      } else {
        updated.add(existing);
      }
    }

    if (!replaced) {
      updated.insert(0, question);
    }

    _questions = updated;
    await _persist();
  }

  Future<void> delete(int questionId) async {
    await initialize();
    _questions = _questions
        .where((question) => question.id != questionId)
        .toList();
    await _persist();
  }

  /// Replaces the managed question cache with the supplied cloud snapshot.
  ///
  /// This is used by the Firebase-backed admin repository synchronization.
  /// Student quiz consumption still reads from this local cache.
  Future<void> replaceAll(List<Question> questions) async {
    await initialize();
    _questions = List<Question>.from(questions);
    await _persist();
  }

  List<Question> byQuizId(String quizId) {
    return _questions
        .where((question) => question.quizId == quizId)
        .toList();
  }

  List<Question> bySubtopic(String subtopicId) {
    return _questions
        .where((question) => question.subtopicId == subtopicId)
        .toList();
  }

  Future<void> _persist() async {
    final preferences = await SharedPreferences.getInstance();
    final success = await preferences.setString(
      _storageKey,
      jsonEncode(_questions.map((question) => question.toJson()).toList()),
    );

    if (!success) {
      throw StateError('Question repository could not be saved.');
    }
  }
}
