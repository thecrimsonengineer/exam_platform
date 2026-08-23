import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:exam_platform/models/study_content.dart';
import 'package:exam_platform/services/study_content/cloud_content_repository.dart';
import 'package:exam_platform/services/study_content/cloud_published_content_repository.dart';
import 'package:exam_platform/services/study_content/student_content_cache_repository.dart';
import 'package:exam_platform/services/study_content_loader.dart';

StudyContent _content({
  required String id,
  required String status,
  required int version,
  String domainId = 'domain_01',
  String competencyId = 'd01_c01',
}) {
  return StudyContent.fromJson({
    'id': id,
    'domainId': domainId,
    'competencyId': competencyId,
    'competencyNumber': '1',
    'title': 'Test competency',
    'status': status,
    'version': version,
    'subtopics': <Map<String, dynamic>>[],
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StudyContentLoader Firebase published-content integration', () {
    late FakeFirebaseFirestore firestore;
    late CloudPublishedContentRepository repository;
    late StudentContentCacheRepository cacheRepository;
    late StudyContentLoader loader;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});

      final preferences = await SharedPreferences.getInstance();

      firestore = FakeFirebaseFirestore();

      repository = CloudPublishedContentRepository(
        repository: CloudContentRepository(
          firestore: firestore,
        ),
      );

      cacheRepository = StudentContentCacheRepository(
        preferences: preferences,
      );

      loader = StudyContentLoader(
        repository: repository,
        cacheRepository: cacheRepository,
      );
    });

    test('loads only published content from Firebase', () async {
      final cloud = CloudContentRepository(
        firestore: firestore,
      );

      await cloud.saveDraft(
        _content(
          id: 'draft_1',
          status: 'draft',
          version: 1,
        ),
      );

      await cloud.publish(
        _content(
          id: 'published_1',
          status: 'published',
          version: 1,
        ),
      );

      await cloud.updatePublishedStatus(
        'published_1',
        'archived',
      );

      await cloud.publish(
        _content(
          id: 'published_2',
          status: 'published',
          version: 2,
        ),
      );

      final published = await loader.loadPublishedContent();

      expect(published.length, 1);
      expect(published.single.id, 'published_2');
      expect(published.single.status, 'published');

      final cached = await cacheRepository.loadAll();

      expect(cached.length, 1);
      expect(cached.single.id, 'published_2');
    });

    test('selects the latest published version for a competency', () async {
      final cloud = CloudContentRepository(
        firestore: firestore,
      );

      await cloud.publish(
        _content(
          id: 'cp_v1',
          status: 'published',
          version: 1,
        ),
      );

      await cloud.publish(
        _content(
          id: 'cp_v2',
          status: 'published',
          version: 2,
        ),
      );

      final published = await loader.loadPublishedContent();

      expect(published.length, 1);
      expect(published.single.id, 'cp_v2');
      expect(published.single.version, 2);

      final cached = await cacheRepository.loadLatestForCompetency(
        'd01_c01',
      );

      expect(cached, isNotNull);
      expect(cached!.id, 'cp_v2');
      expect(cached.version, 2);
    });

    test('loads a published competency by domain and competency', () async {
      final cloud = CloudContentRepository(
        firestore: firestore,
      );

      await cloud.publish(
        _content(
          id: 'cp_v3',
          status: 'published',
          version: 3,
          domainId: 'domain_02',
          competencyId: 'd02_c01',
        ),
      );

      final content = await loader.loadStudyContent(
        domainId: 'domain_02',
        competencyId: 'd02_c01',
      );

      expect(content.id, 'cp_v3');
      expect(content.version, 3);
      expect(content.status, 'published');

      final cached = await cacheRepository.loadLatestForCompetency(
        'd02_c01',
      );

      expect(cached, isNotNull);
      expect(cached!.id, 'cp_v3');
    });

    test('does not return archived content by content ID', () async {
      final cloud = CloudContentRepository(
        firestore: firestore,
      );

      await cloud.publish(
        _content(
          id: 'cp_archived',
          status: 'published',
          version: 1,
        ),
      );

      await cloud.updatePublishedStatus(
        'cp_archived',
        'archived',
      );

      await expectLater(
        loader.loadPublishedByContentId('cp_archived'),
        throwsA(isA<StateError>()),
      );

      expect(
        await cacheRepository.load('cp_archived'),
        isNull,
      );
    });
  });
}