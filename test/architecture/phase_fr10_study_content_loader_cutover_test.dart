import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const loaderPath = 'lib/services/study_content_loader.dart';
  const deliveryPath =
      'lib/services/study_content/learner_content_package_delivery_service.dart';
  const screenPath = 'lib/screens/courses/csp/study_content_screen.dart';
  const workflowPath =
      '.github/workflows/phase_fr_firestore_read_reduction.yml';

  late String loader;
  late String delivery;
  late String screen;
  late String workflow;

  setUpAll(() {
    loader = File(loaderPath).readAsStringSync();
    delivery = File(deliveryPath).readAsStringSync();
    screen = File(screenPath).readAsStringSync();
    workflow = File(workflowPath).readAsStringSync();
  });

  test('FR10D default learner loader uses package delivery', () {
    expect(loader, contains('LearnerContentPackageDeliveryService'));
    expect(loader, contains('_deliveryService.loadCompetency(competencyId)'));
    expect(
      loader,
      isNot(contains('repository ?? CloudPublishedContentRepository()')),
    );
    expect(
      loader,
      contains(
        'Legacy StudyContent repository access requires explicit injection.',
      ),
    );
  });

  test('FR10D targeted learner load has no persistent-cache fallback', () {
    final start = loader.indexOf('Future<StudyContent> loadStudyContent');
    final end = loader.indexOf('// Published Domains', start);
    final targeted = loader.substring(start, end);

    expect(targeted, contains('_deliveryService.loadCompetency'));
    expect(targeted, isNot(contains('loadLatestForCompetency')));
    expect(targeted, isNot(contains('catch (_)')));
  });

  test('FR10D refresh uses the same package boundary', () {
    final start = loader.indexOf('Future<StudyContent> refreshStudyContent');
    final end = loader.indexOf('// Published Repository + Cache', start);
    final refresh = loader.substring(start, end);

    expect(refresh, contains('_deliveryService.loadCompetency'));
    expect(refresh, isNot(contains('loadPublishedCompetency')));
  });

  test('FR10D delivery is UID-authorized before cache access', () {
    final methodStart = delivery.indexOf(
      'Future<StudyContent> loadCompetency(String competencyId)',
    );
    final methodEnd = delivery.indexOf(
      'String _requireAuthorizedUser()',
      methodStart,
    );
    final method = delivery.substring(methodStart, methodEnd);
    final userIndex = method.indexOf('_requireAuthorizedUser()');
    final boundaryIndex = method.indexOf(
      'LearnerOnlineAccessRuntime.requireBoundaryFor(userId)',
    );
    final preferencesIndex = method.indexOf(
      'SharedPreferences.getInstance()',
    );

    expect(userIndex, greaterThanOrEqualTo(0));
    expect(boundaryIndex, greaterThan(userIndex));
    expect(preferencesIndex, greaterThan(boundaryIndex));
  });

  test('FR10D keeps existing first-frame RAM and targeted package load', () {
    expect(screen, contains('peekSessionStudyContent'));
    expect(screen, contains('loadStudyContent'));
  });

  test('FR10D cutover gate is wired into main FR CI', () {
    expect(workflow, contains('FR10 StudyContentLoader cutover tests'));
    expect(
      workflow,
      contains(
        'flutter test test/services/study_content/'
        'learner_content_package_delivery_service_test.dart',
      ),
    );
    expect(
      workflow,
      contains(
        'flutter test test/architecture/'
        'phase_fr10_study_content_loader_cutover_test.dart',
      ),
    );
  });
}
