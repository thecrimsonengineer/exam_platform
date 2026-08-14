import '../../models/content_mapping_candidate.dart';
import '../../models/source_structure_node.dart';
import '../../models/study_content.dart';
import 'content_repository_service.dart';
import 'intelligent_content_draft_service.dart';

/// Bridges Content Intelligence output into the Admin Content Repository.
///
/// Intelligence creates a StudyContent draft.
/// The normal Content Repository remains responsible for persistence
/// and lifecycle management.
class IntelligentContentRepositoryService {
  final ContentRepositoryService _repository;
  final IntelligentContentDraftService _draftService;

  IntelligentContentRepositoryService({
    ContentRepositoryService? repository,
    IntelligentContentDraftService? draftService,
  }) : _repository = repository ?? ContentRepositoryService(),
       _draftService = draftService ?? const IntelligentContentDraftService();

  /// Creates and saves a mapped source node as a StudyContent draft.
  ///
  /// The resulting content always enters the repository as DRAFT.
  Future<StudyContent> createDraftFromMapping({
    required ContentMappingCandidate candidate,
    required SourceStructureNode sourceNode,
  }) async {
    final content = _draftService.createDraft(
      candidate: candidate,
      sourceNode: sourceNode,
    );

    await _repository.saveDraft(content);

    return content;
  }
}
