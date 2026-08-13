import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/student_topic_bookmark.dart';

class StudentTopicBookmarkService {
  const StudentTopicBookmarkService();

  static const String _storageKey =
      'csp11.student.topic_bookmarks.v1';

  Future<List<StudentTopicBookmark>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);

    if (raw == null || raw.trim().isEmpty) {
      return const [];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const [];
      }

      return decoded
          .whereType<Map>()
          .map(
            (item) => StudentTopicBookmark.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .where((item) => item.storageId.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<bool> isBookmarked({
    required String contentId,
    required String subtopicId,
    required String topicId,
  }) async {
    final key = '$contentId::$subtopicId::$topicId';
    final items = await loadAll();
    return items.any((item) => item.storageId == key);
  }

  Future<void> save({
    required String contentId,
    required String subtopicId,
    required String topicId,
    required String topicTitle,
  }) async {
    final items = await loadAll();
    final key = '$contentId::$subtopicId::$topicId';

    if (items.any((item) => item.storageId == key)) {
      return;
    }

    items.insert(
      0,
      StudentTopicBookmark(
        contentId: contentId,
        subtopicId: subtopicId,
        topicId: topicId,
        topicTitle: topicTitle,
        savedAt: DateTime.now(),
      ),
    );

    await _save(items);
  }

  Future<void> remove({
    required String contentId,
    required String subtopicId,
    required String topicId,
  }) async {
    final key = '$contentId::$subtopicId::$topicId';
    final items = await loadAll()
      ..removeWhere((item) => item.storageId == key);

    await _save(items);
  }

  Future<void> _save(List<StudentTopicBookmark> items) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _storageKey,
      jsonEncode(items.map((item) => item.toJson()).toList()),
    );
  }
}
