import 'dart:collection';
import 'dart:convert';

import 'lab_contracts.dart';
import 'lab_runtime.dart';
import 'lab_state.dart';
import 'lab_story_gate.dart';

enum LabValidationSeverity { warning, error }

class LabValidationIssue {
  const LabValidationIssue({
    required this.code,
    required this.message,
    required this.path,
    this.severity = LabValidationSeverity.error,
  });

  final String code;
  final String message;
  final String path;
  final LabValidationSeverity severity;

  bool get isBlocking => severity == LabValidationSeverity.error;
}

class LabValidationReport {
  const LabValidationReport({
    required this.issues,
    required this.simulationCount,
    required this.reachableNodeIds,
    required this.reachableEndingIds,
    required this.deterministic,
  });

  final List<LabValidationIssue> issues;
  final int simulationCount;
  final Set<String> reachableNodeIds;
  final Set<String> reachableEndingIds;
  final bool deterministic;

  bool get hasBlockingIssues => issues.any((issue) => issue.isBlocking);
  bool get isValid => !hasBlockingIssues && deterministic;

  int get errorCount => issues
      .where((issue) => issue.severity == LabValidationSeverity.error)
      .length;

  int get warningCount => issues
      .where((issue) => issue.severity == LabValidationSeverity.warning)
      .length;

  bool hasCode(String code) => issues.any((issue) => issue.code == code);
}

class LabSimulationResult {
  const LabSimulationResult({
    required this.traversalCount,
    required this.reachableNodeIds,
    required this.reachableEndingIds,
    required this.fingerprint,
    required this.issues,
  });

  final int traversalCount;
  final Set<String> reachableNodeIds;
  final Set<String> reachableEndingIds;
  final String fingerprint;
  final List<LabValidationIssue> issues;
}

class LabPathSimulator {
  const LabPathSimulator({this.runtime = const LabDeterministicRuntime()});

  final LabDeterministicRuntime runtime;

