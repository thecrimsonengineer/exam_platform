import 'dart:io';

import 'package:exam_platform/features/lab/lab_contracts.dart';
import 'package:exam_platform/features/lab/lab_debrief.dart';
import 'package:exam_platform/features/lab/lab_learner_loader.dart';
import 'package:exam_platform/features/lab/lab_learning_twin_bridge.dart';
import 'package:exam_platform/features/lab/lab_session.dart';
import 'package:exam_platform/features/lab/lab_studio.dart';
import 'package:exam_platform/screens/lab/lab_library_screen.dart';
import 'package:exam_platform/screens/lab/lab_player_shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'lab_l3_test_fixtures.dart';

void main() {
  for (var i = 0; i < 10; i++) {
    test(
      'LAB-9 JSON Studio publish learner load ' + (i + 1).toString(),
      () async {
        final pipeline = await publishL3Reference();
        final loader = LabLearnerPackageLoader(
          repository: pipeline.service.repository,
        );
        final loaded = await loader.loadPublished(
          labId: 'confined_space_h2s_simops',
          versionId: 'v1',
        );
        expect(pipeline.published.lifecycle, LabLifecycleStatus.published);
        expect(pipeline.published.report.isValid, isTrue);
        expect(loaded.metadata.lifecycle, LabLifecycleStatus.published);
        expect(loaded.metadata.id, 'confined_space_h2s_simops');
        expect(loaded.nodes.whereType<LabDecisionNode>(), hasLength(4));
        expect(loaded.endings, hasLength(5));
        expect(loaded.metadata.sources, hasLength(3));
      },
    );
  }

  for (var i = 0; i < 10; i++) {
    test('LAB-9 safe route ' + (i + 1).toString(), () async {
      final package = l3ReferenceDraftPackage();
      final session = await runL3SafeRoute(package, sessionId: 'safe_e2e_$i');
      expect(session.status, LabSessionStatus.completed);
      expect(session.endingId, 'safe_completion');
      expect(session.decisionHistory, hasLength(3));
      expect(session.decisionHistory[0].gateTriggered, 'permit_route');
      expect(session.decisionHistory[1].gateTriggered, 'gas_convergence');
      expect(session.decisionHistory[2].gateTriggered, 'ending_safe');
      expect(session.stateValues['final_outcome'], 'safe');
    });
  }

  for (var i = 0; i < 10; i++) {
    test('LAB-9 weak route ' + (i + 1).toString(), () async {
      final package = l3ReferenceDraftPackage();
      final session = await runL3WeakRoute(package, sessionId: 'weak_e2e_$i');
      expect(session.status, LabSessionStatus.completed);
      expect(session.endingId, 'incident_contained');
      expect(session.decisionHistory, hasLength(3));
      expect(session.stateValues['final_outcome'], 'contained');
      expect(session.decisionHistory.first.selectedOptionId, 'p3');
      expect(session.decisionHistory[1].selectedOptionId, 'g3');
      expect(session.decisionHistory.last.selectedOptionId, 'c3');
    });
  }

  for (var i = 0; i < 10; i++) {
    test('LAB-9 critical route ' + (i + 1).toString(), () async {
      final package = l3ReferenceDraftPackage();
      final session = await runL3CriticalFailureRoute(
        package,
        sessionId: 'critical_e2e_$i',
      );
      expect(session.status, LabSessionStatus.completed);
      expect(session.endingId, 'critical_failure');
      expect(session.decisionHistory, hasLength(2));
      expect(
        session.decisionHistory.first.gateTriggered,
        'permit_critical_event',
      );
      expect(
        session.decisionHistory.last.gateTriggered,
        'emergency_critical_failure',
      );
      expect(session.stateValues['emergency_outcome'], 'fatal');
    });
  }

  for (var i = 0; i < 10; i++) {
    test(
      'LAB-9 recovery convergence and authored endings ' + (i + 1).toString(),
      () async {
        final package = l3ReferenceDraftPackage();
        final lane = i % 5;
        late final LabSession session;
        late final String expectedEnding;
        if (lane == 0) {
          session = await runL3SafeRoute(package, sessionId: 'ending_$i');
          expectedEnding = 'safe_completion';
        } else if (lane == 1) {
          session = await runL3RecoveryRoute(package, sessionId: 'ending_$i');
          expectedEnding = 'controlled_recovery';
        } else if (lane == 2) {
          session = await runL3ContainedRoute(package, sessionId: 'ending_$i');
          expectedEnding = 'incident_contained';
        } else if (lane == 3) {
          session = await runL3MajorRoute(package, sessionId: 'ending_$i');
          expectedEnding = 'major_incident';
        } else {
          session = await runL3CriticalFailureRoute(
            package,
            sessionId: 'ending_$i',
          );
          expectedEnding = 'critical_failure';
        }
        expect(session.endingId, expectedEnding);
        expect(session.status, LabSessionStatus.completed);
        if (expectedEnding != 'critical_failure') {
          expect(
            session.decisionHistory.any(
              (event) => event.gateTriggered.contains('convergence'),
            ),
            isTrue,
          );
        }
      },
    );
  }

  for (var i = 0; i < 10; i++) {
    test(
      'LAB-9 session interruption and resume ' + (i + 1).toString(),
      () async {
        final package = l3ReferenceDraftPackage();
        final store = InMemoryLabSessionStore();
        final engine = LabSessionEngine(store: store);
        var session = await engine.startAttempt(
          package: package,
          sessionId: 'resume_$i',
          userId: 'learner_$i',
          mode: LabMode.professional,
          startedAt: DateTime.utc(2026, 9, 19),
        );
        session = await engine.commitDecision(
          package: package,
          session: session,
          optionId: 'p1',
          responseTimeMs: 200,
        );
        session = await engine.interrupt(session);
        expect(session.status, LabSessionStatus.interrupted);
        session = await engine.resume(
          package: package,
          sessionId: session.sessionId,
        );
        expect(session.status, LabSessionStatus.active);
        expect(session.currentNodeId, 'gas_decision');
        session = await engine.commitDecision(
          package: package,
          session: session,
          optionId: 'g1',
          responseTimeMs: 210,
        );
        session = await engine.commitDecision(
          package: package,
          session: session,
          optionId: 'c1',
          responseTimeMs: 220,
        );
        expect(session.endingId, 'safe_completion');
        expect(session.decisionHistory, hasLength(3));
      },
    );
  }

  for (var i = 0; i < 10; i++) {
    test(
      'LAB-9 debrief and Learning Twin evidence ' + (i + 1).toString(),
      () async {
        final package = l3ReferenceDraftPackage();
        final session = await runL3WeakRoute(package, sessionId: 'intel_$i');
        final debrief = const LabDebriefEngine().reconstruct(
          package: package,
          session: session,
        );
        final evidence = const LabLearningTwinEvidenceBridge().buildEvidence(
          package: package,
          session: session,
        );
        expect(debrief.completed, isTrue);
        expect(debrief.endingId, 'incident_contained');
        expect(debrief.decisions, hasLength(3));
        expect(debrief.alternateTimelines, hasLength(3));
        expect(debrief.mistakeDnaSignals, contains('simops_pressure'));
        expect(evidence, hasLength(3));
        expect(evidence.first.mistakeDnaTags, contains('simops_pressure'));
        expect(
          evidence.every(
            (item) => item.completion == LabEvidenceCompletion.completed,
          ),
          isTrue,
        );
      },
    );
  }

  for (var i = 0; i < 10; i++) {
    testWidgets(
      'LAB-9 closure UI boundary and deterministic replay ' +
          (i + 1).toString(),
      (tester) async {
        final package = l3ReferenceDraftPackage();
        if (i == 0 || i == 1) {
          await tester.pumpWidget(
            MaterialApp(
              theme: i == 0 ? ThemeData.light() : ThemeData.dark(),
              home: const LabLibraryScreen(),
            ),
          );
          await tester.pump();
          expect(find.text('Safety Decision LAB'), findsOneWidget);
          expect(find.text('Decision LABs'), findsOneWidget);
        } else if (i == 2 || i == 3) {
          await tester.pumpWidget(
            MaterialApp(
              theme: i == 2 ? ThemeData.light() : ThemeData.dark(),
              home: const LabPlayerShellScreen(),
            ),
          );
          await tester.pump();
          expect(find.text('LAB Player'), findsOneWidget);
          expect(
            find.text('Scene → Decision → Consequence → Story Gate'),
            findsOneWidget,
          );
        } else if (i == 4) {
          final learnerSource = File(
            'lib/screens/lab/lab_library_screen.dart',
          ).readAsStringSync();
          expect(learnerSource, isNot(contains('Lab1000StudioScreen')));
          final adminSource = File(
            'lib/screens/admin/admin_home_screen.dart',
          ).readAsStringSync();
          expect(adminSource, contains('Lab1000StudioScreen'));
        } else if (i == 5) {
          final runtimeSource = File(
            'lib/features/lab/lab_runtime.dart',
          ).readAsStringSync();
          expect(runtimeSource.toLowerCase(), isNot(contains('openai')));
          expect(runtimeSource.toLowerCase(), isNot(contains('runtime llm')));
        } else if (i == 6) {
          final first = await runL3WeakRoute(package, sessionId: 'golden_a');
          final second = await runL3WeakRoute(package, sessionId: 'golden_b');
          expect(first.endingId, second.endingId);
          expect(first.stateValues, second.stateValues);
          expect(
            first.decisionHistory.map((event) => event.gateTriggered).toList(),
            second.decisionHistory.map((event) => event.gateTriggered).toList(),
          );
        } else if (i == 7) {
          final pipeline = await publishL3Reference();
          final stored = await pipeline.service.repository.load(
            'confined_space_h2s_simops',
            'v1',
          );
          expect(stored, isNotNull);
          await expectLater(
            pipeline.service.repository.saveImmutable(stored!),
            throwsA(isA<LabStudioException>()),
          );
        } else if (i == 8) {
          final source = l3ReferenceSource();
          expect(source, contains('confined_space_h2s_simops'));
          expect(source.toLowerCase(), isNot(contains('javascript')));
          expect(source.toLowerCase(), isNot(contains('dartcode')));
          expect(source.toLowerCase(), isNot(contains('executable')));
        } else {
          expect(
            File(
              'test/fixtures/lab/l3_reference_confined_space_h2s.json',
            ).existsSync(),
            isTrue,
          );
          expect(
            File('content/lab_reference_confined_space_h2s.json').existsSync(),
            isTrue,
          );
          expect(package.endings, hasLength(5));
          expect(package.gates, hasLength(10));
        }
      },
    );
  }
}
