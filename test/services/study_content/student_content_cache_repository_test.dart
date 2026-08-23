import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../lib/models/study_content.dart';
import '../../../lib/services/study_content/student_content_cache_repository.dart';

void main() {
  group('StudentContentCacheRepository', () {
    late StudentContentCacheRepository repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});

      final preferences = await SharedPreferences.getInstance();

      repository = StudentContentCacheRepository(preferences: preferences);
    });

    test('starts with an empty cache', () async {
      final contents = await repository.loadAll();

      expect(contents, isEmpty);
    });

    test('stores and retrieves published content', () async {
      final content = _content(
        id: 'content_d07_c03_v1',
        competencyId: 'd07_c03',
        version: 1,
        status: 'Published',
      );

      await repository.save(content);

      final cached = await repository.load(content.id);

      expect(cached, isNotNull);
      expect(cached!.id, content.id);
      expect(cached.competencyId, 'd07_c03');
      expect(cached.version, 1);
      expect(cached.status.toLowerCase(), 'published');
    });

    test('does not cache unpublished content', () async {
      final draft = _content(
        id: 'content_d07_c03_v2',
        competencyId: 'd07_c03',
        version: 2,
        status: 'Draft',
      );

      expect(() => repository.save(draft), throwsArgumentError);

      expect(await repository.load(draft.id), isNull);
      expect(await repository.loadAll(), isEmpty);
    });

    test('newer content version replaces older cached version', () async {
      final v1 = _content(
        id: 'content_d07_c03_v1',
        competencyId: 'd07_c03',
        version: 1,
        status: 'Published',
      );

      final v2 = _content(
        id: 'content_d07_c03_v2',
        competencyId: 'd07_c03',
        version: 2,
        status: 'Published',
      );

      await repository.save(v1);
      await repository.save(v2);

      final cached = await repository.loadLatestForCompetency('d07_c03');

      expect(cached, isNotNull);
      expect(cached!.version, 2);
      expect(cached.id, 'content_d07_c03_v2');
    });

    test('older content cannot replace newer cached version', () async {
      final v2 = _content(
        id: 'content_d07_c03_v2',
        competencyId: 'd07_c03',
        version: 2,
        status: 'Published',
      );

      final v1 = _content(
        id: 'content_d07_c03_v1',
        competencyId: 'd07_c03',
        version: 1,
        status: 'Published',
      );

      await repository.save(v2);
      await repository.save(v1);

      final cached = await repository.loadLatestForCompetency('d07_c03');

      expect(cached, isNotNull);
      expect(cached!.version, 2);
      expect(cached.id, 'content_d07_c03_v2');
    });

    test('does not allow a different content id with the same version '
        'to replace an existing entry', () async {
      final first = _content(
        id: 'content_d07_c03_v1',
        competencyId: 'd07_c03',
        version: 1,
        status: 'Published',
      );

      final second = _content(
        id: 'content_d07_c03_v1_replacement',
        competencyId: 'd07_c03',
        version: 1,
        status: 'Published',
      );

      await repository.save(first);
      await repository.save(second);

      final cached = await repository.loadLatestForCompetency('d07_c03');

      expect(cached, isNotNull);
      expect(cached!.id, 'content_d07_c03_v1');
    });

    test('reports cached version for a competency', () async {
      final content = _content(
        id: 'content_d07_c03_v4',
        competencyId: 'd07_c03',
        version: 4,
        status: 'Published',
      );

      await repository.save(content);

      expect(await repository.cachedVersionForCompetency('d07_c03'), 4);
    });

    test('returns null version when competency is not cached', () async {
      expect(await repository.cachedVersionForCompetency('d07_c03'), isNull);
    });

    test('persists cache across repository instances', () async {
      final content = _content(
        id: 'content_d07_c03_v3',
        competencyId: 'd07_c03',
        version: 3,
        status: 'Published',
      );

      await repository.save(content);

      final preferences = await SharedPreferences.getInstance();

      final secondRepository = StudentContentCacheRepository(
        preferences: preferences,
      );

      final cached = await secondRepository.load(content.id);

      expect(cached, isNotNull);
      expect(cached!.id, content.id);
      expect(cached.version, 3);
    });

    test('removes cached content explicitly', () async {
      final content = _content(
        id: 'content_d07_c03_v1',
        competencyId: 'd07_c03',
        version: 1,
        status: 'Published',
      );

      await repository.save(content);

      expect(await repository.load(content.id), isNotNull);

      await repository.remove(content.id);

      expect(await repository.load(content.id), isNull);
      expect(await repository.loadAll(), isEmpty);
    });

    test('clear removes all cached content', () async {
      final first = _content(
        id: 'content_d07_c01_v1',
        competencyId: 'd07_c01',
        version: 1,
        status: 'Published',
      );

      final second = _content(
        id: 'content_d07_c03_v2',
        competencyId: 'd07_c03',
        version: 2,
        status: 'Published',
      );

      await repository.save(first);
      await repository.save(second);

      expect((await repository.loadAll()).length, 2);

      await repository.clear();

      expect(await repository.loadAll(), isEmpty);
    });
  });
}

StudyContent _content({
  required String id,
  required String competencyId,
  required int version,
  required String status,
}) {
  return StudyContent(
    id: id,
    domainId: 'domain_07',
    competencyId: competencyId,
    competencyNumber: 3,
    title: 'Test Content',
    status: status,
    version: version,
    subtopics: const [],
  );
}
