class ContentGenerationRequest {
  final String sourceId;
  final String competencyId;
  final String subtopicTitle;
  final String topicTitle;
  final String sourceText;
  final String? sourceLocation;

  const ContentGenerationRequest({
    required this.sourceId,
    required this.competencyId,
    required this.subtopicTitle,
    required this.topicTitle,
    required this.sourceText,
    this.sourceLocation,
  });
}
