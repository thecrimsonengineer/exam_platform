import 'dart:convert';
import 'dart:io';

import 'package:exam_platform/features/lab/lab_contracts.dart';
import 'package:exam_platform/features/lab/lab_exhaustive_route_validator.dart';
import 'package:flutter_test/flutter_test.dart';

LabPackage _referenceV2() => LabPackage.decode(
  File('content/lab_reference_confined_space_h2s_v2.json').readAsStringSync(),
);

void main() {
  test('L4L reaches every reference option and authored ending', () {
    final package = _referenceV2();
    final report = const LabExhaustiveRouteValidator().run(package);

    final expectedOptionCount = package.nodes
        .whereType<LabDecisionNode>()
        .fold<int>(0, (sum, node) => sum + node.options.length);
    final expectedEndings = package.endings
        .map((ending) => ending['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();

    expect(report.isValid, isTrue);
    expect(report.deterministic, isTrue);
    expect(report.limitExceeded, isFalse);
    expect(report.issues, isEmpty);
    expect(report.optionCoverageKeys, hasLength(expectedOptionCount));
    expect(report.optionCoverageKeys, hasLength(20));
    expect(report.endingIds, containsAll(expectedEndings));
    expect(report.endingIds, hasLength(5));
    expect(report.routes, hasLength(196));
  });

  test('L4L freezes exact reference ending distribution', () {
    final report = const LabExhaustiveRouteValidator().run(_referenceV2());

    expect(
      report.routeCountByEnding,
      <String, int>{
        'safe_completion': 48,
        'controlled_recovery': 48,
        'incident_contained': 48,
        'major_incident': 39,
        'critical_failure': 13,
      },
    );
    expect(
      report.routeCountByEnding.values.fold<int>(0, (sum, count) => sum + count),
      196,
    );
  });

  test('L4L freezes critical-event and convergence gate win counts', () {
    final report = const LabExhaustiveRouteValidator().run(_referenceV2());

    expect(report.gateWinCountById['permit_critical_event'], 13);
    expect(report.gateWinCountById['permit_route'], 183);
    expect(report.gateWinCountById['gas_critical_event'], 39);
    expect(report.gateWinCountById['gas_work_convergence'], 144);
    expect(report.gateWinCountById['simops_critical_event'], 117);
    expect(report.gateWinCountById['simops_safe_completion'], 9);
    expect(report.gateWinCountById['simops_recovery_completion'], 9);
    expect(report.gateWinCountById['simops_contained_completion'], 9);
    expect(report.gateWinCountById['emergency_critical_failure'], 13);
    expect(report.gateWinCountById['emergency_convergence'], 156);
    expect(report.gateWinCountById['ending_safe'], 39);
    expect(report.gateWinCountById['ending_recovery'], 39);
    expect(report.gateWinCountById['ending_contained'], 39);
    expect(report.gateWinCountById['ending_major'], 39);

    expect(
      report.gateWinCountByType,
      <String, int>{
        'route': 183,
        'criticalEvent': 169,
        'convergence': 300,
        'completion': 196,
      },
    );
    expect(
      report.gateWinCountByType.values.fold<int>(
        0,
        (sum, count) => sum + count,
      ),
      848,
    );
  });

  test('L4L records consequence state and winning gate for every step', () {
    final report = const LabExhaustiveRouteValidator().run(_referenceV2());

    expect(
      report.routes.every(
        (route) => route.steps.every(
          (step) =>
              step.gateId.isNotEmpty &&
              step.stateBefore.isNotEmpty &&
              step.stateAfter.isNotEmpty &&
              (step.optionId == null ||
                  (step.consequenceId != null &&
                      step.consequenceId!.isNotEmpty)),
        ),
      ),
      isTrue,
    );
  });

  test('L4L proves critical SIMOPS option wins priority emergency gate', () {
    final report = const LabExhaustiveRouteValidator().run(_referenceV2());
    final criticalSteps = report.routes
        .expand((route) => route.steps)
        .where(
          (step) => step.nodeId == 'simops_decision' && step.optionId == 's4',
        )
        .toList();

    expect(criticalSteps, isNotEmpty);
    expect(
      criticalSteps.every(
        (step) =>
            step.gateId == 'simops_critical_event' &&
            step.gatePriority == 100 &&
            step.targetNodeId == 'emergency_decision',
      ),
      isTrue,
    );
  });

  test('L4L proves safe SIMOPS option reaches authored safe ending', () {
    final report = const LabExhaustiveRouteValidator().run(_referenceV2());

    expect(
      report.routes.any(
        (route) =>
            route.endingId == 'safe_completion' &&
            route.steps.any(
              (step) =>
                  step.nodeId == 'simops_decision' &&
                  step.optionId == 's1' &&
                  step.gateId == 'simops_safe_completion',
            ),
      ),
      isTrue,
    );
  });

  test('L4L fails closed when route cap prevents exhaustive proof', () {
    final report = const LabExhaustiveRouteValidator().run(
      _referenceV2(),
      maxRoutes: 10,
    );

    expect(report.limitExceeded, isTrue);
    expect(report.isValid, isFalse);
  });


  test('L4L fingerprints consequence state, evidence and simulated time', () {
    final report = const LabExhaustiveRouteValidator().run(_referenceV2());

    final permitSafe = report.routes
        .expand((route) => route.steps)
        .firstWhere(
          (step) =>
              step.nodeId == 'permit_decision' && step.optionId == 'p1',
        );

    expect(permitSafe.stateBefore['permit_verified'], isFalse);
    expect(permitSafe.stateAfter['permit_verified'], isTrue);
    expect(permitSafe.stateAfter['isolated'], isTrue);
    expect(permitSafe.evidenceBefore, isEmpty);
    expect(
      permitSafe.evidenceAfter,
      containsAll(<String>{'permit', 'isolation_record'}),
    );
    expect(permitSafe.simulatedMinutesBefore, 0);
    expect(permitSafe.simulatedMinutesAfter, 3);
    expect(permitSafe.deterministicKey, contains('permit_verified'));
    expect(permitSafe.deterministicKey, contains('isolation_record'));
    expect(permitSafe.deterministicKey, contains('"minutesAfter":3'));
  });

  test('L4L captures exact state delta and winning gate type', () {
    final report = const LabExhaustiveRouteValidator().run(_referenceV2());
    final critical = report.routes
        .expand((route) => route.steps)
        .firstWhere(
          (step) =>
              step.nodeId == 'simops_decision' && step.optionId == 's4',
        );

    expect(critical.gateType, LabGateType.criticalEvent);
    expect(critical.stateDelta.keys, containsAll(<String>{'route', 'risk'}));
    expect(critical.stateDelta['route']!.before, isNot('critical'));
    expect(critical.stateDelta['route']!.after, 'critical');
    expect(critical.stateDelta['risk']!.after, 10);
    expect(critical.deterministicKey, contains('"gateType":"criticalEvent"'));
    expect(critical.deterministicKey, contains('"delta"'));
  });

  test('L4L consequence traces never lose unlocked evidence or move time backwards', () {
    final report = const LabExhaustiveRouteValidator().run(_referenceV2());

    expect(
      report.routes.every(
        (route) => route.steps.every(
          (step) =>
              step.evidenceAfter.containsAll(step.evidenceBefore) &&
              step.simulatedMinutesAfter >= step.simulatedMinutesBefore,
        ),
      ),
      isTrue,
    );
  });

  test('L4L formally covers every authored consequence and Story Gate', () {
    final package = _referenceV2();
    final report = const LabExhaustiveRouteValidator().run(package);

    expect(report.completeConsequenceCoverage, isTrue);
    expect(report.completeGateCoverage, isTrue);
    expect(report.routeInvariantsHold, isTrue);
    expect(report.uncoveredConsequenceIds, isEmpty);
    expect(report.uncoveredGateIds, isEmpty);
    expect(report.consequenceCoverageIds, hasLength(20));
    expect(report.gateCoverageIds, hasLength(14));
    expect(report.gateCoverageIds, hasLength(package.gates.length));
    expect(
      report.gateTypeCoverage,
      containsAll(<LabGateType>{
        LabGateType.route,
        LabGateType.criticalEvent,
        LabGateType.convergence,
        LabGateType.completion,
      }),
    );
  });

  test('L4L proves convergence preserves accumulated state and evidence', () {
    final report = const LabExhaustiveRouteValidator().run(_referenceV2());
    final route = report.routes.firstWhere(
      (candidate) =>
          candidate.steps.any(
            (step) =>
                step.nodeId == 'permit_decision' && step.optionId == 'p1',
          ) &&
          candidate.steps.any(
            (step) => step.nodeId == 'gas_decision' && step.optionId == 'g1',
          ) &&
          candidate.steps.any(
            (step) =>
                step.nodeId == 'simops_decision' && step.optionId == 's1',
          ),
    );
    final gasIndex = route.steps.indexWhere(
      (step) => step.nodeId == 'gas_decision' && step.optionId == 'g1',
    );
    final gas = route.steps[gasIndex];
    final simops = route.steps[gasIndex + 1];

    expect(gas.gateType, LabGateType.convergence);
    expect(gas.gateId, 'gas_work_convergence');
    expect(gas.targetNodeId, 'simops_decision');
    expect(gas.evidenceAfter, containsAll(<String>{
      'permit',
      'isolation_record',
      'gas_test',
    }));
    expect(simops.stateBefore, gas.stateAfter);
    expect(simops.evidenceBefore, gas.evidenceAfter);
    expect(simops.simulatedMinutesBefore, gas.simulatedMinutesAfter);
  });

  test('L4L proves critical chain can terminate at critical failure', () {
    final report = const LabExhaustiveRouteValidator().run(_referenceV2());
    final route = report.routes.firstWhere(
      (candidate) =>
          candidate.endingId == 'critical_failure' &&
          candidate.steps.any(
            (step) =>
                step.nodeId == 'permit_decision' && step.optionId == 'p4',
          ) &&
          candidate.steps.any(
            (step) =>
                step.nodeId == 'emergency_decision' && step.optionId == 'e4',
          ),
    );

    expect(route.steps, hasLength(2));
    expect(route.steps.first.gateType, LabGateType.criticalEvent);
    expect(route.steps.first.gatePriority, 100);
    expect(route.steps.first.targetNodeId, 'emergency_decision');
    expect(route.steps.last.gateType, LabGateType.completion);
    expect(route.steps.last.gateId, 'emergency_critical_failure');
    expect(route.steps.last.endingId, 'critical_failure');
  });

  test('L4L proves recovery and incident-contained authored endings', () {
    final report = const LabExhaustiveRouteValidator().run(_referenceV2());

    expect(
      report.routes.any(
        (route) =>
            route.endingId == 'controlled_recovery' &&
            route.steps.any(
              (step) =>
                  step.nodeId == 'simops_decision' && step.optionId == 's2',
            ),
      ),
      isTrue,
    );
    expect(
      report.routes.any(
        (route) =>
            route.endingId == 'incident_contained' &&
            route.steps.any(
              (step) =>
                  step.nodeId == 'simops_decision' && step.optionId == 's3',
            ),
      ),
      isTrue,
    );
    expect(
      report.routes.any(
        (route) =>
            route.steps.any(
              (step) =>
                  step.nodeId == 'emergency_decision' &&
                  step.optionId == 'e1' &&
                  step.gateType == LabGateType.convergence,
            ) &&
            route.steps.any(
              (step) => step.nodeId == 'closeout_decision',
            ),
      ),
      isTrue,
    );
  });

  test('L4L fails closed when an authored gate can never win', () {
    final decoded = jsonDecode(
      File(
        'content/lab_reference_confined_space_h2s_v2.json',
      ).readAsStringSync(),
    ) as Map;
    final root = decoded.cast<String, Object?>();
    final gates = (root['gates'] as List).cast<Map<String, Object?>>();
    gates.add(<String, Object?>{
      'id': 'never_reachable_gate',
      'type': 'ROUTE',
      'priority': 50,
      'fromNodeId': 'gas_decision',
      'targetNodeId': 'simops_decision',
      'condition': <String, Object?>{
        'op': 'NUMERIC',
        'stateId': 'risk',
        'operator': 'GT',
        'value': 99,
      },
    });

    final report = const LabExhaustiveRouteValidator().run(
      LabPackage.fromJson(root),
    );

    expect(report.completeGateCoverage, isFalse);
    expect(report.uncoveredGateIds, contains('never_reachable_gate'));
    expect(report.isValid, isFalse);
  });

  test('L4L fails closed on a reachable repeated-state route cycle', () {
    final decoded = jsonDecode(
      File('test/fixtures/lab/l2_valid_lab.json').readAsStringSync(),
    ) as Map;
    final root = decoded.cast<String, Object?>();
    final consequences =
        (root['consequences'] as List).cast<Map<String, Object?>>();
    for (final consequence in consequences) {
      consequence['simulatedMinutes'] = 0;
    }
    final gates = (root['gates'] as List).cast<Map<String, Object?>>();
    for (final gate in gates) {
      if (gate['fromNodeId'] == 'decision_one') {
        gate['targetNodeId'] = 'decision_one';
      }
    }

    final report = const LabExhaustiveRouteValidator().run(
      LabPackage.fromJson(root),
      maxRoutes: 500,
      maxDepth: 12,
    );

    expect(report.isValid, isFalse);
    expect(
      report.issues.any(
        (issue) => issue.contains('Reachable route cycle repeated state'),
      ),
      isTrue,
    );
  });

  test('L4L route continuity invariants hold on every exhaustive trace', () {
    final report = const LabExhaustiveRouteValidator().run(_referenceV2());

    expect(report.routeInvariantsHold, isTrue);
    for (final route in report.routes) {
      expect(route.steps.last.endingId, route.endingId);
      expect(route.steps.last.gateType, LabGateType.completion);
      for (var index = 0; index < route.steps.length - 1; index++) {
        final current = route.steps[index];
        final next = route.steps[index + 1];
        expect(current.targetNodeId, next.nodeId);
        expect(current.stateAfter, next.stateBefore);
        expect(current.evidenceAfter, next.evidenceBefore);
        expect(
          current.simulatedMinutesAfter,
          next.simulatedMinutesBefore,
        );
      }
    }
  });

  test('L4L supports valid inline authored consequences', () {
    final decoded = jsonDecode(
      File('test/fixtures/lab/l2_valid_lab.json').readAsStringSync(),
    ) as Map;
    final root = decoded.cast<String, Object?>();
    final consequences = root['consequences'] as List;
    final nodes = root['nodes'] as List;
    final firstNode = (nodes.first as Map).cast<String, Object?>();
    final options = firstNode['options'] as List;
    final firstOption = (options.first as Map).cast<String, Object?>();
    final consequenceId = firstOption['consequenceId'];
    final consequenceIndex = consequences.indexWhere(
      (item) => (item as Map)['id'] == consequenceId,
    );
    final inline = consequences.removeAt(consequenceIndex);
    firstOption.remove('consequenceId');
    firstOption['consequence'] = inline;

    final report = const LabExhaustiveRouteValidator().run(
      LabPackage.fromJson(root),
    );

    expect(report.isValid, isTrue);
    expect(report.completeConsequenceCoverage, isTrue);
    expect(report.consequenceCoverageIds, contains('c_safe'));
    expect(report.routeInvariantsHold, isTrue);
  });

  test('L4L depth guard fails closed on a state-changing route cycle', () {
    final decoded = jsonDecode(
      File('test/fixtures/lab/l2_valid_lab.json').readAsStringSync(),
    ) as Map;
    final root = decoded.cast<String, Object?>();
    final rawGates = root['gates'] as List;
    for (final rawGate in rawGates) {
      final gate = (rawGate as Map).cast<String, Object?>();
      if (gate['fromNodeId'] == 'decision_one') {
        gate['targetNodeId'] = 'decision_one';
      }
    }

    final report = const LabExhaustiveRouteValidator().run(
      LabPackage.fromJson(root),
      maxRoutes: 500,
      maxDepth: 2,
    );

    expect(report.isValid, isFalse);
    expect(report.limitExceeded, isFalse);
    expect(
      report.issues.any(
        (issue) => issue.contains('Route exceeded exhaustive depth guard'),
      ),
      isTrue,
    );
  });

  test('L4L closure evidence summary is deterministic and complete', () {
    const validator = LabExhaustiveRouteValidator();
    final package = _referenceV2();
    final first = validator.run(package);
    final second = validator.run(package);

    final firstEvidence = jsonEncode(first.toEvidenceJson());
    final secondEvidence = jsonEncode(second.toEvidenceJson());

    expect(firstEvidence, secondEvidence);
    expect(
      first.toEvidenceJson()['schemaVersion'],
      'csp11.lab.l4l.exhaustive.v1',
    );
    expect(first.toEvidenceJson()['routeCount'], 196);
    expect(first.toEvidenceJson()['routeCount'], first.routes.length);
    expect(
      first.toEvidenceJson()['gateWinCountByType'],
      <String, int>{
        'completion': 196,
        'convergence': 300,
        'criticalEvent': 169,
        'route': 183,
      },
    );
    expect(
      first.toEvidenceJson()['routeCountByEnding'],
      <String, int>{
        'controlled_recovery': 48,
        'critical_failure': 13,
        'incident_contained': 48,
        'major_incident': 39,
        'safe_completion': 48,
      },
    );
    expect(first.toEvidenceJson()['uncoveredOptionKeys'], isEmpty);
    expect(first.toEvidenceJson()['uncoveredConsequenceIds'], isEmpty);
    expect(first.toEvidenceJson()['uncoveredGateIds'], isEmpty);
    expect(first.toEvidenceJson()['uncoveredEndingIds'], isEmpty);
    expect(first.toEvidenceJson()['routeInvariantsHold'], isTrue);
    expect(first.toEvidenceJson()['isValid'], isTrue);
    expect(first.toEvidenceJson()['fingerprint'], first.fingerprint);
  });

  test('L4L rejects completion at an unauthored ending', () {
    final decoded = jsonDecode(
      File(
        'content/lab_reference_confined_space_h2s_v2.json',
      ).readAsStringSync(),
    ) as Map;
    final root = decoded.cast<String, Object?>();
    final rawGates = root['gates'] as List;
    final gate = rawGates
        .map((item) => (item as Map).cast<String, Object?>())
        .firstWhere((item) => item['id'] == 'simops_safe_completion');
    gate['endingId'] = 'ghost_ending';

    final report = const LabExhaustiveRouteValidator().run(
      LabPackage.fromJson(root),
    );

    expect(report.routeInvariantsHold, isFalse);
    expect(report.endingIds, contains('ghost_ending'));
    expect(report.isValid, isFalse);
  });

  test('L4L fingerprint is stable across repeated exhaustive runs', () {
    const validator = LabExhaustiveRouteValidator();
    final package = _referenceV2();

    final first = validator.run(package);
    final second = validator.run(package);

    expect(first.fingerprint, second.fingerprint);
    expect(first.routes.length, second.routes.length);
    expect(first.optionCoverageKeys, second.optionCoverageKeys);
    expect(first.endingIds, second.endingIds);
  });
}
