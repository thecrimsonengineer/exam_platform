import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/student_topic_progress.dart';

/// Persists completion of individual Main Content topics.
class StudentTopicProgressService {
  const StudentTopicProgressService();

  static const String _storageKey =
      'csp11.student.topic_progress.v1';

  Future<Map<String, StudentTopicProgress>> loadAllProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);

    if (raw == null || raw.trim().isEmpty) {
      return <String, StudentTopicProgress>{};
    }

    try {
      final decoded = jsonDecode(raw);

      if (decoded is! Map) {
        return <String, StudentTopicProgress>{};
      }

      final result = <String, StudentTopicProgress>{};

      for (final entry in decoded.entries) {
        if (entry.value is! Map) {
          continue;
        }

        try {
          final record = StudentTopicProgress.fromJson(
            Map<String, dynamic>.from(entry.value as Map),
          );

          if (record.storageId.isNotEmpty) {
            result[record.storageId] = record;
          }
        } catch (_) {
          // Ignore malformed individual records.
        }
      }

      return result;
    } catch (_) {
      return <String, StudentTopicProgress>{};
    }
  }

  Future<StudentTopicProgress?> loadTopicProgress({
    required String contentId,
    required int contentVersion,
    required String subtopicId,
    required String topicId,
  }) async {
    final all = await loadAllProgress();
    final key = '$contentId::$subtopicId::$topicId';
    final record = all[key];

    if (record == null || record.contentVersion != contentVersion) {
      return null;
    }

    return record;
  }

  Future<void> completeTopic({
    required String contentId,
    required int contentVersion,
    required String subtopicId,
    required String topicId,
    required String topicTitle,
  }) async {
    if (contentId.trim().isEmpty ||
        subtopicId.trim().isEmpty ||
        topicId.trim().isEmpty) {
      return;
    }

    final all = await loadAllProgress();
    final key = '$contentId::$subtopicId::$topicId';
    final existing = all[key];

    all[key] = StudentTopicProgress(
      contentId: contentId,
      contentVersion: contentVersion,
      subtopicId: subtopicId,
      topicId: topicId,
      topicTitle: topicTitle,
      state: StudentTopicLearningState.completed,
      completedAt: existing?.completedAt ?? DateTime.now(),
    );

    await _save(all);
  }

  Future<void> resetTopic({
    required String contentId,
    required String subtopicId,
    required String topicId,
  }) async {
    final all = await loadAllProgress();
    all.remove('$contentId::$subtopicId::$topicId');
    await _save(all);
  }

  Future<void> clearAllProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  Future<void> _save(
    Map<String, StudentTopicProgress> progress,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    final encoded = <String, dynamic>{
      for (final entry in progress.entries)
        entry.key: entry.value.toJson(),
    };

    await prefs.setString(_storageKey, jsonEncode(encoded));
  }
}
