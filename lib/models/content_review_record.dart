import 'content_review_state.dart';

class ContentReviewRecord {
  final String contentId;
  final ContentReviewState state;
  final String? reviewerId;
  final String? comment;
  final DateTime updatedAt;

  const ContentReviewRecord({
    required this.contentId,
    required this.state,
    this.reviewerId,
    this.comment,
    required this.updatedAt,
  });
}
