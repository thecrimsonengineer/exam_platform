import 'dart:convert';

import 'lab_contracts.dart';
import 'lab_runtime.dart';
import 'lab_state.dart';
import 'lab_story_gate.dart';

Map<String, Object?> _orderedState(Map<String, Object?> state) {
  final keys = state.keys.toList()..sort();
  return <String, Object?>{for (final key in keys) key: state[key]};
}

Map<String, Object?> _orderedDelta(Map<String, LabValueChange> delta) {
  final keys = delta.keys.toList()..sort();
  return <String, Object?>{
    for (final key in keys)
      key: <String, Object?>{
        'before': delta[key]!.before,
        'after': delta[key]!.after,
      },
  };
}

class LabExhaustiveRouteStep {
  const LabExhaustiveRouteStep({
    required this.nodeId,
    required this.gateId,
    required this.gateType,
    required this.gatePriority,
    required this.stateBefore,
    required this.stateAfter,
    required this.stateDelta,
    required this.evidenceBefore,
    required this.evidenceAfter,
    required this.simulatedMinutesBefore,
    required this.simulatedMinutesAfter,
    this.optionId,
    this.consequenceId,
    this.targetNodeId,
    this.endingId,
  });

  final String nodeId;
  final String? optionId;
  final String? consequenceId;
  final String gateId;
  final LabGateType gateType;
  final int gatePriority;
  final Map<String, Object?> stateBefore;
  final Map<String, Object?> stateAfter;
  final Map<String, LabValueChange> stateDelta;
  final Set<String> evidenceBefore;
  final Set<String> evidenceAfter;
  final int simulatedMinutesBefore;
  final int simulatedMinutesAfter;
  final String? targetNodeId;
  final String? endingId;

  String get transitionKey =>
      nodeId +
      '::' +
      (optionId ?? 'scene') +
      '::' +
      gateId +
      '::' +
      (targetNodeId ?? endingId ?? 'none');

  String get stateTraceFingerprint {
    final beforeEvidence = evidenceBefore.toList()..sort();
    final afterEvidence = evidenceAfter.toList()..sort();
    return jsonEncode(<String, Object?>{
      'before': _orderedState(stateBefore),
      'after': _orderedState(stateAfter),
      'delta': _orderedDelta(stateDelta),
      'gateType': gateType.name,
      'evidenceBefore': beforeEvidence,
      'evidenceAfter': afterEvidence,
      'minutesBefore': simulatedMinutesBefore,
      'minutesAfter': simulatedMinutesAfter,
    });
  }

  String get deterministicKey => transitionKey + '::' + stateTraceFingerprint;
}

class LabExhaustiveRouteTrace {
  const LabExhaustiveRouteTrace({
    required this.steps,
    required this.endingId,
  });

  final List<LabExhaustiveRouteStep> steps;
  final String endingId;

  String get fingerprint =>
      steps.map((step) => step.deterministicKey).join('>') + '=>' + endingId;
}

class LabExhaustiveRouteReport {
  const LabExhaustiveRouteReport({
    required this.routes,
    required this.optionCoverageKeys,
    required this.consequenceCoverageIds,
    required this.gateCoverageIds,
    required this.gateTypeCoverage,
    required this.endingIds,
    required this.uncoveredOptionKeys,
    required this.uncoveredConsequenceIds,
    required this.uncoveredGateIds,
    required this.uncoveredEndingIds,
    required this.issues,
    required this.limitExceeded,
    required this.completeOptionCoverage,
    required this.completeConsequenceCoverage,
    required this.completeGateCoverage,
    required this.completeEndingCoverage,
    required this.routeInvariantsHold,
    required this.deterministic,
    required this.fingerprint,
  });

  final List<LabExhaustiveRouteTrace> routes;
  final Set<String> optionCoverageKeys;
  final Set<String> consequenceCoverageIds;
  final Set<String> gateCoverageIds;
  final Set<LabGateType> gateTypeCoverage;
  final Set<String> endingIds;
  final Set<String> uncoveredOptionKeys;
  final Set<String> uncoveredConsequenceIds;
  final Set<String> uncoveredGateIds;
  final Set<String> uncoveredEndingIds;
  final List<String> issues;
  final bool limitExceeded;
  final bool completeOptionCoverage;
  final bool completeConsequenceCoverage;
  final bool completeGateCoverage;
  final bool completeEndingCoverage;
  final bool routeInvariantsHold;
  final bool deterministic;
  final String fingerprint;

