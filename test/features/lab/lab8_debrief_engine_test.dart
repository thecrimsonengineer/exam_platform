import 'package:exam_platform/features/lab/lab_debrief.dart';
import 'package:exam_platform/features/lab/lab_session.dart';
import 'package:flutter_test/flutter_test.dart';

import 'lab_l3_test_fixtures.dart';

void main() {
  const engine = LabDebriefEngine();

  for (var i = 0; i < 10; i++) {
    test(
      'LAB-8 chronological decision timeline ' + (i + 1).toString(),
      () async {
        final run = await safeReferenceRun(
          sessionId: 'timeline_' + i.toString(),
        );
        final debrief = engine.reconstruct(
          package: run.package,
          session: run.session,
        );

        expect(debrief.decisions, hasLength(3));
        expect(debrief.decisions[0].nodeId, 'permit_decision');
        expect(debrief.decisions[1].nodeId, 'gas_decision');
        expect(debrief.decisions[2].nodeId, 'closeout_decision');
        expect(
          debrief.decisions[0].timestamp.isBefore(
            debrief.decisions[1].timestamp,
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
        final run = await criticalReferenceRun(
          sessionId: 'causal_' + i.toString(),
        );
        final debrief = engine.reconstruct(
          package: run.package,
          session: run.session,
        );

        expect(debrief.causalChain, hasLength(2));
        expect(debrief.causalChain.first, contains('permit_critical'));
        expect(debrief.causalChain.first, contains('permit_critical_event'));
        expect(debrief.causalChain.last, contains('emergency_fatal'));
        expect(
          debrief.causalChain.last,
          contains('emergency_critical_failure'),
        );
      },
    );
  }

  for (var i = 0; i < 10; i++) {
    test(
      'LAB-8 critical recovery and evidence reconstruction ' +
          (i + 1).toString(),
      () async {
        final run = await recoveryReferenceRun(
          sessionId: 'reconstruct_' + i.toString(),
        );
        final debrief = engine.reconstruct(
          package: run.package,
          session: run.session,
        );

        expect(debrief.criticalDecisionIndexes, contains(0));
        expect(debrief.recoveryDecisionIndexes, containsAll(<int>[1, 2]));
        expect(debrief.competencyEvidence, contains('emergency_response'));
        expect(debrief.mistakeDnaSignals, contains('permit_bypass'));
        expect(debrief.sources, isNotEmpty);
      },
    );
  }

  for (var i = 0; i < 10; i++) {
    test(
      'LAB-8 authored alternate timeline determinism ' + (i + 1).toString(),
      () async {
        final run = await weakReferenceRun(
          sessionId: 'alternate_' + i.toString(),
        );
        final first = engine.reconstruct(
          package: run.package,
          session: run.session,
        );
        final second = engine.reconstruct(
          package: run.package,
          session: run.session,
        );

        expect(first.alternateTimelines, hasLength(3));
        expect(
          first.alternateTimelines.map((item) => item.gateId).toList(),
          second.alternateTimelines.map((item) => item.gateId).toList(),
        );
        expect(first.alternateTimelines.first.alternateOptionId, 'p1');
        expect(first.alternateTimelines.first.gateId, 'permit_route');
      },
    );
  }

  for (var i = 0; i < 10; i++) {
    test(
      'LAB-8 incomplete session source backed behaviour ' + (i + 1).toString(),
      () async {
        final run = await runReferencePath(const <String>[
          'p2',
        ], sessionId: 'incomplete_' + i.toString());
        final debrief = engine.reconstruct(
          package: run.package,
          session: run.session,
        );

        expect(run.session.status, LabSessionStatus.active);
        expect(debrief.completed, isFalse);
        expect(debrief.endingId, isNull);
        expect(debrief.decisions, hasLength(1));
        expect(debrief.decisions.single.sources, isNotEmpty);
        expect(debrief.alternateTimelines, hasLength(1));
      },
    );
  }
}
