import 'package:flutter_test/flutter_test.dart';

import '_support/dqg_contract_fixture.dart';

void main() {
  test('manual override request is itself a blocking condition', () {
    final result = validateContract(
      evidence: perfectEvidence().copyWith(manualOverrideRequested: true),
    );

    expect(result.rule('DQG-012').passed, isFalse);
    expect(result.rule('DQG-064').passed, isFalse);
    expect(result.isPublishable, isFalse);
  });

  test('DQS 100 can never bypass another failed DQG', () {
    final result = validateContract(
      evidence: perfectEvidence().copyWith(unresolvedWarningCount: 1),
    );

    expect(result.rule('DQG-011').passed, isFalse);
    expect(result.rule('DQG-064').passed, isFalse);
    expect(result.isPublishable, isFalse);
  });
}
