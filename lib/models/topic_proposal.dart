class TopicProposal {
  final String subtopicId;
  final String title;
  final String sourceNodeId;
  final double confidence;
  final String rationale;

  const TopicProposal({
    required this.subtopicId,
    required this.title,
    required this.sourceNodeId,
    required this.confidence,
    required this.rationale,
  });
}
