import 'package:flutter_test/flutter_test.dart';

import '_support/dqg_contract_fixture.dart';

void main() {
  test('DQS is computed from exactly ten fixed 10-point categories', () {
    final result = validateContract();

    expect(result.dqsCategories, hasLength(10));
    expect(result.dqsCategories.values.every((value) => value == 10), isTrue);
    expect(result.dqsCategories.values.fold<int>(0, (a, b) => a + b), 100);
    expect(result.dqs, 100);
  });

  test('weakening any scored category makes DQS less than 100', () {
    final d = perfectDistractor(0).copyWith(singleFatalFlaw: false);
    final result = validateContract(
      evidence: replaceDistractor(perfectEvidence(), 0, d),
    );

    expect(result.dqs, lessThan(100));
    expect(result.rule('DQG-008').passed, isFalse);
    expect(result.isPublishable, isFalse);
  });
}
