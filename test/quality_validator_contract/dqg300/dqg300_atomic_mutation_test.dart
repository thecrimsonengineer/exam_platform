import 'package:flutter_test/flutter_test.dart';

import '_support/dqg300_fixture.dart';

void main() {
  group('all 299 atomic DQGs fail closed independently', () {
    for (var i = 1; i <= 299; i++) {
      final ruleId = 'DQG-${i.toString().padLeft(3, '0')}';

      test('$ruleId structured proof failure blocks DQG-300', () {
        final evidence = failRuleProof(perfectDqg300Evidence(), ruleId);
        final result = validatePerfect(evidence: evidence);

        expect(result.rule(ruleId).passed, isFalse);
        expect(result.rule('DQG-300').passed, isFalse);
        expect(result.isPublishable, isFalse);
        expect(result.status.name, 'block');
      });
    }
  });
}
