import '../models/content_review_record.dart';
import '../models/content_review_state.dart';

class ContentReviewService {
  const ContentReviewService();

  ContentReviewRecord createProposal({
    required String contentId,
  }) {
    return ContentReviewRecord(
      contentId: contentId,
      state: ContentReviewState.proposed,
      updatedAt: DateTime.now(),
    );
  }

  ContentReviewRecord review({
    required String contentId,
    required String reviewerId,
    String? comment,
  }) {
    return ContentReviewRecord(
      contentId: contentId,
      state: ContentReviewState.reviewed,
      reviewerId: reviewerId,
      comment: comment,
      updatedAt: DateTime.now(),
    );
  }

  ContentReviewRecord approve({
    required String contentId,
    required String reviewerId,
    String? comment,
  }) {
    return ContentReviewRecord(
      contentId: contentId,
      state: ContentReviewState.approved,
      reviewerId: reviewerId,
      comment: comment,
      updatedAt: DateTime.now(),
    );
  }

  ContentReviewRecord reject({
    required String contentId,
    required String reviewerId,
    String? comment,
  }) {
    return ContentReviewRecord(
      contentId: contentId,
      state: ContentReviewState.rejected,
      reviewerId: reviewerId,
      comment: comment,
      updatedAt: DateTime.now(),
    );
  }
}
