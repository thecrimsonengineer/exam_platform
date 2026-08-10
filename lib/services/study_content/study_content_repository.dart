import '../../models/study_content.dart';

/// Contract for storing and retrieving CSP study content.
///
/// The UI depends on this abstraction rather than directly accessing
/// the underlying storage mechanism.
///
/// This allows the current local implementation to be replaced later
/// by an API/database implementation without redesigning the UI.
abstract class StudyContentRepository {
  /// Saves a StudyContent object as a draft.
  Future<void> saveDraft(StudyContent content);

  /// Loads a previously saved draft by content ID.
  Future<StudyContent?> loadDraft(String contentId);

  /// Returns all locally stored drafts.
  Future<List<StudyContent>> loadAllDrafts();

  /// Publishes a previously saved draft.
  Future<void> publish(String contentId);

  /// Loads published content by content ID.
  Future<StudyContent?> loadPublished(String contentId);

  /// Returns all locally stored published content.
  Future<List<StudyContent>> loadAllPublished();

  /// Deletes a draft by content ID.
  Future<void> deleteDraft(String contentId);
}
