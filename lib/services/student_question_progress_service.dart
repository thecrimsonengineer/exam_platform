import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../features/exam_readiness/models/learner_assessment_attempt.dart';
import '../features/exam_readiness/repositories/learner_assessment_attempt_repository.dart';
import '../models/question.dart';
import '../models/student_question_progress.dart';
import 'auth/learner_local_identity.dart';
import 'progress_analytics_event_bus.dart';

/// UID-scoped local record of CSP11 questions the learner has submitted.
///
/// "Completed question" means a unique Question ID for which the learner has
/// submitted at least one answer. Re-answering the same question increments
/// [attemptCount] but does not inflate the completed-question count.
///
/// This service is deliberately local-only. It follows the frozen learner data
/// boundary:
///
/// Firebase UID -> local namespace -> Question ID.
class StudentQuestionProgressService {
  const StudentQuestionProgressService({this.userIdOverride});

  final String? userIdOverride;

  static String storageKeyForUser(String userId) =>
      'csp11.student.$userId.question_progress.v1';

  String _requireUserId() {
    return LearnerLocalIdentity.requireCurrentUserId(
      userIdOverride: userIdOverride,
    );
  }

  Future<Map<int, StudentQuestionProgress>> loadAllProgress() async {
    final userId = _requireUserId();
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKeyForUser(userId));

    if (raw == null || raw.trim().isEmpty) {
      return <int, StudentQuestionProgress>{};
    }

    try {
      final decoded = jsonDecode(raw);

      if (decoded is! Map) {
        return <int, StudentQuestionProgress>{};
      }

      final result = <int, StudentQuestionProgress>{};

      for (final entry in decoded.entries) {
        if (entry.value is! Map) {
          continue;
        }

        try {
          final record = StudentQuestionProgress.fromJson(
            Map<String, dynamic>.from(entry.value as Map),
          );

          if (record.questionId > 0) {
            result[record.questionId] = record;
          }
        } catch (_) {
          // One damaged local record must not discard all question history.
        }
      }

      return result;
    } catch (_) {
      return <int, StudentQuestionProgress>{};
    }
  }

  Future<void> recordAnswer({
    required Question question,
    required bool correct,
    LearnerConfidenceLevel? confidence,
    String sessionKind = 'practice',
  }) async {
    if (question.id <= 0) {
      return;
    }

    final userId = _requireUserId();
    final all = await loadAllProgress();
    final now = DateTime.now();
    final existing = all[question.id];

    if (existing == null) {
      all[question.id] = StudentQuestionProgress(
        questionId: question.id,
        domainNumber: question.domain,
        competencyId: question.competencyId,
        topicId: question.topicId,
        subtopicId: question.subtopicId,
        attemptCount: 1,
        lastCorrect: correct,
        everCorrect: correct,
        firstAnsweredAt: now,
        lastAnsweredAt: now,
      );
    } else {
      all[question.id] = existing.recordAttempt(
        correct: correct,
        answeredAt: now,
        domainNumber: question.domain,
        competencyId: question.competencyId,
        topicId: question.topicId,
        subtopicId: question.subtopicId,
      );
    }

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      storageKeyForUser(userId),
      jsonEncode(
        all.map(
          (questionId, record) =>
              MapEntry(questionId.toString(), record.toJson()),
        ),
      ),
    );

    try {
      final attempt = LearnerAssessmentAttempt.fromQuestion(
        question: question,
        correct: correct,
        answeredAt: now,
        confidence: confidence,
        sessionKind: sessionKind,
      );
      await LearnerAssessmentAttemptRepository(
        userIdOverride: userId,
      ).append(attempt);
    } catch (_) {
      // M7B evidence capture must never interrupt active quiz persistence.
    }

    ProgressAnalyticsEventBus.markDirty();
  }

  /// Clears only the active learner's local question-completion history.
  Future<void> clearAllProgress() async {
    final userId = _requireUserId();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKeyForUser(userId));
    ProgressAnalyticsEventBus.markDirty();
  }
}
