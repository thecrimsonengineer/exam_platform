import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const loaderPath = 'lib/services/study_content_loader.dart';
  const domainScreenPath = 'lib/screens/courses/csp/domain_screen.dart';
  const darkDomainScreenPath =
      'lib/screens/courses/csp/domain_screen_dark.dart';
  const contentTestScreenPath =
      'lib/screens/courses/csp/content_test_screen.dart';
  const studyScreenPath = 'lib/screens/courses/csp/study_content_screen.dart';
  const workflowPath =
      '.github/workflows/phase_fr_firestore_read_reduction.yml';

  late String loader;
  late String domainScreen;
  late String darkDomainScreen;
  late String contentTestScreen;
  late String studyScreen;
  late String workflow;

  setUpAll(() {
    loader = File(loaderPath).readAsStringSync();
    domainScreen = File(domainScreenPath).readAsStringSync();
    darkDomainScreen = File(darkDomainScreenPath).readAsStringSync();
    contentTestScreen = File(contentTestScreenPath).readAsStringSync();
    studyScreen = File(studyScreenPath).readAsStringSync();
    workflow = File(workflowPath).readAsStringSync();
  });

  test('FR10E domain navigation is canonical and synchronous', () {
    expect(domainScreen, contains('_domain.competencies'));
    expect(domainScreen, contains('Csp11Competency'));
    expect(domainScreen, contains('domainId: _domain.id'));
    expect(domainScreen, contains('competencyId: content.id'));
    expect(domainScreen, isNot(contains('loadPublishedDomainContent')));
    expect(domainScreen, isNot(contains('StudentStudyContentPrefetchService')));
    expect(domainScreen, isNot(contains('_contentFuture')));
  });

  test('FR10E dark navigation uses the same canonical path', () {
    expect(darkDomainScreen, contains('_domain.competencies'));
    expect(darkDomainScreen, contains('Csp11Competency'));
    expect(darkDomainScreen, contains('domainId: _domain.id'));
    expect(darkDomainScreen, contains('competencyId: content.id'));
    expect(darkDomainScreen, isNot(contains('loadPublishedDomainContent')));
    expect(
      darkDomainScreen,
      isNot(contains('StudentStudyContentPrefetchService')),
    );
    expect(darkDomainScreen, isNot(contains('_contentFuture')));
  });

  test('FR10E development content test uses targeted canonical navigation', () {
    expect(contentTestScreen, contains('csp11Domains.first'));
    expect(contentTestScreen, contains('domain.competencies.first'));
    expect(contentTestScreen, contains('StudyContentScreen('));
    expect(contentTestScreen, isNot(contains('loadPublishedContent')));
    expect(contentTestScreen, isNot(contains('StudyContentLoader')));
  });

  test('FR10E structural loader uses the canonical CSP11 blueprint', () {
    expect(loader, contains("import '../data/csp11_blueprint.dart';"));
    expect(loader, contains('for (final domain in csp11Domains)'));
    expect(loader, contains('domainForContentId(domainId)'));

    final domainsStart = loader.indexOf(
      'Future<List<Map<String, dynamic>>> loadDomains()',
    );
    final legacyStart = loader.indexOf('// Legacy Asset Methods', domainsStart);
    final navigation = loader.substring(domainsStart, legacyStart);

    expect(navigation, isNot(contains('loadPublishedContent')));
    expect(navigation, isNot(contains('loadPublishedDomainContent')));
    expect(navigation, isNot(contains('_injectedRepository')));
    expect(navigation, isNot(contains('_resolveCache')));
  });

  test('FR10E default broad learner StudyContent reads fail closed', () {
    expect(
      loader,
      contains('Broad learner StudyContent reads were retired in FR10E'),
    );
    expect(
      loader,
      contains('Broad learner StudyContent domain reads were retired in FR10E'),
    );
  });

  test('FR10E removes unconditional navigation revalidation', () {
    expect(studyScreen, contains('peekSessionStudyContent'));
    expect(studyScreen, isNot(contains('unawaited(')));
    expect(studyScreen, isNot(contains('_refreshSessionContent')));
    expect(studyScreen, isNot(contains('refreshStudyContent(')));
  });

  test('FR10E student-facing CSP screens contain no broad content calls', () {
    final directory = Directory('lib/screens/courses/csp');
    final dartFiles = directory
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    for (final file in dartFiles) {
      final source = file.readAsStringSync();
      expect(
        source,
        isNot(contains('.loadPublished()')),
        reason: file.path,
      );
      expect(
        source,
        isNot(contains('.loadPublishedDomain(')),
        reason: file.path,
      );
      expect(
        source,
        isNot(contains('loadPublishedContent(')),
        reason: file.path,
      );
      expect(
        source,
        isNot(contains('loadPublishedDomainContent(')),
        reason: file.path,
      );
      expect(
        source,
        isNot(contains('StudentContentSyncService')),
        reason: file.path,
      );
    }
  });

  test('FR10E retirement gate is part of exact-SHA FR CI', () {
    expect(workflow, contains('FR10 navigation broad-read retirement tests'));
    expect(
      workflow,
      contains(
        'flutter test test/services/study_content/'
        'study_content_navigation_blueprint_test.dart',
      ),
    );
    expect(
      workflow,
      contains(
        'flutter test test/architecture/'
        'phase_fr10_navigation_broad_read_retirement_test.dart',
      ),
    );
  });
}
