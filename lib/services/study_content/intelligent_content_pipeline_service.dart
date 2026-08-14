import '../../models/content_mapping_candidate.dart';
import '../../models/source_extraction_result.dart';
import '../../models/study_content.dart';
import '../../models/source_structure_node.dart';
import '../csp11_blueprint_mapping_engine.dart';
import '../source_document_structure_analyzer.dart';
import 'intelligent_content_repository_service.dart';

/// Orchestrates source analysis, CSP11 mapping, and draft creation.
///
/// This service does not publish content.
/// Every successfully created StudyContent package enters the repository
/// as DRAFT.
class IntelligentContentPipelineService {
  final SourceDocumentStructureAnalyzer _structureAnalyzer;
  final Csp11BlueprintMappingEngine _mappingEngine;
  final IntelligentContentRepositoryService _repositoryService;

  IntelligentContentPipelineService({
    SourceDocumentStructureAnalyzer? structureAnalyzer,
    Csp11BlueprintMappingEngine? mappingEngine,
    IntelligentContentRepositoryService? repositoryService,
  }) : _structureAnalyzer =
           structureAnalyzer ?? const SourceDocumentStructureAnalyzer(),
       _mappingEngine = mappingEngine ?? const Csp11BlueprintMappingEngine(),
       _repositoryService =
           repositoryService ?? IntelligentContentRepositoryService();

  /// Analyzes a source and generates CSP11 mapping candidates.
  List<ContentMappingCandidate> generateMappings({
    required SourceExtractionResult extraction,
  }) {
    final nodes = _structureAnalyzer.analyze(extraction);

    return _mappingEngine.generateCandidates(
      sourceId: extraction.sourceId,
      nodes: nodes,
    );
  }

  /// Creates a StudyContent draft from a selected mapping candidate.
  Future<StudyContent> createDraftFromCandidate({
    required ContentMappingCandidate candidate,
    required SourceStructureNode sourceNode,
  }) async {
    return _repositoryService.createDraftFromMapping(
      candidate: candidate,
      sourceNode: sourceNode,
    );
  }

  /// Analyzes a source and returns both the extracted structure and
  /// generated CSP11 mapping candidates.
  IntelligentContentPipelineResult analyzeSource({
    required SourceExtractionResult extraction,
  }) {
    final nodes = _structureAnalyzer.analyze(extraction);

    final candidates = _mappingEngine.generateCandidates(
      sourceId: extraction.sourceId,
      nodes: nodes,
    );

    return IntelligentContentPipelineResult(
      sourceId: extraction.sourceId,
      nodes: nodes,
      candidates: candidates,
    );
  }
}

/// Result of the source-to-CSP11 analysis stage.
class IntelligentContentPipelineResult {
  final String sourceId;
  final List<SourceStructureNode> nodes;
  final List<ContentMappingCandidate> candidates;

  const IntelligentContentPipelineResult({
    required this.sourceId,
    required this.nodes,
    required this.candidates,
  });

  bool get hasNodes => nodes.isNotEmpty;

  bool get hasCandidates => candidates.isNotEmpty;
}
