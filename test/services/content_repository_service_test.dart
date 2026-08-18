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
        learningObjectives: const ['Understand risk assessment principles'],
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

    final cloudRepository = CloudContentRepository(firestore: firestore);

    final repository = ContentRepositoryService(storage: cloudRepository);

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

      final cloudRepository = CloudContentRepository(firestore: firestore);

      final repository = ContentRepositoryService(storage: cloudRepository);

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
              package.content.id == revision.id && package.content.version == 2,
        ),
        isTrue,
      );
    },
  );

  test('G.1: repository filters competency history correctly', () async {
    final firestore = FakeFirebaseFirestore();

    final cloudRepository = CloudContentRepository(firestore: firestore);

    final repository = ContentRepositoryService(storage: cloudRepository);

    await repository.saveDraft(_sampleContent(id: 'd07_c01-v1', version: 1));

    await repository.saveDraft(_sampleContent(id: 'd07_c01-v2', version: 2));

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

    final history = await repository.loadHistoryForCompetency('d07_c01');

    expect(history, hasLength(2));
    expect(history.map((item) => item.content.version), [2, 1]);
  });

  test(
    'G.2: repository keeps draft and published copies independently',
    () async {
      final firestore = FakeFirebaseFirestore();

      final cloudRepository = CloudContentRepository(firestore: firestore);

      final repository = ContentRepositoryService(storage: cloudRepository);

      final content = _sampleContent(
        id: 'd07_c01-v1',
        version: 1,
        status: 'validated',
      );

      await repository.saveDraft(content);
      await cloudRepository.publish(content);

      final packages = await repository.loadPackages();

      expect(packages, hasLength(2));

      expect(packages.where((item) => item.isPublishedCopy), hasLength(1));

      expect(packages.where((item) => !item.isPublishedCopy), hasLength(1));
    },
  );

  test('G.3: repository enforces draft lifecycle transitions', () async {
    final firestore = FakeFirebaseFirestore();

    final cloudRepository = CloudContentRepository(firestore: firestore);

    final repository = ContentRepositoryService(storage: cloudRepository);

    final content = _sampleContent();

    await repository.saveDraft(content);

    await repository.submitForReview(content);

    var stored = await cloudRepository.loadDraft(content.id);

    expect(stored, isNotNull);
    expect(stored!.status, 'review');

    final reviewContent = _sampleContent(
      id: content.id,
      version: content.version,
      status: 'review',
    );

    await repository.validateAndMark(reviewContent);

    stored = await cloudRepository.loadDraft(content.id);

    expect(stored, isNotNull);
    expect(stored!.status, 'validated');
  });

  test('G.3: repository rejects publishing non-validated content', () async {
    final firestore = FakeFirebaseFirestore();

    final cloudRepository = CloudContentRepository(firestore: firestore);

    final repository = ContentRepositoryService(storage: cloudRepository);

    final content = _sampleContent(status: 'draft');

    await repository.saveDraft(content);

    expect(() => repository.publish(content), throwsA(isA<StateError>()));
  });

  test('G.3: repository publishes validated content', () async {
    final firestore = FakeFirebaseFirestore();

    final cloudRepository = CloudContentRepository(firestore: firestore);

    final repository = ContentRepositoryService(storage: cloudRepository);

    final content = _sampleContent(status: 'validated');

    await repository.saveDraft(content);
    await repository.publish(content);

    final published = await cloudRepository.loadPublishedContent(content.id);

    expect(published, isNotNull);
    expect(published!.id, content.id);
    expect(published.version, content.version);
    expect(published.status, 'validated');
  });

  test(
    'G.3: revision creates a new version without modifying the original',
    () async {
      final firestore = FakeFirebaseFirestore();

      final cloudRepository = CloudContentRepository(firestore: firestore);

      final repository = ContentRepositoryService(storage: cloudRepository);

      final original = _sampleContent(
        id: 'd07_c01-v1',
        version: 1,
        status: 'draft',
      );

      await repository.saveDraft(original);

      final revision = await repository.createRevision(original);

      expect(revision.id, isNot(original.id));
      expect(revision.version, 2);
      expect(revision.status, 'draft');

      final storedOriginal = await cloudRepository.loadDraft(original.id);

      expect(storedOriginal, isNotNull);
      expect(storedOriginal!.id, original.id);
      expect(storedOriginal.version, 1);
      expect(storedOriginal.status, 'draft');

      final storedRevision = await cloudRepository.loadDraft(revision.id);

      expect(storedRevision, isNotNull);
      expect(storedRevision!.version, 2);
      expect(storedRevision.status, 'draft');
    },
  );

  test('G.3: published copy remains independent from draft revision', () async {
    final firestore = FakeFirebaseFirestore();

    final cloudRepository = CloudContentRepository(firestore: firestore);

    final repository = ContentRepositoryService(storage: cloudRepository);

    final validated = _sampleContent(
      id: 'd07_c01-v1',
      version: 1,
      status: 'validated',
    );

    await repository.saveDraft(validated);
    await repository.publish(validated);

    final revision = await repository.createRevision(validated);

    final published = await cloudRepository.loadPublishedContent(validated.id);

    final draftRevision = await cloudRepository.loadDraft(revision.id);

    expect(published, isNotNull);
    expect(published!.version, 1);
    expect(published.status, 'validated');

    expect(draftRevision, isNotNull);
    expect(draftRevision!.version, 2);
    expect(draftRevision.status, 'draft');
  });

  test('G.3: archived published versions remain retrievable', () async {
    final firestore = FakeFirebaseFirestore();

    final cloudRepository = CloudContentRepository(firestore: firestore);

    final repository = ContentRepositoryService(storage: cloudRepository);

    final published = _sampleContent(
      id: 'd07_c01-v1',
      version: 1,
      status: 'validated',
    );

    await repository.saveDraft(published);
    await repository.publish(published);

    final publishedContent = await cloudRepository.loadPublishedContent(
      published.id,
    );

    expect(publishedContent, isNotNull);

    final archiveTarget = _sampleContent(
      id: published.id,
      version: published.version,
      status: 'published',
    );

    await repository.archive(archiveTarget);

    final archived = await cloudRepository.loadPublishedContent(published.id);

    expect(archived, isNotNull);
    expect(archived!.id, published.id);
    expect(archived.version, published.version);
    expect(archived.status, 'archived');
  });

  test(
    'G.4: revision version is based on the highest existing repository version',
    () async {
      final firestore = FakeFirebaseFirestore();

      final cloudRepository = CloudContentRepository(firestore: firestore);

      final repository = ContentRepositoryService(storage: cloudRepository);

      final version1 = _sampleContent(
        id: 'd07_c01-v1',
        version: 1,
        status: 'draft',
      );

      final version2 = _sampleContent(
        id: 'd07_c01-v2',
        version: 2,
        status: 'draft',
      );

      await repository.saveDraft(version1);
      await repository.saveDraft(version2);

      final revision = await repository.createRevision(version1);

      expect(revision.version, 3);
      expect(revision.competencyId, 'd07_c01');
      expect(revision.status, 'draft');
      expect(revision.id, isNot(version1.id));
      expect(revision.id, isNot(version2.id));

      final original = await cloudRepository.loadDraft(version1.id);

      final existing = await cloudRepository.loadDraft(version2.id);

      final created = await cloudRepository.loadDraft(revision.id);

      expect(original, isNotNull);
      expect(existing, isNotNull);
      expect(created, isNotNull);

      expect(original!.version, 1);
      expect(existing!.version, 2);
      expect(created!.version, 3);
    },
  );

  test(
    'G.4: revision preserves the source content without modifying it',
    () async {
      final firestore = FakeFirebaseFirestore();

      final cloudRepository = CloudContentRepository(firestore: firestore);

      final repository = ContentRepositoryService(storage: cloudRepository);

      final original = _sampleContent(
        id: 'd07_c01-v1',
        version: 1,
        status: 'draft',
      );

      await repository.saveDraft(original);

      final revision = await repository.createRevision(original);

      final storedOriginal = await cloudRepository.loadDraft(original.id);

      final storedRevision = await cloudRepository.loadDraft(revision.id);

      expect(storedOriginal, isNotNull);
      expect(storedRevision, isNotNull);

      expect(storedOriginal!.id, original.id);
      expect(storedOriginal.version, 1);
      expect(storedOriginal.status, 'draft');

      expect(storedRevision!.id, revision.id);
      expect(storedRevision.version, 2);
      expect(storedRevision.status, 'draft');

      expect(
        storedRevision.subtopics.first.title,
        storedOriginal.subtopics.first.title,
      );

      expect(
        storedRevision.subtopics.first.mainContent.first.title,
        storedOriginal.subtopics.first.mainContent.first.title,
      );
    },
  );

  test('G.4: published version is not modified by a draft revision', () async {
    final firestore = FakeFirebaseFirestore();

    final cloudRepository = CloudContentRepository(firestore: firestore);

    final repository = ContentRepositoryService(storage: cloudRepository);

    final published = _sampleContent(
      id: 'd07_c01-v5',
      version: 5,
      status: 'validated',
    );

    await repository.saveDraft(published);
    await repository.publish(published);

    final draftRevision = await repository.createRevision(published);

    expect(draftRevision.version, 6);
    expect(draftRevision.status, 'draft');

    final publishedCopy = await cloudRepository.loadPublishedContent(
      published.id,
    );

    expect(publishedCopy, isNotNull);
    expect(publishedCopy!.version, 5);
    expect(publishedCopy.status, 'validated');

    final revision = await cloudRepository.loadDraft(draftRevision.id);

    expect(revision, isNotNull);
    expect(revision!.version, 6);
    expect(revision.status, 'draft');
  });
}
