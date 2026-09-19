import 'dart:convert';

import 'lab_contracts.dart';
import 'lab_runtime.dart';
import 'lab_state.dart';
import 'lab_story_gate.dart';

class LabExhaustiveRouteStep {
  const LabExhaustiveRouteStep({
    required this.nodeId,
    required this.gateId,
    required this.gatePriority,
    required this.stateBefore,
    required this.stateAfter,
    this.optionId,
    this.consequenceId,
    this.targetNodeId,
    this.endingId,
  });

  final String nodeId;
  final String? optionId;
  final String? consequenceId;
  final String gateId;
  final int gatePriority;
  final Map<String, Object?> stateBefore;
  final Map<String, Object?> stateAfter;
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
}

class LabExhaustiveRouteTrace {
  const LabExhaustiveRouteTrace({
    required this.steps,
    required this.endingId,
  });

  final List<LabExhaustiveRouteStep> steps;
  final String endingId;

  String get fingerprint =>
      steps.map((step) => step.transitionKey).join('>') + '=>' + endingId;
}

class LabExhaustiveRouteReport {
  const LabExhaustiveRouteReport({
    required this.routes,
    required this.optionCoverageKeys,
    required this.endingIds,
    required this.issues,
    required this.limitExceeded,
    required this.completeOptionCoverage,
    required this.completeEndingCoverage,
    required this.deterministic,
    required this.fingerprint,
  });

  final List<LabExhaustiveRouteTrace> routes;
  final Set<String> optionCoverageKeys;
  final Set<String> endingIds;
  final List<String> issues;
  final bool limitExceeded;
  final bool completeOptionCoverage;
  final bool completeEndingCoverage;
  final bool deterministic;
  final String fingerprint;

  bool get isValid =>
      routes.isNotEmpty &&
      issues.isEmpty &&
      !limitExceeded &&
      completeOptionCoverage &&
      completeEndingCoverage &&
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
    final expectedEndings = package.endings
        .map((ending) => ending['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();

    return LabExhaustiveRouteReport(
      routes: List<LabExhaustiveRouteTrace>.unmodifiable(first.routes),
      optionCoverageKeys: Set<String>.unmodifiable(first.optionCoverageKeys),
      endingIds: Set<String>.unmodifiable(first.endingIds),
      issues: List<String>.unmodifiable(first.issues),
      limitExceeded: first.limitExceeded,
      completeOptionCoverage:
          first.optionCoverageKeys.containsAll(expectedOptions),
      completeEndingCoverage: first.endingIds.containsAll(expectedEndings),
      deterministic:
          first.fingerprint == second.fingerprint &&
          first.limitExceeded == second.limitExceeded &&
          _setEquals(first.optionCoverageKeys, second.optionCoverageKeys) &&
          _setEquals(first.endingIds, second.endingIds) &&
          _listEquals(first.issues, second.issues),
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
    final optionCoverage = <String>{};
    final endingIds = <String>{};
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
          optionCoverage.add(node.id + '::' + option.id);
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
              gatePriority: gate.priority,
              stateBefore: Map<String, Object?>.unmodifiable(
                resolution.consequence.before.values,
              ),
              stateAfter: Map<String, Object?>.unmodifiable(
                resolution.consequence.after.values,
              ),
              targetNodeId: gate.targetNodeId,
              endingId: gate.endingId,
            );
            final nextSteps = <LabExhaustiveRouteStep>[...steps, step];

            if (gate.endingId != null) {
              endingIds.add(gate.endingId!);
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
          gatePriority: gate.priority,
          stateBefore: Map<String, Object?>.unmodifiable(state.values),
          stateAfter: Map<String, Object?>.unmodifiable(state.values),
          targetNodeId: gate.targetNodeId,
          endingId: gate.endingId,
        );
        final nextSteps = <LabExhaustiveRouteStep>[...steps, step];

        if (gate.endingId != null) {
          endingIds.add(gate.endingId!);
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

    final routeFingerprints = routes.map((route) => route.fingerprint).toList()
      ..sort();
    final sortedIssues = <String>[...issues]..sort();

    return _EnumerationResult(
      routes: routes,
      optionCoverageKeys: optionCoverage,
      endingIds: endingIds,
      issues: sortedIssues,
      limitExceeded: limitExceeded,
      fingerprint: routeFingerprints.join('|'),
    );
  }

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
    required this.endingIds,
    required this.issues,
    required this.limitExceeded,
    required this.fingerprint,
  });

  final List<LabExhaustiveRouteTrace> routes;
  final Set<String> optionCoverageKeys;
  final Set<String> endingIds;
  final List<String> issues;
  final bool limitExceeded;
  final String fingerprint;
}
