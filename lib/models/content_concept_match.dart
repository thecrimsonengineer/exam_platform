enum ContentConceptMatchType {
  exactDuplicate,
  highSimilarity,
  relatedConcept,
}

class ContentConceptMatch {
  final String sourceId;
  final String? sourceSectionId;
  final String existingContentId;
  final String existingTitle;
  final ContentConceptMatchType type;
  final double confidence;
  final String reason;

  const ContentConceptMatch({
    required this.sourceId,
    this.sourceSectionId,
    required this.existingContentId,
    required this.existingTitle,
    required this.type,
    required this.confidence,
    required this.reason,
  });
}