  Map<String, int> get consequenceApplicationCountById {
    final counts = <String, int>{};
    for (final step in routes.expand((route) => route.steps)) {
      final consequenceId = step.consequenceId;
      if (consequenceId == null) continue;
      counts.update(
        consequenceId,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }
    final keys = counts.keys.toList()..sort();
    return Map<String, int>.unmodifiable(
      <String, int>{for (final key in keys) key: counts[key]!},
    );
  }

  Map<String, int> get gateWinCountById {
    final counts = <String, int>{};
    for (final step in routes.expand((route) => route.steps)) {
      counts.update(step.gateId, (value) => value + 1, ifAbsent: () => 1);
    }
    final keys = counts.keys.toList()..sort();
    return Map<String, int>.unmodifiable(
      <String, int>{for (final key in keys) key: counts[key]!},
    );
  }

  Map<String, int> get gateWinCountByType {
    final counts = <String, int>{};
    for (final step in routes.expand((route) => route.steps)) {
      final key = step.gateType.name;
      counts.update(key, (value) => value + 1, ifAbsent: () => 1);
    }
    final keys = counts.keys.toList()..sort();
    return Map<String, int>.unmodifiable(
      <String, int>{for (final key in keys) key: counts[key]!},
    );
  }

  Map<String, int> get routeCountByEnding {
    final counts = <String, int>{};
    for (final route in routes) {
      counts.update(route.endingId, (value) => value + 1, ifAbsent: () => 1);
    }
    final keys = counts.keys.toList()..sort();
    return Map<String, int>.unmodifiable(
      <String, int>{for (final key in keys) key: counts[key]!},
    );
  }

  Map<String, Object?> toEvidenceJson() {
    final options = optionCoverageKeys.toList()..sort();
    final consequences = consequenceCoverageIds.toList()..sort();
    final gates = gateCoverageIds.toList()..sort();
    final gateTypes = gateTypeCoverage.map((type) => type.name).toList()..sort();
    final endings = endingIds.toList()..sort();
    final missingOptions = uncoveredOptionKeys.toList()..sort();
    final missingConsequences = uncoveredConsequenceIds.toList()..sort();
    final missingGates = uncoveredGateIds.toList()..sort();
    final missingEndings = uncoveredEndingIds.toList()..sort();

    return <String, Object?>{
      'schemaVersion': 'csp11.lab.l4l.exhaustive.v1',
      'routeCount': routes.length,
      'optionCoverageKeys': options,
      'consequenceCoverageIds': consequences,
      'gateCoverageIds': gates,
      'gateTypeCoverage': gateTypes,
      'endingIds': endings,
      'routeCountByEnding': routeCountByEnding,
      'consequenceApplicationCountById': consequenceApplicationCountById,
      'gateWinCountById': gateWinCountById,
      'gateWinCountByType': gateWinCountByType,
      'uncoveredOptionKeys': missingOptions,
      'uncoveredConsequenceIds': missingConsequences,
      'uncoveredGateIds': missingGates,
      'uncoveredEndingIds': missingEndings,
      'limitExceeded': limitExceeded,
      'completeOptionCoverage': completeOptionCoverage,
      'completeConsequenceCoverage': completeConsequenceCoverage,
      'completeGateCoverage': completeGateCoverage,
      'completeEndingCoverage': completeEndingCoverage,
      'routeInvariantsHold': routeInvariantsHold,
      'deterministic': deterministic,
      'issues': issues,
      'fingerprint': fingerprint,
      'isValid': isValid,
    };
  }

  bool get isValid =>
      routes.isNotEmpty &&
      issues.isEmpty &&
      !limitExceeded &&
      completeOptionCoverage &&
      completeConsequenceCoverage &&
      completeGateCoverage &&
      completeEndingCoverage &&
      routeInvariantsHold &&
      deterministic;
}

class LabExhaustiveRouteValidator {
  const LabExhaustiveRouteValidator({
    this.runtime = const LabDeterministicRuntime(),
    this.gateEvaluator = const LabGateEvaluator(),
  });

  final LabDeterministicRuntime runtime;
  final LabGateEvaluator gateEvaluator;