  LabSimulationResult run(LabPackage package, {int limit = 1000}) {
    if (limit <= 0) {
      throw const LabContractException(
        'Simulation limit must be greater than zero.',
      );
    }

    final gates = package.gates.map(LabStoryGate.fromJson).toList();
    final consequences = <String, LabConsequence>{
      for (final consequence in package.consequences)
        consequence.id: consequence,
    };
    final nodes = <String, LabNodeContract>{
      for (final node in package.nodes) node.id: node,
    };

    final startState = LabState.initial(
      registry: package.stateRegistry,
      startingState: package.metadata.startingState,
    );

    final queue = Queue<_SimulationFrame>()
      ..add(
        _SimulationFrame(
          nodeId: package.metadata.startingNodeId,
          state: startState,
          depth: 0,
          pathKey: 'root',
        ),
      );

    final visited = <String>{};
    final reachableNodes = <String>{};
    final reachableEndings = <String>{};
    final fingerprints = <String>[];
    final issues = <LabValidationIssue>[];
    var traversals = 0;

    while (queue.isNotEmpty && traversals < limit) {
      final frame = queue.removeFirst();
      final key = _frameKey(frame);
      if (!visited.add(key)) continue;

      reachableNodes.add(frame.nodeId);
      final node = nodes[frame.nodeId];
      if (node == null) {
        issues.add(
          LabValidationIssue(
            code: 'simulation_unknown_node',
            message: 'Simulation reached unknown node ${frame.nodeId}.',
            path: 'nodes',
          ),
        );
        continue;
      }

      if (frame.depth > package.nodes.length * 8 + 16) {
        issues.add(
          const LabValidationIssue(
            code: 'simulation_cycle_guard',
            message: 'Simulation exceeded the deterministic cycle guard.',
            path: 'gates',
          ),
        );
        continue;
      }

      if (node is LabDecisionNode) {
        for (final option in node.options) {
          if (traversals >= limit) break;
          traversals++;
          try {
            final result = runtime.resolveDecision(
              state: frame.state,
              node: node,
              optionId: option.id,
              applicationKey: frame.pathKey + ':' + node.id + ':' + option.id,
              gates: gates,
              consequenceRegistry: consequences,
            );
            final gate = result.gate;
            if (gate == null) {
              issues.add(
                LabValidationIssue(
                  code: 'runtime_dead_end',
                  message:
                      'Decision ${node.id} option ${option.id} has no eligible Story Gate.',
                  path: 'nodes.${node.id}.options.${option.id}',
                ),
              );
              continue;
            }

            fingerprints.add(
              node.id +
                  ':' +
                  option.id +
                  ':' +
                  gate.gateId +
                  ':' +
                  (gate.targetNodeId ?? gate.endingId ?? ''),
            );

            if (gate.endingId != null) {
              reachableEndings.add(gate.endingId!);
              continue;
            }

            if (gate.targetNodeId == null) {
              issues.add(
                LabValidationIssue(
                  code: 'runtime_gate_no_target',
                  message: 'Gate ${gate.gateId} has no runtime destination.',
                  path: 'gates.${gate.gateId}',
                ),
              );
              continue;
            }

            reachableNodes.add(gate.targetNodeId!);
            queue.add(
              _SimulationFrame(
                nodeId: gate.targetNodeId!,
                state: result.state,
                depth: frame.depth + 1,
                pathKey: frame.pathKey + '>' + node.id + ':' + option.id,
              ),
            );
          } on LabGateAmbiguityException catch (error) {
            issues.add(
              LabValidationIssue(
                code: 'gate_ambiguity',
                message: error.message,
                path: 'gates',
              ),
            );
          } catch (error) {
            issues.add(
              LabValidationIssue(
                code: 'simulation_failure',
                message: error.toString(),
                path: 'nodes.${node.id}',
              ),
            );
          }
        }
      } else {
        traversals++;
        try {
          final gate = const LabGateEvaluator().evaluate(
            state: frame.state,
            currentNodeId: node.id,
            gates: gates,
          );
          if (gate == null) {
            issues.add(
              LabValidationIssue(
                code: 'runtime_dead_end',
                message: 'Scene ${node.id} has no eligible Story Gate.',
                path: 'nodes.${node.id}',
              ),
            );
            continue;
          }

          fingerprints.add(
            node.id +
                ':scene:' +
                gate.gateId +
                ':' +
                (gate.targetNodeId ?? gate.endingId ?? ''),
          );

          if (gate.endingId != null) {
            reachableEndings.add(gate.endingId!);
          } else if (gate.targetNodeId != null) {
            reachableNodes.add(gate.targetNodeId!);
            queue.add(
              _SimulationFrame(
                nodeId: gate.targetNodeId!,
                state: frame.state,
                depth: frame.depth + 1,
                pathKey: frame.pathKey + '>' + node.id,
              ),
            );
          } else {
            issues.add(
              LabValidationIssue(
                code: 'runtime_gate_no_target',
                message: 'Gate ${gate.gateId} has no runtime destination.',
                path: 'gates.${gate.gateId}',
              ),
            );
          }
        } on LabGateAmbiguityException catch (error) {
          issues.add(
            LabValidationIssue(
              code: 'gate_ambiguity',
              message: error.message,
              path: 'gates',
            ),
          );
        } catch (error) {
          issues.add(
            LabValidationIssue(
              code: 'simulation_failure',
              message: error.toString(),
              path: 'nodes.${node.id}',
            ),
          );
        }
      }
    }

    fingerprints.sort();
    return LabSimulationResult(
      traversalCount: traversals,
      reachableNodeIds: Set<String>.unmodifiable(reachableNodes),
      reachableEndingIds: Set<String>.unmodifiable(reachableEndings),
      fingerprint: fingerprints.join('|'),
      issues: List<LabValidationIssue>.unmodifiable(issues),
    );
  }

