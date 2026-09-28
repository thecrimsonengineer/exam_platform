import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/auth/learner_local_identity.dart';
import 'flashcard_recall_event.dart';

class FlashcardRecallEventRepository {
  const FlashcardRecallEventRepository({this.userIdOverride});

  final String? userIdOverride;

  static String storageKeyForUser(String userId) =>
      'csp11.student.$userId.flashcards.recall_events.v1';

  String _requireUserId() =>
      LearnerLocalIdentity.requireCurrentUserId(userIdOverride: userIdOverride);

  Future<List<FlashcardRecallEvent>> loadAll({
    String? competencyId,
    String? cardId,
    String? sessionId,
  }) async {
    final userId = _requireUserId();
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKeyForUser(userId));
    if (raw == null || raw.trim().isEmpty) {
      return const <FlashcardRecallEvent>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Iterable) return const <FlashcardRecallEvent>[];

      final normalizedCompetency = competencyId?.trim().toLowerCase();
      final normalizedCardId = cardId?.trim();
      final normalizedSessionId = sessionId?.trim();
      final byId = <String, FlashcardRecallEvent>{};

      for (final item in decoded) {
        if (item is! Map) continue;
        try {
          final event = FlashcardRecallEvent.fromJson(
            Map<String, dynamic>.from(item),
          );
          if (normalizedCompetency != null &&
              normalizedCompetency.isNotEmpty &&
              event.competencyId != normalizedCompetency) {
            continue;
          }
          if (normalizedCardId != null &&
              normalizedCardId.isNotEmpty &&
              event.cardId != normalizedCardId) {
            continue;
          }
          if (normalizedSessionId != null &&
              normalizedSessionId.isNotEmpty &&
              event.sessionId != normalizedSessionId) {
            continue;
          }
          byId.putIfAbsent(event.eventId, () => event);
        } catch (_) {
          // One damaged recall event must not discard valid learner history.
        }
      }

      final values = byId.values.toList(growable: false)
        ..sort((left, right) => left.occurredAt.compareTo(right.occurredAt));
      return List<FlashcardRecallEvent>.unmodifiable(values);
    } catch (_) {
      return const <FlashcardRecallEvent>[];
    }
  }

  Future<FlashcardRecallEvent?> latestForCard({
    required String competencyId,
    required String cardId,
  }) async {
    final events = await loadAll(competencyId: competencyId, cardId: cardId);
    return events.isEmpty ? null : events.last;
  }

  Future<bool> append(FlashcardRecallEvent event) async {
    event.validate();
    final userId = _requireUserId();
    final values = (await loadAll()).toList(growable: true);

    for (final existing in values) {
      if (existing.eventId != event.eventId) continue;
      if (jsonEncode(existing.toJson()) != jsonEncode(event.toJson())) {
        throw StateError('Flashcard recall event identity is immutable.');
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
      throw StateError('Flashcard recall persistence failed.');
    }
    return true;
  }

  Future<void> clear() async {
    final userId = _requireUserId();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKeyForUser(userId));
  }
}
