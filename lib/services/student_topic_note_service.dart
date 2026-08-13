import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/student_topic_note.dart';

class StudentTopicNoteService {
  const StudentTopicNoteService();

  static const String _storageKey =
      'csp11.student.topic_notes.v1';

  Future<StudentTopicNote?> load({
    required String contentId,
    required String subtopicId,
    required String topicId,
  }) async {
    final all = await loadAll();
    final key = '$contentId::$subtopicId::$topicId';

    for (final note in all) {
      if (note.storageId == key) {
        return note;
      }
    }

    return null;
  }

  Future<List<StudentTopicNote>> loadAll() async {
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
            (item) => StudentTopicNote.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .where((item) => item.storageId.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> save({
    required String contentId,
    required String subtopicId,
    required String topicId,
    required String topicTitle,
    required String note,
  }) async {
    final items = await loadAll();
    final key = '$contentId::$subtopicId::$topicId';

    items.removeWhere((item) => item.storageId == key);

    if (note.trim().isNotEmpty) {
      items.insert(
        0,
        StudentTopicNote(
          contentId: contentId,
          subtopicId: subtopicId,
          topicId: topicId,
          topicTitle: topicTitle,
          note: note.trim(),
          updatedAt: DateTime.now(),
        ),
      );
    }

    await _save(items);
  }

  Future<void> _save(List<StudentTopicNote> items) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _storageKey,
      jsonEncode(items.map((item) => item.toJson()).toList()),
    );
  }
}
