import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String source;

  setUpAll(() {
    source = File('lib/widgets/csp/student_quiz_builder.dart')
        .readAsStringSync()
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n');
  });

  test('Custom Quiz uses FR9 compact catalogue instead of global preload', () {
    expect(source, contains('loadCatalogMetadata()'));
    expect(source, contains('prepareCompetencies('));
    expect(source, contains('_maxRuntimeScopePackages = 4'));
    expect(source, isNot(contains('_quizService.initialize()')));
    expect(source, isNot(contains('getPublishedContent()')));
    expect(source, isNot(contains('ContentPackageSummary')));
  });

  test('Custom Quiz separates catalogue totals from bounded runtime loading', () {
    expect(source, contains('_catalogueScopeCount()'));
    expect(source, contains('descriptor.publishedQuestionCount'));
    expect(source, contains('.take(_maxRuntimeScopePackages)'));
    expect(source, contains('_availablePreparedQuestionCount()'));
    expect(source, contains('published questions in scope'));
    expect(source, contains("_scheduleSubtopicPreparation();"));
  });

  test('Custom Quiz does not preload the complete question bank for All CSP11', () {
    expect(source, contains('loadCatalogMetadata()'));
    expect(source, contains('prepareCompetencies(selected)'));
    expect(source, isNot(contains('prepareCompetencies(_competencyIds)')));
  });
}
