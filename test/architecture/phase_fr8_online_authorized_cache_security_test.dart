import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const gatePath = 'lib/services/online_access/learner_online_access_gate.dart';
  const controllerPath =
      'lib/services/online_access/learner_online_access_session_controller.dart';
  const workflowPath =
      '.github/workflows/phase_fr_firestore_read_reduction.yml';
  const protectedCachePath =
      'lib/services/study_content/'
      'uid_scoped_protected_content_cache_repository.dart';
  const runtimePath =
      'lib/services/online_access/learner_online_access_runtime.dart';
  const authorizedShellPath = 'lib/screens/auth/learner_authorized_shell.dart';
  const authGatePath = 'lib/screens/auth/auth_gate.dart';
  const loaderPath = 'lib/services/study_content_loader.dart';
  const quizPath = 'lib/services/quiz_service.dart';
  const phasePath =
      'docs/firestore/PHASE_FR8_ONLINE_AUTHORIZED_CACHE_SECURITY.md';

  late String gate;
  late String controller;
  late String workflow;
  late String protectedCache;
  late String runtime;
  late String authorizedShell;
  late String authGate;
  late String loader;
  late String quiz;
  late String phase;

  setUpAll(() {
    gate = File(gatePath).readAsStringSync();
    controller = File(controllerPath).readAsStringSync();
    workflow = File(workflowPath).readAsStringSync();
    protectedCache = File(protectedCachePath).readAsStringSync();
    runtime = File(runtimePath).readAsStringSync();
    authorizedShell = File(authorizedShellPath).readAsStringSync();
    authGate = File(authGatePath).readAsStringSync();
    loader = File(loaderPath).readAsStringSync();
    quiz = File(quizPath).readAsStringSync();
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

  test('FR8 protected cache is UID-scoped and authorization-gated', () {
    expect(protectedCache, contains('storageKeyForUser(String userId)'));
    expect(
      protectedCache,
      contains('LearnerProtectedCacheAccessBoundary _accessBoundary'),
    );
    expect(protectedCache, contains('_requireAuthorized()'));
    expect(protectedCache, contains('protected_study_content_cache.v2'));
  });

  test('FR8 legacy cache migration is verify-before-retire', () {
    expect(
      protectedCache,
      contains("legacyCacheKey = 'csp11.student_content_cache.v1'"),
    );
    expect(protectedCache, contains('migrateLegacyIfAuthorized()'));
    expect(protectedCache, contains('final readBack = _store.getString'));
    expect(protectedCache, contains('setBool(migrationMarkerKey, true)'));
    expect(protectedCache, contains('remove(legacyCacheKey)'));
    expect(protectedCache, contains('_restoreScopedValue(previousScopedRaw)'));
  });

  test('FR8C gates the verified learner shell behind online authorization', () {
    expect(authGate, contains('LearnerAuthorizedShell'));
    expect(
      authGate,
      contains('LearnerOnlineAccessRuntime.handleAuthUserChanged'),
    );
    expect(
      authorizedShell,
      contains('snapshot.isAuthorizedFor(widget.userId)'),
    );
    expect(authorizedShell, contains('revalidateOnResume()'));
    expect(authorizedShell, contains('fr8-retry-online-authorization'));
  });

  test('FR8C defaults StudyContent to the protected UID cache', () {
    expect(loader, contains('UidScopedProtectedContentCacheRepository'));
    expect(loader, contains('LearnerOnlineAccessRuntime.requireBoundaryFor'));
    expect(loader, contains('migrateLegacyIfAuthorized()'));
    expect(
      loader,
      isNot(contains('return StudentContentCacheRepository(preferences:')),
    );
  });

  test('FR8C clears protected process memory on lock boundaries', () {
    expect(runtime, contains('StudentStudyContentSessionCache.clear()'));
    expect(runtime, contains('QuizService.shared.clearProtectedSession()'));
    expect(
      runtime,
      contains('StudentProgressDashboardSessionCache.clearAll()'),
    );
    expect(quiz, contains('_protectedSessionGeneration'));
    expect(quiz, contains('generation != _protectedSessionGeneration'));
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
