class AiClassificationCandidate {
  final String targetId;
  final double confidence;
  final String rationale;
  final List<String> evidenceTerms;

  const AiClassificationCandidate({
    required this.targetId,
    required this.confidence,
    required this.rationale,
    this.evidenceTerms = const [],
  });
}

class AiClassificationResult {
  final String sourceNodeId;
  final List<AiClassificationCandidate> candidates;

  const AiClassificationResult({
    required this.sourceNodeId,
    required this.candidates,
  });
}
