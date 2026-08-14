import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/study_content.dart';

/// Local persistent repository for Admin Study Content.
///
/// Draft and Published content are deliberately stored separately.
///
/// Drafts:
///   csp11.study_content.drafts.v1
///
/// Published:
///   csp11.study_content.published.v1
///
/// This is intentionally a local repository. A future API/database
/// repository can replace it without changing the Studio architecture.
class LocalStudyContentRepository {
  LocalStudyContentRepository();

  static const String _draftStorageKey = 'csp11.study_content.drafts.v1';

  static const String _publishedStorageKey = 'csp11.study_content.published.v1';

  static const Set<String> _draftLifecycleStatuses = {
    'draft',
    'review',
    'validated',
  };

  static const Set<String> _publishedLifecycleStatuses = {
    'published',
    'archived',
  };

  // ---------------------------------------------------------------------------
  // DRAFTS
  // ---------------------------------------------------------------------------

  /// Loads all saved draft content.
  Future<List<StudyContent>> loadDrafts() async {
    return _loadContentList(_draftStorageKey);
  }

  /// Loads one draft by Content ID.
  Future<StudyContent?> loadDraft(String contentId) async {
    return _loadContentById(storageKey: _draftStorageKey, contentId: contentId);
  }

  /// Saves or replaces a draft.
  ///
  /// Existing draft behavior is intentionally preserved:
  /// - Existing ID = replace
  /// - New ID = insert at beginning
  Future<void> saveDraft(StudyContent content) async {
    final status = content.status.trim().toLowerCase();

    if (!_draftLifecycleStatuses.contains(status)) {
      throw StateError(
        'Draft storage only accepts draft, review, or validated content. '
        'Received: ${content.status}',
      );
    }

    await _saveContent(
      storageKey: _draftStorageKey,
      content: content,
      storageLabel: 'draft',
    );
  }

  /// Updates the lifecycle status of an item that is still in authoring
  /// storage. The content itself is preserved unchanged.
  ///
  /// Allowed transitions:
  ///
  /// draft     -> draft, review
  /// review    -> draft, review, validated
  /// validated -> review, validated
  Future<void> updateDraftStatus(String contentId, String status) async {
    final normalized = status.trim().toLowerCase();

    if (!_draftLifecycleStatuses.contains(normalized)) {
      throw StateError('Unsupported draft lifecycle status: $status');
    }

    final content = await loadDraft(contentId);

    if (content == null) {
      throw StateError('Draft "$contentId" was not found.');
    }

    final currentStatus = content.status.trim().toLowerCase();

    const allowedTransitions = <String, Set<String>>{
      'draft': {'draft', 'review'},
      'review': {'draft', 'review', 'validated'},
      'validated': {'review', 'validated'},
    };

    final allowedNextStatuses = allowedTransitions[currentStatus];

    if (allowedNextStatuses == null ||
        !allowedNextStatuses.contains(normalized)) {
      throw StateError(
        'Invalid lifecycle transition: '
        '$currentStatus -> $normalized.',
      );
    }

    final json = Map<String, dynamic>.from(content.toJson())
      ..['status'] = normalized;

    await _saveContent(
      storageKey: _draftStorageKey,
      content: StudyContent.fromJson(json),
      storageLabel: 'draft',
    );
  }

  /// Deletes one draft by Content ID.
  Future<void> deleteDraft(String contentId) async {
    await _deleteContent(
      storageKey: _draftStorageKey,
      contentId: contentId,
      storageLabel: 'draft',
    );
  }

