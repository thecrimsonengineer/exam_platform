import '../models/subtopic_proposal.dart';
import '../models/source_structure_node.dart';

abstract class SubtopicClassifier {
  Future<List<SubtopicProposal>> classify({
    required String competencyId,
    required List<SourceStructureNode> nodes,
  });
}

class LocalSubtopicClassifier implements SubtopicClassifier {
  const LocalSubtopicClassifier();

  @override
  Future<List<SubtopicProposal>> classify({
    required String competencyId,
    required List<SourceStructureNode> nodes,
  }) async {
    final proposals = <SubtopicProposal>[];

    for (final node in nodes) {
      final title = node.title.trim();
      if (title.isEmpty || node.type.name == 'paragraph') {
        continue;
      }

      proposals.add(
        SubtopicProposal(
          competencyId: competencyId,
          title: title,
          rationale:
              'Proposed from a source document structural heading. '
              'Semantic consolidation should be performed by the AI layer '
              'and approved by a human.',
          confidence: 0.60,
          evidenceNodeIds: [node.id],
        ),
      );
    }

    return proposals;
  }
}
