enum QuestionQualityStatus {
  pass,
  block,
}

class QuestionQualityRuleResult {
  final String ruleId;
  final bool passed;
  final String message;

  const QuestionQualityRuleResult({
    required this.ruleId,
    required this.passed,
    required this.message,
  });
}

class QuestionQualityValidationResult {
  final List<QuestionQualityRuleResult> rules;
  final Map<String, int> dqsCategories;
  final int dqs;
  final QuestionQualityStatus status;

  QuestionQualityValidationResult.fromAtomicRules({
    required List<QuestionQualityRuleResult> atomicRules,
    required Map<String, int> dqsCategories,
  }) : assert(atomicRules.length == 299),
       assert(!atomicRules.any((rule) => rule.ruleId == 'DQG-300')),
       assert(dqsCategories.length == 10),
       dqsCategories = Map<String, int>.unmodifiable(dqsCategories),
       dqs = dqsCategories.values.fold<int>(0, (sum, score) => sum + score),
       status =
           atomicRules.every((rule) => rule.passed) &&
                   dqsCategories.values.fold<int>(
                         0,
                         (sum, score) => sum + score,
                       ) ==
                       100
               ? QuestionQualityStatus.pass
               : QuestionQualityStatus.block,
       rules = List<QuestionQualityRuleResult>.unmodifiable([
         ...atomicRules,
         QuestionQualityRuleResult(
           ruleId: 'DQG-300',
           passed:
               atomicRules.every((rule) => rule.passed) &&
               dqsCategories.values.fold<int>(
                     0,
                     (sum, score) => sum + score,
                   ) ==
                   100,
           message:
               atomicRules.every((rule) => rule.passed) &&
                       dqsCategories.values.fold<int>(
                             0,
                             (sum, score) => sum + score,
                           ) ==
                           100
                   ? 'Derived aggregate PASS: DQG-001 through DQG-299 all pass and DQS is 100.'
                   : 'Derived aggregate BLOCK: at least one atomic DQG failed or DQS is below 100.',
         ),
       ]);

  bool get isPublishable => status == QuestionQualityStatus.pass;

  int get passedRuleCount => rules.where((rule) => rule.passed).length;

  int get failedRuleCount => rules.where((rule) => !rule.passed).length;

  QuestionQualityRuleResult rule(String ruleId) {
    return rules.firstWhere((rule) => rule.ruleId == ruleId);
  }
}
