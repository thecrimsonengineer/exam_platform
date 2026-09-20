import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'flashcard_ownership.dart';

abstract class FlashcardCollectionRepository {
  Future<FlashcardOwnership?> loadOwnership({
    required String learnerId,
    required String cardId,
  });

  Future<List<FlashcardOwnership>> loadAllOwnership({
    required String learnerId,
  });

  Future<void> saveOwnership({
    required String learnerId,
    required FlashcardOwnership ownership,
  });

  Future<void> clearLearnerCollection({
    required String learnerId,
  });
}

class MemoryFlashcardCollectionRepository
    implements FlashcardCollectionRepository {
  final Map<String, Map<String, FlashcardOwnership>> _byLearner =
      <String, Map<String, FlashcardOwnership>>{};

  @override
  Future<FlashcardOwnership?> loadOwnership({
    required String learnerId,
    required String cardId,
  }) async {
    return _byLearner[learnerId]?[cardId];
  }

  @override
  Future<List<FlashcardOwnership>> loadAllOwnership({
    required String learnerId,
  }) async {
    final records = _byLearner[learnerId]?.values.toList() ??
        <FlashcardOwnership>[];
    records.sort((a, b) => a.cardId.compareTo(b.cardId));
    return List.unmodifiable(records);
  }

  @override
  Future<void> saveOwnership({
    required String learnerId,
    required FlashcardOwnership ownership,
  }) async {
    final learner = _byLearner.putIfAbsent(
      learnerId,
      () => <String, FlashcardOwnership>{},
    );
    learner[ownership.cardId] = ownership;
  }

  @override
  Future<void> clearLearnerCollection({
    required String learnerId,
  }) async {
    _byLearner.remove(learnerId);
  }
}

class SharedPreferencesFlashcardCollectionRepository
    implements FlashcardCollectionRepository {
  static String indexKeyForLearner(String learnerId) =>
      'csp11.student.$learnerId.flashcards.collection.index.v1';

  static String ownershipKeyForLearner({
    required String learnerId,
    required String cardId,
  }) =>
      'csp11.student.$learnerId.flashcards.ownership.v1.$cardId';

  @override
  Future<FlashcardOwnership?> loadOwnership({
    required String learnerId,
    required String cardId,
  }) async {
    _validateIdentity(learnerId: learnerId, cardId: cardId);

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(
      ownershipKeyForLearner(learnerId: learnerId, cardId: cardId),
    );
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    return _decodeOwnership(raw, expectedCardId: cardId);
  }

  @override
  Future<List<FlashcardOwnership>> loadAllOwnership({
    required String learnerId,
  }) async {
    _validateIdentity(learnerId: learnerId, cardId: 'index');

    final prefs = await SharedPreferences.getInstance();
    final ids =
        prefs.getStringList(indexKeyForLearner(learnerId)) ?? <String>[];
    final uniqueIds = ids.toSet().toList()..sort();
    final records = <FlashcardOwnership>[];

    for (final cardId in uniqueIds) {
      final raw = prefs.getString(
        ownershipKeyForLearner(learnerId: learnerId, cardId: cardId),
      );
      if (raw == null || raw.trim().isEmpty) {
        throw FormatException(
          'Flashcard collection index references missing ownership: $cardId',
        );
      }
      records.add(_decodeOwnership(raw, expectedCardId: cardId));
    }

    return List.unmodifiable(records);
  }

  @override
  Future<void> saveOwnership({
    required String learnerId,
    required FlashcardOwnership ownership,
  }) async {
    _validateIdentity(learnerId: learnerId, cardId: ownership.cardId);

    final prefs = await SharedPreferences.getInstance();
    final ownershipKey = ownershipKeyForLearner(
      learnerId: learnerId,
      cardId: ownership.cardId,
    );
    final oldRaw = prefs.getString(ownershipKey);
    final oldIndex =
        prefs.getStringList(indexKeyForLearner(learnerId)) ?? <String>[];

    final wroteOwnership = await prefs.setString(
      ownershipKey,
      jsonEncode(ownership.toJson()),
    );
    if (!wroteOwnership) {
      throw StateError(
        'Unable to persist Flashcard ownership ${ownership.cardId}.',
      );
    }

    final nextIndex = <String>{...oldIndex, ownership.cardId}.toList()..sort();
    final wroteIndex = await prefs.setStringList(
      indexKeyForLearner(learnerId),
      nextIndex,
    );

    if (!wroteIndex) {
      if (oldRaw == null) {
        await prefs.remove(ownershipKey);
      } else {
        await prefs.setString(ownershipKey, oldRaw);
      }
      throw StateError(
        'Unable to persist Flashcard collection index for $learnerId.',
      );
    }
  }

  @override
  Future<void> clearLearnerCollection({
    required String learnerId,
  }) async {
    _validateIdentity(learnerId: learnerId, cardId: 'index');

    final prefs = await SharedPreferences.getInstance();
    final indexKey = indexKeyForLearner(learnerId);
    final ids = prefs.getStringList(indexKey) ?? <String>[];

    for (final cardId in ids.toSet()) {
      await prefs.remove(
        ownershipKeyForLearner(learnerId: learnerId, cardId: cardId),
      );
    }
    await prefs.remove(indexKey);
  }

  static FlashcardOwnership _decodeOwnership(
    String raw, {
    required String expectedCardId,
  }) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw FormatException(
        'Flashcard ownership must be a JSON object: $expectedCardId',
      );
    }

    final ownership = FlashcardOwnership.fromJson(
      Map<String, dynamic>.from(decoded),
    );
    if (ownership.cardId != expectedCardId) {
      throw FormatException(
        'Flashcard ownership key/card mismatch: $expectedCardId',
      );
    }
    return ownership;
  }

  static void _validateIdentity({
    required String learnerId,
    required String cardId,
  }) {
    if (learnerId.trim().isEmpty) {
      throw const FormatException('Flashcard learner ID cannot be empty.');
    }
    if (cardId.trim().isEmpty) {
      throw const FormatException('Flashcard card ID cannot be empty.');
    }
  }
}
