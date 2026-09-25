import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/online_access/learner_online_access_session_controller.dart';
import 'published_flashcard_package.dart';

class CachedFlashcardPackage {
  const CachedFlashcardPackage({
    required this.descriptor,
    required this.compressedBytes,
  });

  final PublishedFlashcardPackageDescriptor descriptor;
  final List<int> compressedBytes;
}

class UidScopedFlashcardPackageCache {
  UidScopedFlashcardPackageCache({
    required SharedPreferences preferences,
    required String userId,
    required LearnerProtectedCacheAccessBoundary accessBoundary,
    this.maxCompressedBytes = 4 * 1024 * 1024,
  }) : _preferences = preferences,
       _userId = _normalizeUserId(userId),
       _accessBoundary = accessBoundary {
    if (maxCompressedBytes <= 0) {
      throw ArgumentError.value(
        maxCompressedBytes,
        'maxCompressedBytes',
        'Flashcard cache budget must be positive.',
      );
    }
  }

  static String storageKeyForUser(String userId) =>
      'csp11.student.${_normalizeUserId(userId)}.'
      'protected_flashcard_packages.v1';

  final SharedPreferences _preferences;
  final String _userId;
  final LearnerProtectedCacheAccessBoundary _accessBoundary;
  final int maxCompressedBytes;

  String get storageKey => storageKeyForUser(_userId);

  Future<PublishedFlashcardPackageDescriptor?> descriptorFor(
    String competencyId,
  ) async {
    _requireAuthorized();
    final entry = _readState()[_normalizeCompetencyId(competencyId)];
    return entry?.descriptor;
  }

  Future<CachedFlashcardPackage?> loadVerified(
    String competencyId, {
    FlashcardPackageDecoder decoder = const FlashcardPackageDecoder(),
  }) async {
    _requireAuthorized();
    final normalized = _normalizeCompetencyId(competencyId);
    final state = _readState();
    final entry = state[normalized];
    if (entry == null) return null;

    try {
      decoder.decode(
        descriptor: entry.descriptor,
        compressedBytes: entry.compressedBytes,
      );
    } on FormatException {
      state.remove(normalized);
      await _persist(state);
      return null;
    }

    return CachedFlashcardPackage(
      descriptor: entry.descriptor,
      compressedBytes: List<int>.unmodifiable(entry.compressedBytes),
    );
  }

  Future<void> saveVerified({
    required PublishedFlashcardPackageDescriptor descriptor,
    required List<int> compressedBytes,
    FlashcardPackageDecoder decoder = const FlashcardPackageDecoder(),
  }) async {
    _requireAuthorized();
    decoder.decode(descriptor: descriptor, compressedBytes: compressedBytes);

    if (compressedBytes.length > maxCompressedBytes) {
      throw StateError('Flashcard package exceeds the cache byte budget.');
    }

    final state = _readState();
    state[descriptor.competencyId] = _FlashcardCacheEntry(
      descriptor: descriptor,
      compressedBytes: List<int>.unmodifiable(compressedBytes),
      lastAccessEpochMs: DateTime.now().toUtc().millisecondsSinceEpoch,
    );

    while (_totalBytes(state) > maxCompressedBytes) {
      final candidates = state.entries
          .where((entry) => entry.key != descriptor.competencyId)
          .toList()
        ..sort((left, right) {
          final byTime = left.value.lastAccessEpochMs.compareTo(
            right.value.lastAccessEpochMs,
          );
          return byTime != 0 ? byTime : left.key.compareTo(right.key);
        });

      if (candidates.isEmpty) {
        throw StateError(
          'Flashcard cache cannot satisfy the configured byte budget.',
        );
      }
      state.remove(candidates.first.key);
    }

    await _persist(state);

    final verified = await loadVerified(
      descriptor.competencyId,
      decoder: decoder,
    );
    if (verified == null) {
      throw StateError('Flashcard cache verification failed after write.');
    }
  }

