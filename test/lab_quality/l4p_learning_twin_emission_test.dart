import 'dart:convert';

import 'package:exam_platform/features/lab/lab_contracts.dart';
import 'package:exam_platform/features/lab/lab_learning_twin_bridge.dart';
import 'package:exam_platform/features/lab/lab_learning_twin_emitter.dart';
import 'package:exam_platform/features/lab/lab_session.dart';
import 'package:exam_platform/screens/lab/lab_reference_player_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/lab/lab_l3_test_fixtures.dart';

class _ThrowingEvidenceSink implements LabLearningEvidenceSink {
  @override
  Future<void> append(LabLearningEvidence evidence) async {
    throw StateError('simulated Learning Twin outage');
  }
}

Future<
  ({
    LabPackage package,
    LabSession start,
    LabSession first,
    LabSession second,
    LabSession completed,
  })
>
_runRecoverySequence() async {
  final package = l3ReferenceDraftPackage();
  final store = InMemoryLabSessionStore();
  final engine = LabSessionEngine(store: store);
  final start = await engine.startAttempt(
    package: package,
    sessionId: 'l4p_recovery',
    userId: 'learner',
    mode: LabMode.professional,
    startedAt: DateTime.utc(2026, 9, 19, 10),
  );
  final first = await engine.commitDecision(
    package: package,
    session: start,
    optionId: 'p4',
    responseTimeMs: 301,
    confidence: 0.9,
    timestamp: DateTime.utc(2026, 9, 19, 10, 1),
  );
  final second = await engine.commitDecision(
    package: package,
    session: first,
    optionId: 'e1',
    responseTimeMs: 302,
    confidence: 0.7,
    timestamp: DateTime.utc(2026, 9, 19, 10, 2),
  );
  final completed = await engine.commitDecision(
    package: package,
    session: second,
    optionId: 'c2',
    responseTimeMs: 303,
    confidence: 0.8,
    timestamp: DateTime.utc(2026, 9, 19, 10, 3),
  );
  return (
    package: package,
    start: start,
    first: first,
    second: second,
    completed: completed,
  );
}

