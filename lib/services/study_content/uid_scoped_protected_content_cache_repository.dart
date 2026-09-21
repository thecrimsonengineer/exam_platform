import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/study_content.dart';
import '../online_access/learner_online_access_session_controller.dart';

abstract interface class ProtectedStudentContentCacheStore {
  String? getString(String key);

  bool? getBool(String key);

  Future<bool> setString(String key, String value);

  Future<bool> setBool(String key, bool value);

  Future<bool> remove(String key);
}

class SharedPreferencesProtectedStudentContentCacheStore
    implements ProtectedStudentContentCacheStore {
  SharedPreferencesProtectedStudentContentCacheStore(
    SharedPreferences preferences,
  ) : _preferences = preferences;

  final SharedPreferences _preferences;

  @override
  String? getString(String key) => _preferences.getString(key);

  @override
  bool? getBool(String key) => _preferences.getBool(key);

  @override
  Future<bool> setString(String key, String value) {
    return _preferences.setString(key, value);
  }

  @override
  Future<bool> setBool(String key, bool value) {
    return _preferences.setBool(key, value);
  }

  @override
  Future<bool> remove(String key) {
    return _preferences.remove(key);
  }
}

enum ProtectedCacheMigrationStatus {
  noLegacyData,
  alreadyScoped,
  invalidLegacyData,
  invalidScopedData,
  writeFailed,
  verificationFailed,
  markerWriteFailed,
  migrated,
}

class ProtectedCacheMigrationResult {
  const ProtectedCacheMigrationResult({
    required this.status,
    this.legacyRetired = false,
  });

  final ProtectedCacheMigrationStatus status;
  final bool legacyRetired;

  bool get migrated => status == ProtectedCacheMigrationStatus.migrated;
}

/// UID-scoped persistent cache for protected learner StudyContent.
///
/// This repository is deliberately staged beside the legacy runtime cache in
/// FR8B. It must not become the learner delivery path until FR8C binds it to a
/// live [LearnerProtectedCacheAccessBoundary].
///
/// Protected bytes may be read or written only while the same Firebase UID is
/// currently online-authorized.
class UidScopedProtectedContentCacheRepository {
  UidScopedProtectedContentCacheRepository({
    required ProtectedStudentContentCacheStore store,
    required String userId,
    required LearnerProtectedCacheAccessBoundary accessBoundary,
  }) : _store = store,
       _userId = _normalizeUserId(userId),
       _accessBoundary = accessBoundary;

  static const String legacyCacheKey = 'csp11.student_content_cache.v1';

  static String storageKeyForUser(String userId) =>
      'csp11.student.${_normalizeUserId(userId)}.'
      'protected_study_content_cache.v2';

  static String migrationMarkerKeyForUser(String userId) =>
      'csp11.student.${_normalizeUserId(userId)}.'
      'protected_study_content_cache.migrated.v2';

  final ProtectedStudentContentCacheStore _store;
  final String _userId;
  final LearnerProtectedCacheAccessBoundary _accessBoundary;

  String get storageKey => storageKeyForUser(_userId);

  String get migrationMarkerKey => migrationMarkerKeyForUser(_userId);

  Future<List<StudyContent>> loadAll() async {
    _requireAuthorized();

    final raw = _store.getString(storageKey);
    if (raw == null || raw.trim().isEmpty) {
      return const <StudyContent>[];
    }

    return _decodeStrict(raw) ?? const <StudyContent>[];
  }

  Future<StudyContent?> load(String contentId) async {
    final contents = await loadAll();

    for (final content in contents) {
      if (content.id == contentId) {
        return content;
      }
    }

    return null;
  }

  Future<StudyContent?> loadLatestForCompetency(String competencyId) async {
    final contents = await loadAll();
    final matches = contents
        .where((content) => content.competencyId == competencyId)
        .toList();

    if (matches.isEmpty) {
      return null;
    }

    matches.sort((left, right) => right.version.compareTo(left.version));
    return matches.first;
  }

  Future<int?> cachedVersionForCompetency(String competencyId) async {
    final content = await loadLatestForCompetency(competencyId);
    return content?.version;
  }

  Future<void> save(StudyContent content) async {
    _requireAuthorized();

    if (!_isValidPublishedContent(content)) {
      throw ArgumentError(
        'Only valid published StudyContent can enter the protected cache.',
      );
    }

    final current = await loadAll();
    final next = _mergeLatest(<StudyContent>[...current, content]);
    final encoded = _encode(next);

    final written = await _store.setString(storageKey, encoded);
    if (!written) {
      throw StateError('Protected StudyContent cache write failed.');
    }
  }

  Future<void> remove(String contentId) async {
    _requireAuthorized();

    final current = await loadAll();
    final next = current.where((content) => content.id != contentId).toList();
    final written = await _store.setString(storageKey, _encode(next));

    if (!written) {
      throw StateError('Protected StudyContent cache write failed.');
    }
  }

