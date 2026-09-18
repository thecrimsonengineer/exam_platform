import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/auth/learner_local_identity.dart';
import '../models/readiness_trajectory_point.dart';

class ReadinessHistoryRepository {
  const ReadinessHistoryRepository({this.userIdOverride});

  final String? userIdOverride;

  static String storageKeyForUser(String userId) =>
      'csp11.student.$userId.exam_readiness.readiness_history.v1';

  String _requireUserId() =>
      LearnerLocalIdentity.requireCurrentUserId(userIdOverride: userIdOverride);

  Future<List<ReadinessTrajectoryPoint>> loadAll() async {
    final userId = _requireUserId();
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKeyForUser(userId));
    if (raw == null || raw.trim().isEmpty) {
      return const <ReadinessTrajectoryPoint>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Iterable) return const <ReadinessTrajectoryPoint>[];

      final byDay = <String, ReadinessTrajectoryPoint>{};
      for (final item in decoded) {
        if (item is! Map) continue;
        try {
          final point = ReadinessTrajectoryPoint.fromJson(
            Map<String, dynamic>.from(item),
          );
          byDay[_dayKey(point.date)] = point;
        } catch (_) {
          // Preserve valid local trajectory history.
        }
      }

      final values = byDay.values.toList(growable: false)
        ..sort((left, right) => left.date.compareTo(right.date));
      return List<ReadinessTrajectoryPoint>.unmodifiable(values);
    } catch (_) {
      return const <ReadinessTrajectoryPoint>[];
    }
  }

  Future<void> saveDaily(ReadinessTrajectoryPoint point) async {
    final userId = _requireUserId();
    final current = {
      for (final item in await loadAll()) _dayKey(item.date): item,
    };
    current[_dayKey(point.date)] = point;

    final values = current.values.toList(growable: false)
      ..sort((left, right) => left.date.compareTo(right.date));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      storageKeyForUser(userId),
      jsonEncode(values.map((item) => item.toJson()).toList(growable: false)),
    );
  }

  Future<void> clear() async {
    final userId = _requireUserId();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKeyForUser(userId));
  }

  String _dayKey(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
