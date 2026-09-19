import 'dart:convert';
import 'dart:io';

import 'package:exam_platform/features/lab/lab_contracts.dart';
import 'package:exam_platform/features/lab/lab_reachable_route_explorer.dart';
import 'package:flutter_test/flutter_test.dart';

LabPackage _referenceV2() => LabPackage.decode(
  File('content/lab_reference_confined_space_h2s_v2.json').readAsStringSync(),
);

LabPackage _largeRoutePackage() {
  final nodes = <LabNodeContract>[];
  final gates = <Map<String, Object?>>[];

  for (var decisionIndex = 1; decisionIndex <= 5; decisionIndex++) {
    final nodeId = 'decision_' + decisionIndex.toString();
    nodes.add(
      LabDecisionNode(
        id: nodeId,
        prompt:
            'Choose an authored action for decision ' +
            decisionIndex.toString() +
            '.',
        options: List<LabDecisionOption>.generate(4, (optionIndex) {
          final number = optionIndex + 1;
          return LabDecisionOption(
            id: 'o' + number.toString(),
            text: 'Authored action ' + number.toString(),
            isBest: number == 1,
            quality: switch (number) {
              1 => LabDecisionQuality.optimal,
              2 => LabDecisionQuality.defensible,
              3 => LabDecisionQuality.weak,
              _ => LabDecisionQuality.critical,
            },
            consequence: LabConsequence(
              id:
                  'd' +
                  decisionIndex.toString() +
                  '_o' +
                  number.toString() +
                  '_consequence',
              explicitNoOp: true,
            ),
          );
        }),
      ),
    );

    if (decisionIndex < 5) {
      gates.add(<String, Object?>{
        'id': 'route_' + decisionIndex.toString(),
        'type': 'ROUTE',
        'priority': 10,
        'fromNodeId': nodeId,
        'targetNodeId': 'decision_' + (decisionIndex + 1).toString(),
        'condition': <String, Object?>{'op': 'ALWAYS'},
      });
    } else {
      gates.add(<String, Object?>{
        'id': 'complete',
        'type': 'COMPLETION',
        'priority': 10,
        'fromNodeId': nodeId,
        'endingId': 'complete_ending',
        'condition': <String, Object?>{'op': 'ALWAYS'},
      });
    }
  }

  return LabPackage(
    schemaVersion: kLabSchemaVersion,
    metadata: LabMetadata(
      id: 'l4m_scale_lab',
      versionId: 'v1',
      title: 'L4M scale LAB',
      description: 'Five four-option decisions create 1,024 complete routes.',
      lifecycle: LabLifecycleStatus.draft,
      supportedModes: const <LabMode>{LabMode.professional},
      startingNodeId: 'decision_1',
      startingState: const <String, Object?>{},
    ),
    stateRegistry: LabStateRegistry(const <LabStateVariableDefinition>[]),
    nodes: nodes,
    gates: gates,
    endings: const <Map<String, Object?>>[
      <String, Object?>{
        'id': 'complete_ending',
        'family': 'SAFE_COMPLETION',
        'title': 'Complete',
      },
    ],
  );
}

