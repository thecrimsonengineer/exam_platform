import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../online_access/learner_online_access_session_controller.dart';
import 'published_question_package.dart';

abstract interface class ProtectedQuestionPackageCacheStore {
  String? getString(String key);

  Future<bool> setString(String key, String value);

  Future<bool> remove(String key);
}

class SharedPreferencesProtectedQuestionPackageCacheStore
    implements ProtectedQuestionPackageCacheStore {
  SharedPreferencesProtectedQuestionPackageCacheStore(
    SharedPreferences preferences,
  ) : _preferences = preferences;

  final SharedPreferences _preferences;

  @override
  String? getString(String key) => _preferences.getString(key);

  @override
  Future<bool> setString(String key, String value) {
    return _preferences.setString(key, value);
  }

  @override
  Future<bool> remove(String key) {
    return _preferences.remove(key);
  }
}

class CachedQuestionPackage {
  const CachedQuestionPackage({
    required this.descriptor,
    required this.compressedBytes,
  });

  final PublishedQuestionPackageDescriptor descriptor;
  final List<int> compressedBytes;
}

class UidScopedQuestionPackageCache {
  UidScopedQuestionPackageCache({
    required ProtectedQuestionPackageCacheStore store,
    required String userId,
    required LearnerProtectedCacheAccessBoundary accessBoundary,
    DateTime Function()? clock,
    this.maxCompressedBytes = defaultMaxCompressedBytes,
  }) : _store = store,
       _userId = _normalizeUserId(userId),
       _accessBoundary = accessBoundary,
       _clock = clock ?? DateTime.now {
    if (maxCompressedBytes <= 0) {
      throw ArgumentError.value(
        maxCompressedBytes,
        'maxCompressedBytes',
        'Question-package cache budget must be positive.',
      );
    }
  }

  static const int defaultMaxCompressedBytes = 512 * 1024;

  static String storageKeyForUser(String userId) =>
      'csp11.student.${_normalizeUserId(userId)}.'
      'protected_question_packages.v1';

  final ProtectedQuestionPackageCacheStore _store;
  final String _userId;
  final LearnerProtectedCacheAccessBoundary _accessBoundary;
  final DateTime Function() _clock;
  final int maxCompressedBytes;

  String get storageKey => storageKeyForUser(_userId);

  Future<PublishedQuestionPackageDescriptor?> descriptorFor(
    String competencyId,
  ) async {
    _requireAuthorized();

    final state = _readState();
    return state.entries[_normalizeCompetencyId(competencyId)]?.descriptor;
  }

  Future<CachedQuestionPackage?> loadVerified(
    String competencyId, {
    QuestionPackageDecoder decoder = const QuestionPackageDecoder(),
  }) async {
    _requireAuthorized();

    final normalized = _normalizeCompetencyId(competencyId);
    final state = _readState();
    final entry = state.entries[normalized];

    if (entry == null) {
      return null;
    }

    try {
      decoder.decode(
        descriptor: entry.descriptor,
        compressedBytes: entry.compressedBytes,
      );
    } on FormatException {
      await _removeInvalidEntry(
        state: state,
        competencyId: normalized,
      );
      return null;
    }

    final touched = entry.copyWith(lastAccessEpochMs: _nowEpochMs());
    final next = state.copyWithEntry(normalized, touched);
    await _persistStateOrThrow(next);

    return CachedQuestionPackage(
      descriptor: touched.descriptor,
      compressedBytes: List<int>.unmodifiable(touched.compressedBytes),
    );
  }

  Future<void> saveVerified({
    required PublishedQuestionPackageDescriptor descriptor,
    required List<int> compressedBytes,
    QuestionPackageDecoder decoder = const QuestionPackageDecoder(),
  }) async {
    _requireAuthorized();

    final competencyId = _normalizeCompetencyId(descriptor.competencyId);

    if (compressedBytes.length > maxCompressedBytes) {
      throw StateError(
        'Question package exceeds the protected cache byte budget.',
      );
    }

    decoder.decode(
      descriptor: descriptor,
      compressedBytes: compressedBytes,
    );

    final previousRaw = _store.getString(storageKey);
    final previous = _readStateFromRaw(previousRaw);
    final nextEntry = _QuestionCacheEntry(
      descriptor: descriptor,
      compressedBytes: List<int>.unmodifiable(compressedBytes),
      lastAccessEpochMs: _nowEpochMs(),
    );

    var next = previous.copyWithEntry(competencyId, nextEntry);
    next = _evictToBudget(next, protectedCompetencyId: competencyId);

    final encoded = _encodeState(next);
    final written = await _store.setString(storageKey, encoded);

    if (!written) {
      throw StateError('Protected question-package cache write failed.');
    }

    final readBackRaw = _store.getString(storageKey);

    try {
      final readBack = _readStateFromRaw(readBackRaw);
      final readBackEntry = readBack.entries[competencyId];

      if (readBackEntry == null ||
          _encodeState(readBack) != encoded) {
        throw const FormatException(
          'Question-package cache read-back mismatch.',
        );
      }

      decoder.decode(
        descriptor: readBackEntry.descriptor,
        compressedBytes: readBackEntry.compressedBytes,
      );
    } catch (_) {
      await _restoreRaw(previousRaw);
      throw StateError(
        'Protected question-package cache verification failed.',
      );
    }
  }

