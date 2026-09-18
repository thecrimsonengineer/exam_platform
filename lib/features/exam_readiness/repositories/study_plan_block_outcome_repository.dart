import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/auth/learner_local_identity.dart';
import '../models/study_plan_block_outcome.dart';

class StudyPlanBlockOutcomeRepository {
  const StudyPlanBlockOutcomeRepository({this.userIdOverride});

  final String? userIdOverride;

  static String storageKeyForUser(String userId) =>
      'csp11.student.$userId.exam_readiness.block_outcomes.v1';

  String _requireUserId() =>
      LearnerLocalIdentity.requireCurrentUserId(userIdOverride: userIdOverride);

  Future<List<StudyPlanBlockOutcome>> loadAll() async {
    final userId = _requireUserId();
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKeyForUser(userId));
    if (raw == null || raw.trim().isEmpty) {
      return const <StudyPlanBlockOutcome>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Iterable) return const <StudyPlanBlockOutcome>[];

      final byId = <String, StudyPlanBlockOutcome>{};
      for (final item in decoded) {
        if (item is! Map) continue;
        try {
          final outcome = StudyPlanBlockOutcome.fromJson(
            Map<String, dynamic>.from(item),
          );
          byId.putIfAbsent(outcome.outcomeId, () => outcome);
        } catch (_) {
          // One damaged local outcome must not discard valid history.
        }
      }

      final values = byId.values.toList(growable: false)
        ..sort((left, right) => left.completedAt.compareTo(right.completedAt));
      return List<StudyPlanBlockOutcome>.unmodifiable(values);
    } catch (_) {
      return const <StudyPlanBlockOutcome>[];
    }
  }

  Future<bool> append(StudyPlanBlockOutcome outcome) async {
    outcome.validate();
    final userId = _requireUserId();
    final values = (await loadAll()).toList(growable: true);
    if (values.any((item) => item.outcomeId == outcome.outcomeId)) {
      return false;
    }

    values.add(outcome);
    values.sort((left, right) => left.completedAt.compareTo(right.completedAt));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      storageKeyForUser(userId),
      jsonEncode(values.map((item) => item.toJson()).toList(growable: false)),
    );
    return true;
  }

  Future<void> clear() async {
    final userId = _requireUserId();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKeyForUser(userId));
  }
}
