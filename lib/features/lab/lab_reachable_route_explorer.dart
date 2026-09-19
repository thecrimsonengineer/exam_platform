import 'dart:convert';

import 'lab_contracts.dart';
import 'lab_exhaustive_route_validator.dart';

enum LabReachableRouteExplorationMode {
  exhaustive,
  representative,
  blocked,
}

class LabReachableRouteExplorationReport {
  const LabReachableRouteExplorationReport({
    required this.mode,
    required this.exhaustiveReport,
    required this.selectedRoutes,
    required this.routeBudget,
    required this.hardRouteLimit,
    required this.selectedOptionCoverageKeys,
    required this.selectedConsequenceCoverageIds,
    required this.selectedGateCoverageIds,
    required this.selectedGateTypeCoverage,
    required this.selectedEndingIds,
    required this.completeMandatoryCoverage,
    required this.deterministic,
    required this.issues,
    required this.fingerprint,
  });

  final LabReachableRouteExplorationMode mode;
  final LabExhaustiveRouteReport exhaustiveReport;
  final List<LabExhaustiveRouteTrace> selectedRoutes;
  final int routeBudget;
  final int hardRouteLimit;
  final Set<String> selectedOptionCoverageKeys;
  final Set<String> selectedConsequenceCoverageIds;
  final Set<String> selectedGateCoverageIds;
  final Set<LabGateType> selectedGateTypeCoverage;
  final Set<String> selectedEndingIds;
  final bool completeMandatoryCoverage;
  final bool deterministic;
  final List<String> issues;
  final String fingerprint;

  int get discoveredRouteCount => exhaustiveReport.routes.length;
  int get selectedRouteCount => selectedRoutes.length;

  bool get isExhaustive =>
      mode == LabReachableRouteExplorationMode.exhaustive;
  bool get isRepresentative =>
      mode == LabReachableRouteExplorationMode.representative;
  bool get isBlocked => mode == LabReachableRouteExplorationMode.blocked;

  bool get isValid =>
      !isBlocked &&
      exhaustiveReport.isValid &&
      selectedRoutes.isNotEmpty &&
      completeMandatoryCoverage &&
      deterministic &&
      issues.isEmpty;

  Map<String, Object?> toEvidenceJson() {
    List<String> sortedStrings(Iterable<String> values) =>
        values.toList()..sort();

    final gateTypes =
        selectedGateTypeCoverage.map((type) => type.name).toList()..sort();
    final routeFingerprints =
        selectedRoutes.map((route) => route.fingerprint).toList()..sort();

    return <String, Object?>{
      'schemaVersion': 'csp11.lab.l4m.exploration.v1',
      'mode': mode.name,
      'routeBudget': routeBudget,
      'hardRouteLimit': hardRouteLimit,
      'discoveredRouteCount': discoveredRouteCount,
      'selectedRouteCount': selectedRouteCount,
      'selectedOptionCoverageKeys':
          sortedStrings(selectedOptionCoverageKeys),
      'selectedConsequenceCoverageIds':
          sortedStrings(selectedConsequenceCoverageIds),
      'selectedGateCoverageIds': sortedStrings(selectedGateCoverageIds),
      'selectedGateTypeCoverage': gateTypes,
      'selectedEndingIds': sortedStrings(selectedEndingIds),
      'selectedRouteFingerprints': routeFingerprints,
      'completeMandatoryCoverage': completeMandatoryCoverage,
      'deterministic': deterministic,
      'issues': issues,
      'exhaustiveProofFingerprint': exhaustiveReport.fingerprint,
      'fingerprint': fingerprint,
      'isValid': isValid,
    };
  }
}

class LabReachableRouteExplorer {
  const LabReachableRouteExplorer({
    this.exhaustiveValidator = const LabExhaustiveRouteValidator(),
  });

  final LabExhaustiveRouteValidator exhaustiveValidator;