  String _frameKey(_SimulationFrame frame) {
    final keys = frame.state.values.keys.toList()..sort();
    final values = <String, Object?>{
      for (final key in keys) key: frame.state.values[key],
    };
    final evidence = frame.state.evidenceUnlocked.toList()..sort();

    return frame.nodeId +
        '|' +
        jsonEncode(values) +
        '|' +
        jsonEncode(evidence) +
        '|' +
        frame.state.simulatedMinutes.toString();
  }
}

class _SimulationFrame {
  const _SimulationFrame({
    required this.nodeId,
    required this.state,
    required this.depth,
    required this.pathKey,
  });

  final String nodeId;
  final LabState state;
  final int depth;
  final String pathKey;
}

class LabValidationEngine {
  const LabValidationEngine({this.simulator = const LabPathSimulator()});

  final LabPathSimulator simulator;

  LabValidationReport validateSource(
    String source, {
    Set<String>? availableAssetIds,
    Set<String>? allowedCompetencyIds,
    int simulationLimit = 1000,
  }) {
    final issues = <LabValidationIssue>[];
    Object? decoded;

    try {
      decoded = jsonDecode(source);
    } catch (error) {
      return LabValidationReport(
        issues: <LabValidationIssue>[
          LabValidationIssue(
            code: 'json_decode',
            message: 'LAB JSON could not be decoded: $error',
            path: r'$',
          ),
        ],
        simulationCount: 0,
        reachableNodeIds: const <String>{},
        reachableEndingIds: const <String>{},
        deterministic: false,
      );
    }

    if (decoded is! Map) {
      return const LabValidationReport(
        issues: <LabValidationIssue>[
          LabValidationIssue(
            code: 'root_type',
            message: 'LAB JSON root must be an object.',
            path: r'$',
          ),
        ],
        simulationCount: 0,
        reachableNodeIds: <String>{},
        reachableEndingIds: <String>{},
        deterministic: false,
      );
    }

    final root = decoded.cast<String, Object?>();
    _rawContractChecks(root, issues);

    LabPackage package;
    try {
      package = LabPackage.fromJson(root);
    } catch (error) {
      issues.add(
        LabValidationIssue(
          code: 'contract',
          message: error.toString(),
          path: r'$',
        ),
      );
      return LabValidationReport(
        issues: List<LabValidationIssue>.unmodifiable(issues),
        simulationCount: 0,
        reachableNodeIds: const <String>{},
        reachableEndingIds: const <String>{},
        deterministic: false,
      );
    }

    return validatePackage(
      package,
      root: root,
      initialIssues: issues,
      availableAssetIds: availableAssetIds,
      allowedCompetencyIds: allowedCompetencyIds,
      simulationLimit: simulationLimit,
    );
  }

