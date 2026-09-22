import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:exam_platform/models/question.dart';
import 'package:exam_platform/services/online_access/learner_online_access_session_controller.dart';
import 'package:exam_platform/services/questions/published_question_package.dart';
import 'package:exam_platform/services/questions/uid_scoped_question_package_cache.dart';

void main() {
  test('FR9B blocks protected question cache access while locked', () async {
    final store = _MemoryStore();
    final cache = UidScopedQuestionPackageCache(
      store: store,
      userId: 'user-a',
      accessBoundary: _FakeBoundary(),
    );
    final package = _package('d01_c01', 101);

    expect(
      () => cache.saveVerified(
        descriptor: package.descriptor,
        compressedBytes: package.bytes,
      ),
      throwsStateError,
    );
    expect(() => cache.descriptorFor('d01_c01'), throwsStateError);
    expect(store.values, isEmpty);
  });

  test('FR9B isolates package bytes by Firebase UID', () async {
    final store = _MemoryStore();
    final boundary = _FakeBoundary()
      ..authorize('user-a')
      ..authorize('user-b');
    final userA = UidScopedQuestionPackageCache(
      store: store,
      userId: 'user-a',
      accessBoundary: boundary,
    );
    final userB = UidScopedQuestionPackageCache(
      store: store,
      userId: 'user-b',
      accessBoundary: boundary,
    );
    final packageA = _package('d01_c01', 101);
    final packageB = _package('d02_c01', 201);

    await userA.saveVerified(
      descriptor: packageA.descriptor,
      compressedBytes: packageA.bytes,
    );
    await userB.saveVerified(
      descriptor: packageB.descriptor,
      compressedBytes: packageB.bytes,
    );

    expect(userA.storageKey, isNot(userB.storageKey));
    expect((await userA.cachedCompetencyIds()), <String>['d01_c01']);
    expect((await userB.cachedCompetencyIds()), <String>['d02_c01']);
    expect(await userA.descriptorFor('d02_c01'), isNull);
    expect(await userB.descriptorFor('d01_c01'), isNull);
  });

  test('FR9B verifies a package before persisting it', () async {
    final store = _MemoryStore();
    final boundary = _FakeBoundary()..authorize('user-a');
    final cache = UidScopedQuestionPackageCache(
      store: store,
      userId: 'user-a',
      accessBoundary: boundary,
    );
    final package = _package('d01_c01', 101);

    await cache.saveVerified(
      descriptor: package.descriptor,
      compressedBytes: package.bytes,
    );

    final loaded = await cache.loadVerified('d01_c01');

    expect(loaded, isNotNull);
    expect(loaded!.descriptor.checksumSha256, package.descriptor.checksumSha256);
    expect(loaded.compressedBytes, package.bytes);
  });

  test('FR9B rejects a package larger than the frozen cache budget', () async {
    final store = _MemoryStore();
    final boundary = _FakeBoundary()..authorize('user-a');
    final package = _package('d01_c01', 101);
    final cache = UidScopedQuestionPackageCache(
      store: store,
      userId: 'user-a',
      accessBoundary: boundary,
      maxCompressedBytes: package.bytes.length - 1,
    );

    expect(
      () => cache.saveVerified(
        descriptor: package.descriptor,
        compressedBytes: package.bytes,
      ),
      throwsStateError,
    );
    expect(store.values, isEmpty);
  });

  test('FR9B evicts the least-recently-used package by compressed bytes', () async {
    final store = _MemoryStore();
    final boundary = _FakeBoundary()..authorize('user-a');
    var now = DateTime.utc(2026, 9, 22, 1);
    final packageA = _package('d01_c01', 101);
    final packageB = _package('d02_c01', 201);
    final packageC = _package('d03_c01', 301);
    final twoPackageBudget = packageA.bytes.length + packageB.bytes.length;
    final cache = UidScopedQuestionPackageCache(
      store: store,
      userId: 'user-a',
      accessBoundary: boundary,
      maxCompressedBytes: twoPackageBudget,
      clock: () => now,
    );

    await cache.saveVerified(
      descriptor: packageA.descriptor,
      compressedBytes: packageA.bytes,
    );
    now = now.add(const Duration(minutes: 1));
    await cache.saveVerified(
      descriptor: packageB.descriptor,
      compressedBytes: packageB.bytes,
    );

    now = now.add(const Duration(minutes: 1));
    expect(await cache.loadVerified('d01_c01'), isNotNull);

    now = now.add(const Duration(minutes: 1));
    await cache.saveVerified(
      descriptor: packageC.descriptor,
      compressedBytes: packageC.bytes,
    );

    final ids = await cache.cachedCompetencyIds();

    expect(ids, contains('d01_c01'));
    expect(ids, contains('d03_c01'));
    expect(ids, isNot(contains('d02_c01')));
    expect(await cache.totalCompressedBytes(), lessThanOrEqualTo(twoPackageBudget));
  });

  test('FR9B invalid replacement leaves the previous verified entry intact', () async {
    final store = _MemoryStore();
    final boundary = _FakeBoundary()..authorize('user-a');
    final cache = UidScopedQuestionPackageCache(
      store: store,
      userId: 'user-a',
      accessBoundary: boundary,
    );
    final original = _package('d01_c01', 101);

    await cache.saveVerified(
      descriptor: original.descriptor,
      compressedBytes: original.bytes,
    );
    final before = store.values[cache.storageKey];

    final invalidDescriptor = PublishedQuestionPackageDescriptor(
      competencyId: 'd01_c01',
      version: original.descriptor.version + 1,
      checksumSha256: _hex64('0'),
      compressedBytes: original.bytes.length,
      publishedQuestionCount: 1,
    );

    expect(
      () => cache.saveVerified(
        descriptor: invalidDescriptor,
        compressedBytes: original.bytes,
      ),
      throwsFormatException,
    );

    expect(store.values[cache.storageKey], before);
    final loaded = await cache.loadVerified('d01_c01');
    expect(loaded!.descriptor.version, original.descriptor.version);
  });

  test('FR9B corrupted read-back restores the previous cache atomically', () async {
    final store = _MemoryStore();
    final boundary = _FakeBoundary()..authorize('user-a');
    final cache = UidScopedQuestionPackageCache(
      store: store,
      userId: 'user-a',
      accessBoundary: boundary,
    );
    final original = _package('d01_c01', 101);
    final replacement = _package('d01_c01', 102, version: 2);

    await cache.saveVerified(
      descriptor: original.descriptor,
      compressedBytes: original.bytes,
    );
    final before = store.values[cache.storageKey];

    store.corruptNextWriteForKey = cache.storageKey;

    expect(
      () => cache.saveVerified(
        descriptor: replacement.descriptor,
        compressedBytes: replacement.bytes,
      ),
      throwsStateError,
    );

    expect(store.values[cache.storageKey], before);
    final loaded = await cache.loadVerified('d01_c01');
    expect(loaded!.descriptor.version, original.descriptor.version);
  });

  test('FR9B default cache budget is exactly 512 KiB', () {
    expect(
      UidScopedQuestionPackageCache.defaultMaxCompressedBytes,
      512 * 1024,
    );
  });
}

