import 'package:exam_platform/features/lab/lab_contracts.dart';
import 'package:exam_platform/features/lab/lab_session.dart';
import 'package:flutter_test/flutter_test.dart';

import 'lab_l2_test_fixtures.dart';

void main() {
  for (var i = 0; i < 10; i++) {
    test('LAB-4 new attempt ' + (i + 1).toString(), () async {
      final store = InMemoryLabSessionStore();
      final engine = LabSessionEngine(store: store);
      final package = buildL2Package();

      final session = await engine.startAttempt(
        package: package,
        sessionId: 'session_start_' + i.toString(),
        userId: 'user_1',
        mode: LabMode.professional,
        startedAt: DateTime.utc(2026, 9, 18, 12, i),
      );

      expect(session.status, LabSessionStatus.active);
      expect(session.currentNodeId, 'decision_one');
      expect(session.labVersionId, 'v1');
      expect(session.decisionHistory, isEmpty);
      expect(session.revision, 0);
    });
  }

  final firstOptions = <String>['o1', 'o2', 'o3', 'o4'];
  for (var i = 0; i < 20; i++) {
    test('LAB-4 commit decision event ' + (i + 1).toString(), () async {
      final store = InMemoryLabSessionStore();
      final engine = LabSessionEngine(store: store);
      final package = buildL2Package();
      final session = await engine.startAttempt(
        package: package,
        sessionId: 'session_commit_' + i.toString(),
        userId: 'user_1',
        mode: LabMode.guided,
      );

      final option = firstOptions[i % firstOptions.length];
      final committed = await engine.commitDecision(
        package: package,
        session: session,
        optionId: option,
        responseTimeMs: 500 + i,
        confidence: 0.7,
        timestamp: DateTime.utc(2026, 9, 18, 13, i),
      );

      expect(committed.currentNodeId, 'decision_two');
      expect(committed.decisionHistory, hasLength(1));
      expect(committed.decisionHistory.single.selectedOptionId, option);
      expect(committed.decisionHistory.single.stateBefore['route'], 'start');
      expect(committed.decisionHistory.single.stateAfter['route'],
          option == 'o4' ? 'critical' : 'safe');
      expect(committed.revision, 1);
    });
  }

  for (var i = 0; i < 10; i++) {
    test('LAB-4 irreversible duplicate submission ' + (i + 1).toString(),
        () async {
      final store = InMemoryLabSessionStore();
      final engine = LabSessionEngine(store: store);
      final package = buildL2Package();
      final original = await engine.startAttempt(
        package: package,
        sessionId: 'session_irreversible_' + i.toString(),
        userId: 'user_1',
        mode: LabMode.professional,
      );

      final first = await engine.commitDecision(
        package: package,
        session: original,
        optionId: 'o1',
        responseTimeMs: 100,
      );
      expect(first.decisionHistory, hasLength(1));

      if (i.isEven) {
        final retry = await engine.commitDecision(
          package: package,
          session: original,
          optionId: 'o1',
          responseTimeMs: 100,
        );
        expect(retry.decisionHistory, hasLength(1));
        expect(retry.revision, 1);
      } else {
        await expectLater(
          engine.commitDecision(
            package: package,
            session: original,
            optionId: 'o2',
            responseTimeMs: 100,
          ),
          throwsA(isA<LabSessionException>()),
        );
      }
    });
  }

  for (var i = 0; i < 10; i++) {
    test('LAB-4 checkpoint round trip ' + (i + 1).toString(), () async {
      final store = InMemoryLabSessionStore();
      final engine = LabSessionEngine(store: store);
      final package = buildL2Package();
      final original = await engine.startAttempt(
        package: package,
        sessionId: 'session_checkpoint_' + i.toString(),
        userId: 'user_1',
        mode: LabMode.assessment,
      );
      final committed = await engine.commitDecision(
        package: package,
        session: original,
        optionId: 'o2',
        responseTimeMs: 250,
      );

      final restored = await engine.restoreCheckpoint(
        package: package,
        checkpoint: committed.encodeCheckpoint(),
      );

      expect(restored.sessionId, committed.sessionId);
      expect(restored.currentNodeId, committed.currentNodeId);
      expect(restored.stateValues, committed.stateValues);
      expect(restored.decisionHistory, hasLength(1));
      expect(restored.labVersionId, 'v1');
    });
  }

  for (var i = 0; i < 10; i++) {
    test('LAB-4 session completion ' + (i + 1).toString(), () async {
      final store = InMemoryLabSessionStore();
      final engine = LabSessionEngine(store: store);
      final package = buildL2Package();
      var session = await engine.startAttempt(
        package: package,
        sessionId: 'session_complete_' + i.toString(),
        userId: 'user_1',
        mode: LabMode.professional,
      );

      session = await engine.commitDecision(
        package: package,
        session: session,
        optionId: firstOptions[i % 4],
        responseTimeMs: 100,
      );
      session = await engine.commitDecision(
        package: package,
        session: session,
        optionId: 'o5',
        responseTimeMs: 120,
      );

      expect(session.status, LabSessionStatus.completed);
      expect(session.endingId, 'safe_end');
      expect(session.decisionHistory, hasLength(2));
      expect(session.revision, 2);
    });
  }

  for (var i = 0; i < 10; i++) {
    test('LAB-4 replay and version pinning ' + (i + 1).toString(), () async {
      final store = InMemoryLabSessionStore();
      final engine = LabSessionEngine(store: store);
      final package = buildL2Package();
      final session = await engine.startAttempt(
        package: package,
        sessionId: 'session_pin_' + i.toString(),
        userId: 'user_1',
        mode: LabMode.guided,
      );

      if (i.isEven) {
        final replay = await engine.replay(
          package: package,
          prior: session,
          newSessionId: 'session_replay_' + i.toString(),
        );
        expect(replay.sessionId, isNot(session.sessionId));
        expect(replay.labVersionId, session.labVersionId);
        expect(replay.decisionHistory, isEmpty);
      } else {
        await expectLater(
          engine.resume(
            package: buildL2Package(versionId: 'v2'),
            sessionId: session.sessionId,
          ),
          throwsA(isA<LabSessionException>()),
        );
      }
    });
  }

  for (var i = 0; i < 10; i++) {
    test('LAB-4 append event order ' + (i + 1).toString(), () async {
      final store = InMemoryLabSessionStore();
      final engine = LabSessionEngine(store: store);
      final package = buildL2Package();
      var session = await engine.startAttempt(
        package: package,
        sessionId: 'session_order_' + i.toString(),
        userId: 'user_1',
        mode: LabMode.professional,
      );
      session = await engine.commitDecision(
        package: package,
        session: session,
        optionId: 'o1',
        responseTimeMs: 101,
        timestamp: DateTime.utc(2026, 9, 18, 10, 0),
      );
      session = await engine.commitDecision(
        package: package,
        session: session,
        optionId: 'o5',
        responseTimeMs: 102,
        timestamp: DateTime.utc(2026, 9, 18, 10, 1),
      );

      expect(session.decisionHistory[0].eventId,
          session.sessionId + ':event:1');
      expect(session.decisionHistory[1].eventId,
          session.sessionId + ':event:2');
      expect(
        session.decisionHistory[0].timestamp
            .isBefore(session.decisionHistory[1].timestamp),
        isTrue,
      );
    });
  }

  for (var i = 0; i < 10; i++) {
    test('LAB-4 offline interruption resume ' + (i + 1).toString(), () async {
      final store = InMemoryLabSessionStore();
      final engine = LabSessionEngine(store: store);
      final package = buildL2Package();
      final session = await engine.startAttempt(
        package: package,
        sessionId: 'session_interrupt_' + i.toString(),
        userId: 'user_1',
        mode: LabMode.professional,
      );

      final interrupted = await engine.interrupt(session);
      expect(interrupted.status, LabSessionStatus.interrupted);
      final resumed = await engine.resume(
        package: package,
        sessionId: session.sessionId,
      );
      expect(resumed.status, LabSessionStatus.active);
      expect(resumed.currentNodeId, 'decision_one');
      expect(resumed.revision, 2);
    });
  }

  for (var i = 0; i < 10; i++) {
    test('LAB-4 stale write protection ' + (i + 1).toString(), () async {
      final store = InMemoryLabSessionStore();
      final engine = LabSessionEngine(store: store);
      final package = buildL2Package();
      final session = await engine.startAttempt(
        package: package,
        sessionId: 'session_stale_' + i.toString(),
        userId: 'user_1',
        mode: LabMode.guided,
      );

      final firstUpdate = session.copyWith(
        revision: 1,
        status: LabSessionStatus.interrupted,
      );
      await store.save(firstUpdate, expectedRevision: 0);

      final staleUpdate = session.copyWith(
        revision: 1,
        currentNodeId: 'decision_two',
      );
      await expectLater(
        store.save(staleUpdate, expectedRevision: 0),
        throwsA(isA<LabStaleSessionWriteException>()),
      );
    });
  }

  for (var i = 0; i < 10; i++) {
    test('LAB-4 idempotent transaction behaviour ' + (i + 1).toString(),
        () async {
      final store = InMemoryLabSessionStore();
      final engine = LabSessionEngine(store: store);
      final package = buildL2Package();
      final session = await engine.startAttempt(
        package: package,
        sessionId: 'session_idempotent_' + i.toString(),
        userId: 'user_1',
        mode: LabMode.professional,
      );

      final update = session.copyWith(
        revision: 1,
        status: LabSessionStatus.interrupted,
      );
      final saved = await store.save(update, expectedRevision: 0);
      final retry = await store.save(saved, expectedRevision: 0);

      expect(retry.revision, 1);
      expect(retry.status, LabSessionStatus.interrupted);
      expect((await store.load(session.sessionId))!.revision, 1);
    });
  }
}
