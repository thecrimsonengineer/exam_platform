import '../../data/csp11_blueprint.dart';
import '../../models/content_mapping_candidate.dart';
import '../../models/source_structure_node.dart';
import '../../models/study_content.dart';

/// Converts Content Intelligence mapping results into a StudyContent draft.
///
/// This service does not publish content.
/// It creates draft content only.
class IntelligentContentDraftService {
  const IntelligentContentDraftService();

  StudyContent createDraft({
    required ContentMappingCandidate candidate,
    required SourceStructureNode sourceNode,
  }) {
    final competencyId = candidate.competencyId?.trim() ?? '';

    if (competencyId.isEmpty) {
      throw StateError(
        'A competency must be identified before creating StudyContent.',
      );
    }

    final domain = domainForContentId(candidate.domainId);

    if (domain == null) {
      throw StateError('Unknown CSP11 domain: ${candidate.domainId}');
    }

    final competency = _findCompetency(
      domain: domain,
      competencyId: competencyId,
    );

    if (competency == null) {
      throw StateError(
        'Competency "$competencyId" was not found '
        'under ${domain.id}.',
      );
    }

    final subtopicTitle = _resolveSubtopicTitle(candidate, sourceNode);

    final subtopicId = _buildSubtopicId(candidate, sourceNode);

    final topicTitle = sourceNode.title.trim().isNotEmpty
        ? sourceNode.title.trim()
        : 'Source Content';

    final topicId = _buildTopicId(candidate, sourceNode);

    final blockText = sourceNode.text.trim();

    final blocks = <ContentBlock>[];

    if (blockText.isNotEmpty) {
      blocks.add(
        ContentBlock(
          id: '${sourceNode.id}_block_01',
          type: 'text',
          data: {'content': blockText},
        ),
      );
    }

    final topic = MainContentTopic(
      id: topicId,
      title: topicTitle,
      blocks: blocks,
      quizzes: const [],
    );

    final subtopic = StudySubtopic(
      id: subtopicId,
      title: subtopicTitle,
      learningObjectives: const [],
      mainContent: [topic],
      questions: const [],
      keyPoints: const [],
      examples: const [],
      caseStudies: const [],
      formulas: const [],
      references: const [],
      examTips: const [],
      commonMistakes: const [],
      keyTakeaways: const [],
      quizzes: const [],
    );

    return StudyContent(
      id: _buildContentId(candidate, competencyId),
      domainId: domain.id,
      competencyId: competency.id,
      competencyNumber: competency.number,
      title: competency.statement,
      status: 'draft',
      version: 1,
      subtopics: [subtopic],
    );
  }

  Csp11Competency? _findCompetency({
    required Csp11Domain domain,
    required String competencyId,
  }) {
    for (final competency in domain.competencies) {
      if (competency.id == competencyId) {
        return competency;
      }
    }

    return null;
  }

  String _resolveSubtopicTitle(
    ContentMappingCandidate candidate,
    SourceStructureNode sourceNode,
  ) {
    final candidateSubtopic = candidate.subtopicId?.trim();

    if (candidateSubtopic != null && candidateSubtopic.isNotEmpty) {
      return candidateSubtopic;
    }

    if (sourceNode.title.trim().isNotEmpty) {
      return sourceNode.title.trim();
    }

    return 'Imported Source Content';
  }

  String _buildContentId(
    ContentMappingCandidate candidate,
    String competencyId,
  ) {
    return '${candidate.sourceId}_${competencyId}_v1';
  }

  String _buildSubtopicId(
    ContentMappingCandidate candidate,
    SourceStructureNode sourceNode,
  ) {
    final supplied = candidate.subtopicId?.trim();

    if (supplied != null && supplied.isNotEmpty) {
      return supplied;
    }

    return '${candidate.sourceNodeId}_subtopic';
  }

  String _buildTopicId(
    ContentMappingCandidate candidate,
    SourceStructureNode sourceNode,
  ) {
    final supplied = candidate.topicId?.trim();

    if (supplied != null && supplied.isNotEmpty) {
      return supplied;
    }

    return '${candidate.sourceNodeId}_topic';
  }
}