  Future<void> remove(String competencyId) async {
    _requireAuthorized();

    final normalized = _normalizeCompetencyId(competencyId);
    final state = _readState();

    if (!state.entries.containsKey(normalized)) {
      return;
    }

    await _persistStateOrThrow(state.withoutEntry(normalized));
  }

  Future<void> clear() async {
    _requireAuthorized();

    final removed = await _store.remove(storageKey);

    if (!removed) {
      throw StateError('Protected question-package cache clear failed.');
    }
  }

  Future<int> totalCompressedBytes() async {
    _requireAuthorized();
    return _readState().totalCompressedBytes;
  }

  Future<List<String>> cachedCompetencyIds() async {
    _requireAuthorized();

    final ids = _readState().entries.keys.toList()..sort();
    return List<String>.unmodifiable(ids);
  }

  _QuestionCacheState _evictToBudget(
    _QuestionCacheState state, {
    required String protectedCompetencyId,
  }) {
    var next = state;

    while (next.totalCompressedBytes > maxCompressedBytes) {
      final candidates = next.entries.entries
          .where((entry) => entry.key != protectedCompetencyId)
          .toList();

      if (candidates.isEmpty) {
        throw StateError(
          'Question-package cache cannot satisfy the frozen byte budget.',
        );
      }

      candidates.sort((left, right) {
        final accessOrder = left.value.lastAccessEpochMs.compareTo(
          right.value.lastAccessEpochMs,
        );

        if (accessOrder != 0) {
          return accessOrder;
        }

        return left.key.compareTo(right.key);
      });

      next = next.withoutEntry(candidates.first.key);
    }

    return next;
  }

  Future<void> _removeInvalidEntry({
    required _QuestionCacheState state,
    required String competencyId,
  }) async {
    final next = state.withoutEntry(competencyId);
    await _persistStateOrThrow(next);
  }

  Future<void> _persistStateOrThrow(_QuestionCacheState state) async {
    final success = await _store.setString(storageKey, _encodeState(state));

    if (!success) {
      throw StateError('Protected question-package cache write failed.');
    }
  }

  Future<void> _restoreRaw(String? raw) async {
    if (raw == null) {
      await _store.remove(storageKey);
      return;
    }

    await _store.setString(storageKey, raw);
  }

  _QuestionCacheState _readState() {
    return _readStateFromRaw(_store.getString(storageKey));
  }

  _QuestionCacheState _readStateFromRaw(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return const _QuestionCacheState.empty();
    }

