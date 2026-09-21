import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const gatePath = 'lib/services/online_access/learner_online_access_gate.dart';
  const controllerPath =
      'lib/services/online_access/learner_online_access_session_controller.dart';
  const workflowPath =
      '.github/workflows/phase_fr_firestore_read_reduction.yml';
  const phasePath =
      'docs/firestore/PHASE_FR8_ONLINE_AUTHORIZED_CACHE_SECURITY.md';

  late String gate;
  late String controller;
  late String workflow;
  late String phase;

  setUpAll(() {
    gate = File(gatePath).readAsStringSync();
    controller = File(controllerPath).readAsStringSync();
    workflow = File(workflowPath).readAsStringSync();
    phase = File(phasePath).readAsStringSync();
  });

  test('FR8 uses the FR2 online access gate as the authorization validator', () {
    expect(
      gate,
      contains('abstract interface class LearnerOnlineAccessValidator'),
    );
    expect(
      gate,
      contains(
        'class LearnerOnlineAccessGate implements LearnerOnlineAccessValidator',
      ),
    );
    expect(controller, contains('LearnerOnlineAccessValidator'));
  });

  test('FR8 session state is UID-bound and fail-closed', () {
    expect(controller, contains('isAuthorizedFor(String userId)'));
    expect(controller, contains('LearnerOnlineLockReason.userChanged'));
    expect(controller, contains('LearnerOnlineLockReason.signedOut'));
    expect(controller, contains('LearnerOnlineLockReason.backendUnavailable'));
    expect(controller, contains('LearnerOnlineLockReason.rejected'));
    expect(controller, contains('generation != _generation'));
  });

  test('FR8 defines resume and connectivity lock boundaries', () {
    expect(controller, contains('revalidateOnResume()'));
    expect(controller, contains('handleTransientConnectivityLoss()'));
    expect(controller, contains('handleConnectivityRestored()'));
    expect(controller, contains('handleConfirmedNetworkLoss()'));
    expect(controller, contains('reconnectGrace'));
  });

  test('FR8 exposes an explicit protected-cache unlock contract', () {
    expect(
      controller,
      contains('abstract interface class LearnerProtectedCacheAccessBoundary'),
    );
    expect(
      controller,
      contains('implements LearnerProtectedCacheAccessBoundary'),
    );
  });

  test('FR8 remains before learner delivery cutover', () {
    expect(phase, contains('FR8 does not perform learner delivery cutover'));
    expect(phase, contains('Firestore remains the learner'));
    expect(
      phase,
      contains('source until the later reviewed FR cutover phases.'),
    );
    expect(phase, contains('no uninstall'));
    expect(phase, contains('copy -> validate -> write -> read-back -> switch'));
  });

  test('FR8 is wired into the main FR validation workflow', () {
    expect(workflow, contains('phase-fr8-online-authorized-cache-security'));
    expect(workflow, contains('FR8 online authorization session tests'));
  });
}
