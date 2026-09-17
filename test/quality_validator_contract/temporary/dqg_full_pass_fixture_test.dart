import 'package:exam_platform/models/question_quality_validation_result.dart';
import 'package:flutter_test/flutter_test.dart';

import '_support/dqg_contract_fixture.dart';

void main() {
  test('perfect DQ6 fixture passes all 64 gates with DQS 100', () {
    final result = validateContract();

    expect(result.rules, hasLength(64));
    expect(result.rules.every((rule) => rule.passed), isTrue);
    expect(result.dqs, 100);
    expect(result.blockCount, 0);
    expect(result.failCount, 0);
    expect(result.warningCount, 0);
    expect(result.status, QuestionQualityStatus.pass);
    expect(result.isPublishable, isTrue);
  });
}
