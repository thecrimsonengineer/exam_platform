import 'dart:io';

import 'package:exam_platform/features/lab/lab_contracts.dart';
import 'package:exam_platform/features/lab/lab_learning_twin_bridge.dart';
import 'package:exam_platform/features/lab/lab_session.dart';
import 'package:flutter_test/flutter_test.dart';

import 'lab_l3_test_fixtures.dart';

void main() {
  const bridge = LabLearningTwinEvidenceBridge();

  for (var i = 0; i < 10; i++) {
    test('LAB-7 sanitized Decision Event ' + (i + 1).toString(), () async {
      final package = l3ReferenceDraftPackage();
      final session = await runL3Route(
        package: package,
        optionIds: const <String>['p3'],
        sessionId: 'sanitized_$i',
        responseTimeBaseMs: 400 + i,
        confidence: 0.8,
      );
      final evidence = bridge.buildEvidence(package: package, session: session);
      final json = evidence.single.toSanitizedJson();
      expect(json['nodeId'], 'permit_decision');
      expect(json['optionId'], 'p3');
      expect(json['responseTimeMs'], 400 + i);
      expect(json.containsKey('userId'), isFalse);
      expect(json.containsKey('stateBefore'), isFalse);
      expect(json.containsKey('stateAfter'), isFalse);
      expect(json.containsKey('stateDelta'), isFalse);
    });
  }

  for (var i = 0; i < 10; i++) {
    test('LAB-7 competency and Mistake DNA evidence ' + (i + 1).toString(), () async {
      final package = l3ReferenceDraftPackage();
      final session = await runL3Route(
        package: package,
        optionIds: const <String>['p3'],
        sessionId: 'mistake_$i',
      );
      final item = bridge.buildEvidence(package: package, session: session).single;
      expect(item.competencyEvidence, contains('d07_c01'));
      expect(item.competencyEvidence, contains('simops_reasoning'));
      expect(item.mistakeDnaTags, contains('simops_pressure'));
      expect(item.mistakeDnaTags, contains('work_before_verification'));
      expect(item.quality, LabDecisionQuality.weak);
    });
  }

  for (var i = 0; i < 10; i++) {
    test('LAB-7 confidence and response latency ' + (i + 1).toString(), () async {
      final confidence = (i + 1) / 10;
      final package = l3ReferenceDraftPackage();
      final session = await runL3Route(
        package: package,
        optionIds: const <String>['p1'],
        sessionId: 'confidence_$i',
        responseTimeBaseMs: 700 + i,
        confidence: confidence,
      );
      final item = bridge.buildEvidence(package: package, session: session).single;
      expect(item.confidence, confidence);
      expect(item.responseTimeMs, 700 + i);
      expect(item.occurredAt, session.decisionHistory.single.timestamp);
    });
  }

  for (var i = 0; i < 10; i++) {
    test('LAB-7 recovery evidence ' + (i + 1).toString(), () async {
      final package = l3ReferenceDraftPackage();
      final session = await runL3Route(
        package: package,
        optionIds: const <String>['p4', 'e1'],
        sessionId: 'recovery_evidence_$i',
      );
      final evidence = bridge.buildEvidence(package: package, session: session);
      expect(evidence, hasLength(2));
      expect(evidence.first.recoveryEvidence, isFalse);
      expect(evidence.last.nodeId, 'emergency_decision');
      expect(evidence.last.recoveryEvidence, isTrue);
      expect(evidence.last.competencyEvidence, contains('recovery_ability'));
    });
  }

  for (var i = 0; i < 10; i++) {
    test('LAB-7 failed and partial session rules ' + (i + 1).toString(), () async {
      final package = l3ReferenceDraftPackage();
      final session = i < 5
          ? await runL3Route(
              package: package,
              optionIds: const <String>['p3'],
              sessionId: 'partial_$i',
            )
          : await runL3WeakRoute(package, sessionId: 'complete_$i');
      final evidence = bridge.buildEvidence(package: package, session: session);
      expect(evidence, isNotEmpty);
      if (i < 5) {
        expect(session.status, LabSessionStatus.active);
        expect(
          evidence.every(
            (item) => item.completion == LabEvidenceCompletion.partial,
          ),
          isTrue,
        );
      } else {
        expect(session.status, LabSessionStatus.completed);
        expect(
          evidence.every(
            (item) => item.completion == LabEvidenceCompletion.completed,
          ),
          isTrue,
        );
      }
    });
  }

  for (var i = 0; i < 10; i++) {
    test('LAB-7 privacy and Story Engine isolation ' + (i + 1).toString(), () async {
      final package = l3ReferenceDraftPackage();
      final session = await runL3Route(
        package: package,
        optionIds: const <String>['p3'],
        sessionId: 'isolation_$i',
      );
      final beforeNode = session.currentNodeId;
      final beforeState = Map<String, Object?>.from(session.stateValues);
      final sink = InMemoryLabLearningEvidenceSink();
      await bridge.emit(package: package, session: session, sink: sink);
      await bridge.emit(package: package, session: session, sink: sink);
      expect(sink.events, hasLength(1));
      expect(session.currentNodeId, beforeNode);
      expect(session.stateValues, beforeState);
      expect(sink.events.single.toSanitizedJson().containsKey('userId'), isFalse);
      final runtimeSource = File(
        'lib/features/lab/lab_runtime.dart',
      ).readAsStringSync();
      expect(runtimeSource, isNot(contains('learning_twin')));
      expect(runtimeSource, isNot(contains('LabLearningTwinEvidenceBridge')));
    });
  }
}
