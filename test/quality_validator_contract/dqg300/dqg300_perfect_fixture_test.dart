import 'package:flutter_test/flutter_test.dart';

import '_support/dqg300_fixture.dart';

void main() {
  test('perfect DQG300 fixture passes exactly 300 of 300 rules', () {
    final result = validatePerfect();

    expect(result.rules.length, 300);
    expect(result.passedRuleCount, 300);
    expect(result.failedRuleCount, 0);
    expect(result.dqs, 100);
    expect(result.dqsCategories.length, 10);
    expect(result.dqsCategories.values, everyElement(10));
    expect(result.isPublishable, isTrue);
    expect(result.status.name, 'pass');
    expect(result.rule('DQG-300').passed, isTrue);
  });
}
