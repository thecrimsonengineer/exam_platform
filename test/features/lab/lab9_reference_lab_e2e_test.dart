import 'dart:io';

import 'package:exam_platform/features/lab/lab_contracts.dart';
import 'package:exam_platform/features/lab/lab_debrief.dart';
import 'package:exam_platform/features/lab/lab_learning_twin_bridge.dart';
import 'package:exam_platform/features/lab/lab_session.dart';
import 'package:exam_platform/features/lab/lab_validation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'lab_l3_test_fixtures.dart';

void main() {
  for (var i = 0; i < 10; i++) {
    test(
      'LAB-9 JSON Studio publish learner load ' + (i + 1).toString(),
      () async {
        final published = await publishReferenceLab(
          reviewerId: 'reviewer_' + i.toString(),
        );

        expect(published.workspace.lifecycle, LabLifecycleStatus.published);
        expect(
          published.package.metadata.lifecycle,
          LabLifecycleStatus.published,
        );
        expect(published.package.metadata.id, 'confined_space_h2s_simops');
        expect(published.package.nodes.whereType<LabDecisionNode>().length, 4);
        expect(published.package.endings, hasLength(5));
      },
    );
  }

  for (var i = 0; i < 10; i++) {
    test('LAB-9 safe route ' + (i + 1).toString(), () async {
      final run = await safeReferenceRun(sessionId: 'safe_e2e_' + i.toString());
      expect(run.session.status, LabSessionStatus.completed);
      expect(run.session.endingId, 'safe_completion');
      expect(run.session.decisionHistory, hasLength(3));
      expect(run.session.stateValues['risk'], 0);
    });
  }

  for (var i = 0; i < 10; i++) {
    test('LAB-9 weak route ' + (i + 1).toString(), () async {
      final run = await weakReferenceRun(sessionId: 'weak_e2e_' + i.toString());
      expect(run.session.status, LabSessionStatus.completed);
      expect(run.session.endingId, 'incident_contained');
      expect(run.session.decisionHistory[0].selectedOptionId, 'p3');
      expect(run.session.decisionHistory[1].selectedOptionId, 'g3');
    });
  }

  for (var i = 0; i < 10; i++) {
    test('LAB-9 critical route ' + (i + 1).toString(), () async {
      final run = await criticalReferenceRun(
        sessionId: 'critical_e2e_' + i.toString(),
      );
      expect(run.session.status, LabSessionStatus.completed);
      expect(run.session.endingId, 'critical_failure');
      expect(run.session.decisionHistory, hasLength(2));
      expect(
        run.session.decisionHistory.first.gateTriggered,
        'permit_critical_event',
      );
    });
  }

  for (var i = 0; i < 10; i++) {
    test(
      'LAB-9 recovery and convergence route ' + (i + 1).toString(),
      () async {
        final run = await recoveryReferenceRun(
          sessionId: 'recovery_e2e_' + i.toString(),
        );
        expect(run.session.endingId, 'controlled_recovery');
        expect(
          run.session.decisionHistory[1].gateTriggered,
          'emergency_convergence',
        );
        expect(run.session.decisionHistory[2].gateTriggered, 'ending_recovery');
      },
    );
  }

  final endingPaths = <String, List<String>>{
    'safe_completion': <String>['p1', 'g1', 'c1'],
    'controlled_recovery': <String>['p1', 'g1', 'c2'],
    'incident_contained': <String>['p1', 'g1', 'c3'],
    'major_incident': <String>['p1', 'g1', 'c4'],
    'critical_failure': <String>['p4', 'e4'],
  };

  for (var i = 0; i < 10; i++) {
    test('LAB-9 all authored endings ' + (i + 1).toString(), () async {
      final entry = endingPaths.entries.elementAt(i % endingPaths.length);
      final run = await runReferencePath(
        entry.value,
        sessionId: 'ending_' + i.toString(),
      );
      expect(run.session.status, LabSessionStatus.completed);
      expect(run.session.endingId, entry.key);
    });
  }

  for (var i = 0; i < 10; i++) {
    test(
      'LAB-9 resume debrief Learning Twin evidence ' + (i + 1).toString(),
      () async {
        final package = referenceLabPackage();
        final store = InMemoryLabSessionStore();
        final sessionEngine = LabSessionEngine(store: store);
        var session = await sessionEngine.startAttempt(
          package: package,
          sessionId: 'resume_' + i.toString(),
          userId: 'resume_user',
          mode: LabMode.professional,
        );
        session = await sessionEngine.commitDecision(
          package: package,
          session: session,
          optionId: 'p1',
          responseTimeMs: 700,
          confidence: 0.8,
        );
        final checkpoint = session.encodeCheckpoint();
        final restored = await sessionEngine.restoreCheckpoint(
          package: package,
          checkpoint: checkpoint,
        );
        final interrupted = await sessionEngine.interrupt(session);
        final resumed = await sessionEngine.resume(
          package: package,
          sessionId: interrupted.sessionId,
        );

        final evidence = const LabLearningTwinEvidenceBridge().buildEvidence(
          package: package,
          session: resumed,
        );
        final debrief = const LabDebriefEngine().reconstruct(
          package: package,
          session: restored,
        );

        expect(resumed.status, LabSessionStatus.active);
        expect(restored.decisionHistory, hasLength(1));
        expect(evidence.single.confidence, 0.8);
        expect(debrief.decisions.single.optionId, 'p1');
      },
    );
  }

  for (var i = 0; i < 10; i++) {
    test(
      'LAB-9 deterministic golden replay and UI boundary ' + (i + 1).toString(),
      () async {
        if (i < 5) {
          final package = referenceLabPackage();
          final first = const LabPathSimulator().run(package);
          final second = const LabPathSimulator().run(package);
          expect(first.fingerprint, second.fingerprint);
          expect(first.reachableEndingIds, containsAll(endingPaths.keys));
          expect(first.issues, isEmpty);
        } else {
          final player = File(
            'lib/screens/lab/lab_player_shell_screen.dart',
          ).readAsStringSync();
          final library = File(
            'lib/screens/lab/lab_library_screen.dart',
          ).readAsStringSync();
          final admin = File(
            'lib/screens/admin/lab/lab1000_studio_screen.dart',
          ).readAsStringSync();

          expect(player, contains('Theme.of(context).brightness'));
          expect(player, contains('StudentGlassScaffold'));
          expect(library, contains('Theme.of(context).brightness'));
          expect(admin, contains('LAB1000 Studio'));
          expect(player, isNot(contains('Lab1000StudioScreen')));
        }
      },
    );
  }
}
