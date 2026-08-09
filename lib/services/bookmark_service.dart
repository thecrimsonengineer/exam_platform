import 'package:shared_preferences/shared_preferences.dart';

class BookmarkService {
  static const String _bookmarkKey =
      'bookmarked_question_ids';

  // ==========================================================
  // GET BOOKMARKS
  // ==========================================================

  Future<Set<int>> getBookmarkedQuestionIds() async {
    final prefs =
        await SharedPreferences.getInstance();

    final List<String> ids =
        prefs.getStringList(_bookmarkKey) ?? [];

    return ids
        .map(int.tryParse)
        .whereType<int>()
        .toSet();
  }

  // ==========================================================
  // CHECK BOOKMARK
  // ==========================================================

  Future<bool> isBookmarked(
    int questionId,
  ) async {
    final bookmarkedIds =
        await getBookmarkedQuestionIds();

    return bookmarkedIds.contains(questionId);
  }

  // ==========================================================
  // ADD BOOKMARK
  // ==========================================================

  Future<void> addBookmark(
    int questionId,
  ) async {
    final bookmarkedIds =
        await getBookmarkedQuestionIds();

    bookmarkedIds.add(questionId);

    await _saveBookmarks(bookmarkedIds);
  }

  // ==========================================================
  // REMOVE BOOKMARK
  // ==========================================================

  Future<void> removeBookmark(
    int questionId,
  ) async {
    final bookmarkedIds =
        await getBookmarkedQuestionIds();

    bookmarkedIds.remove(questionId);

    await _saveBookmarks(bookmarkedIds);
  }

  // ==========================================================
  // TOGGLE BOOKMARK
  // ==========================================================

  Future<void> toggleBookmark(
    int questionId,
  ) async {
    final bookmarkedIds =
        await getBookmarkedQuestionIds();

    if (bookmarkedIds.contains(questionId)) {
      bookmarkedIds.remove(questionId);
    } else {
      bookmarkedIds.add(questionId);
    }

    await _saveBookmarks(bookmarkedIds);
  }

  // ==========================================================
  // COUNT
  // ==========================================================

  Future<int> getBookmarkCount() async {
    final bookmarkedIds =
        await getBookmarkedQuestionIds();

    return bookmarkedIds.length;
  }

  // ==========================================================
  // CLEAR
  // ==========================================================

  Future<void> clearAllBookmarks() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove(_bookmarkKey);
  }

  // ==========================================================
  // SAVE
  // ==========================================================

  Future<void> _saveBookmarks(
    Set<int> bookmarkedIds,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setStringList(
      _bookmarkKey,
      bookmarkedIds
          .map((id) => id.toString())
          .toList(),
    );
  }
}