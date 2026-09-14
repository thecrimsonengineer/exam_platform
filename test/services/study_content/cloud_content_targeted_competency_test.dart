import 'package:exam_platform/models/study_content.dart';
import 'package:exam_platform/services/study_content/cloud_content_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

StudyContent _content({
  required String id,
  required String domainId,
  required String competencyId,
  required int version,
  String status = 'published',
}) {
  return StudyContent.fromJson(<String, dynamic>{
    'id': id,
    'domainId': domainId,
    'competencyId': competencyId,
    'competencyNumber': 1,
    'title': id,
    'status': status,
    'version': version,
    'topics': <Map<String, dynamic>>[],
  });
}

void main() {
  test('targeted published-competency read ignores unrelated and draft copies',
      () async {
    final firestore = FakeFirebaseFirestore();
    final repository = CloudContentRepository(firestore: firestore);

    await repository.saveDraft(
      _content(
        id: 'target-draft',
        domainId: 'domain_01',
        competencyId: 'd01_c01',
        version: 99,
        status: 'draft',
      ),
    );

    await repository.publish(
      _content(
        id: 'target-v1',
        domainId: 'domain_01',
        competencyId: 'd01_c01',
        version: 1,
      ),
    );

    await repository.publish(
      _content(
        id: 'unrelated',
        domainId: 'domain_02',
        competencyId: 'd02_c01',
        version: 8,
      ),
    );

    final loaded = await repository.loadPublishedCompetency(
      domainId: 'domain_01',
      competencyId: 'd01_c01',
    );

    expect(loaded, isNotNull);
    expect(loaded!.id, 'target-v1');
    expect(loaded.domainId, 'domain_01');
    expect(loaded.competencyId, 'd01_c01');
    expect(loaded.status, 'published');
  });

  test('targeted read excludes archived published copy', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = CloudContentRepository(firestore: firestore);

    await repository.publish(
      _content(
        id: 'archived-target',
        domainId: 'domain_01',
        competencyId: 'd01_c01',
        version: 1,
      ),
    );

    await repository.updatePublishedStatus('archived-target', 'archived');

    final loaded = await repository.loadPublishedCompetency(
      domainId: 'domain_01',
      competencyId: 'd01_c01',
    );

    expect(loaded, isNull);
  });
}
