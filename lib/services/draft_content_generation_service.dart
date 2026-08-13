import '../models/content_generation_request.dart';
import '../models/generated_content_draft.dart';

/// Provider-neutral draft generation boundary.
///
/// Current implementation creates a traceable draft shell. An AI provider
/// should be added later without changing the surrounding repository model.
class DraftContentGenerationService {
  const DraftContentGenerationService();

  GeneratedContentDraft createDraftShell(
    ContentGenerationRequest request,
  ) {
    return GeneratedContentDraft(
      sourceId: request.sourceId,
      competencyId: request.competencyId,
      subtopicTitle: request.subtopicTitle,
      topicTitle: request.topicTitle,
      draftText: request.sourceText.trim(),
      sourceLocation: request.sourceLocation,
      createdAt: DateTime.now(),
    );
  }
}
