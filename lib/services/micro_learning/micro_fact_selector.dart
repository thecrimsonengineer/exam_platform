import '../../models/micro_learning/micro_fact.dart';

class MicroFactSelectionContext {
  const MicroFactSelectionContext({
    this.rotationOrdinal = 0,
    this.recentMicroFactIds = const <String>[],
    this.activeAssessmentConceptIds = const <String>{},
  });

  final int rotationOrdinal;
  final List<String> recentMicroFactIds;
  final Set<String> activeAssessmentConceptIds;
}

class MicroFactSelectionResult {
  const MicroFactSelectionResult({
    required this.fact,
    required this.inputFactCount,
    required this.runtimeEligibleCount,
    required this.assessmentExcludedCount,
    required this.repetitionExcludedCount,
    required this.diagnostics,
  });

  final MicroFact? fact;
  final int inputFactCount;
  final int runtimeEligibleCount;
  final int assessmentExcludedCount;
  final int repetitionExcludedCount;
  final List<String> diagnostics;

  bool get hasFact => fact != null;
}

class MicroFactSelector {
  const MicroFactSelector();

  static const int recentWindowSize = 12;

  MicroFactSelectionResult select(
    List<MicroFact> facts, {
    MicroFactSelectionContext context = const MicroFactSelectionContext(),
  }) {
    final diagnostics = <String>[];

    final runtimeEligible = facts
        .where(
          (fact) =>
              fact.status == 'published' && fact.runtime.startupEligible,
        )
        .toList(growable: false);

    if (runtimeEligible.isEmpty) {
      return MicroFactSelectionResult(
        fact: null,
        inputFactCount: facts.length,
        runtimeEligibleCount: 0,
        assessmentExcludedCount: 0,
        repetitionExcludedCount: 0,
        diagnostics: const <String>['ML11_NO_RUNTIME_ELIGIBLE_FACT'],
      );
    }

    final activeConcepts = context.activeAssessmentConceptIds
        .where((value) => value.trim().isNotEmpty)
        .toSet();

    final assessmentSafe = <MicroFact>[];
    var assessmentExcludedCount = 0;
    for (final fact in runtimeEligible) {
      if (_blockedByAssessment(fact, activeConcepts)) {
        assessmentExcludedCount++;
      } else {
        assessmentSafe.add(fact);
      }
    }

    if (assessmentSafe.isEmpty) {
      return MicroFactSelectionResult(
        fact: null,
        inputFactCount: facts.length,
        runtimeEligibleCount: runtimeEligible.length,
        assessmentExcludedCount: assessmentExcludedCount,
        repetitionExcludedCount: 0,
        diagnostics: const <String>['ML11_NO_ASSESSMENT_SAFE_FACT'],
      );
    }

    final recentIds = _recentIds(context.recentMicroFactIds);
    final recentSet = recentIds.toSet();
    final nonRecent = assessmentSafe
        .where((fact) => !recentSet.contains(fact.microFactId))
        .toList(growable: false);

    final List<MicroFact> pool;
    final repetitionExcludedCount =
        assessmentSafe.length - nonRecent.length;
    if (nonRecent.isNotEmpty) {
      pool = nonRecent;
    } else {
      pool = assessmentSafe;
      if (recentSet.isNotEmpty) {
        diagnostics.add('ML11_RECENCY_FALLBACK');
      }
    }

    final baseById = <String, MicroFact>{
      for (final fact in runtimeEligible) fact.microFactId: fact,
    };
    final recentFacts = recentIds
        .map((id) => baseById[id])
        .whereType<MicroFact>()
        .toList(growable: false);

    final categoryRecency = <String, int>{};
    final sourceRecency = <String, int>{};
    final conceptRecency = <String, int>{};
    for (final fact in recentFacts) {
      categoryRecency.update(
        fact.category,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
      sourceRecency.update(
        fact.provenance.sourceRegistryId,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
      for (final concept in fact.curriculum.conceptIds) {
        conceptRecency.update(
          concept,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      }
    }

    final sequence = _balancedSequence(pool);
    final startIndex = _normalizedOrdinal(
      context.rotationOrdinal,
      sequence.length,
    );

    MicroFact? best;
    _SelectionScore? bestScore;
    for (var offset = 0; offset < sequence.length; offset++) {
      final fact = sequence[(startIndex + offset) % sequence.length];
      final score = _SelectionScore(
        categoryRecency: categoryRecency[fact.category] ?? 0,
        sourceRecency:
            sourceRecency[fact.provenance.sourceRegistryId] ?? 0,
        conceptRecency: fact.curriculum.conceptIds.fold<int>(
          0,
          (sum, concept) => sum + (conceptRecency[concept] ?? 0),
        ),
        rotationOffset: offset,
        stableId: fact.microFactId,
      );

      if (bestScore == null || score.compareTo(bestScore) < 0) {
        best = fact;
        bestScore = score;
      }
    }

    return MicroFactSelectionResult(
      fact: best,
      inputFactCount: facts.length,
      runtimeEligibleCount: runtimeEligible.length,
      assessmentExcludedCount: assessmentExcludedCount,
      repetitionExcludedCount: repetitionExcludedCount,
      diagnostics: List<String>.unmodifiable(diagnostics),
    );
  }

  bool _blockedByAssessment(
    MicroFact fact,
    Set<String> activeAssessmentConceptIds,
  ) {
    if (activeAssessmentConceptIds.isEmpty ||
        fact.assessment.sensitivity == 'none' ||
        fact.assessment.linkedQuestionConcepts.isEmpty) {
      return false;
    }

    for (final concept in fact.assessment.linkedQuestionConcepts) {
      if (activeAssessmentConceptIds.contains(concept)) {
        return true;
      }
    }
    return false;
  }

  List<String> _recentIds(List<String> values) {
    final output = <String>[];
    final seen = <String>{};
    for (final raw in values) {
      final value = raw.trim();
      if (value.isEmpty || !seen.add(value)) {
        continue;
      }
      output.add(value);
      if (output.length == recentWindowSize) {
        break;
      }
    }
    return output;
  }

  List<MicroFact> _balancedSequence(List<MicroFact> facts) {
    final grouped = <String, List<MicroFact>>{};
    for (final fact in facts) {
      grouped.putIfAbsent(fact.category, () => <MicroFact>[]).add(fact);
    }

    for (final queue in grouped.values) {
      queue.sort((left, right) {
        final source = left.provenance.sourceRegistryId.compareTo(
          right.provenance.sourceRegistryId,
        );
        if (source != 0) {
          return source;
        }
        return left.microFactId.compareTo(right.microFactId);
      });
    }

    final originalCounts = <String, int>{
      for (final entry in grouped.entries) entry.key: entry.value.length,
    };
    final output = <MicroFact>[];
    String? previousCategory;
    String? previousSource;

    while (grouped.values.any((queue) => queue.isNotEmpty)) {
      final availableCategories = grouped.entries
          .where((entry) => entry.value.isNotEmpty)
          .map((entry) => entry.key)
          .toList(growable: false);

      final preferredCategories = availableCategories
          .where((category) => category != previousCategory)
          .toList(growable: false);

      final candidates = preferredCategories.isNotEmpty
          ? preferredCategories
          : availableCategories;

      candidates.sort((left, right) {
        final leftRemaining = grouped[left]!.length;
        final rightRemaining = grouped[right]!.length;
        final leftOriginal = originalCounts[left]!;
        final rightOriginal = originalCounts[right]!;

        final proportional = (rightRemaining * leftOriginal).compareTo(
          leftRemaining * rightOriginal,
        );
        if (proportional != 0) {
          return proportional;
        }

        final remaining = rightRemaining.compareTo(leftRemaining);
        if (remaining != 0) {
          return remaining;
        }

        return left.compareTo(right);
      });

      final category = candidates.first;
      final queue = grouped[category]!;

      var selectedIndex = 0;
      if (previousSource != null) {
        final alternateIndex = queue.indexWhere(
          (fact) => fact.provenance.sourceRegistryId != previousSource,
        );
        if (alternateIndex >= 0) {
          selectedIndex = alternateIndex;
        }
      }

      final fact = queue.removeAt(selectedIndex);
      output.add(fact);
      previousCategory = fact.category;
      previousSource = fact.provenance.sourceRegistryId;
    }

    return List<MicroFact>.unmodifiable(output);
  }

  int _normalizedOrdinal(int ordinal, int length) {
    if (length <= 0) {
      return 0;
    }
    final remainder = ordinal % length;
    return remainder < 0 ? remainder + length : remainder;
  }
}

class _SelectionScore implements Comparable<_SelectionScore> {
  const _SelectionScore({
    required this.categoryRecency,
    required this.sourceRecency,
    required this.conceptRecency,
    required this.rotationOffset,
    required this.stableId,
  });

  final int categoryRecency;
  final int sourceRecency;
  final int conceptRecency;
  final int rotationOffset;
  final String stableId;

  @override
  int compareTo(_SelectionScore other) {
    var comparison = categoryRecency.compareTo(other.categoryRecency);
    if (comparison != 0) {
      return comparison;
    }

    comparison = sourceRecency.compareTo(other.sourceRecency);
    if (comparison != 0) {
      return comparison;
    }

    comparison = conceptRecency.compareTo(other.conceptRecency);
    if (comparison != 0) {
      return comparison;
    }

    comparison = rotationOffset.compareTo(other.rotationOffset);
    if (comparison != 0) {
      return comparison;
    }

    return stableId.compareTo(other.stableId);
  }
}

