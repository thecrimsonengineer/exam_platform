import '../models/competency_dependency.dart';
import '../models/competency_readiness_profile.dart';
import '../models/readiness_gap.dart';

class RootGapReasoningService {
  const RootGapReasoningService({this.minimumDependentGapCount = 2});

  final int minimumDependentGapCount;

  List<RootGapCandidate> identify({
    required Iterable<CompetencyDependency> dependencies,
    required Map<String, CompetencyReadinessProfile> profiles,
  }) {
    if (minimumDependentGapCount < 1) {
      throw StateError('Minimum dependent gap count must be positive.');
    }

    final grouped = <String, List<CompetencyDependency>>{};
    for (final dependency in dependencies) {
      dependency.validate();
      grouped
          .putIfAbsent(
            dependency.prerequisiteCompetencyId,
            () => <CompetencyDependency>[],
          )
          .add(dependency);
    }

    final result = <RootGapCandidate>[];

    for (final entry in grouped.entries) {
      final prerequisite = profiles[entry.key];
      if (!_hasObservedSeriousGap(prerequisite)) {
        continue;
      }

      final supporting = entry.value
          .where((dependency) {
            return _hasObservedSeriousGap(
              profiles[dependency.dependentCompetencyId],
            );
          })
          .toList(growable: false);

      if (supporting.length < minimumDependentGapCount) {
        continue;
      }

      final strength =
          supporting.fold<double>(
            0,
            (sum, dependency) => sum + dependency.strength,
          ) /
          supporting.length;

      final dependents =
          supporting
              .map((dependency) => dependency.dependentCompetencyId)
              .toSet()
              .toList(growable: false)
            ..sort();

      result.add(
        RootGapCandidate(
          prerequisiteCompetencyId: entry.key,
          dependentCompetencyIds: dependents,
          averageDependencyStrength: strength,
          reasonCodes: const [
            'ROOT_GAP_EXPLICIT_DEPENDENCY',
            'ROOT_GAP_OBSERVED',
            'DEPENDENT_GAPS_OBSERVED',
          ],
        ),
      );
    }

    result.sort(
      (left, right) => right.averageDependencyStrength.compareTo(
        left.averageDependencyStrength,
      ),
    );
    return List<RootGapCandidate>.unmodifiable(result);
  }

  bool _hasObservedSeriousGap(CompetencyReadinessProfile? profile) {
    if (profile == null) return false;
    return profile.gaps.any(
      (gap) =>
          !gap.evidenceLimited &&
          gap.type != ReadinessGapType.evidenceGap &&
          (gap.severity == ReadinessGapSeverity.high ||
              gap.severity == ReadinessGapSeverity.critical),
    );
  }
}
