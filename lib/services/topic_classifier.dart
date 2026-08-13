import '../models/source_structure_node.dart';
import '../models/topic_proposal.dart';

abstract class TopicClassifier {
  Future<List<TopicProposal>> classify({
    required String subtopicId,
    required List<SourceStructureNode> nodes,
  });
}

class LocalTopicClassifier implements TopicClassifier {
  const LocalTopicClassifier();

  @override
  Future<List<TopicProposal>> classify({
    required String subtopicId,
    required List<SourceStructureNode> nodes,
  }) async {
    return nodes
        .where((node) =>
            node.title.trim().isNotEmpty &&
            node.type != SourceStructureNodeType.paragraph)
        .map(
          (node) => TopicProposal(
            subtopicId: subtopicId,
            title: node.title.trim(),
            sourceNodeId: node.id,
            confidence: 0.60,
            rationale:
                'Topic candidate derived from source structure. '
                'Semantic consolidation and approval are required.',
          ),
        )
        .toList();
  }
}