  Map<String, _FlashcardCacheEntry> _readState() {
    final raw = _preferences.getString(storageKey);
    if (raw == null || raw.trim().isEmpty) {
      return <String, _FlashcardCacheEntry>{};
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        throw const FormatException('Flashcard cache root must be an object.');
      }
      final map = Map<String, dynamic>.from(decoded);
      if (map['schemaVersion'] != 1 || map['entries'] is! Map) {
        throw const FormatException('Unsupported flashcard cache schema.');
      }

      final entries = <String, _FlashcardCacheEntry>{};
      for (final item in (map['entries'] as Map).entries) {
        final competencyId = _normalizeCompetencyId(item.key.toString());
        if (item.value is! Map) {
          throw const FormatException('Flashcard cache entry is invalid.');
        }
        final json = Map<String, dynamic>.from(item.value as Map);
        final descriptor = PublishedFlashcardPackageDescriptor.fromJson(
          Map<String, dynamic>.from(
            json['descriptor'] as Map? ?? const <String, dynamic>{},
          ),
        );
        if (descriptor.competencyId != competencyId) {
          throw const FormatException('Flashcard cache identity mismatch.');
        }

        final bytes = base64Decode(json['compressedBase64']?.toString() ?? '');
        if (bytes.length != descriptor.compressedBytes) {
          throw const FormatException(
            'Flashcard cache compressed byte count mismatch.',
          );
        }

        entries[competencyId] = _FlashcardCacheEntry(
          descriptor: descriptor,
          compressedBytes: List<int>.unmodifiable(bytes),
          lastAccessEpochMs:
              int.tryParse(json['lastAccessEpochMs']?.toString() ?? '') ?? 0,
        );
      }
      return entries;
    } catch (_) {
      return <String, _FlashcardCacheEntry>{};
    }
  }

  Future<void> _persist(Map<String, _FlashcardCacheEntry> state) async {
    final ids = state.keys.toList()..sort();
    final success = await _preferences.setString(
      storageKey,
      jsonEncode(<String, dynamic>{
        'schemaVersion': 1,
        'entries': <String, dynamic>{
          for (final id in ids) id: state[id]!.toJson(),
        },
      }),
    );
    if (!success) {
      throw StateError('Flashcard cache write failed.');
    }
  }

  int _totalBytes(Map<String, _FlashcardCacheEntry> state) =>
      state.values.fold<int>(
        0,
        (sum, item) => sum + item.compressedBytes.length,
      );

  void _requireAuthorized() {
    if (!_accessBoundary.isAuthorizedFor(_userId)) {
      throw StateError(
        'Protected flashcard cache is locked until current online '
        'authorization succeeds.',
      );
    }
  }

  static String _normalizeUserId(String userId) {
    final value = userId.trim();
    if (value.isEmpty) {
      throw ArgumentError.value(userId, 'userId', 'Firebase UID is required.');
    }
    return value;
  }

  static String _normalizeCompetencyId(String competencyId) {
    final value = competencyId.trim().toLowerCase();
    if (!RegExp(r'^d0[12]_c\d{2}$').hasMatch(value)) {
      throw ArgumentError.value(
        competencyId,
        'competencyId',
        'Published flashcards currently support Domain 01 and Domain 02.',
      );
    }
    return value;
  }
}

class _FlashcardCacheEntry {
  const _FlashcardCacheEntry({
    required this.descriptor,
    required this.compressedBytes,
    required this.lastAccessEpochMs,
  });

  final PublishedFlashcardPackageDescriptor descriptor;
  final List<int> compressedBytes;
  final int lastAccessEpochMs;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'descriptor': <String, dynamic>{
      'competencyId': descriptor.competencyId,
      'flashcardVersion': descriptor.version,
      'flashcardChecksumSha256': descriptor.checksumSha256,
      'flashcardSizeBytes': descriptor.compressedBytes,
      'flashcardCount': descriptor.flashcardCount,
    },
    'compressedBase64': base64Encode(compressedBytes),
    'lastAccessEpochMs': lastAccessEpochMs,
  };
}
