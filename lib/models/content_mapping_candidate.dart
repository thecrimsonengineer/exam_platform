class ContentMappingCandidate {
  final String sourceId;
  final String sourceNodeId;
  final String domainId;
  final String? competencyId;
  final String? subtopicId;
  final String? topicId;
  final double confidence;
  final String rationale;
  final List<String> evidenceTerms;

  const ContentMappingCandidate({
    required this.sourceId,
    required this.sourceNodeId,
    required this.domainId,
    this.competencyId,
    this.subtopicId,
    this.topicId,
    required this.confidence,
    required this.rationale,
    this.evidenceTerms = const [],
  });
}
