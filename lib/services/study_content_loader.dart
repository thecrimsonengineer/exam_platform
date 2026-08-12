import 'package:flutter/foundation.dart';

import '../models/study_content.dart';
import 'study_content/local_study_content_repository.dart';

/// Loads CSP study content for the student-facing portal.
///
/// Student content is loaded only from the Published Repository.
///
/// Draft, Review, and other authoring states are never exposed here.
///
/// When multiple published versions exist for the same competency,
/// the student portal uses only the highest published version.
class StudyContentLoader {
  const StudyContentLoader();

  // ==========================================================
  // Published Repository
  // ==========================================================

  Future<List<StudyContent>> loadPublishedContent() async {
    final repository = LocalStudyContentRepository();

    final published = await repository.loadPublished();

    return _latestPublishedVersions(published);
  }

  /// Returns the latest published version of each competency.
  ///
  /// Published repository history is preserved, but the student portal
  /// must display only one live version per competency.
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
  Future<StudyContent> loadPublishedByContentId(String contentId) async {
    final repository = LocalStudyContentRepository();

    final content = await repository.loadPublishedContent(contentId);

    if (content == null) {
      throw StateError('Published content "$contentId" was not found.');
    }

    if (content.status.toLowerCase() != 'published') {
      throw StateError('Content "$contentId" is not published.');
    }

    return content;
  }

  /// Loads the latest published competency using Domain ID
  /// and Competency ID.
  Future<StudyContent> loadStudyContent({
    required String domainId,
    required String competencyId,
  }) async {
    final repository = LocalStudyContentRepository();
    final published = await repository.loadPublished();

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
      return latest;
    }

    throw StateError(
      'Published competency "$competencyId" was not found '
      'in domain "$domainId".',
    );
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

  // These methods are intentionally no longer used for student
  // content delivery. They remain unavailable here so the
  // Student Portal cannot accidentally fall back to bundled
  // draft/test assets.

  @visibleForTesting
  Future<Never> loadContentIndex() async {
    throw UnsupportedError(
      'Student content is loaded from the Published Repository.',
    );
  }

  @visibleForTesting
  Future<Never> loadDomain(String domainId) async {
    throw UnsupportedError(
      'Student content is loaded from the Published Repository.',
    );
  }

  @visibleForTesting
  Future<Never> loadCompetencyFile(String assetPath) async {
    throw UnsupportedError(
      'Student content is loaded from the Published Repository.',
    );
  }
}
