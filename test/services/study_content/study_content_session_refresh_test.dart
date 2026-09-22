import 'package:exam_platform/models/study_content.dart';
import 'package:exam_platform/services/auth/learner_local_identity.dart';
import 'package:exam_platform/services/online_access/learner_online_access_gate.dart';
import 'package:exam_platform/services/online_access/learner_online_access_runtime.dart';
import 'package:exam_platform/services/online_access/learner_online_access_session_controller.dart';
import 'package:exam_platform/services/study_content/cloud_content_repository.dart';
import 'package:exam_platform/services/study_content/cloud_published_content_repository.dart';
import 'package:exam_platform/services/study_content/student_content_cache_repository.dart';
import 'package:exam_platform/services/study_content/student_study_content_session_cache.dart';
import 'package:exam_platform/services/study_content_loader.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

StudyContent _content({required String id, required int version}) {
  return StudyContent.fromJson(<String, dynamic>{
    'id': id,
    'domainId': 'domain_01',
    'competencyId': 'd01_c01',
    'competencyNumber': 1,
    'title': 'Competency',
    'status': 'published',
    'version': version,
    'topics': <Map<String, dynamic>>[],
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LearnerOnlineAccessSessionController accessController;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    StudentStudyContentSessionCache.clear();
    LearnerLocalIdentity.activate('student-test');

    accessController = LearnerOnlineAccessSessionController(
      validator: _AuthorizedValidator(),
      currentUserId: () => LearnerLocalIdentity.currentUserId,
    );
    LearnerOnlineAccessRuntime.bind(
      userId: 'student-test',
      controller: accessController,
    );
    await accessController.authorizeForUser('student-test');
  });

  tearDown(() {
    LearnerOnlineAccessRuntime.unbind(accessController);
    accessController.dispose();
    LearnerLocalIdentity.clear();
    StudentStudyContentSessionCache.clear();
  });

  test('successful targeted load populates session cache', () async {
    final firestore = FakeFirebaseFirestore();
    final cloud = CloudContentRepository(firestore: firestore);
    await cloud.publish(_content(id: 'v1', version: 1));

    final preferences = await SharedPreferences.getInstance();
    final loader = StudyContentLoader(
      repository: CloudPublishedContentRepository(repository: cloud),
      cacheRepository: StudentContentCacheRepository(preferences: preferences),
    );

    final loaded = await loader.loadStudyContent(
      domainId: 'domain_01',
      competencyId: 'd01_c01',
    );

    expect(loaded.version, 1);

    final session = loader.peekSessionStudyContent(
      domainId: 'domain_01',
      competencyId: 'd01_c01',
    );

    expect(session?.version, 1);
  });

  test(
    'targeted refresh replaces session cache with newer published version',
    () async {
      final firestore = FakeFirebaseFirestore();
      final cloud = CloudContentRepository(firestore: firestore);
      await cloud.publish(_content(id: 'v1', version: 1));

      final preferences = await SharedPreferences.getInstance();
      final loader = StudyContentLoader(
        repository: CloudPublishedContentRepository(repository: cloud),
        cacheRepository: StudentContentCacheRepository(
          preferences: preferences,
        ),
      );

      await loader.loadStudyContent(
        domainId: 'domain_01',
        competencyId: 'd01_c01',
      );

      await cloud.publish(_content(id: 'v2', version: 2));

      final refreshed = await loader.refreshStudyContent(
        domainId: 'domain_01',
        competencyId: 'd01_c01',
      );

      expect(refreshed.version, 2);
      expect(
        loader
            .peekSessionStudyContent(
              domainId: 'domain_01',
              competencyId: 'd01_c01',
            )
            ?.version,
        2,
      );
    },
  );
}

class _AuthorizedValidator implements LearnerOnlineAccessValidator {
  @override
  Future<LearnerOnlineAccessResult> validate({
    bool forceRefreshToken = false,
  }) async {
    return LearnerOnlineAccessResult(
      status: LearnerOnlineAccessStatus.authorized,
      checkedAt: DateTime.utc(2026),
    );
  }
}
