import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:exam_platform/models/study_content.dart';
import 'package:exam_platform/services/study_content/cloud_content_repository.dart';
import 'package:exam_platform/services/study_content/cloud_published_content_repository.dart';
import 'package:exam_platform/services/study_content/student_content_cache_repository.dart';
import 'package:exam_platform/services/study_content/student_content_sync_service.dart';

StudyContent _content({
  required String id,
  required int version,
  String status = 'published',
}) {
  return StudyContent(
    id: id,
    domainId: 'd07',
    competencyId: 'd07_c03',
    competencyNumber: 3,
    title: 'Needs Assessment',
    status: status,
    version: version,
    subtopics: const [],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeFirebaseFirestore firestore;
  late CloudContentRepository cloudRepository;
  late CloudPublishedContentRepository publishedRepository;
  late StudentContentCacheRepository cacheRepository;
  late StudentContentSyncService syncService;

  setUp(() async {
    firestore = FakeFirebaseFirestore();

    SharedPreferences.setMockInitialValues({});

    final preferences = await SharedPreferences.getInstance();

    cloudRepository = CloudContentRepository(firestore: firestore);

    publishedRepository = CloudPublishedContentRepository(
      repository: cloudRepository,
    );

    cacheRepository = StudentContentCacheRepository(preferences: preferences);

    syncService = StudentContentSyncService(
      cloudRepository: publishedRepository,
      cacheRepository: cacheRepository,
    );
  });

  test('downloads published content when cache is empty', () async {
    final content = _content(id: 'd07_c03-v1', version: 1);

    await cloudRepository.publish(
      StudyContent(
        id: content.id,
        domainId: content.domainId,
        competencyId: content.competencyId,
        competencyNumber: content.competencyNumber,
        title: content.title,
        status: 'validated',
        version: content.version,
        subtopics: content.subtopics,
      ),
    );

    final result = await syncService.synchronize();

    expect(result.downloaded, 1);
    expect(result.unchanged, 0);
    expect(result.skippedOlder, 0);

    final cached = await cacheRepository.loadLatestForCompetency('d07_c03');

    expect(cached, isNotNull);
    expect(cached!.version, 1);
    expect(cached.status, 'published');
  });

  test('does not download unchanged published content again', () async {
    final content = _content(id: 'd07_c03-v1', version: 1);

    await cacheRepository.save(content);

    await cloudRepository.publish(
      StudyContent(
        id: content.id,
        domainId: content.domainId,
        competencyId: content.competencyId,
        competencyNumber: content.competencyNumber,
        title: content.title,
        status: 'validated',
        version: content.version,
        subtopics: content.subtopics,
      ),
    );

    final result = await syncService.synchronize();

    expect(result.downloaded, 0);
    expect(result.unchanged, 1);
    expect(result.skippedOlder, 0);

    final cached = await cacheRepository.loadLatestForCompetency('d07_c03');

    expect(cached!.version, 1);
  });

  test('downloads a newer published version', () async {
    final cached = _content(id: 'd07_c03-v1', version: 1);

    await cacheRepository.save(cached);

    final publishedSource = _content(
      id: 'd07_c03-v2',
      version: 2,
      status: 'validated',
    );

    await cloudRepository.publish(publishedSource);

    final result = await syncService.synchronize();

    expect(result.downloaded, 1);
    expect(result.unchanged, 0);
    expect(result.skippedOlder, 0);

    final latest = await cacheRepository.loadLatestForCompetency('d07_c03');

    expect(latest, isNotNull);
    expect(latest!.version, 2);
    expect(latest.id, 'd07_c03-v2');
  });

  test('never downgrades an existing cached version', () async {
    final cached = _content(id: 'd07_c03-v2', version: 2);

    await cacheRepository.save(cached);

    final olderPublished = _content(
      id: 'd07_c03-v1',
      version: 1,
      status: 'validated',
    );

    await cloudRepository.publish(olderPublished);

    final result = await syncService.synchronize();

    expect(result.downloaded, 0);
    expect(result.unchanged, 0);
    expect(result.skippedOlder, 1);

    final latest = await cacheRepository.loadLatestForCompetency('d07_c03');

    expect(latest, isNotNull);
    expect(latest!.version, 2);
    expect(latest.id, 'd07_c03-v2');
  });

  test('student cloud boundary excludes unpublished content', () async {
    await cloudRepository.saveDraft(
      _content(id: 'd07_c03-draft', version: 1, status: 'draft'),
    );

    final published = await publishedRepository.loadPublished();

    expect(published, isEmpty);
  });

  test(
    'synchronizeCompetency downloads only the requested competency',
    () async {
      final first = _content(id: 'd07_c03-v1', version: 1, status: 'validated');

      final second = StudyContent(
        id: 'd07_c04-v1',
        domainId: 'd07',
        competencyId: 'd07_c04',
        competencyNumber: 4,
        title: 'Another Competency',
        status: 'validated',
        version: 1,
        subtopics: const [],
      );

      await cloudRepository.publish(first);
      await cloudRepository.publish(second);

      final result = await syncService.synchronizeCompetency('d07_c03');

      expect(result.downloaded, 1);

      expect(
        await cacheRepository.loadLatestForCompetency('d07_c03'),
        isNotNull,
      );

      expect(await cacheRepository.loadLatestForCompetency('d07_c04'), isNull);
    },
  );

  test('synchronizeCompetency reports unchanged content', () async {
    final content = _content(id: 'd07_c03-v1', version: 1);

    await cacheRepository.save(content);

    await cloudRepository.publish(
      StudyContent(
        id: content.id,
        domainId: content.domainId,
        competencyId: content.competencyId,
        competencyNumber: content.competencyNumber,
        title: content.title,
        status: 'validated',
        version: content.version,
        subtopics: content.subtopics,
      ),
    );

    final result = await syncService.synchronizeCompetency('d07_c03');

    expect(result.downloaded, 0);
    expect(result.unchanged, 1);
    expect(result.skippedOlder, 0);
  });
}
