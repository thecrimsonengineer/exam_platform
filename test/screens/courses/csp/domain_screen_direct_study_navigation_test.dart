import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DomainScreen direct canonical study navigation', () {
    late String source;

    setUpAll(() {
      source = File(
        'lib/screens/courses/csp/domain_screen.dart',
      ).readAsStringSync();
    });

    test('imports StudyContentScreen directly', () {
      expect(source, contains("import 'study_content_screen.dart';"));
    });

    test('does not import legacy CompetencyScreen', () {
      expect(source, isNot(contains("import 'competency_screen.dart';")));
    });

    test('routes directly to StudyContentScreen', () {
      expect(source, contains('builder: (_) => StudyContentScreen('));
      expect(source, contains('domainId: domainId,'));
      expect(source, contains('competencyId: competencyId,'));
      expect(source, contains('domainTitle: _domain.title,'));
      expect(source, contains('loadingTitle: title,'));
    });

    test('does not route to CompetencyScreen', () {
      expect(source, isNot(contains('builder: (_) => CompetencyScreen(')));
    });
  });
}
