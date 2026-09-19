import 'dart:io';

import 'package:exam_platform/features/lab/lab_contracts.dart';
import 'package:exam_platform/features/lab/lab_session.dart';
import 'package:exam_platform/features/lab/lab_studio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  LabPackage loadV2() {
    final source = File(
      'content/lab_reference_confined_space_h2s_v2.json',
    ).readAsStringSync();
    return LabPackage.decode(source);
  }

  Future<LabSession> commit(
    LabSessionEngine engine,
    LabPackage package,
    LabSession session,
    String optionId,
  ) {
    return engine.commitDecision(
      package: package,
      session: session,
      optionId: optionId,
      responseTimeMs: 250,
    );
  }

  test('v2 reference LAB passes Studio validation', () {
    final source = File(
      'content/lab_reference_confined_space_h2s_v2.json',
    ).readAsStringSync();
    final service = Lab1000StudioService(
      repository: InMemoryLabPublishedRepository(),
    );

    final draft = service.importJson(source);
    final review = service.requestReview(draft);
    final validated = service.approveReview(
      review,
      reviewerId: 'story_gate_regression',
    );

    expect(validated.report.isValid, isTrue);
    expect(validated.package.metadata.versionId, 'v2');
    expect(validated.package.nodes.whereType<LabDecisionNode>(), hasLength(5));
  });

  test('two optimal decisions route to the matching SIMOPS story beat', () async {
    final package = loadV2();
    final store = InMemoryLabSessionStore();
    final engine = LabSessionEngine(store: store);

    var session = await engine.startAttempt(
      package: package,
      sessionId: 'safe_story_route',
      userId: 'story_tester',
      mode: LabMode.guided,
    );

    session = await commit(engine, package, session, 'p1');
    expect(session.currentNodeId, 'gas_decision');
    expect(session.decisionHistory.last.gateTriggered, 'permit_route');

    session = await commit(engine, package, session, 'g1');
    expect(session.currentNodeId, 'simops_decision');
    expect(session.decisionHistory.last.gateTriggered, 'gas_work_convergence');

    final simopsNode = package.nodes
        .whereType<LabDecisionNode>()
        .singleWhere((node) => node.id == 'simops_decision');
    expect(
      simopsNode.prompt,
      contains('Nearby line-breaking SIMOPS begins'),
    );

    session = await commit(engine, package, session, 's1');
    expect(session.status, LabSessionStatus.completed);
    expect(session.endingId, 'safe_completion');
    expect(session.decisionHistory.last.gateTriggered, 'simops_safe_completion');
  });

  test('critical SIMOPS decision interrupts into emergency response', () async {
    final package = loadV2();
    final store = InMemoryLabSessionStore();
    final engine = LabSessionEngine(store: store);

    var session = await engine.startAttempt(
      package: package,
      sessionId: 'critical_story_route',
      userId: 'story_tester',
      mode: LabMode.professional,
    );

    session = await commit(engine, package, session, 'p1');
    session = await commit(engine, package, session, 'g1');
    session = await commit(engine, package, session, 's4');

    expect(session.currentNodeId, 'emergency_decision');
    expect(session.decisionHistory.last.gateTriggered, 'simops_critical_event');
    expect(session.status, LabSessionStatus.active);

    session = await commit(engine, package, session, 'e1');
    expect(session.currentNodeId, 'closeout_decision');
    expect(session.decisionHistory.last.gateTriggered, 'emergency_convergence');
  });
}
