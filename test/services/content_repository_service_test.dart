import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:exam_platform/models/study_content.dart';
import 'package:exam_platform/services/study_content/cloud_content_repository.dart';
import 'package:exam_platform/services/study_content/content_repository_service.dart';

StudyContent _sampleContent({
  String id = 'd07_c01-v1',
  int version = 1,
  String status = 'draft',
}) {
  return StudyContent(
    id: id,
    domainId: 'd07',
    competencyId: 'd07_c01',
    competencyNumber: 1,
    title: 'Needs Assessment',
    status: status,
    version: version,
    subtopics: [
      StudySubtopic(
        id: 'd07_c01_st01',
        title: 'Risk Assessment',
        learningObjectives: const [
          'Understand risk assessment principles',
        ],
        mainContent: [
          MainContentTopic(
            id: 'topic_01',
            title: 'Risk Assessment Process',
            blocks: const [
              ContentBlock(
                id: 'block_01',
                type: 'text',
                data: {
                  'content':
                      'Risk assessment identifies hazards and evaluates risks.',
                },
              ),
            ],
            quizzes: const [],
          ),
        ],
        questions: const [],
        keyPoints: const [],
        examples: const [],
        caseStudies: const [],
        formulas: const [],
        references: const [],
        examTips: const [],
        commonMistakes: const [],
        keyTakeaways: const [],
        quizzes: const [],
      ),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('G.1: repository saves and loads a draft', () async {
    final firestore = FakeFirebaseFirestore();

    final cloudRepository = CloudContentRepository(
      firestore: firestore,
    );

    final repository = ContentRepositoryService(
      storage: cloudRepository,
    );

    final content = _sampleContent();

    await repository.saveDraft(content);

    final packages = await repository.loadPackages();

    expect(packages, hasLength(1));
    expect(packages.first.content.id, content.id);
    expect(packages.first.content.domainId, 'd07');
    expect(packages.first.content.competencyId, 'd07_c01');
    expect(packages.first.content.version, 1);
    expect(packages.first.content.status, 'draft');
    expect(packages.first.isPublishedCopy, isFalse);
  });

  test(
    'G.1: repository creates a new draft revision with incremented version',
    () async {
      final firestore = FakeFirebaseFirestore();

      final cloudRepository = CloudContentRepository(
        firestore: firestore,
      );

      final repository = ContentRepositoryService(
        storage: cloudRepository,
      );

      final original = _sampleContent();

      await repository.saveDraft(original);

      final revision = await repository.createRevision(original);

      expect(revision.id, isNot(original.id));
      expect(revision.competencyId, original.competencyId);
      expect(revision.version, 2);
      expect(revision.status, 'draft');

      final packages = await repository.loadPackages();

      expect(
        packages.any(
          (package) =>
              package.content.id == revision.id &&
              package.content.version == 2,
        ),
        isTrue,
      );
    },
  );

  test('G.1: repository filters competency history correctly', () async {
    final firestore = FakeFirebaseFirestore();

    final cloudRepository = CloudContentRepository(
      firestore: firestore,
    );

    final repository = ContentRepositoryService(
      storage: cloudRepository,
    );

    await repository.saveDraft(
      _sampleContent(
        id: 'd07_c01-v1',
        version: 1,
      ),
    );

    await repository.saveDraft(
      _sampleContent(
        id: 'd07_c01-v2',
        version: 2,
      ),
    );

    final otherCompetency = StudyContent(
      id: 'd07_c02-v1',
      domainId: 'd07',
      competencyId: 'd07_c02',
      competencyNumber: 2,
      title: 'Another Competency',
      status: 'draft',
      version: 1,
      subtopics: const [],
    );

    await repository.saveDraft(otherCompetency);

    final history = await repository.loadHistoryForCompetency(
      'd07_c01',
    );

    expect(history, hasLength(2));
    expect(
      history.map((item) => item.content.version),
      [2, 1],
    );
  });

  test(
    'G.2: repository keeps draft and published copies independently',
    () async {
      final firestore = FakeFirebaseFirestore();

      final cloudRepository = CloudContentRepository(
        firestore: firestore,
      );

      final repository = ContentRepositoryService(
        storage: cloudRepository,
      );

      final content = _sampleContent(
        id: 'd07_c01-v1',
        version: 1,
        status: 'validated',
      );

      await repository.saveDraft(content);
      await cloudRepository.publish(content);

      final packages = await repository.loadPackages();

      expect(packages, hasLength(2));

      expect(
        packages.where((item) => item.isPublishedCopy),
        hasLength(1),
      );

      expect(
        packages.where((item) => !item.isPublishedCopy),
        hasLength(1),
      );
    },
  );
}