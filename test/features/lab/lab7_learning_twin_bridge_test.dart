import 'package:exam_platform/features/lab/lab_learning_twin_bridge.dart';
import 'package:exam_platform/features/lab/lab_session.dart';
import 'package:flutter_test/flutter_test.dart';

import 'lab_l3_test_fixtures.dart';

void main() {
  const bridge = LabLearningTwinEvidenceBridge();

  for (var i = 0; i < 10; i++) {
    test('LAB-7 sanitized Decision Events ' + (i + 1).toString(), () async {
      final run = await runReferencePath(const <String>[
        'p3',
      ], sessionId: 'sanitize_' + i.toString());
      final evidence = bridge.buildEvidence(
        package: run.package,
        session: run.session,
      );
      final json = evidence.single.toSanitizedJson();

      expect(json['eventId'], isNotNull);
      expect(json['labId'], 'confined_space_h2s_simops');
      expect(json.containsKey('userId'), isFalse);
      expect(json.containsKey('stateBefore'), isFalse);
      expect(json.containsKey('stateAfter'), isFalse);
      expect(json.containsKey('stateDelta'), isFalse);
    });
  }

  for (var i = 0; i < 10; i++) {
    test(
      'LAB-7 competency and Mistake DNA evidence ' + (i + 1).toString(),
      () async {
        final run = await runReferencePath(const <String>[
          'p3',
        ], sessionId: 'dna_' + i.toString());
        final item = bridge
            .buildEvidence(package: run.package, session: run.session)
            .single;

        expect(item.competencyEvidence, contains('d07_c01'));
        expect(item.competencyEvidence, contains('simops_reasoning'));
        expect(item.mistakeDnaTags, contains('simops_pressure'));
        expect(item.mistakeDnaTags, contains('work_before_verification'));
      },
    );
  }

  for (var i = 0; i < 10; i++) {
    test(
      'LAB-7 confidence and response latency ' + (i + 1).toString(),
      () async {
        final confidence = (i + 1) / 10;
        final run = await runReferencePath(
          const <String>['p1'],
          sessionId: 'confidence_' + i.toString(),
          confidence: confidence,
        );
        final item = bridge
            .buildEvidence(package: run.package, session: run.session)
            .single;

        expect(item.confidence, confidence);
        expect(item.responseTimeMs, 500);
        expect(item.occurredAt, DateTime.utc(2026, 9, 19, 1, 1));
      },
    );
  }

  for (var i = 0; i < 10; i++) {
    test('LAB-7 recovery evidence ' + (i + 1).toString(), () async {
      final run = await recoveryReferenceRun(
        sessionId: 'recovery_evidence_' + i.toString(),
      );
      final evidence = bridge.buildEvidence(
        package: run.package,
        session: run.session,
      );

      expect(evidence, hasLength(3));
      expect(evidence[0].recoveryEvidence, isFalse);
      expect(evidence[1].recoveryEvidence, isTrue);
      expect(evidence[2].recoveryEvidence, isTrue);
    });
  }

  for (var i = 0; i < 10; i++) {
    test(
      'LAB-7 partial and completed session rules ' + (i + 1).toString(),
      () async {
        if (i.isEven) {
          final run = await runReferencePath(const <String>[
            'p1',
          ], sessionId: 'partial_' + i.toString());
          final evidence = bridge.buildEvidence(
            package: run.package,
            session: run.session,
          );
          expect(run.session.status, LabSessionStatus.active);
          expect(evidence.single.completion, LabEvidenceCompletion.partial);
        } else {
          final run = await safeReferenceRun(
            sessionId: 'complete_' + i.toString(),
          );
          final evidence = bridge.buildEvidence(
            package: run.package,
            session: run.session,
          );
          expect(run.session.status, LabSessionStatus.completed);
          expect(
            evidence.every(
              (item) => item.completion == LabEvidenceCompletion.completed,
            ),
            isTrue,
          );
        }
      },
    );
  }

  for (var i = 0; i < 10; i++) {
    test(
      'LAB-7 Story Engine isolation and privacy boundary ' + (i + 1).toString(),
      () async {
        final run = await runReferencePath(const <String>[
          'p4',
        ], sessionId: 'isolation_' + i.toString());
        final before = run.session.toJson();
        final sink = InMemoryLabLearningEvidenceSink();
        final evidence = await bridge.emit(
          package: run.package,
          session: run.session,
          sink: sink,
        );
        final after = run.session.toJson();

        expect(after, before);
        expect(run.session.currentNodeId, 'emergency_decision');
        expect(evidence.single.optionId, 'p4');
        expect(sink.events, hasLength(1));
      },
    );
  }
}
