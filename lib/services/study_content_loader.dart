import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/study_content.dart';
import 'auth/learner_local_identity.dart';
import 'online_access/learner_online_access_runtime.dart';
import 'study_content/cloud_published_content_repository.dart';
import 'study_content/learner_content_package_delivery_service.dart';
import 'study_content/student_content_cache.dart';
import 'study_content/student_study_content_session_cache.dart';
import 'study_content/uid_scoped_protected_content_cache_repository.dart';

/// Loads CSP study content for the student-facing portal.
///
/// Learner StudyContent is delivered through Firebase-authorized immutable
/// packages from the private Supabase package boundary.
///
/// Persistent protected bytes are never an offline fallback. They are readable
/// only while the same Firebase UID is currently online-authorized.
///
/// Draft, Review, Validated, and Archived content are never exposed through
/// this service.
class StudyContentLoader {
  const StudyContentLoader({
    this.repository,
    this.cacheRepository,
    this.deliveryService,
  });

  /// Explicit legacy repository injection is retained for non-runtime
  /// compatibility tests and tooling only. The zero-argument learner loader
  /// never constructs or reads this Firestore repository.
  final CloudPublishedContentRepository? repository;
  final StudentContentCache? cacheRepository;
  final LearnerContentPackageDeliveryService? deliveryService;

  CloudPublishedContentRepository get _injectedRepository {
    final injected = repository;

    if (injected == null) {
      throw StateError(
        'Legacy StudyContent repository access requires explicit injection.',
      );
    }

    return injected;
  }

  LearnerContentPackageDeliveryService get _deliveryService =>
      deliveryService ?? LearnerContentPackageDeliveryService();

  /// Creates the default student cache repository.
  ///
  /// SharedPreferences is resolved asynchronously because the student cache
  /// is backed by local persistent storage.
  Future<StudentContentCache> _resolveCache() async {
    if (cacheRepository != null) {
      return cacheRepository!;
    }

    final userId = LearnerLocalIdentity.requireCurrentUserId();
    final accessBoundary = LearnerOnlineAccessRuntime.requireBoundaryFor(
      userId,
    );
    final preferences = await SharedPreferences.getInstance();
    final cache = UidScopedProtectedContentCacheRepository(
      store: SharedPreferencesProtectedStudentContentCacheStore(preferences),
      userId: userId,
      accessBoundary: accessBoundary,
    );

    await cache.migrateLegacyIfAuthorized();
    return cache;
  }

  /// Returns published content already verified during this app session.
  ///
  /// This is process memory only and must never be treated as an offline
  /// repository.
  StudyContent? peekSessionStudyContent({
    required String domainId,
    required String competencyId,
  }) {
    final userId = LearnerLocalIdentity.currentUserId;

    if (userId == null || !LearnerOnlineAccessRuntime.isAuthorizedFor(userId)) {
      return null;
    }

    return StudentStudyContentSessionCache.get(
      domainId: domainId,
      competencyId: competencyId,
    );
  }

  /// Refreshes one competency from the authoritative published cloud boundary.
  ///
  /// No persistent-cache fallback is used here because this method is the
  /// silent online revalidation path for content already visible from RAM.
  Future<StudyContent> refreshStudyContent({
    required String domainId,
    required String competencyId,
  }) async {
    if (repository != null) {
      return _loadStudyContentFromInjectedRepository(
        domainId: domainId,
        competencyId: competencyId,
      );
    }

    final latest = await _deliveryService.loadCompetency(competencyId);
    _validateDeliveredScope(
      content: latest,
      domainId: domainId,
      competencyId: competencyId,
    );
    StudentStudyContentSessionCache.put(latest);
    return latest;
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

  /// Loads the latest published content for one domain only.
  ///
  /// Firebase is authoritative. If the targeted cloud read fails, the
  /// existing published student cache may be used as a fallback for this
  /// domain only.
  Future<List<StudyContent>> loadPublishedDomainContent(String domainId) async {
    final cache = await _resolveCache();

    try {
      final published = await _injectedRepository.loadPublishedDomain(domainId);

      final latest = _latestPublishedVersions(
        published
            .where(
              (content) =>
                  content.domainId == domainId &&
                  content.status.toLowerCase() == 'published',
            )
            .toList(),
      );

      for (final content in latest) {
        await cache.save(content);
      }

      return latest;
    } catch (_) {
      final cached = await cache.loadAll();

      final domainCached = cached
          .where(
            (content) =>
                content.domainId == domainId &&
                content.status.toLowerCase() == 'published',
          )
          .toList();

      if (domainCached.isNotEmpty) {
        return _latestPublishedVersions(domainCached);
      }

      throw StateError(
        'Published content for domain "$domainId" is unavailable.',
      );
    }
  }

  Future<List<StudyContent>> loadPublishedContent() async {
    final cache = await _resolveCache();

    try {
      final published = await _injectedRepository.loadPublished();

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
  List<StudyContent> _latestPublishedVersions(List<StudyContent> published) {
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
  Future<StudyContent> loadPublishedByContentId(String contentId) async {
    final cache = await _resolveCache();

    try {
      final content = await _injectedRepository.loadPublishedContent(contentId);

      if (content == null) {
        throw StateError('Published content "$contentId" was not found.');
      }

      await cache.save(content);

      return content;
    } catch (_) {
      final cached = await cache.load(contentId);

      if (cached != null && cached.status.toLowerCase() == 'published') {
        return cached;
      }

      throw StateError('Published content "$contentId" is unavailable.');
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
    if (repository != null) {
      return _loadStudyContentFromInjectedRepository(
        domainId: domainId,
        competencyId: competencyId,
      );
    }

    final latest = await _deliveryService.loadCompetency(competencyId);
    _validateDeliveredScope(
      content: latest,
      domainId: domainId,
      competencyId: competencyId,
    );
    StudentStudyContentSessionCache.put(latest);
    return latest;
  }

  @visibleForTesting
  Future<StudyContent> _loadStudyContentFromInjectedRepository({
    required String domainId,
    required String competencyId,
  }) async {
    final cache = await _resolveCache();
    final latest = await _injectedRepository.loadPublishedCompetency(
      domainId: domainId,
      competencyId: competencyId,
    );

    if (latest == null) {
      throw StateError(
        'Published competency "$competencyId" was not found '
        'in domain "$domainId".',
      );
    }

    await cache.save(latest);
    StudentStudyContentSessionCache.put(latest);
    return latest;
  }

  void _validateDeliveredScope({
    required StudyContent content,
    required String domainId,
    required String competencyId,
  }) {
    if (content.domainId != domainId ||
        content.competencyId != competencyId ||
        content.status.toLowerCase() != 'published') {
      throw StateError(
        'Verified content package does not match the requested learner scope.',
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
  Future<List<Map<String, dynamic>>> loadCompetencies(String domainId) async {
    final published = await loadPublishedDomainContent(domainId);

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
      'Student content is loaded from the online-authorized published package '
      'boundary.',
    );
  }

  /// Student content must never fall back to bundled assets.
  @visibleForTesting
  Future<Never> loadDomain(String domainId) async {
    throw UnsupportedError(
      'Student content is loaded from the online-authorized published package '
      'boundary.',
    );
  }

  /// Student content must never fall back to bundled assets.
  @visibleForTesting
  Future<Never> loadCompetencyFile(String assetPath) async {
    throw UnsupportedError(
      'Student content is loaded from the online-authorized published package '
      'boundary.',
    );
  }
}