  Future<void> clear() async {
    _requireAuthorized();

    final removed = await _store.remove(storageKey);
    if (!removed) {
      throw StateError('Protected StudyContent cache clear failed.');
    }
  }

  Future<ProtectedCacheMigrationResult> migrateLegacyIfAuthorized() async {
    _requireAuthorized();

    final legacyRaw = _store.getString(legacyCacheKey);
    final alreadyMigrated = _store.getBool(migrationMarkerKey) == true;

    if (alreadyMigrated) {
      final retired = legacyRaw == null
          ? true
          : await _store.remove(legacyCacheKey);
      return ProtectedCacheMigrationResult(
        status: ProtectedCacheMigrationStatus.alreadyScoped,
        legacyRetired: retired,
      );
    }

    if (legacyRaw == null || legacyRaw.trim().isEmpty) {
      return const ProtectedCacheMigrationResult(
        status: ProtectedCacheMigrationStatus.noLegacyData,
      );
    }

    final legacyContents = _decodeStrict(legacyRaw);
    if (legacyContents == null) {
      return const ProtectedCacheMigrationResult(
        status: ProtectedCacheMigrationStatus.invalidLegacyData,
      );
    }

    final previousScopedRaw = _store.getString(storageKey);
    var scopedContents = const <StudyContent>[];

    if (previousScopedRaw != null && previousScopedRaw.trim().isNotEmpty) {
      final decodedScoped = _decodeStrict(previousScopedRaw);
      if (decodedScoped == null) {
        return const ProtectedCacheMigrationResult(
          status: ProtectedCacheMigrationStatus.invalidScopedData,
        );
      }
      scopedContents = decodedScoped;
    }

    final merged = _mergeLatest(<StudyContent>[
      ...scopedContents,
      ...legacyContents,
    ]);
    final encoded = _encode(merged);

    final written = await _store.setString(storageKey, encoded);
    if (!written) {
      return const ProtectedCacheMigrationResult(
        status: ProtectedCacheMigrationStatus.writeFailed,
      );
    }

    final readBack = _store.getString(storageKey);
    final decodedReadBack = readBack == null ? null : _decodeStrict(readBack);
    final verified =
        decodedReadBack != null && _encode(decodedReadBack) == encoded;

    if (!verified) {
      await _restoreScopedValue(previousScopedRaw);
      return const ProtectedCacheMigrationResult(
        status: ProtectedCacheMigrationStatus.verificationFailed,
      );
    }

    final markerWritten = await _store.setBool(migrationMarkerKey, true);
    if (!markerWritten) {
      await _restoreScopedValue(previousScopedRaw);
      return const ProtectedCacheMigrationResult(
        status: ProtectedCacheMigrationStatus.markerWriteFailed,
      );
    }

    final legacyRetired = await _store.remove(legacyCacheKey);

    return ProtectedCacheMigrationResult(
      status: ProtectedCacheMigrationStatus.migrated,
      legacyRetired: legacyRetired,
    );
  }

  Future<void> _restoreScopedValue(String? previousRaw) async {
    if (previousRaw == null) {
      await _store.remove(storageKey);
      return;
    }

    await _store.setString(storageKey, previousRaw);
  }

  List<StudyContent>? _decodeStrict(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return null;
      }

      final contents = <StudyContent>[];
      for (final item in decoded) {
        if (item is! Map) {
          return null;
        }

        final content = StudyContent.fromJson(
          Map<String, dynamic>.from(item),
        );

        if (!_isValidPublishedContent(content)) {
          return null;
        }

        contents.add(content);
      }

      return _mergeLatest(contents);
    } catch (_) {
      return null;
    }
  }

  List<StudyContent> _mergeLatest(Iterable<StudyContent> contents) {
    final latestByCompetency = <String, StudyContent>{};

    for (final content in contents) {
      if (!_isValidPublishedContent(content)) {
        continue;
      }

      final existing = latestByCompetency[content.competencyId];
      if (existing == null || content.version > existing.version) {
        latestByCompetency[content.competencyId] = content;
      }
    }

    final result = latestByCompetency.values.toList()
      ..sort((left, right) {
        final competencyOrder = left.competencyId.compareTo(
          right.competencyId,
        );
        if (competencyOrder != 0) {
          return competencyOrder;
        }
        return left.version.compareTo(right.version);
      });

    return result;
  }

  String _encode(Iterable<StudyContent> contents) {
    return jsonEncode(
      contents.map((content) => content.toJson()).toList(),
    );
  }

  bool _isValidPublishedContent(StudyContent content) {
    return content.id.trim().isNotEmpty &&
        content.domainId.trim().isNotEmpty &&
        content.competencyId.trim().isNotEmpty &&
        content.version > 0 &&
        content.status.toLowerCase() == 'published';
  }

  void _requireAuthorized() {
    if (!_accessBoundary.isAuthorizedFor(_userId)) {
      throw StateError(
        'Protected StudyContent cache is locked until current online '
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
}
