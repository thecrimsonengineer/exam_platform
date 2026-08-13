import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/student_learning_progress.dart';

/// Local persistence for the learner's actual CSP11 study progress.
///
/// This deliberately lives beside, rather than inside,
/// StudentLearningPositionService:
///
/// - learning position = where the learner last opened
/// - learning progress = what the learner has actually started/completed
///
/// The storage contract is local today and can later be replaced by a
/// remote learner-progress repository without changing the student UI.
class StudentLearningProgressService {
  const StudentLearningProgressService();

  static const String _storageKey = 'csp11.student.learning_progress.v1';

  Future<Map<String, StudentSubtopicProgress>> loadAllProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);

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
          // Ignore a malformed individual record rather than losing
          // the learner's other progress.
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
    final all = await loadAllProgress();
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

    final all = await loadAllProgress();
    final now = DateTime.now();
    final existing = all[subtopicId];

    // Opening an already completed subtopic must never downgrade
    // it back to "In Progress".
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

    await _saveAllProgress(all);
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

    final all = await loadAllProgress();
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
    );

    await _saveAllProgress(all);
  }

  Future<void> resetSubtopic(String subtopicId) async {
    if (subtopicId.trim().isEmpty) {
      return;
    }

    final all = await loadAllProgress();
    all.remove(subtopicId);

    await _saveAllProgress(all);
  }

  Future<void> clearAllProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  Future<StudentProgressSummary> summarizeSubtopics(
    Iterable<String> subtopicIds,
  ) async {
    final all = await loadAllProgress();

    final states = subtopicIds.map(
      (id) => all[id]?.state ?? StudentLearningState.notStarted,
    );

    return StudentProgressSummary.fromStates(states);
  }

  Future<void> _saveAllProgress(
    Map<String, StudentSubtopicProgress> progress,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_storageKey, encodeStudentProgressMap(progress));
  }
}