  /// Deletes all drafts.
  Future<void> clearDrafts() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_draftStorageKey);
  }

  // ---------------------------------------------------------------------------
  // PUBLISHED CONTENT
  // ---------------------------------------------------------------------------

  /// Loads all published content.
  ///
  /// Published content is stored separately from drafts.
  Future<List<StudyContent>> loadPublished() async {
    return _loadContentList(_publishedStorageKey);
  }

  /// Loads one published competency by Content ID.
  Future<StudyContent?> loadPublishedContent(String contentId) async {
    return _loadContentById(
      storageKey: _publishedStorageKey,
      contentId: contentId,
    );
  }

  /// Publishes validated content into the separate Published repository.
  ///
  /// The published copy receives:
  ///   status = published
  ///
  /// All other StudyContent data remains unchanged.
  Future<void> publish(StudyContent content) async {
    final currentStatus = content.status.trim().toLowerCase();

    if (currentStatus != 'validated') {
      throw StateError('Only VALIDATED content can be published.');
    }

    final publishedJson = Map<String, dynamic>.from(content.toJson());

    publishedJson['status'] = 'published';

    final publishedContent = StudyContent.fromJson(publishedJson);

    await _saveContent(
      storageKey: _publishedStorageKey,
      content: publishedContent,
      storageLabel: 'published',
    );
  }

  /// Updates the lifecycle status of a published version without deleting
  /// the historical record.
  ///
  /// Allowed transitions:
  ///
  /// published -> published, archived
  /// archived  -> archived
  ///
  /// Archived versions remain retained for repository history but are not
  /// student-live.
  Future<void> updatePublishedStatus(String contentId, String status) async {
    final normalized = status.trim().toLowerCase();

    if (!_publishedLifecycleStatuses.contains(normalized)) {
      throw StateError('Unsupported published lifecycle status: $status');
    }

    final content = await loadPublishedContent(contentId);

    if (content == null) {
      throw StateError('Published content "$contentId" was not found.');
    }

    final currentStatus = content.status.trim().toLowerCase();

    const allowedTransitions = <String, Set<String>>{
      'published': {'published', 'archived'},
      'archived': {'archived'},
    };

    final allowedNextStatuses = allowedTransitions[currentStatus];

    if (allowedNextStatuses == null ||
        !allowedNextStatuses.contains(normalized)) {
      throw StateError(
        'Invalid lifecycle transition: '
        '$currentStatus -> $normalized.',
      );
    }

    final json = Map<String, dynamic>.from(content.toJson())
      ..['status'] = normalized;

    await _saveContent(
      storageKey: _publishedStorageKey,
      content: StudyContent.fromJson(json),
      storageLabel: 'published',
    );
  }

  /// Deletes one published competency by Content ID.
  Future<void> deletePublished(String contentId) async {
    await _deleteContent(
      storageKey: _publishedStorageKey,
      contentId: contentId,
      storageLabel: 'published',
    );
  }

  /// Deletes all published content.
  ///
  /// This is primarily useful for controlled development/testing.
  Future<void> clearPublished() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_publishedStorageKey);
  }

  // ---------------------------------------------------------------------------
  // SHARED STORAGE HELPERS
  // ---------------------------------------------------------------------------

  /// Loads a JSON array from the supplied storage key.
  ///
  /// Malformed individual records are ignored so one bad item does not
  /// make the entire repository unusable.
  Future<List<StudyContent>> _loadContentList(String storageKey) async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(storageKey);

    if (raw == null || raw.trim().isEmpty) {
      return <StudyContent>[];
    }

    try {
      final decoded = jsonDecode(raw);

      if (decoded is! List) {
        return <StudyContent>[];
      }

      final contentList = <StudyContent>[];

      for (final item in decoded) {
        if (item is! Map) {
          continue;
        }

        try {
          contentList.add(
            StudyContent.fromJson(Map<String, dynamic>.from(item)),
          );
        } catch (_) {
          // Ignore malformed individual records.
        }
      }

      return contentList;
    } catch (_) {
      return <StudyContent>[];
    }
  }

  /// Loads one content record by ID from a specific storage area.
  Future<StudyContent?> _loadContentById({
    required String storageKey,
    required String contentId,
  }) async {
    final contentList = await _loadContentList(storageKey);

    for (final content in contentList) {
      if (content.id == contentId) {
        return content;
      }
    }

    return null;
  }

  /// Saves or replaces content in a specific storage area.
  Future<void> _saveContent({
    required String storageKey,
    required StudyContent content,
    required String storageLabel,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final contentList = await _loadContentList(storageKey);

    final updated = <StudyContent>[];
    var replaced = false;

    for (final existing in contentList) {
      if (existing.id == content.id) {
        updated.add(content);
        replaced = true;
      } else {
        updated.add(existing);
      }
    }

    if (!replaced) {
      updated.insert(0, content);
    }

    final encoded = jsonEncode(updated.map((item) => item.toJson()).toList());

    final success = await preferences.setString(storageKey, encoded);

    if (!success) {
      throw StateError('Local $storageLabel storage could not be updated.');
    }
  }

  /// Deletes one content record from a specific storage area.
  Future<void> _deleteContent({
    required String storageKey,
    required String contentId,
    required String storageLabel,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final contentList = await _loadContentList(storageKey);

    final updated = contentList
        .where((content) => content.id != contentId)
        .map((content) => content.toJson())
        .toList();

    final success = await preferences.setString(
      storageKey,
      jsonEncode(updated),
    );

    if (!success) {
      throw StateError('Local $storageLabel storage could not be updated.');
    }
  }
}
