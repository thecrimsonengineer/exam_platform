import 'package:exam_platform/models/study_content.dart';
import 'package:exam_platform/services/study_content/cloud_content_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

StudyContent _content({
  required String id,
  required String domainId,
  required String competencyId,
  required int competencyNumber,
  required int version,
  String status = 'validated',
}) {
  return StudyContent(
    id: id,
    domainId: domainId,
    competencyId: competencyId,
    competencyNumber: competencyNumber,
    title: '$competencyId v$version',
    status: status,
    version: version,
    topics: const [],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loadPublishedDomain returns only latest published content in domain',
      () async {
    final firestore = FakeFirebaseFirestore();
    final repository = CloudContentRepository(firestore: firestore);

    await repository.publish(
      _content(
        id: 'd05_c01-v1',
        domainId: 'd05',
        competencyId: 'd05_c01',
        competencyNumber: 1,
        version: 1,
      ),
    );

    await repository.publish(
      _content(
        id: 'd05_c01-v2',
        domainId: 'd05',
        competencyId: 'd05_c01',
        competencyNumber: 1,
        version: 2,
      ),
    );

    await repository.publish(
      _content(
        id: 'd05_c02-v1',
        domainId: 'd05',
        competencyId: 'd05_c02',
        competencyNumber: 2,
        version: 1,
      ),
    );

    await repository.publish(
      _content(
        id: 'd06_c01-v1',
        domainId: 'd06',
        competencyId: 'd06_c01',
        competencyNumber: 1,
        version: 1,
      ),
    );

    await repository.saveDraft(
      _content(
        id: 'd05_c03-draft',
        domainId: 'd05',
        competencyId: 'd05_c03',
        competencyNumber: 3,
        version: 1,
        status: 'draft',
      ),
    );

    final loaded = await repository.loadPublishedDomain('d05');

    expect(loaded, hasLength(2));
    expect(
      loaded.map((content) => content.competencyId).toSet(),
      <String>{'d05_c01', 'd05_c02'},
    );

    final latestC01 =
        loaded.singleWhere((content) => content.competencyId == 'd05_c01');
    expect(latestC01.version, 2);

    expect(
      loaded.every(
        (content) =>
            content.domainId == 'd05' &&
            content.status.toLowerCase() == 'published',
      ),
      isTrue,
    );
  });

  test('loadPublishedDomain excludes archived published copies', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = CloudContentRepository(firestore: firestore);

    await repository.publish(
      _content(
        id: 'd05_c01-v1',
        domainId: 'd05',
        competencyId: 'd05_c01',
        competencyNumber: 1,
        version: 1,
      ),
    );

    await repository.updatePublishedStatus('d05_c01-v1', 'archived');

    final loaded = await repository.loadPublishedDomain('d05');

    expect(loaded, isEmpty);
  });
}
