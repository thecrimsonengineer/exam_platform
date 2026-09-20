import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'flashcard_review_session_state.dart';

abstract class FlashcardReviewSessionRepository {
  Future<FlashcardReviewSessionState?> load({
    required String learnerId,
    required String sessionId,
  });

  Future<List<String>> listSessionIds({
    required String learnerId,
  });

  Future<void> save({
    required String learnerId,
    required FlashcardReviewSessionState state,
  });

  Future<void> delete({
    required String learnerId,
    required String sessionId,
  });
}

class MemoryFlashcardReviewSessionRepository
    implements FlashcardReviewSessionRepository {
  final Map<String, Map<String, FlashcardReviewSessionState>> _byLearner =
      <String, Map<String, FlashcardReviewSessionState>>{};

  @override
  Future<FlashcardReviewSessionState?> load({
    required String learnerId,
    required String sessionId,
  }) async {
    return _byLearner[learnerId]?[sessionId];
  }

  @override
  Future<List<String>> listSessionIds({
    required String learnerId,
  }) async {
    final ids = _byLearner[learnerId]?.keys.toList() ?? <String>[];
    ids.sort();
    return List.unmodifiable(ids);
  }

  @override
  Future<void> save({
    required String learnerId,
    required FlashcardReviewSessionState state,
  }) async {
    state.validate();
    final bucket = _byLearner.putIfAbsent(
      learnerId,
      () => <String, FlashcardReviewSessionState>{},
    );
    bucket[state.sessionId] = state;
  }

  @override
  Future<void> delete({
    required String learnerId,
    required String sessionId,
  }) async {
    _byLearner[learnerId]?.remove(sessionId);
  }
}

class SharedPreferencesFlashcardReviewSessionRepository
    implements FlashcardReviewSessionRepository {
  static String indexKeyForLearner(String learnerId) =>
      'csp11.student.$learnerId.flashcards.review_sessions.index.v1';

  static String stateKeyForLearner({
    required String learnerId,
    required String sessionId,
  }) => 'csp11.student.$learnerId.flashcards.review_session.v1.$sessionId';

  @override
  Future<FlashcardReviewSessionState?> load({
    required String learnerId,
    required String sessionId,
  }) async {
    _validate(learnerId: learnerId, sessionId: sessionId);
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(
      stateKeyForLearner(
        learnerId: learnerId,
        sessionId: sessionId,
      ),
    );
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw FormatException(
        'Flashcard review session must be a JSON object: $sessionId',
      );
    }

    final state = FlashcardReviewSessionState.fromJson(
      Map<String, dynamic>.from(decoded),
    );
    if (state.sessionId != sessionId) {
      throw FormatException(
        'Flashcard review session key/identity mismatch: $sessionId',
      );
    }
    return state;
  }

  @override
  Future<List<String>> listSessionIds({
    required String learnerId,
  }) async {
    _validate(learnerId: learnerId, sessionId: 'index');
    final prefs = await SharedPreferences.getInstance();
    final ids =
        prefs.getStringList(indexKeyForLearner(learnerId)) ?? <String>[];
    final unique = ids.toSet().toList()..sort();
    return List.unmodifiable(unique);
  }

  @override
  Future<void> save({
    required String learnerId,
    required FlashcardReviewSessionState state,
  }) async {
    _validate(learnerId: learnerId, sessionId: state.sessionId);
    state.validate();

    final prefs = await SharedPreferences.getInstance();
    final key = stateKeyForLearner(
      learnerId: learnerId,
      sessionId: state.sessionId,
    );
    final oldRaw = prefs.getString(key);
    final oldIndex =
        prefs.getStringList(indexKeyForLearner(learnerId)) ?? <String>[];

    final wroteState = await prefs.setString(
      key,
      jsonEncode(state.toJson()),
    );
    if (!wroteState) {
      throw StateError(
        'Unable to persist Flashcard review session '
        '${state.sessionId}.',
      );
    }

    final nextIndex = <String>{...oldIndex, state.sessionId}.toList()
      ..sort();
    final wroteIndex = await prefs.setStringList(
      indexKeyForLearner(learnerId),
      nextIndex,
    );
    if (!wroteIndex) {
      if (oldRaw == null) {
        await prefs.remove(key);
      } else {
        await prefs.setString(key, oldRaw);
      }
      throw StateError(
        'Unable to persist Flashcard review session index for $learnerId.',
      );
    }
  }

  @override
  Future<void> delete({
    required String learnerId,
    required String sessionId,
  }) async {
    _validate(learnerId: learnerId, sessionId: sessionId);
    final prefs = await SharedPreferences.getInstance();
    final indexKey = indexKeyForLearner(learnerId);
    final ids = prefs.getStringList(indexKey) ?? <String>[];

    await prefs.remove(
      stateKeyForLearner(
        learnerId: learnerId,
        sessionId: sessionId,
      ),
    );
    ids.removeWhere((id) => id == sessionId);
    await prefs.setStringList(indexKey, ids.toSet().toList()..sort());
  }

  static void _validate({
    required String learnerId,
    required String sessionId,
  }) {
    if (learnerId.trim().isEmpty) {
      throw const FormatException(
        'Flashcard review session learner ID is required.',
      );
    }
    if (sessionId.trim().isEmpty) {
      throw const FormatException(
        'Flashcard review session ID is required.',
      );
    }
  }
}
