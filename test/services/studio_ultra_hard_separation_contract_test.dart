import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String read(String path) => File(path).readAsStringSync();

  test('legacy Bulk 120 importer remains on the H0.3 path', () {
    final source = read(
      'lib/services/studio/studio_bulk_question_publish_service.dart',
    );

    expect(source, contains('StudioBulkQuestionPublishService'));
    expect(source, contains('_questionService.validate(question)'));
    expect(source, contains('publishPreparedBatch('));
    expect(source, isNot(contains('Dqg300QuestionQualityValidator')));
    expect(source, isNot(contains('publishPreparedUltraHardBatch')));
  });

  test('Ultra Hard importer is a distinct DQG300 path', () {
    final source = read(
      'lib/services/studio/studio_ultra_hard_question_publish_service.dart',
    );

    expect(source, contains('Dqg300QuestionQualityValidator'));
    expect(source, contains('result.passedRuleCount != 300'));
    expect(source, contains('result.failedRuleCount != 0'));
    expect(source, contains('result.dqs != 100'));
    expect(source, contains('publishPreparedUltraHardBatch('));
  });

  test('Studio exposes both legacy and Ultra Hard bulk buttons', () {
    final source = read(
      'lib/screens/admin/study_content/study_content_studio_screen.dart',
    );

    expect(source, contains("ValueKey('legacy-bulk-question-import')"));
    expect(source, contains("ValueKey('ultra-hard-bulk-question-import')"));
    expect(source, contains('Bulk 120 JSON • H0.3 • Publish • Auto-Link'));
    expect(source, contains('Ultra Hard JSON • DQG300 • 300/300'));
  });
}
