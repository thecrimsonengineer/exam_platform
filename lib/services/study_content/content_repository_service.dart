import '../../data/csp11_blueprint.dart';
import '../../models/content_repository.dart';
import '../../models/study_content.dart';
import 'cloud_content_repository.dart';
import 'content_import_service.dart';
import 'content_validator.dart';

/// Application service for the Admin Content Repository.
///
/// Firebase is now the active persistence layer for Admin operations.
/// LocalStudyContentRepository remains available for migration/cache work
/// but is no longer the Admin repository source of truth.
class ContentRepositoryService {
  final CloudContentRepository _storage;

  ContentRepositoryService({CloudContentRepository? storage})
    : _storage = storage ?? CloudContentRepository();

  Future<List<ContentPackageSummary>> loadPackages() async {
    final drafts = await _storage.loadDrafts();
    final published = await _storage.loadPublished();

    final byId = <String, ContentPackageSummary>{};

    // Draft and published copies are intentionally stored independently.
    // The same StudyContent ID may legitimately exist once as a draft
    // and once as a published copy.
    for (final content in drafts) {
      byId['draft:${content.id}'] = ContentPackageSummary(
        content: content,
        isPublishedCopy: false,
      );
    }

    for (final content in published) {
      byId['published:${content.id}'] = ContentPackageSummary(
        content: content,
        isPublishedCopy: true,
      );
    }

    final packages = byId.values.toList();

    packages.sort((a, b) {
      final domainA = domainForContentId(a.content.domainId)?.number ?? 999;
      final domainB = domainForContentId(b.content.domainId)?.number ?? 999;

      final domainCompare = domainA.compareTo(domainB);

      if (domainCompare != 0) {
        return domainCompare;
      }

      final competencyCompare = a.content.competencyNumber.compareTo(
        b.content.competencyNumber,
      );

      if (competencyCompare != 0) {
        return competencyCompare;
      }

      final versionCompare = b.content.version.compareTo(a.content.version);

      if (versionCompare != 0) {
        return versionCompare;
      }

      // Keep draft/published copies deterministic when they have the
      // same content ID and version.
      final publishedCompare = a.isPublishedCopy.toString().compareTo(
        b.isPublishedCopy.toString(),
      );

      if (publishedCompare != 0) {
        return publishedCompare;
      }

      return a.content.title.compareTo(b.content.title);
    });

    return packages;
  }

  Future<List<ContentPackageSummary>> loadHistoryForCompetency(
    String competencyId,
  ) async {
    final packages = await loadPackages();

    final filtered = packages
        .where((item) => item.content.competencyId == competencyId)
        .toList();

    filtered.sort((a, b) {
      final versionCompare = b.content.version.compareTo(a.content.version);

      if (versionCompare != 0) {
        return versionCompare;
      }

      final publishedCompare = b.isPublishedCopy.toString().compareTo(
        a.isPublishedCopy.toString(),
      );

      if (publishedCompare != 0) {
        return publishedCompare;
      }

      return b.content.id.compareTo(a.content.id);
    });

    return filtered;
  }

  Future<List<String>> validatePackage(StudyContent content) async {
    final issues = const ContentValidator().validate(content);

    return issues
        .where((issue) => issue.severity == ContentImportIssueSeverity.error)
        .map((issue) => issue.message)
        .toList();
  }

  Future<void> submitForReview(StudyContent content) async {
    await _storage.updateDraftStatus(content.id, 'review');
  }

  Future<void> validateAndMark(StudyContent content) async {
    if (content.status.toLowerCase() != 'review') {
      throw StateError(
        'Only REVIEW content can be validated. '
        'Submit the package for review first.',
      );
    }

    final errors = await validatePackage(content);

    if (errors.isNotEmpty) {
      throw StateError(
        'Validation failed:\n'
        '${errors.map((error) => '• $error').join('\n')}',
      );
    }

    await _storage.updateDraftStatus(content.id, 'validated');
  }

  Future<void> publish(StudyContent content) async {
    final errors = await validatePackage(content);

    if (errors.isNotEmpty) {
      throw StateError(
        'Publishing is blocked because validation errors remain.',
      );
    }

    final latest = await _storage.loadDraft(content.id);

    if (latest == null) {
      throw StateError(
        'The selected package is no longer present in the draft repository.',
      );
    }

    if (latest.status.toLowerCase() != 'validated') {
      throw StateError(
        'Only VALIDATED content can be published from the Repository.',
      );
    }

    await _storage.publish(latest);
  }

  Future<void> archive(StudyContent content) async {
    if (content.status.toLowerCase() != 'published') {
      throw StateError('Only PUBLISHED content can be archived.');
    }

    await _storage.updatePublishedStatus(content.id, 'archived');
  }

  Future<StudyContent> createRevision(StudyContent source) async {
    final nextVersion = source.version + 1;
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final revisionId = '${source.competencyId.trim()}-v$nextVersion-$timestamp';

    final json = Map<String, dynamic>.from(source.toJson())
      ..['id'] = revisionId
      ..['version'] = nextVersion
      ..['status'] = 'draft';

    final revision = StudyContent.fromJson(json);

    await _storage.saveDraft(revision);

    return revision;
  }

  Future<void> saveDraft(StudyContent content) async {
    await _storage.saveDraft(content);
  }

  Future<void> deleteDraft(StudyContent content) async {
    await _storage.deleteDraft(content.id);
  }

  Future<void> deletePublishedVersion(StudyContent content) async {
    final status = content.status.trim().toLowerCase();

    if (status != 'published' && status != 'archived') {
      throw StateError(
        'Only PUBLISHED or ARCHIVED content can be permanently deleted.',
      );
    }

    await _storage.deletePublished(content.id);
  }

  Future<void> refreshStatusAsDraft(StudyContent content, String status) async {
    const allowed = <String>{'draft', 'review', 'validated'};

    final normalized = status.toLowerCase();

    if (!allowed.contains(normalized)) {
      throw StateError('Unsupported draft lifecycle status: $status');
    }

    await _storage.updateDraftStatus(content.id, normalized);
  }
}
