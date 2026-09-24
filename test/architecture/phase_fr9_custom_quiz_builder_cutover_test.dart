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
    expect(source, contains('_maxAllScopePackages = 4'));
    expect(source, isNot(contains('_quizService.initialize()')));
    expect(source, isNot(contains('getPublishedContent()')));
    expect(source, isNot(contains('ContentPackageSummary')));
  });

  test('Custom Quiz keeps all-scope package preparation bounded', () {
    expect(
      source,
      contains('candidates.take(_maxAllScopePackages)'),
    );
    expect(source, contains('_availablePreparedQuestionCount()'));
  });
}
