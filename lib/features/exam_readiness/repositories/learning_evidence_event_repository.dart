import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/auth/learner_local_identity.dart';
import '../models/learning_evidence_event.dart';

class LearningEvidenceEventRepository {
  const LearningEvidenceEventRepository({this.userIdOverride});

  final String? userIdOverride;

  static String storageKeyForUser(String userId) =>
      'csp11.student.$userId.exam_readiness.learning_evidence_events.v1';

  String _requireUserId() =>
      LearnerLocalIdentity.requireCurrentUserId(userIdOverride: userIdOverride);

  Future<List<LearningEvidenceEvent>> loadAll({String? competencyId}) async {
    final userId = _requireUserId();
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKeyForUser(userId));
    if (raw == null || raw.trim().isEmpty) {
      return const <LearningEvidenceEvent>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Iterable) return const <LearningEvidenceEvent>[];

      final normalizedCompetency = competencyId?.trim().toLowerCase();
      final byId = <String, LearningEvidenceEvent>{};
      for (final item in decoded) {
        if (item is! Map) continue;
        try {
          final event = LearningEvidenceEvent.fromJson(
            Map<String, dynamic>.from(item),
          );
          if (normalizedCompetency != null &&
              normalizedCompetency.isNotEmpty &&
              event.competencyId.trim().toLowerCase() !=
                  normalizedCompetency) {
            continue;
          }
          byId.putIfAbsent(event.evidenceEventId, () => event);
        } catch (_) {
          // One damaged event must not discard valid learner evidence.
        }
      }

      final values = byId.values.toList(growable: false)
        ..sort((left, right) => left.occurredAt.compareTo(right.occurredAt));
      return List<LearningEvidenceEvent>.unmodifiable(values);
    } catch (_) {
      return const <LearningEvidenceEvent>[];
    }
  }

  Future<LearningEvidenceEvent?> loadById(String evidenceEventId) async {
    final id = evidenceEventId.trim();
    if (id.isEmpty) return null;
    final events = await loadAll();
    for (final event in events) {
      if (event.evidenceEventId == id) return event;
    }
    return null;
  }

  Future<bool> append(LearningEvidenceEvent event) async {
    event.validate();
    final userId = _requireUserId();
    final values = (await loadAll()).toList(growable: true);

    for (final existing in values) {
      if (existing.evidenceEventId != event.evidenceEventId) continue;
      if (jsonEncode(existing.toJson()) != jsonEncode(event.toJson())) {
        throw StateError('Learning evidence event identity is immutable.');
      }
      return false;
    }

    values.add(event);
    values.sort((left, right) => left.occurredAt.compareTo(right.occurredAt));

    final prefs = await SharedPreferences.getInstance();
    final saved = await prefs.setString(
      storageKeyForUser(userId),
      jsonEncode(values.map((item) => item.toJson()).toList(growable: false)),
    );
    if (!saved) {
      throw StateError('Learning evidence persistence failed.');
    }
    return true;
  }

  Future<void> clear() async {
    final userId = _requireUserId();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKeyForUser(userId));
  }
}
