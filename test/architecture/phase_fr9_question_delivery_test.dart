import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const phasePath = 'docs/firestore/PHASE_FR9_QUESTION_DELIVERY_CUTOVER.md';
  const packagePath = 'lib/services/questions/published_question_package.dart';
  const cachePath =
      'lib/services/questions/uid_scoped_question_package_cache.dart';
  const fr7BuilderPath =
      'tool/fr7_package_publish/fr7_package_publish_core.dart';
  const workflowPath =
      '.github/workflows/phase_fr_firestore_read_reduction.yml';

  late String phase;
  late String packageSource;
  late String cacheSource;
  late String fr7Builder;
  late String workflow;

  setUpAll(() {
    phase = File(phasePath).readAsStringSync();
    packageSource = File(packagePath).readAsStringSync();
    cacheSource = File(cachePath).readAsStringSync();
    fr7Builder = File(fr7BuilderPath).readAsStringSync();
    workflow = File(workflowPath).readAsStringSync();
  });

  test('FR9 starts only from the exact frozen FR8 checkpoint', () {
    expect(phase, contains('phase-fr8-closed'));
    expect(phase, contains('a55dd91c25df2f3e1b9f59298130d2bd72a929f3'));
  });

  test('FR9 keeps direct learner Supabase Data API access forbidden', () {
    expect(phase, contains('direct learner Data API access remains forbidden'));
    expect(phase, contains('private Storage objects are never made public'));
    expect(phase, contains('short-lived signed URL'));
  });

  test('FR9 decoder is pinned to the frozen FR7 question envelope', () {
    expect(fr7Builder, contains("'schemaVersion': 1"));
    expect(fr7Builder, contains("'kind': 'questions'"));
    expect(fr7Builder, contains("'questionCount': payloads.length"));
    expect(fr7Builder, contains("'questions': payloads"));

    expect(packageSource, contains("_requiredInt(envelope, 'schemaVersion')"));
    expect(packageSource, contains("_requiredString(envelope, 'kind')"));
    expect(packageSource, contains("'questionCount'"));
    expect(packageSource, contains("envelope['questions']"));
  });

  test('FR9 verifies protected package bytes before question decoding', () {
    final byteCountIndex = packageSource.indexOf(
      'compressedBytes.length != descriptor.compressedBytes',
    );
    final checksumIndex = packageSource.indexOf(
      'sha256.convert(compressed).toString()',
    );
    final gzipIndex = packageSource.indexOf(
      'GZipDecoder().decodeBytes(compressed)',
    );
    final jsonIndex = packageSource.indexOf(
      'jsonDecode(utf8.decode(decodedBytes))',
    );

    expect(byteCountIndex, greaterThanOrEqualTo(0));
    expect(checksumIndex, greaterThan(byteCountIndex));
    expect(gzipIndex, greaterThan(checksumIndex));
    expect(jsonIndex, greaterThan(gzipIndex));
  });

  test(
    'FR9 package validation remains competency-scoped and published-only',
    () {
      expect(packageSource, contains('Question package competency mismatch'));
      expect(
        packageSource,
        contains('Question package contains a cross-competency question'),
      );
      expect(
        packageSource,
        contains('Question package contains a non-published question'),
      );
      expect(packageSource, contains('exactly four options'));
    },
  );

  test('FR9 freezes the protected question cache budget below whole bank', () {
    expect(phase, contains('512 KiB'));
    expect(phase, contains('1,040,943'));
    expect(phase, contains('below the complete current question bank'));
  });

  test('FR9B question-package cache is UID-scoped and authorization-gated', () {
    expect(cacheSource, contains('storageKeyForUser(String userId)'));
    expect(
      cacheSource,
      contains('LearnerProtectedCacheAccessBoundary _accessBoundary'),
    );
    expect(cacheSource, contains('_requireAuthorized()'));
    expect(cacheSource, contains('protected_question_packages.v1'));
  });

  test('FR9B cache enforces the frozen compressed-byte LRU budget', () {
    expect(cacheSource, contains('defaultMaxCompressedBytes = 512 * 1024'));
    expect(cacheSource, contains('totalCompressedBytes'));
    expect(cacheSource, contains('_evictToBudget'));
    expect(cacheSource, contains('lastAccessEpochMs'));
    expect(cacheSource, contains('candidates.sort'));
  });

  test('FR9B cache verifies replacement before and after persistence', () {
    final preWriteDecode = cacheSource.indexOf(
      'decoder.decode(descriptor: descriptor, compressedBytes: compressedBytes);',
    );
    final write = cacheSource.indexOf(
      'final written = await _store.setString(storageKey, encoded)',
    );
    final readBack = cacheSource.indexOf(
      'final readBackRaw = _store.getString(storageKey)',
    );
    final restore = cacheSource.indexOf('await _restoreRaw(previousRaw)');

    expect(preWriteDecode, greaterThanOrEqualTo(0));
    expect(write, greaterThan(preWriteDecode));
    expect(readBack, greaterThan(write));
    expect(restore, greaterThan(readBack));
  });

  test('FR9B cache never references learner-owned progress namespaces', () {
    expect(cacheSource, isNot(contains('question_progress')));
    expect(cacheSource, isNot(contains('readiness')));
    expect(cacheSource, isNot(contains('bookmark')));
    expect(cacheSource, isNot(contains('attempt')));
  });

  test('FR9 is wired into the main FR validation workflow', () {
    expect(workflow, contains('phase-fr9-question-delivery-cutover'));
    expect(workflow, contains('FR9 question delivery foundation tests'));
    expect(workflow, contains('FR9 protected question cache tests'));
  });
}
