class SubtopicProposal {
  final String competencyId;
  final String title;
  final String rationale;
  final double confidence;
  final List<String> evidenceNodeIds;

  const SubtopicProposal({
    required this.competencyId,
    required this.title,
    required this.rationale,
    required this.confidence,
    this.evidenceNodeIds = const [],
  });
}
