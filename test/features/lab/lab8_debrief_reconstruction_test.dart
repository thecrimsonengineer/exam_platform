import 'package:exam_platform/features/lab/lab_debrief.dart';
import 'package:exam_platform/features/lab/lab_session.dart';
import 'package:flutter_test/flutter_test.dart';

import 'lab_l3_test_fixtures.dart';

void main() {
  const engine = LabDebriefEngine();

  for (var i = 0; i < 10; i++) {
    test(
      'LAB-8 chronological timeline ordering ' + (i + 1).toString(),
      () async {
        final package = l3ReferenceDraftPackage();
        final session = await runL3WeakRoute(package, sessionId: 'timeline_$i');
        final debrief = engine.reconstruct(package: package, session: session);
        expect(debrief.decisions, hasLength(3));
        expect(debrief.decisions.map((item) => item.index).toList(), <int>[
          0,
          1,
          2,
        ]);
        expect(debrief.decisions.map((item) => item.nodeId).toList(), <String>[
          'permit_decision',
          'gas_decision',
          'closeout_decision',
        ]);
        expect(
          debrief.decisions[0].timestamp.isBefore(
            debrief.decisions[1].timestamp,
          ),
          isTrue,
        );
        expect(
          debrief.decisions[1].timestamp.isBefore(
            debrief.decisions[2].timestamp,
          ),
          isTrue,
        );
      },
    );
  }

  for (var i = 0; i < 10; i++) {
    test(
      'LAB-8 consequence gate and causal reconstruction ' + (i + 1).toString(),
      () async {
        final package = l3ReferenceDraftPackage();
        final session = await runL3SafeRoute(package, sessionId: 'causal_$i');
        final debrief = engine.reconstruct(package: package, session: session);
        expect(debrief.decisions.first.consequenceId, 'permit_safe');
        expect(debrief.decisions.first.gateId, 'permit_route');
        expect(debrief.decisions[1].consequenceId, 'gas_safe');
        expect(debrief.decisions[1].gateId, 'gas_convergence');
        expect(debrief.decisions.last.gateId, 'ending_safe');
        expect(
          debrief.causalChain.first,
          'permit_decision -> p1 -> permit_safe -> permit_route',
        );
        expect(debrief.endingId, 'safe_completion');
      },
    );
  }

  for (var i = 0; i < 10; i++) {
    test(
      'LAB-8 critical and recovery identification ' + (i + 1).toString(),
      () async {
        final package = l3ReferenceDraftPackage();
        final session = await runL3RecoveryRoute(
          package,
          sessionId: 'identify_$i',
        );
        final debrief = engine.reconstruct(package: package, session: session);
        expect(debrief.criticalDecisionIndexes, <int>[0]);
        expect(debrief.recoveryDecisionIndexes, <int>[1, 2]);
        expect(debrief.decisions.first.critical, isTrue);
        expect(debrief.decisions[1].recovery, isTrue);
        expect(debrief.decisions[2].recovery, isTrue);
        expect(debrief.competencyEvidence, contains('recovery_ability'));
        expect(debrief.mistakeDnaSignals, contains('permit_bypass'));
      },
    );
  }

  for (var i = 0; i < 10; i++) {
    test('LAB-8 alternate authored timeline ' + (i + 1).toString(), () async {
      final package = l3ReferenceDraftPackage();
      final session = await runL3WeakRoute(package, sessionId: 'alternate_$i');
      final debrief = engine.reconstruct(package: package, session: session);
      expect(debrief.alternateTimelines, hasLength(3));
      final permit = debrief.alternateTimelines.firstWhere(
        (item) => item.nodeId == 'permit_decision',
      );
      final gas = debrief.alternateTimelines.firstWhere(
        (item) => item.nodeId == 'gas_decision',
      );
      final closeout = debrief.alternateTimelines.firstWhere(
        (item) => item.nodeId == 'closeout_decision',
      );
      expect(permit.originalOptionId, 'p3');
      expect(permit.alternateOptionId, 'p1');
      expect(permit.gateId, 'permit_route');
      expect(gas.originalOptionId, 'g3');
      expect(gas.alternateOptionId, 'g1');
      expect(gas.gateId, 'gas_convergence');
      expect(closeout.originalOptionId, 'c3');
      expect(closeout.alternateOptionId, 'c1');
      expect(closeout.endingId, 'safe_completion');
    });
  }

  for (var i = 0; i < 10; i++) {
    test(
      'LAB-8 incomplete deterministic reconstruction ' + (i + 1).toString(),
      () async {
        final package = l3ReferenceDraftPackage();
        final session = await runL3Route(
          package: package,
          optionIds: const <String>['p3'],
          sessionId: 'incomplete_$i',
        );
        final first = engine.reconstruct(package: package, session: session);
        final second = engine.reconstruct(package: package, session: session);
        expect(session.status, LabSessionStatus.active);
        expect(first.completed, isFalse);
        expect(first.endingId, isNull);
        expect(first.decisions, hasLength(1));
        expect(first.causalChain, second.causalChain);
        expect(
          first.alternateTimelines.length,
          second.alternateTimelines.length,
        );
        expect(first.sources, package.metadata.sources);
      },
    );
  }
}
