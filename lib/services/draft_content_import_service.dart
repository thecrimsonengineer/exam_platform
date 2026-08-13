import '../models/content_import_result.dart';
import '../models/content_review_state.dart';

class DraftContentImportService {
  const DraftContentImportService();

  ContentImportResult prepareImport({
    required String contentId,
    required String title,
    required String content,
    required ContentReviewState reviewState,
  }) {
    if (contentId.trim().isEmpty) {
      return const ContentImportResult(
        imported: false,
        contentId: '',
        message: 'Content ID is required.',
      );
    }

    if (title.trim().isEmpty || content.trim().isEmpty) {
      return ContentImportResult(
        imported: false,
        contentId: contentId,
        message: 'Title and content are required.',
      );
    }

    if (reviewState != ContentReviewState.approved) {
      return ContentImportResult(
        imported: false,
        contentId: contentId,
        message: 'Content must be approved before import.',
      );
    }

    return ContentImportResult(
      imported: true,
      contentId: contentId,
      message: 'Content is ready for repository import.',
    );
  }
}
