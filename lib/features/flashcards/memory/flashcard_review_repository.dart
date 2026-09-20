import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'flashcard_review_state.dart';

abstract class FlashcardReviewRepository {
  Future<FlashcardReviewState?> load({
    required String learnerId,
    required String cardId,
  });

  Future<List<FlashcardReviewState>> loadAll({
    required String learnerId,
  });

  Future<void> save({
    required String learnerId,
    required FlashcardReviewState state,
  });

  Future<void> delete({
    required String learnerId,
    required String cardId,
  });
}

class MemoryFlashcardReviewRepository implements FlashcardReviewRepository {
  final Map<String, Map<String, FlashcardReviewState>> _byLearner =
      <String, Map<String, FlashcardReviewState>>{};

  @override
  Future<FlashcardReviewState?> load({
    required String learnerId,
    required String cardId,
  }) async {
    return _byLearner[learnerId]?[cardId];
  }

  @override
  Future<List<FlashcardReviewState>> loadAll({
    required String learnerId,
  }) async {
    final records =
        _byLearner[learnerId]?.values.toList() ?? <FlashcardReviewState>[];
    records.sort((a, b) => a.cardId.compareTo(b.cardId));
    return List.unmodifiable(records);
  }

  @override
  Future<void> save({
    required String learnerId,
    required FlashcardReviewState state,
  }) async {
    _validateIdentity(learnerId: learnerId, cardId: state.cardId);
    state.validate();
    final bucket = _byLearner.putIfAbsent(
      learnerId,
      () => <String, FlashcardReviewState>{},
    );
    bucket[state.cardId] = state;
  }

  @override
  Future<void> delete({
    required String learnerId,
    required String cardId,
  }) async {
    _byLearner[learnerId]?.remove(cardId);
  }
}

class SharedPreferencesFlashcardReviewRepository
    implements FlashcardReviewRepository {
  static String indexKeyForLearner(String learnerId) =>
      'csp11.student.$learnerId.flashcards.memory.index.v1';

  static String stateKeyForLearner({
    required String learnerId,
    required String cardId,
  }) => 'csp11.student.$learnerId.flashcards.memory.v1.$cardId';

  @override
  Future<FlashcardReviewState?> load({
    required String learnerId,
    required String cardId,
  }) async {
    _validateIdentity(learnerId: learnerId, cardId: cardId);
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(
      stateKeyForLearner(learnerId: learnerId, cardId: cardId),
    );
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw FormatException(
        'Flashcard review state must be a JSON object: $cardId',
      );
    }

    final state = FlashcardReviewState.fromJson(
      Map<String, dynamic>.from(decoded),
    );
    if (state.cardId != cardId) {
      throw FormatException(
        'Flashcard memory key/card mismatch: $cardId',
      );
    }
    return state;
  }

  @override
  Future<List<FlashcardReviewState>> loadAll({
    required String learnerId,
  }) async {
    _validateIdentity(learnerId: learnerId, cardId: 'index');
    final prefs = await SharedPreferences.getInstance();
    final ids =
        prefs.getStringList(indexKeyForLearner(learnerId)) ?? <String>[];
    final uniqueIds = ids.toSet().toList()..sort();
    final records = <FlashcardReviewState>[];

    for (final cardId in uniqueIds) {
      final state = await load(learnerId: learnerId, cardId: cardId);
      if (state == null) {
        throw FormatException(
          'Flashcard memory index references missing state: $cardId',
        );
      }
      records.add(state);
    }

    return List.unmodifiable(records);
  }

  @override
  Future<void> save({
    required String learnerId,
    required FlashcardReviewState state,
  }) async {
    _validateIdentity(learnerId: learnerId, cardId: state.cardId);
    state.validate();

    final prefs = await SharedPreferences.getInstance();
    final key = stateKeyForLearner(
      learnerId: learnerId,
      cardId: state.cardId,
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
        'Unable to persist Flashcard review state ${state.cardId}.',
      );
    }

    final nextIndex = <String>{...oldIndex, state.cardId}.toList()..sort();
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
        'Unable to persist Flashcard memory index for $learnerId.',
      );
    }
  }

  @override
  Future<void> delete({
    required String learnerId,
    required String cardId,
  }) async {
    _validateIdentity(learnerId: learnerId, cardId: cardId);
    final prefs = await SharedPreferences.getInstance();
    final indexKey = indexKeyForLearner(learnerId);
    final ids = prefs.getStringList(indexKey) ?? <String>[];

    await prefs.remove(
      stateKeyForLearner(learnerId: learnerId, cardId: cardId),
    );
    ids.removeWhere((id) => id == cardId);
    await prefs.setStringList(indexKey, ids.toSet().toList()..sort());
  }
}

void _validateIdentity({
  required String learnerId,
  required String cardId,
}) {
  if (learnerId.trim().isEmpty) {
    throw const FormatException('Flashcard memory learner ID is required.');
  }
  if (cardId.trim().isEmpty) {
    throw const FormatException('Flashcard memory card ID is required.');
  }
}
