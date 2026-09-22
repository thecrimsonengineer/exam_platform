import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const phasePath =
      'docs/firestore/PHASE_FR10_STUDY_CONTENT_DELIVERY_CUTOVER.md';
  const packagePath =
      'lib/services/study_content/published_content_package.dart';
  const cachePath =
      'lib/services/study_content/uid_scoped_content_package_cache.dart';
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

  test('FR10 starts only from the exact frozen FR9 checkpoint', () {
    expect(phase, contains('phase-fr9-closed'));
    expect(
      phase,
      contains('7787a1aed26317432285d6b38d51f60927cb9396'),
    );
  });

  test('FR10 freezes production content-package measurements', () {
    expect(phase, contains('35'));
    expect(phase, contains('782,343'));
    expect(phase, contains('8,212'));
    expect(phase, contains('28,334'));
    expect(phase, contains('22,353'));
    expect(phase, contains('512 KiB'));
    expect(phase, contains('whole-bank'));
  });

  test('FR10 keeps protected delivery private and online-authorized', () {
    expect(phase, contains('ONLINE_AUTHORIZED'));
    expect(phase, contains('Direct learner Supabase Data API access remains forbidden'));
    expect(phase, contains('private'));
    expect(phase, contains('60-second signed URL'));
    expect(phase, contains('no Storage object path'));
  });

  test('FR10 decoder is pinned to the frozen FR7 content envelope', () {
    expect(fr7Builder, contains("'schemaVersion': 1"));
    expect(fr7Builder, contains("'kind': 'content'"));
    expect(fr7Builder, contains("'sourceVersion': sourceVersion"));
    expect(fr7Builder, contains("'content': payload"));

    expect(packageSource, contains("_requiredInt(envelope, 'schemaVersion')"));
    expect(packageSource, contains("_requiredString(envelope, 'kind')"));
    expect(packageSource, contains("'sourceVersion'"));
    expect(packageSource, contains("envelope['content']"));
  });

  test('FR10 verifies protected bytes before StudyContent decoding', () {
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
    final modelIndex = packageSource.indexOf(
      'StudyContent.fromJson(contentJson)',
    );

    expect(byteCountIndex, greaterThanOrEqualTo(0));
    expect(checksumIndex, greaterThan(byteCountIndex));
    expect(gzipIndex, greaterThan(checksumIndex));
    expect(jsonIndex, greaterThan(gzipIndex));
    expect(modelIndex, greaterThan(jsonIndex));
  });

  test('FR10 package validation is competency-scoped and published-only', () {
    expect(packageSource, contains('Content package competency mismatch'));
    expect(
      packageSource,
      contains('Content package contains cross-competency StudyContent'),
    );
    expect(packageSource, contains('Content package domain mismatch'));
    expect(
      packageSource,
      contains('Content package contains non-published StudyContent'),
    );
    expect(
      packageSource,
      contains('Content package source version does not match StudyContent'),
    );
  });

  test('FR10B cache is UID-scoped and authorization-gated', () {
    expect(cacheSource, contains('storageKeyForUser(String userId)'));
    expect(
      cacheSource,
      contains('LearnerProtectedCacheAccessBoundary _accessBoundary'),
    );
    expect(cacheSource, contains('_requireAuthorized()'));
    expect(cacheSource, contains('protected_content_packages.v1'));
  });

  test('FR10B cache enforces the frozen compressed-byte LRU budget', () {
    expect(cacheSource, contains('defaultMaxCompressedBytes = 512 * 1024'));
    expect(cacheSource, contains('totalCompressedBytes'));
    expect(cacheSource, contains('_evictToBudget'));
    expect(cacheSource, contains('lastAccessEpochMs'));
    expect(cacheSource, contains('candidates.sort'));
  });

  test('FR10B verifies replacement before write and after read-back', () {
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

  test('FR10B cache never references learner-owned progress namespaces', () {
    expect(cacheSource, isNot(contains('question_progress')));
    expect(cacheSource, isNot(contains('readiness')));
    expect(cacheSource, isNot(contains('bookmark')));
    expect(cacheSource, isNot(contains('attempt')));
  });

  test('FR10A does not cut learner runtime over yet', () {
    expect(
      packageSource,
      isNot(contains('CloudPublishedContentRepository')),
    );
    expect(packageSource, isNot(contains('cloud_firestore')));
    expect(packageSource, isNot(contains('SupabaseClient')));
    expect(phase, contains('no learner runtime cutover'));
  });

  test('FR10 is wired into the inherited FR validation workflow', () {
    expect(workflow, contains('phase-fr10-studycontent-delivery-cutover'));
    expect(workflow, contains('FR10 StudyContent delivery foundation tests'));
    expect(
      workflow,
      contains(
        'flutter test test/services/study_content/'
        'published_content_package_test.dart',
      ),
    );
    expect(
      workflow,
      contains(
        'flutter test test/architecture/'
        'phase_fr10_study_content_delivery_test.dart',
      ),
    );
    expect(workflow, contains('Preserve exact frozen Phase L engine suite'));
    expect(workflow, contains('Full repository regression'));
    expect(workflow, contains('Diff hygiene'));
  });
}
