import 'package:exam_platform/services/question_quality_validator.dart';
import 'package:flutter_test/flutter_test.dart';

import '_support/dqg_contract_manifest.dart';

void main() {
  test('contract contains exactly 64 contiguous unique DQG identifiers', () {
    expect(dqgContractRules, hasLength(64));
    final ids = dqgContractRules.map((rule) => rule.id).toList();
    expect(ids.toSet(), hasLength(64));
    expect(
      ids,
      List.generate(64, (index) => 'DQG-${(index + 1).toString().padLeft(3, '0')}'),
    );
  });

  test('validator exposes the exact frozen 64-rule manifest', () {
    expect(
      QuestionQualityValidator.ruleIds,
      dqgContractRules.map((rule) => rule.id).toList(),
    );
  });
}
