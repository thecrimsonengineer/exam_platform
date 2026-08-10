import 'package:flutter/foundation.dart';

import '../models/study_content.dart';
import 'study_content/local_study_content_repository.dart';

/// Loads CSP study content for the student-facing portal.
///
/// Student content is loaded only from the Published Repository.
///
/// Draft, Review, and other authoring states are never exposed here.
class StudyContentLoader {
  const StudyContentLoader();

  // ==========================================================
  // Published Repository
  // ==========================================================

  Future<List<StudyContent>> loadPublishedContent() async {
    final repository = LocalStudyContentRepository();
    return repository.loadPublished();
  }

  /// Loads one published competency by Content ID.
  Future<StudyContent> loadPublishedByContentId(
    String contentId,
  ) async {
    final repository = LocalStudyContentRepository();

    final content = await repository.loadPublishedContent(contentId);

    if (content == null) {
      throw StateError(
        'Published content "$contentId" was not found.',
      );
    }

    return content;
  }

  /// Loads a published competency using Domain ID and Competency ID.
  ///
  /// The published repository stores the complete StudyContent object,
  /// so the student portal searches the published collection rather
  /// than reading bundled JSON assets.
  Future<StudyContent> loadStudyContent({
    required String domainId,
    required String competencyId,
  }) async {
    final repository = LocalStudyContentRepository();
    final published = await repository.loadPublished();

    for (final content in published) {
      if (content.domainId == domainId &&
          content.competencyId == competencyId) {
        if (content.status.toLowerCase() != 'published') {
          throw StateError(
            'Content "$competencyId" is not published.',
          );
        }

        return content;
      }
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

  /// Returns all published competencies belonging to a domain.
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
  //
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