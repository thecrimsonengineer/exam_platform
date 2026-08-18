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

    expect(stored?.status, 'review');

    await repository.validateAndMark(content);

    stored = await cloudRepository.loadDraft(content.id);

    expect(stored?.status, 'validated');
  });

  test('G.3: repository rejects publishing non-validated content', () async {
    final firestore = FakeFirebaseFirestore();

    final cloudRepository = CloudContentRepository(firestore: firestore);

    final repository = ContentRepositoryService(storage: cloudRepository);

    final content = _sampleContent(status: 'draft');

    await repository.saveDraft(content);

    expect(() => repository.publish(content), throwsA(isA<StateError>()));

    final published = await cloudRepository.loadPublishedContent(content.id);

    expect(published, isNull);
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
    expect(published?.id, content.id);
    expect(published?.version, content.version);
    expect(published?.status, 'published');
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

      expect(revision.version, 2);
      expect(revision.status, 'draft');
      expect(revision.id, isNot(original.id));

      final storedOriginal = await cloudRepository.loadDraft(original.id);

      expect(storedOriginal, isNotNull);
      expect(storedOriginal?.id, original.id);
      expect(storedOriginal?.version, 1);
      expect(storedOriginal?.status, 'draft');

      final storedRevision = await cloudRepository.loadDraft(revision.id);

      expect(storedRevision, isNotNull);
      expect(storedRevision?.version, 2);
      expect(storedRevision?.status, 'draft');
    },
  );

  test('G.3: published copy remains independent from draft revision', () async {
    final firestore = FakeFirebaseFirestore();

    final cloudRepository = CloudContentRepository(firestore: firestore);

    final repository = ContentRepositoryService(storage: cloudRepository);

    final publishedSource = _sampleContent(
      id: 'd07_c01-v1',
      version: 1,
      status: 'validated',
    );

    await repository.saveDraft(publishedSource);
    await repository.publish(publishedSource);

    final revision = await repository.createRevision(publishedSource);

    expect(revision.version, 2);
    expect(revision.status, 'draft');

    final published = await cloudRepository.loadPublishedContent(
      publishedSource.id,
    );

    expect(published, isNotNull);
    expect(published?.id, publishedSource.id);
    expect(published?.version, 1);
    expect(published?.status, 'published');

    final draftRevision = await cloudRepository.loadDraft(revision.id);

    expect(draftRevision, isNotNull);
    expect(draftRevision?.version, 2);
    expect(draftRevision?.status, 'draft');
  });

  test('G.3: archived published versions remain retrievable', () async {
    final firestore = FakeFirebaseFirestore();

    final cloudRepository = CloudContentRepository(firestore: firestore);

    final repository = ContentRepositoryService(storage: cloudRepository);

    final content = _sampleContent(
      id: 'd07_c01-v1',
      version: 1,
      status: 'validated',
    );

    await repository.saveDraft(content);
    await repository.publish(content);

    final published = await cloudRepository.loadPublishedContent(content.id);

    expect(published, isNotNull);

    await repository.archive(published!);

    final archived = await cloudRepository.loadPublishedContent(content.id);

    expect(archived, isNotNull);
    expect(archived?.id, content.id);
    expect(archived?.version, 1);
    expect(archived?.status, 'archived');
  });

  test(
    'G.4: revision version is based on the highest existing repository version',
    () async {
      final firestore = FakeFirebaseFirestore();

      final cloudRepository = CloudContentRepository(firestore: firestore);

      final repository = ContentRepositoryService(storage: cloudRepository);

      final version1 = _sampleContent(id: 'd07_c01-v1', version: 1);

      final version3 = _sampleContent(id: 'd07_c01-v3', version: 3);

      await repository.saveDraft(version1);
      await repository.saveDraft(version3);

      final revision = await repository.createRevision(version1);

      expect(revision.version, 4);
      expect(revision.status, 'draft');
    },
  );

  test(
    'G.4: revision preserves the source content without modifying it',
    () async {
      final firestore = FakeFirebaseFirestore();

      final cloudRepository = CloudContentRepository(firestore: firestore);

      final repository = ContentRepositoryService(storage: cloudRepository);

      final source = _sampleContent(id: 'd07_c01-v2', version: 2);

      await repository.saveDraft(source);

      final revision = await repository.createRevision(source);

      expect(revision.version, 3);
      expect(revision.title, source.title);
      expect(revision.competencyId, source.competencyId);
      expect(revision.domainId, source.domainId);

      final storedSource = await cloudRepository.loadDraft(source.id);

      expect(storedSource, isNotNull);
      expect(storedSource?.id, source.id);
      expect(storedSource?.version, 2);
      expect(storedSource?.title, source.title);
      expect(storedSource?.status, source.status);
    },
  );

  test('G.4: published version is not modified by a draft revision', () async {
    final firestore = FakeFirebaseFirestore();

    final cloudRepository = CloudContentRepository(firestore: firestore);

    final repository = ContentRepositoryService(storage: cloudRepository);

    final source = _sampleContent(
      id: 'd07_c01-v2',
      version: 2,
      status: 'validated',
    );

    await repository.saveDraft(source);
    await repository.publish(source);

    final revision = await repository.createRevision(source);

    expect(revision.version, 3);
    expect(revision.status, 'draft');

    final published = await cloudRepository.loadPublishedContent(source.id);

    expect(published, isNotNull);
    expect(published?.id, source.id);
    expect(published?.version, 2);
    expect(published?.status, 'published');

    final revisionStored = await cloudRepository.loadDraft(revision.id);

    expect(revisionStored, isNotNull);
    expect(revisionStored?.version, 3);
    expect(revisionStored?.status, 'draft');
  });

  test('G.5: published content can transition only to archived', () async {
    final firestore = FakeFirebaseFirestore();

    final cloudRepository = CloudContentRepository(firestore: firestore);

    final repository = ContentRepositoryService(storage: cloudRepository);

    final content = _sampleContent(
      id: 'd07_c01-v1',
      version: 1,
      status: 'validated',
    );

    await repository.saveDraft(content);
    await repository.publish(content);

    final published = await cloudRepository.loadPublishedContent(content.id);

    expect(published, isNotNull);

    await repository.archive(published!);

    final stored = await cloudRepository.loadPublishedContent(content.id);

    expect(stored?.status, 'archived');

    expect(() => repository.archive(published), throwsA(isA<StateError>()));
  });

  test('G.5: draft lifecycle cannot skip review', () async {
    final firestore = FakeFirebaseFirestore();

    final cloudRepository = CloudContentRepository(firestore: firestore);

    final repository = ContentRepositoryService(storage: cloudRepository);

    final content = _sampleContent(status: 'draft');

    await repository.saveDraft(content);

    expect(
      () => repository.refreshStatusAsDraft(content, 'validated'),
      throwsA(isA<StateError>()),
    );

    final stored = await cloudRepository.loadDraft(content.id);

    expect(stored?.status, 'draft');
  });

  test('G.5: review can transition only to validated', () async {
    final firestore = FakeFirebaseFirestore();

    final cloudRepository = CloudContentRepository(firestore: firestore);

    final repository = ContentRepositoryService(storage: cloudRepository);

    final content = _sampleContent(status: 'review');

    await repository.saveDraft(content);

    await repository.refreshStatusAsDraft(content, 'validated');

    final stored = await cloudRepository.loadDraft(content.id);

    expect(stored?.status, 'validated');
  });

  test(
    'G.5: validated content cannot move backwards in draft lifecycle',
    () async {
      final firestore = FakeFirebaseFirestore();

      final cloudRepository = CloudContentRepository(firestore: firestore);

      final repository = ContentRepositoryService(storage: cloudRepository);

      final content = _sampleContent(status: 'validated');

      await repository.saveDraft(content);

      expect(
        () => repository.refreshStatusAsDraft(content, 'review'),
        throwsA(isA<StateError>()),
      );

      expect(
        () => repository.refreshStatusAsDraft(content, 'draft'),
        throwsA(isA<StateError>()),
      );

      final stored = await cloudRepository.loadDraft(content.id);

      expect(stored?.status, 'validated');
    },
  );

  test(
    'G.5: published and archived content cannot be changed through draft lifecycle',
    () async {
      final firestore = FakeFirebaseFirestore();

      final cloudRepository = CloudContentRepository(firestore: firestore);

      final repository = ContentRepositoryService(storage: cloudRepository);

      final published = _sampleContent(
        id: 'd07_c01-v1',
        version: 1,
        status: 'published',
      );

      await repository.saveDraft(published);

      expect(
        () => repository.refreshStatusAsDraft(published, 'review'),
        throwsA(isA<StateError>()),
      );

      final archived = _sampleContent(
        id: 'd07_c01-v2',
        version: 2,
        status: 'archived',
      );

      await repository.saveDraft(archived);

      expect(
        () => repository.refreshStatusAsDraft(archived, 'review'),
        throwsA(isA<StateError>()),
      );
    },
  );

  // ---------------------------------------------------------------------------
  // G.6: Repository deletion integrity
  // ---------------------------------------------------------------------------

  test(
    'G.6: existing draft can be deleted from the draft repository',
    () async {
      final firestore = FakeFirebaseFirestore();

      final cloudRepository = CloudContentRepository(firestore: firestore);

      final repository = ContentRepositoryService(storage: cloudRepository);

      final content = _sampleContent(
        id: 'd07_c01-v1',
        version: 1,
        status: 'draft',
      );

      await repository.saveDraft(content);

      expect(await cloudRepository.loadDraft(content.id), isNotNull);

      await repository.deleteDraft(content);

      expect(await cloudRepository.loadDraft(content.id), isNull);

      final packages = await repository.loadPackages();

      expect(packages.where((item) => item.content.id == content.id), isEmpty);
    },
  );

  test('G.6: deleting a missing draft throws StateError', () async {
    final firestore = FakeFirebaseFirestore();

    final cloudRepository = CloudContentRepository(firestore: firestore);

    final repository = ContentRepositoryService(storage: cloudRepository);

    final content = _sampleContent(
      id: 'd07_c01-missing',
      version: 1,
      status: 'draft',
    );

    expect(() => repository.deleteDraft(content), throwsA(isA<StateError>()));
  });

  test('G.6: published copy can be permanently deleted', () async {
    final firestore = FakeFirebaseFirestore();

    final cloudRepository = CloudContentRepository(firestore: firestore);

    final repository = ContentRepositoryService(storage: cloudRepository);

    final content = _sampleContent(
      id: 'd07_c01-v1',
      version: 1,
      status: 'validated',
    );

    await repository.saveDraft(content);
    await repository.publish(content);

    final published = await cloudRepository.loadPublishedContent(content.id);

    expect(published, isNotNull);

    await repository.deletePublishedVersion(published!);

    expect(await cloudRepository.loadPublishedContent(content.id), isNull);
  });

  test('G.6: archived copy can be permanently deleted', () async {
    final firestore = FakeFirebaseFirestore();

    final cloudRepository = CloudContentRepository(firestore: firestore);

    final repository = ContentRepositoryService(storage: cloudRepository);

    final content = _sampleContent(
      id: 'd07_c01-v1',
      version: 1,
      status: 'validated',
    );

    await repository.saveDraft(content);
    await repository.publish(content);

    final published = await cloudRepository.loadPublishedContent(content.id);

    expect(published, isNotNull);

    await repository.archive(published!);

    final archived = await cloudRepository.loadPublishedContent(content.id);

    expect(archived, isNotNull);
    expect(archived?.status, 'archived');

    await repository.deletePublishedVersion(archived!);

    expect(await cloudRepository.loadPublishedContent(content.id), isNull);
  });

  test(
    'G.6: published content cannot be deleted through draft deletion',
    () async {
      final firestore = FakeFirebaseFirestore();

      final cloudRepository = CloudContentRepository(firestore: firestore);

      final repository = ContentRepositoryService(storage: cloudRepository);

      final content = _sampleContent(
        id: 'd07_c01-v1',
        version: 1,
        status: 'published',
      );

      await repository.saveDraft(content);

      expect(() => repository.deleteDraft(content), throwsA(isA<StateError>()));

      expect(await cloudRepository.loadDraft(content.id), isNotNull);
    },
  );

  test(
    'G.6: archived content cannot be deleted through draft deletion',
    () async {
      final firestore = FakeFirebaseFirestore();

      final cloudRepository = CloudContentRepository(firestore: firestore);

      final repository = ContentRepositoryService(storage: cloudRepository);

      final content = _sampleContent(
        id: 'd07_c01-v1',
        version: 1,
        status: 'archived',
      );

      await repository.saveDraft(content);

      expect(() => repository.deleteDraft(content), throwsA(isA<StateError>()));

      expect(await cloudRepository.loadDraft(content.id), isNotNull);
    },
  );

  test(
    'G.6: invalid published lifecycle state cannot be permanently deleted',
    () async {
      final firestore = FakeFirebaseFirestore();

      final cloudRepository = CloudContentRepository(firestore: firestore);

      final repository = ContentRepositoryService(storage: cloudRepository);

      final content = _sampleContent(
        id: 'd07_c01-v1',
        version: 1,
        status: 'draft',
      );

      await cloudRepository.publish(content);

      await cloudRepository.updatePublishedStatus(
        content.id,
        'draft',
      );

      final published = await cloudRepository.loadPublishedContent(content.id);

      expect(published, isNotNull);
      expect(published?.status, 'draft');

      expect(
        () => repository.deletePublishedVersion(published!),
        throwsA(isA<StateError>()),
      );

      expect(await cloudRepository.loadPublishedContent(content.id), isNotNull);
    },
  );

  test(
    'G.6: deleting draft does not delete independent published copy',
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

      await repository.deleteDraft(content);

      expect(await cloudRepository.loadDraft(content.id), isNull);

      final published = await cloudRepository.loadPublishedContent(content.id);

      expect(published, isNotNull);
      expect(published?.id, content.id);
      expect(published?.version, 1);
    },
  );

  test(
    'G.6: deleting published copy does not delete independent draft copy',
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

      final published = await cloudRepository.loadPublishedContent(content.id);

      expect(published, isNotNull);

      await repository.deletePublishedVersion(published!);

      expect(await cloudRepository.loadPublishedContent(content.id), isNull);

      final draft = await cloudRepository.loadDraft(content.id);

      expect(draft, isNotNull);
      expect(draft?.id, content.id);
      expect(draft?.version, 1);
      expect(draft?.status, 'validated');
    },
  );

  test(
    'G.6: deleting archived version removes it from repository history',
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
      await repository.publish(content);

      final published = await cloudRepository.loadPublishedContent(content.id);

      expect(published, isNotNull);

      await repository.archive(published!);

      final archived = await cloudRepository.loadPublishedContent(content.id);

      expect(archived, isNotNull);
      expect(archived?.status, 'archived');

      await repository.deletePublishedVersion(archived!);

      final history = await repository.loadHistoryForCompetency(
        content.competencyId,
      );

      expect(
        history.where(
          (item) =>
              item.content.id == content.id &&
              item.isPublishedCopy,
        ),
        isEmpty,
      );
    },
  );

  test('G.6: deleting a missing published version throws StateError', () async {
    final firestore = FakeFirebaseFirestore();

    final cloudRepository = CloudContentRepository(firestore: firestore);

    final repository = ContentRepositoryService(storage: cloudRepository);

    final content = _sampleContent(
      id: 'd07_c01-missing-published',
      version: 1,
      status: 'published',
    );

    expect(
      () => repository.deletePublishedVersion(content),
      throwsA(isA<StateError>()),
    );
  });
}