    try {
      final decoded = jsonDecode(raw);

      if (decoded is! Map) {
        throw const FormatException('Question cache root must be an object.');
      }

      final map = Map<String, dynamic>.from(decoded);
      final schemaVersion = _toInt(map['schemaVersion']);

      if (schemaVersion != 1) {
        throw const FormatException(
          'Unsupported protected question-cache schema.',
        );
      }

      final rawEntries = map['entries'];

      if (rawEntries is! Map) {
        throw const FormatException(
          'Protected question-cache entries must be an object.',
        );
      }

      final entries = <String, _QuestionCacheEntry>{};

      for (final rawEntry in rawEntries.entries) {
        final competencyId = _normalizeCompetencyId(
          rawEntry.key.toString(),
        );

        if (rawEntry.value is! Map) {
          throw const FormatException(
            'Protected question-cache entry must be an object.',
          );
        }

        final entryJson = Map<String, dynamic>.from(
          rawEntry.value as Map,
        );

        final descriptor = PublishedQuestionPackageDescriptor.fromJson(
          Map<String, dynamic>.from(
            entryJson['descriptor'] as Map? ?? const <String, dynamic>{},
          ),
        );

        if (descriptor.competencyId != competencyId) {
          throw const FormatException(
            'Protected question-cache competency mismatch.',
          );
        }

        final encodedBytes = entryJson['compressedBase64']?.toString() ?? '';
        if (encodedBytes.isEmpty) {
          throw const FormatException(
            'Protected question-cache bytes are missing.',
          );
        }

        final compressedBytes = base64Decode(encodedBytes);
        if (compressedBytes.length != descriptor.compressedBytes) {
          throw const FormatException(
            'Protected question-cache byte count mismatch.',
          );
        }

        final lastAccessEpochMs = _toInt(entryJson['lastAccessEpochMs']);
        if (lastAccessEpochMs < 0) {
          throw const FormatException(
            'Protected question-cache access timestamp is invalid.',
          );
        }

        entries[competencyId] = _QuestionCacheEntry(
          descriptor: descriptor,
          compressedBytes: List<int>.unmodifiable(compressedBytes),
          lastAccessEpochMs: lastAccessEpochMs,
        );
      }

      return _QuestionCacheState(entries: entries);
    } catch (error) {
      if (error is FormatException) {
        rethrow;
      }

      throw const FormatException(
        'Protected question-package cache is invalid.',
      );
    }
  }

  String _encodeState(_QuestionCacheState state) {
    final ids = state.entries.keys.toList()..sort();

    return jsonEncode(<String, dynamic>{
      'schemaVersion': 1,
      'entries': <String, dynamic>{
        for (final competencyId in ids)
          competencyId: state.entries[competencyId]!.toJson(),
      },
    });
  }

  int _nowEpochMs() => _clock().toUtc().millisecondsSinceEpoch;

  void _requireAuthorized() {
    if (!_accessBoundary.isAuthorizedFor(_userId)) {
      throw StateError(
        'Protected question-package cache is locked until current online '
        'authorization succeeds for Firebase UID "$_userId".',
      );
    }
  }

  static String _normalizeUserId(String userId) {
    final normalized = userId.trim();

    if (normalized.isEmpty) {
      throw ArgumentError.value(
        userId,
        'userId',
        'Firebase UID cannot be empty.',
      );
    }

    return normalized;
  }

  static String _normalizeCompetencyId(String competencyId) {
    final normalized = competencyId.trim().toLowerCase();

    if (!RegExp(r'^d\d{2}_c\d{2}$').hasMatch(normalized)) {
      throw ArgumentError.value(
        competencyId,
        'competencyId',
        'CSP11 competency ID must use dNN_cNN format.',
      );
    }

    return normalized;
  }
}

class _QuestionCacheEntry {
  const _QuestionCacheEntry({
    required this.descriptor,
    required this.compressedBytes,
    required this.lastAccessEpochMs,
  });

  final PublishedQuestionPackageDescriptor descriptor;
  final List<int> compressedBytes;
  final int lastAccessEpochMs;

  _QuestionCacheEntry copyWith({required int lastAccessEpochMs}) {
    return _QuestionCacheEntry(
      descriptor: descriptor,
      compressedBytes: compressedBytes,
      lastAccessEpochMs: lastAccessEpochMs,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'descriptor': <String, dynamic>{
      'competencyId': descriptor.competencyId,
      'questionVersion': descriptor.version,
      'questionChecksumSha256': descriptor.checksumSha256,
      'questionSizeBytes': descriptor.compressedBytes,
      'publishedQuestionCount': descriptor.publishedQuestionCount,
      'ultraHardCount': descriptor.ultraHardCount,
    },
    'compressedBase64': base64Encode(compressedBytes),
    'lastAccessEpochMs': lastAccessEpochMs,
  };
}

class _QuestionCacheState {
  const _QuestionCacheState({required this.entries});

  const _QuestionCacheState.empty()
    : entries = const <String, _QuestionCacheEntry>{};

  final Map<String, _QuestionCacheEntry> entries;

  int get totalCompressedBytes => entries.values.fold<int>(
    0,
    (total, entry) => total + entry.compressedBytes.length,
  );

  _QuestionCacheState copyWithEntry(
    String competencyId,
    _QuestionCacheEntry entry,
  ) {
    return _QuestionCacheState(
      entries: <String, _QuestionCacheEntry>{
        ...entries,
        competencyId: entry,
      },
    );
  }

  _QuestionCacheState withoutEntry(String competencyId) {
    final next = <String, _QuestionCacheEntry>{...entries}
      ..remove(competencyId);
    return _QuestionCacheState(entries: next);
  }
}

int _toInt(Object? value) {
  if (value is int) {
    return value;
  }

  if (value is num && value == value.toInt()) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ?? -1;
}
