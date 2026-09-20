import '../models/flashcard_content_package.dart';

class FlashcardMappingCoverageReport {
  const FlashcardMappingCoverageReport({
    required this.mappingCount,
    required this.mappedQuestionIds,
    required this.unmappedEligibleQuestionIds,
    required this.conceptsWithMappings,
    required this.conceptsWithoutMappings,
    required this.mappingsPerConcept,
  });

  final int mappingCount;
  final List<int> mappedQuestionIds;
  final List<int> unmappedEligibleQuestionIds;
  final List<String> conceptsWithMappings;
  final List<String> conceptsWithoutMappings;
  final Map<String, int> mappingsPerConcept;

  double get eligibleQuestionCoverageRatio {
    final denominator =
        mappedQuestionIds.length + unmappedEligibleQuestionIds.length;
    if (denominator == 0) {
      return 1;
    }
    return mappedQuestionIds.length / denominator;
  }

  factory FlashcardMappingCoverageReport.build({
    required FlashcardContentPackage package,
    Iterable<int> eligibleQuestionIds = const <int>[],
  }) {
    final counts = <String, int>{
      for (final concept in package.concepts) concept.id: 0,
    };
    final mappedQuestions = <int>{};

    for (final mapping in package.questionMappings) {
      mappedQuestions.add(mapping.questionId);
      if (counts.containsKey(mapping.conceptId)) {
        counts[mapping.conceptId] = counts[mapping.conceptId]! + 1;
      }
    }

    final eligible = eligibleQuestionIds.where((id) => id > 0).toSet();
    final unmappedEligible = eligible.difference(mappedQuestions).toList()
      ..sort();

    final withMappings = counts.entries
        .where((entry) => entry.value > 0)
        .map((entry) => entry.key)
        .toList()
      ..sort();
    final withoutMappings = counts.entries
        .where((entry) => entry.value == 0)
        .map((entry) => entry.key)
        .toList()
      ..sort();
    final sortedQuestions = mappedQuestions.toList()..sort();
    final sortedCounts = Map<String, int>.fromEntries(
      counts.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );

    return FlashcardMappingCoverageReport(
      mappingCount: package.questionMappings.length,
      mappedQuestionIds: List.unmodifiable(sortedQuestions),
      unmappedEligibleQuestionIds: List.unmodifiable(unmappedEligible),
      conceptsWithMappings: List.unmodifiable(withMappings),
      conceptsWithoutMappings: List.unmodifiable(withoutMappings),
      mappingsPerConcept: Map.unmodifiable(sortedCounts),
    );
  }
}
