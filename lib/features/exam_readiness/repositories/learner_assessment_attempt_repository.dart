import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/auth/learner_local_identity.dart';
import '../models/learner_assessment_attempt.dart';

class LearnerAssessmentAttemptRepository {
  const LearnerAssessmentAttemptRepository({this.userIdOverride});

  final String? userIdOverride;

  static String storageKeyForUser(String userId) =>
      'csp11.student.$userId.exam_readiness.assessment_attempts.v1';

  String _requireUserId() {
    return LearnerLocalIdentity.requireCurrentUserId(
      userIdOverride: userIdOverride,
    );
  }

  Future<List<LearnerAssessmentAttempt>> loadAll() async {
    final userId = _requireUserId();
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKeyForUser(userId));

    if (raw == null || raw.trim().isEmpty) {
      return const <LearnerAssessmentAttempt>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <LearnerAssessmentAttempt>[];
      }

      final byId = <String, LearnerAssessmentAttempt>{};

      for (final item in decoded) {
        if (item is! Map) {
          continue;
        }

        try {
          final attempt = LearnerAssessmentAttempt.fromJson(
            Map<String, dynamic>.from(item),
          );

          if (attempt.attemptId.trim().isEmpty || attempt.questionId <= 0) {
            continue;
          }

          byId.putIfAbsent(attempt.attemptId, () => attempt);
        } catch (_) {
          // One malformed attempt must not discard the rest of the ledger.
        }
      }

      final attempts = byId.values.toList(growable: false)
        ..sort((left, right) => left.answeredAt.compareTo(right.answeredAt));

      return List<LearnerAssessmentAttempt>.unmodifiable(attempts);
    } catch (_) {
      return const <LearnerAssessmentAttempt>[];
    }
  }

  Future<bool> append(LearnerAssessmentAttempt attempt) async {
    if (attempt.attemptId.trim().isEmpty || attempt.questionId <= 0) {
      return false;
    }

    final userId = _requireUserId();
    final current = (await loadAll()).toList(growable: true);

    if (current.any((item) => item.attemptId == attempt.attemptId)) {
      return false;
    }

    current.add(attempt);
    current.sort((left, right) => left.answeredAt.compareTo(right.answeredAt));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      storageKeyForUser(userId),
      jsonEncode(current.map((item) => item.toJson()).toList()),
    );

    return true;
  }

  Future<void> clear() async {
    final userId = _requireUserId();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKeyForUser(userId));
  }
}
