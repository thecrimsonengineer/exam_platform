import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/student_learning_progress.dart';
import 'student_learning_progress_session_cache.dart';
import 'progress_analytics_event_bus.dart';
import 'auth/learner_local_identity.dart';

/// Local persistence for the learner's actual CSP11 study progress.
///
/// Storage identity is two-dimensional:
///
/// 1. Firebase UID selects the learner namespace.
/// 2. Subtopic ID selects the progress record inside that namespace.
///
/// This prevents two accounts on the same phone/browser profile from sharing
/// completion state.
///
/// The pre-UID device-global V1 key is intentionally NOT migrated automatically
/// because the app cannot prove which historical account created it.
class StudentLearningProgressService {
  const StudentLearningProgressService({this.userIdOverride});

  final String? userIdOverride;

  static const String legacyStorageKey = 'csp11.student.learning_progress.v1';

  static String storageKeyForUser(String userId) =>
      'csp11.student.$userId.learning_progress.v2';

  String _requireUserId() {
    return LearnerLocalIdentity.requireCurrentUserId(
      userIdOverride: userIdOverride,
    );
  }

  Future<Map<String, StudentSubtopicProgress>> loadAllProgress() async {
    final userId = _requireUserId();
    return _loadAllProgressForUser(userId);
  }

  Future<Map<String, StudentSubtopicProgress>> _loadAllProgressForUser(
    String userId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKeyForUser(userId));

    if (raw == null || raw.trim().isEmpty) {
      return <String, StudentSubtopicProgress>{};
    }

    try {
      final decoded = jsonDecode(raw);

      if (decoded is! Map) {
        return <String, StudentSubtopicProgress>{};
      }

      final result = <String, StudentSubtopicProgress>{};

      for (final entry in decoded.entries) {
        final value = entry.value;

        if (value is! Map) {
          continue;
        }

        try {
          final record = StudentSubtopicProgress.fromJson(
            Map<String, dynamic>.from(value),
          );

          if (record.subtopicId.isNotEmpty) {
            result[entry.key.toString()] = record;
          }
        } catch (_) {
          // Ignore one malformed record instead of losing the learner's
          // remaining progress.
        }
      }

      return result;
    } catch (_) {
      return <String, StudentSubtopicProgress>{};
    }
  }

  Future<StudentSubtopicProgress?> loadSubtopicProgress({
    required String subtopicId,
    int? expectedContentVersion,
  }) async {
    final userId = _requireUserId();
    final all = await _loadAllProgressForUser(userId);
    final record = all[subtopicId];

    if (record == null) {
      return null;
    }

    if (expectedContentVersion != null &&
        record.studyContentVersion != expectedContentVersion) {
      return null;
    }

    return record;
  }

  Future<void> markInProgress({
    required String domainId,
    required int domainNumber,
    required String domainTitle,
    required String competencyId,
    required String competencyTitle,
    required String subtopicId,
    required String subtopicTitle,
    required String studyContentId,
    required int studyContentVersion,
  }) async {
    if (subtopicId.trim().isEmpty) {
      return;
    }

    final userId = _requireUserId();
    final all = await _loadAllProgressForUser(userId);
    final now = DateTime.now();
    final existing = all[subtopicId];

    // Opening an already completed subtopic must never downgrade it.
    if (existing != null &&
        existing.state == StudentLearningState.completed &&
        existing.studyContentVersion == studyContentVersion) {
      all[subtopicId] = existing.copyWith(lastOpenedAt: now);
    } else {
      all[subtopicId] = StudentSubtopicProgress(
        domainId: domainId,
        domainNumber: domainNumber,
        domainTitle: domainTitle,
        competencyId: competencyId,
        competencyTitle: competencyTitle,
        subtopicId: subtopicId,
        subtopicTitle: subtopicTitle,
        studyContentId: studyContentId,
        studyContentVersion: studyContentVersion,
        state: StudentLearningState.inProgress,
        lastOpenedAt: now,
        completedAt: null,
      );
    }

    await _saveAllProgressForUser(userId, all);
    StudentLearningProgressSessionCache.invalidateCurrentUser();
    ProgressAnalyticsEventBus.markDirty();
  }

  Future<void> completeSubtopic({
    required String domainId,
    required int domainNumber,
    required String domainTitle,
    required String competencyId,
    required String competencyTitle,
    required String subtopicId,
    required String subtopicTitle,
    required String studyContentId,
    required int studyContentVersion,
  }) async {
    if (subtopicId.trim().isEmpty) {
      return;
    }

    final userId = _requireUserId();
    final all = await _loadAllProgressForUser(userId);
    final now = DateTime.now();
    final existing = all[subtopicId];

    final completedAt = existing?.completedAt ?? now;

    all[subtopicId] = StudentSubtopicProgress(
      domainId: domainId,
      domainNumber: domainNumber,
      domainTitle: domainTitle,
      competencyId: competencyId,
      competencyTitle: competencyTitle,
      subtopicId: subtopicId,
      subtopicTitle: subtopicTitle,
      studyContentId: studyContentId,
      studyContentVersion: studyContentVersion,
      state: StudentLearningState.completed,
      lastOpenedAt: now,
      completedAt: completedAt,
      lastCompletedAt: now,
    );

    await _saveAllProgressForUser(userId, all);
    StudentLearningProgressSessionCache.invalidateCurrentUser();
    ProgressAnalyticsEventBus.markDirty();
  }

  Future<void> resetSubtopic(String subtopicId) async {
    if (subtopicId.trim().isEmpty) {
      return;
    }

    final userId = _requireUserId();
    final all = await _loadAllProgressForUser(userId);
    all.remove(subtopicId);

    await _saveAllProgressForUser(userId, all);
    StudentLearningProgressSessionCache.invalidateCurrentUser();
    ProgressAnalyticsEventBus.markDirty();
  }

  /// Clears only the currently active learner's progress.
  Future<void> clearAllProgress() async {
    final userId = _requireUserId();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKeyForUser(userId));
    StudentLearningProgressSessionCache.invalidateCurrentUser();
    ProgressAnalyticsEventBus.markDirty();
  }

  Future<StudentProgressSummary> summarizeSubtopics(
    Iterable<String> subtopicIds,
  ) async {
    final userId = _requireUserId();
    final all = await _loadAllProgressForUser(userId);

    final states = subtopicIds.map(
      (id) => all[id]?.state ?? StudentLearningState.notStarted,
    );

    return StudentProgressSummary.fromStates(states);
  }

  Future<void> _saveAllProgressForUser(
    String userId,
    Map<String, StudentSubtopicProgress> progress,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      storageKeyForUser(userId),
      encodeStudentProgressMap(progress),
    );
  }
}