  LabValidationReport validatePackage(
    LabPackage package, {
    Map<String, Object?>? root,
    Iterable<LabValidationIssue> initialIssues = const <LabValidationIssue>[],
    Set<String>? availableAssetIds,
    Set<String>? allowedCompetencyIds,
    int simulationLimit = 1000,
  }) {
    final issues = <LabValidationIssue>[...initialIssues];
    final nodeIds = package.nodes.map((node) => node.id).toSet();
    final consequenceIds = package.consequences
        .map((consequence) => consequence.id)
        .toSet();

    if (consequenceIds.length != package.consequences.length) {
      issues.add(
        const LabValidationIssue(
          code: 'duplicate_consequence',
          message: 'Consequence IDs must be unique.',
          path: 'consequences',
        ),
      );
    }

    final gates = <LabStoryGate>[];
    for (var index = 0; index < package.gates.length; index++) {
      final raw = package.gates[index];
      try {
        final gate = LabStoryGate.fromJson(raw);
        gates.add(gate);

        if (gate.fromNodeId != null && !nodeIds.contains(gate.fromNodeId)) {
          issues.add(
            LabValidationIssue(
              code: 'gate_source_reference',
              message: 'Gate ${gate.id} references an unknown source node.',
              path: 'gates[$index].fromNodeId',
            ),
          );
        }
        if (gate.targetNodeId != null && !nodeIds.contains(gate.targetNodeId)) {
          issues.add(
            LabValidationIssue(
              code: 'gate_target_reference',
              message: 'Gate ${gate.id} references an unknown target node.',
              path: 'gates[$index].targetNodeId',
            ),
          );
        }
        if (gate.type == LabGateType.criticalEvent &&
            gate.condition is LabAlwaysCondition) {
          issues.add(
            LabValidationIssue(
              code: 'critical_event_prerequisite',
              message:
                  'Critical Event Gate ${gate.id} requires an explicit prerequisite condition.',
              path: 'gates[$index].condition',
            ),
          );
        }
      } catch (error) {
        issues.add(
          LabValidationIssue(
            code: 'gate_contract',
            message: error.toString(),
            path: 'gates[$index]',
          ),
        );
      }
    }

    final endingIds = <String>{};
    for (var index = 0; index < package.endings.length; index++) {
      final ending = package.endings[index];
      final id = ending['id']?.toString() ?? '';
      try {
        LabIds.requireCanonical(id, 'ending ID');
        parseEndingFamily(ending['family']);
      } catch (error) {
        issues.add(
          LabValidationIssue(
            code: 'ending_contract',
            message: error.toString(),
            path: 'endings[$index]',
          ),
        );
        continue;
      }
      if (!endingIds.add(id)) {
        issues.add(
          LabValidationIssue(
            code: 'duplicate_ending',
            message: 'Duplicate ending ID: $id',
            path: 'endings[$index].id',
          ),
        );
      }
    }

    for (var index = 0; index < gates.length; index++) {
      final gate = gates[index];
      if (gate.endingId != null && !endingIds.contains(gate.endingId)) {
        issues.add(
          LabValidationIssue(
            code: 'ending_reference',
            message: 'Gate ${gate.id} references an unknown ending.',
            path: 'gates[$index].endingId',
          ),
        );
      }
    }

    final evidenceIds = <String>{};
    for (var index = 0; index < package.evidence.length; index++) {
      final evidence = package.evidence[index];
      final id = evidence['id']?.toString() ?? '';
      if (!LabIds.isCanonical(id)) {
        issues.add(
          LabValidationIssue(
            code: 'evidence_id',
            message: 'Evidence requires a canonical ID.',
            path: 'evidence[$index].id',
          ),
        );
      } else {
        evidenceIds.add(id);
      }

      final assetId = evidence['assetId']?.toString();
      final required = evidence['required'] != false;
      if (assetId != null &&
          assetId.isNotEmpty &&
          required &&
          availableAssetIds != null &&
          !availableAssetIds.contains(assetId)) {
        issues.add(
          LabValidationIssue(
            code: 'asset_unavailable',
            message: 'Required LAB asset is unavailable: $assetId',
            path: 'evidence[$index].assetId',
          ),
        );
      }
    }

    for (final node in package.nodes.whereType<LabDecisionNode>()) {
      for (final option in node.options) {
        if (option.consequenceId != null &&
            !consequenceIds.contains(option.consequenceId)) {
          issues.add(
            LabValidationIssue(
              code: 'consequence_reference',
              message: 'Option ${option.id} references an unknown consequence.',
              path: 'nodes.${node.id}.options.${option.id}.consequenceId',
            ),
          );
        }

        LabConsequence? consequence = option.consequence;
        if (consequence == null && option.consequenceId != null) {
          for (final candidate in package.consequences) {
            if (candidate.id == option.consequenceId) {
              consequence = candidate;
              break;
            }
          }
        }
        if (consequence == null) continue;

        for (final mutation in consequence.mutations) {
          final stateId = mutation.stateId;
          if (stateId != null &&
              !package.stateRegistry.definitions.containsKey(stateId)) {
            issues.add(
              LabValidationIssue(
                code: 'state_reference',
                message:
                    'Consequence ${consequence.id} references unknown state $stateId.',
                path: 'consequences.${consequence.id}',
              ),
            );
          }
        }

        for (final evidenceId in consequence.evidenceUnlocks) {
          if (!evidenceIds.contains(evidenceId)) {
            issues.add(
              LabValidationIssue(
                code: 'evidence_reference',
                message:
                    'Consequence ${consequence.id} unlocks unknown evidence $evidenceId.',
                path: 'consequences.${consequence.id}.evidenceUnlocks',
              ),
            );
          }
        }
      }
    }

    for (final mapping in package.metadata.competencyMappings) {
      final canonical = RegExp(r'^d\d{2}_c\d{2}$').hasMatch(mapping);
      if (!canonical ||
          (allowedCompetencyIds != null &&
              !allowedCompetencyIds.contains(mapping))) {
        issues.add(
          LabValidationIssue(
            code: 'competency_mapping',
            message: 'Invalid canonical competency mapping: $mapping',
            path: 'competencyMappings',
          ),
        );
      }
    }

    if (package.metadata.sources.isEmpty) {
      issues.add(
        const LabValidationIssue(
          code: 'source_reference',
          message: 'At least one LAB source/reference is required.',
          path: 'sources',
        ),
      );
    } else {
      for (final source in package.metadata.sources) {
        if (source.trim().isEmpty) {
          issues.add(
            const LabValidationIssue(
              code: 'source_reference',
              message: 'LAB source/reference entries cannot be blank.',
              path: 'sources',
            ),
          );
        }
      }
    }

    _validateStaticGraph(package, gates, endingIds, issues);
    _validateAlwaysGateAmbiguity(gates, issues);

    LabSimulationResult first = const LabSimulationResult(
      traversalCount: 0,
      reachableNodeIds: <String>{},
      reachableEndingIds: <String>{},
      fingerprint: '',
      issues: <LabValidationIssue>[],
    );
    var deterministic = false;

    if (!issues.any((issue) => issue.isBlocking)) {
      try {
        first = simulator.run(package, limit: simulationLimit);
        final second = simulator.run(package, limit: simulationLimit);
        issues.addAll(first.issues);
        deterministic =
            first.fingerprint == second.fingerprint &&
            first.traversalCount == second.traversalCount &&
            _setEquals(first.reachableNodeIds, second.reachableNodeIds) &&
            _setEquals(first.reachableEndingIds, second.reachableEndingIds);
        if (!deterministic) {
          issues.add(
            const LabValidationIssue(
              code: 'nondeterministic',
              message: 'Repeated LAB simulations produced different results.',
              path: 'gates',
            ),
          );
        }
      } catch (error) {
        issues.add(
          LabValidationIssue(
            code: 'simulation_failure',
            message: error.toString(),
            path: 'gates',
          ),
        );
      }
    }

    return LabValidationReport(
      issues: List<LabValidationIssue>.unmodifiable(issues),
      simulationCount: first.traversalCount,
      reachableNodeIds: first.reachableNodeIds,
      reachableEndingIds: first.reachableEndingIds,
      deterministic: deterministic,
    );
  }

