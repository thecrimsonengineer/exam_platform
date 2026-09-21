import 'dart:convert';

import 'package:exam_platform/models/study_content.dart';
import 'package:exam_platform/services/online_access/learner_online_access_session_controller.dart';
import 'package:exam_platform/services/study_content/uid_scoped_protected_content_cache_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FR8B blocks protected cache reads while authorization is locked', () {
    final store = _MemoryStore();
    final boundary = _FakeBoundary();
    final repository = UidScopedProtectedContentCacheRepository(
      store: store,
      userId: 'user-a',
      accessBoundary: boundary,
    );

    store.values[repository.storageKey] = jsonEncode(<Object>[
      _content(
        id: 'content-a',
        competencyId: 'd01_c01',
        version: 1,
      ).toJson(),
    ]);

    expect(repository.loadAll, throwsStateError);
  });

  test('FR8B stores protected content in a Firebase-UID namespace', () async {
    final store = _MemoryStore();
    final boundary = _FakeBoundary()..authorize('user-a');
    final repository = UidScopedProtectedContentCacheRepository(
      store: store,
      userId: 'user-a',
      accessBoundary: boundary,
    );

    await repository.save(
      _content(id: 'content-a', competencyId: 'd01_c01', version: 1),
    );

    expect(
      repository.storageKey,
      'csp11.student.user-a.protected_study_content_cache.v2',
    );
    expect(store.values.containsKey(repository.storageKey), isTrue);
    expect(
      store.values.containsKey(
        UidScopedProtectedContentCacheRepository.legacyCacheKey,
      ),
      isFalse,
    );
  });

  test('FR8B keeps different Firebase UID cache namespaces isolated', () async {
    final store = _MemoryStore();
    final boundary = _FakeBoundary()
      ..authorize('user-a')
      ..authorize('user-b');
    final userA = UidScopedProtectedContentCacheRepository(
      store: store,
      userId: 'user-a',
      accessBoundary: boundary,
    );
    final userB = UidScopedProtectedContentCacheRepository(
      store: store,
      userId: 'user-b',
      accessBoundary: boundary,
    );

    await userA.save(
      _content(id: 'content-a', competencyId: 'd01_c01', version: 1),
    );
    await userB.save(
      _content(id: 'content-b', competencyId: 'd02_c01', version: 1),
    );

    expect((await userA.loadAll()).single.id, 'content-a');
    expect((await userB.loadAll()).single.id, 'content-b');
    expect(userA.storageKey, isNot(userB.storageKey));
  });

  test('FR8B migration is forbidden until the same UID is authorized', () {
    final store = _MemoryStore();
    final repository = UidScopedProtectedContentCacheRepository(
      store: store,
      userId: 'user-a',
      accessBoundary: _FakeBoundary(),
    );
    store.values[UidScopedProtectedContentCacheRepository.legacyCacheKey] =
        jsonEncode(<Object>[
          _content(
            id: 'legacy-a',
            competencyId: 'd01_c01',
            version: 1,
          ).toJson(),
        ]);

    expect(repository.migrateLegacyIfAuthorized, throwsStateError);
    expect(
      store.values.containsKey(
        UidScopedProtectedContentCacheRepository.legacyCacheKey,
      ),
      isTrue,
    );
    expect(store.values.containsKey(repository.storageKey), isFalse);
  });

  test(
    'FR8B migrates legacy cache only after verified copy and read-back',
    () async {
      final store = _MemoryStore();
      final boundary = _FakeBoundary()..authorize('user-a');
      final repository = UidScopedProtectedContentCacheRepository(
        store: store,
        userId: 'user-a',
        accessBoundary: boundary,
      );
      store.values[UidScopedProtectedContentCacheRepository.legacyCacheKey] =
          jsonEncode(<Object>[
            _content(
              id: 'legacy-a',
              competencyId: 'd01_c01',
              version: 1,
            ).toJson(),
            _content(
              id: 'legacy-newer',
              competencyId: 'd01_c01',
              version: 2,
            ).toJson(),
          ]);

      final result = await repository.migrateLegacyIfAuthorized();

      expect(result.status, ProtectedCacheMigrationStatus.migrated);
      expect(result.legacyRetired, isTrue);
      expect(
        store.values.containsKey(
          UidScopedProtectedContentCacheRepository.legacyCacheKey,
        ),
        isFalse,
      );
      expect(store.bools[repository.migrationMarkerKey], isTrue);
      final cached = await repository.loadLatestForCompetency('d01_c01');
      expect(cached, isNotNull);
      expect(cached!.id, 'legacy-newer');
      expect(cached.version, 2);
    },
  );

  test(
    'FR8B invalid legacy bytes remain intact and are never switched',
    () async {
      final store = _MemoryStore();
      final boundary = _FakeBoundary()..authorize('user-a');
      final repository = UidScopedProtectedContentCacheRepository(
        store: store,
        userId: 'user-a',
        accessBoundary: boundary,
      );
      store.values[UidScopedProtectedContentCacheRepository.legacyCacheKey] =
          '{"invalid":"shape"}';

      final result = await repository.migrateLegacyIfAuthorized();

      expect(result.status, ProtectedCacheMigrationStatus.invalidLegacyData);
      expect(
        store.values[UidScopedProtectedContentCacheRepository.legacyCacheKey],
        '{"invalid":"shape"}',
      );
      expect(store.values.containsKey(repository.storageKey), isFalse);
      expect(store.bools[repository.migrationMarkerKey], isNot(true));
    },
  );

  test(
    'FR8B read-back failure restores the previous scoped cache and legacy bytes',
    () async {
      final store = _MemoryStore();
      final boundary = _FakeBoundary()..authorize('user-a');
      final repository = UidScopedProtectedContentCacheRepository(
        store: store,
        userId: 'user-a',
        accessBoundary: boundary,
      );
      final previous = jsonEncode(<Object>[
        _content(
          id: 'existing-a',
          competencyId: 'd02_c01',
          version: 1,
        ).toJson(),
      ]);
      store.values[repository.storageKey] = previous;
      store.values[UidScopedProtectedContentCacheRepository.legacyCacheKey] =
          jsonEncode(<Object>[
            _content(
              id: 'legacy-a',
              competencyId: 'd01_c01',
              version: 1,
            ).toJson(),
          ]);
      store.corruptNextStringWriteForKey = repository.storageKey;

      final result = await repository.migrateLegacyIfAuthorized();

      expect(result.status, ProtectedCacheMigrationStatus.verificationFailed);
      expect(store.values[repository.storageKey], previous);
      expect(
        store.values.containsKey(
          UidScopedProtectedContentCacheRepository.legacyCacheKey,
        ),
        isTrue,
      );
      expect(store.bools[repository.migrationMarkerKey], isNot(true));
    },
  );

  test(
    'FR8B completed marker permits safe cleanup retry without recopying',
    () async {
      final store = _MemoryStore();
      final boundary = _FakeBoundary()..authorize('user-a');
      final repository = UidScopedProtectedContentCacheRepository(
        store: store,
        userId: 'user-a',
        accessBoundary: boundary,
      );
      store.values[repository.storageKey] = jsonEncode(<Object>[
        _content(
          id: 'scoped-a',
          competencyId: 'd01_c01',
          version: 1,
        ).toJson(),
      ]);
      store.values[UidScopedProtectedContentCacheRepository.legacyCacheKey] =
          jsonEncode(<Object>[
            _content(
              id: 'legacy-a',
              competencyId: 'd01_c01',
              version: 1,
            ).toJson(),
          ]);
      store.bools[repository.migrationMarkerKey] = true;

      final result = await repository.migrateLegacyIfAuthorized();

      expect(result.status, ProtectedCacheMigrationStatus.alreadyScoped);
      expect(result.legacyRetired, isTrue);
      expect(
        store.values.containsKey(
          UidScopedProtectedContentCacheRepository.legacyCacheKey,
        ),
        isFalse,
      );
      expect((await repository.loadAll()).single.id, 'scoped-a');
    },
  );
}