  LabReachableRouteExplorationReport explore(
    LabPackage package, {
    int routeBudget = 1000,
    int hardRouteLimit = 10000,
  }) {
    if (routeBudget <= 0) {
      throw const LabContractException(
        'L4M route exploration budget must be greater than zero.',
      );
    }
    if (hardRouteLimit <= 0 || hardRouteLimit < routeBudget) {
      throw const LabContractException(
        'L4M hard route limit must be greater than or equal to the route budget.',
      );
    }

    final exhaustive = exhaustiveValidator.run(
      package,
      maxRoutes: hardRouteLimit,
    );

    if (!exhaustive.isValid) {
      final issues = <String>[
        ...exhaustive.issues,
        if (exhaustive.limitExceeded)
          'L4M exact route discovery exceeded the hard route guard.',
        if (!exhaustive.limitExceeded && exhaustive.issues.isEmpty)
          'L4M exact route discovery did not produce a publishable proof.',
      ]..sort();

      return LabReachableRouteExplorationReport(
        mode: LabReachableRouteExplorationMode.blocked,
        exhaustiveReport: exhaustive,
        selectedRoutes: const <LabExhaustiveRouteTrace>[],
        routeBudget: routeBudget,
        hardRouteLimit: hardRouteLimit,
        selectedOptionCoverageKeys: const <String>{},
        selectedConsequenceCoverageIds: const <String>{},
        selectedGateCoverageIds: const <String>{},
        selectedGateTypeCoverage: const <LabGateType>{},
        selectedEndingIds: const <String>{},
        completeMandatoryCoverage: false,
        deterministic: exhaustive.deterministic,
        issues: List<String>.unmodifiable(issues),
        fingerprint: '',
      );
    }

    final ordered = <LabExhaustiveRouteTrace>[...exhaustive.routes]
      ..sort((left, right) => left.fingerprint.compareTo(right.fingerprint));

    final mode = ordered.length <= routeBudget
        ? LabReachableRouteExplorationMode.exhaustive
        : LabReachableRouteExplorationMode.representative;

    final selected = mode == LabReachableRouteExplorationMode.exhaustive
        ? ordered
        : _selectRepresentative(
            ordered,
            routeBudget: routeBudget,
            exhaustive: exhaustive,
          );

    final coverage = _coverageOf(selected);
    final completeCoverage =
        coverage.optionKeys.containsAll(exhaustive.optionCoverageKeys) &&
        coverage.consequenceIds.containsAll(
          exhaustive.consequenceCoverageIds,
        ) &&
        coverage.gateIds.containsAll(exhaustive.gateCoverageIds) &&
        coverage.gateTypes.containsAll(exhaustive.gateTypeCoverage) &&
        coverage.endingIds.containsAll(exhaustive.endingIds);

    final firstFingerprint = _selectionFingerprint(selected);
    final repeated = mode == LabReachableRouteExplorationMode.exhaustive
        ? ordered
        : _selectRepresentative(
            ordered,
            routeBudget: routeBudget,
            exhaustive: exhaustive,
          );
    final deterministic =
        exhaustive.deterministic &&
        firstFingerprint == _selectionFingerprint(repeated);

    final issues = <String>[];
    if (!completeCoverage) {
      issues.add(
        'L4M representative route budget cannot preserve all mandatory reachable coverage.',
      );
    }
    if (!deterministic) {
      issues.add(
        'L4M repeated representative selection produced different results.',
      );
    }

    return LabReachableRouteExplorationReport(
      mode: mode,
      exhaustiveReport: exhaustive,
      selectedRoutes: List<LabExhaustiveRouteTrace>.unmodifiable(selected),
      routeBudget: routeBudget,
      hardRouteLimit: hardRouteLimit,
      selectedOptionCoverageKeys:
          Set<String>.unmodifiable(coverage.optionKeys),
      selectedConsequenceCoverageIds:
          Set<String>.unmodifiable(coverage.consequenceIds),
      selectedGateCoverageIds: Set<String>.unmodifiable(coverage.gateIds),
      selectedGateTypeCoverage:
          Set<LabGateType>.unmodifiable(coverage.gateTypes),
      selectedEndingIds: Set<String>.unmodifiable(coverage.endingIds),
      completeMandatoryCoverage: completeCoverage,
      deterministic: deterministic,
      issues: List<String>.unmodifiable(issues),
      fingerprint: firstFingerprint,
    );
  }

