import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const shellTestPath = 'test/screens/auth/learner_authorized_shell_test.dart';
  const sessionTestPath =
      'test/services/online_access/'
      'learner_online_access_session_controller_test.dart';
  const connectivityTestPath =
      'test/services/online_access/'
      'learner_online_connectivity_coordinator_test.dart';
  const cacheTestPath =
      'test/services/study_content/'
      'uid_scoped_protected_content_cache_repository_test.dart';
  const preservationTestPath =
      'test/architecture/phase_fr_local_data_preservation_test.dart';
  const loaderPath = 'lib/services/study_content_loader.dart';
  const quizPath = 'lib/services/quiz_service.dart';
  const phasePath =
      'docs/firestore/PHASE_FR8_ONLINE_AUTHORIZED_CACHE_SECURITY.md';

  late String shellTests;
  late String sessionTests;
  late String connectivityTests;
  late String cacheTests;
  late String preservationTests;
  late String loader;
  late String quiz;
  late String phase;

  setUpAll(() {
    shellTests = File(shellTestPath).readAsStringSync();
    sessionTests = File(sessionTestPath).readAsStringSync();
    connectivityTests = File(connectivityTestPath).readAsStringSync();
    cacheTests = File(cacheTestPath).readAsStringSync();
    preservationTests = File(preservationTestPath).readAsStringSync();
    loader = File(loaderPath).readAsStringSync();
    quiz = File(quizPath).readAsStringSync();
    phase = File(phasePath).readAsStringSync();
  });

  test('FR8E has an executable offline-launch fail-closed proof', () {
    expect(
      shellTests,
      contains('FR8E offline launch never renders protected learner UI'),
    );
    expect(
      connectivityTests,
      contains('FR8D offline launch locks without attempting authorization'),
    );
  });

  test('FR8E proves cached protected content stays locked offline', () {
    expect(
      cacheTests,
      contains('FR8B blocks protected cache reads while authorization is locked'),
    );
    expect(cacheTests, contains('expect(repository.loadAll, throwsStateError)'));
  });

  test('FR8E proves logout and account-switch isolation', () {
    expect(
      sessionTests,
      contains('FR8 authorizes only the currently active Firebase UID'),
    );
    expect(sessionTests, contains('LearnerOnlineLockReason.userChanged'));
    expect(
      cacheTests,
      contains('FR8B keeps different Firebase UID cache namespaces isolated'),
    );
  });

  test('FR8E proves resume locks before remote reauthorization', () {
    expect(
      shellTests,
      contains('FR8E app resume locks protected UI until reauthorization'),
    );
    expect(
      sessionTests,
      contains('FR8 resume locks first and then forces reauthorization'),
    );
    expect(sessionTests, contains('forceRefreshToken: true'));
  });

  test('FR8E proves interrupted protected-cache migration is non-destructive', () {
    expect(
      cacheTests,
      contains(
        'FR8B read-back failure restores the previous scoped cache and legacy bytes',
      ),
    );
    expect(cacheTests, contains('ProtectedCacheMigrationStatus.verificationFailed'));
  });

  test('FR8E preserves existing learner-owned local data contracts', () {
    expect(
      preservationTests,
      contains('FR preserves UID-scoped learner progress namespaces'),
    );
    expect(
      preservationTests,
      contains('FR preserves UID-scoped Exam Readiness namespaces'),
    );
    expect(
      preservationTests,
      contains('FR retains the legacy learner progress key for safe migration'),
    );
  });

  test('FR8E does not perform learner source cutover', () {
    expect(loader, contains('CloudPublishedContentRepository'));
    expect(quiz, contains('CloudQuestionRepository'));
    expect(quiz, contains('CloudContentRepository'));
    expect(phase, contains('Firestore remains the learner'));
    expect(phase, contains('Do not begin learner source cutover during FR8'));
  });
}