void main() {
  const emitter = LabIncrementalLearningTwinEvidenceEmitter();

  test('L4P emits each newly persisted decision once with stable completion', () async {
    final route = await _runRecoverySequence();
    final sink = InMemoryLabLearningEvidenceSink();

    final first = await emitter.emitNewlyPersisted(
      package: route.package,
      before: route.start,
      after: route.first,
      sink: sink,
    );
    final second = await emitter.emitNewlyPersisted(
      package: route.package,
      before: route.first,
      after: route.second,
      sink: sink,
    );
    final third = await emitter.emitNewlyPersisted(
      package: route.package,
      before: route.second,
      after: route.completed,
      sink: sink,
    );

    expect(first.allDelivered, isTrue);
    expect(second.allDelivered, isTrue);
    expect(third.allDelivered, isTrue);
    expect(sink.events, hasLength(3));
    expect(
      sink.events.map((item) => item.completion).toList(),
      <LabEvidenceCompletion>[
        LabEvidenceCompletion.partial,
        LabEvidenceCompletion.partial,
        LabEvidenceCompletion.completed,
      ],
    );
    expect(sink.events.first.eventId, route.first.decisionHistory.first.eventId);
    expect(sink.events.last.eventId, route.completed.decisionHistory.last.eventId);
  });

  test('L4P retains recovery, confidence, competency and Mistake DNA evidence', () async {
    final route = await _runRecoverySequence();
    final sink = InMemoryLabLearningEvidenceSink();

    await emitter.emitNewlyPersisted(
      package: route.package,
      before: route.start,
      after: route.completed,
      sink: sink,
    );

    expect(sink.events, hasLength(3));
    expect(sink.events[0].confidence, 0.9);
    expect(sink.events[1].nodeId, 'emergency_decision');
    expect(sink.events[1].recoveryEvidence, isTrue);
    expect(sink.events[1].competencyEvidence, contains('recovery_ability'));
    expect(sink.events[0].mistakeDnaTags, contains('permit_bypass'));
  });

  test('L4P evidence remains sanitized', () async {
    final route = await _runRecoverySequence();
    final sink = InMemoryLabLearningEvidenceSink();

    await emitter.emitNewlyPersisted(
      package: route.package,
      before: route.start,
      after: route.first,
      sink: sink,
    );

    final json = sink.events.single.toSanitizedJson();
    expect(json.containsKey('userId'), isFalse);
    expect(json.containsKey('stateBefore'), isFalse);
    expect(json.containsKey('stateAfter'), isFalse);
    expect(json.containsKey('stateDelta'), isFalse);
    expect(json.containsKey('stateValues'), isFalse);
    expect(json.containsKey('evidenceUnlocked'), isFalse);
  });

  test('L4P repeated emission is idempotent by Decision Event ID', () async {
    final route = await _runRecoverySequence();
    final sink = InMemoryLabLearningEvidenceSink();

    final first = await emitter.emitNewlyPersisted(
      package: route.package,
      before: route.start,
      after: route.first,
      sink: sink,
    );
    final retry = await emitter.emitNewlyPersisted(
      package: route.package,
      before: route.start,
      after: route.first,
      sink: sink,
    );

    expect(first.allDelivered, isTrue);
    expect(retry.allDelivered, isTrue);
    expect(sink.events, hasLength(1));
    expect(sink.events.single.eventId, route.first.decisionHistory.single.eventId);
  });

  test('L4P sink failure cannot roll back or mutate the persisted LAB story', () async {
    final route = await _runRecoverySequence();
    final beforeJson = jsonEncode(route.start.toJson());
    final afterJson = jsonEncode(route.first.toJson());

    final result = await emitter.emitNewlyPersisted(
      package: route.package,
      before: route.start,
      after: route.first,
      sink: _ThrowingEvidenceSink(),
    );

    expect(result.transitionValid, isTrue);
    expect(result.allDelivered, isFalse);
    expect(result.failedEventIds, <String>[route.first.decisionHistory.single.eventId]);
    expect(result.issues.single, contains('simulated Learning Twin outage'));
    expect(jsonEncode(route.start.toJson()), beforeJson);
    expect(jsonEncode(route.first.toJson()), afterJson);
    expect(route.first.currentNodeId, 'emergency_decision');
  });

  test('L4P rejects rewritten committed history before emitting evidence', () async {
    final route = await _runRecoverySequence();
    final tamperedJson = route.second.toJson();
    final history = tamperedJson['decisionHistory'] as List;
    final firstEvent = (history.first as Map).cast<String, Object?>();
    firstEvent['selectedOptionId'] = 'p1';
    final tampered = LabSession.fromJson(tamperedJson);
    final sink = InMemoryLabLearningEvidenceSink();

    final result = await emitter.emitNewlyPersisted(
      package: route.package,
      before: route.first,
      after: tampered,
      sink: sink,
    );

    expect(result.transitionValid, isFalse);
    expect(result.attemptedEventIds, isEmpty);
    expect(sink.events, isEmpty);
    expect(
      result.issues.any((issue) => issue.contains('rewrote committed Decision Event')),
      isTrue,
    );
  });

  test('L4P rejects cross-session or cross-version evidence transitions', () async {
    final route = await _runRecoverySequence();
    final changed = route.first.toJson();
    changed['sessionId'] = 'different_session';
    final mismatched = LabSession.fromJson(changed);
    final sink = InMemoryLabLearningEvidenceSink();

    final result = await emitter.emitNewlyPersisted(
      package: route.package,
      before: route.start,
      after: mismatched,
      sink: sink,
    );

    expect(result.transitionValid, isFalse);
    expect(result.attemptedEventIds, isEmpty);
    expect(sink.events, isEmpty);
    expect(
      result.issues,
      contains('L4P transition must remain inside one pinned LAB session.'),
    );
  });

  test('L4P does not alter frozen retrospective completed-session semantics', () async {
    final route = await _runRecoverySequence();
    final retrospective = const LabLearningTwinEvidenceBridge().buildEvidence(
      package: route.package,
      session: route.completed,
    );

    expect(retrospective, hasLength(3));
    expect(
      retrospective.every(
        (item) => item.completion == LabEvidenceCompletion.completed,
      ),
      isTrue,
    );
  });

  testWidgets('L4P learner player emits only after a decision is committed', (
    tester,
  ) async {
    final sink = InMemoryLabLearningEvidenceSink();

    await tester.pumpWidget(
      MaterialApp(
        home: LabReferencePlayerScreen(
          mode: LabMode.professional,
          learningEvidenceSink: sink,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(sink.events, isEmpty);
    expect(find.byKey(const ValueKey('lab-option-p1')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('lab-option-p1')));
    await tester.pump();
    expect(sink.events, isEmpty);

    await tester.drag(
      find.byKey(const ValueKey('lab-reference-player')),
      const Offset(0, -700),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('lab-confirm-decision')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('lab-confirm-decision')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('lab-consequence-screen')), findsOneWidget);
    expect(sink.events, hasLength(1));
    expect(sink.events.single.nodeId, 'permit_decision');
    expect(sink.events.single.optionId, 'p1');
    expect(sink.events.single.completion, LabEvidenceCompletion.partial);
  });

  test('L4P can catch up multiple append-only events after an evidence outage', () async {
    final route = await _runRecoverySequence();
    final sink = InMemoryLabLearningEvidenceSink();

    final result = await emitter.emitNewlyPersisted(
      package: route.package,
      before: route.start,
      after: route.completed,
      sink: sink,
    );

    expect(result.allDelivered, isTrue);
    expect(result.attemptedEventIds, hasLength(3));
    expect(sink.events, hasLength(3));
    expect(sink.events[0].completion, LabEvidenceCompletion.partial);
    expect(sink.events[1].completion, LabEvidenceCompletion.partial);
    expect(sink.events[2].completion, LabEvidenceCompletion.completed);
  });
}
