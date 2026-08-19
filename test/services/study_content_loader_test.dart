import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:exam_platform/models/study_content.dart';
import 'package:exam_platform/services/study_content/cloud_content_repository.dart';
import 'package:exam_platform/services/study_content/cloud_published_content_repository.dart';
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
  group('StudyContentLoader Firebase published-content integration', () {
    late FakeFirebaseFirestore firestore;
    late CloudPublishedContentRepository repository;
    late StudyContentLoader loader;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      repository = CloudPublishedContentRepository(
        repository: CloudContentRepository(firestore: firestore),
      );
      loader = StudyContentLoader(repository: repository);
    });

    test('loads only published content from Firebase', () async {
      final cloud = CloudContentRepository(firestore: firestore);

      await cloud.saveDraft(_content(id: 'draft_1', status: 'draft', version: 1));
      await cloud.publish(_content(id: 'published_1', status: 'published', version: 1));
      await cloud.updatePublishedStatus('published_1', 'archived');
      await cloud.publish(_content(id: 'published_2', status: 'published', version: 2));

      final published = await loader.loadPublishedContent();

      expect(published.length, 1);
      expect(published.single.id, 'published_2');
      expect(published.single.status, 'published');
    });

    test('selects the latest published version for a competency', () async {
      final cloud = CloudContentRepository(firestore: firestore);

      await cloud.publish(
        _content(id: 'cp_v1', status: 'published', version: 1),
      );
      await cloud.publish(
        _content(id: 'cp_v2', status: 'published', version: 2),
      );

      final published = await loader.loadPublishedContent();

      expect(published.length, 1);
      expect(published.single.id, 'cp_v2');
      expect(published.single.version, 2);
    });

    test('loads a published competency by domain and competency', () async {
      final cloud = CloudContentRepository(firestore: firestore);

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
    });

    test('does not return archived content by content ID', () async {
      final cloud = CloudContentRepository(firestore: firestore);

      await cloud.publish(
        _content(id: 'cp_archived', status: 'published', version: 1),
      );
      await cloud.updatePublishedStatus('cp_archived', 'archived');

      await expectLater(
        loader.loadPublishedByContentId('cp_archived'),
        throwsA(isA<StateError>()),
      );
    });
  });
}