  LabExhaustiveRouteReport run(
    LabPackage package, {
    int maxRoutes = 10000,
    int? maxDepth,
  }) {
    if (maxRoutes <= 0) {
      throw const LabContractException(
        'Exhaustive LAB route limit must be greater than zero.',
      );
    }

    final first = _enumerate(
      package,
      maxRoutes: maxRoutes,
      maxDepth: maxDepth,
    );
    final second = _enumerate(
      package,
      maxRoutes: maxRoutes,
      maxDepth: maxDepth,
    );
    final expectedOptions = <String>{
      for (final node in package.nodes.whereType<LabDecisionNode>())
        for (final option in node.options) node.id + '::' + option.id,
    };
    final expectedConsequences = <String>{
      for (final node in package.nodes.whereType<LabDecisionNode>())
        for (final option in node.options)
          (option.consequence?.id ?? option.consequenceId)!,
    };
    final expectedGates = package.gates
        .map((gate) => gate['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
    final expectedEndings = package.endings
        .map((ending) => ending['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
    final uncoveredOptions =
        expectedOptions.difference(first.optionCoverageKeys);
    final uncoveredConsequences =
        expectedConsequences.difference(first.consequenceCoverageIds);
    final uncoveredGates = expectedGates.difference(first.gateCoverageIds);
    final uncoveredEndings = expectedEndings.difference(first.endingIds);
    final invariantsHold = _routesHoldInvariants(
      first.routes,
      package: package,
    );

    return LabExhaustiveRouteReport(
      routes: List<LabExhaustiveRouteTrace>.unmodifiable(first.routes),
      optionCoverageKeys: Set<String>.unmodifiable(first.optionCoverageKeys),
      consequenceCoverageIds:
          Set<String>.unmodifiable(first.consequenceCoverageIds),
      gateCoverageIds: Set<String>.unmodifiable(first.gateCoverageIds),
      gateTypeCoverage:
          Set<LabGateType>.unmodifiable(first.gateTypeCoverage),
      endingIds: Set<String>.unmodifiable(first.endingIds),
      uncoveredOptionKeys: Set<String>.unmodifiable(uncoveredOptions),
      uncoveredConsequenceIds: Set<String>.unmodifiable(uncoveredConsequences),
      uncoveredGateIds: Set<String>.unmodifiable(uncoveredGates),
      uncoveredEndingIds: Set<String>.unmodifiable(uncoveredEndings),
      issues: List<String>.unmodifiable(first.issues),
      limitExceeded: first.limitExceeded,
      completeOptionCoverage: uncoveredOptions.isEmpty,
      completeConsequenceCoverage: uncoveredConsequences.isEmpty,
      completeGateCoverage: uncoveredGates.isEmpty,
      completeEndingCoverage: uncoveredEndings.isEmpty,
      routeInvariantsHold: invariantsHold,
      deterministic:
          first.fingerprint == second.fingerprint &&
          first.limitExceeded == second.limitExceeded &&
          _setEquals(first.optionCoverageKeys, second.optionCoverageKeys) &&
          _setEquals(
            first.consequenceCoverageIds,
            second.consequenceCoverageIds,
          ) &&
          _setEquals(first.gateCoverageIds, second.gateCoverageIds) &&
          _gateTypeSetEquals(
            first.gateTypeCoverage,
            second.gateTypeCoverage,
          ) &&
          _setEquals(first.endingIds, second.endingIds) &&
          _listEquals(first.issues, second.issues) &&
          invariantsHold ==
              _routesHoldInvariants(second.routes, package: package),
      fingerprint: first.fingerprint,
    );
  }

  _EnumerationResult _enumerate(
    LabPackage package, {
    required int maxRoutes,
    int? maxDepth,
  }) {
    final nodes = <String, LabNodeContract>{
      for (final node in package.nodes) node.id: node,
    };
    final gates = package.gates.map(LabStoryGate.fromJson).toList();
    final consequences = <String, LabConsequence>{
      for (final consequence in package.consequences)
        consequence.id: consequence,
    };
    final routes = <LabExhaustiveRouteTrace>[];
    final issues = <String>[];
    final depthLimit = maxDepth ?? package.nodes.length * 8 + 16;
    var limitExceeded = false;

    final startState = LabState.initial(
      registry: package.stateRegistry,
      startingState: package.metadata.startingState,
    );

    void walk(
      String nodeId,
      LabState state,
      List<LabExhaustiveRouteStep> steps,
      Set<String> activeFrames,
      String pathKey,
    ) {
      if (limitExceeded) return;
      if (routes.length >= maxRoutes) {
        limitExceeded = true;
        return;
      }
      if (steps.length > depthLimit) {
        issues.add('Route exceeded exhaustive depth guard at ' + nodeId + '.');
        return;
      }

      final frameKey = _frameKey(nodeId, state);
      if (activeFrames.contains(frameKey)) {
        issues.add('Reachable route cycle repeated state at ' + nodeId + '.');
        return;
      }
      final nextFrames = <String>{...activeFrames, frameKey};
      final node = nodes[nodeId];
      if (node == null) {
        issues.add('Route reached unknown node ' + nodeId + '.');
        return;
      }

      if (node is LabDecisionNode) {
        for (final option in node.options) {
          if (limitExceeded) return;
          try {
            final resolution = runtime.resolveDecision(
              state: state,
              node: node,
              optionId: option.id,
              applicationKey:
                  'L4L:' + pathKey + ':' + node.id + ':' + option.id,
              gates: gates,
              consequenceRegistry: consequences,
            );
            final gate = resolution.gate;
            if (gate == null) {
              issues.add(
                'Decision ' +
                    node.id +
                    ' option ' +
                    option.id +
                    ' has no Story Gate.',
              );
              continue;
            }

            final step = LabExhaustiveRouteStep(
              nodeId: node.id,
              optionId: option.id,
              consequenceId: resolution.consequence.consequenceId,
              gateId: gate.gateId,
              gateType: gate.type,
              gatePriority: gate.priority,
              stateBefore: Map<String, Object?>.unmodifiable(
                resolution.consequence.before.values,
              ),
              stateAfter: Map<String, Object?>.unmodifiable(
                resolution.consequence.after.values,
              ),
              stateDelta: Map<String, LabValueChange>.unmodifiable(
                resolution.consequence.delta,
              ),
              evidenceBefore: Set<String>.unmodifiable(
                resolution.consequence.before.evidenceUnlocked,
              ),
              evidenceAfter: Set<String>.unmodifiable(
                resolution.consequence.after.evidenceUnlocked,
              ),
              simulatedMinutesBefore:
                  resolution.consequence.before.simulatedMinutes,
              simulatedMinutesAfter:
                  resolution.consequence.after.simulatedMinutes,
              targetNodeId: gate.targetNodeId,
              endingId: gate.endingId,
            );
            final nextSteps = <LabExhaustiveRouteStep>[...steps, step];

            if (gate.endingId != null) {
              routes.add(
                LabExhaustiveRouteTrace(
                  steps: List<LabExhaustiveRouteStep>.unmodifiable(nextSteps),
                  endingId: gate.endingId!,
                ),
              );
              if (routes.length >= maxRoutes) limitExceeded = true;
              continue;
            }
            if (gate.targetNodeId == null) {
              issues.add('Gate ' + gate.gateId + ' has no route destination.');
              continue;
            }

            walk(
              gate.targetNodeId!,
              resolution.state,
              nextSteps,
              nextFrames,
              pathKey + '>' + node.id + ':' + option.id,
            );
          } on LabGateAmbiguityException catch (error) {
            issues.add(error.message);
          } catch (error) {
            issues.add(
              'Route failure at ' +
                  node.id +
                  '/' +
                  option.id +
                  ': ' +
                  error.toString(),
            );
          }
        }
        return;
      }

      try {
        final gate = gateEvaluator.evaluate(
          state: state,
          currentNodeId: node.id,
          gates: gates,
        );
        if (gate == null) {
          issues.add('Scene ' + node.id + ' has no Story Gate.');
          return;
        }
        final step = LabExhaustiveRouteStep(
          nodeId: node.id,
          gateId: gate.gateId,
          gateType: gate.type,
          gatePriority: gate.priority,
          stateBefore: Map<String, Object?>.unmodifiable(state.values),
          stateAfter: Map<String, Object?>.unmodifiable(state.values),
          stateDelta: const <String, LabValueChange>{},
          evidenceBefore: Set<String>.unmodifiable(state.evidenceUnlocked),
          evidenceAfter: Set<String>.unmodifiable(state.evidenceUnlocked),
          simulatedMinutesBefore: state.simulatedMinutes,
          simulatedMinutesAfter: state.simulatedMinutes,
          targetNodeId: gate.targetNodeId,
          endingId: gate.endingId,
        );
        final nextSteps = <LabExhaustiveRouteStep>[...steps, step];

        if (gate.endingId != null) {
          routes.add(
            LabExhaustiveRouteTrace(
              steps: List<LabExhaustiveRouteStep>.unmodifiable(nextSteps),
              endingId: gate.endingId!,
            ),
          );
          if (routes.length >= maxRoutes) limitExceeded = true;
          return;
        }
        if (gate.targetNodeId == null) {
          issues.add(
            'Scene gate ' + gate.gateId + ' has no route destination.',
          );
          return;
        }

        walk(
          gate.targetNodeId!,
          state,
          nextSteps,
          nextFrames,
          pathKey + '>' + node.id + ':scene',
        );
      } on LabGateAmbiguityException catch (error) {
        issues.add(error.message);
      } catch (error) {
        issues.add('Scene route failure at ' + node.id + ': ' + error.toString());
      }
    }

    walk(
      package.metadata.startingNodeId,
      startState,
      const <LabExhaustiveRouteStep>[],
      const <String>{},
      'root',
    );

    final completedSteps = routes.expand((route) => route.steps).toList();
    final optionCoverage = <String>{
      for (final step in completedSteps)
        if (step.optionId != null) step.nodeId + '::' + step.optionId!,
    };
    final consequenceCoverage = <String>{
      for (final step in completedSteps)
        if (step.consequenceId != null) step.consequenceId!,
    };
    final gateCoverage = <String>{
      for (final step in completedSteps) step.gateId,
    };
    final gateTypeCoverage = <LabGateType>{
      for (final step in completedSteps) step.gateType,
    };
    final endingIds = <String>{
      for (final route in routes) route.endingId,
    };

    final routeFingerprints = routes.map((route) => route.fingerprint).toList()
      ..sort();
    final sortedIssues = <String>[...issues]..sort();

    return _EnumerationResult(
      routes: routes,
      optionCoverageKeys: optionCoverage,
      consequenceCoverageIds: consequenceCoverage,
      gateCoverageIds: gateCoverage,
      gateTypeCoverage: gateTypeCoverage,
      endingIds: endingIds,
      issues: sortedIssues,
      limitExceeded: limitExceeded,
      fingerprint: routeFingerprints.join('|'),
    );
  }

  bool _routesHoldInvariants(
    List<LabExhaustiveRouteTrace> routes, {
    required LabPackage package,
  }) {
    if (routes.isEmpty) return false;

    final initial = LabState.initial(
      registry: package.stateRegistry,
      startingState: package.metadata.startingState,
    ).snapshot;
    final authoredEndingIds = package.endings
        .map((ending) => ending['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
    final authoredConsequences = <String, LabConsequence>{
      for (final consequence in package.consequences)
        consequence.id: consequence,
      for (final node in package.nodes.whereType<LabDecisionNode>())
        for (final option in node.options)
          if (option.consequence != null)
            option.consequence!.id: option.consequence!,
    };
    final authoredGates = <String, LabStoryGate>{
      for (final gate in package.gates.map(LabStoryGate.fromJson))
        gate.id: gate,
    };

    for (final route in routes) {
      if (route.steps.isEmpty) return false;
      final first = route.steps.first;
      if (!_mapEquals(first.stateBefore, initial.values) ||
          first.evidenceBefore.isNotEmpty ||
          first.simulatedMinutesBefore != 0) {
        return false;
      }

      for (var index = 0; index < route.steps.length; index++) {
        final step = route.steps[index];
        if (step.simulatedMinutesAfter < step.simulatedMinutesBefore ||
            !step.evidenceAfter.containsAll(step.evidenceBefore) ||
            !_deltaMatchesSnapshots(step) ||
            !_authoredConsequenceMatches(step, authoredConsequences) ||
            !_authoredGateMatches(step, authoredGates)) {
          return false;
        }

        final hasTarget = step.targetNodeId != null;
        final hasEnding = step.endingId != null;
        if (hasTarget == hasEnding) return false;

        final terminal = index == route.steps.length - 1;
        if (terminal) {
          if (!hasEnding ||
              step.endingId != route.endingId ||
              !authoredEndingIds.contains(route.endingId) ||
              step.gateType != LabGateType.completion) {
            return false;
          }
        } else {
          if (!hasTarget || hasEnding) return false;
          final next = route.steps[index + 1];
          if (step.targetNodeId != next.nodeId ||
              !_mapEquals(step.stateAfter, next.stateBefore) ||
              !_setEquals(step.evidenceAfter, next.evidenceBefore) ||
              step.simulatedMinutesAfter != next.simulatedMinutesBefore) {
            return false;
          }
        }
      }
    }
    return true;
  }

  bool _authoredConsequenceMatches(
    LabExhaustiveRouteStep step,
    Map<String, LabConsequence> authored,
  ) {
    if (step.optionId == null) {
      return step.consequenceId == null &&
          step.stateDelta.isEmpty &&
          step.simulatedMinutesAfter == step.simulatedMinutesBefore &&
          _setEquals(step.evidenceBefore, step.evidenceAfter);
    }

    final consequenceId = step.consequenceId;
    if (consequenceId == null) return false;
    final consequence = authored[consequenceId];
    if (consequence == null) return false;

    if (step.simulatedMinutesAfter !=
        step.simulatedMinutesBefore + consequence.simulatedMinutes) {
      return false;
    }

    final expectedEvidence = <String>{
      ...step.evidenceBefore,
      ...consequence.evidenceUnlocks,
    };
    if (!_setEquals(expectedEvidence, step.evidenceAfter)) return false;

    final expectedMutationIds = consequence.mutations
        .where((mutation) => mutation.kind != LabMutationKind.noOp)
        .map((mutation) => mutation.stateId)
        .whereType<String>()
        .toSet();
    if (!step.stateDelta.keys.toSet().containsAll(expectedMutationIds)) {
      return false;
    }
    return true;
  }

  bool _authoredGateMatches(
    LabExhaustiveRouteStep step,
    Map<String, LabStoryGate> authored,
  ) {
    final gate = authored[step.gateId];
    if (gate == null ||
        (gate.fromNodeId != null && gate.fromNodeId != step.nodeId) ||
        gate.type != step.gateType ||
        gate.priority != step.gatePriority ||
        gate.targetNodeId != step.targetNodeId ||
        gate.endingId != step.endingId) {
      return false;
    }
    return true;
  }

  bool _deltaMatchesSnapshots(LabExhaustiveRouteStep step) {
    for (final entry in step.stateDelta.entries) {
      if (!_valueEquals(entry.value.before, step.stateBefore[entry.key]) ||
          !_valueEquals(entry.value.after, step.stateAfter[entry.key])) {
        return false;
      }
    }
    for (final key in step.stateBefore.keys) {
      if (!step.stateAfter.containsKey(key)) return false;
      if (!step.stateDelta.containsKey(key) &&
          !_valueEquals(step.stateBefore[key], step.stateAfter[key])) {
        return false;
      }
    }
    return step.stateAfter.keys.every(step.stateBefore.containsKey);
  }

  bool _mapEquals(Map<String, Object?> left, Map<String, Object?> right) {
    if (left.length != right.length) return false;
    for (final key in left.keys) {
      if (!right.containsKey(key) || !_valueEquals(left[key], right[key])) {
        return false;
      }
    }
    return true;
  }

  bool _valueEquals(Object? left, Object? right) =>
      jsonEncode(left) == jsonEncode(right);

  bool _gateTypeSetEquals(Set<LabGateType> left, Set<LabGateType> right) =>
      left.length == right.length && left.containsAll(right);

  String _frameKey(String nodeId, LabState state) {
    final keys = state.values.keys.toList()..sort();
    final orderedValues = <String, Object?>{
      for (final key in keys) key: state.values[key],
    };
    final evidence = state.evidenceUnlocked.toList()..sort();
    return nodeId +
        '|' +
        jsonEncode(orderedValues) +
        '|' +
        jsonEncode(evidence) +
        '|' +
        state.simulatedMinutes.toString();
  }

  bool _setEquals(Set<String> left, Set<String> right) =>
      left.length == right.length && left.containsAll(right);

  bool _listEquals(List<String> left, List<String> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }
}

class _EnumerationResult {
  const _EnumerationResult({
    required this.routes,
    required this.optionCoverageKeys,
    required this.consequenceCoverageIds,
    required this.gateCoverageIds,
    required this.gateTypeCoverage,
    required this.endingIds,
    required this.issues,
    required this.limitExceeded,
    required this.fingerprint,
  });

  final List<LabExhaustiveRouteTrace> routes;
  final Set<String> optionCoverageKeys;
  final Set<String> consequenceCoverageIds;
  final Set<String> gateCoverageIds;
  final Set<LabGateType> gateTypeCoverage;
  final Set<String> endingIds;
  final List<String> issues;
  final bool limitExceeded;
  final String fingerprint;
}