void main() {
  test('L4M uses exhaustive mode when reachable routes fit the budget', () {
    final report = const LabReachableRouteExplorer().explore(_referenceV2());

    expect(report.mode, LabReachableRouteExplorationMode.exhaustive);
    expect(report.isExhaustive, isTrue);
    expect(report.isRepresentative, isFalse);
    expect(report.isBlocked, isFalse);
    expect(report.discoveredRouteCount, 196);
    expect(report.selectedRouteCount, 196);
    expect(report.completeMandatoryCoverage, isTrue);
    expect(report.deterministic, isTrue);
    expect(report.issues, isEmpty);
    expect(report.isValid, isTrue);
    expect(
      report.selectedOptionCoverageKeys,
      report.exhaustiveReport.optionCoverageKeys,
    );
    expect(
      report.selectedConsequenceCoverageIds,
      report.exhaustiveReport.consequenceCoverageIds,
    );
    expect(
      report.selectedGateCoverageIds,
      report.exhaustiveReport.gateCoverageIds,
    );
    expect(report.selectedEndingIds, report.exhaustiveReport.endingIds);
  });

  test('L4M default budget becomes representative above 1,000 routes', () {
    final report = const LabReachableRouteExplorer().explore(
      _largeRoutePackage(),
    );

    expect(report.mode, LabReachableRouteExplorationMode.representative);
    expect(report.discoveredRouteCount, 1024);
    expect(report.selectedRouteCount, 1000);
    expect(report.routeBudget, 1000);
    expect(report.completeMandatoryCoverage, isTrue);
    expect(report.selectedOptionCoverageKeys, hasLength(20));
    expect(report.selectedConsequenceCoverageIds, hasLength(20));
    expect(report.selectedGateCoverageIds, hasLength(5));
    expect(report.selectedEndingIds, <String>{'complete_ending'});
    expect(report.deterministic, isTrue);
    expect(report.isValid, isTrue);
  });

  test('L4M deterministically selects representative complete routes', () {
    final report = const LabReachableRouteExplorer().explore(
      _referenceV2(),
      routeBudget: 32,
      hardRouteLimit: 10000,
    );

    expect(report.mode, LabReachableRouteExplorationMode.representative);
    expect(report.isRepresentative, isTrue);
    expect(report.discoveredRouteCount, 196);
    expect(report.selectedRouteCount, 32);
    expect(report.selectedRouteCount, lessThan(report.discoveredRouteCount));
    expect(report.completeMandatoryCoverage, isTrue);
    expect(report.deterministic, isTrue);
    expect(report.issues, isEmpty);
    expect(report.isValid, isTrue);
    expect(report.selectedOptionCoverageKeys, hasLength(20));
    expect(report.selectedConsequenceCoverageIds, hasLength(20));
    expect(report.selectedGateCoverageIds, hasLength(14));
    expect(report.selectedEndingIds, hasLength(5));
    expect(
      report.selectedGateTypeCoverage,
      containsAll(<LabGateType>{
        LabGateType.route,
        LabGateType.criticalEvent,
        LabGateType.convergence,
        LabGateType.completion,
      }),
    );
  });

  test('L4M reuses a precomputed L4L proof without changing selection', () {
    const explorer = LabReachableRouteExplorer();
    final package = _referenceV2();
    final direct = explorer.explore(package, routeBudget: 32);
    final reused = explorer.exploreFromExhaustive(
      direct.exhaustiveReport,
      routeBudget: 32,
      hardRouteLimit: 10000,
    );

    expect(reused.mode, direct.mode);
    expect(reused.selectedRouteCount, direct.selectedRouteCount);
    expect(reused.fingerprint, direct.fingerprint);
    expect(reused.selectedOptionCoverageKeys, direct.selectedOptionCoverageKeys);
    expect(
      reused.selectedConsequenceCoverageIds,
      direct.selectedConsequenceCoverageIds,
    );
    expect(reused.selectedGateCoverageIds, direct.selectedGateCoverageIds);
    expect(reused.selectedEndingIds, direct.selectedEndingIds);
    expect(reused.isValid, isTrue);
  });

  test('L4M representative routes are all complete authored traces', () {
    final report = const LabReachableRouteExplorer().explore(
      _referenceV2(),
      routeBudget: 32,
    );

    expect(
      report.selectedRoutes.every(
        (route) =>
            route.steps.isNotEmpty &&
            route.steps.last.gateType == LabGateType.completion &&
            route.steps.last.endingId == route.endingId,
      ),
      isTrue,
    );
  });

  test('L4M representative selection is byte-stable across repeated runs', () {
    const explorer = LabReachableRouteExplorer();
    final package = _referenceV2();

    final first = explorer.explore(package, routeBudget: 32);
    final second = explorer.explore(package, routeBudget: 32);

    expect(first.fingerprint, second.fingerprint);
    expect(first.selectedRouteCount, second.selectedRouteCount);
    expect(
      first.selectedRoutes.map((route) => route.fingerprint).toList(),
      second.selectedRoutes.map((route) => route.fingerprint).toList(),
    );
    expect(
      jsonEncode(first.toEvidenceJson()),
      jsonEncode(second.toEvidenceJson()),
    );
  });

  test(
    'L4M fails closed when representative budget loses mandatory coverage',
    () {
      final report = const LabReachableRouteExplorer().explore(
        _referenceV2(),
        routeBudget: 2,
        hardRouteLimit: 10000,
      );

      expect(report.mode, LabReachableRouteExplorationMode.representative);
      expect(report.selectedRouteCount, 2);
      expect(report.completeMandatoryCoverage, isFalse);
      expect(report.isValid, isFalse);
      expect(
        report.issues,
        contains(
          'L4M representative route budget cannot preserve all mandatory reachable coverage.',
        ),
      );
    },
  );

  test('L4M blocks when exact route discovery exceeds its hard guard', () {
    final report = const LabReachableRouteExplorer().explore(
      _referenceV2(),
      routeBudget: 32,
      hardRouteLimit: 50,
    );

    expect(report.mode, LabReachableRouteExplorationMode.blocked);
    expect(report.isBlocked, isTrue);
    expect(report.exhaustiveReport.limitExceeded, isTrue);
    expect(report.selectedRoutes, isEmpty);
    expect(report.completeMandatoryCoverage, isFalse);
    expect(report.isValid, isFalse);
    expect(
      report.issues,
      contains('L4M exact route discovery exceeded the hard route guard.'),
    );
  });

  test(
    'L4M evidence exposes exhaustive proof and selected coverage separately',
    () {
      final report = const LabReachableRouteExplorer().explore(
        _referenceV2(),
        routeBudget: 32,
      );
      final evidence = report.toEvidenceJson();

      expect(evidence['schemaVersion'], 'csp11.lab.l4m.exploration.v1');
      expect(evidence['mode'], 'representative');
      expect(evidence['routeBudget'], 32);
      expect(evidence['hardRouteLimit'], 10000);
      expect(evidence['discoveredRouteCount'], 196);
      expect(evidence['selectedRouteCount'], 32);
      expect(evidence['completeMandatoryCoverage'], isTrue);
      expect(evidence['deterministic'], isTrue);
      expect(evidence['isValid'], isTrue);
      expect(
        evidence['exhaustiveProofFingerprint'],
        report.exhaustiveReport.fingerprint,
      );
      expect(evidence['fingerprint'], report.fingerprint);
      expect((evidence['selectedRouteFingerprints'] as List), hasLength(32));
    },
  );

  test('L4M validates budget and hard-guard configuration', () {
    final package = _referenceV2();
    const explorer = LabReachableRouteExplorer();

    expect(
      () => explorer.explore(package, routeBudget: 0),
      throwsA(isA<LabContractException>()),
    );
    expect(
      () => explorer.explore(package, routeBudget: 100, hardRouteLimit: 50),
      throwsA(isA<LabContractException>()),
    );
  });
}
