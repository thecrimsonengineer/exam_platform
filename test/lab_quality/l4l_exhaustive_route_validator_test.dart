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
    expect(report.routes.length, greaterThan(100));
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
