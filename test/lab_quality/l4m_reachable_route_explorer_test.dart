import 'dart:convert';
import 'dart:io';

import 'package:exam_platform/features/lab/lab_contracts.dart';
import 'package:exam_platform/features/lab/lab_reachable_route_explorer.dart';
import 'package:flutter_test/flutter_test.dart';

LabPackage _referenceV2() => LabPackage.decode(
  File('content/lab_reference_confined_space_h2s_v2.json').readAsStringSync(),
);

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

  test('L4M fails closed when representative budget loses mandatory coverage', () {
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
  });

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

  test('L4M evidence exposes exhaustive proof and selected coverage separately', () {
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
    expect(
      (evidence['selectedRouteFingerprints'] as List),
      hasLength(32),
    );
  });

  test('L4M validates budget and hard-guard configuration', () {
    final package = _referenceV2();
    const explorer = LabReachableRouteExplorer();

    expect(
      () => explorer.explore(package, routeBudget: 0),
      throwsA(isA<LabContractException>()),
    );
    expect(
      () => explorer.explore(
        package,
        routeBudget: 100,
        hardRouteLimit: 50,
      ),
      throwsA(isA<LabContractException>()),
    );
  });
}
