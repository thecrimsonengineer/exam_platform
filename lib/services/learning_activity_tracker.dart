import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'auth/learner_local_identity.dart';

/// UID-scoped foreground app-time tracker.
///
/// It records time while the learner shell is in the foreground. Background
/// time is excluded. Data is local-only and stored as daily second buckets.
class LearningActivityTracker {
  LearningActivityTracker._();

  static final LearningActivityTracker instance = LearningActivityTracker._();

  static String storageKeyForUser(String userId) =>
      'csp11.student.$userId.app_activity.v1';

  Timer? _timer;
  DateTime? _lastTick;
  String? _userId;
  bool _running = false;

  Future<void> start() async {
    if (_running) {
      return;
    }

    final userId = LearnerLocalIdentity.currentUserId?.trim();
    if (userId == null || userId.isEmpty) {
      return;
    }

    _userId = userId;
    _running = true;
    _lastTick = DateTime.now();

    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => unawaited(_flushElapsed()),
    );
  }

  Future<void> resume() async {
    await start();
  }

  Future<void> pause() async {
    if (!_running) {
      return;
    }

    await _flushElapsed();
    _running = false;
    _lastTick = null;
    _timer?.cancel();
    _timer = null;
  }

  Future<void> dispose() async {
    await pause();
    _userId = null;
  }

  Future<void> _flushElapsed() async {
    if (!_running || _lastTick == null || _userId == null) {
      return;
    }

    final now = DateTime.now();
    var elapsed = now.difference(_lastTick!).inSeconds;
    _lastTick = now;

    if (elapsed <= 0) {
      return;
    }

    // Protect against browser timer throttling producing giant jumps.
    if (elapsed > 120) {
      elapsed = 120;
    }

    final prefs = await SharedPreferences.getInstance();
    final key = storageKeyForUser(_userId!);
    final map = _decode(prefs.getString(key));
    final day = dateKey(now);

    map[day] = (map[day] ?? 0) + elapsed;

    await prefs.setString(key, jsonEncode(map));
  }

  Future<Map<String, int>> loadDailySeconds({
    String? userIdOverride,
    int days = 7,
    DateTime? now,
  }) async {
    final userId = userIdOverride?.trim().isNotEmpty == true
        ? userIdOverride!.trim()
        : LearnerLocalIdentity.requireCurrentUserId();

    final prefs = await SharedPreferences.getInstance();
    final stored = _decode(prefs.getString(storageKeyForUser(userId)));
    final anchor = now ?? DateTime.now();

    final result = <String, int>{};

    for (var offset = days - 1; offset >= 0; offset--) {
      final date = DateTime(
        anchor.year,
        anchor.month,
        anchor.day,
      ).subtract(Duration(days: offset));
      final key = dateKey(date);
      result[key] = stored[key] ?? 0;
    }

    return result;
  }

  static String dateKey(DateTime value) {
    final local = value.toLocal();
    final year = local.year.toString().padLeft(4, '0');
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  static Map<String, int> _decode(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return <String, int>{};
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return <String, int>{};
      }

      final result = <String, int>{};

      for (final entry in decoded.entries) {
        final value = entry.value;
        final seconds = value is num
            ? value.toInt()
            : int.tryParse(value?.toString() ?? '') ?? 0;

        if (seconds > 0) {
          result[entry.key.toString()] = seconds;
        }
      }

      return result;
    } catch (_) {
      return <String, int>{};
    }
  }
}