  void _rawContractChecks(
    Map<String, Object?> root,
    List<LabValidationIssue> issues,
  ) {
    final nodes = root['nodes'];
    if (nodes is! Iterable) return;

    var nodeIndex = 0;
    for (final rawNode in nodes) {
      if (rawNode is Map &&
          rawNode['type']?.toString().toUpperCase() == 'DECISION') {
        final options = rawNode['options'];
        if (options is! Iterable || options.length != 4) {
          issues.add(
            LabValidationIssue(
              code: 'four_options',
              message: 'Decision Nodes require exactly four options.',
              path: 'nodes[$nodeIndex].options',
            ),
          );
        } else {
          final best = options
              .where((option) => option is Map && option['isBest'] == true)
              .length;
          if (best != 1) {
            issues.add(
              LabValidationIssue(
                code: 'best_uniqueness',
                message: 'Decision Node requires exactly one BEST option.',
                path: 'nodes[$nodeIndex].options',
              ),
            );
          }
        }
      }
      nodeIndex++;
    }
  }

  void _validateStaticGraph(
    LabPackage package,
    List<LabStoryGate> gates,
    Set<String> endingIds,
    List<LabValidationIssue> issues,
  ) {
    final adjacency = <String, Set<String>>{
      for (final node in package.nodes) node.id: <String>{},
    };
    final completionSources = <String>{};

    for (final gate in gates) {
      final sources = gate.fromNodeId == null
          ? adjacency.keys
          : <String>[gate.fromNodeId!];

      for (final source in sources) {
        if (!adjacency.containsKey(source)) continue;
        if (gate.targetNodeId != null) {
          adjacency[source]!.add(gate.targetNodeId!);
        }
        if (gate.endingId != null && endingIds.contains(gate.endingId)) {
          completionSources.add(source);
        }
      }
    }

    final reachable = <String>{};
    final queue = Queue<String>()..add(package.metadata.startingNodeId);
    while (queue.isNotEmpty) {
      final node = queue.removeFirst();
      if (!reachable.add(node)) continue;
      for (final target in adjacency[node] ?? const <String>{}) {
        if (!reachable.contains(target)) queue.add(target);
      }
    }

    for (final node in package.nodes) {
      if (!reachable.contains(node.id)) {
        issues.add(
          LabValidationIssue(
            code: 'orphan_node',
            message: 'Node ${node.id} is unreachable from the starting node.',
            path: 'nodes.${node.id}',
          ),
        );
      } else if ((adjacency[node.id]?.isEmpty ?? true) &&
          !completionSources.contains(node.id)) {
        issues.add(
          LabValidationIssue(
            code: 'dead_end',
            message: 'Reachable node ${node.id} has no authored continuation.',
            path: 'nodes.${node.id}',
          ),
        );
      }
    }

    final reachableCompletionSources = completionSources
        .where(reachable.contains)
        .toSet();
    if (reachableCompletionSources.isEmpty) {
      issues.add(
        const LabValidationIssue(
          code: 'ending_unreachable',
          message: 'No authored ending is reachable from the starting node.',
          path: 'endings',
        ),
      );
    }

    final visiting = <String>{};
    final visited = <String>{};

    bool unsafeCycle(String node, List<String> stack) {
      if (visiting.contains(node)) {
        final cycleStart = stack.indexOf(node);
        final cycle = cycleStart < 0
            ? <String>{node}
            : stack.sublist(cycleStart).toSet();
        final hasCompletion = cycle.any(completionSources.contains);
        final exits = cycle.any(
          (member) => (adjacency[member] ?? const <String>{}).any(
            (target) => !cycle.contains(target),
          ),
        );
        return !hasCompletion && !exits;
      }
      if (!visited.add(node)) return false;

      visiting.add(node);
      stack.add(node);
      for (final target in adjacency[node] ?? const <String>{}) {
        if (unsafeCycle(target, stack)) return true;
      }
      stack.removeLast();
      visiting.remove(node);
      return false;
    }

    if (unsafeCycle(package.metadata.startingNodeId, <String>[])) {
      issues.add(
        const LabValidationIssue(
          code: 'unsafe_cycle',
          message:
              'Reachable graph contains a cycle with no authored exit or ending.',
          path: 'gates',
        ),
      );
    }
  }

  void _validateAlwaysGateAmbiguity(
    List<LabStoryGate> gates,
    List<LabValidationIssue> issues,
  ) {
    for (var i = 0; i < gates.length; i++) {
      final left = gates[i];
      if (left.condition is! LabAlwaysCondition) continue;
      for (var j = i + 1; j < gates.length; j++) {
        final right = gates[j];
        if (right.condition is! LabAlwaysCondition) continue;
        if (left.fromNodeId == right.fromNodeId &&
            left.priority == right.priority) {
          issues.add(
            LabValidationIssue(
              code: 'gate_ambiguity',
              message:
                  'Always-true gates ${left.id} and ${right.id} share the same priority.',
              path: 'gates',
            ),
          );
        }
      }
    }
  }

  bool _setEquals(Set<String> left, Set<String> right) =>
      left.length == right.length && left.containsAll(right);
}