({
  PublishedQuestionPackageDescriptor descriptor,
  List<int> bytes,
}) _package(
  String competencyId,
  int questionId, {
  int version = 1,
}) {
  final domain = int.parse(competencyId.substring(1, 3));
  final question = Question(
    id: questionId,
    domain: domain,
    competencyId: competencyId,
    subtopicId: '${competencyId}_t01_s01',
    topicId: '${competencyId}_t01',
    question: 'A learner evaluates the safest available control.',
    options: const <String>[
      'Control the hazard at source.',
      'Use a warning only.',
      'Delay action.',
      'Rely on memory.',
    ],
    correctAnswer: 0,
    explanation: 'Source control is the strongest listed option.',
    reference: 'CSP11 reference',
    difficulty: 'Hard',
    cognitiveLevel: 'application',
    questionType: 'scenario_mcq',
    status: 'published',
    version: version,
    tags: const <String>['risk-control'],
  );

  final envelope = <String, dynamic>{
    'schemaVersion': 1,
    'kind': 'questions',
    'competencyId': competencyId,
    'sourceRecordMaxVersion': version,
    'questionCount': 1,
    'questions': <Map<String, dynamic>>[question.toJson()],
  };

  final encoded = utf8.encode(jsonEncode(envelope));
  final compressed = GZipEncoder().encode(encoded);

  return (
    descriptor: PublishedQuestionPackageDescriptor(
      competencyId: competencyId,
      version: version,
      checksumSha256: sha256.convert(compressed).toString(),
      compressedBytes: compressed.length,
      publishedQuestionCount: 1,
    ),
    bytes: compressed,
  );
}

String _hex64(String character) {
  return List<String>.filled(64, character).join();
}

class _FakeBoundary implements LearnerProtectedCacheAccessBoundary {
  final Set<String> _authorized = <String>{};

  void authorize(String userId) {
    _authorized.add(userId);
  }

  @override
  bool isAuthorizedFor(String userId) => _authorized.contains(userId);
}

class _MemoryStore implements ProtectedQuestionPackageCacheStore {
  final Map<String, String> values = <String, String>{};

  String? corruptNextWriteForKey;

  @override
  String? getString(String key) => values[key];

  @override
  Future<bool> remove(String key) async {
    values.remove(key);
    return true;
  }

  @override
  Future<bool> setString(String key, String value) async {
    if (corruptNextWriteForKey == key) {
      corruptNextWriteForKey = null;
      values[key] = '{"schemaVersion":1,"entries":"corrupted"}';
      return true;
    }

    values[key] = value;
    return true;
  }
}
