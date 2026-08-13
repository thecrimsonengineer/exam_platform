enum MappingReviewDecision {
  pending,
  accepted,
  edited,
  rejected,
}

class MappingReviewItem {
  final String id;
  final String sourceId;
  final String sourceNodeId;
  final String? domainId;
  final String? competencyId;
  final String? subtopicTitle;
  final String? topicTitle;
  final double confidence;
  final String rationale;
  final MappingReviewDecision decision;

  const MappingReviewItem({
    required this.id,
    required this.sourceId,
    required this.sourceNodeId,
    this.domainId,
    this.competencyId,
    this.subtopicTitle,
    this.topicTitle,
    required this.confidence,
    required this.rationale,
    this.decision = MappingReviewDecision.pending,
  });

  MappingReviewItem copyWith({
    String? domainId,
    String? competencyId,
    String? subtopicTitle,
    String? topicTitle,
    MappingReviewDecision? decision,
  }) {
    return MappingReviewItem(
      id: id,
      sourceId: sourceId,
      sourceNodeId: sourceNodeId,
      domainId: domainId ?? this.domainId,
      competencyId: competencyId ?? this.competencyId,
      subtopicTitle: subtopicTitle ?? this.subtopicTitle,
      topicTitle: topicTitle ?? this.topicTitle,
      confidence: confidence,
      rationale: rationale,
      decision: decision ?? this.decision,
    );
  }
}
