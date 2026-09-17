import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/question.dart';

/// Device-local storage for learner question bookmarks.
///
/// IDs remain stored under the original preference key for backwards
/// compatibility. V2 also stores complete Question JSON snapshots so the
/// learner can recall bookmarked questions without another Firebase read.
class BookmarkService {
  static const String _bookmarkKey = 'bookmarked_question_ids';
  static const String _snapshotKey = 'bookmarked_question_snapshots_v2';

  // ==========================================================
  // GET BOOKMARKS
  // ==========================================================

  Future<Set<int>> getBookmarkedQuestionIds() async {
    final prefs = await SharedPreferences.getInstance();
    final rawIds = prefs.getStringList(_bookmarkKey) ?? const <String>[];

    final ids = rawIds.map(int.tryParse).whereType<int>().toSet();

    // A snapshot is authoritative evidence that the learner bookmarked the
    // question even if an older app version did not keep the ID list aligned.
    for (final question in await _readSnapshotQuestions()) {
      ids.add(question.id);
    }

    return ids;
  }

  /// Returns locally cached bookmark snapshots, newest bookmark first.
  ///
  /// Malformed cache entries are ignored rather than blocking the learner's
  /// bookmark library.
  Future<List<Question>> getBookmarkedQuestions() async {
    final stored = await _readSnapshotQuestions();
    final seen = <int>{};
    final result = <Question>[];

    for (final question in stored.reversed) {
      if (seen.add(question.id)) {
        result.add(question);
      }
    }

    return List<Question>.unmodifiable(result);
  }

  // ==========================================================
  // CHECK BOOKMARK
  // ==========================================================

  Future<bool> isBookmarked(int questionId) async {
    final bookmarkedIds = await getBookmarkedQuestionIds();
    return bookmarkedIds.contains(questionId);
  }

  // ==========================================================
  // QUESTION SNAPSHOT API
  // ==========================================================

  /// Adds a bookmark and caches the complete question on this device.
  Future<void> addQuestion(Question question) async {
    final bookmarkedIds = await getBookmarkedQuestionIds();
    final snapshots = await _readSnapshotQuestions();

    bookmarkedIds.add(question.id);
    snapshots.removeWhere((item) => item.id == question.id);
    snapshots.add(question);

    await _saveBookmarks(bookmarkedIds);
    await _saveSnapshotQuestions(snapshots);
  }

  /// Toggles a bookmark while keeping the ID list and local snapshot cache in
  /// sync. This is the preferred API for learner-facing quiz screens.
  Future<void> toggleQuestion(Question question) async {
    final bookmarkedIds = await getBookmarkedQuestionIds();
    final snapshots = await _readSnapshotQuestions();
    final alreadyBookmarked = bookmarkedIds.contains(question.id);

    snapshots.removeWhere((item) => item.id == question.id);

    if (alreadyBookmarked) {
      bookmarkedIds.remove(question.id);
    } else {
      bookmarkedIds.add(question.id);
      snapshots.add(question);
    }

    await _saveBookmarks(bookmarkedIds);
    await _saveSnapshotQuestions(snapshots);
  }

  // ==========================================================
  // LEGACY ID API
  // ==========================================================

  /// Retained for compatibility with older callers that only know the ID.
  ///
  /// A full recallable cache entry requires [addQuestion] or [toggleQuestion].
  Future<void> addBookmark(int questionId) async {
    final bookmarkedIds = await getBookmarkedQuestionIds();
    bookmarkedIds.add(questionId);
    await _saveBookmarks(bookmarkedIds);
  }

  Future<void> removeBookmark(int questionId) async {
    final bookmarkedIds = await getBookmarkedQuestionIds();
    final snapshots = await _readSnapshotQuestions();

    bookmarkedIds.remove(questionId);
    snapshots.removeWhere((item) => item.id == questionId);

    await _saveBookmarks(bookmarkedIds);
    await _saveSnapshotQuestions(snapshots);
  }

  /// Retained for compatibility. New quiz UI should use [toggleQuestion] so a
  /// recallable snapshot is saved together with the bookmark ID.
  Future<void> toggleBookmark(int questionId) async {
    final bookmarkedIds = await getBookmarkedQuestionIds();
    final snapshots = await _readSnapshotQuestions();

    if (bookmarkedIds.contains(questionId)) {
      bookmarkedIds.remove(questionId);
      snapshots.removeWhere((item) => item.id == questionId);
    } else {
      bookmarkedIds.add(questionId);
    }

    await _saveBookmarks(bookmarkedIds);
    await _saveSnapshotQuestions(snapshots);
  }

  // ==========================================================
  // COUNT / CLEAR
  // ==========================================================

  Future<int> getBookmarkCount() async {
    final bookmarkedIds = await getBookmarkedQuestionIds();
    return bookmarkedIds.length;
  }

  Future<void> clearAllBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_bookmarkKey);
    await prefs.remove(_snapshotKey);
  }

  // ==========================================================
  // STORAGE
  // ==========================================================

  Future<List<Question>> _readSnapshotQuestions() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getStringList(_snapshotKey) ?? const <String>[];
    final questions = <Question>[];

    for (final value in encoded) {
      try {
        final decoded = jsonDecode(value);

        if (decoded is! Map) {
          continue;
        }

        questions.add(Question.fromJson(Map<String, dynamic>.from(decoded)));
      } catch (_) {
        // Ignore one corrupt local cache item and continue loading the rest.
      }
    }

    return questions;
  }

  Future<void> _saveBookmarks(Set<int> bookmarkedIds) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = bookmarkedIds.map((id) => id.toString()).toList()..sort();

    await prefs.setStringList(_bookmarkKey, ids);
  }

  Future<void> _saveSnapshotQuestions(List<Question> questions) async {
    final prefs = await SharedPreferences.getInstance();
    final seen = <int>{};
    final encoded = <String>[];

    for (final question in questions) {
      if (!seen.add(question.id)) {
        continue;
      }

      encoded.add(jsonEncode(question.toJson()));
    }

    await prefs.setStringList(_snapshotKey, encoded);
  }
}
