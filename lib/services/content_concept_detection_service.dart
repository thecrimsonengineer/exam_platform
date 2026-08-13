import '../models/content_concept_match.dart';

class ContentConceptDetectionService {
  const ContentConceptDetectionService();

  ContentConceptMatch? compare({
    required String sourceId,
    String? sourceSectionId,
    required String candidateText,
    required String existingContentId,
    required String existingTitle,
    required String existingText,
  }) {
    final candidate = _normalize(candidateText);
    final existing = _normalize(existingText);

    if (candidate.isEmpty || existing.isEmpty) {
      return null;
    }

    if (candidate == existing) {
      return ContentConceptMatch(
        sourceId: sourceId,
        sourceSectionId: sourceSectionId,
        existingContentId: existingContentId,
        existingTitle: existingTitle,
        type: ContentConceptMatchType.exactDuplicate,
        confidence: 1.0,
        reason: 'Normalized text is identical.',
      );
    }

    final candidateWords = candidate.split(' ').toSet();
    final existingWords = existing.split(' ').toSet();
    final union = {...candidateWords, ...existingWords};
    final intersection = candidateWords.intersection(existingWords);

    if (union.isEmpty) {
      return null;
    }

    final similarity = intersection.length / union.length;

    if (similarity >= 0.75) {
      return ContentConceptMatch(
        sourceId: sourceId,
        sourceSectionId: sourceSectionId,
        existingContentId: existingContentId,
        existingTitle: existingTitle,
        type: ContentConceptMatchType.highSimilarity,
        confidence: similarity,
        reason: 'High normalized word overlap detected.',
      );
    }

    if (similarity >= 0.45) {
      return ContentConceptMatch(
        sourceId: sourceId,
        sourceSectionId: sourceSectionId,
        existingContentId: existingContentId,
        existingTitle: existingTitle,
        type: ContentConceptMatchType.relatedConcept,
        confidence: similarity,
        reason: 'Potentially related concepts detected.',
      );
    }

    return null;
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
