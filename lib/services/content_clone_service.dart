import '../models/content_clone_request.dart';

class ContentCloneService {
  const ContentCloneService();

  Map<String, dynamic> cloneDraft({
    required ContentCloneRequest request,
    required Map<String, dynamic> source,
  }) {
    final copy = Map<String, dynamic>.from(source);

    copy['id'] = request.newContentId;
    copy['title'] = request.newTitle;
    copy['sourceContentId'] = request.sourceContentId;
    copy['status'] = 'Draft';
    copy['clonedAt'] = DateTime.now().toIso8601String();

    return copy;
  }
}