  List<LabExhaustiveRouteTrace> _selectRepresentative(
    List<LabExhaustiveRouteTrace> ordered, {
    required int routeBudget,
    required LabExhaustiveRouteReport exhaustive,
  }) {
    final selected = <LabExhaustiveRouteTrace>[];
    final selectedFingerprints = <String>{};

    final uncoveredOptions = Set<String>.from(exhaustive.optionCoverageKeys);
    final uncoveredConsequences =
        Set<String>.from(exhaustive.consequenceCoverageIds);
    final uncoveredGates = Set<String>.from(exhaustive.gateCoverageIds);
    final uncoveredGateTypes =
        Set<LabGateType>.from(exhaustive.gateTypeCoverage);
    final uncoveredEndings = Set<String>.from(exhaustive.endingIds);

    bool hasUncovered() =>
        uncoveredOptions.isNotEmpty ||
        uncoveredConsequences.isNotEmpty ||
        uncoveredGates.isNotEmpty ||
        uncoveredGateTypes.isNotEmpty ||
        uncoveredEndings.isNotEmpty;

    while (selected.length < routeBudget && hasUncovered()) {
      LabExhaustiveRouteTrace? best;
      var bestScore = 0;

      for (final route in ordered) {
        if (selectedFingerprints.contains(route.fingerprint)) continue;
        final features = _coverageOf(<LabExhaustiveRouteTrace>[route]);
        final score =
            features.optionKeys.intersection(uncoveredOptions).length +
            features.consequenceIds.intersection(uncoveredConsequences).length +
            features.gateIds.intersection(uncoveredGates).length +
            features.gateTypes.intersection(uncoveredGateTypes).length +
            features.endingIds.intersection(uncoveredEndings).length;

        if (score > bestScore) {
          best = route;
          bestScore = score;
        }
      }

      if (best == null || bestScore == 0) break;
      selected.add(best);
      selectedFingerprints.add(best.fingerprint);

      final covered = _coverageOf(<LabExhaustiveRouteTrace>[best]);
      uncoveredOptions.removeAll(covered.optionKeys);
      uncoveredConsequences.removeAll(covered.consequenceIds);
      uncoveredGates.removeAll(covered.gateIds);
      uncoveredGateTypes.removeAll(covered.gateTypes);
      uncoveredEndings.removeAll(covered.endingIds);
    }

    final remaining = ordered
        .where((route) => !selectedFingerprints.contains(route.fingerprint))
        .toList(growable: false);
    final slots = routeBudget - selected.length;

    if (slots > 0 && remaining.isNotEmpty) {
      final take = slots < remaining.length ? slots : remaining.length;
      for (var index = 0; index < take; index++) {
        final position = (index * remaining.length / take).floor();
        final route = remaining[position];
        if (selectedFingerprints.add(route.fingerprint)) {
          selected.add(route);
        }
      }
    }

    selected.sort(
      (left, right) => left.fingerprint.compareTo(right.fingerprint),
    );
    return selected;
  }

  _RouteCoverage _coverageOf(Iterable<LabExhaustiveRouteTrace> routes) {
    final optionKeys = <String>{};
    final consequenceIds = <String>{};
    final gateIds = <String>{};
    final gateTypes = <LabGateType>{};
    final endingIds = <String>{};

    for (final route in routes) {
      endingIds.add(route.endingId);
      for (final step in route.steps) {
        final optionId = step.optionId;
        if (optionId != null) {
          optionKeys.add(step.nodeId + '::' + optionId);
        }
        final consequenceId = step.consequenceId;
        if (consequenceId != null) consequenceIds.add(consequenceId);
        gateIds.add(step.gateId);
        gateTypes.add(step.gateType);
      }
    }

    return _RouteCoverage(
      optionKeys: optionKeys,
      consequenceIds: consequenceIds,
      gateIds: gateIds,
      gateTypes: gateTypes,
      endingIds: endingIds,
    );
  }

  String _selectionFingerprint(Iterable<LabExhaustiveRouteTrace> routes) {
    final fingerprints = routes.map((route) => route.fingerprint).toList()
      ..sort();
    return jsonEncode(fingerprints);
  }
}

class _RouteCoverage {
  const _RouteCoverage({
    required this.optionKeys,
    required this.consequenceIds,
    required this.gateIds,
    required this.gateTypes,
    required this.endingIds,
  });

  final Set<String> optionKeys;
  final Set<String> consequenceIds;
  final Set<String> gateIds;
  final Set<LabGateType> gateTypes;
  final Set<String> endingIds;
}
