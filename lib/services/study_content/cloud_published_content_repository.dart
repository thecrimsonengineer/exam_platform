import '../../models/study_content.dart';
import 'cloud_content_repository.dart';

/// Student-facing boundary for published CSP11 study content.
///
/// This repository intentionally exposes published content only. Draft,
/// review, validated, and archived content never crosses this boundary.
class CloudPublishedContentRepository {
  CloudPublishedContentRepository({CloudContentRepository? repository})
    : _repository = repository ?? CloudContentRepository();

  final CloudContentRepository _repository;

  Future<List<StudyContent>> loadPublished() async {
    final contents = await _repository.loadPublished();

    return contents
        .where((content) => content.status.toLowerCase() == 'published')
        .toList();
  }

  Future<StudyContent?> loadPublishedContent(String contentId) async {
    final content = await _repository.loadPublishedContent(contentId);

    if (content == null || content.status.toLowerCase() != 'published') {
      return null;
    }

    return content;
  }
}
