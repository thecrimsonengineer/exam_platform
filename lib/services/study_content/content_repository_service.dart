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

  Future<List<StudyContent>> loadDrafts() async {
    return _storage.loadDrafts();
  }

  Future<List<StudyContent>> loadPublished() async {
    return _storage.loadPublished();
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
    final current = await _storage.loadDraft(content.id);

    if (current == null) {
      throw StateError(
        'The selected package is no longer present in the draft repository.',
      );
    }

    if (current.status.toLowerCase() != 'draft') {
      throw StateError('Only DRAFT content can be submitted for review.');
    }

    await _storage.updateDraftStatus(content.id, 'review');
  }

  Future<void> validateAndMark(StudyContent content) async {
    final current = await _storage.loadDraft(content.id);

    if (current == null) {
      throw StateError(
        'The selected package is no longer present in the draft repository.',
      );
    }

    if (current.status.toLowerCase() != 'review') {
      throw StateError(
        'Only REVIEW content can be validated. '
        'Submit the package for review first.',
      );
    }

    final errors = await validatePackage(current);

    if (errors.isNotEmpty) {
      throw StateError(
        'Validation failed:\n'
        '${errors.map((error) => 'â€¢ $error').join('\n')}',
      );
    }

    await _storage.updateDraftStatus(content.id, 'validated');
  }

  Future<void> publish(StudyContent content) async {
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

    final errors = await validatePackage(latest);

    if (errors.isNotEmpty) {
      throw StateError(
        'Publishing is blocked because validation errors remain.',
      );
    }

    await _storage.publish(latest);
  }

  /// Archives the currently stored published copy.
  ///
  /// The repository state is authoritative. The supplied [content] object
  /// is only used to identify the published version. This prevents stale
  /// or draft objects from incorrectly blocking an archive operation.
  Future<void> archive(StudyContent content) async {
    final current = await _storage.loadPublishedContent(content.id);

    if (current == null) {
      throw StateError(
        'The selected package is no longer present in the published repository.',
      );
    }

    final status = current.status.trim().toLowerCase();

    if (status != 'published') {
      throw StateError('Only PUBLISHED content can be archived.');
    }

    await _storage.updatePublishedStatus(content.id, 'archived');
  }

  /// Creates the next repository version for the competency.
  ///
  /// The next version is determined from the highest existing draft or
  /// published version, rather than only from the supplied source version.
  /// This prevents duplicate version numbers when a revision is created
  /// from an older source.
  Future<StudyContent> createRevision(StudyContent source) async {
    final history = await loadHistoryForCompetency(source.competencyId);

    final highestVersion = history.fold<int>(
      source.version,
      (highest, package) =>
          package.content.version > highest ? package.content.version : highest,
    );

    final nextVersion = highestVersion + 1;
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
    final status = content.status.trim().toLowerCase();

    // Existing validated/review/published fixtures and repository objects
    // may legitimately be written directly to the cloud repository during
    // repository-level testing or migration. Lifecycle transitions themselves
    // remain enforced by the dedicated lifecycle methods.
    if (status.isEmpty) {
      throw StateError('Content lifecycle status cannot be empty.');
    }

    await _storage.saveDraft(content);
  }

  Future<void> deleteDraft(StudyContent content) async {
    final current = await _storage.loadDraft(content.id);

    if (current == null) {
      throw StateError(
        'The selected draft is no longer present in the repository.',
      );
    }

    final status = current.status.trim().toLowerCase();

    if (status == 'published' || status == 'archived') {
      throw StateError(
        'Published lifecycle states cannot be deleted as drafts.',
      );
    }

    await _storage.deleteDraft(content.id);
  }

  /// Permanently deletes the currently stored published or archived copy.
  ///
  /// The stored repository version is authoritative. This prevents a stale
  /// [content] object from incorrectly determining whether deletion is
  /// allowed.
  Future<void> deletePublishedVersion(StudyContent content) async {
    final current = await _storage.loadPublishedContent(content.id);

    if (current == null) {
      throw StateError(
        'The selected published version is no longer present in the repository.',
      );
    }

    final status = current.status.trim().toLowerCase();

    if (status != 'published' && status != 'archived') {
      throw StateError(
        'Only PUBLISHED or ARCHIVED content can be permanently deleted.',
      );
    }

    await _storage.deletePublished(content.id);
  }

  /// Changes the status of an existing draft.
  ///
  /// G.5 enforces sequential lifecycle transitions:
  ///
  /// DRAFT -> REVIEW
  /// REVIEW -> VALIDATED
  ///
  /// A draft cannot jump directly to VALIDATED and a validated package
  /// cannot be moved backwards through this method.
  Future<void> refreshStatusAsDraft(StudyContent content, String status) async {
    final requested = status.trim().toLowerCase();

    const allowed = <String>{'draft', 'review', 'validated'};

    if (!allowed.contains(requested)) {
      throw StateError('Unsupported draft lifecycle status: $status');
    }

    final current = await _storage.loadDraft(content.id);

    if (current == null) {
      throw StateError(
        'The selected package is no longer present in the draft repository.',
      );
    }

    final existing = current.status.trim().toLowerCase();

    if (existing == requested) {
      return;
    }

    final validTransition =
        (existing == 'draft' && requested == 'review') ||
        (existing == 'review' && requested == 'validated');

    if (!validTransition) {
      throw StateError(
        'Invalid draft lifecycle transition: '
        '${existing.toUpperCase()} -> ${requested.toUpperCase()}.',
      );
    }

    await _storage.updateDraftStatus(content.id, requested);
  }
}
