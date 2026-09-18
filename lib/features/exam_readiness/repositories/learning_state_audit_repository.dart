import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/auth/learner_local_identity.dart';
import '../models/learning_state_update_event.dart';

class LearningStateAuditRepository {
  const LearningStateAuditRepository({this.userIdOverride});

  final String? userIdOverride;

  static String storageKeyForUser(String userId) =>
      'csp11.student.$userId.exam_readiness.learning_state_audit.v1';

  String _requireUserId() =>
      LearnerLocalIdentity.requireCurrentUserId(userIdOverride: userIdOverride);

  Future<List<LearningStateUpdateEvent>> loadAll() async {
    final userId = _requireUserId();
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKeyForUser(userId));
    if (raw == null || raw.trim().isEmpty) {
      return const <LearningStateUpdateEvent>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Iterable) return const <LearningStateUpdateEvent>[];

      final byId = <String, LearningStateUpdateEvent>{};
      for (final item in decoded) {
        if (item is! Map) continue;
        try {
          final event = LearningStateUpdateEvent.fromJson(
            Map<String, dynamic>.from(item),
          );
          if (event.eventId.trim().isNotEmpty) {
            byId.putIfAbsent(event.eventId, () => event);
          }
        } catch (_) {
          // Preserve valid audit events.
        }
      }

      final values = byId.values.toList(growable: false)
        ..sort((left, right) => left.occurredAt.compareTo(right.occurredAt));
      return List<LearningStateUpdateEvent>.unmodifiable(values);
    } catch (_) {
      return const <LearningStateUpdateEvent>[];
    }
  }

  Future<bool> append(LearningStateUpdateEvent event) async {
    if (event.eventId.trim().isEmpty) return false;

    final userId = _requireUserId();
    final values = (await loadAll()).toList(growable: true);
    if (values.any((item) => item.eventId == event.eventId)) return false;

    values.add(event);
    values.sort((left, right) => left.occurredAt.compareTo(right.occurredAt));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      storageKeyForUser(userId),
      jsonEncode(values.map((item) => item.toJson()).toList(growable: false)),
    );
    return true;
  }
}
