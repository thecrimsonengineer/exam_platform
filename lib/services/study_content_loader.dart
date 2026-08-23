import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/study_content.dart';
import 'study_content/cloud_published_content_repository.dart';
import 'study_content/student_content_cache_repository.dart';

/// Loads CSP study content for the student-facing portal.
///
/// Firebase is the authoritative source for published content.
///
/// When Firebase is unavailable, the loader falls back to the last valid
/// published content stored in the student cache.
///
/// Draft, Review, Validated, and Archived content are never exposed through
/// this service.
class StudyContentLoader {
  const StudyContentLoader({
    this.repository,
    this.cacheRepository,
  });

  final CloudPublishedContentRepository? repository;
  final StudentContentCacheRepository? cacheRepository;

  CloudPublishedContentRepository get _repository =>
      repository ?? CloudPublishedContentRepository();

  /// Creates the default student cache repository.
  ///
  /// SharedPreferences is resolved asynchronously because the student cache
  /// is backed by local persistent storage.
  Future<StudentContentCacheRepository> _resolveCache() async {
    if (cacheRepository != null) {
      return cacheRepository!;
    }

    final preferences = await SharedPreferences.getInstance();

    return StudentContentCacheRepository(
      preferences: preferences,
    );
  }

  // ==========================================================
  // Published Repository + Cache
  // ==========================================================

  /// Loads the latest published version of each competency.
  ///
  /// Firebase is attempted first. Successfully retrieved published content
  /// is written to the local student cache.
  ///
  /// If Firebase fails, the last valid published cache is returned instead.
  Future<List<StudyContent>> loadPublishedContent() async {
    final cache = await _resolveCache();

    try {
      final published = await _repository.loadPublished();

      final latest = _latestPublishedVersions(published);

      for (final content in latest) {
        await cache.save(content);
      }

      return latest;
    } catch (_) {
      final cached = await cache.loadAll();

      if (cached.isNotEmpty) {
        return _latestPublishedVersions(cached);
      }

      throw StateError(
        'Published CSP11 content is unavailable because the cloud '
        'repository could not be reached and no cached content exists.',
      );
    }
  }

  /// Returns the latest published version of each competency.
  List<StudyContent> _latestPublishedVersions(
    List<StudyContent> published,
  ) {
    final latestByCompetency = <String, StudyContent>{};

    for (final content in published) {
      if (content.status.toLowerCase() != 'published') {
        continue;
      }

      final existing = latestByCompetency[content.competencyId];

      if (existing == null || content.version > existing.version) {
        latestByCompetency[content.competencyId] = content;
      }
    }

    return latestByCompetency.values.toList();
  }

  /// Loads one published competency by Content ID.
  ///
  /// Firebase is attempted first. If Firebase fails, the cached published
  /// content with the requested ID is used.
  Future<StudyContent> loadPublishedByContentId(
    String contentId,
  ) async {
    final cache = await _resolveCache();

    try {
      final content = await _repository.loadPublishedContent(contentId);

      if (content == null) {
        throw StateError(
          'Published content "$contentId" was not found.',
        );
      }

      await cache.save(content);

      return content;
    } catch (_) {
      final cached = await cache.load(contentId);

      if (cached != null &&
          cached.status.toLowerCase() == 'published') {
        return cached;
      }

      throw StateError(
        'Published content "$contentId" is unavailable.',
      );
    }
  }

  /// Loads the latest published competency using Domain ID
  /// and Competency ID.
  ///
  /// Firebase is attempted first. If Firebase fails, the latest valid
  /// cached version for the competency is returned.
  Future<StudyContent> loadStudyContent({
    required String domainId,
    required String competencyId,
  }) async {
    final cache = await _resolveCache();

    try {
      final published = await _repository.loadPublished();

      StudyContent? latest;

      for (final content in published) {
        if (content.domainId != domainId ||
            content.competencyId != competencyId ||
            content.status.toLowerCase() != 'published') {
          continue;
        }

        if (latest == null || content.version > latest.version) {
          latest = content;
        }
      }

      if (latest != null) {
        await cache.save(latest);
        return latest;
      }

      throw StateError(
        'Published competency "$competencyId" was not found '
        'in domain "$domainId".',
      );
    } catch (_) {
      final cached = await cache.loadLatestForCompetency(
        competencyId,
      );

      if (cached != null &&
          cached.domainId == domainId &&
          cached.status.toLowerCase() == 'published') {
        return cached;
      }

      throw StateError(
        'Published competency "$competencyId" is unavailable '
        'in domain "$domainId".',
      );
    }
  }

  // ==========================================================
  // Published Domains
  // ==========================================================

  /// Returns unique published domains.
  Future<List<Map<String, dynamic>>> loadDomains() async {
    final published = await loadPublishedContent();

    final domains = <String, Map<String, dynamic>>{};

    for (final content in published) {
      domains[content.domainId] = {
        'id': content.domainId,
        'title': content.domainId,
      };
    }

    return domains.values.toList();
  }

  // ==========================================================
  // Published Competencies
  // ==========================================================

  /// Returns the latest published version of each competency
  /// belonging to a domain.
  Future<List<Map<String, dynamic>>> loadCompetencies(
    String domainId,
  ) async {
    final published = await loadPublishedContent();

    return published
        .where(
          (content) =>
              content.domainId == domainId &&
              content.status.toLowerCase() == 'published',
        )
        .map(
          (content) => <String, dynamic>{
            'id': content.competencyId,
            'domainId': content.domainId,
            'competencyNumber': content.competencyNumber,
            'title': content.title,
            'status': content.status,
            'version': content.version,
          },
        )
        .toList();
  }

  /// Finds a published competency.
  Future<Map<String, dynamic>?> loadCompetencyIndexEntry(
    String domainId,
    String competencyId,
  ) async {
    final competencies = await loadCompetencies(domainId);

    for (final competency in competencies) {
      if (competency['id']?.toString() == competencyId) {
        return competency;
      }
    }

    return null;
  }

  // ==========================================================
  // Legacy Asset Methods
  // ==========================================================

  /// Student content must never fall back to bundled assets.
  @visibleForTesting
  Future<Never> loadContentIndex() async {
    throw UnsupportedError(
      'Student content is loaded from the Firebase Published Repository '
      'or the published student cache.',
    );
  }

  /// Student content must never fall back to bundled assets.
  @visibleForTesting
  Future<Never> loadDomain(String domainId) async {
    throw UnsupportedError(
      'Student content is loaded from the Firebase Published Repository '
      'or the published student cache.',
    );
  }

  /// Student content must never fall back to bundled assets.
  @visibleForTesting
  Future<Never> loadCompetencyFile(String assetPath) async {
    throw UnsupportedError(
      'Student content is loaded from the Firebase Published Repository '
      'or the published student cache.',
    );
  }
}