StudyContent _content({
  required String id,
  required String competencyId,
  required int version,
}) {
  return StudyContent(
    id: id,
    domainId: competencyId.substring(0, 3),
    competencyId: competencyId,
    competencyNumber: int.parse(competencyId.substring(5)),
    title: 'Test content',
    status: 'Published',
    version: version,
  );
}

class _FakeBoundary implements LearnerProtectedCacheAccessBoundary {
  final Set<String> _authorized = <String>{};

  void authorize(String userId) {
    _authorized.add(userId);
  }

  @override
  bool isAuthorizedFor(String userId) => _authorized.contains(userId);
}

class _MemoryStore implements ProtectedStudentContentCacheStore {
  final Map<String, String> values = <String, String>{};
  final Map<String, bool> bools = <String, bool>{};

  String? corruptNextStringWriteForKey;

  @override
  String? getString(String key) => values[key];

  @override
  bool? getBool(String key) => bools[key];

  @override
  Future<bool> remove(String key) async {
    values.remove(key);
    bools.remove(key);
    return true;
  }

  @override
  Future<bool> setBool(String key, bool value) async {
    bools[key] = value;
    return true;
  }

  @override
  Future<bool> setString(String key, String value) async {
    if (corruptNextStringWriteForKey == key) {
      corruptNextStringWriteForKey = null;
      values[key] = '{"corrupted":true}';
      return true;
    }

    values[key] = value;
    return true;
  }
}
